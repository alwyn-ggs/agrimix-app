import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import 'pending_approval_tab.dart';
import 'all_users_tab.dart';
import 'admins_tab.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab Bar
        Container(
          decoration: BoxDecoration(
            color: NatureColors.pureWhite,
            boxShadow: [
              BoxShadow(
                color: NatureColors.darkGray.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: NatureColors.primaryGreen,
            labelColor: NatureColors.primaryGreen,
            unselectedLabelColor: NatureColors.mediumGray,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(
                icon: Icon(Icons.pending_actions, size: 20),
                text: 'Pending Approval',
              ),
              Tab(
                icon: Icon(Icons.people, size: 20),
                text: 'All Users',
              ),
              Tab(
                icon: Icon(Icons.admin_panel_settings, size: 20),
                text: 'Admins',
              ),
            ],
          ),
        ),
        // Tab Content
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  NatureColors.natureBackground,
                  NatureColors.offWhite,
                ],
              ),
            ),
            child: TabBarView(
              controller: _tabController,
              children: const [
                PendingApprovalTab(),
                AllUsersTab(),
                AdminsTab(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}