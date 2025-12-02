import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/theme.dart';
import '../../providers/auth_provider.dart';
import '../common/notifications_page.dart';
import '../../l10n/app_localizations.dart';
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
  int? _myRecipesTabIndex;

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
          onTapMyDrafts: () => setState(() {
            _index = 4;
            _myRecipesTabIndex = 0; // Drafts tab
          }),
          onTapFavorites: () => setState(() {
            _index = 4;
            _myRecipesTabIndex = 1; // Favorites tab
          }),
        );
      case 1:
        return const RecipesTab();
      case 2:
        return const FermentationTab();
      case 3:
        return const CommunityTab();
      case 4:
        final tab = MyRecipesTab(initialTabIndex: _myRecipesTabIndex);
        // Reset the tab index after creating the widget
        _myRecipesTabIndex = null;
        return tab;
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
              // Profile Avatar - tap to go to profile
              GestureDetector(
                onTap: () => setState(() => _index = 5), // Go to Profile tab
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: Consumer<AuthProvider>(
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
        destinations: [
          NavigationDestination(
            icon: Tooltip(
              message: AppLocalizations.of(context).t('home'),
              child: const Icon(Icons.eco_outlined, color: NatureColors.mediumGray),
            ),
            selectedIcon: Tooltip(
              message: AppLocalizations.of(context).t('home'),
              child: const Icon(Icons.eco, color: NatureColors.pureWhite),
            ),
            label: AppLocalizations.of(context).t('home'),
          ),
          NavigationDestination(
            icon: Tooltip(
              message: AppLocalizations.of(context).t('recipes'),
              child: const Icon(Icons.menu_book_outlined, color: NatureColors.mediumGray),
            ),
            selectedIcon: Tooltip(
              message: AppLocalizations.of(context).t('recipes'),
              child: const Icon(Icons.menu_book, color: NatureColors.pureWhite),
            ),
            label: AppLocalizations.of(context).t('recipes'),
          ),
          NavigationDestination(
            icon: Tooltip(
              message: AppLocalizations.of(context).t('ferment'),
              child: const Icon(Icons.science_outlined, color: NatureColors.mediumGray),
            ),
            selectedIcon: Tooltip(
              message: AppLocalizations.of(context).t('ferment'),
              child: const Icon(Icons.science, color: NatureColors.pureWhite),
            ),
            label: AppLocalizations.of(context).t('ferment'),
          ),
          NavigationDestination(
            icon: Tooltip(
              message: AppLocalizations.of(context).t('community'),
              child: const Icon(Icons.forum_outlined, color: NatureColors.mediumGray),
            ),
            selectedIcon: Tooltip(
              message: AppLocalizations.of(context).t('community'),
              child: const Icon(Icons.forum, color: NatureColors.pureWhite),
            ),
            label: AppLocalizations.of(context).t('community'),
          ),
          NavigationDestination(
            icon: Tooltip(
              message: AppLocalizations.of(context).t('my_recipes'),
              child: const Icon(Icons.library_books_outlined, color: NatureColors.mediumGray),
            ),
            selectedIcon: Tooltip(
              message: AppLocalizations.of(context).t('my_recipes'),
              child: const Icon(Icons.library_books, color: NatureColors.pureWhite),
            ),
            label: AppLocalizations.of(context).t('my_recipes'),
          ),
          NavigationDestination(
            icon: Tooltip(
              message: AppLocalizations.of(context).t('profile'),
              child: const Icon(Icons.person_outline, color: NatureColors.mediumGray),
            ),
            selectedIcon: Tooltip(
              message: AppLocalizations.of(context).t('profile'),
              child: const Icon(Icons.person, color: NatureColors.pureWhite),
            ),
            label: AppLocalizations.of(context).t('profile'),
          ),
        ],
      ),
    );
  }


}