import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/chat_history_service.dart';

class ChatHistoryDrawer extends StatefulWidget {
  final String featureType;
  final String? activeSessionId;
  final Function(Map<String, dynamic> session) onSessionSelected;
  final VoidCallback onNewChatStarted;

  const ChatHistoryDrawer({
    super.key,
    required this.featureType,
    required this.activeSessionId,
    required this.onSessionSelected,
    required this.onNewChatStarted,
  });

  @override
  State<ChatHistoryDrawer> createState() => _ChatHistoryDrawerState();
}

class _ChatHistoryDrawerState extends State<ChatHistoryDrawer> {
  final ChatHistoryService _historyService = ChatHistoryService();
  List<Map<String, dynamic>> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    final sessions = await _historyService.getSessions(widget.featureType);
    if (mounted) {
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    }
  }

  String _getFeatureTitle() {
    switch (widget.featureType) {
      case 'main_chat': return 'Chat History';
      case 'study_assistant': return 'Study Sessions';
      case 'flashcards': return 'Saved Decks';
      case 'image_gen': return 'Generated Images';
      case 'headshots': return 'Pro Headshots';
      default: return 'History';
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupSessions() {
    final Map<String, List<Map<String, dynamic>>> groups = {
      'Today': [],
      'Yesterday': [],
      'Previous 7 Days': [],
      'Older': [],
    };

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final sevenDaysAgo = today.subtract(const Duration(days: 7));

    for (final session in _sessions) {
      final updatedStr = session['updated_at'] ?? session['created_at'];
      if (updatedStr == null) {
        groups['Older']!.add(session);
        continue;
      }

      final date = DateTime.parse(updatedStr).toLocal();
      if (date.isAfter(today)) {
        groups['Today']!.add(session);
      } else if (date.isAfter(yesterday)) {
        groups['Yesterday']!.add(session);
      } else if (date.isAfter(sevenDaysAgo)) {
        groups['Previous 7 Days']!.add(session);
      } else {
        groups['Older']!.add(session);
      }
    }

    return groups;
  }

  void _renameSession(Map<String, dynamic> session) {
    final controller = TextEditingController(text: session['title']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D241D), // AppColors.neutralSurface
        title: Text('Rename Thread', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter new title...',
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF6F00))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _historyService.updateSessionTitle(session['id'], controller.text.trim());
                Navigator.pop(context);
                _loadSessions();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6F00)),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteSession(Map<String, dynamic> session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D241D),
        title: Text('Delete Thread', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete this thread? This action cannot be undone.', style: GoogleFonts.inter(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await _historyService.deleteSession(session['id'], widget.featureType);
              Navigator.pop(context);
              _loadSessions();
              if (widget.activeSessionId == session['id']) {
                widget.onNewChatStarted();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groupSessions();
    const primaryColor = Color(0xFFFF6F00); // AppColors.primary
    const surfaceColor = Color(0xFF2D241D); // AppColors.neutralSurface
    const borderColor = Color(0xFF3D3228); // AppColors.neutralBorder

    return Drawer(
      backgroundColor: const Color(0xFF1E1712), // Dark drawer color
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getFeatureTitle(),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Start New Chat Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  widget.onNewChatStarted();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'New Thread',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Session List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: primaryColor))
                  : _sessions.isEmpty
                      ? Center(
                          child: Text(
                            'No threads saved yet.',
                            style: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          children: groups.keys.where((k) => groups[k]!.isNotEmpty).map((groupTitle) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 18.0, bottom: 8.0),
                                  child: Text(
                                    groupTitle,
                                    style: GoogleFonts.inter(
                                      color: primaryColor.withOpacity(0.8),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                ...groups[groupTitle]!.map((session) {
                                  final isActive = session['id'] == widget.activeSessionId;
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8.0),
                                    decoration: BoxDecoration(
                                      color: isActive ? surfaceColor : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isActive ? borderColor : Colors.transparent,
                                      ),
                                    ),
                                    child: ListTile(
                                      onTap: () {
                                        Navigator.pop(context);
                                        widget.onSessionSelected(session);
                                      },
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12.0),
                                      title: Text(
                                        session['title'] ?? 'Conversation',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          color: isActive ? Colors.white : Colors.white70,
                                          fontSize: 14,
                                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                      ),
                                      trailing: isActive
                                          ? Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit_outlined, size: 18, color: primaryColor),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                  onPressed: () => _renameSession(session),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                  onPressed: () => _deleteSession(session),
                                                ),
                                              ],
                                            )
                                          : null,
                                    ),
                                  );
                                }),
                              ],
                            );
                          }).toList(),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
