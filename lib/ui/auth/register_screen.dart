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
  bool _acceptedTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  void _showUnderReviewDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.pending_actions,
                  size: 48,
                  color: Colors.orange.shade600,
                ),
              ),
              const SizedBox(height: 20),
              
              // Title
              const Text(
                'Account Under Review',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: NatureColors.darkGreen,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              // Message
              const Text(
                'Your account is already registered and is currently under review. Please wait for administrator approval before you can access the app.',
                style: TextStyle(
                  fontSize: 14,
                  color: NatureColors.darkGray,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // OK Button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    // Ensure user is signed out so we return to login screen
                    context.read<AuthProvider>().signOut();
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Go back to login screen
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: NatureColors.primaryGreen,
                    foregroundColor: NatureColors.pureWhite,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: NatureColors.mediumGray,
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
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                  color: NatureColors.mediumGray,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
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
                            obscureText: _obscureConfirmPassword,
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
                          
                          // Accept Terms & Privacy
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: _acceptedTerms,
                                onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                                side: const BorderSide(color: Colors.black, width: 2),
                                fillColor: const WidgetStatePropertyAll(Colors.transparent),
                                checkColor: Colors.black,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              Expanded(
                                child: Wrap(
                                  children: [
                                    const Text('I agree to the ', style: TextStyle(fontSize: 12, color: NatureColors.darkGray)),
                                    InkWell(
                                      onTap: () => Navigator.pushNamed(context, '/terms'),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 2),
                                        child: Text('Terms of Service', style: TextStyle(fontSize: 12, color: NatureColors.primaryGreen, decoration: TextDecoration.underline)),
                                      ),
                                    ),
                                    const Text(' and ', style: TextStyle(fontSize: 12, color: NatureColors.darkGray)),
                                    InkWell(
                                      onTap: () => Navigator.pushNamed(context, '/privacy'),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 2),
                                        child: Text('Privacy Policy', style: TextStyle(fontSize: 12, color: NatureColors.primaryGreen, decoration: TextDecoration.underline)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Create Account Button
                          FilledButton(
                            onPressed: (auth.loading || !_acceptedTerms)
                                ? null
                                : () async {
                                    if (!_formKey.currentState!.validate()) return;
                                    final provider = context.read<AuthProvider>();
                                    await provider.register(
                                          _email.text.trim(), 
                                          _password.text.trim(),
                                          _name.text.trim(),
                                          membershipId: _membershipId.text.trim().isEmpty 
                                              ? null 
                                              : _membershipId.text.trim(),
                                        );
                                    if (!mounted) return;
                                    final currentError = provider.error;
                                    if (currentError == null) {
                                      // Registration success path: show under-review popup
                                      provider.clearError();
                                      _showUnderReviewDialog(context);
                                    } else if (currentError.contains('under review')) {
                                      // Show popup dialog for under review message
                                      provider.clearError();
                                      _showUnderReviewDialog(context);
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

                          const SizedBox(height: 8),
                          // Agreement
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text('By registering, you agree to the ', style: TextStyle(fontSize: 12, color: NatureColors.darkGray)),
                              InkWell(
                                onTap: () => Navigator.pushNamed(context, '/terms'),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 2),
                                  child: Text('Terms of Service', style: TextStyle(fontSize: 12, color: NatureColors.primaryGreen, decoration: TextDecoration.underline)),
                                ),
                              ),
                              const Text(' and ', style: TextStyle(fontSize: 12, color: NatureColors.darkGray)),
                              InkWell(
                                onTap: () => Navigator.pushNamed(context, '/privacy'),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 2),
                                  child: Text('Privacy Policy', style: TextStyle(fontSize: 12, color: NatureColors.primaryGreen, decoration: TextDecoration.underline)),
                                ),
                              ),
                              const Text('.', style: TextStyle(fontSize: 12, color: NatureColors.darkGray)),
                            ],
                          ),
                          
                          // Error Message
                          if (auth.error != null)
                            Container(
                              margin: const EdgeInsets.only(top: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: auth.error!.contains('under review') 
                                    ? Colors.orange.shade50 
                                    : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: auth.error!.contains('under review') 
                                      ? Colors.orange.shade200 
                                      : Colors.red.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    auth.error!.contains('under review') 
                                        ? Icons.pending_actions 
                                        : Icons.error_outline, 
                                    color: auth.error!.contains('under review') 
                                        ? Colors.orange.shade600 
                                        : Colors.red.shade600, 
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      auth.error!,
                                      style: TextStyle(
                                        color: auth.error!.contains('under review') 
                                            ? Colors.orange.shade700 
                                            : Colors.red.shade700,
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