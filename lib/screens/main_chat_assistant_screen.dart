import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import '../constants/colors.dart';
import '../services/hugging_face_service.dart';
import '../services/supabase_storage_service.dart';
import '../services/subscription_service.dart';
import '../services/chat_history_service.dart';
import '../widgets/upgrade_prompt_dialog.dart';
import '../widgets/chat_history_drawer.dart';
import '../widgets/formatted_message_view.dart';
import 'settings_screen.dart';
import 'tools_hub_screen.dart';

class MainChatAssistantScreen extends StatefulWidget {
  const MainChatAssistantScreen({super.key});

  @override
  State<MainChatAssistantScreen> createState() => _MainChatAssistantScreenState();
}

class _MainChatAssistantScreenState extends State<MainChatAssistantScreen> {
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
      'message': 'Hello! I am your Tech4All AI assistant. How can I help you today?',
      'isLoading': false,
      'imageUrl': null,
    }
  ];

  bool _isTyping = false;
  String _selectedModel = 'Sonder 0.1';

  final SubscriptionService _subscriptionService = SubscriptionService();
  String _userTier = 'FREE';
  int _textRequestsToday = 0;
  int _textRequestsLimit = 5;
  bool _isLoadingLimitInfo = true;

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

        // Reset if user is free but selected pro model
        if (_userTier == 'FREE' && _selectedModel == 'Sonder 0.1 Pro') {
          _selectedModel = 'Sonder 0.1';
        }
      });
    }
  }

  final ImagePicker _picker = ImagePicker();
  final SupabaseStorageService _storageService = SupabaseStorageService();
  XFile? _attachedImage;
  Uint8List? _attachedImageBytes;
  double _uploadProgress = 0.0;
  bool _isUploadingImage = false;
  String? _uploadedImageUrl;
  bool _isMenuOpen = false;

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isMenuOpen = false;
    });
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _attachedImage = image;
          _attachedImageBytes = bytes;
          _isUploadingImage = true;
          _uploadProgress = 0.0;
          _uploadedImageUrl = null;
        });

        // Start simulated smooth upload progress over 1 second to create a premium WOW indicator
        Timer? progressTimer;
        progressTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
          setState(() {
            if (_uploadProgress < 0.9) {
              _uploadProgress += 0.05;
            } else {
              progressTimer?.cancel();
            }
          });
        });

        // Perform actual upload to Supabase
        final publicUrl = await _storageService.uploadSelfie(image);
        
        progressTimer.cancel();

        setState(() {
          if (publicUrl != null) {
            _uploadProgress = 1.0;
            _uploadedImageUrl = publicUrl;
            _isUploadingImage = false;
          } else {
            _attachedImage = null;
            _attachedImageBytes = null;
            _isUploadingImage = false;
            _uploadProgress = 0.0;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to upload image. Please try again.')),
            );
          }
        });
      }
    } catch (e) {
      print('Error picking/uploading image: $e');
      setState(() {
        _isUploadingImage = false;
        _attachedImage = null;
        _attachedImageBytes = null;
      });
    }
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
          message: "You have completed your daily quota of requests on the $_userTier tier. Upgrade to BASIC or PRO to get up to 150 requests per day and access Sonder 0.1 Pro models!",
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
        final session = await _historyService.createSession('main_chat', initialTitle: text.isEmpty ? 'Image Analysis' : text);
        _activeSessionId = session['id'];
      } catch (e) {
        print('Error creating session: $e');
        _activeSessionId = 'local_${DateTime.now().millisecondsSinceEpoch}';
      }
    }

    // Save user message to database
    if (_activeSessionId != null) {
      try {
        await _historyService.addMessage(
          _activeSessionId!,
          isUser: true,
          message: text.isEmpty && hasImage ? 'Attached Image' : text,
          imageUrl: hasImage ? activeImageUrl : null,
        );
      } catch (e) {
        print('Error saving user message to database: $e');
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
      _uploadProgress = 0.0;
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
      // Use Vision model
      response = await _hfService.generateVisionText(text.isEmpty ? "Describe this image" : text, visionUrl);
    } else {
      // Use Standard Chat model
      final modelId = _selectedModel == 'Sonder 0.1 Pro' 
          ? HuggingFaceService.modelChatSonder120b 
          : HuggingFaceService.modelChatSonder20b;
      response = await _hfService.generateText(text, modelId);
    }

    // Save AI message to database
    if (_activeSessionId != null) {
      try {
        await _historyService.addMessage(
          _activeSessionId!,
          isUser: false,
          message: response,
        );
      } catch (e) {
        print('Error saving AI response to database: $e');
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
          border: Border.all(color: AppColors.primary.withOpacity(0.5)),
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

  void _showEditPromptDialog(int index) {
    final originalText = _messages[index]['message'] as String;
    final textController = TextEditingController(text: originalText);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.neutralSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.neutralBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit_note_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Revert & Edit Prompt',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Editing this prompt will revert the conversation to this point. All subsequent messages will be cleared, and a new AI response will be generated.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.neutralTextMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.neutralBorder),
                  ),
                  child: TextField(
                    controller: textController,
                    maxLines: 4,
                    minLines: 2,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Type your edited prompt here...',
                      hintStyle: TextStyle(color: Colors.white30),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.neutralBorder),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          final newText = textController.text.trim();
                          if (newText.isNotEmpty) {
                            Navigator.pop(context);
                            _regenerateResponse(index, newText);
                          }
                        },
                        child: Text(
                          'Regenerate',
                          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _regenerateResponse(int index, String newText) async {
    final originalMsg = _messages[index];
    final String? msgImageUrl = originalMsg['imageUrl'];

    // Limits check
    final allowed = await _subscriptionService.checkAndIncrementTextUsage();
    if (!allowed) {
      if (mounted) {
        UpgradePromptDialog.show(
          context,
          title: "Daily Limit Reached",
          message: "You have completed your daily quota of requests on the $_userTier tier. Upgrade to BASIC or PRO to get up to 150 requests per day and access Sonder 0.1 Pro models!",
        );
      }
      return;
    }
    _refreshLimitInfo();

    setState(() {
      _messages[index]['message'] = newText;
      if (index + 1 < _messages.length) {
        _messages.removeRange(index + 1, _messages.length);
      }
      _isTyping = true;
    });

    _scrollToBottom();

    String response;
    if (msgImageUrl != null && msgImageUrl.isNotEmpty) {
      response = await _hfService.generateVisionText(newText, msgImageUrl);
    } else {
      final modelId = _selectedModel == 'Sonder 0.1 Pro' 
          ? HuggingFaceService.modelChatSonder120b 
          : HuggingFaceService.modelChatSonder20b;
      response = await _hfService.generateText(newText, modelId);
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
        featureType: 'main_chat',
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
                'message': 'Hello! I am your Tech4All AI assistant. How can I help you today?',
                'isLoading': false,
                'imageUrl': null,
              }
            ];
          });
        },
      ),
      appBar: AppBar(
        title: Text(
          'Tech4All AI',
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
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.history, color: Colors.white),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Model Switcher
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.neutralSurface,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.neutralBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedModel = 'Sonder 0.1'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedModel == 'Sonder 0.1' ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: Center(
                          child: Text(
                            'Sonder 0.1',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (_userTier == 'FREE') {
                          UpgradePromptDialog.show(
                            context,
                            title: "Pro Model Restricted",
                            message: "The Sonder 0.1 Pro (120B) reasoning model is exclusive to BASIC and PRO tiers. Upgrade now to unlock premium model access!",
                          );
                        } else {
                          setState(() => _selectedModel = 'Sonder 0.1 Pro');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedModel == 'Sonder 0.1 Pro' ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Sonder 0.1 Pro',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amberAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.amberAccent, width: 0.5),
                              ),
                              child: Text(
                                'PRO',
                                style: GoogleFonts.inter(
                                  color: Colors.amberAccent,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _selectedModel == 'Sonder 0.1 Pro'
                    ? '💡 Sonder 0.1 Pro (120B reasoning model) supports deep reasoning & logic.'
                    : '⚡ Sonder 0.1 (20B parameters) provides fast, responsive everyday help.',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.neutralTextMuted,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
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
            const SizedBox(height: 8),
            // Quick Tools/Prompts
            Container(
              height: 50,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildQuickAction('Help me Plan'),
                  const SizedBox(width: 8),
                  _buildQuickAction('Write an Email'),
                  const SizedBox(width: 8),
                  _buildQuickAction('Solve Math'),
                  const SizedBox(width: 8),
                  _buildQuickAction('Creative Ideas'),
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
                      message: "Typing...",
                      isLoading: true,
                    );
                  }
                  final msg = _messages[index];
                  return ChatMessage(
                    isUser: msg['isUser'],
                    message: msg['message'],
                    isLoading: msg['isLoading'] ?? false,
                    onEdit: msg['isUser'] ? () => _showEditPromptDialog(index) : null,
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
                    if (_attachedImageBytes != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.primary, width: 1.5),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.memory(
                                  _attachedImageBytes!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            if (_isUploadingImage)
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: CircularProgressIndicator(
                                      value: _uploadProgress,
                                      strokeWidth: 3,
                                      color: Colors.white,
                                      backgroundColor: Colors.white24,
                                    ),
                                  ),
                                ),
                              ),
                            Positioned(
                              top: -6,
                              right: -6,
                              child: Listener(
                                behavior: HitTestBehavior.opaque,
                                onPointerDown: (_) {
                                  setState(() {
                                    _attachedImage = null;
                                    _attachedImageBytes = null;
                                    _uploadedImageUrl = null;
                                    _isUploadingImage = false;
                                    _uploadProgress = 0.0;
                                  });
                                  Future.delayed(const Duration(milliseconds: 50), () {
                                    if (mounted) {
                                      _focusNode.requestFocus();
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ],
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
                                hintText: 'Message Tech4All...',
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
                    const SizedBox(height: 8),
                    Text(
                      'AI can make mistakes. Please verify important information.',
                      style: GoogleFonts.inter(fontSize: 10, color: AppColors.neutralTextMuted),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final bool isUser;
  final String message;
  final bool isLoading;
  final bool showChartPlaceholder;
  final VoidCallback? onEdit;
  final String? imageUrl;

  const ChatMessage({
    super.key,
    required this.isUser,
    required this.message,
    this.isLoading = false,
    this.showChartPlaceholder = false,
    this.onEdit,
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
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                  ),
                  child: const Center(
                    child: Icon(Icons.auto_awesome, color: Colors.white, size: 16),
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
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)
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
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 200),
                                child: Image.network(
                                  imageUrl!,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ],
                        FormattedMessageView(
                          text: message,
                        ),
                        if (isUser && onEdit != null) ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: onEdit,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.neutralBorder.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.neutralBorder.withOpacity(0.5)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.edit_rounded, size: 14, color: Colors.white70),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Edit',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (!isUser) ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: message));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Copied to clipboard!',
                                        style: GoogleFonts.inter(color: Colors.white),
                                      ),
                                      backgroundColor: AppColors.primary,
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.neutralBorder.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.neutralBorder.withOpacity(0.5)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.copy_rounded, size: 14, color: Colors.white70),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Copy',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
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
          if (showChartPlaceholder && !isLoading) ...[
             const SizedBox(height: 12),
             Container(
               margin: const EdgeInsets.only(left: 44), // Align with text
               height: 160,
               width: 250,
               decoration: BoxDecoration(
                 color: AppColors.neutralSurface,
                 borderRadius: BorderRadius.circular(12),
                 border: Border.all(color: AppColors.neutralBorder),
               ),
               child: const Center(
                 child: Icon(Icons.bar_chart, size: 48, color: AppColors.primary),
               ),
             )
          ]
        ],
      ),
    );
  }
}
