import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/pricing_screen.dart';
import 'redesign_icons.dart';

class UpgradePromptDialog extends StatelessWidget {
  final String title;
  final String message;

  const UpgradePromptDialog({
    super.key,
    required this.title,
    required this.message,
  });

  static void show(BuildContext context, {required String title, required String message}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      builder: (context) => UpgradePromptDialog(title: title, message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLimit = title.toLowerCase().contains('limit');

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const RadialGradient(
            center: Alignment(0.0, -0.65),
            radius: 1.35,
            colors: [
              Color(0xFF332014), // Warm amber ambient glow
              Color(0xFF1E140E),
              Color(0xFF110B07), // Obsidian edge
            ],
          ),
          border: Border.all(color: const Color(0x66FF8A24), width: 1.4),
          boxShadow: [
            const BoxShadow(
              color: Color(0x4DFF7300),
              blurRadius: 40,
              offset: Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.8),
              blurRadius: 30,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Bar: Badge Tag and Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0x2EB97D14),
                      border: Border.all(color: const Color(0xA6EEAF37), width: 1.0),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x26EEAF37),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RedesignIcons.lightning(size: 12, color: const Color(0xFFF6C15C)),
                        const SizedBox(width: 4),
                        Text(
                          isLimit ? 'QUOTA REACHED' : 'PRO ACCESS REQUIRED',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: const Color(0xFFF6C15C),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _DialogBounceButton(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x8C40362F), Color(0x8C261F1A)],
                        ),
                        border: Border.all(color: const Color(0x2EFFFFFF), width: 1.0),
                      ),
                      child: Center(
                        child: RedesignIcons.close(size: 15, color: const Color(0xFFD4CFC9)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Glowing Squircle Center Emblem
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFA438), Color(0xFFFF6A00)],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x80FF7300),
                      blurRadius: 24,
                      spreadRadius: 1,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: isLimit
                      ? RedesignIcons.lightning(size: 30, color: Colors.white)
                      : RedesignIcons.aiSparkles(size: 30, color: Colors.white),
                ),
              ),

              const SizedBox(height: 18),

              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.4,
                ),
              ),

              const SizedBox(height: 10),

              // Message Body
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  color: const Color(0xFFD2C7BD),
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 18),

              // Feature Highlights Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0x47261A12),
                  border: Border.all(color: const Color(0x33FF9838), width: 1.0),
                ),
                child: Column(
                  children: [
                    _buildFeatureRow('Access Sonder 0.1 Pro (70B reasoning model)'),
                    const SizedBox(height: 8),
                    _buildFeatureRow('Up to 150 daily requests with zero waiting queue'),
                    const SizedBox(height: 8),
                    _buildFeatureRow('High-resolution AI Image Generator & Studio Tools'),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Action Buttons Row
              Row(
                children: [
                  // Maybe Later Button
                  Expanded(
                    flex: 2,
                    child: _DialogBounceButton(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x8C40362F), Color(0x8C261F1A)],
                          ),
                          border: Border.all(color: const Color(0x2EFFFFFF), width: 1.0),
                        ),
                        child: Center(
                          child: Text(
                            'Maybe Later',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFD4C9C2),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Upgrade Now Glowing Button
                  Expanded(
                    flex: 3,
                    child: _DialogBounceButton(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PricingScreen()),
                        );
                      },
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFF9E3B), Color(0xFFFF6800)],
                          ),
                          border: Border.all(color: const Color(0x80FFE1B9), width: 1.0),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x66FF7300),
                              blurRadius: 18,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            RedesignIcons.lightning(size: 16, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              'Upgrade Now',
                              style: GoogleFonts.inter(
                                fontSize: 14,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String text) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFFF9233),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFFDDD2C9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _DialogBounceButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _DialogBounceButton({required this.child, this.onTap});

  @override
  State<_DialogBounceButton> createState() => _DialogBounceButtonState();
}

class _DialogBounceButtonState extends State<_DialogBounceButton> with SingleTickerProviderStateMixin {
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
