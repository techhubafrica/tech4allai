import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:universal_html/html.dart' as html;
import '../services/hugging_face_service.dart';
import '../services/subscription_service.dart';
import '../services/chat_history_service.dart';
import '../widgets/chat_history_drawer.dart';
import '../widgets/formatted_message_view.dart';
import '../widgets/upgrade_prompt_dialog.dart';
import '../widgets/redesign_icons.dart';
import 'tools_hub_screen.dart';

class CodeAssistantScreen extends StatefulWidget {
  const CodeAssistantScreen({super.key});

  @override
  State<CodeAssistantScreen> createState() => _CodeAssistantScreenState();
}

class _CodeAssistantScreenState extends State<CodeAssistantScreen> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final HuggingFaceService _hfService = HuggingFaceService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  final ChatHistoryService _historyService = ChatHistoryService();

  String _userTier = 'FREE';
  int _textRequestsToday = 0;
  int _textRequestsLimit = 5;
  bool _isLoadingLimitInfo = true;

  String _selectedMode = 'Write & Generate';
  String _selectedLanguage = 'All Languages';

  String? _attachedFileName;
  String? _attachedCodeSnippet;
  int _attachedLineCount = 0;

  String? _activeSessionId;
  bool _isSending = false;

  String? _toastMessage;
  bool _isToastError = false;
  Timer? _toastTimer;

  final List<String> _modes = [
    'Write & Generate',
    'Debug & Fix',
    'Explain & Document',
    'Refactor & Optimize',
  ];

  final List<String> _languages = [
    'All Languages',
    'Dart / Flutter',
    'Python',
    'JS / TS',
    'HTML / CSS',
    'SQL',
    'C++ / C#',
    'Java / Kotlin',
  ];

  final List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'message': 'Hello Developer! I am your AI Code Assistant. Select a task mode or attach a code file, and ask me to write, debug, explain, or refactor code.',
      'isLoading': false,
    }
  ];

  @override
  void initState() {
    super.initState();
    _refreshLimitInfo();
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showNotification(String message, {bool isError = false}) {
    _toastTimer?.cancel();
    setState(() {
      _toastMessage = message;
      _isToastError = isError;
    });
    _toastTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() => _toastMessage = null);
      }
    });
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
        } else if (_userTier == 'SUPERADMIN') {
          _textRequestsLimit = 999999;
        } else {
          _textRequestsLimit = 5;
        }
        _isLoadingLimitInfo = false;
      });
    }
  }

  void _pickCodeFile() {
    final uploadInput = html.FileUploadInputElement();
    uploadInput.accept = '.dart,.py,.js,.ts,.html,.css,.json,.sql,.cpp,.c,.cs,.java,.kt,.txt';
    uploadInput.click();

    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files == null || files.isEmpty) return;
      final file = files[0];
      final reader = html.FileReader();

      reader.readAsText(file);
      reader.onLoadEnd.listen((e) {
        if (mounted) {
          final content = reader.result as String? ?? '';
          final lines = content.split('\n').length;
          setState(() {
            _attachedFileName = file.name;
            _attachedCodeSnippet = content;
            _attachedLineCount = lines;
          });
          _showNotification('Attached ${file.name} ($lines lines)');
        }
      });
    });
  }

  Future<void> _sendMessage() async {
    if (_isSending) return;

    final userPrompt = _promptController.text.trim();
    if (userPrompt.isEmpty && _attachedCodeSnippet == null) {
      _showNotification('Please enter a coding request or attach code', isError: true);
      return;
    }

    final promptText = userPrompt.isNotEmpty
        ? userPrompt
        : 'Please analyze the attached code file: ${_attachedFileName ?? "code snippet"}';

    setState(() {
      _messages.add({
        'isUser': true,
        'message': promptText + (_attachedFileName != null ? '\n\n[Attached: $_attachedFileName ($_attachedLineCount lines)]' : ''),
        'isLoading': false,
      });
      _isSending = true;
      _promptController.clear();
    });

    _scrollToBottom();

    final canProceed = await _subscriptionService.checkAndIncrementTextUsage();
    if (!canProceed && _userTier != 'SUPERADMIN') {
      if (mounted) {
        setState(() {
          _isSending = false;
          if (_messages.isNotEmpty && _messages.last['isUser'] == true) {
            _messages.removeLast();
          }
          _promptController.text = userPrompt;
        });
        UpgradePromptDialog.show(
          context,
          title: "Daily Limit Reached",
          message: "You have completed your daily quota of requests on the $_userTier tier. Upgrade to BASIC or PRO to unlock high-capacity models and faster responses!",
        );
      }
      return;
    }
    _refreshLimitInfo();

    try {
      final response = await _hfService.generateCodeAssistantResponse(
        promptText,
        codeSnippet: _attachedCodeSnippet,
        mode: _selectedMode,
        language: _selectedLanguage,
      );

      if (mounted) {
        setState(() {
          _isSending = false;
          _messages.add({
            'isUser': false,
            'message': response,
            'isLoading': false,
          });
          _attachedFileName = null;
          _attachedCodeSnippet = null;
          _attachedLineCount = 0;
        });

        _scrollToBottom();
        _saveToHistory(promptText, response);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        _showNotification('Error generating code response', isError: true);
      }
    }
  }

  Future<void> _saveToHistory(String userPrompt, String aiResponse) async {
    try {
      final cleanPrompt = userPrompt.replaceAll(RegExp(r'\s+'), ' ').trim();
      final firstLine = cleanPrompt.length > 35 ? '${cleanPrompt.substring(0, 35)}...' : cleanPrompt;
      final sessionTitle = 'Code ($_selectedMode): $firstLine';

      if (_activeSessionId == null) {
        final session = await _historyService.createSession('code_assistant', initialTitle: sessionTitle);
        if (mounted) {
          setState(() {
            _activeSessionId = session['id'];
          });
        }
      }

      final modeHeader = 'Mode: $_selectedMode | Language: $_selectedLanguage\n\n$userPrompt';
      await _historyService.addMessage(_activeSessionId!, isUser: true, message: modeHeader);
      await _historyService.addMessage(_activeSessionId!, isUser: false, message: aiResponse);
    } catch (_) {}
  }

  Future<void> _loadSession(Map<String, dynamic> session) async {
    setState(() {
      _activeSessionId = session['id'];
      _isSending = true;
    });

    try {
      final dbMessages = await _historyService.getMessages(session['id']);
      if (mounted) {
        final loadedMessages = dbMessages.map((m) {
          final isUser = (m['is_user'] == true || m['isUser'] == true);
          final rawText = (m['message'] ?? m['content'] ?? '') as String;
          final cleanText = isUser ? rawText.replaceAll(RegExp(r'^Mode:.*?\n\n'), '') : rawText;
          return {
            'isUser': isUser,
            'message': cleanText,
            'isLoading': false,
          };
        }).toList();

        setState(() {
          _messages.clear();
          if (loadedMessages.isEmpty) {
            _messages.add({
              'isUser': false,
              'message': 'Loaded thread "${session['title']}". Ask any coding question!',
              'isLoading': false,
            });
          } else {
            _messages.addAll(loadedMessages);
          }
          _isSending = false;
        });

        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _isSending = false);
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A06),
      drawer: ChatHistoryDrawer(
        featureType: 'code_assistant',
        activeSessionId: _activeSessionId,
        onSessionSelected: (session) => _loadSession(session),
        onNewChatStarted: () {
          setState(() {
            _activeSessionId = null;
            _messages.clear();
            _messages.add({
              'isUser': false,
              'message': 'Started a new coding thread. What code shall we write, debug, or refactor?',
              'isLoading': false,
            });
            _promptController.clear();
            _attachedFileName = null;
            _attachedCodeSnippet = null;
            _attachedLineCount = 0;
          });
        },
      ),
      body: Stack(
        children: [
          // Top Ambient Glow Orb
          Positioned(
            top: -120,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 620,
                height: 400,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0x38FF7300),
                      Color(0x14FF7300),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 1. TOP HEADER BAR
                _buildHeaderBar(),

                // 2. CONTROLS BAR: Task Mode & Language Filter
                _buildControlsHeader(),

                // 3. CHAT MESSAGES STREAM
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 960),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _messages.length + (_isSending ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length && _isSending) {
                            return _buildTypingIndicator();
                          }
                          final msg = _messages[index];
                          return _buildMessageRow(msg);
                        },
                      ),
                    ),
                  ),
                ),

                // 4. ATTACHED FILE BANNER
                if (_attachedFileName != null) _buildAttachedFileBanner(),

                // 5. BOTTOM COMPOSER BAR
                _buildComposerBar(),
              ],
            ),
          ),

          // 6. FLOATING TOAST NOTIFICATION
          if (_toastMessage != null)
            Positioned(
              top: 18,
              left: 20,
              right: 20,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: _isToastError ? const Color(0xFF1E0E0A) : const Color(0xFF1C130D),
                    border: Border.all(
                      color: _isToastError ? const Color(0x80FF3B30) : const Color(0x66FF9233),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _isToastError ? const Color(0x40FF3B30) : const Color(0x38FF7300),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(7),
                          gradient: LinearGradient(
                            colors: _isToastError
                                ? [const Color(0xFFFF5252), const Color(0xFFD32F2F)]
                                : [const Color(0xFFFFA438), const Color(0xFFFF6A00)],
                          ),
                        ),
                        child: Center(
                          child: _isToastError
                              ? RedesignIcons.close(size: 13, color: Colors.white)
                              : RedesignIcons.aiSparkles(size: 13, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          _toastMessage!,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildHeaderBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          _CodeBounceButton(
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
                  colors: [Color(0xA640362F), Color(0xA6261F1A)],
                ),
                border: Border.all(color: const Color(0x24FFFFFF), width: 1.0),
              ),
              child: Center(
                child: RedesignIcons.arrowBack(size: 21, color: Colors.white),
              ),
            ),
          ),

          // Center Title with Squircle Code Badge
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF26C6DA), Color(0xFF0097A7)],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x6600BCD4),
                      blurRadius: 12,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: RedesignIcons.toolCode(size: 17, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'AI Code Assistant',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          // History Button
          Builder(
            builder: (context) => _CodeBounceButton(
              onTap: () => Scaffold.of(context).openDrawer(),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xA640362F), Color(0xA6261F1A)],
                  ),
                  border: Border.all(color: const Color(0x24FFFFFF), width: 1.0),
                ),
                child: Row(
                  children: [
                    RedesignIcons.history(size: 16, color: const Color(0xFFD4CFC9)),
                    const SizedBox(width: 6),
                    Text(
                      'History',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF19110B).withValues(alpha: 0.6),
        border: const Border(
          bottom: BorderSide(color: Color(0x1FFFFFFF), width: 1.0),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_isLoadingLimitInfo)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF26C6DA),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Plan: $_userTier',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFFC7BEB4),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _userTier == 'SUPERADMIN'
                            ? 'Daily: Unlimited'
                            : 'Daily: $_textRequestsToday / $_textRequestsLimit queries',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: _textRequestsToday >= _textRequestsLimit
                              ? const Color(0xFFFF5252)
                              : const Color(0xFF8E857D),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              // Mode Choice Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _modes.map((mode) {
                    final isSelected = _selectedMode == mode;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: _CodeBounceButton(
                        onTap: () => setState(() => _selectedMode = mode),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: isSelected ? const Color(0x2BFF7300) : const Color(0xFF140D08),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFFF7A00) : const Color(0x26FFFFFF),
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            mode,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? const Color(0xFFFF9233) : const Color(0xFFBEB8B2),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 6),

              // Language Choice Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _languages.map((lang) {
                    final isSelected = _selectedLanguage == lang;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedLanguage = lang),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: isSelected ? const Color(0x1F26C6DA) : Colors.transparent,
                            border: Border.all(
                              color: isSelected ? const Color(0x8026C6DA) : const Color(0x14FFFFFF),
                              width: 0.9,
                            ),
                          ),
                          child: Text(
                            lang,
                            style: GoogleFonts.sourceCodePro(
                              fontSize: 11,
                              color: isSelected ? const Color(0xFF26C6DA) : const Color(0xFF8E857D),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              gradient: const LinearGradient(
                colors: [Color(0xFF26C6DA), Color(0xFF0097A7)],
              ),
            ),
            child: Center(
              child: RedesignIcons.toolCode(size: 18, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A120B).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x26FF7300), width: 1.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF7A00)),
                ),
                const SizedBox(width: 10),
                Text(
                  'Synthesizing code...',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFB5ACA2),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageRow(Map<String, dynamic> msg) {
    final isUser = msg['isUser'] as bool;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                gradient: const LinearGradient(
                  colors: [Color(0xFF26C6DA), Color(0xFF0097A7)],
                ),
                boxShadow: const [
                  BoxShadow(color: Color(0x4D00BCD4), blurRadius: 10),
                ],
              ),
              child: Center(
                child: RedesignIcons.toolCode(size: 18, color: Colors.white),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF2A1C12).withValues(alpha: 0.85)
                    : const Color(0xFF1A120B).withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isUser ? const Color(0x4DFF7300) : const Color(0x28FFFFFF),
                  width: 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isUser)
                    SelectableText(
                      msg['message'] ?? '',
                      style: GoogleFonts.sourceCodePro(
                        color: Colors.white,
                        fontSize: 13.5,
                        height: 1.5,
                      ),
                    )
                  else
                    FormattedMessageView(
                      text: msg['message'] ?? '',
                    ),
                  if (isUser) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _CodeBounceButton(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: msg['message'] ?? ''));
                          _showNotification('Prompt copied to clipboard');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: const Color(0x1AFFFFFF),
                            border: Border.all(color: const Color(0x21FFFFFF), width: 0.9),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              RedesignIcons.copy(size: 12, color: const Color(0xFFFF9233)),
                              const SizedBox(width: 4),
                              Text(
                                'Copy',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFFD4CFC9),
                                  fontWeight: FontWeight.w600,
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

  Widget _buildAttachedFileBanner() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E140C),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x66FF7300), width: 1.0),
          ),
          child: Row(
            children: [
              RedesignIcons.toolCode(size: 18, color: const Color(0xFFFF9233)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Attached: $_attachedFileName ($_attachedLineCount lines)',
                  style: GoogleFonts.sourceCodePro(color: Colors.white, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _attachedFileName = null;
                    _attachedCodeSnippet = null;
                    _attachedLineCount = 0;
                  });
                },
                child: RedesignIcons.close(size: 16, color: const Color(0xFF8E857D)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComposerBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0A06),
        border: Border(top: BorderSide(color: Color(0x1AFFFFFF), width: 1.0)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Row(
            children: [
              // Attach File Action
              _CodeBounceButton(
                onTap: _pickCodeFile,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xA640362F), Color(0xA6261F1A)],
                    ),
                    border: Border.all(color: const Color(0x24FFFFFF), width: 1.0),
                  ),
                  child: Center(
                    child: RedesignIcons.toolCode(size: 19, color: const Color(0xFFD4CFC9)),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Code Request Input Field
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A120B),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0x26FFFFFF), width: 1.0),
                  ),
                  child: TextField(
                    controller: _promptController,
                    style: GoogleFonts.sourceCodePro(color: Colors.white, fontSize: 13),
                    maxLines: 4,
                    minLines: 1,
                    cursorColor: const Color(0xFFFF7A00),
                    decoration: InputDecoration(
                      hintText: 'Ask or paste code ($_selectedMode)...',
                      hintStyle: GoogleFonts.inter(color: const Color(0xFF756C64), fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Send Action Button
              _CodeBounceButton(
                onTap: _isSending ? null : _sendMessage,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFA438), Color(0xFFFF6A00)],
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66FF7300),
                        blurRadius: 16,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : RedesignIcons.send(size: 20, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CodeBounceButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _CodeBounceButton({required this.child, this.onTap});

  @override
  State<_CodeBounceButton> createState() => _CodeBounceButtonState();
}

class _CodeBounceButtonState extends State<_CodeBounceButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 130),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic, reverseCurve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
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
