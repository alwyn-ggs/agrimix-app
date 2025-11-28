import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../router.dart';
import '../../theme/theme.dart';
import '../common/validators.dart';
import '../common/widgets/app_error.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    // Listen for successful login
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      auth.addListener(_handleAuthChange);
    });
  }

  @override
  void dispose() {
    context.read<AuthProvider>().removeListener(_handleAuthChange);
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _handleAuthChange() {
    if (!mounted || _hasNavigated) return;

    final auth = context.read<AuthProvider>();
    if (!auth.loading && auth.isLoggedIn && auth.currentAppUser != null) {
      _hasNavigated = true;
      final role = auth.userRole;
      final targetRoute = role == 'admin' ? Routes.adminDashboard : Routes.farmerDashboard;
      Navigator.of(context).pushNamedAndRemoveUntil(targetRoute, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
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
              padding: const EdgeInsets.all(16),
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
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Logo/Title Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: NatureColors.primaryGreen,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Column(
                              children: [
                                Icon(
                                  Icons.eco,
                                  size: 48,
                                  color: NatureColors.pureWhite,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'AgriMix',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: NatureColors.pureWhite,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Organic Fertilizer Assistant',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: NatureColors.offWhite,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Email Field
                          TextFormField(
                            controller: _email,
                            style: const TextStyle(
                              color: NatureColors.textDark,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: const Icon(
                                Icons.email_outlined,
                                color: NatureColors.textDark,
                              ),
                              filled: true,
                              fillColor: NatureColors.offWhite.withAlpha((0.8 * 255).round()),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: NatureColors.lightGreen.withAlpha((0.3 * 255).round()),
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: NatureColors.lightGreen.withAlpha((0.3 * 255).round()),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: NatureColors.primaryGreen,
                                  width: 2,
                                ),
                              ),
                              labelStyle: const TextStyle(
                                color: NatureColors.darkGray,
                              ),
                            ),
                            validator: Validators.email,
                          ),
                          const SizedBox(height: 16),
                          
                          // Password Field
                          TextFormField(
                            controller: _password,
                            style: const TextStyle(
                              color: NatureColors.textDark,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(
                                Icons.lock_outlined,
                                color: NatureColors.textDark,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: NatureColors.textDark,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: NatureColors.offWhite.withAlpha((0.8 * 255).round()),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: NatureColors.lightGreen.withAlpha((0.3 * 255).round()),
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: NatureColors.lightGreen.withAlpha((0.3 * 255).round()),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: NatureColors.primaryGreen,
                                  width: 2,
                                ),
                              ),
                              labelStyle: const TextStyle(
                                color: NatureColors.darkGray,
                              ),
                            ),
                            obscureText: _obscurePassword,
                            validator: Validators.notEmpty,
                          ),
                          const SizedBox(height: 12),

                          // Remember me
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (v) => setState(() => _rememberMe = v ?? false),
                                side: const BorderSide(color: Colors.black, width: 2),
                                fillColor: const WidgetStatePropertyAll(Colors.transparent),
                                checkColor: Colors.black,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              const Text(
                                'Remember me',
                                style: TextStyle(color: NatureColors.textDark),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Login Button
                          FilledButton(
                            onPressed: auth.loading
                                ? null
                                : () async {
                                    if (!_formKey.currentState!.validate()) return;
                                  await context
                                      .read<AuthProvider>()
                                      .signIn(
                                        _email.text.trim(),
                                        _password.text.trim(),
                                        rememberMe: _rememberMe,
                                      );
                                    // Navigation will be handled by the router based on user role
                                  },
                            style: FilledButton.styleFrom(
                              backgroundColor: NatureColors.primaryGreen,
                              foregroundColor: NatureColors.pureWhite,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: auth.loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(NatureColors.pureWhite),
                                    ),
                                  )
                                : const Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 16),

                          // Google Sign-in
                          OutlinedButton.icon(
                            onPressed: auth.loading
                                ? null
                                : () async {
                                    await context.read<AuthProvider>().signInWithGoogle();
                                  },
                            icon: const Icon(Icons.g_mobiledata, color: NatureColors.darkGray),
                            label: const Text(
                              'Continue with Google',
                              style: TextStyle(color: NatureColors.darkGray),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: NatureColors.lightGreen.withAlpha((0.4 * 255).round())),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pushNamed(context, Routes.register),
                                  style: TextButton.styleFrom(
                                    foregroundColor: NatureColors.primaryGreen,
                                  ),
                                  child: const Text('Create Account', style: TextStyle(fontSize: 12)),
                                ),
                              ),
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pushNamed(context, Routes.forgot),
                                  style: TextButton.styleFrom(
                                    foregroundColor: NatureColors.darkGray,
                                  ),
                                  child: const Text('Forgot Password?', style: TextStyle(fontSize: 12)),
                                ),
                              ),
                            ],
                          ),
                          
                          // Error Message (wraps safely on small screens)
                          if (auth.error != null) ...[
                            const SizedBox(height: 16),
                            AppErrorInline(
                              message: auth.error!,
                              padding: const EdgeInsets.all(0),
                            ),
                            const SizedBox(height: 12),
                          ],
                          // Footer links removed from Login; shown in Register flow
                        ],
                      ),
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