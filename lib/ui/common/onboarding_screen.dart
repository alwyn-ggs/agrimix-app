import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';
import '../../router.dart';
import '../../theme/theme.dart';

/// Increment this value whenever onboarding content changes and should be reshown.
const int onboardingExperienceVersion = 1;

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  final List<_Slide> _slides = const [
    _Slide(
      icon: Icons.eco,
      imageAsset: 'assets/onboarding/identity.png',
      title: 'AgriMix',
      subtitle: 'Optimize your fermentation. Grow smarter.',
      bullets: ['Auto-logs', 'Recipe guidance'],
      footnote: 'Swipe to learn more',
    ),
    _Slide(
      icon: Icons.bubble_chart_outlined,
      imageAsset: 'assets/onboarding/logs.png',
      title: 'Fermentation logs',
      bullets: ['Stage tracking', 'Photos & notes', 'Timely reminders'],
      footnote: 'Keep a clean, complete record',
    ),
    _Slide(
      icon: Icons.menu_book_outlined,
      imageAsset: 'assets/onboarding/recipes.png',
      title: 'Recipes & community',
      bullets: ['Recipe library', 'Community tips', 'Rate & comment'],
      footnote: 'Learn from proven mixes',
    ),
    _Slide(
      icon: Icons.notifications_active_outlined,
      imageAsset: 'assets/onboarding/alerts.png',
      title: 'Alerts & safety',
      bullets: ['Smart notifications', 'Safety reminders', 'Offline-friendly notes'],
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);
    await prefs.setInt('onboarding_version', onboardingExperienceVersion);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(Routes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          child: Column(
            children: [
              // Header with brand
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: NatureColors.primaryGreen,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: NatureColors.textDark.withAlpha((0.08 * 255).round()),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.eco, color: NatureColors.pureWhite, size: 24),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'AgriMix',
                      style: TextStyle(
                        color: NatureColors.darkGreen,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _finish,
                      child: const Text('Skip'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // Slides
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
                ),
              ),

              // Pagination dots
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_slides.length, (i) {
                    final active = i == _index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      height: 10,
                      width: active ? 28 : 10,
                      decoration: BoxDecoration(
                        color: active ? NatureColors.primaryGreen : NatureColors.mediumGray,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: NatureColors.primaryGreen.withAlpha((0.3 * 255).round()),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                    );
                  }),
                ),
              ),

              // CTAs
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      if (_index < _slides.length - 1) {
                        _controller.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
                      } else {
                        await _finish();
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: NatureColors.primaryGreen,
                      foregroundColor: NatureColors.pureWhite,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(_index == _slides.length - 1 ? 'Get Started' : 'Next'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  final _Slide slide;
  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background hero image
          _SlideHero(slide: slide),

          // Gradient overlay for readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withAlpha((0.0 * 255).round()),
                  const Color(0xCC1B5E20), // warm green tint near bottom
                ],
              ),
            ),
          ),

          // Foreground content on a warm glass card
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((0.12 * 255).round()),
                      border: Border.all(color: Colors.white.withAlpha((0.28 * 255).round())),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Gentle welcome line for the first slide
                        if (slide.subtitle != null)
                          Text(
                            slide.subtitle!,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: Colors.white.withAlpha((0.95* 255).round()),
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        if (slide.subtitle != null) const SizedBox(height: 6),
                        Text(
                          slide.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        if (slide.bullets != null)
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: slide.bullets!
                                .map(
                                  (b) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha((0.16 * 255).round()),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(color: Colors.white.withAlpha((0.28 * 255).round())),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                                        const SizedBox(width: 6),
                                        Text(b, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        if (slide.footnote != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            slide.footnote!,
                            style: TextStyle(color: Colors.white.withAlpha((0.9 * 255).round())),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Slide {
  final IconData icon;
  final String title;
  final String? subtitle;
  final List<String>? bullets;
  final String? footnote;
  final String? imageAsset;
  const _Slide({required this.icon, required this.title, this.subtitle, this.bullets, this.footnote, this.imageAsset});
}

class _SlideHero extends StatelessWidget {
  final _Slide slide;
  const _SlideHero({required this.slide});

  @override
  Widget build(BuildContext context) {
    final hasImage = (slide.imageAsset != null && slide.imageAsset!.isNotEmpty);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: NatureColors.lightGreen,
        child: AspectRatio(
          aspectRatio: 1.8,
          child: hasImage
              ? Image.asset(
                  slide.imageAsset!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(slide.icon, size: 64, color: NatureColors.pureWhite),
                    );
                  },
                )
              : Center(
                  child: Icon(slide.icon, size: 64, color: NatureColors.pureWhite),
                ),
        ),
      ),
    );
  }
}


