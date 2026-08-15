import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/colors.dart';
import '../services/hugging_face_service.dart';
import '../services/supabase_storage_service.dart';
import '../services/subscription_service.dart';
import '../services/chat_history_service.dart';
import '../widgets/upgrade_prompt_dialog.dart';
import '../widgets/chat_history_drawer.dart';
import '../widgets/formatted_message_view.dart';
import 'tools_hub_screen.dart';

class StudyAssistantScreen extends StatefulWidget {
  const StudyAssistantScreen({super.key});

  @override
  State<StudyAssistantScreen> createState() => _StudyAssistantScreenState();
}

class _StudyAssistantScreenState extends State<StudyAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final HuggingFaceService _hfService = HuggingFaceService();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  final ChatHistoryService _historyService = ChatHistoryService();
  String? _activeSessionId;
  bool _isLoadingMessages = false;
  
  List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'message': 'Hi! I\'m your Study Buddy. Need help with homework, explaining concepts, or making a quiz?',
      'isLoading': false,
      'imageUrl': null,
    }
  ];

  bool _isTyping = false;

  final SubscriptionService _subscriptionService = SubscriptionService();
  String _userTier = 'FREE';
  int _textRequestsToday = 0;
  int _textRequestsLimit = 5;
  bool _isLoadingLimitInfo = true;

  Uint8List? _attachedImageBytes;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _refreshLimitInfo();
  }

  Future<void> _loadMessages() async {
    if (_activeSessionId == null) return;
    setState(() => _isLoadingMessages = true);
    try {
      final dbMsgs = await _historyService.getMessages(_activeSessionId!);
      if (mounted) {
        setState(() {
          _messages = dbMsgs.map((m) => {
            'isUser': m['is_user'] == true,
            'message': m['message'] as String,
            'imageUrl': m['image_url'] as String?,
            'isLoading': false,
          }).toList();
          _isLoadingMessages = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('Error loading messages: $e');
      if (mounted) setState(() => _isLoadingMessages = false);
    }
  }

  Future<void> _refreshLimitInfo() async {
    final sub = await _subscriptionService.getSubscription();
    if (mounted && sub != null) {
      setState(() {
        _userTier = sub['tier'] ?? 'FREE';
        _textRequestsToday = sub['text_requests_today'] ?? 0;
        if (_userTier == 'BASIC') {
          _textRequestsLimit = 50;
        } else if (_userTier == 'PRO') {
          _textRequestsLimit = 150;
        } else {
          _textRequestsLimit = 5;
        }
        _isLoadingLimitInfo = false;
      });
    }
  }

  final ImagePicker _picker = ImagePicker();
  final SupabaseStorageService _storageService = SupabaseStorageService();
  XFile? _attachedImage;
  bool _isUploadingImage = false;
  String? _uploadedImageUrl;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _attachedImage = image;
          _attachedImageBytes = bytes;
          _isUploadingImage = true;
          _uploadedImageUrl = null;
        });

        // Perform actual upload to Supabase
        final publicUrl = await _storageService.uploadSelfie(image);
        
        setState(() {
          if (publicUrl != null) {
            _uploadedImageUrl = publicUrl;
          } else {
            _attachedImage = null;
            _attachedImageBytes = null;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to upload image. Please try again.')),
            );
          }
          _isUploadingImage = false;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      setState(() {
        _isUploadingImage = false;
        _attachedImage = null;
        _attachedImageBytes = null;
      });
    }
  }

  void _clearAttachedImage() {
    setState(() {
      _attachedImage = null;
      _attachedImageBytes = null;
      _uploadedImageUrl = null;
    });
  }

  Future<void> _sendMessage({String? predefinedText}) async {
    final text = predefinedText ?? _controller.text.trim();
    if (text.isEmpty && _uploadedImageUrl == null) return;

    // Limits check
    final allowed = await _subscriptionService.checkAndIncrementTextUsage();
    if (!allowed) {
      if (mounted) {
        UpgradePromptDialog.show(
          context,
          title: "Daily Limit Reached",
          message: "You have completed your daily quota of requests on the $_userTier tier. Upgrade to BASIC or PRO to get up to 150 requests per day!",
        );
      }
      return;
    }
    _refreshLimitInfo();

    final String activeImageUrl = _uploadedImageUrl ?? '';
    final hasImage = activeImageUrl.isNotEmpty;
    final Uint8List? imageBytesCopy = _attachedImageBytes;

    // Create session if not active
    if (_activeSessionId == null) {
      try {
        final session = await _historyService.createSession('study_assistant', initialTitle: text.isEmpty ? 'Study Material' : text);
        _activeSessionId = session['id'];
      } catch (e) {
        print('Error creating study session: $e');
        _activeSessionId = 'local_${DateTime.now().millisecondsSinceEpoch}';
      }
    }

    // Save user message to database
    if (_activeSessionId != null) {
      try {
        await _historyService.addMessage(
          _activeSessionId!,
          isUser: true,
          message: text.isEmpty && hasImage ? 'Study Document Attached' : text,
          imageUrl: hasImage ? activeImageUrl : null,
        );
      } catch (e) {
        print('Error saving study message: $e');
      }
    }

    setState(() {
      _messages.add({
        'isUser': true,
        'message': text,
        'imageUrl': hasImage ? activeImageUrl : null,
        'isLoading': false,
      });
      _isTyping = true;
      _controller.clear();
      _attachedImage = null;
      _attachedImageBytes = null;
      _uploadedImageUrl = null;
      _isUploadingImage = false;
    });
    
    _scrollToBottom();
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });

    // Call API
    String response;
    if (hasImage || imageBytesCopy != null) {
      String visionUrl = activeImageUrl;
      if (imageBytesCopy != null) {
        final base64String = base64Encode(imageBytesCopy);
        visionUrl = 'data:image/jpeg;base64,$base64String';
      }
      response = await _hfService.generateVisionText(
        text.isEmpty ? "Explain this study material or concept shown in the image." : text, 
        visionUrl
      );
    } else {
      final prompt = "You are a helpful study assistant. Keep answers clear and educational.\n\nUser: $text\n\nAssistant:";
      response = await _hfService.generateText(prompt, HuggingFaceService.modelChat);
    }

    // Save AI response to database
    if (_activeSessionId != null) {
      try {
        await _historyService.addMessage(
          _activeSessionId!,
          isUser: false,
          message: response,
        );
      } catch (e) {
        print('Error saving study assistant response: $e');
      }
    }

    if (mounted) {
      setState(() {
        _isTyping = false;
        _messages.add({
          'isUser': false,
          'message': response,
          'isLoading': false,
          'imageUrl': null,
        });
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      drawer: ChatHistoryDrawer(
        featureType: 'study_assistant',
        activeSessionId: _activeSessionId,
        onSessionSelected: (session) {
          setState(() {
            _activeSessionId = session['id'];
          });
          _loadMessages();
        },
        onNewChatStarted: () {
          setState(() {
            _activeSessionId = null;
            _messages = [
              {
                'isUser': false,
                'message': 'Hi! I\'m your Study Buddy. Need help with homework, explaining concepts, or making a quiz?',
                'isLoading': false,
                'imageUrl': null,
              }
            ];
          });
        },
      ),
      appBar: AppBar(
        title: Text(
          'Study Assistant',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ToolsHubScreen()),
            );
          },
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Builder(
              builder: (context) => ElevatedButton.icon(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.history, size: 16, color: Colors.white),
                label: Text(
                  'History',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neutralSurface,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: AppColors.neutralBorder),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!_isLoadingLimitInfo) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Account Plan: $_userTier',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.neutralTextMuted,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Daily Limit: $_textRequestsToday / $_textRequestsLimit queries',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: _textRequestsToday >= _textRequestsLimit ? Colors.redAccent : AppColors.neutralTextMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Quick Tools/Prompts
            Container(
              height: 50,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildQuickAction('Explain Concept'),
                  const SizedBox(width: 8),
                  _buildQuickAction('Make Quiz'),
                  const SizedBox(width: 8),
                  _buildQuickAction('Outline Essay'),
                  const SizedBox(width: 8),
                  _buildQuickAction('Summarize Notes'),
                ],
              ),
            ),

            // Chat Area
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isTyping) {
                     return const ChatMessage(
                      isUser: false,
                      message: "Thinking...",
                      isLoading: true,
                    );
                  }
                  final msg = _messages[index];
                  return ChatMessage(
                    isUser: msg['isUser'],
                    message: msg['message'],
                    isLoading: msg['isLoading'] ?? false,
                    imageUrl: msg['imageUrl'],
                  );
                },
              ),
            ),
            
            // Input Area
            TextFieldTapRegion(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.backgroundDark,
                  border: Border(top: BorderSide(color: AppColors.neutralBorder, width: 0.5)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Staged Image Preview
                    if (_attachedImage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.neutralSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.neutralBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.image, color: Colors.greenAccent, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _attachedImage!.name,
                                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_isUploadingImage)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppColors.primary)),
                                )
                              else
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                                  onPressed: _clearAttachedImage,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                            ],
                          ),
                        ),
                      ),
                    
                    // Input Row
                    Row(
                      children: [
                        // Attachment options directly side-by-side
                        IconButton(
                          icon: const Icon(Icons.add_a_photo, color: Colors.white70),
                          onPressed: () => _pickImage(ImageSource.camera),
                        ),
                        IconButton(
                          icon: const Icon(Icons.photo_library, color: Colors.white70),
                          onPressed: () => _pickImage(ImageSource.gallery),
                        ),
                        const SizedBox(width: 8),
                        
                        // TextField wrapped in a rounded container
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppColors.neutralSurface,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppColors.neutralBorder),
                            ),
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Ask a question...',
                                hintStyle: GoogleFonts.inter(color: AppColors.neutralTextMuted),
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Send Button
                        GestureDetector(
                          onTap: _isUploadingImage ? null : () => _sendMessage(),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_upward, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(String title) {
    return GestureDetector(
      onTap: () {
        _sendMessage(predefinedText: "Can you help me $title?");
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.neutralSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
        ),
        child: Center(
          child: Text(
            title,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final bool isUser;
  final String message;
  final bool isLoading;
  final String? imageUrl;

  const ChatMessage({
    super.key,
    required this.isUser,
    required this.message,
    this.isLoading = false,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent, // Distinct color for Study Buddy
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(Icons.school, color: Colors.black, size: 16),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.neutralSurface : Colors.transparent,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
                      bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
                    ),
                    border: isUser ? null : Border.all(color: AppColors.neutralBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isLoading)
                        Row(
                          children: [
                            const SizedBox(
                              width: 16, 
                              height: 16, 
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.greenAccent)
                            ),
                            const SizedBox(width: 12),
                            Text(
                              message, 
                              style: GoogleFonts.inter(color: AppColors.neutralTextMuted)
                            ),
                          ],
                        )
                      else ...[
                        if (imageUrl != null) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (c, o, s) => const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ],
                        FormattedMessageView(
                          text: message,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 0), 
              ],
            ],
          ),
        ],
      ),
    );
  }
}
