import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/fal_api_service.dart';
import '../services/supabase_storage_service.dart';
import '../services/subscription_service.dart';
import '../widgets/upgrade_prompt_dialog.dart';
import '../services/chat_history_service.dart';
import '../widgets/chat_history_drawer.dart';
import '../widgets/redesign_icons.dart';
import 'tools_hub_screen.dart';

class HeadshotsScreen extends StatefulWidget {
  const HeadshotsScreen({super.key});

  @override
  State<HeadshotsScreen> createState() => _HeadshotsScreenState();
}

class _HeadshotsScreenState extends State<HeadshotsScreen> {
  final FalApiService _falService = FalApiService();
  final SupabaseStorageService _supabaseService = SupabaseStorageService();
  final ChatHistoryService _historyService = ChatHistoryService();
  final SubscriptionService _subscriptionService = SubscriptionService();

  String? _activeSessionId;

  String _userTier = 'FREE';
  double _userCredits = 0.0;
  int _headshotsToday = 0;
  int _headshotsThisMonth = 0;
  bool _isLoadingLimitInfo = true;

  final ImagePicker _picker = ImagePicker();
  Uint8List? _referenceImageBytes;
  bool _isUploading = false;
  String? _referenceUrl;

  String _selectedStyle = 'Executive';
  String _selectedGender = 'Male';
  final TextEditingController _customPromptController = TextEditingController();
  bool _isGenerating = false;

  final List<Map<String, dynamic>> _styles = [
    {
      'title': 'Executive',
      'icon': Icons.business,
      'prompt': 'professional executive suite, corporate leadership, confident authoritative pose, high-end office background'
    },
    {
      'title': 'Casual',
      'icon': Icons.weekend,
      'prompt': 'smart casual attire, relaxed friendly demeanor, soft natural lighting, blurred lifestyle background'
    },
    {
      'title': 'Office Aesthetic',
      'icon': Icons.apartment,
      'prompt': 'modern office environment, business casual, glass walls, bright professional setting'
    },
    {
      'title': 'Tech Lead',
      'icon': Icons.computer,
      'prompt': 'modern tech company vibe, open plan office, hoodie or t-shirt with blazer, approachable innovation'
    },
    {
      'title': 'Startup Founder',
      'icon': Icons.rocket_launch,
      'prompt': 'dynamic and ambitious, modern co-working space, energetic lighting, confident gaze'
    },
    {
      'title': 'Minimalist',
      'icon': Icons.crop_square,
      'prompt': 'clean solid color background, simple elegant clothing, studio lighting, focus purely on the face'
    },
    {
      'title': 'LinkedIn Standard',
      'icon': Icons.camera_alt,
      'prompt': 'classic professional headshot, neutral grey background, suit and tie or formal blouse, evenly lit'
    },
  ];

  @override
  void initState() {
    super.initState();
    _refreshLimitInfo();
  }

  @override
  void dispose() {
    _customPromptController.dispose();
    super.dispose();
  }

