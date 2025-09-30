import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/theme.dart';
import '../../providers/auth_provider.dart';
import '../common/notifications_page.dart';
import 'tabs/home_tab.dart';
import 'tabs/recipes_tab.dart';
import 'tabs/fermentation_tab.dart';
import 'tabs/community_tab.dart';
import 'tabs/my_recipes_tab.dart';
import 'tabs/profile_tab.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    context.watch<AuthProvider>();
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Persist session by default; do not sign out on back navigation
        }
      },
      child: Scaffold(
      backgroundColor: NatureColors.natureBackground,
      body: SafeArea(
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
              child: _buildCurrentTab(),
            ),
          ),
          // Bottom Navigation
          _buildBottomNavigation(),
        ],
        ),
      ),
    ));
  }

  Widget _buildCurrentTab() {
    switch (_index) {
      case 0:
        return HomeTab(
          onTapBrowseRecipes: () => setState(() => _index = 1),
        );
      case 1:
        return const RecipesTab();
      case 2:
        return const FermentationTab();
      case 3:
        return const CommunityTab();
      case 4:
        return const MyRecipesTab();
      case 5:
        return const ProfileTab();
      default:
        return const HomeTab();
    }
  }

  Widget _buildTopBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: NatureColors.primaryGreen,
        boxShadow: [
          BoxShadow(
            color: NatureColors.textDark.withAlpha((0.1 * 255).round()),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo and Title
          const Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(
                    Icons.eco,
                    color: NatureColors.pureWhite,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'AgriMix',
                    style: TextStyle(
                      color: NatureColors.pureWhite,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Actions
          Row(
            children: [
              // Notifications
              Builder(
                builder: (context) {
                  final userId = context.watch<AuthProvider>().currentUser?.uid;
                  return IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsPage()),
                      );
                    },
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(
                          Icons.notifications_outlined,
                          color: NatureColors.pureWhite,
                          size: 28,
                        ),
                        if (userId != null)
                          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(userId)
                                .collection('notifications')
                                .where('read', isEqualTo: false)
                                .snapshots(),
                            builder: (context, snapshot) {
                              final count = snapshot.data?.docs.length ?? 0;
                              if (count <= 0) return const SizedBox.shrink();
                              return Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  constraints: const BoxConstraints(minWidth: 18, minHeight: 16),
                                  child: Text(
                                    count > 99 ? '99+' : '$count',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              // Profile Menu
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'profile':
                      setState(() => _index = 5); // Go to Profile tab
                      break;
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
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person_outline),
                        SizedBox(width: 8),
                        Text('Profile'),
                      ],
                    ),
                  ),
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
                                  : 'F',
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
                        color: NatureColors.pureWhite,
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

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: NatureColors.pureWhite,
        boxShadow: [
          BoxShadow(
            color: NatureColors.textDark.withAlpha((0.1 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: NatureColors.pureWhite,
        indicatorColor: NatureColors.lightGreen,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        destinations: const [
          NavigationDestination(
            icon: Tooltip(
              message: 'Home',
              child: Icon(Icons.home_outlined, color: NatureColors.mediumGray),
            ),
            selectedIcon: Tooltip(
              message: 'Home',
              child: Icon(Icons.home, color: NatureColors.pureWhite),
            ),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Tooltip(
              message: 'Recipes',
              child: Icon(Icons.restaurant_menu_outlined, color: NatureColors.mediumGray),
            ),
            selectedIcon: Tooltip(
              message: 'Recipes',
              child: Icon(Icons.restaurant_menu, color: NatureColors.pureWhite),
            ),
            label: 'Recipes',
          ),
          NavigationDestination(
            icon: Tooltip(
              message: 'Ferment',
              child: Icon(Icons.bubble_chart_outlined, color: NatureColors.mediumGray),
            ),
            selectedIcon: Tooltip(
              message: 'Ferment',
              child: Icon(Icons.bubble_chart, color: NatureColors.pureWhite),
            ),
            label: 'Ferment',
          ),
          NavigationDestination(
            icon: Tooltip(
              message: 'Community',
              child: Icon(Icons.groups_outlined, color: NatureColors.mediumGray),
            ),
            selectedIcon: Tooltip(
              message: 'Community',
              child: Icon(Icons.groups, color: NatureColors.pureWhite),
            ),
            label: 'Community',
          ),
          NavigationDestination(
            icon: Tooltip(
              message: 'My Recipes',
              child: Icon(Icons.person_pin_outlined, color: NatureColors.mediumGray),
            ),
            selectedIcon: Tooltip(
              message: 'My Recipes',
              child: Icon(Icons.person_pin, color: NatureColors.pureWhite),
            ),
            label: 'My Recipes',
          ),
          NavigationDestination(
            icon: Tooltip(
              message: 'Profile',
              child: Icon(Icons.person_outline, color: NatureColors.mediumGray),
            ),
            selectedIcon: Tooltip(
              message: 'Profile',
              child: Icon(Icons.person, color: NatureColors.pureWhite),
            ),
            label: 'Profile',
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ListTile(
              leading: Icon(Icons.notifications_outlined),
              title: Text('Notifications'),
              subtitle: Text('Manage notification preferences'),
            ),
            const ListTile(
              leading: Icon(Icons.palette_outlined),
              title: Text('Theme'),
              subtitle: Text('Change app appearance'),
            ),
            const ListTile(
              leading: Icon(Icons.language_outlined),
              title: Text('Language'),
              subtitle: Text('Select your preferred language'),
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help & Support'),
              subtitle: const Text('Get help and contact support'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/help');
              },
            ),
            ListTile(
              leading: const Icon(Icons.article_outlined),
              title: const Text('Terms of Service'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/terms');
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy Policy'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/privacy');
              },
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