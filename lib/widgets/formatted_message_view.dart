import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';

class FormattedMessageView extends StatefulWidget {
  final String text;

  const FormattedMessageView({super.key, required this.text});

  @override
  State<FormattedMessageView> createState() => _FormattedMessageViewState();
}

class _FormattedMessageViewState extends State<FormattedMessageView> {
  bool _isThinkingExpanded = false;

  @override
  Widget build(BuildContext context) {
    // 1. Parse thinking process (<think>...</think>)
    final thinkRegex = RegExp(r'<think>([\s\S]*?)(?:</think>|$)');
    final match = thinkRegex.firstMatch(widget.text);

    String? thinkingContent;
    String mainResponseContent = widget.text;

    if (match != null) {
      thinkingContent = match.group(1)?.trim();
      // Remove the think block from main response
      mainResponseContent = widget.text.replaceAll(thinkRegex, '').trim();
    }

    // Colors aligned with AppColors
    const primaryColor = Color(0xFFFF6F00); // AppColors.primary
    const surfaceColor = Color(0xFF2D241D); // AppColors.neutralSurface
    const borderColor = Color(0xFF3D3228); // AppColors.neutralBorder
    const textMutedColor = Color(0xFF9E9E9E); // AppColors.neutralTextMuted

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Collapsible Thinking Block
        if (thinkingContent != null && thinkingContent.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: surfaceColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      _isThinkingExpanded = !_isThinkingExpanded;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.psychology_outlined,
                          color: primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Thought Process',
                            style: GoogleFonts.inter(
                              color: textMutedColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          _isThinkingExpanded ? Icons.expand_less : Icons.expand_more,
                          color: textMutedColor,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isThinkingExpanded) ...[
                  const Divider(color: borderColor, height: 1),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      thinkingContent,
                      style: GoogleFonts.firaCode(
                        color: textMutedColor.withOpacity(0.8),
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],

        // Main Response (rendered using MarkdownBody)
        if (mainResponseContent.isNotEmpty)
          MarkdownBody(
            data: mainResponseContent,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              p: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 15,
                height: 1.5,
              ),
              h1: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.6,
              ),
              h2: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
                height: 1.5,
              ),
              h3: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
              strong: GoogleFonts.inter(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
              em: const TextStyle(
                fontStyle: FontStyle.italic,
              ),
              blockquote: GoogleFonts.inter(
                color: textMutedColor,
                fontStyle: FontStyle.italic,
              ),
              blockquoteDecoration: BoxDecoration(
                color: surfaceColor.withOpacity(0.3),
                border: const Border(
                  left: BorderSide(color: primaryColor, width: 4),
                ),
              ),
              listBullet: GoogleFonts.inter(
                color: primaryColor,
                fontSize: 15,
              ),
              code: GoogleFonts.firaCode(
                color: primaryColor,
                backgroundColor: surfaceColor,
                fontSize: 13,
              ),
              codeblockPadding: const EdgeInsets.all(12),
              codeblockDecoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
            ),
            builders: {
              'code': CodeBlockBuilder(),
            },
          ),
      ],
    );
  }
}

/// Custom builder to render copy-able code blocks
class CodeBlockBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(dynamic element, TextStyle? preferredStyle) {
    final String textContent = element.textContent.trim();
    
    // Check if it's a multiline block
    if (textContent.contains('\n')) {
      return Builder(
        builder: (context) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2D241D), // AppColors.neutralSurface
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF3D3228)), // AppColors.neutralBorder
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E1712), // Darker header
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Code block',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF9E9E9E),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 16, color: Color(0xFFFF6F00)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: textContent));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Code copied to clipboard!'),
                              duration: Duration(seconds: 2),
                              backgroundColor: Color(0xFFFF6F00),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Code content
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(
                    textContent,
                    style: GoogleFonts.firaCode(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      );
    }
    
    // Inline code fallback (default rendering)
    return null;
  }
}
