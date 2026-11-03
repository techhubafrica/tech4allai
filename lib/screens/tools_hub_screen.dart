import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/redesign_icons.dart';
import 'ai_image_generator_screen.dart';
import 'headshots_screen.dart';
import 'summarizer_screen.dart';
import 'detector_screen.dart';
import 'study_assistant_screen.dart';
import 'code_assistant_screen.dart';
import 'flashcard_assistant_screen.dart';

class ToolsHubScreen extends StatefulWidget {
  const ToolsHubScreen({super.key});

  @override
  State<ToolsHubScreen> createState() => _ToolsHubScreenState();
}

class _ToolsHubScreenState extends State<ToolsHubScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _isSearchOpen = false;

  final List<String> _categories = [
    'All',
    'Creative',
    'Productivity',
    'Code',
    'Study',
  ];

  late final List<Map<String, dynamic>> _allTools;

  @override
  void initState() {
    super.initState();
    _allTools = [
      {
        'id': 'image_gen',
        'title': 'Image\nGenerator',
        'description': 'Text to Image & Photorealism',
        'category': 'Creative',
        'isNew': true,
        'badge': 'NEW',
        'gradient': const [Color(0xFFBA68C8), Color(0xFF7B1FA2)],
        'iconWidget': RedesignIcons.toolImage(size: 22, color: Colors.white),
        'screenBuilder': (BuildContext context) => const AiImageGeneratorScreen(),
      },
      {
        'id': 'headshots',
        'title': 'Pro\nHeadshots',
        'description': 'Studio Quality Portraits',
        'category': 'Creative',
        'isNew': false,
        'badge': 'STUDIO',
        'gradient': const [Color(0xFF42A5F5), Color(0xFF1976D2)],
        'iconWidget': RedesignIcons.toolHeadshots(size: 22, color: Colors.white),
        'screenBuilder': (BuildContext context) => const HeadshotsScreen(),
      },
      {
        'id': 'summarizer',
        'title': 'AI\nSummarizer',
        'description': 'Condense Documents & Articles',
        'category': 'Productivity',
        'isNew': false,
        'badge': 'PRO',
        'gradient': const [Color(0xFFFFA726), Color(0xFFF57C00)],
        'iconWidget': RedesignIcons.toolSummarizer(size: 22, color: Colors.white),
        'screenBuilder': (BuildContext context) => const SummarizerScreen(),
      },
      {
        'id': 'detector',
        'title': 'Detector &\nHumanizer',
        'description': 'AI Verification & Paraphrasing',
        'category': 'Productivity',
        'isNew': false,
        'badge': 'VERIFY',
        'gradient': const [Color(0xFFEF5350), Color(0xFFC62828)],
        'iconWidget': RedesignIcons.toolDetector(size: 22, color: Colors.white),
        'screenBuilder': (BuildContext context) => const DetectorScreen(),
      },
      {
        'id': 'study',
        'title': 'Study\nAssistant',
        'description': 'Homework & Academic Tutoring',
        'category': 'Study',
        'isNew': false,
        'badge': 'TUTOR',
        'gradient': const [Color(0xFF66BB6A), Color(0xFF2E7D32)],
        'iconWidget': RedesignIcons.toolStudy(size: 22, color: Colors.white),
        'screenBuilder': (BuildContext context) => const StudyAssistantScreen(),
      },
      {
        'id': 'code',
        'title': 'Code\nAssistant',
        'description': 'Debug, Refactor & Architecture',
        'category': 'Code',
        'isNew': false,
        'badge': 'DEV',
        'gradient': const [Color(0xFF26C6DA), Color(0xFF0097A7)],
        'iconWidget': RedesignIcons.toolCode(size: 22, color: Colors.white),
        'screenBuilder': (BuildContext context) => const CodeAssistantScreen(),
      },
      {
        'id': 'flashcards',
        'title': 'Flashcard\nAssistant',
        'description': 'AI Study Decks & Active Recall',
        'category': 'Study',
        'isNew': false,
        'badge': 'RECALL',
        'gradient': const [Color(0xFFFFCA28), Color(0xFFFFA000)],
        'iconWidget': RedesignIcons.toolFlashcards(size: 22, color: Colors.white),
        'screenBuilder': (BuildContext context) => const FlashcardAssistantScreen(),
      },
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredTools {
    return _allTools.where((tool) {
      final matchesCategory = _selectedCategory == 'All' || tool['category'] == _selectedCategory;
      if (!matchesCategory) return false;

      if (_searchQuery.trim().isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final title = (tool['title'] as String).replaceAll('\n', ' ').toLowerCase();
      final desc = (tool['description'] as String).toLowerCase();
      return title.contains(query) || desc.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A06),
      body: Stack(
        children: [
          // 1. Top Ambient Glow Orb matching redesign/tech4all_ai_redesign.html
          Positioned(
            top: -100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 600,
                height: 380,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0x38FF7300),
                      const Color(0x14FF7300),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // 2. Main Content Canvas
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double width = constraints.maxWidth;
                int crossAxisCount = 2;
                double childAspectRatio = 0.88;

                if (width >= 1100) {
                  crossAxisCount = 4;
                  childAspectRatio = 1.05;
                } else if (width >= 720) {
                  crossAxisCount = 3;
                  childAspectRatio = 0.98;
                } else if (width < 360) {
                  crossAxisCount = 1;
                  childAspectRatio = 1.8;
                } else {
                  crossAxisCount = 2;
                  childAspectRatio = 0.88;
                }

                final double contentWidth = width >= 1100 ? 1150 : (width >= 720 ? 880 : width);

                return Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: contentWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // --- HEADER ROW MATCHING REDESIGN ARCHITECTURE ---
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Left Glowing Logo Squircle + Title
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(13),
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [Color(0xFFFFA438), Color(0xFFFF6A00)],
                                      ),
                                      border: Border.all(color: const Color(0x8CFFE6C3), width: 1.0),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x66FF7300),
                                          blurRadius: 18,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        'T',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 22,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'AI Tools Hub',
                                        style: GoogleFonts.inter(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: -0.4,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Row(
                                        children: [
                                          RedesignIcons.lightning(size: 13, color: const Color(0xFFFF9233)),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Next-gen intelligent suites',
                                            style: GoogleFonts.inter(
                                              fontSize: 11.5,
                                              color: const Color(0xFF9E968F),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              // Right Search Glass Pill Button
                              _ToolBounceButton(
                                onTap: () {
                                  setState(() {
                                    _isSearchOpen = !_isSearchOpen;
                                    if (!_isSearchOpen) {
                                      _searchController.clear();
                                      _searchQuery = '';
                                    }
                                  });
                                },
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color(0xA640362F),
                                        Color(0xA6261F1A),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: _isSearchOpen
                                          ? const Color(0xFFFF9233)
                                          : const Color(0x24FFFFFF),
                                      width: 1.0,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.35),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                      if (_isSearchOpen)
                                        const BoxShadow(
                                          color: Color(0x4DFF7300),
                                          blurRadius: 12,
                                        ),
                                    ],
                                  ),
                                  child: Center(
                                    child: _isSearchOpen
                                        ? RedesignIcons.close(size: 18, color: Colors.white)
                                        : RedesignIcons.search(size: 18, color: const Color(0xFFD4CFC9)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // --- EXPANDABLE SEARCH PILL BAR ---
                        if (_isSearchOpen)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                            child: Container(
                              height: 46,
                              decoration: BoxDecoration(
                                color: const Color(0x59291D15),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0x59FF9233), width: 1.1),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x33FF7300),
                                    blurRadius: 14,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: Row(
                                children: [
                                  RedesignIcons.search(size: 17, color: const Color(0xFFFF9233)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      autofocus: true,
                                      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                                      cursorColor: const Color(0xFFFF9233),
                                      onChanged: (val) => setState(() => _searchQuery = val),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        isDense: true,
                                        hintText: 'Search AI tools...',
                                        hintStyle: GoogleFonts.inter(
                                          color: const Color(0xFF7E756E),
                                          fontSize: 13.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_searchQuery.isNotEmpty)
                                    GestureDetector(
                                      onTap: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 6),
                                        child: RedesignIcons.close(size: 15, color: const Color(0xFFBEB8B2)),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),

                        // --- SUBTITLE TAGLINE ---
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
                          child: Text(
                            'Empower your workflow with high-performance generative models and productivity engines.',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF8E857D),
                              fontSize: 12.5,
                              height: 1.4,
                            ),
                          ),
                        ),

                        // --- HORIZONTAL CATEGORY PILL SELECTOR ---
                        Container(
                          height: 38,
                          margin: const EdgeInsets.only(bottom: 14),
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _categories.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, idx) {
                              final cat = _categories[idx];
                              final isSelected = _selectedCategory == cat;
                              return _ToolBounceButton(
                                onTap: () => setState(() => _selectedCategory = cat),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(19),
                                    gradient: isSelected
                                        ? const LinearGradient(
                                            colors: [Color(0xFFFF981A), Color(0xFFFF6701)],
                                          )
                                        : const LinearGradient(
                                            colors: [Color(0x8C40362F), Color(0x8C261F1A)],
                                          ),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0x80FFE1B9)
                                          : const Color(0x24FFFFFF),
                                      width: 1.0,
                                    ),
                                    boxShadow: isSelected
                                        ? const [
                                            BoxShadow(
                                              color: Color(0x66FF7300),
                                              blurRadius: 14,
                                              offset: Offset(0, 3),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    cat,
                                    style: GoogleFonts.inter(
                                      color: isSelected ? Colors.white : const Color(0xFFBEB8B2),
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // --- TOOLS GRID CARDS ---
                        Expanded(
                          child: _filteredTools.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: const Color(0x26FF9233),
                                            border: Border.all(color: const Color(0x38FF9233)),
                                          ),
                                          child: Center(
                                            child: RedesignIcons.search(size: 24, color: const Color(0xFFFF9838)),
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        Text(
                                          'No tools found',
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Try searching with a different term or clear filters.',
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFF8E857D),
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : GridView.builder(
                                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 20),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 14,
                                    childAspectRatio: childAspectRatio,
                                  ),
                                  itemCount: _filteredTools.length,
                                  itemBuilder: (context, idx) {
                                    final tool = _filteredTools[idx];
                                    return ToolGridCard(
                                      iconWidget: tool['iconWidget'] as Widget,
                                      title: tool['title'] as String,
                                      description: tool['description'] as String,
                                      badge: tool['badge'] as String,
                                      isNew: tool['isNew'] as bool,
                                      gradientColors: tool['gradient'] as List<Color>,
                                      onTap: () {
                                        final builder = tool['screenBuilder'] as Widget Function(BuildContext);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: builder),
                                        );
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }
}

class ToolGridCard extends StatelessWidget {
  final Widget iconWidget;
  final String title;
  final String description;
  final String badge;
  final bool isNew;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const ToolGridCard({
    super.key,
    required this.iconWidget,
    required this.title,
    required this.description,
    required this.badge,
    required this.isNew,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _ToolBounceButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0x8C302117), // Warm amber glass
              Color(0x991C140D),
            ],
          ),
          border: Border.all(
            color: const Color(0x2BFFFFFF),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
            const BoxShadow(
              color: Color(0x14FF7300),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Squircle Color Badge & Status Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Squircle Glowing Tool Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors.first.withValues(alpha: 0.45),
                        blurRadius: 14,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: iconWidget,
                  ),
                ),

                // Glowing Tag Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isNew
                        ? const Color(0x33FF7300)
                        : const Color(0x264E3A2C),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isNew
                          ? const Color(0xA6FF7300)
                          : const Color(0x33FFFFFF),
                      width: 0.8,
                    ),
                    boxShadow: isNew
                        ? const [
                            BoxShadow(
                              color: Color(0x33FF7300),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    badge,
                    style: GoogleFonts.inter(
                      color: isNew ? const Color(0xFFFF9838) : const Color(0xFFC4B8AF),
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Title
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.3,
                height: 1.22,
              ),
            ),

            const SizedBox(height: 5),

            // Description
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: const Color(0xFF9E968F),
                height: 1.35,
              ),
            ),

            const SizedBox(height: 10),

            // Bottom Arrow Glass Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0x38403226),
                    border: Border.all(color: const Color(0x24FFFFFF), width: 0.8),
                  ),
                  child: Center(
                    child: RedesignIcons.arrowRight(
                      color: const Color(0xFFBEB8B2),
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolBounceButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _ToolBounceButton({required this.child, required this.onTap});

  @override
  State<_ToolBounceButton> createState() => _ToolBounceButtonState();
}

class _ToolBounceButtonState extends State<_ToolBounceButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: widget.child,
      ),
    );
  }
}
