import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/theme.dart';
import 'splash_screen.dart';
import 'widgets/app_error.dart';
import 'widgets/error_boundary.dart';
import '../auth/login_screen.dart';
import '../admin/dashboard.dart' as admin;
import '../farmer/dashboard.dart' as farmer;
import 'package:shared_preferences/shared_preferences.dart';
import '../../router.dart';

class AppWrapper extends StatelessWidget {
  const AppWrapper({super.key});

  Future<bool> _hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('seen_onboarding') == true;
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          // Show error if there's an authentication error
          if (authProvider.hasError) {
            return AppErrorPage(
              title: 'Authentication Error',
              message: authProvider.error ?? 'An authentication error occurred',
              onRetry: () {
                authProvider.clearError();
                // Try to refresh the current user
                authProvider.refreshCurrentUser();
              },
            );
          }
          
          // Show splash while loading
          if (authProvider.loading) {
            return const SplashScreen();
          }
          
          // If not logged in, show onboarding once then login
          if (!authProvider.isLoggedIn) {
            return FutureBuilder<bool>(
              future: _hasSeenOnboarding(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SplashScreen();
                final seen = snapshot.data == true;
                if (seen) return const LoginScreen();
                // Navigate to onboarding and show splash meanwhile
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.of(context).pushReplacementNamed(Routes.onboarding);
                });
                return const SplashScreen();
              },
            );
          }
          
          // If logged in but user data is not loaded yet, show splash
          if (authProvider.currentAppUser == null) {
            return const SplashScreen();
          }
          
          // Route based on user role
          final userRole = authProvider.userRole;
          
          if (userRole == 'admin') {
            return const admin.Dashboard();
          } else if (userRole == 'farmer') {
            // Check if farmer is approved
            if (authProvider.currentAppUser?.approved == true) {
              return const farmer.Dashboard();
            } else {
              return const _PendingApprovalScreen();
            }
          }
          
          // Fallback to splash if role is unknown
          return const SplashScreen();
        },
      ),
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
