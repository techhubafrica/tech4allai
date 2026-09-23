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

class SummarizerScreen extends StatefulWidget {
  const SummarizerScreen({super.key});

  @override
  State<SummarizerScreen> createState() => _SummarizerScreenState();
}

class _SummarizerScreenState extends State<SummarizerScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _customPromptController = TextEditingController();
  
  final HuggingFaceService _hfService = HuggingFaceService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  final ChatHistoryService _historyService = ChatHistoryService();

  String _selectedMode = 'Executive Summary';
  String _selectedLength = 'Medium';
  
  String? _summary;
  bool _isLoading = false;
  String? _activeSessionId;

  String? _attachedFileName;
  String? _attachedBase64Image;
  bool _isVisionDocument = false;

  final List<String> _modes = [
    'Executive Summary',
    'Comprehensive Breakdown',
    'Action Items & Decisions',
    'Custom Focus',
  ];

  final List<String> _lengths = [
    'Short',
    'Medium',
    'Detailed',
  ];

  @override
  void dispose() {
    _textController.dispose();
    _customPromptController.dispose();
    super.dispose();
  }

  void _pickDocumentOrImage() {
    final uploadInput = html.FileUploadInputElement();
    uploadInput.accept = '.txt,.md,.json,.csv,.pdf,.docx,image/*';
    uploadInput.click();

    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files == null || files.isEmpty) return;
      final file = files[0];
      final reader = html.FileReader();

      final isImage = file.type.startsWith('image/');

      if (isImage) {
        reader.readAsDataUrl(file);
        reader.onLoadEnd.listen((e) {
          if (mounted) {
            setState(() {
              _attachedFileName = file.name;
              _attachedBase64Image = reader.result as String;
              _isVisionDocument = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Attached scanned document image: ${file.name}'),
                backgroundColor: Colors.green,
              ),
            );
          }
        });
      } else {
        reader.readAsText(file);
        reader.onLoadEnd.listen((e) {
          if (mounted) {
            final content = reader.result as String? ?? '';
            setState(() {
              _attachedFileName = file.name;
              _textController.text = content;
              _isVisionDocument = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Loaded ${file.name} (${content.split(RegExp(r'\s+')).length} words)'),
                backgroundColor: Colors.green,
              ),
            );
          }
        });
      }
    });
  }

  Future<void> _summarizeText() async {
    if (_isLoading) return;

    final text = _textController.text.trim();
    if (text.isEmpty && _attachedBase64Image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please paste text or upload a document/image to summarize.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    // Instantly enter loading state on button tap (0ms latency)
    setState(() {
      _isLoading = true;
      _summary = null;
    });

    final canProceed = await _subscriptionService.checkAndIncrementTextUsage();
    if (!canProceed) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Daily request limit reached. Please upgrade your tier for more requests.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    try {
      String result = '';
      if (_isVisionDocument && _attachedBase64Image != null) {
        result = await _hfService.summarizeVisionDocument(
          _attachedBase64Image!,
          promptHint: _selectedMode == 'Custom Focus' ? _customPromptController.text.trim() : '',
          mode: _selectedMode,
          length: _selectedLength,
        );
      } else {
        result = await _hfService.summarizeText(
          text,
          mode: _selectedMode,
          length: _selectedLength,
          customPrompt: _selectedMode == 'Custom Focus' ? _customPromptController.text.trim() : '',
        );
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _summary = result;
        });

        _saveToHistory(text.isNotEmpty ? text : (_attachedFileName ?? 'Scanned Document'), result);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating summary: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _saveToHistory(String inputPreview, String summaryOutput) async {
    try {
      final cleanInput = inputPreview.replaceAll(RegExp(r'\s+'), ' ').trim();
      final firstLine = cleanInput.length > 35 ? '${cleanInput.substring(0, 35)}...' : cleanInput;
      final sessionTitle = 'Summary: $firstLine';

      if (_activeSessionId == null) {
        final session = await _historyService.createSession('summarizer', initialTitle: sessionTitle);
        _activeSessionId = session['id'];
      }

      final promptPayload = 'Mode: $_selectedMode | Length: $_selectedLength\n\n$inputPreview';

      await _historyService.addMessage(_activeSessionId!, isUser: true, message: promptPayload);
      await _historyService.addMessage(_activeSessionId!, isUser: false, message: summaryOutput);
    } catch (e) {
      print('Error saving summary to history: $e');
    }
  }

  Future<void> _loadSession(Map<String, dynamic> session) async {
    setState(() {
      _activeSessionId = session['id'];
      _isLoading = true;
    });

    try {
      final messages = await _historyService.getMessages(session['id']);
      if (mounted && messages.isNotEmpty) {
        final aiMessage = messages.lastWhere(
          (m) => (m['is_user'] == false || m['isUser'] == false),
          orElse: () => messages.last,
        );
        final userMessage = messages.firstWhere(
          (m) => (m['is_user'] == true || m['isUser'] == true),
          orElse: () => messages.first,
        );

        setState(() {
          _summary = aiMessage['message'] ?? aiMessage['content'] ?? '';
          _textController.text = ((userMessage['message'] ?? userMessage['content'] ?? '') as String).replaceAll(RegExp(r'^Mode:.*?\n\n'), '');
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _copySummary() {
    if (_summary == null) return;
    Clipboard.setData(ClipboardData(text: _summary!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Summary copied to clipboard!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _downloadSummary() {
    if (_summary == null) return;
    final blob = html.Blob([_summary!], 'text/plain;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'summary_${DateTime.now().millisecondsSinceEpoch}.md')
      ..click();
    html.Url.revokeObjectUrl(url);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Downloaded summary as Markdown file!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(
          'AI Summarizer',
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
                icon: const Icon(Icons.history, size: 18, color: AppColors.primary),
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
        featureType: 'summarizer',
        activeSessionId: _activeSessionId,
        onSessionSelected: (session) {
          _loadSession(session);
        },
        onNewChatStarted: () {
          setState(() {
            _activeSessionId = null;
            _summary = null;
            _textController.clear();
            _attachedFileName = null;
            _attachedBase64Image = null;
            _isVisionDocument = false;
          });
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Upload Area
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.neutralSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.neutralBorder),
              ),
              child: Column(
                children: [
                  const Icon(Icons.cloud_upload_outlined, size: 44, color: AppColors.primary),
                  const SizedBox(height: 12),
                  Text(
                    'Upload Document or Image',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Supports .TXT, .MD, .JSON, .CSV & Scanned Images (OCR)',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.neutralTextMuted,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (_attachedFileName != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isVisionDocument ? Icons.image : Icons.description,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _attachedFileName!,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                            onPressed: () {
                              setState(() {
                                _attachedFileName = null;
                                _attachedBase64Image = null;
                                _isVisionDocument = false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppColors.primary.withOpacity(0.08),
                      ),
                      onPressed: _pickDocumentOrImage,
                      icon: const Icon(Icons.folder_open, color: AppColors.primary, size: 20),
                      label: Text(
                        'Browse Files',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Divider
            Row(
              children: [
                Expanded(child: Divider(color: AppColors.neutralBorder)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR PASTE TEXT',
                    style: GoogleFonts.inter(
                      color: AppColors.neutralTextMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: AppColors.neutralBorder)),
              ],
            ),
            const SizedBox(height: 20),

            // Text Input Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.neutralSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.neutralBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _textController,
                    maxLines: 7,
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 14, height: 1.5),
                    decoration: InputDecoration(
                      hintText: 'Paste text or article content here to summarize...',
                      hintStyle: GoogleFonts.inter(color: AppColors.neutralTextMuted, fontSize: 14),
                      border: InputBorder.none,
                    ),
                  ),
                  const Divider(color: AppColors.neutralBorder),
                  const SizedBox(height: 6),
                  // Word & Character counter
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_textController.text.trim().isEmpty ? 0 : _textController.text.trim().split(RegExp(r'\s+')).length} words • ${_textController.text.length} characters',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.neutralTextMuted),
                      ),
                      if (_textController.text.isNotEmpty || _attachedFileName != null)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _textController.clear();
                              _attachedFileName = null;
                              _attachedBase64Image = null;
                              _isVisionDocument = false;
                            });
                          },
                          child: Text(
                            'Clear',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Mode Selection Section
            Text(
              'Summary Mode',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _modes.map((mode) {
                final isSelected = _selectedMode == mode;
                return ChoiceChip(
                  label: Text(mode),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedMode = mode);
                  },
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.neutralSurface,
                  labelStyle: GoogleFonts.inter(
                    color: isSelected ? Colors.white : AppColors.neutralTextMuted,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.neutralBorder,
                    ),
                  ),
                );
              }).toList(),
            ),

            if (_selectedMode == 'Custom Focus') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customPromptController,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g. Focus on financial statistics and key dates only...',
                  hintStyle: GoogleFonts.inter(color: AppColors.neutralTextMuted, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.neutralSurface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.neutralBorder),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Length Selection Section
            Text(
              'Summary Length',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: _lengths.map((len) {
                final isSelected = _selectedLength == len;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isSelected ? AppColors.primary.withOpacity(0.18) : AppColors.neutralSurface,
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : AppColors.neutralBorder,
                          width: isSelected ? 2.0 : 1.0,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => setState(() => _selectedLength = len),
                      child: Text(
                        len,
                        style: GoogleFonts.inter(
                          color: isSelected ? Colors.white : AppColors.neutralTextMuted,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _summarizeText,
                child: _isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Synthesizing Summary...',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'Summarize Document',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),

            // Results Output Area
            if (_summary != null) ...[
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.neutralSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withOpacity(0.6), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome, color: AppColors.primary, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'Summary Output',
                              style: GoogleFonts.inter(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.copy, color: Colors.white70, size: 20),
                              tooltip: 'Copy Summary',
                              onPressed: _copySummary,
                            ),
                            IconButton(
                              icon: const Icon(Icons.download, color: Colors.white70, size: 20),
                              tooltip: 'Download Markdown',
                              onPressed: _downloadSummary,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.neutralBorder),
                    const SizedBox(height: 12),
                    FormattedMessageView(
                      text: _summary!,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
