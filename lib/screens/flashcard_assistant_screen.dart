import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/hugging_face_service.dart';
import '../services/supabase_storage_service.dart';
import '../services/subscription_service.dart';
import '../widgets/upgrade_prompt_dialog.dart';
import '../services/chat_history_service.dart';
import '../widgets/chat_history_drawer.dart';
import '../widgets/redesign_icons.dart';
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
  final SubscriptionService _subscriptionService = SubscriptionService();

  String? _activeSessionId;
  List<FlashCardModel> _flashcards = [];
  bool _isLoading = false;

  String _userTier = 'FREE';
  int _textRequestsToday = 0;
  int _textRequestsLimit = 5;
  bool _isLoadingLimitInfo = true;

  XFile? _attachedImage;
  bool _isUploadingImage = false;
  String? _uploadedImageUrl;
  int _currentPage = 0;

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
    _pageController.dispose();
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
        _textRequestsToday = sub['text_requests_today'] ?? 0;
        if (_userTier == 'BASIC') {
          _textRequestsLimit = 50;
        } else if (_userTier == 'PRO') {
          _textRequestsLimit = 150;
        } else if (_userTier == 'SUPERADMIN') {
          _textRequestsLimit = 999999;
        } else {
          _textRequestsLimit = 5;
        }
        _isLoadingLimitInfo = false;
      });
    }
  }

  Future<void> _loadSessionFlashcards(Map<String, dynamic> session) async {
    setState(() => _isLoading = true);
    try {
      final dbMsgs = await _historyService.getMessages(session['id']);
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
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _attachedImage = image;
          _isUploadingImage = true;
          _uploadedImageUrl = null;
        });

        final publicUrl = await _storageService.uploadSelfie(image);
        setState(() {
          if (publicUrl != null) {
            _uploadedImageUrl = publicUrl;
            _showNotification('Study material image uploaded');
          } else {
            _attachedImage = null;
            _showNotification('Failed to upload image', isError: true);
          }
          _isUploadingImage = false;
        });
      }
    } catch (_) {
      setState(() {
        _isUploadingImage = false;
        _attachedImage = null;
      });
      _showNotification('Could not access image', isError: true);
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
      _showNotification('Please enter notes or upload an image first', isError: true);
      return;
    }

    final allowed = await _subscriptionService.checkAndIncrementTextUsage();
    if (!allowed && _userTier != 'SUPERADMIN') {
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
      final responseText = await _hfService.generateFlashcards(prompt, _uploadedImageUrl);
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
          _showNotification('Generated ${_flashcards.length} flashcards!');
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
        } catch (_) {}
      }
    } catch (_) {
      _showNotification('Failed to generate flashcards. Please try again.', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildQuickAction(String title) {
    return _FlashcardBounceButton(
      onTap: () {
        setState(() {
          _promptController.text = title;
        });
        _generateFlashcards();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: const Color(0xFF1E140C),
          border: Border.all(color: const Color(0x38FF7300), width: 1.0),
        ),
        child: Center(
          child: Text(
            title,
            style: GoogleFonts.inter(
              color: const Color(0xFFD4C9C0),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
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
        featureType: 'flashcards',
        activeSessionId: _activeSessionId,
        onSessionSelected: (session) => _loadSessionFlashcards(session),
        onNewChatStarted: () {
          setState(() {
            _activeSessionId = null;
            _flashcards = [];
            _currentPage = 0;
            _promptController.clear();
            _attachedImage = null;
            _uploadedImageUrl = null;
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

                // 2. QUICK ACTIONS & LIMITS HEADER
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 860),
                    child: Column(
                      children: [
                        if (!_isLoadingLimitInfo) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFFFF9233),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Plan: $_userTier',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: const Color(0xFFC7BEB4),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  _userTier == 'SUPERADMIN'
                                      ? 'Daily: Unlimited'
                                      : 'Daily: $_textRequestsToday / $_textRequestsLimit queries',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: _textRequestsToday >= _textRequestsLimit
                                        ? const Color(0xFFFF5252)
                                        : const Color(0xFF8E857D),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Quick Prompts Row
                        SizedBox(
                          height: 44,
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
                              _buildQuickAction('Spanish Vocabulary'),
                              const SizedBox(width: 8),
                              _buildQuickAction('Computer Science DSA'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. MAIN FLASHCARD OR EMPTY DISPLAY AREA
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 860),
                      child: _buildMainContent(),
                    ),
                  ),
                ),

                // 4. ATTACHED IMAGE PREVIEW
                if (_attachedImage != null) _buildImagePreview(),

                // 5. INPUT COMPOSER SECTION
                _buildInputSection(),
              ],
            ),
          ),

          // 6. FLOATING TOAST NOTIFICATION
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
          _FlashcardBounceButton(
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
              ),
              child: Center(
                child: RedesignIcons.arrowBack(size: 21, color: Colors.white),
              ),
            ),
          ),

          // Title with Squircle Flashcard Badge
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF26A69A), Color(0xFF00796B)],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66009688),
                      blurRadius: 12,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: RedesignIcons.toolFlashcards(size: 17, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Flashcards Studio',
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
            builder: (context) => _FlashcardBounceButton(
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

  Widget _buildMainContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0x26FF7300),
                border: Border.all(color: const Color(0x66FF7300), width: 1.2),
              ),
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFFFF7A00)),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _isUploadingImage ? 'Uploading study materials...' : 'Generating interactive flashcards...',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
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
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0x1AFFFFFF),
                  border: Border.all(color: const Color(0x26FFFFFF), width: 1),
                ),
                child: Center(
                  child: RedesignIcons.toolFlashcards(size: 32, color: const Color(0xFFFF9233)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No Flashcards Generated Yet',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Type a study topic (e.g. "Biology Mitosis") or snap a photo of notes/textbook to generate cards.',
                style: GoogleFonts.inter(color: const Color(0xFF8E857D), height: 1.4, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Progress Pill
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: const Color(0x1F26A69A),
            border: Border.all(color: const Color(0x6626A69A), width: 0.9),
          ),
          child: Text(
            'Card ${_currentPage + 1} of ${_flashcards.length}',
            style: GoogleFonts.inter(color: const Color(0xFF26A69A), fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),

        // PageView for swipeable cards
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: _flashcards.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
                child: RedesignFlashCardWidget(card: _flashcards[index]),
              );
            },
          ),
        ),

        // Navigation controls
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _FlashcardBounceButton(
                onTap: _currentPage > 0
                    ? () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage > 0 ? const Color(0xFF1E140C) : const Color(0xFF140D08),
                    border: Border.all(color: const Color(0x28FFFFFF), width: 1),
                  ),
                  child: Center(
                    child: RedesignIcons.arrowBack(
                      size: 18,
                      color: _currentPage > 0 ? Colors.white : Colors.white30,
                    ),
                  ),
                ),
              ),

              _FlashcardBounceButton(
                onTap: () {
                  setState(() => _flashcards = []);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0xFF1E140C),
                    border: Border.all(color: const Color(0x38FF7300), width: 1.0),
                  ),
                  child: Row(
                    children: [
                      RedesignIcons.history(size: 14, color: const Color(0xFFFF9233)),
                      const SizedBox(width: 6),
                      Text(
                        'New Deck',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              _FlashcardBounceButton(
                onTap: _currentPage < _flashcards.length - 1
                    ? () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage < _flashcards.length - 1
                        ? const Color(0xFF1E140C)
                        : const Color(0xFF140D08),
                    border: Border.all(color: const Color(0x28FFFFFF), width: 1),
                  ),
                  child: Center(
                    child: RedesignIcons.arrowRight(
                      size: 18,
                      color: _currentPage < _flashcards.length - 1 ? Colors.white : Colors.white30,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E140C),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x66FF7300), width: 1.0),
          ),
          child: Row(
            children: [
              RedesignIcons.gallery(size: 20, color: const Color(0xFFFF9233)),
              const SizedBox(width: 10),
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
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF7A00)),
                )
              else
                GestureDetector(
                  onTap: _clearAttachedImage,
                  child: RedesignIcons.close(size: 16, color: const Color(0xFF8E857D)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0A06),
        border: Border(top: BorderSide(color: Color(0x1AFFFFFF), width: 1.0)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Row(
            children: [
              // Camera Button
              _FlashcardBounceButton(
                onTap: () => _pickImage(ImageSource.camera),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xA640362F), Color(0xA6261F1A)],
                    ),
                    border: Border.all(color: const Color(0x24FFFFFF), width: 1.0),
                  ),
                  child: Center(
                    child: RedesignIcons.camera(size: 19, color: const Color(0xFFD4CFC9)),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Gallery Button
              _FlashcardBounceButton(
                onTap: () => _pickImage(ImageSource.gallery),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xA640362F), Color(0xA6261F1A)],
                    ),
                    border: Border.all(color: const Color(0x24FFFFFF), width: 1.0),
                  ),
                  child: Center(
                    child: RedesignIcons.gallery(size: 19, color: const Color(0xFFD4CFC9)),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // TextField
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A120B),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0x26FFFFFF), width: 1.0),
                  ),
                  child: TextField(
                    controller: _promptController,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13.5),
                    maxLines: 3,
                    minLines: 1,
                    cursorColor: const Color(0xFFFF7A00),
                    decoration: InputDecoration(
                      hintText: 'Enter topic or paste notes...',
                      hintStyle: GoogleFonts.inter(color: const Color(0xFF756C64), fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: (_) => _generateFlashcards(),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Send Action Button
              _FlashcardBounceButton(
                onTap: _isLoading || _isUploadingImage ? null : _generateFlashcards,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
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
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : RedesignIcons.send(size: 20, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RedesignFlashCardWidget extends StatefulWidget {
  final FlashCardModel card;

  const RedesignFlashCardWidget({super.key, required this.card});

  @override
  State<RedesignFlashCardWidget> createState() => _RedesignFlashCardWidgetState();
}

class _RedesignFlashCardWidgetState extends State<RedesignFlashCardWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
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
        return const Color(0xFF00E676);
      case 'hard':
        return const Color(0xFFFF5252);
      case 'medium':
      default:
        return const Color(0xFFFF9233);
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
              ..setEntry(3, 2, 0.001)
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
        borderRadius: BorderRadius.circular(26),
        gradient: const RadialGradient(
          center: Alignment(0.0, -0.6),
          radius: 1.3,
          colors: [
            Color(0xFF2C1E14),
            Color(0xFF1B130D),
            Color(0xFF120C08),
          ],
        ),
        border: Border.all(color: const Color(0x59FF7300), width: 1.4),
        boxShadow: [
          const BoxShadow(
            blurRadius: 28,
            offset: Offset(0, 8),
            color: Color(0x38FF7300),
          ),
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(0, 8),
            color: Colors.black.withValues(alpha: 0.5),
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
                  RedesignIcons.aiSparkles(size: 16, color: const Color(0xFFFF9233)),
                  const SizedBox(width: 8),
                  Text(
                    'QUESTION',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFF9233),
                      letterSpacing: 1.4,
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
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.touch_app_rounded, color: Color(0xFF8E857D), size: 16),
              const SizedBox(width: 6),
              Text(
                'Tap card to flip & reveal answer',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF8E857D)),
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
        borderRadius: BorderRadius.circular(26),
        gradient: const RadialGradient(
          center: Alignment(0.0, -0.6),
          radius: 1.3,
          colors: [
            Color(0xFF132418),
            Color(0xFF0F1A12),
            Color(0xFF0A120D),
          ],
        ),
        border: Border.all(color: const Color(0x5900E676), width: 1.4),
        boxShadow: [
          const BoxShadow(
            blurRadius: 28,
            offset: Offset(0, 8),
            color: Color(0x3800E676),
          ),
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(0, 8),
            color: Colors.black.withValues(alpha: 0.5),
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
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF00E676), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'ANSWER',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF00E676),
                      letterSpacing: 1.4,
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
              letterSpacing: -0.3,
            ),
          ),
          if (widget.card.explanation != null && widget.card.explanation!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              widget.card.explanation!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: const Color(0xFFB9DEC2),
                height: 1.45,
              ),
            ),
          ],
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.touch_app_rounded, color: Color(0xFF8E857D), size: 16),
              const SizedBox(width: 6),
              Text(
                'Tap card to flip back to question',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF8E857D)),
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: diffColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: diffColor.withValues(alpha: 0.4), width: 1),
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

class _FlashcardBounceButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _FlashcardBounceButton({required this.child, this.onTap});

  @override
  State<_FlashcardBounceButton> createState() => _FlashcardBounceButtonState();
}

class _FlashcardBounceButtonState extends State<_FlashcardBounceButton> with SingleTickerProviderStateMixin {
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
