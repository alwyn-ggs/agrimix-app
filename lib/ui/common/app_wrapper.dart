import 'dart:async';
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
import '../../utils/logger.dart';

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
          
          // Show splash while loading with reasonable timeout for fresh install
          if (authProvider.loading) {
            return FutureBuilder(
              future: Future.delayed(const Duration(seconds: 15)), // Reasonable timeout for fresh install
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  // If still loading after timeout, show emergency screen
                  return _EmergencyLoginScreen(authProvider: authProvider);
                }
                return const SplashScreen();
              },
            );
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
          
          // If logged in but user data is not loaded yet, show splash with timeout
          if (authProvider.currentAppUser == null) {
            return FutureBuilder(
              future: Future.delayed(const Duration(seconds: 10)), // Reasonable timeout for user data
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  // Force user data refresh or show emergency screen
                  return _EmergencyUserDataScreen(authProvider: authProvider);
                }
                return const SplashScreen();
              },
            );
          }
          
          // Route based on user role
          final userRole = authProvider.userRole;
          final isApproved = authProvider.currentAppUser?.approved;
          
          AppLogger.debug('AppWrapper: User role: $userRole, approved: $isApproved');
          
          
          if (userRole == 'admin') {
            AppLogger.debug('AppWrapper: Routing to admin dashboard');
            return const admin.Dashboard();
          } else if (userRole == 'farmer') {
            // Check if farmer is approved
            if (isApproved == true) {
              AppLogger.debug('AppWrapper: Routing to farmer dashboard (approved)');
              return const farmer.Dashboard();
            } else {
              AppLogger.debug('AppWrapper: Routing to pending approval screen (not approved)');
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
                      
                      // Refresh and Sign Out Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Refresh Button
                          OutlinedButton.icon(
                            onPressed: () async {
                              final authProvider = context.read<AuthProvider>();
                              await authProvider.refreshCurrentUser();
                              
                              // If there's an error (like session expired), show it
                              if (authProvider.hasError) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(authProvider.error ?? 'Failed to refresh'),
                                      backgroundColor: Colors.red,
                                      action: SnackBarAction(
                                        label: 'Login',
                                        textColor: Colors.white,
                                        onPressed: () {
                                          authProvider.signOut();
                                        },
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Refresh'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: NatureColors.primaryGreen,
                              side: const BorderSide(color: NatureColors.primaryGreen),
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          // Sign Out Button
                          FilledButton.icon(
                            onPressed: () => context.read<AuthProvider>().signOut(),
                            icon: const Icon(Icons.logout, size: 18),
                            label: const Text('Sign Out'),
                            style: FilledButton.styleFrom(
                              backgroundColor: NatureColors.primaryGreen,
                              foregroundColor: NatureColors.pureWhite,
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Help text
                      Text(
                        'If you have been approved, tap "Refresh" to update your status.',
                        style: TextStyle(
                          fontSize: 14,
                          color: NatureColors.mediumGray,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
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

/// Emergency login screen for when normal loading fails
class _EmergencyLoginScreen extends StatelessWidget {
  final AuthProvider authProvider;
  
  const _EmergencyLoginScreen({required this.authProvider});

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
                          color: NatureColors.primaryGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.refresh,
                          size: 64,
                          color: NatureColors.pureWhite,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Title
                      const Text(
                        'Login Taking Too Long',
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
                        'The app is taking longer than usual to load. This is common on fresh installs. Let\'s try to fix this.',
                        style: TextStyle(
                          fontSize: 16,
                          color: NatureColors.darkGray,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      
                      // Action Buttons
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () {
                                authProvider.resetAuthState();
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: NatureColors.primaryGreen,
                                foregroundColor: NatureColors.pureWhite,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Try Again',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                authProvider.signOut();
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: NatureColors.primaryGreen,
                                side: const BorderSide(color: NatureColors.primaryGreen),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Sign Out & Start Over',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
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

/// Emergency user data screen for when user data loading fails
class _EmergencyUserDataScreen extends StatelessWidget {
  final AuthProvider authProvider;
  
  const _EmergencyUserDataScreen({required this.authProvider});

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
                          Icons.account_circle_outlined,
                          size: 64,
                          color: NatureColors.pureWhite,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Title
                      const Text(
                        'Setting Up Your Account',
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
                        'We\'re having trouble loading your account data. This is common on fresh installs. Let\'s try to refresh your account.',
                        style: TextStyle(
                          fontSize: 16,
                          color: NatureColors.darkGray,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      
                      // Action Buttons
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () {
                                authProvider.refreshCurrentUser();
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: NatureColors.primaryGreen,
                                foregroundColor: NatureColors.pureWhite,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Refresh Account',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                authProvider.signOut();
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: NatureColors.primaryGreen,
                                side: const BorderSide(color: NatureColors.primaryGreen),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Sign Out & Try Again',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
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
