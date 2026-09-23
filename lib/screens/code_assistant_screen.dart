import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:universal_html/html.dart' as html;
import '../constants/colors.dart';
import '../services/hugging_face_service.dart';
import '../services/subscription_service.dart';
import '../services/chat_history_service.dart';
import '../widgets/chat_history_drawer.dart';
import '../widgets/formatted_message_view.dart';

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

  String _selectedMode = 'Write & Generate';
  String _selectedLanguage = 'All Languages';

  String? _attachedFileName;
  String? _attachedCodeSnippet;
  int _attachedLineCount = 0;

  String? _activeSessionId;
  bool _isSending = false;

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
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Attached ${file.name} ($lines lines of code)'),
              backgroundColor: Colors.green,
            ),
          );
        }
      });
    });
  }

  Future<void> _sendMessage() async {
    if (_isSending) return;

    final userPrompt = _promptController.text.trim();
    if (userPrompt.isEmpty && _attachedCodeSnippet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a coding request or attach a code file.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    final promptText = userPrompt.isNotEmpty
        ? userPrompt
        : 'Please analyze the attached code file: ${_attachedFileName ?? "code snippet"}';

    // 1. INSTANT 0-LAG UI insertion
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

    // 2. Subscription Limit Check
    final canProceed = await _subscriptionService.checkAndIncrementTextUsage();
    if (!canProceed) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Daily request limit reached. Please upgrade your tier for more requests.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    // 3. Call AI Code Model
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
          // Clear attachment after sending
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating code response: $e'), backgroundColor: Colors.redAccent),
        );
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
    } catch (e) {
      print('Error saving code session to history: $e');
    }
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
    } catch (e) {
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
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(
          'AI Code Assistant',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Builder(
            builder: (context) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: OutlinedButton.icon(
                onPressed: () => Scaffold.of(context).openDrawer(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.neutralBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  backgroundColor: AppColors.neutralSurface,
                ),
                icon: const Icon(Icons.history, size: 18, color: Colors.cyanAccent),
                label: Text(
                  'History',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: ChatHistoryDrawer(
        featureType: 'code_assistant',
        activeSessionId: _activeSessionId,
        onSessionSelected: (session) {
          _loadSession(session);
        },
        onNewChatStarted: () {
          setState(() {
            _activeSessionId = null;
            _messages.clear();
            _messages.add({
              'isUser': false,
              'message': 'Started a new coding thread. What code shall we write or debug?',
              'isLoading': false,
            });
            _promptController.clear();
            _attachedFileName = null;
            _attachedCodeSnippet = null;
            _attachedLineCount = 0;
          });
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Mode & Language Controls Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: AppColors.neutralSurface,
                border: Border(bottom: BorderSide(color: AppColors.neutralBorder)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Task Mode Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _modes.map((mode) {
                        final isSelected = _selectedMode == mode;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(mode),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) setState(() => _selectedMode = mode);
                            },
                            selectedColor: Colors.cyanAccent.withOpacity(0.25),
                            backgroundColor: AppColors.backgroundDark,
                            labelStyle: GoogleFonts.inter(
                              color: isSelected ? Colors.cyanAccent : AppColors.neutralTextMuted,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isSelected ? Colors.cyanAccent : AppColors.neutralBorder,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Language Filter Chips
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
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary.withOpacity(0.18) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.neutralBorder,
                                ),
                              ),
                              child: Text(
                                lang,
                                style: GoogleFonts.sourceCodePro(
                                  fontSize: 11,
                                  color: isSelected ? Colors.white : AppColors.neutralTextMuted,
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

            // Chat & Code Stream
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length + (_isSending ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isSending) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.cyanAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.code, color: Colors.cyanAccent, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Writing code...',
                            style: GoogleFonts.sourceCodePro(color: AppColors.neutralTextMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }

                  final msg = _messages[index];
                  final isUser = msg['isUser'] as bool;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: [
                        if (!isUser) ...[
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.cyanAccent.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.cyanAccent.withOpacity(0.4)),
                            ),
                            child: const Icon(Icons.code, color: Colors.cyanAccent, size: 18),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isUser ? AppColors.neutralSurface : const Color(0xFF16120E),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isUser ? AppColors.neutralBorder : Colors.cyanAccent.withOpacity(0.3),
                              ),
                            ),
                            child: isUser
                                ? Text(
                                    msg['message'] ?? '',
                                    style: GoogleFonts.sourceCodePro(
                                      color: Colors.white,
                                      fontSize: 13,
                                      height: 1.5,
                                    ),
                                  )
                                : FormattedMessageView(
                                    text: msg['message'] ?? '',
                                  ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Attached File Badge
            if (_attachedFileName != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.neutralSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.insert_drive_file, color: Colors.cyanAccent, size: 18),
                    const SizedBox(width: 8),
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
                      child: const Icon(Icons.close, color: Colors.white70, size: 16),
                    ),
                  ],
                ),
              ),

            // Bottom Code Input Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.backgroundDark,
                border: Border(top: BorderSide(color: AppColors.neutralBorder)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file, color: Colors.cyanAccent, size: 22),
                    tooltip: 'Attach Code File',
                    onPressed: _pickCodeFile,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.neutralSurface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.neutralBorder),
                      ),
                      child: TextField(
                        controller: _promptController,
                        style: GoogleFonts.sourceCodePro(color: Colors.white, fontSize: 13),
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: 'Ask or paste code ($_selectedMode)...',
                          hintStyle: GoogleFonts.inter(color: AppColors.neutralTextMuted, fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _isSending ? null : _sendMessage,
                    child: CircleAvatar(
                      backgroundColor: _isSending ? AppColors.neutralBorder : Colors.cyanAccent,
                      radius: 20,
                      child: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.arrow_upward, color: Colors.black, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
