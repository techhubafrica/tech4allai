import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:universal_html/html.dart' as html;
import 'package:image_picker/image_picker.dart';
import '../services/fal_api_service.dart';
import '../services/supabase_storage_service.dart';
import '../services/subscription_service.dart';
import '../widgets/upgrade_prompt_dialog.dart';
import '../services/chat_history_service.dart';
import '../widgets/chat_history_drawer.dart';
import '../widgets/redesign_icons.dart';
import 'tools_hub_screen.dart';

class AiImageGeneratorScreen extends StatefulWidget {
  const AiImageGeneratorScreen({super.key});

  @override
  State<AiImageGeneratorScreen> createState() => _AiImageGeneratorScreenState();
}

class _AiImageGeneratorScreenState extends State<AiImageGeneratorScreen> {
  final TextEditingController _promptController = TextEditingController();
  final FalApiService _falService = FalApiService();
  final SupabaseStorageService _storageService = SupabaseStorageService();
  final ImagePicker _picker = ImagePicker();
  final ChatHistoryService _historyService = ChatHistoryService();
  final SubscriptionService _subscriptionService = SubscriptionService();

  String? _activeSessionId;
  String _userTier = 'FREE';
  double _userCredits = 0.0;
  int _imagesToday = 0;
  int _imagesThisMonth = 0;
  bool _isLoadingLimitInfo = true;

  String? _generatedImageUrl;
  bool _isLoading = false;
  String _selectedAspectRatio = '1:1';
  final List<String> _aspectRatios = ['1:1', '16:9', '9:16', '4:3', '3:4', '21:9'];

  int _selectedTabIndex = 0; // 0: With Prompt, 1: Upload Image
  List<XFile> _referenceImages = [];

