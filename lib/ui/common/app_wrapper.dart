import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../router.dart';
import '../../theme/theme.dart';
import '../../services/fcm_message_handler.dart';
import 'splash_screen.dart';
import '../auth/login_screen.dart';
import '../admin/dashboard.dart' as admin;
import '../farmer/dashboard.dart' as farmer;

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  bool _hasTimedOut = false;

  @override
  void initState() {
    super.initState();
    // Set a timeout to prevent infinite loading
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted) {
        setState(() {
          _hasTimedOut = true;
        });
      }
    });
    
    // Initialize FCM message handler
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fcmHandler = context.read<FCMMessageHandler>();
      fcmHandler.handleForegroundMessage(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // If loading takes too long, only show timeout when a logged-in user is
        // either awaiting user doc creation or not yet approved. Do NOT show for
        // anonymous/unauthenticated loading or already approved users.
        if (_hasTimedOut && authProvider.loading) {
          final isLoggedIn = authProvider.isLoggedIn;
          final appUser = authProvider.currentAppUser;
          final isAwaitingProfile = appUser == null; // user doc not yet created/fetched
          final isNotApproved = appUser != null && appUser.approved != true;

          if (isLoggedIn && (isAwaitingProfile || isNotApproved)) {
            return const _PendingUserSetupScreen();
          }
          // Otherwise, keep showing splash without surfacing timeout
        }
        
        // Show splash while loading
        if (authProvider.loading) {
          return const SplashScreen();
        }
        
        // If not logged in, show login screen
        if (!authProvider.isLoggedIn) {
          return const LoginScreen();
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
    );
  }

  Widget _buildTimeoutError(BuildContext context) {
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
            padding: const EdgeInsets.all(16), // Reduced from 24 for mobile
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
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.timer_off,
                          size: 64,
                          color: NatureColors.pureWhite,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Title
                      const Text(
                        'Loading Timeout',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: NatureColors.textDark,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      
                      // Description
                      const Text(
                        'The app is taking longer than expected to load. This might be due to network issues or server problems.',
                        style: TextStyle(
                          fontSize: 16,
                          color: NatureColors.textDark,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      
                      // Retry Button
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            _hasTimedOut = false;
                          });
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: NatureColors.primaryGreen,
                          foregroundColor: NatureColors.pureWhite,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Retry',
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
                        child: Icon(
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
                          color: NatureColors.textDark,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      
                      // Description
                      const Text(
                        'Your account is currently under review. You will be notified once it has been approved by an administrator.',
                        style: TextStyle(
                          fontSize: 16,
                          color: NatureColors.textDark,
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

class _PendingUserSetupScreen extends StatelessWidget {
  const _PendingUserSetupScreen();

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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16), // Reduced from 24 for mobile
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
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.hourglass_bottom,
                            size: 64,
                            color: NatureColors.pureWhite,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Setting up your account...',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: NatureColors.textDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'We are finalizing your profile. If this takes too long, try again.',
                          style: TextStyle(
                            fontSize: 16,
                            color: NatureColors.textDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FilledButton(
                              onPressed: () => context.read<AuthProvider>().signOut(),
                              style: FilledButton.styleFrom(
                                backgroundColor: NatureColors.primaryGreen,
                                foregroundColor: NatureColors.pureWhite,
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Sign Out'),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: () {
                                // Retry by resetting timeout and triggering a rebuild
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(builder: (_) => const AppWrapper()),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: NatureColors.primaryGreen,
                                side: const BorderSide(color: NatureColors.primaryGreen),
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Retry'),
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
      ),
    );
  }
}