  Future<void> _refreshLimitInfo() async {
    final sub = await _subscriptionService.getSubscription();
    if (mounted && sub != null) {
      setState(() {
        _userTier = sub['tier'] ?? 'FREE';
        _userCredits = (sub['credits'] as num?)?.toDouble() ?? 0.0;
        _headshotsToday = sub['headshots_today'] ?? 0;
        _headshotsThisMonth = sub['headshots_this_month'] ?? 0;
        _isLoadingLimitInfo = false;
      });
    }
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

  Future<void> _loadSessionHeadshot(Map<String, dynamic> session) async {
    setState(() => _isGenerating = true);
    try {
      final dbMsgs = await _historyService.getMessages(session['id']);
      final imgMsg = dbMsgs.firstWhere(
        (m) => m['image_url'] != null && m['image_url'].isNotEmpty,
        orElse: () => <String, dynamic>{},
      );

      setState(() {
        _activeSessionId = session['id'];
        _isGenerating = false;
      });
      if (imgMsg.isNotEmpty && imgMsg['image_url'] != null) {
        _showResultDialog(imgMsg['image_url']);
      }
    } catch (e) {
      print('Error loading headshot from history: $e');
      setState(() => _isGenerating = false);
    }
  }

  void _showGuidelinesModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          gradient: const RadialGradient(
            center: Alignment(0, -0.6),
            radius: 1.1,
            colors: [Color(0xFF28180D), Color(0xFF140D08)],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: const Color(0x66FF8A24), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF8A24).withOpacity(0.18),
              blurRadius: 32,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0x40FF8A24),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3888FF), Color(0xFF1D5BFF)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x553888FF),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        )
                      ],
                    ),
                    child: Center(child: RedesignIcons.toolHeadshots(size: 20, color: Colors.white)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Upload Photo to Transform',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Upload a clear photo. Tech Hub Africa\'s ELYON 0.1V maps your facial geometry directly to preserve your authentic identity.',
                style: GoogleFonts.inter(color: const Color(0xFFB0A49B), fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 20),
              _buildGuidelineRow('Direct gaze', 'Look directly at the camera with a front-facing angle.'),
              _buildGuidelineRow('Even lighting', 'Ensure face is evenly lit with no harsh shadows or tints.'),
              _buildGuidelineRow('Unobstructed face', 'Remove glasses, hats, or heavy hair covering your facial features.'),
              const SizedBox(height: 26),
              _BounceButton(
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
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
                      )
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Upload Reference Photo',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 15.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuidelineRow(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: const Color(0x26FF8A24),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0x40FF8A24)),
            ),
            child: Center(
              child: RedesignIcons.check(size: 14, color: const Color(0xFFFF9436)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.inter(color: const Color(0xFF9E9287), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 100,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();

        setState(() {
          _referenceImageBytes = bytes;
          _isUploading = true;
          _referenceUrl = null;
        });

        try {
          final publicUrl = await _supabaseService.uploadSelfie(image);

          if (mounted) {
            setState(() {
              _isUploading = false;
              if (publicUrl != null) {
                _referenceUrl = publicUrl;
              } else {
                _showNotification('Failed to link reference photo: Returned URL was empty.', isError: true);
              }
            });
            if (publicUrl != null) {
              _showNotification('Reference photo uploaded & facial contours mapped!');
            }
          }
        } catch (uploadErr) {
          if (mounted) {
            setState(() {
              _isUploading = false;
            });
            _showNotification('Upload failed: $uploadErr', isError: true);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        _showNotification('Error picking image: $e', isError: true);
      }
    }
  }

  Future<void> _generateHeadshot() async {
    if (_referenceUrl == null) {
      _showNotification('Please upload a reference photo first.', isError: true);
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    final isFree = _userTier == 'FREE';
    final modelEndpoint = isFree ? 'fal-ai/flux-2/klein/4b/edit/lora' : 'fal-ai/nano-banana-pro/edit';

    final double cost = await _subscriptionService.getModelPrice(modelEndpoint);

    final checkResult = await _subscriptionService.checkAndIncrementImageUsage(
      isHeadshot: true,
      cost: cost,
    );

    if (checkResult['success'] != true) {
      setState(() => _isGenerating = false);
      final String limitMsg = checkResult['message'] ?? 'Headshot generation limit reached.';
      if (mounted) {
        UpgradePromptDialog.show(
          context,
          title: "Generation Limit Reached",
          message: "$limitMsg Upgrade to BASIC or PRO to get shared credit allocations and higher quality models!",
        );
      }
      return;
    }

    _refreshLimitInfo();

    final styleData = _styles.firstWhere((s) => s['title'] == _selectedStyle);
    final stylePrompt = styleData['prompt'] as String;

    final customPromptText = _customPromptController.text.trim();
    final genderContext = _selectedGender == 'Male' ? 'a male person, man' : 'a female person, woman';
    final photorealismTags =
        "raw photograph, 8k uhd, dslr, soft lighting, high quality, highly detailed, film grain, photorealistic, extremely realistic, highly detailed photography, Fujifilm XT4, sharp focus";

    final String identityLockPrefix =
        "INSTRUCTION: PIXEL PRIORITY MODE. IDENTITY LOCK: ABSOLUTE. Use ONLY the visual data from the reference image for facial feature construction. Maintain the exact same eyes, nose shape, jawline contour, and skin texture. Generate this exact person into: ";

    final basePrompt = customPromptText.isNotEmpty
        ? "$identityLockPrefix $customPromptText of $genderContext, $photorealismTags"
        : "$identityLockPrefix a high-end professional corporate headshot of $genderContext, $stylePrompt, $photorealismTags";

    String? imageUrl = await _falService.generateFromReferenceImage(
      referenceUrl: _referenceUrl!,
      prompt: basePrompt,
      isFree: isFree,
    );

    if (mounted) {
      setState(() {
        _isGenerating = false;
      });

      if (imageUrl != null) {
        _showResultDialog(imageUrl);
        try {
          final session = await _historyService.createSession('headshots', initialTitle: '$_selectedStyle Headshot');
          _activeSessionId = session['id'];
          await _historyService.addMessage(
            _activeSessionId!,
            isUser: true,
            message: 'Style: $_selectedStyle, Gender: $_selectedGender',
          );
          await _historyService.addMessage(
            _activeSessionId!,
            isUser: false,
            message: 'Generated professional headshot successfully.',
            imageUrl: imageUrl,
          );
        } catch (dbErr) {
          print('Error saving headshot to history database: $dbErr');
        }
      } else {
        _showNotification('AI Generation failed. Please try again.', isError: true);
      }
    }
  }

  void _showResultDialog(String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          padding: const EdgeInsets.all(22.0),
          decoration: BoxDecoration(
            gradient: const RadialGradient(
              center: Alignment(0, -0.6),
              radius: 1.1,
              colors: [Color(0xFF2E1F16), Color(0xFF140D08)],
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0x66FF8A24), width: 1.4),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF8A24).withOpacity(0.2),
                blurRadius: 36,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3888FF), Color(0xFF1D5BFF)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(child: RedesignIcons.toolHeadshots(size: 18, color: Colors.white)),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Your Headshot',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                  _BounceButton(
                    onTap: () => Navigator.pop(dialogCtx),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0x33281C14),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0x33FF8A24)),
                      ),
                      child: RedesignIcons.close(size: 16, color: Colors.white70),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0x33FF8A24)),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        height: 280,
                        color: const Color(0x331C130D),
                        child: const Center(
                          child: CircularProgressIndicator(color: Color(0xFFFF8A24)),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _BounceButton(
                      onTap: () => Navigator.pop(dialogCtx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0x33241A13),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0x33FF8A24)),
                        ),
                        child: Center(
                          child: Text(
                            'Close',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BounceButton(
                      onTap: () async {
                        try {
                          _showNotification('Starting high-res download...');
                          final imageBytes = await _falService.downloadImageBytes(imageUrl);
                          if (imageBytes == null) throw 'Failed to fetch image bytes';

                          final blob = html.Blob([imageBytes]);
                          final url = html.Url.createObjectUrlFromBlob(blob);
                          html.AnchorElement(href: url)
                            ..setAttribute('download', 'headshot_${DateTime.now().millisecondsSinceEpoch}.jpg')
                            ..click();
                          html.Url.revokeObjectUrl(url);

                          if (mounted) {
                            _showNotification('Download started!');
                          }
                          if (dialogCtx.mounted) {
                            Navigator.pop(dialogCtx);
                          }
                        } catch (e) {
                          _showNotification('Error downloading: $e', isError: true);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF8A24), Color(0xFFFF6600)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x66FF7A1A),
                              blurRadius: 12,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            RedesignIcons.download(size: 16, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'Save Headshot',
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
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A06),
      drawer: ChatHistoryDrawer(
        featureType: 'headshots',
        activeSessionId: _activeSessionId,
        onSessionSelected: (session) {
          _loadSessionHeadshot(session);
        },
        onNewChatStarted: () {
          setState(() {
            _activeSessionId = null;
            _referenceImageBytes = null;
            _referenceUrl = null;
            _customPromptController.clear();
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
                if (!_isLoadingLimitInfo) _buildLimitBar(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 820),
                        child: _referenceUrl == null ? _buildPhase1Layout() : _buildPhase2Layout(),
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
                color: const Color(0x33241A13),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x33FF8A24)),
              ),
              child: Center(child: RedesignIcons.arrowBack(size: 20)),
            ),
          ),
          const SizedBox(width: 14),
          // Tool Blue Squircle Badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3888FF), Color(0xFF1D5BFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x553888FF),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                )
              ],
            ),
            child: Center(child: RedesignIcons.toolHeadshots(size: 18, color: Colors.white)),
          ),
          const SizedBox(width: 10),
          Text(
            'AI Headshots',
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

  Widget _buildLimitBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0x331C130D),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x22FF8A24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _userTier == 'FREE'
                      ? 'Daily: $_headshotsToday / 2  •  Monthly: $_headshotsThisMonth / 15'
                      : 'Balance: \$${_userCredits.toStringAsFixed(2)} USD',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFFB0A49B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0x26FF8A24),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0x40FF8A24)),
                  ),
                  child: Text(
                    _userTier == 'FREE' ? 'Klein 4B' : 'Nano Banana Pro',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFFFF9436),
                      fontWeight: FontWeight.bold,
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

  Widget _buildStepBadge(String step, String title) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF9436), Color(0xFFFF6B00)],
            ),
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Color(0x55FF7A1A),
                blurRadius: 8,
                offset: Offset(0, 2),
              )
            ],
          ),
          child: Center(
            child: Text(
              step,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildPhase1Layout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepBadge('1', 'Upload Reference Photo'),
        const SizedBox(height: 14),
        _BounceButton(
          onTap: _showGuidelinesModal,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
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
            child: _isUploading
                ? Column(
                    children: [
                      const SizedBox(
                        height: 38,
                        width: 38,
                        child: CircularProgressIndicator(color: Color(0xFFFF8A24), strokeWidth: 2.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Mapping facial contours...',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Securing reference photo on high-speed storage',
                        style: GoogleFonts.inter(color: const Color(0xFF9E9287), fontSize: 12),
                      ),
                    ],
                  )
                : (_referenceImageBytes == null)
                    ? Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0x26FF8A24),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0x4DFF8A24)),
                            ),
                            child: Center(
                              child: RedesignIcons.camera(size: 26, color: const Color(0xFFFF9436)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tap to Select 1 Photo',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'We will transform this photo into studio-grade 8K portraits with absolute identity lock.',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF9E9287),
                              fontSize: 12.5,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.memory(
                              _referenceImageBytes!,
                              height: 140,
                              width: 140,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Upload Failed',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFFF5252),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap to try again.',
                            style: GoogleFonts.inter(color: const Color(0xFF9E9287), fontSize: 12),
                          ),
                        ],
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhase2Layout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reference Initialized Success Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0x2610B981),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x6610B981)),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0x3310B981),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: RedesignIcons.check(size: 18, color: const Color(0xFF10B981)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reference Initialized',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF10B981),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Facial geometry locked. Ready for studio transformation.',
                      style: GoogleFonts.inter(color: const Color(0xFFD1FAE5), fontSize: 12),
                    ),
                  ],
                ),
              ),
              _BounceButton(
                onTap: () {
                  setState(() {
                    _referenceUrl = null;
                    _referenceImageBytes = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0x33000000),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0x4D10B981)),
                  ),
                  child: Text(
                    'Change',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Step 2: Gender Selector
        _buildStepBadge('2', 'Select Gender'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _BounceButton(
                onTap: () => setState(() => _selectedGender = 'Male'),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: _selectedGender == 'Male'
                        ? const LinearGradient(
                            colors: [Color(0xFFFF8A24), Color(0xFFFF6600)],
                          )
                        : null,
                    color: _selectedGender == 'Male' ? null : const Color(0x33281C14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _selectedGender == 'Male' ? const Color(0xFFFF9436) : const Color(0x33FF8A24),
                    ),
                    boxShadow: _selectedGender == 'Male'
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
                      'Male',
                      style: GoogleFonts.inter(
                        color: _selectedGender == 'Male' ? Colors.white : const Color(0xFFD6CBC3),
                        fontWeight: _selectedGender == 'Male' ? FontWeight.bold : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BounceButton(
                onTap: () => setState(() => _selectedGender = 'Female'),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: _selectedGender == 'Female'
                        ? const LinearGradient(
                            colors: [Color(0xFFFF8A24), Color(0xFFFF6600)],
                          )
                        : null,
                    color: _selectedGender == 'Female' ? null : const Color(0x33281C14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _selectedGender == 'Female' ? const Color(0xFFFF9436) : const Color(0x33FF8A24),
                    ),
                    boxShadow: _selectedGender == 'Female'
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
                      'Female',
                      style: GoogleFonts.inter(
                        color: _selectedGender == 'Female' ? Colors.white : const Color(0xFFD6CBC3),
                        fontWeight: _selectedGender == 'Female' ? FontWeight.bold : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Step 3: Choose Style
        _buildStepBadge('3', 'Choose Style'),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.6,
          ),
          itemCount: _styles.length,
          itemBuilder: (context, index) {
            final style = _styles[index];
            final isSelected = _selectedStyle == style['title'];

            return _BounceButton(
              onTap: () => setState(() => _selectedStyle = style['title']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFFFF8A24), Color(0xFFFF6600)],
                        )
                      : null,
                  color: isSelected ? null : const Color(0x731C130D),
                  borderRadius: BorderRadius.circular(14),
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
                child: Row(
                  children: [
                    Icon(
                      style['icon'] as IconData,
                      color: isSelected ? Colors.white : const Color(0xFFFF9436),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        style['title'],
                        style: GoogleFonts.inter(
                          color: isSelected ? Colors.white : const Color(0xFFE8DFD8),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),

        // Custom Scene Field
        Text(
          'Or Create Custom Scene',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 14.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: const Color(0x731C130D),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x40FF8A24)),
          ),
          child: TextField(
            controller: _customPromptController,
            maxLines: 3,
            minLines: 1,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 13.5),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'e.g. In a charcoal grey tailored blazer, standing by floor-to-ceiling glass in a Tokyo skyscraper at dusk.',
              hintStyle: GoogleFonts.inter(color: const Color(0xFF7A6F65), fontSize: 13),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Action CTA
        _BounceButton(
          onTap: _isGenerating ? () {} : _generateHeadshot,
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
            child: _isGenerating
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Generating Studio Headshot...',
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
                        'Generate Headshot',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 15.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 48),
      ],
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
