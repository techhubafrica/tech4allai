import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import 'ai_image_generator_screen.dart';
import 'headshots_screen.dart';
import 'summarizer_screen.dart';
import 'detector_screen.dart';
import 'study_assistant_screen.dart';
import 'code_assistant_screen.dart';
import 'flashcard_assistant_screen.dart';

class ToolsHubScreen extends StatelessWidget {
  const ToolsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
             // Custom Header matching others
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                       Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            'T',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'AI Tools Hub',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.neutralSurface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.neutralBorder),
                    ),
                    child: const Icon(Icons.search, color: Colors.white, size: 24),
                  ),
                ],
              ),
            ),
             Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Text(
                'Empowering your creativity & productivity with state-of-the-art AI models.',
                style: GoogleFonts.inter(color: AppColors.neutralTextMuted, height: 1.4),
              ),
            ),
            
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85, // Adjust for taller cards
                children: [
                  ToolGridCard(
                    icon: Icons.image,
                    title: 'Image\nGenerator',
                    description: 'Text to Image',
                    color: Colors.purpleAccent,
                    isNew: true,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiImageGeneratorScreen())),
                  ),
                  ToolGridCard(
                    icon: Icons.face,
                    title: 'Pro\nHeadshots',
                    description: 'Studio Quality',
                    color: Colors.blueAccent,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HeadshotsScreen())),
                  ),
                  ToolGridCard(
                    icon: Icons.summarize,
                    title: 'AI\nSummarizer',
                    description: 'Condense Text',
                    color: Colors.orangeAccent,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SummarizerScreen())),
                  ),
                  ToolGridCard(
                    icon: Icons.security,
                    title: 'Detector &\nHumanizer',
                    description: 'AI Check',
                    color: Colors.redAccent,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DetectorScreen())),
                  ),
                  ToolGridCard(
                    icon: Icons.school,
                    title: 'Study\nAssistant',
                    description: 'Homework Help',
                    color: Colors.greenAccent,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudyAssistantScreen())),
                  ),
                  ToolGridCard(
                    icon: Icons.code,
                    title: 'Code\nAssistant',
                    description: 'Debug & Write',
                    color: Colors.cyanAccent,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CodeAssistantScreen()));
                    },
                  ),
                  ToolGridCard(
                    icon: Icons.auto_awesome,
                    title: 'FlashCard\nAssistant',
                    description: 'AI Study Cards',
                    color: Colors.amberAccent,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const FlashcardAssistantScreen()));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }
}

class ToolGridCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final bool isNew;
  final VoidCallback? onTap;

  const ToolGridCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    this.isNew = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.neutralSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.neutralBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                if (isNew)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'NEW',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.neutralTextMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
