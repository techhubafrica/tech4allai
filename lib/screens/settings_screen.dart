import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/colors.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../services/subscription_service.dart';
import 'pricing_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  String _userTier = 'FREE';
  double _userCredits = 0.0;
  bool _isLoadingSubscription = true;

  @override
  void initState() {
    super.initState();
    _fetchSubscriptionInfo();
  }

  Future<void> _fetchSubscriptionInfo() async {
    final sub = await _subscriptionService.getSubscription();
    if (mounted && sub != null) {
      setState(() {
        _userTier = sub['tier'] ?? 'FREE';
        _userCredits = (sub['credits'] as num?)?.toDouble() ?? 0.0;
        _isLoadingSubscription = false;
      });
    } else {
      if (mounted) {
        setState(() => _isLoadingSubscription = false);
      }
    }
  }

  void _showUnderDevelopmentMessage(BuildContext context, String title) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$title is currently under development.',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? 'Unknown Email';
    final fullName = user?.userMetadata?['full_name'] ?? user?.userMetadata?['name'] ?? 'User';
    final avatarUrl = user?.userMetadata?['avatar_url'] ?? user?.userMetadata?['picture'] ?? '';
    final initials = fullName.isNotEmpty
        ? fullName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // User Profile Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.neutralSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.neutralBorder),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.primary,
                        backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl.isEmpty
                            ? Text(
                                initials,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              email,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.neutralTextMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.neutralBorder, height: 1),
                  const SizedBox(height: 12),
                  // Subscription Tier Badge & Credits
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _userTier == 'FREE' ? Icons.bolt : Icons.stars,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isLoadingSubscription ? 'Loading...' : 'Plan: $_userTier',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      if (!_isLoadingSubscription && _userTier != 'FREE')
                        Text(
                          'Credits: \$${_userCredits.toStringAsFixed(2)} USD',
                          style: GoogleFonts.inter(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        )
                      else if (!_isLoadingSubscription && _userTier == 'FREE')
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const PricingScreen()),
                            ).then((_) => _fetchSubscriptionInfo());
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Upgrade',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('Account'),
            _buildSettingsItem(
              icon: Icons.stars_outlined,
              title: 'Subscription Tiers',
              trailingText: _isLoadingSubscription ? 'Loading...' : _userTier,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PricingScreen()),
                ).then((_) => _fetchSubscriptionInfo());
              },
            ),
            _buildSettingsItem(
              icon: Icons.person_outline,
              title: 'Personal Information',
              onTap: () => _showUnderDevelopmentMessage(context, 'Personal Information'),
            ),
            _buildSettingsItem(
              icon: Icons.lock_outline,
              title: 'Security',
              onTap: () => _showUnderDevelopmentMessage(context, 'Security Settings'),
            ),
            _buildSettingsItem(
              icon: Icons.payment_outlined,
              title: 'Payment Methods',
              onTap: () => _showUnderDevelopmentMessage(context, 'Payment Methods'),
            ),
            
            const SizedBox(height: 24),
            _buildSectionHeader('Preferences'),
            _buildSettingsItem(
              icon: Icons.notifications_none,
              title: 'Notifications',
              onTap: () => _showUnderDevelopmentMessage(context, 'Notifications Preferences'),
            ),
            _buildSettingsItem(
              icon: Icons.language,
              title: 'Language',
              onTap: () => _showUnderDevelopmentMessage(context, 'Language Settings'),
            ),
            _buildSettingsItem(
              icon: Icons.dark_mode_outlined,
              title: 'Theme',
              trailingText: 'Dark',
              onTap: () => _showUnderDevelopmentMessage(context, 'Theme Preferences'),
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('Support'),
            _buildSettingsItem(
              icon: Icons.help_outline,
              title: 'Help Center',
              onTap: () => _showUnderDevelopmentMessage(context, 'Help Center'),
            ),
            _buildSettingsItem(
              icon: Icons.info_outline,
              title: 'About Tech4All',
              onTap: () => _showUnderDevelopmentMessage(context, 'About Tech4All'),
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('Session'),
            _buildSettingsItem(
              icon: Icons.logout,
              title: 'Log Out',
              iconColor: Colors.redAccent,
              textColor: Colors.redAccent,
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
              },
            ),
            
            const SizedBox(height: 48),
            Text(
              'Version 2.4.1 (Build 1084)',
              style: GoogleFonts.inter(
                color: AppColors.neutralTextMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: AppColors.neutralTextMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    String? trailingText,
    Color? iconColor,
    Color? textColor,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.neutralSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neutralBorder),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: iconColor ?? AppColors.primary),
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: textColor ?? Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: trailingText != null
            ? Text(
                trailingText,
                style: GoogleFonts.inter(color: AppColors.neutralTextMuted),
              )
            : const Icon(Icons.chevron_right, color: AppColors.neutralTextMuted),
      ),
    );
  }
}
