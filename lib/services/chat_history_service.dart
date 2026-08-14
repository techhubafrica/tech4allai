import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatHistoryService {
  static final ChatHistoryService _instance = ChatHistoryService._internal();
  factory ChatHistoryService() => _instance;
  ChatHistoryService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get current user ID helper
  String? get _userId => _supabase.auth.currentUser?.id;

  /// Fetch all sessions for a specific feature type
  Future<List<Map<String, dynamic>>> getSessions(String featureType) async {
    final uid = _userId;
    if (uid == null) return [];

    try {
      final response = await _supabase
          .from('chat_sessions')
          .select()
          .eq('user_id', uid)
          .eq('feature_type', featureType)
          .order('updated_at', ascending: false);

      final List<Map<String, dynamic>> sessions = List<Map<String, dynamic>>.from(response);
      
      // Cache locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_sessions_$featureType', jsonEncode(sessions));
      
      return sessions;
    } catch (e) {
      print('Error getting chat sessions: $e. Loading local cache.');
      // Load local cache fallback
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString('cached_sessions_$featureType');
      if (cachedStr != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(cachedStr));
      }
      return [];
    }
  }

  /// Create a new chat session
  Future<Map<String, dynamic>> createSession(String featureType, {String? initialTitle}) async {
    final uid = _userId;
    if (uid == null) throw Exception('User not authenticated');

    final title = initialTitle ?? 'New Conversation';

    try {
      final response = await _supabase
          .from('chat_sessions')
          .insert({
            'user_id': uid,
            'feature_type': featureType,
            'title': title,
          })
          .select()
          .single();

      return Map<String, dynamic>.from(response);
    } catch (e) {
      print('Error creating chat session in DB: $e. Creating local fallback session.');
      // Fallback local session for offline/testing
      final tempId = 'local_${DateTime.now().millisecondsSinceEpoch}';
      final newSession = {
        'id': tempId,
        'user_id': uid,
        'feature_type': featureType,
        'title': title,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString('cached_sessions_$featureType');
      List<dynamic> list = cachedStr != null ? jsonDecode(cachedStr) : [];
      list.insert(0, newSession);
      await prefs.setString('cached_sessions_$featureType', jsonEncode(list));
      
      return newSession;
    }
  }

  /// Fetch all messages for a session
  Future<List<Map<String, dynamic>>> getMessages(String sessionId) async {
    if (sessionId.startsWith('local_')) {
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString('cached_messages_$sessionId');
      if (cachedStr != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(cachedStr));
      }
      return [];
    }

    try {
      final response = await _supabase
          .from('chat_messages')
          .select()
          .eq('session_id', sessionId)
          .order('created_at', ascending: true);

      final List<Map<String, dynamic>> messages = List<Map<String, dynamic>>.from(response);
      
      // Cache locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_messages_$sessionId', jsonEncode(messages));
      
      return messages;
    } catch (e) {
      print('Error getting chat messages: $e. Loading local cache.');
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString('cached_messages_$sessionId');
      if (cachedStr != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(cachedStr));
      }
      return [];
    }
  }

  /// Add a message to a session
  Future<Map<String, dynamic>> addMessage(
    String sessionId, {
    required bool isUser,
    required String message,
    String? imageUrl,
    Map<String, dynamic>? metadata,
  }) async {
    final tempMsg = {
      'id': 'msg_${DateTime.now().millisecondsSinceEpoch}',
      'session_id': sessionId,
      'is_user': isUser,
      'message': message,
      'image_url': imageUrl,
      'metadata': metadata,
      'created_at': DateTime.now().toIso8601String(),
    };

    // If local session
    if (sessionId.startsWith('local_')) {
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString('cached_messages_$sessionId');
      List<dynamic> list = cachedStr != null ? jsonDecode(cachedStr) : [];
      list.add(tempMsg);
      await prefs.setString('cached_messages_$sessionId', jsonEncode(list));
      
      // Auto-name if first message
      if (isUser && list.length == 1) {
        await updateSessionTitle(sessionId, _generateTitle(message));
      }
      return tempMsg;
    }

    try {
      final response = await _supabase
          .from('chat_messages')
          .insert({
            'session_id': sessionId,
            'is_user': isUser,
            'message': message,
            'image_url': imageUrl,
            'metadata': metadata,
          })
          .select()
          .single();

      final newMsg = Map<String, dynamic>.from(response);

      // Auto-update session title and updated_at
      final countRes = await _supabase
          .from('chat_messages')
          .select('id')
          .eq('session_id', sessionId);
          
      if (isUser && countRes.length <= 1) {
        await updateSessionTitle(sessionId, _generateTitle(message));
      } else {
        // Just touch updated_at
        await _supabase
            .from('chat_sessions')
            .update({'updated_at': DateTime.now().toIso8601String()})
            .eq('id', sessionId);
      }

      return newMsg;
    } catch (e) {
      print('Error saving message in DB: $e. Logging to local cache.');
      // Local save fallback
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString('cached_messages_$sessionId');
      List<dynamic> list = cachedStr != null ? jsonDecode(cachedStr) : [];
      list.add(tempMsg);
      await prefs.setString('cached_messages_$sessionId', jsonEncode(list));
      return tempMsg;
    }
  }

  /// Update the session title
  Future<void> updateSessionTitle(String sessionId, String newTitle) async {
    if (sessionId.startsWith('local_')) {
      final prefs = await SharedPreferences.getInstance();
      // Try to find in all cache types
      final featureTypes = ['main_chat', 'study_assistant', 'flashcards', 'image_gen', 'headshots'];
      for (final type in featureTypes) {
        final cachedStr = prefs.getString('cached_sessions_$type');
        if (cachedStr != null) {
          List<dynamic> list = jsonDecode(cachedStr);
          var index = list.indexWhere((s) => s['id'] == sessionId);
          if (index != -1) {
            list[index]['title'] = newTitle;
            list[index]['updated_at'] = DateTime.now().toIso8601String();
            await prefs.setString('cached_sessions_$type', jsonEncode(list));
            break;
          }
        }
      }
      return;
    }

    try {
      await _supabase
          .from('chat_sessions')
          .update({
            'title': newTitle,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId);
    } catch (e) {
      print('Error updating session title: $e');
    }
  }

  /// Delete a session
  Future<void> deleteSession(String sessionId, String featureType) async {
    final prefs = await SharedPreferences.getInstance();

    if (sessionId.startsWith('local_')) {
      final cachedStr = prefs.getString('cached_sessions_$featureType');
      if (cachedStr != null) {
        List<dynamic> list = jsonDecode(cachedStr);
        list.removeWhere((s) => s['id'] == sessionId);
        await prefs.setString('cached_sessions_$featureType', jsonEncode(list));
      }
      prefs.remove('cached_messages_$sessionId');
      return;
    }

    try {
      await _supabase.from('chat_sessions').delete().eq('id', sessionId);
    } catch (e) {
      print('Error deleting session: $e');
    }
  }

  /// Generate a clean title from prompt text
  String _generateTitle(String text) {
    if (text.isEmpty) return 'New Conversation';
    
    // Trim and clean up whitespace
    var title = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    
    // Strip common starting prompts
    final removePrefixes = [
      'can you help me',
      'can you explain',
      'can you write',
      'please write',
      'write a',
      'how to',
      'what is',
      'tell me about',
    ];
    
    for (final prefix in removePrefixes) {
      if (title.toLowerCase().startsWith(prefix)) {
        title = title.substring(prefix.length).trim();
      }
    }

    if (title.isEmpty) return 'Conversation';
    
    // Capitalize first letter
    title = title[0].toUpperCase() + title.substring(1);
    
    // Truncate to max 35 chars
    if (title.length > 35) {
      title = '${title.substring(0, 32)}...';
    }
    
    return title;
  }
}
