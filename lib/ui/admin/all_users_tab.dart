import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/user.dart';
import '../../theme/theme.dart';

class AllUsersTab extends StatefulWidget {
  const AllUsersTab({super.key});

  @override
  State<AllUsersTab> createState() => _AllUsersTabState();
}

class _AllUsersTabState extends State<AllUsersTab> {
  bool _isRefreshing = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        if (adminProvider.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Show only approved users and admins. Hide unapproved farmers.
        final visibleUsers = adminProvider.users
            .where((u) => u.role == 'admin' || u.approved == true)
            .toList();

        return RefreshIndicator(
          onRefresh: () async {
            setState(() => _isRefreshing = true);
            await context.read<AdminProvider>().forceRefreshUsers();
            await Future.delayed(const Duration(milliseconds: 200));
            if (mounted) setState(() => _isRefreshing = false);
          },
          child: visibleUsers.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: const [
                    SizedBox(height: 8),
                    Center(
                      child: Text(
                        'No users to display',
                        style: TextStyle(color: NatureColors.mediumGray),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: visibleUsers.length + (_isRefreshing ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isRefreshing && index == 0) {
                      return const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: LinearProgressIndicator(minHeight: 2),
                      );
                    }
                    final hasHeader = _isRefreshing;
                    final userIndex = hasHeader ? index - 1 : index;
                    final user = visibleUsers[userIndex];
                    return _UserCard(user: user);
                  },
                ),
        );
      },
    );
  }
}

class _UserCard extends StatelessWidget {
  final AppUser user;

  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: user.role == 'admin'
              ? NatureColors.darkGreen
              : NatureColors.lightGreen,
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: NatureColors.pureWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: NatureColors.darkGreen,
          ),
        ),
        subtitle: Text(
          user.email,
          style: const TextStyle(color: NatureColors.mediumGray),
        ),
        onTap: () {},
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: user.role == 'admin'
                ? NatureColors.darkGreen.withOpacity(0.1)
                : user.approved
                    ? NatureColors.primaryGreen.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            user.role == 'admin'
                ? 'Admin'
                : user.approved
                    ? 'Approved'
                    : 'Pending',
            style: TextStyle(
              color: user.role == 'admin'
                  ? NatureColors.darkGreen
                  : user.approved
                      ? NatureColors.primaryGreen
                      : Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
