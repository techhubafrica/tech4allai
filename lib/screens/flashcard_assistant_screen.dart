import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/colors.dart';
import '../services/hugging_face_service.dart';
import '../services/supabase_storage_service.dart';
import '../services/subscription_service.dart';
import '../widgets/upgrade_prompt_dialog.dart';
import '../services/chat_history_service.dart';
import '../widgets/chat_history_drawer.dart';
import 'tools_hub_screen.dart';

class FlashCardModel {
  final String front;
  final String back;
  final String? explanation;
  final String difficulty;

  FlashCardModel({
    required this.front,
    required this.back,
    this.explanation,
    required this.difficulty,
  });

  factory FlashCardModel.fromJson(Map<String, dynamic> json) {
    return FlashCardModel(
      front: json['front'] ?? '',
      back: json['back'] ?? '',
      explanation: json['explanation'],
      difficulty: json['difficulty'] ?? 'medium',
    );
  }
}

class FlashcardAssistantScreen extends StatefulWidget {
  const FlashcardAssistantScreen({super.key});

  @override
  State<FlashcardAssistantScreen> createState() => _FlashcardAssistantScreenState();
}

class _FlashcardAssistantScreenState extends State<FlashcardAssistantScreen> {
  final TextEditingController _promptController = TextEditingController();
  final HuggingFaceService _hfService = HuggingFaceService();
  final SupabaseStorageService _storageService = SupabaseStorageService();
  final ImagePicker _picker = ImagePicker();
  final PageController _pageController = PageController();

  final ChatHistoryService _historyService = ChatHistoryService();
  String? _activeSessionId;

  List<FlashCardModel> _flashcards = [];
  bool _isLoading = false;

