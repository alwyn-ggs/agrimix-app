import 'package:flutter/material.dart';
import '../../../theme/theme.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
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
            Text('1. Overview', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('This Privacy Policy explains how AgriMix collects, uses, and protects your information.'),
            const SizedBox(height: 16),
            Text('2. Information We Collect', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.only(left: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Account data: name, email, membership ID (optional).'),
                  Text('• Usage data: app interactions, device information, crash logs.'),
                  Text('• Content data: recipes, fermentation logs, posts, photos you upload.'),
                  Text('• Notification tokens for push notifications.'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('3. How We Use Information', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.only(left: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Provide and improve the Service and features you request.'),
                  Text('• Personalize content (e.g., recipe suggestions).'),
                  Text('• Send important notifications and updates.'),
                  Text('• Ensure safety, moderation, and prevent abuse.'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('4. Legal Bases', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('We process data under: performance of a contract, legitimate interests, compliance with legal obligations, and consent where required.'),
            const SizedBox(height: 16),
            Text('5. Sharing of Information', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('We share data with service providers (e.g., hosting, analytics, notifications) under strict rule. We do not sell personal data.'),
            const SizedBox(height: 16),
            Text('6. Data Retention', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('We retain information for as long as necessary to provide the Service and comply with legal obligations. You may request deletion.'),
            const SizedBox(height: 16),
            Text('7. Security', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('We implement reasonable technical and organizational safeguards. No method is 100% secure.'),
            const SizedBox(height: 16),
            Text('8. Your Rights', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.only(left: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Access, correct, or delete your data.'),
                  Text('• Object to or restrict certain processing.'),
                  Text('• Portability of your data (where applicable).'),
                  Text('• Withdraw consent at any time (where processing relies on consent).'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('9. Children’s Privacy', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('The Service is not directed to children under 13 (or as defined by local law).'),
            const SizedBox(height: 16),
            Text('10. International Transfers', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Your data may be transferred to servers in other countries with appropriate safeguards in place.'),
            const SizedBox(height: 16),
            Text('11. Changes to this Policy', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('We may update this Policy. We will notify you of material changes as required.'),
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


