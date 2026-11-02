import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/tools_hub_screen.dart';
import '../screens/main_chat_assistant_screen.dart';
import '../screens/settings_screen.dart';
import 'redesign_icons.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget nextScreen;
    switch (index) {
      case 0:
        nextScreen = const ToolsHubScreen();
        break;
      case 1:
        nextScreen = const MainChatAssistantScreen();
        break;
      case 2:
        nextScreen = const SettingsScreen();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xF518100B),
            Color(0xF80F0906),
          ],
        ),
        border: const Border(
          top: BorderSide(color: Color(0x38FF9233), width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
          const BoxShadow(
            color: Color(0x1FFF7300),
            blurRadius: 14,
            offset: Offset(0, -2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(context, 0, (color) => RedesignIcons.navTools(size: 23, color: color), 'Tools'),
              _buildNavItem(context, 1, (color) => RedesignIcons.navChat(size: 23, color: color), 'Chat'),
              _buildNavItem(context, 2, (color) => RedesignIcons.navProfile(size: 23, color: color), 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, Widget Function(Color color) iconBuilder, String label) {
    final bool isActive = currentIndex == index;
    final color = isActive ? const Color(0xFFFF9233) : const Color(0xFF8E857D);
    return _NavBounceItem(
      onTap: () => _onItemTapped(context, index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isActive ? const Color(0x26FF9233) : Colors.transparent,
          border: Border.all(
            color: isActive ? const Color(0x4DFF9233) : Colors.transparent,
            width: 1.0,
          ),
          boxShadow: isActive
              ? const [
                  BoxShadow(
                    color: Color(0x33FF7300),
                    blurRadius: 12,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconBuilder(color),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                color: isActive ? const Color(0xFFFF9838) : const Color(0xFF8E857D),
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBounceItem extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _NavBounceItem({required this.child, required this.onTap});

  @override
  State<_NavBounceItem> createState() => _NavBounceItemState();
}

class _NavBounceItemState extends State<_NavBounceItem> {
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
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: widget.child,
      ),
    );
  }
}
