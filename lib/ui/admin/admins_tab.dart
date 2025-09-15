import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/user.dart';
import '../../theme/theme.dart';

class AdminsTab extends StatefulWidget {
  const AdminsTab({super.key});

  @override
  State<AdminsTab> createState() => _AdminsTabState();
}

class _AdminsTabState extends State<AdminsTab> {
  bool _isRefreshing = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        if (adminProvider.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        final adminUsers = adminProvider.users
            .where((user) => user.role == 'admin')
            .toList();

        return RefreshIndicator(
          onRefresh: () async {
            setState(() => _isRefreshing = true);
            await context.read<AdminProvider>().forceRefreshUsers();
            await Future.delayed(const Duration(milliseconds: 200));
            if (mounted) setState(() => _isRefreshing = false);
          },
          child: Column(
            children: [
              if (_isRefreshing) const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: adminUsers.isEmpty
                    ? AnimatedOpacity(
                        duration: const Duration(milliseconds: 150),
                        opacity: _isRefreshing ? 0.6 : 1,
                        child: ListView(children: const [
                          SizedBox(height: 120),
                          Center(
                            child: Text(
                              'No admin users found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: NatureColors.darkGray,
                              ),
                            ),
                          ),
                          SizedBox(height: 200),
                        ]),
                      )
                    : AnimatedOpacity(
                        duration: const Duration(milliseconds: 150),
                        opacity: _isRefreshing ? 0.6 : 1,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: adminUsers.length,
                          itemBuilder: (context, index) {
                            final user = adminUsers[index];
                            return _AdminCard(user: user);
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AdminCard extends StatelessWidget {
  final AppUser user;

  const _AdminCard({required this.user});

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
        leading: const CircleAvatar(
          backgroundColor: NatureColors.darkGreen,
          child: Icon(
            Icons.admin_panel_settings,
            color: NatureColors.pureWhite,
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
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: NatureColors.darkGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Admin',
            style: TextStyle(
              color: NatureColors.darkGreen,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
