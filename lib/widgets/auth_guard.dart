import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/auth_screen.dart';
import '../constants/colors.dart';
import '../services/subscription_service.dart';

class AuthGuard extends StatefulWidget {
  final Widget child;
  const AuthGuard({super.key, required this.child});

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  Session? _session;
  bool _isSuperAdminDemo = false;
  bool _isChecking = true;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _checkSession();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        _checkSession();
      }
    });
  }

  Future<void> _checkSession() async {
    final session = Supabase.instance.client.auth.currentSession;
    final isSuperAdmin = await SubscriptionService().isSuperAdminLoggedIn();
    if (mounted) {
      setState(() {
        _session = session;
        _isSuperAdminDemo = isSuperAdmin;
        _isChecking = false;
      });
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_session == null && !_isSuperAdminDemo) {
      return const AuthScreen();
    }

    return widget.child;
  }
}
