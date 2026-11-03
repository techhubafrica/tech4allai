import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:js' as js;
import '../services/subscription_service.dart';
import '../widgets/redesign_icons.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  String _currentTier = 'FREE';
  double _currentCredits = 0.0;
  bool _isLoading = true;
  String? _checkoutLoadingTier;

  @override
  void initState() {
    super.initState();
    _fetchSubscriptionInfo();
  }

  Future<void> _fetchSubscriptionInfo() async {
    setState(() => _isLoading = true);
    try {
      await _subscriptionService.syncPendingPayments();
    } catch (_) {}
    final sub = await _subscriptionService.getSubscription();
    if (mounted && sub != null) {
      setState(() {
        _currentTier = sub['tier'] ?? 'FREE';
        _currentCredits = (sub['credits'] as num?)?.toDouble() ?? 0.0;
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showNotification(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        duration: const Duration(seconds: 4),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFA1E140C),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isError ? const Color(0x66FF3B30) : const Color(0x66FF8A24),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: (isError ? const Color(0xFFFF3B30) : const Color(0xFFFF8A24)).withOpacity(0.2),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isError ? const Color(0x33FF3B30) : const Color(0x33FF8A24),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: isError
                      ? RedesignIcons.alertCircle(size: 16, color: Colors.redAccent)
                      : RedesignIcons.check(size: 16, color: const Color(0xFFFF8A24)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleUpgrade(String tier, double amountGHS) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _showNotification('Please log in to upgrade your subscription.', isError: true);
      return;
    }

    setState(() => _checkoutLoadingTier = tier);

    try {
      final paymentData = await _subscriptionService.createRushPayPayment(
        amountGHS: amountGHS,
        tier: tier,
        email: user.email ?? '',
      );

      if (paymentData != null) {
        final ref = paymentData['payment_reference'] ?? paymentData['reference'];
        if (ref != null) {
          final widgetToken = await _subscriptionService.createRushPayWidgetSession(ref);
          if (widgetToken != null) {
            // Trigger browser overlay
            js.context.callMethod('openRushPayCheckout', [
              ref,
              widgetToken,
              'https://tech4all-ai.techhubafrica.org/webhook/rushpay'
            ]);

            // Show verification dialog
            if (mounted) {
              _showVerificationDialog(ref.toString());
            }
          } else {
            throw Exception('Failed to retrieve checkout session token.');
          }
        } else {
          throw Exception('Payment reference missing from response.');
        }
      } else {
        throw Exception('Payment creation failed. Please check credentials.');
      }
    } catch (e) {
      if (mounted) {
        _showNotification('Checkout initialization error: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _checkoutLoadingTier = null);
    }
  }

  void _showVerificationDialog(String ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            gradient: const RadialGradient(
              center: Alignment(0, -0.6),
              radius: 1.1,
              colors: [Color(0xFF2E1F16), Color(0xFF140D08)],
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0x66FF8A24), width: 1.4),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF8A24).withOpacity(0.2),
                blurRadius: 36,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF9436), Color(0xFFFF6B00)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: RedesignIcons.paymentCard(size: 20, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Processing Payment',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Complete your transaction in the secure RushPay checkout window. Once complete, click below to verify and instantly unlock your tier benefits.',
                style: GoogleFonts.inter(color: const Color(0xFFB5AAA0), fontSize: 13.5, height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _BounceButton(
                      onTap: () {
                        Navigator.pop(context);
                        _fetchSubscriptionInfo();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0x33241A13),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0x33FF8A24)),
                        ),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BounceButton(
                      onTap: () async {
                        Navigator.pop(context);
                        setState(() => _isLoading = true);
                        final upgraded = await _subscriptionService.verifyAndApplyPayment(ref);
                        await _fetchSubscriptionInfo();
                        if (mounted) {
                          if (upgraded) {
                            _showNotification('🎉 Congratulations! Your subscription has been upgraded!');
                          } else {
                            _showNotification('Payment verification in progress. We\'ll sync automatically.');
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF8A24), Color(0xFFFF6600)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x66FF7A1A),
                              blurRadius: 14,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'I Have Paid / Sync',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 13.5,
                            ),
                          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A06),
      body: Stack(
        children: [
          // Ambient Radial Background
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.6),
                  radius: 1.1,
                  colors: const [
                    Color(0xFF28180D),
                    Color(0xFF0F0A06),
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),

          // Lighting Orb
          Positioned(
            top: -120,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 360,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFF8A24).withOpacity(0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Color(0xFFFF8A24)),
                        )
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1080),
                              child: Column(
                                children: [
                                  _buildCurrentPlanBanner(),
                                  const SizedBox(height: 36),
                                  Text(
                                    'Choose Your Upgrade',
                                    style: GoogleFonts.inter(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Unlock advanced AI capabilities and higher generation quotas.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFFB0A49B),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  _buildPricingCardsLayout(),
                                  const SizedBox(height: 48),
                                ],
                              ),
                            ),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0x660F0A06),
        border: Border(bottom: BorderSide(color: Color(0x22FF8A24))),
      ),
      child: Row(
        children: [
          _BounceButton(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0x33241A13),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x33FF8A24)),
              ),
              child: Center(child: RedesignIcons.arrowBack(size: 20)),
            ),
          ),
          const SizedBox(width: 14),
          // Tier Squircle Badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFB03A), Color(0xFFFF7A00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x55FF7A1A),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                )
              ],
            ),
            child: Center(child: RedesignIcons.awardStars(size: 18, color: Colors.white)),
          ),
          const SizedBox(width: 10),
          Text(
            'Membership Plans',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          _BounceButton(
            onTap: _fetchSubscriptionInfo,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0x33241A13),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0x33FF8A24)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RedesignIcons.awardStars(size: 16, color: const Color(0xFFFF9436)),
                  const SizedBox(width: 6),
                  Text(
                    'Sync Tier',
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
        ],
      ),
    );
  }

  Widget _buildCurrentPlanBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0x731C130D),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x40FF8A24)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF9436), Color(0xFFFF6B00)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x55FF7A1A),
                  blurRadius: 12,
                  offset: Offset(0, 3),
                )
              ],
            ),
            child: Center(
              child: RedesignIcons.awardStars(size: 26, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Plan: $_currentTier',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                if (_currentTier != 'FREE') ...[
                  Text(
                    'Credit Balance: \$${_currentCredits.toStringAsFixed(2)} USD',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      color: const Color(0xFF10B981),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ] else ...[
                  Text(
                    'Free Tier Active • Upgrade anytime for higher quotas & pro models',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: const Color(0xFFB0A49B),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCardsLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 750;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildFreeCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildBasicCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildProCard()),
            ],
          );
        } else {
          return Column(
            children: [
              _buildFreeCard(),
              const SizedBox(height: 20),
              _buildBasicCard(),
              const SizedBox(height: 20),
              _buildProCard(),
            ],
          );
        }
      },
    );
  }

  Widget _buildFreeCard() {
    return _buildPricingCard(
      title: 'FREE',
      price: '0 GHS',
      period: 'forever',
      features: [
        '5 Text requests / day',
        'Normal text models only',
        'No Sonder 0.1 Pro access',
        '5 Schnell images / day',
        '2 Headshots / day (Lora model)',
        '25 images & 15 headshots max / mo',
      ],
      isPopular: false,
      buttonText: _currentTier == 'FREE' ? 'Active Plan' : 'Free Tier',
      onTap: () {},
      isEnabled: false,
    );
  }

  Widget _buildBasicCard() {
    return _buildPricingCard(
      title: 'BASIC',
      price: '100 GHS',
      period: 'monthly',
      features: [
        '50 Text requests / day',
        'Access to Sonder 0.1 Pro models',
        '\$5 USD image/headshot credits',
        'Credits reset monthly',
        'Cost deducted dynamically per image',
        'No rollover of credits',
      ],
      isPopular: true,
      buttonText: _currentTier == 'BASIC' ? 'Active Plan' : 'Upgrade to Basic',
      onTap: () => _handleUpgrade('BASIC', 100.0),
      isEnabled: _currentTier != 'BASIC',
    );
  }

  Widget _buildProCard() {
    return _buildPricingCard(
      title: 'PRO',
      price: '250 GHS',
      period: 'monthly',
      features: [
        '150 Text requests / day',
        'Access to Sonder 0.1 Pro models',
        '\$10 USD image/headshot credits',
        'Credits reset monthly',
        'Cost deducted dynamically per image',
        'Ideal for high-volume content creators',
      ],
      isPopular: false,
      buttonText: _currentTier == 'PRO' ? 'Active Plan' : 'Upgrade to Pro',
      onTap: () => _handleUpgrade('PRO', 250.0),
      isEnabled: _currentTier != 'PRO',
    );
  }

  Widget _buildPricingCard({
    required String title,
    required String price,
    required String period,
    required List<String> features,
    required bool isPopular,
    required String buttonText,
    required VoidCallback onTap,
    required bool isEnabled,
  }) {
    final isLoading = _checkoutLoadingTier == title;

    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: const Color(0x731C130D),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPopular ? const Color(0xFFFF8A24) : const Color(0x40FF8A24),
          width: isPopular ? 2.0 : 1.2,
        ),
        boxShadow: [
          if (isPopular)
            BoxShadow(
              color: const Color(0xFFFF8A24).withOpacity(0.18),
              blurRadius: 24,
              offset: const Offset(0, 8),
            )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: isPopular ? const Color(0xFFFF9436) : Colors.white,
                ),
              ),
              if (isPopular) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0x26FF8A24),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0x4DFF8A24)),
                  ),
                  child: Text(
                    'RECOMMENDED',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFF9436),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                price,
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '/ $period',
                style: GoogleFonts.inter(color: const Color(0xFF9E9287), fontSize: 13.5),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0x22FF8A24), thickness: 1),
          const SizedBox(height: 20),
          ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RedesignIcons.check(size: 16, color: const Color(0xFFFF9436)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        feature,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFFD6CBC3),
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 24),
          _BounceButton(
            onTap: isEnabled && !isLoading ? onTap : () {},
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                gradient: isEnabled
                    ? (isPopular
                        ? const LinearGradient(colors: [Color(0xFFFF8A24), Color(0xFFFF6600)])
                        : const LinearGradient(colors: [Color(0x33281C14), Color(0x4D281C14)]))
                    : null,
                color: isEnabled ? null : const Color(0x221C130D),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isEnabled
                      ? (isPopular ? const Color(0xFFFF9436) : const Color(0x40FF8A24))
                      : const Color(0x22FF8A24),
                ),
                boxShadow: isEnabled && isPopular
                    ? const [
                        BoxShadow(
                          color: Color(0x55FF7A1A),
                          blurRadius: 14,
                          offset: Offset(0, 3),
                        )
                      ]
                    : null,
              ),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        buttonText,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isEnabled ? Colors.white : const Color(0xFF7A6F65),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BounceButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _BounceButton({required this.child, required this.onTap});

  @override
  State<_BounceButton> createState() => _BounceButtonState();
}

class _BounceButtonState extends State<_BounceButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 140),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: widget.child,
        ),
      ),
    );
  }
}
