import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/subscription_service.dart';
import '../widgets/auth_guard.dart';
import '../widgets/redesign_icons.dart';
import 'tools_hub_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();

  // Login Controllers
  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController = TextEditingController();

  // Signup Controllers
  final TextEditingController _signupNameController = TextEditingController();
  final TextEditingController _signupEmailController = TextEditingController();
  final TextEditingController _signupPasswordController = TextEditingController();

  // OTP Controller
  final TextEditingController _otpInputController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  bool _isLoading = false;
  bool _isOtpSent = false;
  String _otpEmail = '';
  bool _obscureLoginPassword = true;
  bool _obscureSignupPassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupNameController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _otpInputController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        duration: const Duration(seconds: 3),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1C0D08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x80FF3B30), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40FF3B30),
                blurRadius: 20,
                offset: Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black54,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: const Color(0x33FF3B30),
                  border: Border.all(color: const Color(0x66FF3B30), width: 1),
                ),
                child: Center(
                  child: RedesignIcons.close(size: 15, color: const Color(0xFFFF5252)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFFFEAEA),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        duration: const Duration(seconds: 3),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF0C180F),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x8000E676), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x3800E676),
                blurRadius: 20,
                offset: Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black54,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: const Color(0x3300E676),
                  border: Border.all(color: const Color(0x6600E676), width: 1),
                ),
                child: const Center(
                  child: Icon(Icons.check_rounded, color: Color(0xFF00E676), size: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFE8FCEF),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text.trim();
    final isSuperAdmin = SubscriptionService.isSuperAdmin(email);

    if (isSuperAdmin && password == SubscriptionService.superAdminPassword) {
      await SubscriptionService().setSuperAdminDemoSession(true);

      try {
        final response = await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        if (response.user != null) {
          await SubscriptionService().ensureSuperAdminSubscription(response.user!.id);
        }
      } on AuthException catch (_) {
        try {
          final signupRes = await Supabase.instance.client.auth.signUp(
            email: email,
            password: password,
            data: {'full_name': 'TechHub SuperAdmin'},
          );
          final userId = signupRes.user?.id ?? Supabase.instance.client.auth.currentUser?.id;
          if (userId != null) {
            await SubscriptionService().ensureSuperAdminSubscription(userId);
          }
        } catch (_) {}
      } catch (_) {}

      _showSuccess('Superadmin Demo Mode Logged In!');
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const AuthGuard(
              child: ToolsHubScreen(),
            ),
          ),
          (route) => false,
        );
      }
      return;
    }

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _showSuccess('Logged in successfully!');
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignup() async {
    if (!_signupFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final email = _signupEmailController.text.trim();
    final isSuperAdmin = SubscriptionService.isSuperAdmin(email);

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: _signupPasswordController.text.trim(),
        data: {
          'full_name': _signupNameController.text.trim(),
        },
      );

      if (isSuperAdmin && response.user != null) {
        await SubscriptionService().ensureSuperAdminSubscription(response.user!.id);
      }

      if (response.session == null && response.user != null) {
        setState(() {
          _isOtpSent = true;
          _otpEmail = email;
        });
        _showSuccess('Verification code sent to $email!');
      } else {
        _showSuccess(isSuperAdmin ? 'Superadmin Demo Mode Account Created!' : 'Account created and logged in!');
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final otpCode = _otpInputController.text.trim();
    if (otpCode.length < 6 || otpCode.length > 8) {
      _showError('Please enter a valid 6 to 8-digit verification code.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.verifyOTP(
        email: _otpEmail,
        token: otpCode,
        type: OtpType.signup,
      );
      _showSuccess('Email verified successfully!');
      if (mounted) {
        setState(() {
          _isOtpSent = false;
        });
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Verification failed. Please check the code and try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                width: 620,
                height: 420,
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
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isOtpSent ? _buildOtpView() : _buildTabsView(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabsView() {
    return Column(
      key: const ValueKey('tabs_view'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Squircle Glowing Logo Badge
        Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFA438), Color(0xFFFF6A00)],
            ),
            border: Border.all(color: const Color(0x8CFFE6C3), width: 1.1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x73FF7300),
                blurRadius: 28,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'T',
              style: GoogleFonts.inter(
                fontSize: 38,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.8,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Tech4All AI',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RedesignIcons.lightning(size: 14, color: const Color(0xFFFF9233)),
            const SizedBox(width: 5),
            Text(
              'Your intelligent workspace for everyday tasks',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF9E968F),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Glassmorphic Card Container
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0x8C302117), // Warm amber glass
                Color(0x991C140D),
              ],
            ),
            border: Border.all(color: const Color(0x2BFFFFFF), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              const BoxShadow(
                color: Color(0x1FFF7300),
                blurRadius: 18,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Capsule Switcher Track (selector-track style)
              Container(
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0x59291D15),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0x24FFFFFF), width: 1.0),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _AuthBounceButton(
                        onTap: () {
                          _tabController.animateTo(0);
                          setState(() {});
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: _tabController.index == 0
                                ? const LinearGradient(
                                    colors: [Color(0xFFFF9534), Color(0xFFFF6701)],
                                  )
                                : null,
                            boxShadow: _tabController.index == 0
                                ? const [
                                    BoxShadow(
                                      color: Color(0x66FF7300),
                                      blurRadius: 14,
                                      offset: Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Log In',
                            style: GoogleFonts.inter(
                              color: _tabController.index == 0 ? Colors.white : const Color(0xFFBEB8B2),
                              fontWeight: _tabController.index == 0 ? FontWeight.bold : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _AuthBounceButton(
                        onTap: () {
                          _tabController.animateTo(1);
                          setState(() {});
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: _tabController.index == 1
                                ? const LinearGradient(
                                    colors: [Color(0xFFFF9534), Color(0xFFFF6701)],
                                  )
                                : null,
                            boxShadow: _tabController.index == 1
                                ? const [
                                    BoxShadow(
                                      color: Color(0x66FF7300),
                                      blurRadius: 14,
                                      offset: Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Sign Up',
                            style: GoogleFonts.inter(
                              color: _tabController.index == 1 ? Colors.white : const Color(0xFFBEB8B2),
                              fontWeight: _tabController.index == 1 ? FontWeight.bold : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Animated Form View
              AnimatedCrossFade(
                firstChild: _buildLoginForm(),
                secondChild: _buildSignupForm(),
                crossFadeState: _tabController.index == 0
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                duration: const Duration(milliseconds: 250),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            controller: _loginEmailController,
            label: 'Email Address',
            hint: 'email@example.com',
            prefixWidget: RedesignIcons.email(size: 17, color: const Color(0xFF8E857D)),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Email is required';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _loginPasswordController,
            label: 'Password',
            hint: '••••••••',
            prefixWidget: RedesignIcons.lock(size: 17, color: const Color(0xFF8E857D)),
            obscureText: _obscureLoginPassword,
            suffixWidget: GestureDetector(
              onTap: () => setState(() => _obscureLoginPassword = !_obscureLoginPassword),
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _obscureLoginPassword
                    ? RedesignIcons.eyeOff(size: 18, color: const Color(0xFF8E857D))
                    : RedesignIcons.eye(size: 18, color: const Color(0xFFFF9233)),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Password is required';
              return null;
            },
          ),
          const SizedBox(height: 24),
          _AuthBounceButton(
            onTap: _isLoading ? () {} : _handleLogin,
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF9534), Color(0xFFFF6701)],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66FF7300),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                      )
                    : Text(
                        'Log In',
                        style: GoogleFonts.inter(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupForm() {
    return Form(
      key: _signupFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            controller: _signupNameController,
            label: 'Full Name',
            hint: 'John Doe',
            prefixWidget: RedesignIcons.navProfile(size: 17, color: const Color(0xFF8E857D)),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Name is required';
              return null;
            },
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _signupEmailController,
            label: 'Email Address',
            hint: 'email@example.com',
            prefixWidget: RedesignIcons.email(size: 17, color: const Color(0xFF8E857D)),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Email is required';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _signupPasswordController,
            label: 'Password',
            hint: '•••••••• (Min. 6 chars)',
            prefixWidget: RedesignIcons.lock(size: 17, color: const Color(0xFF8E857D)),
            obscureText: _obscureSignupPassword,
            suffixWidget: GestureDetector(
              onTap: () => setState(() => _obscureSignupPassword = !_obscureSignupPassword),
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _obscureSignupPassword
                    ? RedesignIcons.eyeOff(size: 18, color: const Color(0xFF8E857D))
                    : RedesignIcons.eye(size: 18, color: const Color(0xFFFF9233)),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Password is required';
              if (value.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 24),
          _AuthBounceButton(
            onTap: _isLoading ? () {} : _handleSignup,
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF9534), Color(0xFFFF6701)],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66FF7300),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                      )
                    : Text(
                        'Sign Up',
                        style: GoogleFonts.inter(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpView() {
    return Column(
      key: const ValueKey('otp_view'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // OTP Header Squircle
        Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
            ),
            border: Border.all(color: const Color(0x8CA5D6A7), width: 1.1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x662E7D32),
                blurRadius: 28,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.mark_email_read_rounded, color: Colors.white, size: 38),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Verify Email',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF9E968F), height: 1.45),
            children: [
              const TextSpan(text: 'We sent a verification code to\n'),
              TextSpan(
                text: _otpEmail,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // OTP Input Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0x8C302117),
                Color(0x991C140D),
              ],
            ),
            border: Border.all(color: const Color(0x2BFFFFFF), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Monospace Digits Input
              Container(
                decoration: BoxDecoration(
                  color: const Color(0x59291D15),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0x4DFF9233), width: 1.2),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextFormField(
                  controller: _otpInputController,
                  focusNode: _otpFocusNode,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 6.0,
                  ),
                  cursorColor: const Color(0xFFFF9233),
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  decoration: const InputDecoration(
                    counterText: '',
                    hintText: '••••••••',
                    hintStyle: TextStyle(
                      fontFamily: 'monospace',
                      color: Color(0xFF7E756E),
                      letterSpacing: 6.0,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  onFieldSubmitted: (_) => _verifyOtp(),
                ),
              ),

              const SizedBox(height: 24),

              // Verify Button
              _AuthBounceButton(
                onTap: _isLoading ? () {} : _verifyOtp,
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9534), Color(0xFFFF6701)],
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66FF7300),
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                          )
                        : Text(
                            'Verify Code',
                            style: GoogleFonts.inter(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () {
                  setState(() {
                    _isOtpSent = false;
                    _otpInputController.clear();
                  });
                },
                child: Text(
                  'Back to Sign Up',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFBEB8B2),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0x26FF9233),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x40FF9233), width: 0.8),
                ),
                child: Row(
                  children: [
                    RedesignIcons.infoCircle(size: 16, color: const Color(0xFFFF9233)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Can't find the email? Please check your Spam folder.",
                        style: GoogleFonts.inter(
                          color: const Color(0xFFD4C9C2),
                          fontSize: 11.5,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required Widget prefixWidget,
    bool obscureText = false,
    Widget? suffixWidget,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: const Color(0xFFBEB8B2),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0x59291D15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x26FFFFFF), width: 1.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              prefixWidget,
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  obscureText: obscureText,
                  keyboardType: keyboardType,
                  validator: validator,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                  cursorColor: const Color(0xFFFF9233),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    hintText: hint,
                    hintStyle: GoogleFonts.inter(color: const Color(0xFF7E756E), fontSize: 13.5),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              if (suffixWidget != null) suffixWidget,
            ],
          ),
        ),
      ],
    );
  }
}

class _AuthBounceButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _AuthBounceButton({required this.child, required this.onTap});

  @override
  State<_AuthBounceButton> createState() => _AuthBounceButtonState();
}

class _AuthBounceButtonState extends State<_AuthBounceButton> {
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
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: widget.child,
      ),
    );
  }
}
