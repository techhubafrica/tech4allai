import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:universal_html/html.dart' as html;
import '../services/hugging_face_service.dart';
import '../services/supabase_storage_service.dart';
import '../services/subscription_service.dart';
import '../services/chat_history_service.dart';
import '../widgets/upgrade_prompt_dialog.dart';
import '../widgets/chat_history_drawer.dart';
import '../widgets/formatted_message_view.dart';
import '../widgets/redesign_icons.dart';
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
  bool _isSending = false;
  String _selectedModel = 'Sonder 0.1';

  final SubscriptionService _subscriptionService = SubscriptionService();
  String _userTier = 'FREE';

  final ImagePicker _picker = ImagePicker();
  final SupabaseStorageService _storageService = SupabaseStorageService();
  Uint8List? _attachedImageBytes;
  double _uploadProgress = 0.0;
  bool _isUploadingImage = false;
  String? _uploadedImageUrl;

  String? _toastMessage;
  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();
    _refreshLimitInfo();
    _focusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _showToast(String message) {
    _toastTimer?.cancel();
    setState(() {
      _toastMessage = message;
    });
    _toastTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) {
        setState(() {
          _toastMessage = null;
        });
      }
    });
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
      if (mounted) setState(() => _isLoadingMessages = false);
    }
  }

  Future<void> _refreshLimitInfo() async {
    final sub = await _subscriptionService.getSubscription();
    if (mounted && sub != null) {
      setState(() {
        _userTier = sub['tier'] ?? 'FREE';

        // Reset if user is free but selected pro model
        if (_userTier == 'FREE' && _selectedModel == 'Sonder 0.1 Pro') {
          _selectedModel = 'Sonder 0.1';
        }
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _attachedImageBytes = bytes;
          _isUploadingImage = true;
          _uploadProgress = 0.0;
          _uploadedImageUrl = null;
        });

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

        final publicUrl = await _storageService.uploadSelfie(image);
        progressTimer.cancel();

        setState(() {
          if (publicUrl != null) {
            _uploadProgress = 1.0;
            _uploadedImageUrl = publicUrl;
            _isUploadingImage = false;
            _showToast('Image ready for analysis');
          } else {
            _attachedImageBytes = null;
            _isUploadingImage = false;
            _uploadProgress = 0.0;
            _showToast('Failed to upload image. Please try again.');
          }
        });
      }
    } catch (e) {
      setState(() {
        _attachedImageBytes = null;
        _isUploadingImage = false;
        _uploadProgress = 0.0;
      });
      _showToast('Could not access image');
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

  void _showEditPromptDialog(int index) {
    final originalText = _messages[index]['message'] as String;
    final textController = TextEditingController(text: originalText);

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const RadialGradient(
                center: Alignment(0.0, -0.6),
                radius: 1.25,
                colors: [
                  Color(0xFF2E1F16), // Warm amber ambient glow
                  Color(0xFF1E140E),
                  Color(0xFF140D08), // Deep dark base
                ],
              ),
              border: Border.all(color: const Color(0x4DFF9233), width: 1.2),
              boxShadow: [
                const BoxShadow(
                  color: Color(0x40FF7300),
                  blurRadius: 30,
                  offset: Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.65),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header with Squircle Badge & Close Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFFF9534), Color(0xFFFF6701)],
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x66FF7300),
                                blurRadius: 14,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: RedesignIcons.edit(size: 19, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Revert & Edit Prompt',
                              style: GoogleFonts.inter(
                                fontSize: 17.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Reverts thread & generates fresh response',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: const Color(0xFF9E968F),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Close Circle Button
                    BouncingButton(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x8C40362F), Color(0x8C261F1A)],
                          ),
                          border: Border.all(color: const Color(0x2EFFFFFF), width: 1.0),
                        ),
                        child: Center(
                          child: RedesignIcons.close(size: 16, color: Colors.white70),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Informational Warning Pill Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0x382D1F15),
                    border: Border.all(color: const Color(0x33FF9838), width: 0.8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFF9233),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Editing clears subsequent messages and starts a new AI response from this point.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFFDDD2CA),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Modern Glass Text Input Area
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0x59291D15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x38FF9838), width: 1.1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: textController,
                    autofocus: true,
                    maxLines: 5,
                    minLines: 3,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14.5,
                      height: 1.4,
                    ),
                    cursorColor: const Color(0xFFFF9233),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintText: 'Type your edited prompt here...',
                      hintStyle: GoogleFonts.inter(
                        color: const Color(0xFF7E756E),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // Action Buttons Row (Cancel & Save & Resubmit)
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      flex: 2,
                      child: BouncingButton(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x8C40362F), Color(0x8C261F1A)],
                            ),
                            border: Border.all(color: const Color(0x2EFFFFFF), width: 1.0),
                          ),
                          child: Center(
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(
                                color: const Color(0xFFD4C9C2),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Glowing Save & Resubmit Button
                    Expanded(
                      flex: 3,
                      child: BouncingButton(
                        onTap: () {
                          final newText = textController.text.trim();
                          if (newText.isNotEmpty && newText != originalText) {
                            Navigator.pop(context);
                            _regenerateResponse(index, newText);
                          }
                        },
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFFF9534), Color(0xFFFF6701)],
                            ),
                            border: Border.all(color: const Color(0x80FFE1B9), width: 1.0),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x66FF7300),
                                blurRadius: 16,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              RedesignIcons.send(size: 16, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                'Resubmit',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
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

  Future<void> _sendMessage({String? predefinedText}) async {
    final text = predefinedText ?? _controller.text.trim();
    if ((text.isEmpty && _attachedImageBytes == null) || _isSending) return;

    if (predefinedText == null) {
      _controller.clear();
    }

    final hasImage = _uploadedImageUrl != null;
    final activeImageUrl = _uploadedImageUrl ?? '';
    final imageBytesCopy = _attachedImageBytes;

    setState(() {
      _isSending = true;
      _isTyping = true;
      _messages.add({
        'isUser': true,
        'message': text,
        'imageUrl': hasImage ? activeImageUrl : null,
        'isLoading': false,
      });

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

    // 1. Quota / Limits check
    final allowed = await _subscriptionService.checkAndIncrementTextUsage();
    if (!allowed) {
      setState(() {
        _isSending = false;
        _isTyping = false;
        if (_messages.isNotEmpty) {
          _messages.removeLast();
        }
        _controller.text = text;
      });
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

    // 2. Create session if not active
    if (_activeSessionId == null) {
      try {
        final session = await _historyService.createSession(
          'main_chat',
          initialTitle: text.isEmpty ? 'Image Analysis' : text,
        );
        _activeSessionId = session['id'];
      } catch (e) {
        _activeSessionId = 'local_${DateTime.now().millisecondsSinceEpoch}';
      }
    }

    // 3. Save user message to database
    if (_activeSessionId != null) {
      try {
        await _historyService.addMessage(
          _activeSessionId!,
          isUser: true,
          message: text.isEmpty && hasImage ? 'Attached Image' : text,
          imageUrl: hasImage ? activeImageUrl : null,
        );
      } catch (e) {
        // database error handled
      }
    }

    // 4. Call AI API
    String response;
    try {
      if (hasImage || imageBytesCopy != null) {
        String visionUrl = activeImageUrl;
        if (imageBytesCopy != null) {
          final base64String = base64Encode(imageBytesCopy);
          visionUrl = 'data:image/jpeg;base64,$base64String';
        }
        response = await _hfService.generateVisionText(
          text.isEmpty ? "Describe this image" : text,
          visionUrl,
        );
      } else {
        final modelId = _selectedModel == 'Sonder 0.1 Pro'
            ? HuggingFaceService.modelChatSonder120b
            : HuggingFaceService.modelChatSonder20b;
        response = await _hfService.generateText(text, modelId);
      }
    } catch (e) {
      response = "Sorry, I encountered an error processing your request. Please try again.";
    }

    // 5. Save AI message to database
    if (_activeSessionId != null) {
      try {
        await _historyService.addMessage(
          _activeSessionId!,
          isUser: false,
          message: response,
        );
      } catch (e) {
        // database error handled
      }
    }

    if (mounted) {
      setState(() {
        _isSending = false;
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

  Widget _buildHistoryDrawer() {
    return ChatHistoryDrawer(
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
        _showToast('Started new chat');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080503),
      drawer: _buildHistoryDrawer(),
      endDrawer: _buildHistoryDrawer(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: Stack(
              children: [
                // Ambient Radial Background Glow matching app-canvas
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0.0, -0.64),
                        radius: 1.25,
                        colors: [
                          Color(0xFF28180D),
                          Color(0xFF150D07),
                          Color(0xFF110B07),
                        ],
                        stops: [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),

                // Top ambient orange glow orb
                Positioned(
                  top: -60,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 280,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0x26FF7A00),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x33FF7A00),
                            blurRadius: 90,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Main Column Structure
                Column(
                  children: [
                    // 1. TOP HEADER BAR
                    _buildHeaderBar(),

                    // 2. MODEL SELECTOR
                    _buildModelSwitcher(),

                    // 3. CHAT MESSAGES AREA
                    Expanded(
                      child: _isLoadingMessages
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFFF7A00),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              itemCount: _messages.length + (_isTyping ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _messages.length && _isTyping) {
                                  return const FadeSlideMessage(
                                    child: ChatMessage(
                                      isUser: false,
                                      message: "Thinking...",
                                      isLoading: true,
                                    ),
                                  );
                                }
                                final msg = _messages[index];
                                return FadeSlideMessage(
                                  child: ChatMessage(
                                    isUser: msg['isUser'],
                                    message: msg['message'],
                                    isLoading: msg['isLoading'] ?? false,
                                    onEdit: msg['isUser'] ? () => _showEditPromptDialog(index) : null,
                                    imageUrl: msg['imageUrl'],
                                    onShowToast: _showToast,
                                  ),
                                );
                              },
                            ),
                    ),

                    // 5. BOTTOM COMPOSER BAR & FOOTER
                    _buildComposerBar(),
                  ],
                ),

                // 6. FLOATING TOAST NOTIFICATION
                if (_toastMessage != null)
                  Positioned(
                    top: 16,
                    left: 20,
                    right: 20,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xA640362F),
                              Color(0xA6261F1A),
                            ],
                          ),
                          border: Border.all(color: const Color(0x4DEEAF37), width: 1.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          _toastMessage!,
                          style: GoogleFonts.inter(
                            color: const Color(0xFFFFE082),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- TOP HEADER BAR ---
  Widget _buildHeaderBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button: glass-pill-top 44x44
          BouncingButton(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ToolsHubScreen()),
              );
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xA640362F), // rgba(64, 54, 47, 0.65)
                    Color(0xA6261F1A), // rgba(38, 31, 26, 0.65)
                  ],
                ),
                border: Border.all(color: const Color(0x24FFFFFF), width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: RedesignIcons.arrowBack(
                  size: 21,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Title
          Text(
            'Tech4All AI',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.4,
              color: Colors.white,
            ),
          ),

          // Right Controls: History Pill + Settings Gear
          Row(
            children: [
              Builder(
                builder: (context) => BouncingButton(
                  onTap: () => Scaffold.of(context).openEndDrawer(),
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(21),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xA640362F),
                          Color(0xA6261F1A),
                        ],
                      ),
                      border: Border.all(color: const Color(0x24FFFFFF), width: 1.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RedesignIcons.history(
                          size: 17,
                          color: const Color(0xD9FFFFFF),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'History',
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xF2FFFFFF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              BouncingButton(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: RedesignIcons.settings(
                      size: 23,
                      color: const Color(0xFFD4CFC9),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- MODEL SEGMENTED SWITCHER ---
  Widget _buildModelSwitcher() {
    final isPro = _selectedModel == 'Sonder 0.1 Pro';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: const Color(0xD1221B16), // rgba(34, 27, 22, 0.82)
          border: Border.all(color: const Color(0x1CFFFFFF), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Standard Model Tab
            Expanded(
              child: BouncingButton(
                onTap: () {
                  if (_selectedModel != 'Sonder 0.1') {
                    setState(() => _selectedModel = 'Sonder 0.1');
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: !isPro
                        ? const LinearGradient(
                            colors: [
                              Color(0xFFFF981A),
                              Color(0xFFFF7300),
                              Color(0xFFFF5E00),
                            ],
                            stops: [0.0, 0.55, 1.0],
                          )
                        : null,
                    border: !isPro
                        ? Border.all(color: const Color(0x73FFE1B9), width: 1.0)
                        : null,
                    boxShadow: !isPro
                        ? [
                            const BoxShadow(
                              color: Color(0xA6FF7800),
                              blurRadius: 22,
                            ),
                            const BoxShadow(
                              color: Color(0x47FF6400),
                              blurRadius: 40,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      'Sonder 0.1',
                      style: GoogleFonts.inter(
                        fontSize: 15.5,
                        fontWeight: !isPro ? FontWeight.bold : FontWeight.w600,
                        letterSpacing: -0.2,
                        color: !isPro ? Colors.white : const Color(0xD9FFFFFF),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Pro Model Tab
            Expanded(
              child: BouncingButton(
                onTap: () {
                  if (_userTier == 'FREE') {
                    UpgradePromptDialog.show(
                      context,
                      title: "Pro Model Restricted",
                      message: "The Sonder 0.1 Pro (70B) reasoning model is exclusive to BASIC and PRO tiers. Upgrade now to unlock premium model access!",
                    );
                  } else {
                    if (_selectedModel != 'Sonder 0.1 Pro') {
                      setState(() => _selectedModel = 'Sonder 0.1 Pro');
                    }
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: isPro
                        ? const LinearGradient(
                            colors: [
                              Color(0xFFFF981A),
                              Color(0xFFFF7300),
                              Color(0xFFFF5E00),
                            ],
                            stops: [0.0, 0.55, 1.0],
                          )
                        : null,
                    border: isPro
                        ? Border.all(color: const Color(0x73FFE1B9), width: 1.0)
                        : null,
                    boxShadow: isPro
                        ? [
                            const BoxShadow(
                              color: Color(0xA6FF7800),
                              blurRadius: 22,
                            ),
                            const BoxShadow(
                              color: Color(0x47FF6400),
                              blurRadius: 40,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sonder 0.1 Pro',
                        style: GoogleFonts.inter(
                          fontSize: 15.0,
                          fontWeight: isPro ? FontWeight.bold : FontWeight.w600,
                          letterSpacing: -0.2,
                          color: isPro ? Colors.white : const Color(0xD9FFFFFF),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0x2EB97D14), // rgba(185, 125, 20, 0.18)
                          border: Border.all(color: const Color(0xA6EEAF37), width: 1.0),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x26EEAF37),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Text(
                          'PRO',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: const Color(0xFFF6C15C),
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
    );
  }

  // --- BOTTOM COMPOSER BAR & FOOTER ---
  Widget _buildComposerBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Color(0xFF0D0805),
            Color(0xF2120C08),
            Colors.transparent,
          ],
          stops: [0.0, 0.7, 1.0],
        ),
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
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFF7A00), width: 1.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.memory(
                        _attachedImageBytes!,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (_isUploadingImage)
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            value: _uploadProgress,
                            strokeWidth: 2.8,
                            color: const Color(0xFFFF7A00),
                            backgroundColor: Colors.white24,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _attachedImageBytes = null;
                          _uploadedImageUrl = null;
                          _isUploadingImage = false;
                          _uploadProgress = 0.0;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: RedesignIcons.close(size: 13, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Main Inputs Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Grouped Camera & Gallery Capsule (media-pill-group)
              Container(
                height: 54,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xD9211B16), // rgba(33, 27, 22, 0.85)
                  borderRadius: BorderRadius.circular(27),
                  border: Border.all(color: const Color(0x1CFFFFFF), width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Camera Circle Button
                    BouncingButton(
                      onTap: () => _pickImage(ImageSource.camera),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xB840362E),
                              Color(0xB82A231D),
                            ],
                          ),
                          border: Border.all(color: const Color(0x1AFFFFFF), width: 1.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: RedesignIcons.camera(
                            size: 21,
                            color: const Color(0xFFBEB8B2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Gallery Circle Button
                    BouncingButton(
                      onTap: () => _pickImage(ImageSource.gallery),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xB840362E),
                              Color(0xB82A231D),
                            ],
                          ),
                          border: Border.all(color: const Color(0x1AFFFFFF), width: 1.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: RedesignIcons.gallery(
                            size: 20,
                            color: const Color(0xFFBEB8B2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Center Glowing Message Input Pill (message-input-pill)
              Expanded(
                child: Container(
                  height: 54,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(27),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xC72C231C), // rgba(44, 35, 28, 0.78)
                        Color(0xE01C1611), // rgba(28, 22, 17, 0.88)
                      ],
                    ),
                    border: Border.all(
                      color: _focusNode.hasFocus
                          ? const Color(0xF2FF9637)
                          : const Color(0x9FEB822A), // rgba(235, 130, 42, 0.62)
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _focusNode.hasFocus
                            ? const Color(0x6BFF7A00)
                            : const Color(0x3DFF7300),
                        blurRadius: _focusNode.hasFocus ? 28 : 22,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Message Tech4All...',
                      hintStyle: GoogleFonts.inter(
                        color: const Color(0xFF8C837B),
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Right Glowing Orange Send Button (send-glow-btn)
              BouncingButton(
                onTap: _isSending || _isUploadingImage ? null : () => _sendMessage(),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFFA834),
                        Color(0xFFFF7700),
                        Color(0xFFFF5500),
                      ],
                      stops: [0.0, 0.55, 1.0],
                    ),
                    border: Border.all(color: const Color(0x80FFE1B9), width: 1.0),
                    boxShadow: [
                      const BoxShadow(
                        color: Color(0xB8FF7300),
                        blurRadius: 24,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.45),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isSending
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : RedesignIcons.send(
                            color: Colors.white,
                            size: 22,
                          ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Bottom Disclaimer
          Text(
            'AI can make mistakes. Please verify important information.',
            style: GoogleFonts.inter(
              color: const Color(0xFF8E857D),
              fontSize: 11.5,
              letterSpacing: -0.1,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CHAT MESSAGE COMPONENT (Pixel-perfect matching redesign/tech4all_ai_redesign.html)
// ============================================================================
class ChatMessage extends StatefulWidget {
  final bool isUser;
  final String message;
  final bool isLoading;
  final VoidCallback? onEdit;
  final String? imageUrl;
  final void Function(String message)? onShowToast;

  const ChatMessage({
    super.key,
    required this.isUser,
    required this.message,
    this.isLoading = false,
    this.onEdit,
    this.imageUrl,
    this.onShowToast,
  });

  @override
  State<ChatMessage> createState() => _ChatMessageState();
}

class _ChatMessageState extends State<ChatMessage> {
  bool _isLiked = false;
  bool _isCopied = false;

  void _copyResponse() {
    final thinkRegex = RegExp(r'<think>([\s\S]*?)(?:</think>|$)');
    final cleanText = widget.message.replaceAll(thinkRegex, '').trim();

    Clipboard.setData(ClipboardData(text: cleanText));
    setState(() => _isCopied = true);
    widget.onShowToast?.call('Response copied to clipboard');

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() => _isCopied = false);
      }
    });
  }

  void _toggleLike() {
    setState(() => _isLiked = !_isLiked);
    if (_isLiked) {
      widget.onShowToast?.call('Thanks for the feedback!');
    }
  }

  void _shareResponse() {
    final thinkRegex = RegExp(r'<think>([\s\S]*?)(?:</think>|$)');
    final cleanText = widget.message.replaceAll(thinkRegex, '').trim();

    try {
      html.window.navigator.share({
        'title': 'Tech4All AI Response',
        'text': cleanText,
      });
    } catch (_) {
      Clipboard.setData(ClipboardData(text: cleanText));
      widget.onShowToast?.call('Share link copied to clipboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isUser) {
      return _buildUserBubble();
    } else {
      return _buildAssistantRow();
    }
  }

  // --- USER MESSAGE BUBBLE ---
  Widget _buildUserBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 620),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(6),
                ),
                gradient: const LinearGradient(
                  colors: [
                    Color(0x40FF8C1A), // rgba(255, 140, 26, 0.25)
                    Color(0x4DFF6200), // rgba(255, 98, 0, 0.30)
                  ],
                ),
                border: Border.all(color: const Color(0x80FF9436), width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.imageUrl != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 220),
                          child: Image.network(
                            widget.imageUrl!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ],
                  Text(
                    widget.message,
                    style: GoogleFonts.inter(
                      fontSize: 15.5,
                      color: Colors.white,
                      height: 1.42,
                    ),
                  ),
                  if (widget.onEdit != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: BouncingButton(
                        onTap: widget.onEdit,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0x334E3C2E),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0x40FFC391)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.edit_note_rounded, size: 14, color: Colors.white70),
                              const SizedBox(width: 5),
                              Text(
                                'Edit',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- ASSISTANT MESSAGE CARD (assistant-card + ai-avatar-glow) ---
  Widget _buildAssistantRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sparkle Avatar Squircle (ai-avatar-glow)
          Container(
            width: 38,
            height: 38,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFA438),
                  Color(0xFFFF6A00),
                ],
              ),
              border: Border.all(color: const Color(0x8CFFE6C3), width: 1.0),
              boxShadow: [
                const BoxShadow(
                  color: Color(0xBFFF7300),
                  blurRadius: 22,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.45),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: RedesignIcons.aiSparkles(
                color: Colors.white,
                size: 21,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Main Assistant Response Card (assistant-card)
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const RadialGradient(
                  center: Alignment(-0.64, -0.64),
                  radius: 1.4,
                  colors: [
                    Color(0x7A6E523C), // rgba(110, 82, 60, 0.48)
                    Color(0xAD34261D), // rgba(52, 38, 29, 0.68)
                    Color(0xE0211812), // rgba(33, 24, 18, 0.88)
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
                border: Border.all(color: const Color(0xA6F58A30), width: 1.5),
                boxShadow: [
                  const BoxShadow(
                    color: Color(0x47FF7300),
                    blurRadius: 28,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 34,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.isLoading)
                    Row(
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Color(0xFFFF7A00),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          widget.message,
                          style: GoogleFonts.inter(
                            color: const Color(0xFFD8CFC8),
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    // Render Formatted Message Markdown without duplicate copy button
                    FormattedMessageView(
                      text: widget.message,
                      showCopyButton: false,
                    ),

                    const SizedBox(height: 16),

                    // Copy Response Button Row (card-inner-btn)
                    Align(
                      alignment: Alignment.centerRight,
                      child: BouncingButton(
                        onTap: _copyResponse,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0x8C4E3C2E), // rgba(78, 60, 46, 0.55)
                                Color(0xA632251C), // rgba(50, 37, 28, 0.65)
                              ],
                            ),
                            border: Border.all(
                              color: _isCopied
                                  ? Colors.greenAccent
                                  : const Color(0x38FFC391), // rgba(255, 195, 145, 0.22)
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.28),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _isCopied
                                  ? const Icon(
                                      Icons.check_circle_rounded,
                                      size: 16,
                                      color: Colors.greenAccent,
                                    )
                                  : RedesignIcons.copy(
                                      size: 16,
                                      color: const Color(0xFFFF9333),
                                    ),
                              const SizedBox(width: 8),
                              Text(
                                _isCopied ? 'Copied!' : 'Copy Response',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _isCopied ? Colors.greenAccent : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Bottom Right Action Icons (Thumbs Up & Share)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Thumbs Up
                        BouncingButton(
                          onTap: _toggleLike,
                          child: Container(
                            width: 38,
                            height: 36,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(11),
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0x8C4E3C2E),
                                  Color(0xA632251C),
                                ],
                              ),
                              border: Border.all(
                                color: _isLiked
                                    ? const Color(0xFFFF9838)
                                    : const Color(0x38FFC391),
                                width: 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.28),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: RedesignIcons.thumbUp(
                                size: 17,
                                isLiked: _isLiked,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Share Button
                        BouncingButton(
                          onTap: _shareResponse,
                          child: Container(
                            width: 38,
                            height: 36,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(11),
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0x8C4E3C2E),
                                  Color(0xA632251C),
                                ],
                              ),
                              border: Border.all(color: const Color(0x38FFC391), width: 1.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.28),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: RedesignIcons.share(
                                size: 17,
                                color: const Color(0xFFD8CFC8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// MICRO-INTERACTION WIDGETS (Bouncing Button & Fade-Slide Transition)
// ============================================================================
class BouncingButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const BouncingButton({super.key, required this.child, this.onTap});

  @override
  State<BouncingButton> createState() => _BouncingButtonState();
}

class _BouncingButtonState extends State<BouncingButton> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 130),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) _animController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      _animController.reverse();
      widget.onTap!();
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null) _animController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

class FadeSlideMessage extends StatefulWidget {
  final Widget child;
  const FadeSlideMessage({super.key, required this.child});

  @override
  State<FadeSlideMessage> createState() => _FadeSlideMessageState();
}

class _FadeSlideMessageState extends State<FadeSlideMessage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Cubic(0.16, 1.0, 0.3, 1.0),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Cubic(0.16, 1.0, 0.3, 1.0),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}
