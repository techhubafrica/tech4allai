import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/chat_history_service.dart';
import 'redesign_icons.dart';

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
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _sessions = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      case 'summarizer': return 'Summaries History';
      case 'code_assistant': return 'Code Sessions';
      default: return 'History';
    }
  }

  List<Map<String, dynamic>> get _filteredSessions {
    if (_searchQuery.trim().isEmpty) return _sessions;
    final q = _searchQuery.toLowerCase();
    return _sessions.where((s) {
      final title = (s['title'] ?? '').toString().toLowerCase();
      return title.contains(q);
    }).toList();
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

    for (final session in _filteredSessions) {
      final updatedStr = session['updated_at'] ?? session['created_at'];
      if (updatedStr == null) {
        groups['Older']!.add(session);
        continue;
      }

      final date = DateTime.tryParse(updatedStr)?.toLocal();
      if (date == null) {
        groups['Older']!.add(session);
        continue;
      }

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

  String _formatSessionTime(dynamic dateStr) {
    if (dateStr == null) return '';
    final dt = DateTime.tryParse(dateStr.toString())?.toLocal();
    if (dt == null) return '';
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  void _renameSession(Map<String, dynamic> session) {
    final controller = TextEditingController(text: session['title'] ?? '');
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const RadialGradient(
              center: Alignment(0.0, -0.6),
              radius: 1.2,
              colors: [
                Color(0xFF2E1F16),
                Color(0xFF1E140E),
                Color(0xFF150D08),
              ],
            ),
            border: Border.all(color: const Color(0x4DFF9233), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0x40FF7300),
                blurRadius: 28,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF9233), Color(0xFFFF6900)],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x66FF7300),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Center(
                      child: RedesignIcons.edit(size: 18, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Rename Thread',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0x402A1E16),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0x33FF9838), width: 1.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14.5),
                  cursorColor: const Color(0xFFFF9233),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter new title...',
                    hintStyle: GoogleFonts.inter(color: const Color(0xFF8E857D)),
                  ),
                  onSubmitted: (val) async {
                    if (val.trim().isNotEmpty) {
                      await _historyService.updateSessionTitle(session['id'], val.trim());
                      if (context.mounted) Navigator.pop(context);
                      _loadSessions();
                    }
                  },
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _DialogButton(
                    label: 'Cancel',
                    isPrimary: false,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  _DialogButton(
                    label: 'Save',
                    isPrimary: true,
                    onTap: () async {
                      if (controller.text.trim().isNotEmpty) {
                        await _historyService.updateSessionTitle(session['id'], controller.text.trim());
                        if (context.mounted) Navigator.pop(context);
                        _loadSessions();
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteSession(Map<String, dynamic> session) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const RadialGradient(
              center: Alignment(0.0, -0.6),
              radius: 1.2,
              colors: [
                Color(0xFF2E1714),
                Color(0xFF1E100D),
                Color(0xFF150A08),
              ],
            ),
            border: Border.all(color: const Color(0x66FF5252), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0x40FF5252),
                blurRadius: 28,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF5252), Color(0xFFD32F2F)],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x66FF5252),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Center(
                      child: RedesignIcons.trash(size: 18, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Delete Thread',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Are you sure you want to delete this thread? All messages in this conversation will be permanently removed.',
                style: GoogleFonts.inter(
                  color: const Color(0xFFD4C9C2),
                  fontSize: 13.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _DialogButton(
                    label: 'Cancel',
                    isPrimary: false,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  _DialogButton(
                    label: 'Delete',
                    isPrimary: true,
                    isDanger: true,
                    onTap: () async {
                      await _historyService.deleteSession(session['id'], widget.featureType);
                      if (context.mounted) Navigator.pop(context);
                      _loadSessions();
                      if (widget.activeSessionId == session['id']) {
                        widget.onNewChatStarted();
                      }
                    },
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
    final groups = _groupSessions();
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = screenWidth >= 600 ? 380.0 : (screenWidth * 0.86).clamp(280.0, 420.0);

    return SizedBox(
      width: drawerWidth,
      child: Drawer(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            gradient: const RadialGradient(
              center: Alignment(0.0, -0.9),
              radius: 1.35,
              colors: [
                Color(0xFF28180D), // Warm amber ambient glow
                Color(0xFF18100A),
                Color(0xFF100A06), // Deep dark base
              ],
            ),
            border: const Border(
              left: BorderSide(color: Color(0x38FF9233), width: 1.0),
              right: BorderSide(color: Color(0x38FF9233), width: 1.0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.65),
                blurRadius: 36,
                spreadRadius: 6,
              ),
              BoxShadow(
                color: const Color(0x2EFF7300),
                blurRadius: 24,
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header matching redesign header architecture
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFFF9534), Color(0xFFFF6701)],
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x66FF7300),
                                  blurRadius: 14,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: RedesignIcons.history(size: 20, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getFeatureTitle(),
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0x26FF9233),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0x40FF9233), width: 0.8),
                                ),
                                child: Text(
                                  '${_filteredSessions.length} thread${_filteredSessions.length == 1 ? '' : 's'}',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFFFF9838),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Glass close circle button
                      _DrawerIconButton(
                        onTap: () => Navigator.pop(context),
                        child: RedesignIcons.close(size: 18, color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                // New Thread Glowing Capsule CTA
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  child: _DrawerBounceButton(
                    onTap: () {
                      Navigator.pop(context);
                      widget.onNewChatStarted();
                    },
                    child: Container(
                      height: 48,
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          RedesignIcons.plus(size: 19, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'New Thread',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Real-time Search Pill
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0x59291D15),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: const Color(0x24FFFFFF), width: 1.0),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        RedesignIcons.search(size: 16, color: const Color(0xFF8E857D)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 13.5),
                            cursorColor: const Color(0xFFFF9233),
                            onChanged: (val) => setState(() => _searchQuery = val),
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: 'Search conversations...',
                              hintStyle: GoogleFonts.inter(
                                color: const Color(0xFF7E756E),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: RedesignIcons.close(size: 14, color: const Color(0xFFBEB8B2)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Session Threads List with Categories
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Color(0xFFFF881E),
                            ),
                          ),
                        )
                      : _filteredSessions.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 54,
                                      height: 54,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0x26FF9233),
                                        border: Border.all(color: const Color(0x38FF9233)),
                                      ),
                                      child: Center(
                                        child: RedesignIcons.chatBubble(
                                          size: 24,
                                          color: const Color(0xFFFF9838),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      _searchQuery.isNotEmpty
                                          ? 'No matching threads found'
                                          : 'No threads saved yet',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _searchQuery.isNotEmpty
                                          ? 'Try a different search keyword'
                                          : 'Start a conversation to see it listed here.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF8E857D),
                                        fontSize: 12,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
                              children: groups.keys.where((k) => groups[k]!.isNotEmpty).map((groupTitle) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Section Pill Header
                                    Padding(
                                      padding: const EdgeInsets.only(top: 14.0, bottom: 8.0),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(0xFFFF9233),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            groupTitle.toUpperCase(),
                                            style: GoogleFonts.inter(
                                              color: const Color(0xFFFF9838),
                                              fontWeight: FontWeight.w700,
                                              fontSize: 11,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ...groups[groupTitle]!.map((session) {
                                      final isActive = session['id'] == widget.activeSessionId;
                                      final timeStr = _formatSessionTime(session['updated_at'] ?? session['created_at']);
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8.0),
                                        child: _SessionCard(
                                          session: session,
                                          isActive: isActive,
                                          timeStr: timeStr,
                                          onTap: () {
                                            Navigator.pop(context);
                                            widget.onSessionSelected(session);
                                          },
                                          onRename: () => _renameSession(session),
                                          onDelete: () => _deleteSession(session),
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
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final Map<String, dynamic> session;
  final bool isActive;
  final String timeStr;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _SessionCard({
    required this.session,
    required this.isActive,
    required this.timeStr,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return _DrawerBounceButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: isActive
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x664E3524),
                    Color(0x732E1D13),
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x4D2B1E16),
                    Color(0x591B120C),
                  ],
                ),
          border: Border.all(
            color: isActive ? const Color(0xFFFF9233) : const Color(0x22FFFFFF),
            width: isActive ? 1.3 : 1.0,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: const Color(0x4DFF7300),
                blurRadius: 14,
                offset: const Offset(0, 3),
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                color: isActive ? const Color(0x33FF9233) : const Color(0x26423429),
                border: Border.all(
                  color: isActive ? const Color(0x66FF9233) : const Color(0x1AFFFFFF),
                  width: 0.8,
                ),
              ),
              child: Center(
                child: RedesignIcons.chatBubble(
                  size: 15,
                  color: isActive ? const Color(0xFFFF9838) : const Color(0xFF8E857D),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session['title'] ?? 'Conversation',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: isActive ? Colors.white : const Color(0xFFDDD5CE),
                      fontSize: 13.5,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (isActive) ...[
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFFF9233),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Active',
                          style: GoogleFonts.inter(
                            color: const Color(0xFFFF9838),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (timeStr.isNotEmpty)
                          Text(
                            ' • $timeStr',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF8E857D),
                              fontSize: 11,
                            ),
                          ),
                      ] else ...[
                        Text(
                          timeStr.isNotEmpty ? timeStr : 'Chat session',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF8E857D),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // Actions: Rename & Delete
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CardActionButton(
                  onTap: onRename,
                  child: RedesignIcons.edit(size: 15, color: const Color(0xFFFF9838)),
                ),
                const SizedBox(width: 6),
                _CardActionButton(
                  onTap: onDelete,
                  child: RedesignIcons.trash(size: 15, color: const Color(0xFFEF5350)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CardActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _CardActionButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return _DrawerBounceButton(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          color: const Color(0x33403226),
          border: Border.all(color: const Color(0x26FFFFFF), width: 0.8),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _DrawerIconButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _DrawerIconButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return _DrawerBounceButton(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(19),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x8C40362F), Color(0x8C261F1A)],
          ),
          border: Border.all(color: const Color(0x2EFFFFFF), width: 1.0),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final bool isDanger;
  final VoidCallback onTap;

  const _DialogButton({
    required this.label,
    required this.isPrimary,
    this.isDanger = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _DrawerBounceButton(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isPrimary
              ? (isDanger
                  ? const LinearGradient(colors: [Color(0xFFFF5252), Color(0xFFD32F2F)])
                  : const LinearGradient(colors: [Color(0xFFFF9534), Color(0xFFFF6701)]))
              : const LinearGradient(colors: [Color(0x66403226), Color(0x66291E16)]),
          border: Border.all(
            color: isPrimary
                ? Colors.transparent
                : const Color(0x33FFFFFF),
            width: 1.0,
          ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: (isDanger ? const Color(0x66FF5252) : const Color(0x66FF7300)),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: isPrimary ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerBounceButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _DrawerBounceButton({required this.child, required this.onTap});

  @override
  State<_DrawerBounceButton> createState() => _DrawerBounceButtonState();
}

class _DrawerBounceButtonState extends State<_DrawerBounceButton> {
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
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: widget.child,
      ),
    );
  }
}
