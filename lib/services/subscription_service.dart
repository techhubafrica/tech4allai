import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // RushPay API Credentials securely configured
  static const String _rushPayPublicId = 'app_1fce02f4c7898aba';
  static const String _rushPayApiKey = 'rp_e67014a3fd936ceba21a9ffe46a6399f';
  static const String _rushPayBaseUrl = 'https://core.rushpay.cash';

  // Fal.ai API key from FalApiService
  static const String _falKey = '2a647d8e-4767-4e9b-b47b-7524fcc387eb:724ada3684a44ab9e123c2be138de772';

  /// Get current user's subscription details
  Future<Map<String, dynamic>?> getSubscription() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _supabase
          .from('user_subscriptions')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        return response;
      } else {
        // Automatically provision if record doesn't exist
        return await ensureSubscriptionExists(userId);
      }
    } catch (e) {
      print('Error fetching subscription: $e');
      return null;
    }
  }

  /// Create a subscription record for the user if missing
  Future<Map<String, dynamic>> ensureSubscriptionExists(String userId) async {
    try {
      final defaultSub = {
        'id': userId,
        'tier': 'FREE',
        'credits': 0.0000,
      };
      
      await _supabase.from('user_subscriptions').upsert(defaultSub);
      return defaultSub;
    } catch (e) {
      print('Error ensuring subscription exists: $e');
      return {
        'id': userId,
        'tier': 'FREE',
        'credits': 0.0000,
      };
    }
  }

  /// Atomically verify and increment daily text requests limit
  /// Returns [true] if request is allowed, [false] if limit reached.
  Future<bool> checkAndIncrementTextUsage() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    // Get current tier to determine limits
    final sub = await getSubscription();
    final tier = sub?['tier'] ?? 'FREE';

    int maxLimit = 5;
    if (tier == 'BASIC') {
      maxLimit = 50;
    } else if (tier == 'PRO') {
      maxLimit = 150;
    }

    try {
      final bool allowed = await _supabase.rpc(
        'increment_text_usage',
        params: {
          'target_user_id': userId,
          'max_limit': maxLimit,
        },
      );
      return allowed;
    } catch (e) {
      print('Error invoking increment_text_usage RPC: $e. Falling back to local check.');
      // Local fallback in case database triggers aren't loaded yet
      if (sub == null) return true;
      final int todayCount = sub['text_requests_today'] ?? 0;
      return todayCount < maxLimit;
    }
  }

  /// Check and increment image/headshot requests, deducting credits for basic/pro users
  /// Returns map containing 'success', 'message', and 'credits'
  Future<Map<String, dynamic>> checkAndIncrementImageUsage({
    required bool isHeadshot,
    required double cost,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return {'success': false, 'message': 'User is not authenticated.'};
    }

    try {
      final Map<String, dynamic> result = await _supabase.rpc(
        'increment_image_usage',
        params: {
          'target_user_id': userId,
          'is_headshot': isHeadshot,
          'credit_cost': cost,
        },
      );
      return result;
    } catch (e) {
      print('Error invoking increment_image_usage RPC: $e');
      return {
        'success': false,
        'message': 'Failed to verify limits due to database error: $e',
      };
    }
  }

  /// Dynamically fetch unit cost of a model from Fal.ai pricing API
  Future<double> getModelPrice(String endpointId) async {
    final url = Uri.parse('https://api.fal.ai/v1/models/pricing?endpoint_id=$endpointId');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Key $_falKey',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final price = data['unit_price'] ?? data['price'];
        if (price != null) {
          return (price as num).toDouble();
        }
      }
    } catch (e) {
      print('Exception fetching model price from Fal.ai: $e');
    }

    // Default Fallbacks
    if (endpointId.contains('schnell') || endpointId.contains('nano-banana-2')) {
      return 0.003;
    }
    return 0.025; // Default for edit/lora/pro headshots
  }

  /// Create a payment reference in RushPay
  Future<Map<String, dynamic>?> createRushPayPayment({
    required double amountGHS,
    required String tier,
    required String email,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final url = Uri.parse('$_rushPayBaseUrl/api/v1/merchant/payments/create');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-API-Key': _rushPayApiKey,
        },
        body: jsonEncode({
          'amount': amountGHS.toStringAsFixed(2),
          'description': 'Tech4All $tier Subscription Upgrade',
          'callback_url': 'https://tech4all-ai.techhubafrica.org/webhook/rushpay',
          'metadata': {
            'user_id': userId,
            'tier': tier,
          },
        }),
      );

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        if (res['success'] == true) {
          return res['data'];
        }
      }
      print('RushPay create payment error: ${response.statusCode} - ${response.body}');
    } catch (e) {
      print('Exception creating RushPay payment: $e');
    }
    return null;
  }

  /// Request a short-lived widget session token from RushPay
  Future<String?> createRushPayWidgetSession(String paymentReference) async {
    final url = Uri.parse('$_rushPayBaseUrl/api/v1/merchant/payments/widget-session');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-API-Key': _rushPayApiKey,
        },
        body: jsonEncode({
          'payment_reference': paymentReference,
        }),
      );

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        if (res['success'] == true && res['data'] != null) {
          return res['data']['widget_session_token'] ?? res['data']['token'];
        }
      }
      print('RushPay widget-session error: ${response.statusCode} - ${response.body}');
    } catch (e) {
      print('Exception creating RushPay widget session: $e');
    }
    return null;
  }
}
