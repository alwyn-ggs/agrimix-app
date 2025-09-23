import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/notification_service.dart';
import '../../providers/community_provider.dart';
import '../community/post_detail_page.dart';
import '../../theme/theme.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthProvider>().currentUser;
    return Scaffold(
      backgroundColor: NatureColors.natureBackground,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              final user = context.read<AuthProvider>().currentUser;
              if (user == null) return;
              final service = context.read<NotificationService>();
              if (value == 'read_all') {
                await service.markAllNotificationsAsRead(user.uid);
              } else if (value == 'clear_all') {
                await service.clearAllNotifications(user.uid);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'read_all', child: Text('Read all')),
              PopupMenuItem(value: 'clear_all', child: Text('Clear all')),
            ],
          ),
        ],
        backgroundColor: NatureColors.primaryGreen,
        foregroundColor: NatureColors.pureWhite,
      ),
      body: currentUser == null
          ? const Center(child: Text('Please login to view notifications'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser.uid)
                  .collection('notifications')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Failed to load notifications'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? const [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined, size: 64, color: NatureColors.lightGray),
                        SizedBox(height: 12),
                        Text('No notifications', style: TextStyle(color: NatureColors.mediumGray)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final id = docs[index].id;
                    final read = (data['read'] as bool?) ?? false;
                    final title = (data['title'] as String?) ?? 'Notification';
                    final body = (data['body'] as String?) ?? '';
                    final type = (data['type'] as String?) ?? 'general';
                    final createdAtTs = data['createdAt'];
                    DateTime? createdAt;
                    if (createdAtTs is Timestamp) createdAt = createdAtTs.toDate();

                    return InkWell(
                      onTap: () async {
                        await context
                            .read<NotificationService>()
                            .markNotificationAsRead(currentUser.uid, id);
                        _handleOpenNotification(context, type, data);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: read ? Colors.white : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: read
                              ? Border.all(color: NatureColors.offWhite)
                              : Border.all(color: NatureColors.lightGreen.withAlpha((0.4 * 255).round())),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha((0.03 * 255).round()),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: type == 'warning' ? Colors.orange : NatureColors.lightGreen,
                              child: Icon(
                                type == 'warning' ? Icons.report_gmailerrorred_outlined : Icons.notifications_outlined,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    title,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      color: NatureColors.darkGray,
                                                    ),
                                                  ),
                                                ),
                                                if (!read)
                                                  Container(
                                                    width: 10,
                                                    height: 10,
                                                    margin: const EdgeInsets.only(left: 6, top: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red,
                                                      borderRadius: BorderRadius.circular(5),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              body,
                                              style: const TextStyle(color: NatureColors.darkGray),
                                            ),
                                            if (createdAt != null) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                _formatRelative(createdAt),
                                                style: const TextStyle(color: NatureColors.mediumGray, fontSize: 12),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (value) async {
                                          final service = context.read<NotificationService>();
                                          if (value == 'mark_read') {
                                            await service.markNotificationAsRead(currentUser.uid, id);
                                          } else if (value == 'mark_unread') {
                                            await service.markNotificationAsUnread(currentUser.uid, id);
                                          } else if (value == 'delete') {
                                            await service.deleteNotification(currentUser.uid, id);
                                          }
                                        },
                                        itemBuilder: (context) => const [
                                          PopupMenuItem(value: 'mark_read', child: Text('Mark as read')),
                                          PopupMenuItem(value: 'mark_unread', child: Text('Mark as unread')),
                                          PopupMenuItem(value: 'delete', child: Text('Delete this')),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  String _formatRelative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  void _handleOpenNotification(BuildContext context, String type, Map<String, dynamic> data) async {
    switch (type) {
      case 'warning':
        // Navigate to a simple detail view of the message
        final title = (data['title'] as String?) ?? 'Community Warning';
        final body = (data['body'] as String?) ?? '';
        _showMessageSheet(context, title: title, body: body, isWarning: true);
        break;
      case 'violation_report':
        // For admins, open reported post if present
        final targetType = data['targetType']?.toString() ?? '';
        final targetId = data['targetId']?.toString() ?? '';
        if (targetType == 'post' && targetId.isNotEmpty) {
          try {
            final provider = context.read<CommunityProvider>();
            final post = await provider.postsRepo.getPost(targetId);
            if (post != null && context.mounted) {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => PostDetailPage(post: post),
              ));
            }
          } catch (_) {}
        }
        break;
      default:
        // general notifications: open detail
        final title = (data['title'] as String?) ?? 'Notification';
        final body = (data['body'] as String?) ?? '';
        _showMessageSheet(context, title: title, body: body, isWarning: false);
    }
  }
}

void _showMessageSheet(BuildContext context, {required String title, required String body, required bool isWarning}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final height = MediaQuery.of(ctx).size.height * 0.5;
      return Container(
        height: height,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isWarning ? Colors.orange.shade50 : NatureColors.offWhite,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(
                  bottom: BorderSide(color: (isWarning ? Colors.orange : NatureColors.lightGreen).withAlpha((0.4 * 255).round())),
                ),
              ),
              child: Row(
                children: [
                  Icon(isWarning ? Icons.report_gmailerrorred_outlined : Icons.notifications_outlined,
                      color: isWarning ? Colors.orange : NatureColors.darkGray),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isWarning ? Colors.orange.shade800 : NatureColors.darkGray,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Text(
                  body,
                  style: const TextStyle(fontSize: 15, height: 1.5, color: NatureColors.darkGray),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}


