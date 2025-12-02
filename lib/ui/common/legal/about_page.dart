import 'package:flutter/material.dart';
import '../../../theme/theme.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: NatureColors.primaryGreen,
        foregroundColor: NatureColors.pureWhite,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Title and Version
            Center(
              child: Column(
                children: [
                  Text(
                    'AgriMix',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: NatureColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Organic Fertilizer Creation and Fermentation Tracking',
                    style: textTheme.titleSmall?.copyWith(
                      color: NatureColors.darkGray,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version 1.0.0',
                    style: textTheme.bodyMedium?.copyWith(
                      color: NatureColors.darkGray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Description
            Text(
              'Description',
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'AgriMix is a mobile application designed to assist small-scale farmers in creating, monitoring, and managing fermentation-based organic fertilizer such as Fermented Plant Juice (FPJ) and Fermented Fruit Juice (FFJ). The application provides guided instructions, fermentation tracking, reminders, and record management to help farmers improve their production process.',
            ),
            const SizedBox(height: 24),

            // Meet the Developers
            Text(
              'Meet the Developers',
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            
            // Developer Cards
            const _DeveloperCard(
              name: 'Alwyn Nabor',
              role: 'Full Stack Developer',
              imagePath: 'assets/images/developers/alwyn.jpg',
            ),
            const SizedBox(height: 12),
            const _DeveloperCard(
              name: 'Randy Aguenza',
              role: 'Backend Developer, Researcher',
              imagePath: 'assets/images/developers/randy.jpg',
            ),
            const SizedBox(height: 12),
            const _DeveloperCard(
              name: 'Leomar Ceazar Caringal',
              role: 'Tester, Documentation, Researcher',
              imagePath: 'assets/images/developers/leomar.jpg',
            ),
            const SizedBox(height: 24),

            // Purpose of the App
            Text(
              'Purpose of the App',
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.only(left: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Help farmers easily create FFJ and FPJ mixtures.'),
                  SizedBox(height: 4),
                  Text('• Provide a step-by-step fermentation guide.'),
                  SizedBox(height: 4),
                  Text('• Track fermentation progress with logs and reminders.'),
                  SizedBox(height: 4),
                  Text('• Manage organic fertilizer records.'),
                  SizedBox(height: 4),
                  Text('• Promote organic farming practices in rural communities.'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Contact
            Text(
              'Contact',
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'For inquiries or feedback, you may reach the developer team at:',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.email_outlined,
                  size: 20,
                  color: NatureColors.primaryGreen,
                ),
                const SizedBox(width: 8),
                Text(
                  'agrimix6@gmail.com',
                  style: textTheme.bodyMedium?.copyWith(
                    color: NatureColors.primaryGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _DeveloperCard extends StatelessWidget {
  final String name;
  final String role;
  final String? imagePath;

  const _DeveloperCard({
    required this.name,
    required this.role,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 2,
        color: NatureColors.pureWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: NatureColors.lightGreen.withAlpha((0.3 * 255).round()),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Developer image or placeholder
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: NatureColors.primaryGreen.withAlpha((0.15 * 255).round()),
                  borderRadius: BorderRadius.circular(12),
                  image: imagePath != null
                      ? DecorationImage(
                          image: AssetImage(imagePath!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: imagePath == null
                    ? const Icon(
                        Icons.person,
                        size: 80,
                        color: NatureColors.primaryGreen,
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              // Name
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              // Role
              Text(
                role,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
