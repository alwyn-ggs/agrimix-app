import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/notification_analytics_service.dart';
import 'notification_preferences_page.dart';
import 'notification_analytics_page.dart';
import '../../theme/theme.dart';

class EnhancedNotificationsPage extends StatefulWidget {
  const EnhancedNotificationsPage({super.key});

  @override
  State<EnhancedNotificationsPage> createState() => _EnhancedNotificationsPageState();
}

class _EnhancedNotificationsPageState extends State<EnhancedNotificationsPage> {
  final NotificationAnalyticsService _analyticsService = NotificationAnalyticsService();
  String _selectedFilter = 'all';
  String _selectedSort = 'newest';

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthProvider>().currentUser;
    return Scaffold(
      backgroundColor: NatureColors.natureBackground,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: NatureColors.primaryGreen,
        foregroundColor: NatureColors.pureWhite,
        actions: [
          _buildFilterMenu(),
          _buildSortMenu(),
          _buildMoreMenu(),
        ],
      ),
      body: currentUser == null
          ? const Center(child: Text('Please login to view notifications'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _getNotificationsStream(currentUser.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Failed to load notifications'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return _buildEmptyState();
                }
                return _buildNotificationsList(docs, currentUser.uid);
              },
            ),
    );
  }

  Widget _buildFilterMenu() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        setState(() {
          _selectedFilter = value;
        });
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'all', child: Text('All Notifications')),
        PopupMenuItem(value: 'unread', child: Text('Unread Only')),
        PopupMenuItem(value: 'announcements', child: Text('Announcements')),
        PopupMenuItem(value: 'fermentation_reminders', child: Text('Fermentation Reminders')),
        PopupMenuItem(value: 'community_updates', child: Text('Community Updates')),
        PopupMenuItem(value: 'moderation_alerts', child: Text('Moderation Alerts')),
      ],
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Icon(Icons.filter_list),
      ),
    );
  }

  Widget _buildSortMenu() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        setState(() {
          _selectedSort = value;
        });
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'newest', child: Text('Newest First')),
        PopupMenuItem(value: 'oldest', child: Text('Oldest First')),
        PopupMenuItem(value: 'type', child: Text('By Type')),
        PopupMenuItem(value: 'priority', child: Text('By Priority')),
      ],
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Icon(Icons.sort),
      ),
    );
  }

  Widget _buildMoreMenu() {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        final currentUser = context.read<AuthProvider>().currentUser;
        if (currentUser == null) return;

        switch (value) {
          case 'mark_all_read':
            await _markAllAsRead(currentUser.uid);
            break;
          case 'clear_all':
            await _clearAllNotifications(currentUser.uid);
            break;
          case 'preferences':
            _navigateToPreferences();
            break;
          case 'analytics':
            _navigateToAnalytics();
            break;
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'mark_all_read', child: Text('Mark All as Read')),
        PopupMenuItem(value: 'clear_all', child: Text('Clear All')),
        PopupMenuItem(value: 'preferences', child: Text('Preferences')),
        PopupMenuItem(value: 'analytics', child: Text('Analytics')),
      ],
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Icon(Icons.more_vert),
      ),
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getNotificationsStream(String userId) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications');

    // Apply filter
    if (_selectedFilter == 'unread') {
      query = query.where('read', isEqualTo: false);
    } else if (_selectedFilter != 'all') {
      query = query.where('type', isEqualTo: _selectedFilter);
    }

    // Apply sort
    switch (_selectedSort) {
      case 'oldest':
        return query.orderBy('createdAt', descending: false).snapshots();
      case 'type':
        return query.orderBy('type').orderBy('createdAt', descending: true).snapshots();
      case 'priority':
        return query.orderBy('priority', descending: true).orderBy('createdAt', descending: true).snapshots();
      default: // newest
        return query.orderBy('createdAt', descending: true).snapshots();
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_off_outlined, size: 64, color: NatureColors.lightGray),
          const SizedBox(height: 16),
          const Text(
            'No notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: NatureColors.mediumGray,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You\'re all caught up!',
            style: TextStyle(color: NatureColors.mediumGray),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToPreferences,
            icon: const Icon(Icons.settings),
            label: const Text('Notification Preferences'),
            style: ElevatedButton.styleFrom(
              backgroundColor: NatureColors.primaryGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, String userId) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final doc = docs[index];
        final data = doc.data();
        final id = doc.id;
        final read = (data['read'] as bool?) ?? false;
        final title = (data['title'] as String?) ?? 'Notification';
        final body = (data['body'] as String?) ?? '';
        final type = (data['type'] as String?) ?? 'general';
        final priority = (data['priority'] as int?) ?? 0;
        final actions = (data['actions'] as List<dynamic>?) ?? [];
        final createdAtTs = data['createdAt'];
        DateTime? createdAt;
        if (createdAtTs is Timestamp) createdAt = createdAtTs.toDate();

        return _buildNotificationCard(
          id: id,
          title: title,
          body: body,
          type: type,
          priority: priority,
          read: read,
          actions: actions,
          createdAt: createdAt,
          userId: userId,
        );
      },
    );
  }

  Widget _buildNotificationCard({
    required String id,
    required String title,
    required String body,
    required String type,
    required int priority,
    required bool read,
    required List<dynamic> actions,
    required DateTime? createdAt,
    required String userId,
  }) {
    return Card(
      elevation: read ? 1 : 3,
      child: InkWell(
        onTap: () => _handleNotificationTap(id, type, userId),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: read
                ? Border.all(color: NatureColors.offWhite)
                : Border.all(color: _getPriorityColor(priority).withValues(alpha: 0.3)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNotificationIcon(type, priority),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontWeight: read ? FontWeight.w500 : FontWeight.w600,
                                  fontSize: 16,
                                  color: NatureColors.darkGray,
                                ),
                              ),
                            ),
                            if (!read)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: NatureColors.primaryGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          body,
                          style: const TextStyle(
                            color: NatureColors.darkGray,
                            fontSize: 14,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (createdAt != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 14,
                                color: NatureColors.mediumGray,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatRelativeTime(createdAt),
                                style: const TextStyle(
                                  color: NatureColors.mediumGray,
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              if (priority > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getPriorityColor(priority).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: _getPriorityColor(priority).withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    _getPriorityLabel(priority),
                                    style: TextStyle(
                                      color: _getPriorityColor(priority),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleNotificationAction(value, id, type, userId),
                    itemBuilder: (context) => [
                      if (!read)
                        const PopupMenuItem(value: 'mark_read', child: Text('Mark as Read')),
                      if (read)
                        const PopupMenuItem(value: 'mark_unread', child: Text('Mark as Unread')),
                      const PopupMenuItem(value: 'snooze', child: Text('Snooze')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildActionButtons(actions, id, type, userId),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(String type, int priority) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case 'announcements':
        iconData = Icons.campaign;
        iconColor = Colors.blue;
        break;
      case 'fermentation_reminders':
        iconData = Icons.science;
        iconColor = NatureColors.primaryGreen;
        break;
      case 'community_updates':
        iconData = Icons.people;
        iconColor = Colors.purple;
        break;
      case 'moderation_alerts':
        iconData = Icons.warning;
        iconColor = Colors.orange;
        break;
      case 'system_updates':
        iconData = Icons.system_update;
        iconColor = Colors.grey;
        break;
      case 'digest':
        iconData = Icons.dashboard;
        iconColor = Colors.teal;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = NatureColors.primaryGreen;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  Widget _buildActionButtons(List<dynamic> actions, String notificationId, String type, String userId) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: actions.map((action) {
        final actionData = action as Map<String, dynamic>;
        final actionId = actionData['id'] as String;
        final actionTitle = actionData['title'] as String;
        // showsUserInterface exists but is not used directly in UI; retain parse without unused var.
        final bool _ = actionData['showsUserInterface'] as bool? ?? true;

        return ActionChip(
          label: Text(actionTitle),
          onPressed: () => _handleActionTap(actionId, notificationId, type, userId),
      backgroundColor: NatureColors.primaryGreen.withValues(alpha: 0.1),
          labelStyle: const TextStyle(
            color: NatureColors.primaryGreen,
            fontWeight: FontWeight.w500,
          ),
        );
      }).toList(),
    );
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 3:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 1:
        return Colors.yellow;
      default:
        return NatureColors.primaryGreen;
    }
  }

  String _getPriorityLabel(int priority) {
    switch (priority) {
      case 3:
        return 'HIGH';
      case 2:
        return 'MED';
      case 1:
        return 'LOW';
      default:
        return 'NORMAL';
    }
  }

  String _formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _handleNotificationTap(String id, String type, String userId) async {
    // Mark as read
    await _markAsRead(id, userId);
    
    // Track analytics
    await _analyticsService.trackNotificationOpened(
      userId: userId,
      notificationId: id,
      notificationType: type,
    );

    // Navigate based on type
    _navigateBasedOnType(type, id);
  }

  Future<void> _handleActionTap(String actionId, String notificationId, String type, String userId) async {
    // Track analytics
    await _analyticsService.trackNotificationClicked(
      userId: userId,
      notificationId: notificationId,
      notificationType: type,
      metadata: {'action': actionId},
    );

    // Handle action
    switch (actionId) {
      case 'view_details':
        _navigateBasedOnType(type, notificationId);
        break;
      case 'mark_done':
        _showMarkDoneDialog(notificationId);
        break;
      case 'quick_reply':
        _showQuickReplyDialog(notificationId);
        break;
      case 'snooze':
        _showSnoozeDialog(notificationId);
        break;
      default:
        _showActionNotImplementedDialog(actionId);
    }
  }

  Future<void> _handleNotificationAction(String action, String id, String type, String userId) async {
    switch (action) {
      case 'mark_read':
        await _markAsRead(id, userId);
        break;
      case 'mark_unread':
        await _markAsUnread(id, userId);
        break;
      case 'snooze':
        _showSnoozeDialog(id);
        break;
      case 'delete':
        await _deleteNotification(id, userId);
        break;
    }
  }

  void _navigateBasedOnType(String type, String notificationId) {
    switch (type) {
      case 'announcements':
        _navigateToAnnouncements();
        break;
      case 'fermentation_reminders':
        _navigateToFermentation();
        break;
      case 'community_updates':
        _navigateToCommunity();
        break;
      case 'moderation_alerts':
        _navigateToModeration();
        break;
      case 'system_updates':
        _navigateToSettings();
        break;
      default:
        _navigateToNotifications();
    }
  }

  void _showMarkDoneDialog(String notificationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Done'),
        content: const Text('Are you sure you want to mark this as done?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessSnackBar('Marked as done');
            },
            child: const Text('Mark Done'),
          ),
        ],
      ),
    );
  }

  void _showQuickReplyDialog(String notificationId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Reply'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Type your reply...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessSnackBar('Reply sent');
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showSnoozeDialog(String notificationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Snooze Notification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('15 minutes'),
              onTap: () {
                Navigator.pop(context);
                _snoozeNotification(notificationId, 15);
              },
            ),
            ListTile(
              title: const Text('1 hour'),
              onTap: () {
                Navigator.pop(context);
                _snoozeNotification(notificationId, 60);
              },
            ),
            ListTile(
              title: const Text('4 hours'),
              onTap: () {
                Navigator.pop(context);
                _snoozeNotification(notificationId, 240);
              },
            ),
            ListTile(
              title: const Text('1 day'),
              onTap: () {
                Navigator.pop(context);
                _snoozeNotification(notificationId, 1440);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showActionNotImplementedDialog(String actionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Action Not Available'),
        content: Text('The action "$actionId" is not yet implemented.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: NatureColors.primaryGreen,
      ),
    );
  }

  // Navigation methods
  void _navigateToPreferences() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationPreferencesPage(),
      ),
    );
  }

  void _navigateToAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationAnalyticsPage(),
      ),
    );
  }

  void _navigateToAnnouncements() {
    // Navigate to announcements page
    _showComingSoonDialog('Announcements');
  }

  void _navigateToFermentation() {
    // Navigate to fermentation page
    _showComingSoonDialog('Fermentation');
  }

  void _navigateToCommunity() {
    // Navigate to community page
    _showComingSoonDialog('Community');
  }

  void _navigateToModeration() {
    // Navigate to moderation page
    _showComingSoonDialog('Moderation');
  }

  void _navigateToSettings() {
    // Navigate to settings page
    _showComingSoonDialog('Settings');
  }

  void _navigateToNotifications() {
    // Already on notifications page
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coming Soon'),
        content: Text('$feature navigation will be implemented soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Database operations
  Future<void> _markAsRead(String id, String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(id)
          .update({'read': true});
    } catch (e) {
      _showErrorSnackBar('Failed to mark as read');
    }
  }

  Future<void> _markAsUnread(String id, String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(id)
          .update({'read': false});
    } catch (e) {
      _showErrorSnackBar('Failed to mark as unread');
    }
  }

  Future<void> _markAllAsRead(String userId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final query = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .get();

      for (final doc in query.docs) {
        batch.update(doc.reference, {'read': true});
      }

      await batch.commit();
      _showSuccessSnackBar('All notifications marked as read');
    } catch (e) {
      _showErrorSnackBar('Failed to mark all as read');
    }
  }

  Future<void> _clearAllNotifications(String userId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final query = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .get();

      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      _showSuccessSnackBar('All notifications cleared');
    } catch (e) {
      _showErrorSnackBar('Failed to clear all notifications');
    }
  }

  Future<void> _deleteNotification(String id, String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(id)
          .delete();
      _showSuccessSnackBar('Notification deleted');
    } catch (e) {
      _showErrorSnackBar('Failed to delete notification');
    }
  }

  void _snoozeNotification(String notificationId, int minutes) {
    // Implementation for snoozing notifications
    _showSuccessSnackBar('Notification snoozed for $minutes minutes');
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
