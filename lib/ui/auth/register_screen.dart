import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/theme.dart';
import '../common/validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _membershipId = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: NatureColors.natureBackground,
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: NatureColors.primaryGreen,
        foregroundColor: NatureColors.pureWhite,
        elevation: 0,
      ),
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header Section
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: NatureColors.lightGreen,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Column(
                              children: [
                                Icon(
                                  Icons.person_add,
                                  size: 48,
                                  color: NatureColors.pureWhite,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Join AgriMix',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: NatureColors.pureWhite,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Start your nature-inspired journey',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: NatureColors.offWhite,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Name Field
                          TextFormField(
                            controller: _name,
                            style: const TextStyle(
                              color: NatureColors.pureBlack,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: const Icon(
                                Icons.person_outlined,
                                color: NatureColors.pureBlack,
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
                            validator: Validators.notEmpty,
                          ),
                          const SizedBox(height: 16),
                          
                          // Email Field
                          TextFormField(
                            controller: _email,
                            style: const TextStyle(
                              color: NatureColors.pureBlack,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: const Icon(
                                Icons.email_outlined,
                                color: NatureColors.pureBlack,
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
                              color: NatureColors.pureBlack,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(
                                Icons.lock_outlined,
                                color: NatureColors.pureBlack,
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
                            obscureText: true,
                            validator: (v) => Validators.minLength(v, 6, label: 'Password'),
                          ),
                          const SizedBox(height: 16),

                          // Confirm Password
                          TextFormField(
                            controller: _confirmPassword,
                            style: const TextStyle(
                              color: NatureColors.pureBlack,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: NatureColors.pureBlack,
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
                            obscureText: true,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Confirm Password is required';
                              if (v != _password.text) return 'Passwords do not match';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Membership ID Field (Optional)
                          TextFormField(
                            controller: _membershipId,
                            style: const TextStyle(
                              color: NatureColors.pureBlack,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Membership ID (Optional)',
                              prefixIcon: const Icon(
                                Icons.card_membership_outlined,
                                color: NatureColors.pureBlack,
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
                          ),
                          const SizedBox(height: 24),
                          
                          // Create Account Button
                          FilledButton(
                            onPressed: auth.loading
                                ? null
                                : () async {
                                    if (!_formKey.currentState!.validate()) return;
                                    await context.read<AuthProvider>().register(
                                          _email.text.trim(), 
                                          _password.text.trim(),
                                          _name.text.trim(),
                                          membershipId: _membershipId.text.trim().isEmpty 
                                              ? null 
                                              : _membershipId.text.trim(),
                                        );
                                    if (!mounted) return;
                                    if (auth.error == null) {
                                      Navigator.of(context).pop(); // back to login without dialog
                                    }
                                  },
                            style: FilledButton.styleFrom(
                              backgroundColor: NatureColors.lightGreen,
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
                                    'Register Account',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Back to Login
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: NatureColors.primaryGreen,
                            ),
                            child: const Text('Already have an account? Sign In', style: TextStyle(fontSize: 12)),
                          ),
                          
                          // Error Message
                          if (auth.error != null)
                            Container(
                              margin: const EdgeInsets.only(top: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      auth.error!,
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
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
        ),
      ),
    );
  }
}