  String? _toastMessage;
  bool _isToastError = false;
  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();
    _refreshLimitInfo();
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _promptController.dispose();
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
        _userCredits = (sub['credits'] as num?)?.toDouble() ?? 0.0;
        _imagesToday = sub['images_today'] ?? 0;
        _imagesThisMonth = sub['images_this_month'] ?? 0;
        _isLoadingLimitInfo = false;
      });
    }
  }

  Future<void> _loadSessionImage(Map<String, dynamic> session) async {
    setState(() => _isLoading = true);
    try {
      final dbMsgs = await _historyService.getMessages(session['id']);
      final imgMsg = dbMsgs.firstWhere(
        (m) => m['image_url'] != null && m['image_url'].isNotEmpty,
        orElse: () => <String, dynamic>{},
      );
      final promptMsg = dbMsgs.firstWhere(
        (m) => m['is_user'] == true,
        orElse: () => <String, dynamic>{},
      );

      setState(() {
        _activeSessionId = session['id'];
        if (imgMsg.isNotEmpty) {
          _generatedImageUrl = imgMsg['image_url'];
        }
        if (promptMsg.isNotEmpty) {
          _promptController.text = promptMsg['message'];
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImages() async {
    if (_referenceImages.length >= 3) {
      _showNotification('You can only upload up to 3 reference images.', isError: true);
      return;
    }
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _referenceImages.addAll(images);
          if (_referenceImages.length > 3) {
            _referenceImages = _referenceImages.sublist(0, 3);
          }
        });
      }
    } catch (_) {
      _showNotification('Failed to access images', isError: true);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _referenceImages.removeAt(index);
    });
  }

  Future<void> _generateImage() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      _showNotification('Please enter a descriptive image prompt', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _generatedImageUrl = null;
    });

    final isFree = _userTier == 'FREE';
    final modelEndpoint = _selectedTabIndex == 0
        ? (isFree ? 'fal-ai/flux/schnell' : 'fal-ai/nano-banana-2')
        : (isFree ? 'fal-ai/flux-2/klein/4b/edit/lora' : 'fal-ai/nano-banana-pro/edit');

    final double cost = await _subscriptionService.getModelPrice(modelEndpoint);

    final checkResult = await _subscriptionService.checkAndIncrementImageUsage(
      isHeadshot: false,
      cost: cost,
    );

    if (checkResult['success'] != true) {
      setState(() => _isLoading = false);
      final String limitMsg = checkResult['message'] ?? 'Image generation limit reached.';
      if (mounted) {
        UpgradePromptDialog.show(
          context,
          title: "Generation Limit Reached",
          message: "$limitMsg Upgrade to BASIC or PRO to unlock high-resolution engines and faster generation speeds!",
        );
      }
      return;
    }

    _refreshLimitInfo();
    String? imageUrl;

    if (_selectedTabIndex == 0) {
      imageUrl = await _falService.generateImageFromPrompt(
        prompt: prompt,
        aspectRatio: _selectedAspectRatio,
        isFree: isFree,
      );
    } else {
      if (_referenceImages.isEmpty) {
        setState(() => _isLoading = false);
        _showNotification('Please upload at least 1 reference image.', isError: true);
        return;
      }

      _showNotification('Uploading reference images...');
      List<String> uploadedUrls = [];
      for (var file in _referenceImages) {
        final publicUrl = await _storageService.uploadSelfie(file);
        if (publicUrl != null) {
          uploadedUrls.add(publicUrl);
        }
      }

      if (uploadedUrls.isEmpty) {
        setState(() => _isLoading = false);
        _showNotification('Failed to upload reference images.', isError: true);
        return;
      }

      _showNotification('Synthesizing image with AI...');
      imageUrl = await _falService.generateFromMultipleReferenceImages(
        referenceUrls: uploadedUrls,
        prompt: prompt,
        isFree: isFree,
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (imageUrl != null) {
          _generatedImageUrl = imageUrl;
          _showNotification('Image generated successfully!');
        } else {
          _showNotification('Failed to generate image. Please try again.', isError: true);
        }
      });

      if (imageUrl != null) {
        try {
          final session = await _historyService.createSession('image_gen', initialTitle: prompt);
          _activeSessionId = session['id'];
          await _historyService.addMessage(
            _activeSessionId!,
            isUser: true,
            message: prompt,
          );
          await _historyService.addMessage(
            _activeSessionId!,
            isUser: false,
            message: 'Generated image successfully.',
            imageUrl: imageUrl,
          );
        } catch (_) {}
      }
    }
  }

  Future<void> _saveImage() async {
    if (_generatedImageUrl == null) return;
    try {
      _showNotification('Downloading high-res image...');
      final bytes = await _falService.downloadImageBytes(_generatedImageUrl!);
      if (bytes == null) throw 'Failed to download';

      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', 'ai_image_${DateTime.now().millisecondsSinceEpoch}.jpg')
        ..click();
      html.Url.revokeObjectUrl(url);

      _showNotification('Image downloaded successfully!');
    } catch (_) {
      _showNotification('Failed to download image.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A06),
      drawer: ChatHistoryDrawer(
        featureType: 'image_gen',
        activeSessionId: _activeSessionId,
        onSessionSelected: (session) => _loadSessionImage(session),
        onNewChatStarted: () {
          setState(() {
            _activeSessionId = null;
            _generatedImageUrl = null;
            _promptController.clear();
            _referenceImages.clear();
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

                // 2. MAIN SCROLLABLE CONTENT
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 860),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Model & Quota Capsule
                            _buildQuotaBanner(),
                            const SizedBox(height: 14),

                            // Segmented Switcher Pill: With Prompt / Upload Image
                            _buildSegmentedTabSwitcher(),
                            const SizedBox(height: 18),

                            // Image Canvas Preview Box
                            _buildPreviewCanvas(),
                            const SizedBox(height: 20),

                            // Prompt & Settings Glass Card
                            _buildPromptSettingsCard(),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. FLOATING TOAST NOTIFICATION
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
                          boxShadow: [
                            BoxShadow(
                              color: _isToastError ? const Color(0x66FF3B30) : const Color(0x66FF7300),
                              blurRadius: 8,
                            ),
                          ],
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
          _ImageBounceButton(
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: RedesignIcons.arrowBack(size: 21, color: Colors.white),
              ),
            ),
          ),

          // Title with Squircle Tool Badge
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFBA68C8), Color(0xFF7B1FA2)],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66AB47BC),
                      blurRadius: 12,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: RedesignIcons.toolImage(size: 17, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Image Generator',
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
            builder: (context) => _ImageBounceButton(
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

  Widget _buildQuotaBanner() {
    if (_isLoadingLimitInfo) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E140C).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x26FF7300), width: 1.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _userTier == 'FREE' ? const Color(0xFFFF9233) : const Color(0xFF00E676),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _userTier == 'FREE'
                    ? 'Daily: $_imagesToday/5 • Monthly: $_imagesThisMonth/25'
                    : 'Credits: \$${_userCredits.toStringAsFixed(2)} USD',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFFC9BFB5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
            decoration: BoxDecoration(
              color: const Color(0x2EB97D14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xA6EEAF37), width: 0.8),
            ),
            child: Text(
              _userTier == 'FREE' ? 'FLUX SCHNELL' : 'FLUX NANO PRO',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
                color: const Color(0xFFF6C15C),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedTabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: const Color(0xD1221B16),
        border: Border.all(color: const Color(0x1CFFFFFF), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _ImageBounceButton(
              onTap: () => setState(() => _selectedTabIndex = 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(21),
                  gradient: _selectedTabIndex == 0
                      ? const LinearGradient(
                          colors: [Color(0xFFFF981A), Color(0xFFFF7300), Color(0xFFFF5E00)],
                        )
                      : null,
                  border: _selectedTabIndex == 0
                      ? Border.all(color: const Color(0x73FFE1B9), width: 1.0)
                      : null,
                  boxShadow: _selectedTabIndex == 0
                      ? const [
                          BoxShadow(color: Color(0xA6FF7800), blurRadius: 18),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'With Prompt',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: _selectedTabIndex == 0 ? FontWeight.bold : FontWeight.w600,
                      color: _selectedTabIndex == 0 ? Colors.white : const Color(0xD9FFFFFF),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: _ImageBounceButton(
              onTap: () => setState(() => _selectedTabIndex = 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(21),
                  gradient: _selectedTabIndex == 1
                      ? const LinearGradient(
                          colors: [Color(0xFFFF981A), Color(0xFFFF7300), Color(0xFFFF5E00)],
                        )
                      : null,
                  border: _selectedTabIndex == 1
                      ? Border.all(color: const Color(0x73FFE1B9), width: 1.0)
                      : null,
                  boxShadow: _selectedTabIndex == 1
                      ? const [
                          BoxShadow(color: Color(0xA6FF7800), blurRadius: 18),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Upload Image',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: _selectedTabIndex == 1 ? FontWeight.bold : FontWeight.w600,
                      color: _selectedTabIndex == 1 ? Colors.white : const Color(0xD9FFFFFF),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCanvas() {
    return Container(
      height: 380,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF18110B).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x38FF7300), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: _isLoading
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0x26FF7300),
                          border: Border.all(color: const Color(0x66FF7300), width: 1.2),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFFFF7A00),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Generating visual rendering...',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFD4C9C0),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                : _generatedImageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.network(
                          _generatedImageUrl!,
                          fit: BoxFit.contain,
                          loadingBuilder: (_, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFFF7A00),
                              ),
                            );
                          },
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0x1AFFFFFF),
                              border: Border.all(color: const Color(0x2BFFFFFF), width: 1),
                            ),
                            child: Center(
                              child: RedesignIcons.gallery(size: 26, color: const Color(0xFF8E857D)),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Enter your prompt below to generate an image',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF8E857D),
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
          ),
          if (_generatedImageUrl != null && !_isLoading)
            Positioned(
              bottom: 16,
              right: 16,
              child: _ImageBounceButton(
                onTap: _saveImage,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.download_rounded, color: Colors.white, size: 17),
                      const SizedBox(width: 6),
                      Text(
                        'Download',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
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

  Widget _buildPromptSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E140C).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x28FFFFFF), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Prompt Label
          Text(
            'PROMPT DESCRIPTION',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: const Color(0xFF9E9286),
            ),
          ),
          const SizedBox(height: 8),

          // Text Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF140D08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x38FF7300), width: 1.0),
            ),
            child: TextField(
              controller: _promptController,
              maxLines: 3,
              minLines: 2,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
              cursorColor: const Color(0xFFFF7A00),
              decoration: InputDecoration(
                hintText: 'Describe the image, lighting, colors, style...',
                hintStyle: GoogleFonts.inter(color: const Color(0xFF756C64), fontSize: 13.5),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),

          // Reference Images Area (when Upload Image tab active)
          if (_selectedTabIndex == 1) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'REFERENCE IMAGES (${_referenceImages.length}/3)',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: const Color(0xFF9E9286),
                  ),
                ),
                if (_referenceImages.length < 3)
                  GestureDetector(
                    onTap: _pickImages,
                    child: Text(
                      '+ Add Photo',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFF9233),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_referenceImages.isNotEmpty)
              SizedBox(
                height: 74,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _referenceImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 12),
                          width: 74,
                          height: 74,
                          decoration: BoxDecoration(
                            color: const Color(0xFF261911),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0x66FF7300), width: 1.2),
                          ),
                          child: Center(
                            child: RedesignIcons.gallery(size: 24, color: const Color(0xFFFF9233)),
                          ),
                        ),
                        Positioned(
                          top: -4,
                          right: 6,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF3B30),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 12),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],

          // Aspect Ratio Selector
          if (_selectedTabIndex == 0) ...[
            const SizedBox(height: 16),
            Text(
              'ASPECT RATIO',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: const Color(0xFF9E9286),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _aspectRatios.map((ratio) {
                  final isSelected = _selectedAspectRatio == ratio;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: _ImageBounceButton(
                      onTap: () => setState(() => _selectedAspectRatio = ratio),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: isSelected ? const Color(0x2BFF7300) : const Color(0xFF140D08),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFFF7A00) : const Color(0x26FFFFFF),
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          ratio,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? const Color(0xFFFF9438) : const Color(0xFFB5ACA2),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          const SizedBox(height: 22),

          // Generate Image Button
          _ImageBounceButton(
            onTap: _isLoading ? null : _generateImage,
            child: Container(
              height: 48,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFA438), Color(0xFFFF6A00)],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66FF7300),
                    blurRadius: 20,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RedesignIcons.lightning(size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    _isLoading ? 'Generating Visual...' : 'Generate Image',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
}

class _ImageBounceButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _ImageBounceButton({required this.child, this.onTap});

  @override
  State<_ImageBounceButton> createState() => _ImageBounceButtonState();
}

class _ImageBounceButtonState extends State<_ImageBounceButton> with SingleTickerProviderStateMixin {
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
