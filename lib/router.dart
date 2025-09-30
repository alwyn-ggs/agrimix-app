import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ui/admin/dashboard.dart' as admin;
import 'ui/admin/ingredient_management_screen.dart';
import 'ui/farmer/dashboard.dart' as farmer;
import 'ui/auth/login_screen.dart';
import 'ui/auth/register_screen.dart';
import 'ui/auth/forgot_password_screen.dart';
import 'ui/common/splash_screen.dart';
import 'ui/recipe/list_page.dart';
import 'ui/recipe/detail_page.dart';
import 'ui/recipe/edit_page.dart';
import 'ui/recipe/formulate_recipe_flow.dart';
import 'ui/community/post_list_page.dart';
import 'ui/community/post_detail_page.dart';
import 'ui/community/new_post_page.dart';
import 'ui/fermentation/new_log_page.dart';
import 'ui/fermentation/log_detail_page.dart';
import 'ui/common/onboarding_screen.dart';
import 'ui/common/legal/terms_page.dart';
import 'ui/common/legal/privacy_page.dart';
import 'ui/common/help/help_page.dart';
import 'providers/auth_provider.dart';
import 'models/post.dart';
import 'theme/theme.dart';

class Routes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const forgot = '/forgot';
  static const farmerDashboard = '/farmer';
  static const adminDashboard = '/admin';
  static const recipes = '/recipes';
  static const recipeDetail = '/recipe-detail';
  static const recipeEdit = '/recipe-edit';
  static const formulateRecipe = '/formulate-recipe';
  static const posts = '/posts';
  static const postDetail = '/post-detail';
  static const newPost = '/new-post';
  static const newLog = '/new-log';
  static const logDetail = '/log-detail';
  static const ingredientManagement = '/ingredient-management';
  static const terms = '/terms';
  static const privacy = '/privacy';
  static const help = '/help';
  static const onboarding = '/onboarding';
}

class AppRouter {
  static const initialRoute = Routes.splash;

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case Routes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case Routes.register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case Routes.forgot:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      case Routes.farmerDashboard:
        return _guardedRoute(
          builder: (_) => const farmer.Dashboard(),
          requiredRole: 'farmer',
          settings: settings,
        );
      case Routes.adminDashboard:
        return _guardedRoute(
          builder: (_) => const admin.Dashboard(),
          requiredRole: 'admin',
          settings: settings,
        );
      case Routes.recipes:
        return _guardedRoute(
          builder: (_) => const RecipeListPage(),
          requireAuth: true,
          settings: settings,
        );
      case Routes.recipeDetail:
        return _guardedRoute(
          builder: (_) => const RecipeDetailPage(),
          requireAuth: true,
          settings: settings,
        );
      case Routes.recipeEdit:
        return _guardedRoute(
          builder: (_) => const RecipeEditPage(),
          requireAuth: true,
          settings: settings,
        );
      case Routes.formulateRecipe:
        return _guardedRoute(
          builder: (_) => const FormulateRecipeFlow(),
          requireAuth: true,
          settings: settings,
        );
      case Routes.posts:
        return _guardedRoute(
          builder: (_) => const PostListPage(),
          requireAuth: true,
          settings: settings,
        );
      case Routes.postDetail:
        return _guardedRoute(
          builder: (context) {
            final args = settings.arguments as Map<String, dynamic>?;
            final post = args?['post'] as Post?;
            if (post == null) {
              return const Scaffold(
                body: Center(child: Text('Post not found')),
              );
            }
            return PostDetailPage(post: post);
          },
          requireAuth: true,
          settings: settings,
        );
      case Routes.newPost:
        return _guardedRoute(
          builder: (_) => const NewPostPage(),
          requireAuth: true,
          settings: settings,
        );
      case Routes.newLog:
        return _guardedRoute(
          builder: (_) => const NewLogPage(),
          requireAuth: true,
          settings: settings,
        );
      case Routes.logDetail:
        return _guardedRoute(
          builder: (_) => const LogDetailPage(),
          requireAuth: true,
          settings: settings,
        );
      case Routes.ingredientManagement:
        return _guardedRoute(
          builder: (_) => const IngredientManagementScreen(),
          requiredRole: 'admin',
          settings: settings,
        );
      case Routes.onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case Routes.terms:
        return MaterialPageRoute(builder: (_) => const TermsPage());
      case Routes.privacy:
        return MaterialPageRoute(builder: (_) => const PrivacyPage());
      case Routes.help:
        return MaterialPageRoute(builder: (_) => const HelpPage());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Page not found')),
          ),
        );
    }
  }

  static Route<dynamic> _guardedRoute({
    required Widget Function(BuildContext) builder,
    String? requiredRole,
    bool requireAuth = false,
    RouteSettings? settings,
  }) {
    return MaterialPageRoute(
      settings: settings,
      builder: (context) {
        final authProvider = context.watch<AuthProvider>();
        
        // Show splash while loading
        if (authProvider.loading) {
          return const SplashScreen();
        }
        
        // Check if user is logged in
        if (!authProvider.isLoggedIn) {
          return const LoginScreen();
        }
        
        // Check if user has required role
        if (requiredRole != null && authProvider.userRole != requiredRole) {
          // Redirect to appropriate dashboard based on user role
          if (authProvider.userRole == 'admin') {
            return const admin.Dashboard();
          } else {
            return const farmer.Dashboard();
          }
        }
        
        // Check if user is approved (for farmers)
        if (authProvider.userRole == 'farmer' && 
            authProvider.currentAppUser?.approved != true) {
          return const _PendingApprovalScreen();
        }
        
        return builder(context);
      },
    );
  }
}

class _PendingApprovalScreen extends StatelessWidget {
  const _PendingApprovalScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NatureColors.natureBackground,
      body: Container(
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
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        NatureColors.pureWhite,
                        NatureColors.lightGray,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: NatureColors.lightGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.pending_actions,
                          size: 64,
                          color: NatureColors.pureWhite,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Title
                      const Text(
                        'Account Pending Approval',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: NatureColors.darkGreen,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      
                      // Description
                      const Text(
                        'Your account is currently under review. You will be notified once it has been approved by an administrator.',
                        style: TextStyle(
                          fontSize: 16,
                          color: NatureColors.darkGray,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      
                      // Sign Out Button
                      FilledButton(
                        onPressed: () => context.read<AuthProvider>().signOut(),
                        style: FilledButton.styleFrom(
                          backgroundColor: NatureColors.primaryGreen,
                          foregroundColor: NatureColors.pureWhite,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Sign Out',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}