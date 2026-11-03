import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:universal_html/html.dart' as html;
import '../services/hugging_face_service.dart';
import '../services/subscription_service.dart';
import '../services/chat_history_service.dart';
import '../widgets/chat_history_drawer.dart';
import '../widgets/formatted_message_view.dart';
import '../widgets/redesign_icons.dart';

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

  void _showNotification(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        duration: const Duration(seconds: 3),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFA1E140C),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isError ? const Color(0x66FF3B30) : const Color(0x66FF8A24),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: (isError ? const Color(0xFFFF3B30) : const Color(0xFFFF8A24)).withOpacity(0.2),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isError ? const Color(0x33FF3B30) : const Color(0x33FF8A24),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: isError
                      ? RedesignIcons.alertCircle(size: 16, color: Colors.redAccent)
                      : RedesignIcons.check(size: 16, color: const Color(0xFFFF8A24)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
            _showNotification('Attached scanned document: ${file.name}');
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
            _showNotification('Loaded ${file.name} (${content.split(RegExp(r'\s+')).length} words)');
          }
        });
      }
    });
  }

  Future<void> _summarizeText() async {
    if (_isLoading) return;

    final text = _textController.text.trim();
    if (text.isEmpty && _attachedBase64Image == null) {
      _showNotification('Please paste text or upload a document/image to summarize.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _summary = null;
    });

    final canProceed = await _subscriptionService.checkAndIncrementTextUsage();
    if (!canProceed) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showNotification('Daily request limit reached. Upgrade tier for unlimited access.', isError: true);
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
        _showNotification('Error generating summary: $e', isError: true);
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
          _textController.text = ((userMessage['message'] ?? userMessage['content'] ?? '') as String)
              .replaceAll(RegExp(r'^Mode:.*?\n\n'), '');
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
    _showNotification('Summary copied to clipboard!');
  }

  void _downloadSummary() {
    if (_summary == null) return;
    final blob = html.Blob([_summary!], 'text/plain;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'summary_${DateTime.now().millisecondsSinceEpoch}.md')
      ..click();
    html.Url.revokeObjectUrl(url);
    _showNotification('Downloaded summary as Markdown file!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A06),
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
      body: Stack(
        children: [
          // Ambient Radial Background
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.6),
                  radius: 1.1,
                  colors: const [
                    Color(0xFF28180D),
                    Color(0xFF0F0A06),
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),

          // Lighting Orb
          Positioned(
            top: -120,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 360,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFF8A24).withOpacity(0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 820),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildUploadCard(),
                            const SizedBox(height: 18),
                            _buildDivider(),
                            const SizedBox(height: 18),
                            _buildTextInputCard(),
                            const SizedBox(height: 24),
                            _buildModeSelector(),
                            if (_selectedMode == 'Custom Focus') ...[
                              const SizedBox(height: 12),
                              _buildCustomFocusField(),
                            ],
                            const SizedBox(height: 22),
                            _buildLengthSelector(),
                            const SizedBox(height: 28),
                            _buildActionCTA(),
                            if (_summary != null) ...[
                              const SizedBox(height: 32),
                              _buildOutputCard(),
                            ],
                            const SizedBox(height: 48),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0x660F0A06),
        border: Border(bottom: BorderSide(color: Color(0x22FF8A24))),
      ),
      child: Row(
        children: [
          _BounceButton(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0x33241A13),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x33FF8A24)),
              ),
              child: Center(child: RedesignIcons.arrowBack(size: 20)),
            ),
          ),
          const SizedBox(width: 14),
          // Tool Squircle Badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF9436), Color(0xFFFF6B00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x55FF7A1A),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                )
              ],
            ),
            child: Center(child: RedesignIcons.toolSummarizer(size: 18, color: Colors.white)),
          ),
          const SizedBox(width: 10),
          Text(
            'AI Summarizer',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          Builder(
            builder: (ctx) => _BounceButton(
              onTap: () => Scaffold.of(ctx).openDrawer(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0x33241A13),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0x33FF8A24)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RedesignIcons.history(size: 16, color: const Color(0xFFFF9436)),
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

  Widget _buildUploadCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0x731C130D),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x40FF8A24)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 20,
            offset: Offset(0, 6),
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0x26FF8A24),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x4DFF8A24)),
            ),
            child: Center(
              child: RedesignIcons.cloudUpload(size: 26, color: const Color(0xFFFF9436)),
            ),
          ),
          const SizedBox(height: 14),
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
              fontSize: 12.5,
              color: const Color(0xFF9E9287),
            ),
          ),
          if (_attachedFileName != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0x26FF8A24),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x66FF8A24)),
              ),
              child: Row(
                children: [
                  RedesignIcons.toolSummarizer(size: 18, color: const Color(0xFFFF9436)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _attachedFileName!,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _BounceButton(
                    onTap: () {
                      setState(() {
                        _attachedFileName = null;
                        _attachedBase64Image = null;
                        _isVisionDocument = false;
                      });
                    },
                    child: RedesignIcons.close(size: 16, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          _BounceButton(
            onTap: _pickDocumentOrImage,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: const Color(0x1AFF8A24),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x66FF8A24), width: 1.2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RedesignIcons.toolImage(size: 18, color: const Color(0xFFFF9436)),
                  const SizedBox(width: 8),
                  Text(
                    'Browse Files',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0x22FF8A24), thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR PASTE TEXT',
            style: GoogleFonts.inter(
              color: const Color(0xFF8E8377),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0x22FF8A24), thickness: 1)),
      ],
    );
  }

  Widget _buildTextInputCard() {
    final wordCount = _textController.text.trim().isEmpty
        ? 0
        : _textController.text.trim().split(RegExp(r'\s+')).length;
    final charCount = _textController.text.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0x731C130D),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x40FF8A24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _textController,
            maxLines: 7,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.inter(color: Colors.white, fontSize: 14, height: 1.55),
            decoration: InputDecoration(
              hintText: 'Paste text, transcript, or article content here to summarize...',
              hintStyle: GoogleFonts.inter(color: const Color(0xFF7A6F65), fontSize: 14),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0x22FF8A24), thickness: 1),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$wordCount words • $charCount characters',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9E9287)),
              ),
              if (_textController.text.isNotEmpty || _attachedFileName != null)
                _BounceButton(
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
                      color: const Color(0xFFFF5252),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Summary Mode',
          style: GoogleFonts.inter(
            fontSize: 14.5,
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
            return _BounceButton(
              onTap: () => setState(() => _selectedMode = mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFFFF8A24), Color(0xFFFF6600)],
                        )
                      : null,
                  color: isSelected ? null : const Color(0x33281C14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFFF9436) : const Color(0x33FF8A24),
                  ),
                  boxShadow: isSelected
                      ? const [
                          BoxShadow(
                            color: Color(0x55FF7A1A),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Text(
                  mode,
                  style: GoogleFonts.inter(
                    color: isSelected ? Colors.white : const Color(0xFFD6CBC3),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCustomFocusField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x731C130D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x40FF8A24)),
      ),
      child: TextField(
        controller: _customPromptController,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 13.5),
        decoration: InputDecoration(
          hintText: 'e.g. Focus on financial statistics and key dates only...',
          hintStyle: GoogleFonts.inter(color: const Color(0xFF7A6F65), fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildLengthSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Summary Length',
          style: GoogleFonts.inter(
            fontSize: 14.5,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: _lengths.map((len) {
            final isSelected = _selectedLength == len;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _BounceButton(
                  onTap: () => setState(() => _selectedLength = len),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFFFF8A24), Color(0xFFFF6600)],
                            )
                          : null,
                      color: isSelected ? null : const Color(0x33281C14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFFF9436) : const Color(0x33FF8A24),
                      ),
                      boxShadow: isSelected
                          ? const [
                              BoxShadow(
                                color: Color(0x55FF7A1A),
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        len,
                        style: GoogleFonts.inter(
                          color: isSelected ? Colors.white : const Color(0xFFD6CBC3),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionCTA() {
    return _BounceButton(
      onTap: _isLoading ? () {} : _summarizeText,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF8A24), Color(0xFFFF6600)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66FF7A1A),
              blurRadius: 18,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
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
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RedesignIcons.aiSparkles(size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Summarize Document',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 15.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildOutputCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0x991C130D),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x66FF8A24), width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33FF7A1A),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF9436), Color(0xFFFF6B00)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: RedesignIcons.aiSparkles(size: 16, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Summary Output',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _BounceButton(
                    onTap: _copySummary,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0x33281C14),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0x33FF8A24)),
                      ),
                      child: RedesignIcons.copy(size: 16, color: const Color(0xFFFF9436)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _BounceButton(
                    onTap: _downloadSummary,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0x33281C14),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0x33FF8A24)),
                      ),
                      child: RedesignIcons.download(size: 16, color: const Color(0xFFFF9436)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0x33FF8A24), thickness: 1),
          const SizedBox(height: 14),
          FormattedMessageView(
            text: _summary!,
          ),
        ],
      ),
    );
  }
}

class _BounceButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _BounceButton({required this.child, required this.onTap});

  @override
  State<_BounceButton> createState() => _BounceButtonState();
}

class _BounceButtonState extends State<_BounceButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 140),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: widget.child,
        ),
      ),
    );
  }
}
