import 'package:flutter/material.dart';
import '../../router.dart';
import '../../theme/theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NatureColors.natureBackground,
      body: SafeArea(
        child: Container(
          width: double.infinity,
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // App logo/name
                    const _AppLogo(),
                    const SizedBox(height: 16),
                    // Tagline
                    Text(
                      'Optimize your fermentation. Grow smarter.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: NatureColors.darkGreen,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 24),
                    // Language selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _LanguageChip(label: 'Filipino', selected: true, onTap: () {}),
                        const SizedBox(width: 8),
                        _LanguageChip(label: 'English', selected: false, onTap: () {}),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Key features
                    const _FeatureList(features: [
                      'Automated fermentation logs',
                      'Recipe library tailored to your setup',
                      'Community tips and support',
                      'Smart alerts and notifications',
                    ]),
                    const SizedBox(height: 24),
                    // CTAs
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pushNamed(Routes.login),
                            child: const Text('Log in'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.of(context).pushNamed(Routes.register),
                            style: FilledButton.styleFrom(
                              backgroundColor: NatureColors.primaryGreen,
                              foregroundColor: NatureColors.pureWhite,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Create account'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Help / legal
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {},
                          child: const Text('Terms of Service'),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Privacy Policy'),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Help & Support'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.agriculture, size: 72, color: NatureColors.primaryGreen),
        const SizedBox(height: 8),
        Text(
          'AgriMix',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: NatureColors.darkGreen,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

class _LanguageChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _LanguageChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? NatureColors.lightGreen : NatureColors.pureWhite,
          border: Border.all(color: selected ? NatureColors.primaryGreen : NatureColors.lightGray),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? NatureColors.darkGreen : NatureColors.darkGray,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _FeatureList extends StatelessWidget {
  final List<String> features;
  const _FeatureList({required this.features});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Why AgriMix?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: NatureColors.darkGreen,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        const SizedBox(height: 8),
        ...features.map((f) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, color: NatureColors.primaryGreen, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(f)),
                ],
              ),
            )),
      ],
    );
  }
}


