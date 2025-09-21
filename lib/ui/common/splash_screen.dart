import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: NatureColors.primaryGreen,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: NatureColors.darkGray.withAlpha((0.2 * 255).round()),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.eco,
                  size: 80,
                  color: NatureColors.pureWhite,
                ),
              ),
              const SizedBox(height: 32),
              
              // App Name
              const Text(
                'AgriMix',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: NatureColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your Organic Fertilizer Assistant',
                style: TextStyle(
                  fontSize: 16,
                  color: NatureColors.darkGray,
                ),
              ),
              const SizedBox(height: 48),
              
              // Loading Indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(NatureColors.primaryGreen),
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              const Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 14,
                  color: NatureColors.mediumGray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
