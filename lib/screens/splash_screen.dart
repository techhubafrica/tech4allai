import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/auth_guard.dart';
import '../widgets/redesign_icons.dart';
import 'tools_hub_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..addListener(() {
        setState(() {});
      });

    _controller.forward().then((_) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const AuthGuard(
              child: ToolsHubScreen(),
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A06),
      body: Stack(
        children: [
          // Ambient Glow Orb matching redesign
          Positioned(
            top: -120,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 600,
                height: 400,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0x3DFF7300),
                      Color(0x14FF7300),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // Central Branding Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Squircle Glowing Logo Badge
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFA438), Color(0xFFFF6A00)],
                    ),
                    border: Border.all(color: const Color(0x8CFFE6C3), width: 1.2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x73FF7300),
                        blurRadius: 32,
                        offset: Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Color(0x3DFF5500),
                        blurRadius: 48,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'T',
                      style: GoogleFonts.inter(
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -1.0,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Title
                Text(
                  'Tech4All AI',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.6,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 8),

                // Subtitle with lightning
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RedesignIcons.lightning(size: 15, color: const Color(0xFFFF9233)),
                    const SizedBox(width: 6),
                    Text(
                      'Intelligence Unleashed',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: const Color(0xFF9E968F),
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 52),

                // Glowing Orange Capsule Progress Bar
                Container(
                  width: 210,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0x402C1E15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0x26FFFFFF), width: 0.8),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 210 * _controller.value,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF9534), Color(0xFFFF6701)],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x66FF7300),
                          blurRadius: 10,
                          offset: Offset(0, 1),
                        ),
                      ],
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
}
