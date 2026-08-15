import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:universal_html/html.dart' as html;
import 'package:image_picker/image_picker.dart';
import '../constants/colors.dart';
import '../services/fal_api_service.dart';
import '../services/supabase_storage_service.dart';
import '../services/subscription_service.dart';
import '../widgets/upgrade_prompt_dialog.dart';
import '../services/chat_history_service.dart';
import '../widgets/chat_history_drawer.dart';
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
  String? _activeSessionId;

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
      print('Error loading image from history: $e');
      setState(() => _isLoading = false);
    }
  }

  final SubscriptionService _subscriptionService = SubscriptionService();
  String _userTier = 'FREE';
  double _userCredits = 0.0;
  int _imagesToday = 0;
  int _imagesThisMonth = 0;
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
        _imagesToday = sub['images_today'] ?? 0;
        _imagesThisMonth = sub['images_this_month'] ?? 0;
        _isLoadingLimitInfo = false;
      });
    }
  }

  String? _generatedImageUrl;
  bool _isLoading = false;
  String _selectedAspectRatio = '1:1';
  final List<String> _aspectRatios = ['1:1', '16:9', '9:16', '4:3', '3:4', '21:9'];

  int _selectedTabIndex = 0; // 0: With prompt, 1: Upload Image
  List<XFile> _referenceImages = [];

  Future<void> _pickImages() async {
    if (_referenceImages.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only upload up to 3 reference images.')),
      );
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
    } catch (e) {
      print('Error picking images: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _referenceImages.removeAt(index);
    });
  }

  Future<void> _generateImage() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _isLoading = true;
      _generatedImageUrl = null;
    });

    final isFree = _userTier == 'FREE';
    final modelEndpoint = _selectedTabIndex == 0
        ? (isFree ? 'fal-ai/flux/schnell' : 'fal-ai/nano-banana-2')
        : (isFree ? 'fal-ai/flux-2/klein/4b/edit/lora' : 'fal-ai/nano-banana-pro/edit');

    // Fetch dynamic model cost
    final double cost = await _subscriptionService.getModelPrice(modelEndpoint);

    // Verify limits and deduct credits atomically
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
          message: "$limitMsg Upgrade to BASIC or PRO to get shared credit allocations and higher quality models!",
        );
      }
      return;
    }
    
    _refreshLimitInfo();

    String? imageUrl;
    
    if (_selectedTabIndex == 0) {
      // Normal Text-to-Image
      imageUrl = await _falService.generateImageFromPrompt(
        prompt: prompt,
        aspectRatio: _selectedAspectRatio,
        isFree: isFree,
      );
    } else {
      // Image-to-Image with References
      if (_referenceImages.isEmpty) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Please upload at least 1 reference image.')),
        );
        return;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Uploading reference images...')),
      );

      List<String> uploadedUrls = [];
      for (var file in _referenceImages) {
         final publicUrl = await _storageService.uploadSelfie(file);
         if (publicUrl != null) {
            uploadedUrls.add(publicUrl);
         }
      }

      if (uploadedUrls.isEmpty) {
         setState(() => _isLoading = false);
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Failed to upload images. Please try again.')),
         );
         return;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Generating image...')),
      );

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
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Failed to generate image. Please try again.')),
          );
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
        } catch (dbErr) {
          print('Error saving image to history database: $dbErr');
        }
      }
    }
  }

  Future<void> _saveImage() async {
    if (_generatedImageUrl == null) return;
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fetching high-res image...')),
        );
      }
      
      final bytes = await _falService.downloadImageBytes(_generatedImageUrl!);
      if (bytes == null) throw 'Failed to download bytes';

      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', 'ai_image_${DateTime.now().millisecondsSinceEpoch}.jpg')
        ..click();
      html.Url.revokeObjectUrl(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download started!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      drawer: ChatHistoryDrawer(
        featureType: 'image_gen',
        activeSessionId: _activeSessionId,
        onSessionSelected: (session) {
          _loadSessionImage(session);
        },
        onNewChatStarted: () {
          setState(() {
            _activeSessionId = null;
            _generatedImageUrl = null;
            _promptController.clear();
            _referenceImages.clear();
          });
        },
      ),
      appBar: AppBar(
        title: Text(
          'Image Generator',
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
          const SizedBox(width: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.neutralSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.neutralBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _userTier == 'FREE' ? Icons.bolt : Icons.stars,
                    color: AppColors.primary,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isLoadingLimitInfo ? 'Loading...' : _userTier,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Center(
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.neutralSurface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.neutralBorder),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 16),
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
                          ? 'Daily: $_imagesToday / 5 | Monthly: $_imagesThisMonth / 25'
                          : 'Balance: \$${_userCredits.toStringAsFixed(2)} USD',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.neutralTextMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _userTier == 'FREE' ? 'Using Schnell Model' : 'Using Pro Models',
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Custom Tabs
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: AppColors.neutralSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.neutralBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedTabIndex = 0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _selectedTabIndex == 0 ? AppColors.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'With prompt',
                                  style: GoogleFonts.inter(
                                    color: _selectedTabIndex == 0 ? Colors.white : AppColors.neutralTextMuted,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedTabIndex = 1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _selectedTabIndex == 1 ? AppColors.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Upload Image',
                                  style: GoogleFonts.inter(
                                    color: _selectedTabIndex == 1 ? Colors.white : AppColors.neutralTextMuted,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Main Image Area
                    Stack(
                      children: [
                        Container(
                          height: 400,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.neutralSurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.neutralBorder),
                          ),
                          child: _isLoading 
                            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                            : _generatedImageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(_generatedImageUrl!, fit: BoxFit.contain),
                                )
                              : Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.image_outlined, size: 64, color: AppColors.neutralTextMuted),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Enter a prompt to generate an image',
                                        style: GoogleFonts.inter(color: AppColors.neutralTextMuted),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                        if (_generatedImageUrl != null)
                          Positioned(
                            bottom: 16,
                            right: 16,
                            child: FloatingActionButton(
                              backgroundColor: AppColors.primary,
                              onPressed: _saveImage,
                              child: const Icon(Icons.download, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Prompt Input Area
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.neutralSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.neutralBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Prompt',
                            style: GoogleFonts.inter(
                              color: AppColors.neutralTextMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                            TextField(
                              controller: _promptController,
                              maxLines: 3,
                              style: GoogleFonts.inter(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Describe the image you want to generate...',
                                hintStyle: GoogleFonts.inter(color: AppColors.neutralTextMuted),
                                border: InputBorder.none,
                              ),
                            ),
                            
                            if (_selectedTabIndex == 1) ...[
                              const SizedBox(height: 16),
                              Text(
                                'Reference Images (${_referenceImages.length}/3)',
                                style: GoogleFonts.inter(
                                  color: AppColors.neutralTextMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (_referenceImages.isNotEmpty)
                                SizedBox(
                                  height: 80,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _referenceImages.length,
                                    itemBuilder: (context, index) {
                                      return Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Container(
                                            margin: const EdgeInsets.only(right: 12),
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: AppColors.primary),
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: const Center(
                                                child: Icon(Icons.image, color: Colors.white, size: 30),
                                              ), // Because we're using XFile on web, standard Image.file doesn't work well without path mapping, so we show an icon or memory image if we load bytes. Keeping it simple.
                                            ),
                                          ),
                                          Positioned(
                                            top: -5,
                                            right: 5,
                                            child: GestureDetector(
                                              onTap: () => _removeImage(index),
                                              child: Container(
                                                padding: const EdgeInsets.all(2),
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.close, color: Colors.white, size: 14),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              const SizedBox(height: 8),
                              if (_referenceImages.length < 3)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.neutralSurface,
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: AppColors.neutralBorder),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: _pickImages,
                                  icon: const Icon(Icons.add_photo_alternate, size: 18),
                                  label: Text('Add Reference', style: GoogleFonts.inter(fontSize: 13)),
                                ),
                            ],
                            
                            if (_selectedTabIndex == 0) ...[
                              const SizedBox(height: 16),
                              Text(
                                'Aspect Ratio',
                                style: GoogleFonts.inter(
                                  color: AppColors.neutralTextMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _selectedAspectRatio,
                                dropdownColor: AppColors.neutralSurface,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppColors.backgroundDark,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppColors.neutralBorder),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppColors.neutralBorder),
                                  ),
                                ),
                                style: GoogleFonts.inter(color: Colors.white),
                                items: _aspectRatios.map((ratio) {
                                  return DropdownMenuItem(
                                    value: ratio,
                                    child: Text(ratio),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedAspectRatio = newValue;
                                    });
                                  }
                                },
                              ),
                            ],
                            const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _isLoading ? null : _generateImage,
                              child: Text(
                                _isLoading ? 'Generating...' : 'Generate Image',
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
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
