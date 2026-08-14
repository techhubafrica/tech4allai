import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../services/hugging_face_service.dart';
import '../widgets/under_development_overlay.dart';

class CodeAssistantScreen extends StatefulWidget {
  const CodeAssistantScreen({super.key});

  @override
  State<CodeAssistantScreen> createState() => _CodeAssistantScreenState();
}

class _CodeAssistantScreenState extends State<CodeAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final HuggingFaceService _hfService = HuggingFaceService();
  final ScrollController _scrollController = ScrollController();
  
  final List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'message': 'Hello Developer! I can help you write, debug, and explain code. What are you working on?',
      'isLoading': false,
    }
  ];

  bool _isTyping = false;

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'isUser': true,
        'message': text,
        'isLoading': false,
      });
      _isTyping = true;
      _controller.clear();
    });
    
    _scrollToBottom();

    // Call API with StarCoder model
    // We might want to prepend a system prompt if the model supports it well, or just send the code request.
    // StarCoder is good at completion. Let's try to frame it as a question/answer interactions.
    // "Question: $text\nAnswer:"
    final prompt = "Question: $text\nAnswer:";
    final response = await _hfService.generateText(prompt, HuggingFaceService.modelCode);

    if (mounted) {
      setState(() {
        _isTyping = false;
        _messages.add({
          'isUser': false,
          'message': response,
          'isLoading': false,
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(
          'Code Assistant',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: UnderDevelopmentOverlay(
        child: SafeArea(
          child: Column(
            children: [
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
                      message: "Coding...",
                      isLoading: true,
                    );
                  }
                  final msg = _messages[index];
                  return ChatMessage(
                    isUser: msg['isUser'],
                    message: msg['message'],
                    isLoading: msg['isLoading'] ?? false,
                  );
                },
              ),
            ),
            
            // Input Area
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.backgroundDark, 
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.neutralSurface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.neutralBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.neutralBorder.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.code, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                             controller: _controller,
                             style: GoogleFonts.sourceCodePro(color: Colors.white, fontSize: 13),
                             decoration: InputDecoration(
                               hintText: 'Ask about code...',
                               hintStyle: GoogleFonts.inter(color: AppColors.neutralTextMuted),
                               border: InputBorder.none,
                               isDense: true,
                             ),
                             onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _sendMessage,
                          child: const CircleAvatar(
                            backgroundColor: AppColors.primary,
                            radius: 18,
                            child: Icon(Icons.arrow_upward, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  const ChatMessage({
    super.key,
    required this.isUser,
    required this.message,
    this.isLoading = false,
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
                    color: Colors.cyanAccent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(Icons.code, color: Colors.black, size: 16),
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
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent)
                            ),
                            const SizedBox(width: 12),
                            Text(
                              message, 
                              style: GoogleFonts.inter(color: AppColors.neutralTextMuted)
                            ),
                          ],
                        )
                      else
                        Text(
                          message,
                          style: GoogleFonts.sourceCodePro( // Use monospaced font for code
                            color: Colors.white,
                            height: 1.5,
                            fontSize: 14,
                          ),
                        ),
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