  Future<void> _loadSessionFlashcards(Map<String, dynamic> session) async {
    setState(() => _isLoading = true);
    try {
      final dbMsgs = await _historyService.getMessages(session['id']);
      // Find the message containing cards metadata
      final cardMsg = dbMsgs.firstWhere(
        (m) => m['metadata'] != null && m['metadata']['cards'] != null,
        orElse: () => <String, dynamic>{},
      );
      if (cardMsg.isNotEmpty) {
        final List<dynamic> cardsJson = cardMsg['metadata']['cards'];
        setState(() {
          _flashcards = cardsJson.map((c) => FlashCardModel.fromJson(c)).toList();
          _activeSessionId = session['id'];
          _currentPage = 0;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading flashcards from history: $e');
      setState(() => _isLoading = false);
    }
  }

  final SubscriptionService _subscriptionService = SubscriptionService();
  String _userTier = 'FREE';
  int _textRequestsToday = 0;
  int _textRequestsLimit = 5;
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
        _textRequestsToday = sub['text_requests_today'] ?? 0;
        if (_userTier == 'BASIC') {
          _textRequestsLimit = 50;
        } else if (_userTier == 'PRO') {
          _textRequestsLimit = 150;
        } else {
          _textRequestsLimit = 5;
        }
        _isLoadingLimitInfo = false;
      });
    }
  }
  
  // Image attachments
  XFile? _attachedImage;
  bool _isUploadingImage = false;
  String? _uploadedImageUrl;

  int _currentPage = 0;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _attachedImage = image;
          _isUploadingImage = true;
          _uploadedImageUrl = null;
        });

        // Upload image to Supabase storage
        final publicUrl = await _storageService.uploadSelfie(image);
        
        setState(() {
          if (publicUrl != null) {
            _uploadedImageUrl = publicUrl;
          } else {
            _attachedImage = null;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to upload image. Please try again.')),
            );
          }
          _isUploadingImage = false;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      setState(() {
        _isUploadingImage = false;
        _attachedImage = null;
      });
    }
  }

  void _clearAttachedImage() {
    setState(() {
      _attachedImage = null;
      _uploadedImageUrl = null;
    });
  }

  Future<void> _generateFlashcards() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty && _uploadedImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter notes or upload an image first.')),
      );
      return;
    }

    // Limits check
    final allowed = await _subscriptionService.checkAndIncrementTextUsage();
    if (!allowed) {
      if (mounted) {
        UpgradePromptDialog.show(
          context,
          title: "Daily Limit Reached",
          message: "You have completed your daily quota of requests on the $_userTier tier. Upgrade to BASIC or PRO to get up to 150 requests per day!",
        );
      }
      return;
    }
    _refreshLimitInfo();

    setState(() {
      _isLoading = true;
      _flashcards = [];
    });

    try {
      // API call to Hugging Face
      final responseText = await _hfService.generateFlashcards(prompt, _uploadedImageUrl);
      
      // Clean JSON formatting from AI response
      String cleanJson = responseText.trim();
      if (cleanJson.startsWith('```')) {
        int firstNewLine = cleanJson.indexOf('\n');
        if (firstNewLine != -1) {
          cleanJson = cleanJson.substring(firstNewLine + 1);
        }
      }
      if (cleanJson.endsWith('```')) {
        cleanJson = cleanJson.substring(0, cleanJson.lastIndexOf('```'));
      }
      cleanJson = cleanJson.trim();

      final Map<String, dynamic> decoded = jsonDecode(cleanJson);
      final List<dynamic> cardsJson = decoded['cards'] ?? [];

      setState(() {
        _flashcards = cardsJson.map((c) => FlashCardModel.fromJson(c)).toList();
        _currentPage = 0;
        if (_flashcards.isNotEmpty) {
          _promptController.clear();
          _attachedImage = null;
          _uploadedImageUrl = null;
        }
      });

      if (_flashcards.isNotEmpty) {
        try {
          final title = prompt.isNotEmpty ? prompt : 'Image Flashcards';
          final session = await _historyService.createSession('flashcards', initialTitle: title);
          _activeSessionId = session['id'];
          await _historyService.addMessage(
            _activeSessionId!,
            isUser: true,
            message: prompt.isEmpty ? 'Generate flashcards from attached image.' : prompt,
          );
          await _historyService.addMessage(
            _activeSessionId!,
            isUser: false,
            message: 'Generated ${_flashcards.length} flashcards successfully.',
            metadata: {'cards': cardsJson},
          );
        } catch (dbErr) {
          print('Error saving flashcard deck to history database: $dbErr');
        }
      }
    } catch (e) {
      print('Error parsing flashcards: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to parse AI flashcard response. Please try again.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildQuickAction(String title) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _promptController.text = title;
        });
        _generateFlashcards();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.neutralSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amberAccent.withOpacity(0.5)),
        ),
        child: Center(
          child: Text(
            title,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      drawer: ChatHistoryDrawer(
        featureType: 'flashcards',
        activeSessionId: _activeSessionId,
        onSessionSelected: (session) {
          _loadSessionFlashcards(session);
        },
        onNewChatStarted: () {
          setState(() {
            _activeSessionId = null;
            _flashcards = [];
            _currentPage = 0;
          });
        },
      ),
      appBar: AppBar(
        title: Text(
          'Flashcard',
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
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.history, color: Colors.white),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16, left: 8),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.neutralSurface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.neutralBorder),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!_isLoadingLimitInfo) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Account Plan: $_userTier',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.neutralTextMuted,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Daily Limit: $_textRequestsToday / $_textRequestsLimit queries',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: _textRequestsToday >= _textRequestsLimit ? Colors.redAccent : AppColors.neutralTextMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Quick Tools/Prompts
            Container(
              height: 50,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildQuickAction('Biology Mitosis'),
                  const SizedBox(width: 8),
                  _buildQuickAction('Chemistry Elements'),
                  const SizedBox(width: 8),
                  _buildQuickAction('History Dates'),
                  const SizedBox(width: 8),
                  _buildQuickAction('Spanish Vocab'),
                ],
              ),
            ),
            
            // Onboarding text / Description
            if (_flashcards.isEmpty && !_isLoading)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Text(
                  'Upload study materials or enter text below to generate custom AI flashcards.',
                  style: GoogleFonts.inter(color: AppColors.neutralTextMuted, height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ),

            // Main Display Area
            Expanded(
              child: _buildMainContent(),
            ),

            // Attached Image Preview
            if (_attachedImage != null) _buildImagePreview(),

            // Input Control Section
            _buildInputSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
            const SizedBox(height: 24),
            Text(
              _isUploadingImage ? 'Uploading study materials...' : 'Creating smart flashcards...',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_flashcards.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.amberAccent.withOpacity(0.06),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.amberAccent.withOpacity(0.12), width: 2),
                ),
                child: const Icon(
                  Icons.help_outline,
                  size: 64,
                  color: Colors.amberAccent,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No flashcards generated',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Type a topic (e.g. "Biology Mitosis") or snap a photo of your textbook notes to begin.',
                style: GoogleFonts.inter(color: AppColors.neutralTextMuted, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Progress text
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Card ${_currentPage + 1} of ${_flashcards.length}',
            style: GoogleFonts.inter(color: AppColors.neutralTextMuted, fontWeight: FontWeight.w600),
          ),
        ),
        
        // PageView for swipeable cards
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _flashcards.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: FlashCardWidget(card: _flashcards[index]),
              );
            },
          ),
        ),

        // Navigation controls
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white, size: 32),
                onPressed: _currentPage > 0
                    ? () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
              ),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _flashcards = [];
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neutralSurface,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.neutralBorder),
                  ),
                ),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reset'),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white, size: 32),
                onPressed: _currentPage < _flashcards.length - 1
                    ? () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.neutralSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neutralBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.image, color: Colors.amberAccent, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _attachedImage!.name,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_isUploadingImage)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppColors.primary)),
            )
          else
            IconButton(
              icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
              onPressed: _clearAttachedImage,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.backgroundDark,
        border: Border(top: BorderSide(color: AppColors.neutralBorder, width: 0.5)),
      ),
      child: Row(
        children: [
          // Attachment options
          IconButton(
            icon: const Icon(Icons.add_a_photo, color: Colors.white70),
            onPressed: () => _pickImage(ImageSource.camera),
          ),
          IconButton(
            icon: const Icon(Icons.photo_library, color: Colors.white70),
            onPressed: () => _pickImage(ImageSource.gallery),
          ),
          const SizedBox(width: 8),
          
          // TextField
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.neutralSurface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.neutralBorder),
              ),
              child: TextField(
                controller: _promptController,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Enter topic or copy notes...',
                  hintStyle: GoogleFonts.inter(color: AppColors.neutralTextMuted),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Send Button
          GestureDetector(
            onTap: _isLoading || _isUploadingImage ? null : _generateFlashcards,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_upward, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class FlashCardWidget extends StatefulWidget {
  final FlashCardModel card;

  const FlashCardWidget({
    super.key,
    required this.card,
  });

  @override
  State<FlashCardWidget> createState() => _FlashCardWidgetState();
}

class _FlashCardWidgetState extends State<FlashCardWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = Tween<double>(begin: 0.0, end: pi).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() {
      _isFront = !_isFront;
    });
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.greenAccent;
      case 'hard':
        return Colors.redAccent;
      case 'medium':
      default:
        return Colors.amberAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flipCard,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value;
          final isBack = angle >= pi / 2;
          
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..rotateY(angle),
            alignment: Alignment.center,
            child: isBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: _buildCardBack(),
                  )
                : _buildCardFront(),
          );
        },
      ),
    );
  }

  Widget _buildCardFront() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1F1C18),
            Color(0xFF282520),
          ],
        ),
        border: Border.all(color: Colors.amberAccent.withOpacity(0.12), width: 1.5),
        boxShadow: const [
          BoxShadow(
            blurRadius: 20,
            offset: Offset(0, 8),
            color: Color(0x66000000),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.help_outline, color: Colors.amberAccent, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'QUESTION',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.amberAccent,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              _buildDifficultyBadge(),
            ],
          ),
          const Spacer(),
          Text(
            widget.card.front,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.touch_app, color: Colors.white30, size: 16),
              const SizedBox(width: 6),
              Text(
                'Tap to flip and view answer',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white30),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF151D18),
            Color(0xFF1E2820),
          ],
        ),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.12), width: 1.5),
        boxShadow: const [
          BoxShadow(
            blurRadius: 20,
            offset: Offset(0, 8),
            color: Color(0x66000000),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'ANSWER',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.greenAccent,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              _buildDifficultyBadge(),
            ],
          ),
          const Spacer(),
          Text(
            widget.card.back,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          if (widget.card.explanation != null && widget.card.explanation!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              widget.card.explanation!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
          ],
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.touch_app, color: Colors.white30, size: 16),
              const SizedBox(width: 6),
              Text(
                'Tap to flip back',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white30),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyBadge() {
    final diffColor = _getDifficultyColor(widget.card.difficulty);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: diffColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: diffColor.withOpacity(0.3), width: 1),
      ),
      child: Text(
        widget.card.difficulty.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: diffColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
