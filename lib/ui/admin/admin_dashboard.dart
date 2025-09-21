import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import 'users_page.dart';
import 'recipes_page.dart';
import 'moderation_queue_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const AdminHomePage(),
    const UsersPage(),
    const RecipesPage(),
    const ModerationQueuePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NatureColors.natureBackground,
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: NatureColors.pureWhite,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: NatureColors.primaryGreen,
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.admin_panel_settings, color: NatureColors.pureWhite, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Admin Panel',
                        style: TextStyle(
                          color: NatureColors.pureWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Navigation items
                Expanded(
                  child: ListView(
                    children: [
                      _buildNavItem(0, Icons.dashboard, 'Dashboard'),
                      _buildNavItem(1, Icons.people, 'Users'),
                      _buildNavItem(2, Icons.restaurant_menu, 'Recipes'),
                      _buildNavItem(3, Icons.gavel, 'Moderation'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: _pages[_selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String title) {
    final isSelected = _selectedIndex == index;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? NatureColors.primaryGreen : NatureColors.mediumGray,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? NatureColors.primaryGreen : NatureColors.textDark,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedTileColor: NatureColors.primaryGreen.withAlpha((0.1 * 255).round()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Admin Dashboard',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: NatureColors.textDark,
            ),
          ),
          const SizedBox(height: 24),
          
          // Stats cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Users',
                  '1,234',
                  Icons.people,
                  NatureColors.primaryGreen,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Total Recipes',
                  '567',
                  Icons.restaurant_menu,
                  NatureColors.infoBlue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Open Violations',
                  '12',
                  Icons.report_problem,
                  NatureColors.warning,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Pending Approvals',
                  '8',
                  Icons.pending_actions,
                  NatureColors.mediumGray,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Quick actions
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: NatureColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              _buildActionCard(
                'Review Violations',
                'Check and moderate reported content',
                Icons.gavel,
                () {
                  // Navigate to moderation page
                },
              ),
              const SizedBox(width: 16),
              _buildActionCard(
                'Approve Users',
                'Review pending user registrations',
                Icons.person_add,
                () {
                  // Navigate to users page
                },
              ),
              const SizedBox(width: 16),
              _buildActionCard(
                'Manage Recipes',
                'Review and moderate recipes',
                Icons.restaurant_menu,
                () {
                  // Navigate to recipes page
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: NatureColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: NatureColors.mediumGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, String description, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: NatureColors.primaryGreen, size: 32),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: NatureColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: NatureColors.mediumGray,
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
