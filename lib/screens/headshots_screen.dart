import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:archive/archive.dart';
import '../constants/colors.dart';
import '../services/fal_api_service.dart';
import '../services/supabase_storage_service.dart';
import '../services/subscription_service.dart';
import '../widgets/upgrade_prompt_dialog.dart';
import '../services/chat_history_service.dart';
import '../widgets/chat_history_drawer.dart';
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
  String? _activeSessionId;

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

  final SubscriptionService _subscriptionService = SubscriptionService();
  String _userTier = 'FREE';
  double _userCredits = 0.0;
  int _headshotsToday = 0;
  int _headshotsThisMonth = 0;
  bool _isLoadingLimitInfo = true;

  @override
  void initState() {
    super.initState();
    _refreshLimitInfo();
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

  // State variables for Phase 1: Uploading
  final ImagePicker _picker = ImagePicker();
  Uint8List? _referenceImageBytes; 
  bool _isUploading = false;
  String? _referenceUrl; // Store the resulting Supabase public URL
  
  // State variables for Phase 2: Generation
  String _selectedStyle = 'Executive';
  String _selectedGender = 'Male'; // Gender context for prompt
  final TextEditingController _customPromptController = TextEditingController();
  bool _isGenerating = false;

  final List<Map<String, dynamic>> _styles = [
    {'title': 'Executive', 'icon': Icons.business, 'prompt': 'professional executive suite, corporate leadership, confident authoritative pose, high-end office background'},
    {'title': 'Casual', 'icon': Icons.weekend, 'prompt': 'smart casual attire, relaxed friendly demeanor, soft natural lighting, blurred lifestyle background'},
    {'title': 'Office Aesthetic', 'icon': Icons.apartment, 'prompt': 'modern office environment, business casual, glass walls, bright professional setting'},
    {'title': 'Tech Lead', 'icon': Icons.computer, 'prompt': 'modern tech company vibe, open plan office, hoodie or t-shirt with blazer, approachable innovation'},
    {'title': 'Startup Founder', 'icon': Icons.rocket_launch, 'prompt': 'dynamic and ambitious, modern co-working space, energetic lighting, confident gaze'},
    {'title': 'Minimalist', 'icon': Icons.crop_square, 'prompt': 'clean solid color background, simple elegant clothing, studio lighting, focus purely on the face'},
    {'title': 'LinkedIn Standard', 'icon': Icons.camera_alt, 'prompt': 'classic professional headshot, neutral grey background, suit and tie or formal blouse, evenly lit'},
  ];



  @override
  void dispose() {
    _customPromptController.dispose();
    super.dispose();
  }

  void _showGuidelinesModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.neutralSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload Photo to Transform',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Upload any clear photo. The AI will directly transform it into a stunningly realistic 8k portrait based on your instructions.',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildGuidelineRow(Icons.face, 'Look directly at the camera (Front-facing angle).'),
            _buildGuidelineRow(Icons.light_mode, 'Ensure your face is evenly lit with no harsh shadows.'),
            _buildGuidelineRow(Icons.visibility_off, 'Remove glasses, hats, or hair covering your face.'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _pickImage();
                },
                child: Text(
                  'Upload Reference Photo',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidelineRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
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
          // Instantly backend-upload the photo to Supabase to prepare for Zero-Shot generation
          final publicUrl = await _supabaseService.uploadSelfie(image);
          
          if (mounted) {
              setState(() {
                 _isUploading = false;
                 if (publicUrl != null) {
                    _referenceUrl = publicUrl;
                 } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to securely link reference photo: Returned URL was empty.')),
                    );
                 }
              });
          }
        } catch (uploadErr) {
          if (mounted) {
              setState(() {
                 _isUploading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Upload failed: $uploadErr')),
              );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _generateHeadshot() async {
    if (_referenceUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload a reference photo first.')),
        );
        return;
    }

    setState(() {
      _isGenerating = true;
    });

    final isFree = _userTier == 'FREE';
    final modelEndpoint = isFree ? 'fal-ai/flux-2/klein/4b/edit/lora' : 'fal-ai/nano-banana-pro/edit';

    // Fetch dynamic model cost
    final double cost = await _subscriptionService.getModelPrice(modelEndpoint);

    // Verify limits and deduct credits atomically
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
    final photorealismTags = "raw photograph, 8k uhd, dslr, soft lighting, high quality, highly detailed, film grain, photorealistic, extremely realistic, highly detailed photography, Fujifilm XT4, sharp focus";
    
    // Exact Natural Language Command tuned for Nano Banana Pro (Gemini) Architecture
    final String identityLockPrefix = "INSTRUCTION: PIXEL PRIORITY MODE. IDENTITY LOCK: ABSOLUTE. Use ONLY the visual data from the reference image for facial feature construction. Maintain the exact same eyes, nose shape, jawline contour, and skin texture. Generate this exact person into: ";

    final basePrompt = customPromptText.isNotEmpty
      ? "$identityLockPrefix $customPromptText of $genderContext, $photorealismTags"
      : "$identityLockPrefix a high-end professional corporate headshot of $genderContext, $stylePrompt, $photorealismTags";
    
    // Call Fal.ai Zero-Shot PuLID Inference
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
         ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('AI Generation failed. Please try again.')),
          );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
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
      appBar: AppBar(
        title: Text(
          'AI Headshots',
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
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Builder(
              builder: (context) => ElevatedButton.icon(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.history, size: 16, color: Colors.white),
                label: Text(
                  'History',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neutralSurface,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: AppColors.neutralBorder),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!_isLoadingLimitInfo) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _userTier == 'FREE'
                          ? 'Daily: $_headshotsToday / 2 | Monthly: $_headshotsThisMonth / 15'
                          : 'Balance: \$${_userCredits.toStringAsFixed(2)} USD',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.neutralTextMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _userTier == 'FREE' ? 'Using Klein Model' : 'Using Pro Models',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
             Expanded(
               child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                 child: _referenceUrl == null
                   ? _buildPhase1Layout() 
                   : _buildPhase2Layout(),
               ),
             ),
          ],
        ),
      ),
    );
  }

