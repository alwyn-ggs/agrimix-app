import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/user.dart';
import '../../theme/theme.dart';
import '../../utils/exceptions.dart';

class PendingApprovalTab extends StatefulWidget {
  const PendingApprovalTab({super.key});

  @override
  State<PendingApprovalTab> createState() => _PendingApprovalTabState();
}

class _PendingApprovalTabState extends State<PendingApprovalTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<AppUser> _lastNonEmptyPending = const [];
  bool _isRefreshing = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        print('PendingApprovalTab: Building with AdminProvider');
        print('PendingApprovalTab: AdminProvider instance: ${adminProvider.hashCode}');

        return Column(
          children: [
            const SizedBox(height: 12),
            const SizedBox(height: 16),
            // Content from real-time stream with pull-to-refresh
            Expanded(
              child: ScrollConfiguration(
                behavior: const MaterialScrollBehavior().copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.stylus,
                    PointerDeviceKind.unknown,
                  },
                ),
                child: RefreshIndicator(
                  onRefresh: () async {
                    setState(() => _isRefreshing = true);
                    await adminProvider.forceRefreshUsers();
                    await Future.delayed(const Duration(milliseconds: 200));
                    if (mounted) setState(() => _isRefreshing = false);
                  },
                  child: Column(
                    children: [
                      if (_isRefreshing)
                        const LinearProgressIndicator(minHeight: 2),
                      Expanded(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 150),
                          opacity: _isRefreshing ? 0.6 : 1,
                          child: StreamBuilder<List<AppUser>>(
                            stream: adminProvider.pendingUsersStream,
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return CustomScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  slivers: [
                                    SliverFillRemaining(
                                      hasScrollBody: false,
                                      child: Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.error_outline, color: Colors.red),
                                            const SizedBox(height: 8),
                                            Text('Failed to load: ${snapshot.error}'),
                                            const SizedBox(height: 8),
                                            FilledButton(
                                              onPressed: () => adminProvider.forceRefreshUsers(),
                                              child: const Text('Retry'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }

                              if (snapshot.connectionState == ConnectionState.waiting) {
                                final list = _lastNonEmptyPending;
                                if (list.isNotEmpty) {
                                  return _buildPendingListScrollable(list);
                                }
                                return CustomScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  slivers: const [
                                    SliverFillRemaining(
                                      hasScrollBody: false,
                                      child: Center(child: CircularProgressIndicator()),
                                    ),
                                  ],
                                );
                              }

                              final streamList = snapshot.data ?? const <AppUser>[];
                              final providerList = adminProvider.pendingUsers;
                              final effectiveList = streamList.isNotEmpty
                                  ? streamList
                                  : (providerList.isNotEmpty ? providerList : const <AppUser>[]);

                              if (effectiveList.isNotEmpty) {
                                _lastNonEmptyPending = effectiveList;
                                return _buildPendingListScrollable(effectiveList);
                              }

                              return CustomScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                slivers: [
                                  SliverFillRemaining(
                                    hasScrollBody: false,
                                    child: _buildEmptyState(),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
                  color: NatureColors.darkGray.withOpacity(0.1),
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
                    color: NatureColors.lightGreen.withOpacity(0.1),
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
                  'No pending account',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: NatureColors.darkGreen,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'All users are approved',
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
                color: NatureColors.darkGray.withOpacity(0.1),
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

  Widget _buildPendingListScrollable(List<AppUser> list) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pending (stream: ${list.length})',
                    style: const TextStyle(color: Colors.blue, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final user = list[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: NatureColors.pureWhite,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: NatureColors.darkGray.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _PendingUserCard(user: user),
                );
              },
              childCount: list.length,
            ),
          ),
        ),
      ],
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
                  color: NatureColors.primaryGreen.withOpacity(0.1),
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
                color: NatureColors.lightGreen.withOpacity(0.1),
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
              Icon(
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
                child: Builder(
                  builder: (context) {
                    final adminProvider = context.read<AdminProvider>();
                    final approving = adminProvider.isApproving(user.uid);
                    return OutlinedButton(
                      onPressed: approving ? null : () => _rejectUser(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Reject'),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final adminProvider = context.watch<AdminProvider>();
                    final approving = adminProvider.isApproving(user.uid);
                    return FilledButton(
                      onPressed: approving ? null : () => _approveUser(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: NatureColors.primaryGreen,
                        foregroundColor: NatureColors.pureWhite,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: approving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Approve'),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _approveUser(BuildContext context) async {
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
            onPressed: () async {
              Navigator.pop(context);
              try {
                await context.read<AdminProvider>().approveUser(user.uid);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${user.name} has been approved successfully!'),
                      backgroundColor: NatureColors.primaryGreen,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to approve user: ${e.toString()}'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _rejectUser(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NatureColors.pureWhite,
        title: const Text(
          'Reject User',
          style: TextStyle(color: NatureColors.darkGreen),
        ),
        content: Text(
          'Are you sure you want to reject ${user.name}?',
          style: const TextStyle(color: NatureColors.darkGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await context.read<AdminProvider>().rejectUser(user.uid);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${user.name} has been rejected'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to reject user: ${e.toString()}'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
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
