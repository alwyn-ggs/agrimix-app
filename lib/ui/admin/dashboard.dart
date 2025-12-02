import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import 'users_page.dart';
import 'recipes_page.dart';
import 'ingredients_page.dart';
import 'community_moderation_page.dart';
import 'fermentation_monitor_page.dart';
import 'announcements_page.dart';
import '../common/notifications_page.dart';
import 'admin_notification_settings_page.dart';
import '../../l10n/app_localizations.dart';


class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;
  bool _isSidebarExpanded = false;

  List<AdminMenuItem> _getMenuItems(BuildContext context) {
    return [
      AdminMenuItem(
        icon: Icons.people_outline,
        titleKey: 'users',
        page: const UsersPage(),
      ),
      AdminMenuItem(
        icon: Icons.restaurant_menu_outlined,
        titleKey: 'recipes',
        page: const RecipesPage(),
      ),
      AdminMenuItem(
        icon: Icons.inventory_outlined,
        titleKey: 'ingredients',
        page: const IngredientsPage(),
      ),
      AdminMenuItem(
        icon: Icons.groups_outlined,
        titleKey: 'community',
        page: const CommunityModerationPage(initialTabIndex: 0),
      ),
      AdminMenuItem(
        icon: Icons.bubble_chart_outlined,
        titleKey: 'ferment',
        page: const FermentationMonitorPage(),
      ),
      AdminMenuItem(
        icon: Icons.campaign_outlined,
        titleKey: 'announcements',
        page: const AnnouncementsPage(),
      ),
    ];
  }

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                      child: _getMenuItems(context)[_selectedIndex].page,
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
    ));
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
            child: Row(
              children: [
                const Icon(
                  Icons.admin_panel_settings,
                  color: NatureColors.pureWhite,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).t('admin_panel'),
                    style: const TextStyle(
                      color: NatureColors.pureWhite,
                      fontSize: 16,
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
              itemCount: _getMenuItems(context).length,
              itemBuilder: (context, index) {
                final item = _getMenuItems(context)[index];
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
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                AppLocalizations.of(context).t(item.titleKey),
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
                          Text(
                            AppLocalizations.of(context).t('administrator'),
                            style: const TextStyle(
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
            tooltip: _isSidebarExpanded ? AppLocalizations.of(context).t('collapse_menu') : AppLocalizations.of(context).t('expand_menu'),
            padding: const EdgeInsets.all(8), // Added padding for better touch target
          ),
          const SizedBox(width: 8),
          // Page Title
          Expanded(
            child: Text(
              AppLocalizations.of(context).t(_getMenuItems(context)[_selectedIndex].titleKey),
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
              Builder(
                builder: (context) {
                  final auth = context.watch<AuthProvider>();
                  final userId = auth.currentUser?.uid;
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
                          size: 24,
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
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
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
                    padding: const EdgeInsets.all(8),
                  );
                },
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
        title: Row(
          children: [
            const Icon(Icons.settings, color: NatureColors.primaryGreen),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context).t('settings')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: Text(AppLocalizations.of(context).t('notifications')),
              subtitle: Text(AppLocalizations.of(context).t('notifications_sub')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminNotificationSettingsPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: Text(AppLocalizations.of(context).t('theme')),
              subtitle: Text(AppLocalizations.of(context).t('theme_sub')),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings/theme');
              },
            ),
            ListTile(
              leading: const Icon(Icons.language_outlined),
              title: Text(AppLocalizations.of(context).t('language')),
              subtitle: Text(AppLocalizations.of(context).t('language_sub')),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings/language');
              },
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: Text(AppLocalizations.of(context).t('admin_settings')),
              subtitle: Text(AppLocalizations.of(context).t('admin_settings_sub')),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings/admin');
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: Text(AppLocalizations.of(context).t('help_support')),
              subtitle: Text(AppLocalizations.of(context).t('help_support_sub')),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/help');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).t('close')),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.logout, color: Colors.red),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context).t('logout')),
          ],
        ),
        content: Text(AppLocalizations.of(context).t('logout_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).t('cancel')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().signOut();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizations.of(context).t('logout')),
          ),
        ],
      ),
    );
  }
}

class AdminMenuItem {
  final IconData icon;
  final String titleKey;
  final Widget page;

  AdminMenuItem({
    required this.icon,
    required this.titleKey,
    required this.page,
  });
}