// Training layout completely deprecated for Zero-Shot method

  Widget _buildPhase1Layout() {
      return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader('1', 'Upload Reference Photo'),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _showGuidelinesModal,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.neutralSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary, width: 2, style: BorderStyle.solid),
                ),
                child: _isUploading
                  ? Column(
                      children: [
                        const SizedBox(
                          height: 40, width: 40,
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Uploading secure reference...',
                          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    )
                  : (_referenceImageBytes == null)
                    ? Column(
                        children: [
                          const Icon(Icons.add_a_photo, size: 40, color: AppColors.primary),
                          const SizedBox(height: 16),
                          Text(
                            'Tap to Select 1 Photo',
                            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'We will process and transform this exact image into your requested scene using Tech Hub Africa\'s ELYON 0.1V.',
                            style: TextStyle(
                              color: AppColors.neutralTextMuted, fontSize: 12, height: 1.5),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              _referenceImageBytes!,
                              height: 120,
                              width: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Upload Failed.',
                            style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to try again.',
                            style: GoogleFonts.inter(color: AppColors.neutralTextMuted, fontSize: 12),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 32),
// Start Training Button Deprecated
// Deprecated Button
          ]
      );
  }

  Widget _buildPhase2Layout() {
      return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                     color: Colors.green.withOpacity(0.1),
                     borderRadius: BorderRadius.circular(12),
                     border: Border.all(color: Colors.green),
                 ),
                 child: Row(
                     children: [
                         const Icon(Icons.check_circle, color: Colors.green),
                         const SizedBox(width: 12),
                         Expanded(
                             child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                     Text('Reference Initialized', style: GoogleFonts.inter(color: Colors.green, fontWeight: FontWeight.bold)),
                                     Text('Your facial structures are mapped and ready to be instantly injected.', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                                 ],
                             )
                         ),
                         // Add a button to "Change Photo"
                         IconButton(
                           icon: const Icon(Icons.edit, color: Colors.white70),
                           onPressed: () {
                             setState(() {
                               _referenceUrl = null;
                               _referenceImageBytes = null;
                             });
                           },
                         )
                     ],
                 ),
             ),
             const SizedBox(height: 32),
              const SizedBox(height: 24),
              // Gender Selection Toggle
              _buildStepHeader('2', 'Select Gender'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedGender = 'Male'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _selectedGender == 'Male' ? AppColors.primary.withOpacity(0.2) : AppColors.neutralSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _selectedGender == 'Male' ? AppColors.primary : AppColors.neutralBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.male, color: _selectedGender == 'Male' ? AppColors.primary : Colors.white70),
                            const SizedBox(width: 8),
                            Text('Male', style: GoogleFonts.inter(color: _selectedGender == 'Male' ? AppColors.primary : Colors.white, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedGender = 'Female'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _selectedGender == 'Female' ? AppColors.primary.withOpacity(0.2) : AppColors.neutralSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _selectedGender == 'Female' ? AppColors.primary : AppColors.neutralBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.female, color: _selectedGender == 'Female' ? AppColors.primary : Colors.white70),
                            const SizedBox(width: 8),
                            Text('Female', style: GoogleFonts.inter(color: _selectedGender == 'Female' ? AppColors.primary : Colors.white, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
             _buildStepHeader('3', 'Choose Style'),
            const SizedBox(height: 12),
            
            // Style Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.5,
              ),
              itemCount: _styles.length,
              itemBuilder: (context, index) {
                 final style = _styles[index];
                 final isSelected = _selectedStyle == style['title'];
                 
                 return GestureDetector(
                   onTap: () {
                     setState(() {
                       _selectedStyle = style['title'];
                     });
                   },
                   child: Container(
                     padding: const EdgeInsets.symmetric(horizontal: 12),
                     decoration: BoxDecoration(
                       color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.neutralSurface,
                       borderRadius: BorderRadius.circular(12),
                       border: Border.all(color: isSelected ? AppColors.primary : AppColors.neutralBorder),
                     ),
                     child: Row(
                       children: [
                         Icon(style['icon'], color: isSelected ? AppColors.primary : Colors.white70, size: 20),
                         const SizedBox(width: 8),
                         Expanded(
                           child: Text(
                             style['title'],
                             style: GoogleFonts.inter(
                               color: isSelected ? AppColors.primary : Colors.white,
                               fontWeight: FontWeight.w600,
                               fontSize: 13,
                             ),
                             maxLines: 2,
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
            
            // Custom Prompt TextField
            Text(
              'Or Create Custom Scene',
              style: GoogleFonts.inter(
                color: AppColors.neutralTextMuted,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.neutralSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.neutralBorder),
              ),
              child: TextField(
                controller: _customPromptController,
                maxLines: 3,
                minLines: 1,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'e.g., Playing golf in a green polo, standing on a putting green on a sunny day.',
                  hintStyle: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 32),
             SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isGenerating ? null : _generateHeadshot,
                child: _isGenerating 
                  ? const SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                    )
                  : Text(
                      'Generate Headshot (10s)',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
              ),
             ),
          ]
      );
  }

  void _showResultDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.neutralSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your Headshot',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(imageUrl, fit: BoxFit.cover),
              ),
              const SizedBox(height: 16),
               Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.neutralBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 12),
                   Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                         try {
                           if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Starting high-res download...')),
                              );
                           }
                           
                           final imageBytes = await _falService.downloadImageBytes(imageUrl);
                           if (imageBytes == null) throw 'Failed to fetch image bytes';

                           final blob = html.Blob([imageBytes]);
                           final url = html.Url.createObjectUrlFromBlob(blob);
                           final anchor = html.AnchorElement(href: url)
                              ..setAttribute('download', 'headshot_${DateTime.now().millisecondsSinceEpoch}.jpg')
                              ..click();
                           html.Url.revokeObjectUrl(url);

                           if (mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text('Download started!')),
                             );
                             Navigator.pop(context);
                           }
                         } catch (e) {
                           if (mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(content: Text('Error: $e')),
                             );
                           }
                         }
                      },
                      icon: const Icon(Icons.download, size: 18, color: Colors.white),
                      label: const Text('Save', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepHeader(String step, String title) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
