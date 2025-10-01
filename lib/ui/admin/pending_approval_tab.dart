import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/user.dart';
import '../../theme/theme.dart';
import '../../utils/logger.dart';

class PendingApprovalTab extends StatelessWidget {
  const PendingApprovalTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        AppLogger.debug('PendingApprovalTab: Loading: ${adminProvider.loading}, Users count: ${adminProvider.users.length}');
        
        if (adminProvider.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        final pendingUsers = adminProvider.users
            .where((user) => user.role == 'farmer' && !user.approved)
            .toList();
            
        AppLogger.debug('PendingApprovalTab: Pending users count: ${pendingUsers.length}');

        return Column(
          children: [
            // Simple count banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: NatureColors.lightGreen.withAlpha((0.2 * 255).round()),
              child: Row(
                children: [
                  const Icon(Icons.pending_actions, color: NatureColors.primaryGreen, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Pending approvals: ${pendingUsers.length}',
                    style: const TextStyle(
                      color: NatureColors.darkGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Content with pull-to-refresh
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await context.read<AdminProvider>().forceRefreshUsers();
                },
                child: pendingUsers.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildEmptyState(),
                        ],
                      )
                    : _buildUsersList(pendingUsers),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: NatureColors.pureWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: NatureColors.darkGray.withAlpha((0.1 * 255).round()),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: NatureColors.lightGreen.withAlpha((0.1 * 255).round()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: NatureColors.primaryGreen,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Pending Approvals',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: NatureColors.darkGreen,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'All farmer accounts are approved',
                  style: TextStyle(
                    fontSize: 16,
                    color: NatureColors.mediumGray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(List<AppUser> pendingUsers) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pendingUsers.length,
      itemBuilder: (context, index) {
        final user = pendingUsers[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: NatureColors.pureWhite,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: NatureColors.darkGray.withAlpha((0.1 * 255).round()),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _PendingUserCard(user: user),
        );
      },
    );
  }
}

class _PendingUserCard extends StatelessWidget {
  final AppUser user;

  const _PendingUserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: NatureColors.primaryGreen.withAlpha((0.3 * 255).round()),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.person,
                  color: NatureColors.primaryGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: NatureColors.darkGreen,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: const TextStyle(
                        fontSize: 14,
                        color: NatureColors.mediumGray,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (user.membershipId != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: NatureColors.lightGreen.withAlpha((0.3 * 255).round()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Membership ID: ${user.membershipId}',
                style: const TextStyle(
                  fontSize: 12,
                  color: NatureColors.darkGreen,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.access_time,
                size: 16,
                color: NatureColors.mediumGray,
              ),
              const SizedBox(width: 4),
              Text(
                'Registered: ${_formatDate(user.createdAt)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: NatureColors.mediumGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _rejectUser(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => _approveUser(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: NatureColors.primaryGreen,
                    foregroundColor: NatureColors.pureWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _approveUser(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NatureColors.pureWhite,
        title: const Text(
          'Approve User',
          style: TextStyle(color: NatureColors.darkGreen),
        ),
        content: Text(
          'Are you sure you want to approve ${user.name}?',
          style: const TextStyle(color: NatureColors.darkGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<AdminProvider>().approveUser(user.uid);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${user.name} has been approved'),
                  backgroundColor: NatureColors.primaryGreen,
                ),
              );
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _rejectUser(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NatureColors.pureWhite,
        title: const Text(
          'Reject User',
          style: TextStyle(color: NatureColors.darkGreen),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to reject ${user.name}?',
              style: const TextStyle(color: NatureColors.darkGray),
            ),
            const SizedBox(height: 12),
            const Text('Reason (optional)', style: TextStyle(color: NatureColors.darkGreen, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter a reason to include in the email',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final reason = controller.text.trim().isEmpty ? null : controller.text.trim();
              context.read<AdminProvider>().rejectUser(user.uid, reason: reason);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${user.name} has been rejected'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
