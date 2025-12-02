import 'package:flutter/material.dart';
import '../../../theme/theme.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        backgroundColor: NatureColors.primaryGreen,
        foregroundColor: NatureColors.pureWhite,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Last updated: September 30, 2025', style: textTheme.bodySmall?.copyWith(color: NatureColors.darkGray)),
            const SizedBox(height: 16),
            Text('1. Introduction', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Welcome to AgriMix. By accessing or using the app, you agree to these Terms.'),
            const SizedBox(height: 16),
            Text('2. Acceptance of Terms', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('If you do not agree with any part of these Terms, you may not use the Service.'),
            const SizedBox(height: 16),
            Text('3. Use of the Service', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('You agree to use the Service only for lawful purposes and in accordance with these Terms.'),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.only(left: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Do not attempt to interfere with security or integrity.'),
                  Text('• Do not misuse APIs, notifications, or data provided by the app.'),
                  Text('• Follow community guidelines when posting content.'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('4. Accounts & Security', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('You are responsible for maintaining the confidentiality of your credentials and for all activities under your account.'),
            const SizedBox(height: 16),
            Text('5. Content Ownership', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('You retain ownership of content you submit; you grant AgriMix a license to host and display it within the Service.'),
            const SizedBox(height: 16),
            Text('6. Prohibited Activities', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.only(left: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Reverse engineering or unauthorized access.'),
                  Text('• Posting illegal, harmful, or infringing content.'),
                  Text('• Circumventing moderation or rate limits.'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('7. Disclaimers', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('The Service is provided “as is” without warranties of any kind. Agronomic outcomes may vary and are not guaranteed.'),
            const SizedBox(height: 16),
            Text('8. Limitation of Liability', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('To the fullest extent permitted by law, AgriMix will not be liable for indirect or consequential damages arising from your use of the Service.'),
            const SizedBox(height: 16),
            Text('9. Indemnification', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('You agree to indemnify and hold AgriMix harmless from claims arising out of your use of the Service or violation of these Terms.'),
            const SizedBox(height: 16),
            Text('10. Termination', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('We may suspend or terminate access to the Service at any time for conduct that violates these Terms.'),
            const SizedBox(height: 16),
            Text('11. Changes to Terms', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('We may update these Terms from time to time. Continued use constitutes acceptance of the revised Terms.'),
            const SizedBox(height: 16),
            Text('12. Contact Us', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Questions? Email agrimix6@gmail.com'),
          ],
        ),
      ),
    );
  }
}


