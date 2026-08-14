import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:js' as js;
import '../constants/colors.dart';
import '../services/subscription_service.dart';

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

  Future<void> _handleUpgrade(String tier, double amountGHS) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to upgrade your subscription.')),
      );
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

            // Show a dialog asking user to verify payment once done
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checkout initialization error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _checkoutLoadingTier = null);
    }
  }

  void _showVerificationDialog(String ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.neutralSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.neutralBorder),
        ),
        title: Text(
          'Processing Payment',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        content: Text(
          'Once you complete your payment in the secure window, click the button below to sync your subscription status.',
          style: GoogleFonts.inter(color: AppColors.neutralTextMuted),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _fetchSubscriptionInfo();
            },
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.redAccent),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              final upgraded = await _subscriptionService.verifyAndApplyPayment(ref);
              await _fetchSubscriptionInfo();
              if (mounted) {
                if (upgraded) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🎉 Congratulations! Your subscription has been successfully upgraded!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'I have paid / Sync status',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(
          'Membership Plans',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  // Current Plan Header Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.1),
                          AppColors.neutralSurface,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.neutralBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.stars, color: AppColors.primary, size: 36),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Status: $_currentTier Plan',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (_currentTier != 'FREE') ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Credit Balance: \$${_currentCredits.toStringAsFixed(2)} USD',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.greenAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  Text(
                    'Choose Your Upgrade',
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unlock advanced AI capabilities and higher generation quotas.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: AppColors.neutralTextMuted),
                  ),
                  const SizedBox(height: 32),

                  // Pricing Cards Layout
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildPricingCard(
                          title: 'FREE',
                          price: '0 GHS',
                          period: 'forever',
                          features: [
                            '5 Text requests / day',
                            'Normal text models only',
                            'No Sonder 0.1 Pro access',
                            '5 Schnell images / day',
                            '2 Headshots / day (Lora model)',
                            '25 images & 15 headshots max / month',
                          ],
                          isPopular: false,
                          buttonText: _currentTier == 'FREE' ? 'Active Plan' : 'Free Tier',
                          onTap: () {},
                          isEnabled: false,
                        )),
                        const SizedBox(width: 16),
                        Expanded(child: _buildPricingCard(
                          title: 'BASIC',
                          price: '1 GHS',
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
                          buttonText: _currentTier == 'BASIC' ? 'Active' : 'Upgrade Basic',
                          onTap: () => _handleUpgrade('BASIC', 1.0),
                          isEnabled: _currentTier != 'BASIC',
                        )),
                        const SizedBox(width: 16),
                        Expanded(child: _buildPricingCard(
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
                          buttonText: _currentTier == 'PRO' ? 'Active' : 'Upgrade Pro',
                          onTap: () => _handleUpgrade('PRO', 250.0),
                          isEnabled: _currentTier != 'PRO',
                        )),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildPricingCard(
                          title: 'FREE',
                          price: '0 GHS',
                          period: 'forever',
                          features: [
                            '5 Text requests / day',
                            'Normal text models only',
                            'No Sonder 0.1 Pro access',
                            '5 Schnell images / day',
                            '2 Headshots / day (Lora model)',
                            '25 images & 15 headshots max / month',
                          ],
                          isPopular: false,
                          buttonText: _currentTier == 'FREE' ? 'Active Plan' : 'Free Tier',
                          onTap: () {},
                          isEnabled: false,
                        ),
                        const SizedBox(height: 24),
                        _buildPricingCard(
                          title: 'BASIC',
                          price: '1 GHS',
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
                          buttonText: _currentTier == 'BASIC' ? 'Active' : 'Upgrade Basic',
                          onTap: () => _handleUpgrade('BASIC', 1.0),
                          isEnabled: _currentTier != 'BASIC',
                        ),
                        const SizedBox(height: 24),
                        _buildPricingCard(
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
                          buttonText: _currentTier == 'PRO' ? 'Active' : 'Upgrade Pro',
                          onTap: () => _handleUpgrade('PRO', 250.0),
                          isEnabled: _currentTier != 'PRO',
                        ),
                      ],
                    ),
                ],
              ),
            ),
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
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.neutralSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPopular ? AppColors.primary : AppColors.neutralBorder,
          width: isPopular ? 2.0 : 1.5,
        ),
        boxShadow: [
          if (isPopular)
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 1,
            )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: isPopular ? AppColors.primary : Colors.white,
                ),
              ),
              if (isPopular)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'RECOMMENDED',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                )
            ],
          ),
          const SizedBox(height: 16),
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
              const SizedBox(width: 4),
              Text(
                '/ $period',
                style: GoogleFonts.inter(color: AppColors.neutralTextMuted, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: AppColors.neutralBorder),
          const SizedBox(height: 24),
          ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        feature,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.85),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isEnabled && !isLoading ? onTap : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isPopular ? AppColors.primary : const Color(0xFF382F25),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF241D17),
                disabledForegroundColor: AppColors.neutralTextMuted,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      buttonText,
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
            ),
          )
        ],
      ),
    );
  }
}
