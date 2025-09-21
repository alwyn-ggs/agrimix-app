import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/theme.dart';
import '../../providers/auth_provider.dart';
import 'users_page.dart';
import 'recipes_page.dart';
import 'ingredients_page.dart';
import 'community_moderation_page.dart';
import 'fermentation_monitor_page.dart';
import 'announcements_page.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;
  bool _isSidebarExpanded = false;

  final List<AdminMenuItem> _menuItems = [
    AdminMenuItem(
      icon: Icons.people_outline,
      title: 'Users',
      page: const UsersPage(),
    ),
    AdminMenuItem(
      icon: Icons.restaurant_menu_outlined,
      title: 'Recipes',
      page: const RecipesPage(),
    ),
    AdminMenuItem(
      icon: Icons.inventory_outlined,
      title: 'Ingredients',
      page: const IngredientsPage(),
    ),
    AdminMenuItem(
      icon: Icons.groups_outlined,
      title: 'Community',
      page: const CommunityModerationPage(),
    ),
    AdminMenuItem(
      icon: Icons.bubble_chart_outlined,
      title: 'Fermentation',
      page: const FermentationMonitorPage(),
    ),
    AdminMenuItem(
      icon: Icons.campaign_outlined,
      title: 'Announcements',
      page: const AnnouncementsPage(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NatureColors.natureBackground,
      body: SafeArea(
        child: Stack(
          children: [
            // Main Content - Fixed width to prevent overflow
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: 0,
              child: Column(
                children: [
                  // Top Bar
                  _buildTopBar(),
                  // Content
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
                      child: _menuItems[_selectedIndex].page,
                    ),
                  ),
                ],
              ),
            ),
            // Sidebar - Overlay on top
            if (_isSidebarExpanded)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: MediaQuery.of(context).size.width * 0.85, // Responsive width for mobile
                  child: _buildSidebar(),
                ),
              ),
            // Semi-transparent overlay when sidebar is open
            if (_isSidebarExpanded)
              Positioned(
                left: MediaQuery.of(context).size.width * 0.85, // Responsive width for mobile
                right: 0,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isSidebarExpanded = false;
                    });
                  },
                  child: Container(
                    color: Colors.black.withAlpha((0.3 * 255).round()),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            NatureColors.darkGreen,
            NatureColors.primaryGreen,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: NatureColors.darkGray.withAlpha((0.1 * 255).round()),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo/Header
          Container(
            padding: const EdgeInsets.all(12), // Reduced from 16 for mobile
            child: const Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  color: NatureColors.pureWhite,
                  size: 24, // Reduced from 28 for mobile
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Admin Panel',
                    style: TextStyle(
                      color: NatureColors.pureWhite,
                      fontSize: 16, // Reduced from 18 for mobile
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: NatureColors.offWhite, height: 1),
          // Menu Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final item = _menuItems[index];
                final isSelected = _selectedIndex == index;
                
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Reduced margins for mobile
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
                          _isSidebarExpanded = false; // Auto-close menu when item is clicked
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // Reduced padding for mobile
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? NatureColors.pureWhite 
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected 
                              ? Border.all(
                                  color: NatureColors.lightGreen.withAlpha((0.3 * 255).round()),
                                  width: 1,
                                )
                              : null,
                          boxShadow: isSelected 
                              ? [
                                  BoxShadow(
                                    color: NatureColors.darkGreen.withAlpha((0.1 * 255).round()),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              color: isSelected 
                                  ? NatureColors.darkGreen 
                                  : NatureColors.pureWhite,
                              size: 20, // Reduced from 24 for mobile
                            ),
                            const SizedBox(width: 12), // Reduced from 16 for mobile
                            Expanded(
                              child: Text(
                                item.title,
                                style: TextStyle(
                                  color: isSelected 
                                      ? NatureColors.darkGreen 
                                      : NatureColors.pureWhite,
                                  fontWeight: isSelected 
                                      ? FontWeight.w700 
                                      : FontWeight.w500,
                                  fontSize: 14, // Reduced from 16 for mobile
                                ),
                              ),
                            ),
                            if (isSelected)
                              Container(
                                width: 4,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: NatureColors.primaryGreen,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // User Info
          Container(
            padding: const EdgeInsets.all(16),
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final user = authProvider.currentAppUser;
                return Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: NatureColors.lightGreen,
                      child: Text(
                        user?.name.isNotEmpty == true 
                            ? user!.name[0].toUpperCase() 
                            : 'A',
                        style: const TextStyle(
                          color: NatureColors.pureWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Admin',
                            style: const TextStyle(
                              color: NatureColors.pureWhite,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Text(
                            'Administrator',
                            style: TextStyle(
                              color: NatureColors.offWhite,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 60, // Reduced from 70 for mobile
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            NatureColors.primaryGreen,
            NatureColors.lightGreen,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: NatureColors.darkGray.withAlpha((0.1 * 255).round()),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Hamburger Menu Button
          IconButton(
            onPressed: () {
              setState(() {
                _isSidebarExpanded = !_isSidebarExpanded;
              });
            },
            icon: const Icon(
              Icons.menu,
              color: NatureColors.pureWhite,
              size: 24, // Reduced from 28 for mobile
            ),
            tooltip: _isSidebarExpanded ? 'Collapse Menu' : 'Expand Menu',
            padding: const EdgeInsets.all(8), // Added padding for better touch target
          ),
          const SizedBox(width: 8),
          // Page Title
          Expanded(
            child: Text(
              _menuItems[_selectedIndex].title,
              style: const TextStyle(
                fontSize: 18, // Reduced from 24 for mobile
                fontWeight: FontWeight.bold,
                color: NatureColors.pureWhite,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          // Actions
          Row(
            children: [
              // Notifications
              IconButton(
                onPressed: () {
                  
                },
                icon: Stack(
                  children: [
                    const Icon(
                      Icons.notifications_outlined,
                      color: NatureColors.pureWhite, // Changed from darkGray for better visibility
                      size: 24, // Reduced from 28 for mobile
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8), // Added padding for better touch target
              ),
              const SizedBox(width: 8),
              // Profile Menu
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'settings':
                      _showSettingsDialog(context);
                      break;
                    case 'logout':
                      _showLogoutDialog(context);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings_outlined),
                        SizedBox(width: 8),
                        Text('Settings'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Logout', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: Row(
                    children: [
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          final user = authProvider.currentAppUser;
                          return CircleAvatar(
                            backgroundColor: NatureColors.lightGreen,
                            child: Text(
                              user?.name.isNotEmpty == true 
                                  ? user!.name[0].toUpperCase() 
                                  : 'A',
                              style: const TextStyle(
                                color: NatureColors.pureWhite,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: NatureColors.darkGray,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.settings, color: NatureColors.primaryGreen),
            SizedBox(width: 8),
            Text('Settings'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: Icon(Icons.notifications_outlined),
              title: Text('Notifications'),
              subtitle: Text('Manage notification preferences'),
            ),
            ListTile(
              leading: Icon(Icons.palette_outlined),
              title: Text('Theme'),
              subtitle: Text('Change app appearance'),
            ),
            ListTile(
              leading: Icon(Icons.language_outlined),
              title: Text('Language'),
              subtitle: Text('Select your preferred language'),
            ),
            ListTile(
              leading: Icon(Icons.admin_panel_settings_outlined),
              title: Text('Admin Settings'),
              subtitle: Text('Configure admin-specific settings'),
            ),
            ListTile(
              leading: Icon(Icons.help_outline),
              title: Text('Help & Support'),
              subtitle: Text('Get help and contact support'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('Logout'),
          ],
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().signOut();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class AdminMenuItem {
  final IconData icon;
  final String title;
  final Widget page;

  AdminMenuItem({
    required this.icon,
    required this.title,
    required this.page,
  });
}