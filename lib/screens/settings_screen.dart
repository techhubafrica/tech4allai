import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/redesign_icons.dart';
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
        content: Row(
          children: [
            RedesignIcons.lightning(size: 16, color: const Color(0xFFFF9438)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$title is currently under development.',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E140C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0x4DFF7300), width: 1.2),
        ),
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
      backgroundColor: const Color(0xFF0F0A06),
      body: Stack(
        children: [
          // 1. Ambient Glow Orb matching redesign/tech4all_ai_redesign.html
          Positioned(
            top: -100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 600,
                height: 380,
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

          // 2. Main Content Canvas
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- HEADER ---
                      _buildHeader(),
                      const SizedBox(height: 20),

                      // --- USER PROFILE CARD ---
                      _buildProfileCard(fullName, email, avatarUrl, initials),
                      const SizedBox(height: 24),

                      // --- ACCOUNT SECTION ---
                      _buildSectionHeader('Account'),
                      _buildSettingsGroup([
                        _SettingsTileData(
                          iconWidget: RedesignIcons.awardStars(size: 20, color: const Color(0xFFFF9233)),
                          iconBgColor: const Color(0x2BFF7300),
                          title: 'Subscription Tiers',
                          subtitle: 'View plans, tokens & usage rates',
                          trailingWidget: _isLoadingSubscription
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF7300)),
                                )
                              : _buildTierPill(),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const PricingScreen()),
                            ).then((_) => _fetchSubscriptionInfo());
                          },
                        ),
                        _SettingsTileData(
                          iconWidget: RedesignIcons.navProfile(size: 20, color: const Color(0xFFFF9233)),
                          iconBgColor: const Color(0x2BFF7300),
                          title: 'Personal Information',
                          subtitle: 'Profile details, name and email',
                          onTap: () => _showUnderDevelopmentMessage(context, 'Personal Information'),
                        ),
                        _SettingsTileData(
                          iconWidget: RedesignIcons.lock(size: 20, color: const Color(0xFFFF9233)),
                          iconBgColor: const Color(0x2BFF7300),
                          title: 'Security',
                          subtitle: 'Password, MFA & account safety',
                          onTap: () => _showUnderDevelopmentMessage(context, 'Security Settings'),
                        ),
                        _SettingsTileData(
                          iconWidget: RedesignIcons.paymentCard(size: 20, color: const Color(0xFFFF9233)),
                          iconBgColor: const Color(0x2BFF7300),
                          title: 'Payment Methods',
                          subtitle: 'Saved billing cards & invoices',
                          onTap: () => _showUnderDevelopmentMessage(context, 'Payment Methods'),
                        ),
                      ]),

                      const SizedBox(height: 24),

                      // --- PREFERENCES SECTION ---
                      _buildSectionHeader('Preferences'),
                      _buildSettingsGroup([
                        _SettingsTileData(
                          iconWidget: RedesignIcons.bell(size: 20, color: const Color(0xFFFF9233)),
                          iconBgColor: const Color(0x2BFF7300),
                          title: 'Notifications',
                          subtitle: 'Push notifications & activity alerts',
                          onTap: () => _showUnderDevelopmentMessage(context, 'Notifications'),
                        ),
                        _SettingsTileData(
                          iconWidget: RedesignIcons.globe(size: 20, color: const Color(0xFFFF9233)),
                          iconBgColor: const Color(0x2BFF7300),
                          title: 'Language',
                          subtitle: 'Default dialect & localized responses',
                          trailingText: 'English (US)',
                          onTap: () => _showUnderDevelopmentMessage(context, 'Language Settings'),
                        ),
                        _SettingsTileData(
                          iconWidget: RedesignIcons.moon(size: 20, color: const Color(0xFFFF9233)),
                          iconBgColor: const Color(0x2BFF7300),
                          title: 'Theme',
                          subtitle: 'Visual appearance & atmosphere',
                          trailingText: 'Dark Glow',
                          onTap: () => _showUnderDevelopmentMessage(context, 'Theme Preferences'),
                        ),
                      ]),

                      const SizedBox(height: 24),

                      // --- SUPPORT SECTION ---
                      _buildSectionHeader('Support'),
                      _buildSettingsGroup([
                        _SettingsTileData(
                          iconWidget: RedesignIcons.helpCircle(size: 20, color: const Color(0xFFFF9233)),
                          iconBgColor: const Color(0x2BFF7300),
                          title: 'Help Center',
                          subtitle: 'Documentation, guides & FAQs',
                          onTap: () => _showUnderDevelopmentMessage(context, 'Help Center'),
                        ),
                        _SettingsTileData(
                          iconWidget: RedesignIcons.infoCircle(size: 20, color: const Color(0xFFFF9233)),
                          iconBgColor: const Color(0x2BFF7300),
                          title: 'About Tech4All AI',
                          subtitle: 'Terms, privacy policy and mission',
                          onTap: () => _showUnderDevelopmentMessage(context, 'About Tech4All'),
                        ),
                      ]),

                      const SizedBox(height: 24),

                      // --- SESSION / LOGOUT SECTION ---
                      _buildSectionHeader('Session'),
                      _SettingsBounceButton(
                        onTap: () async {
                          final shouldSignOut = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xFF1E140C),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: const BorderSide(color: Color(0x33FF7300), width: 1.2),
                              ),
                              title: Row(
                                children: [
                                  RedesignIcons.logout(size: 20, color: const Color(0xFFFF5252)),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Confirm Sign Out',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              content: Text(
                                'Are you sure you want to log out from this device?',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFFD4CFC9),
                                  fontSize: 14,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text(
                                    'Cancel',
                                    style: GoogleFonts.inter(color: const Color(0xFF8E857D), fontWeight: FontWeight.w600),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF3B30),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    'Log Out',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (shouldSignOut == true) {
                            await SubscriptionService().setSuperAdminDemoSession(false);
                            await Supabase.instance.client.auth.signOut();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0x14FF3B30),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0x40FF3B30), width: 1.2),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0x28FF3B30),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0x4DFF3B30), width: 1),
                                ),
                                child: Center(
                                  child: RedesignIcons.logout(size: 20, color: const Color(0xFFFF5252)),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Log Out',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFFF5252),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Sign out of your active account session',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: const Color(0xFFB07272),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              RedesignIcons.chevronRight(size: 16, color: const Color(0xFFFF5252)),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // --- FOOTER BADGE ---
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0x0FFFFFFF),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0x1AFFFFFF), width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF00E676),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Tech4All AI v2.4.1 (Build 1084)',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF8E857D),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Secured with TLS 256-bit Cloud Encryption',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF5E564E),
                                fontSize: 10,
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
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFA438), Color(0xFFFF6A00)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x59FF6A00),
                blurRadius: 14,
                spreadRadius: 1,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'T',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w900,
                fontSize: 22,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings & Profile',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  RedesignIcons.lightning(size: 13, color: const Color(0xFFF5923E)),
                  const SizedBox(width: 4),
                  Text(
                    'Preferences, plan & account control',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFB5ACA2),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(String fullName, String email, String avatarUrl, String initials) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E140C).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x38FF7300), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFA438), Color(0xFFFF6A00)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF7A00).withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: avatarUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.network(
                            avatarUrl,
                            width: 58,
                            height: 58,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Text(
                              initials,
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      : Text(
                          initials,
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                ),
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
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      email,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFFA89F95),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            height: 1,
            color: const Color(0x1FFFFFFF),
          ),
          const SizedBox(height: 14),

          // Plan & Credits Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Plan indicator
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _userTier == 'SUPERADMIN'
                          ? const Color(0xFF00E5FF)
                          : (_userTier == 'FREE' ? const Color(0xFF8E857D) : const Color(0xFFFF9233)),
                      boxShadow: [
                        BoxShadow(
                          color: _userTier == 'SUPERADMIN'
                              ? const Color(0xFF00E5FF).withValues(alpha: 0.6)
                              : const Color(0xFFFF9233).withValues(alpha: 0.6),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isLoadingSubscription
                        ? 'Loading...'
                        : (_userTier == 'SUPERADMIN' ? 'SUPERADMIN (Demo Mode)' : 'Plan: $_userTier'),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),

              // Credits or Upgrade Button
              if (!_isLoadingSubscription && _userTier == 'SUPERADMIN')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0x1F00E5FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x6600E5FF), width: 1),
                  ),
                  child: Text(
                    'Unlimited Credits',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF00E5FF),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                )
              else if (!_isLoadingSubscription && _userTier != 'FREE')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0x1F00E676),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x6600E676), width: 1),
                  ),
                  child: Text(
                    'Credits: \$${_userCredits.toStringAsFixed(2)} USD',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF00E676),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                )
              else if (!_isLoadingSubscription && _userTier == 'FREE')
                _SettingsBounceButton(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PricingScreen()),
                    ).then((_) => _fetchSubscriptionInfo());
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFA438), Color(0xFFFF6A00)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x40FF6A00),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RedesignIcons.lightning(size: 13, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          'Upgrade',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTierPill() {
    Color pillColor;
    Color textColor;
    if (_userTier == 'SUPERADMIN') {
      pillColor = const Color(0x2400E5FF);
      textColor = const Color(0xFF00E5FF);
    } else if (_userTier == 'PRO') {
      pillColor = const Color(0x2BFF7300);
      textColor = const Color(0xFFFF9233);
    } else {
      pillColor = const Color(0x1AFFFFFF);
      textColor = const Color(0xFFBEB8B2);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: pillColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        _userTier,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFF7A00),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: const Color(0xFF8E857D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(List<_SettingsTileData> items) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E140C).withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x21FFFFFF), width: 1.0),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _SettingsBounceButton(
              onTap: items[i].onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    // Squircle Icon Badge
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: items[i].iconBgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x33FF7300), width: 1),
                      ),
                      child: Center(child: items[i].iconWidget),
                    ),
                    const SizedBox(width: 14),
                    // Title and subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            items[i].title,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          if (items[i].subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              items[i].subtitle!,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF8E857D),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Trailing
                    if (items[i].trailingWidget != null) ...[
                      items[i].trailingWidget!,
                      const SizedBox(width: 8),
                    ] else if (items[i].trailingText != null) ...[
                      Text(
                        items[i].trailingText!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFFBEB8B2),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    RedesignIcons.chevronRight(size: 16, color: const Color(0xFF7A7066)),
                  ],
                ),
              ),
            ),
            if (i < items.length - 1)
              const Divider(
                height: 1,
                thickness: 1,
                indent: 68,
                endIndent: 16,
                color: Color(0x14FFFFFF),
              ),
          ],
        ],
      ),
    );
  }
}

class _SettingsTileData {
  final Widget iconWidget;
  final Color iconBgColor;
  final String title;
  final String? subtitle;
  final String? trailingText;
  final Widget? trailingWidget;
  final VoidCallback? onTap;

  const _SettingsTileData({
    required this.iconWidget,
    required this.iconBgColor,
    required this.title,
    this.subtitle,
    this.trailingText,
    this.trailingWidget,
    this.onTap,
  });
}

class _SettingsBounceButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _SettingsBounceButton({required this.child, this.onTap});

  @override
  State<_SettingsBounceButton> createState() => _SettingsBounceButtonState();
}

class _SettingsBounceButtonState extends State<_SettingsBounceButton> with SingleTickerProviderStateMixin {
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
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
