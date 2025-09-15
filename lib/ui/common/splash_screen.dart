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
                padding: const EdgeInsets.all(20), // Reduced from 24 for mobile
                decoration: BoxDecoration(
                  color: NatureColors.primaryGreen,
                  borderRadius: BorderRadius.circular(16), // Reduced from 20 for mobile
                  boxShadow: [
                    BoxShadow(
                      color: NatureColors.darkGray.withOpacity(0.2),
                      blurRadius: 16, // Reduced from 20 for mobile
                      offset: const Offset(0, 8), // Reduced from 10 for mobile
                    ),
                  ],
                ),
                child: Icon(
                  Icons.eco,
                  size: 64, // Reduced from 80 for mobile
                  color: NatureColors.pureWhite,
                ),
              ),
              const SizedBox(height: 32),
              
              // App Name
              const Text(
                'AgriMix',
                style: TextStyle(
                  fontSize: 28, // Reduced from 36 for mobile
                  fontWeight: FontWeight.bold,
                  color: NatureColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your Organic Fertilizer Assistant',
                style: TextStyle(
                  fontSize: 14, // Reduced from 16 for mobile
                  color: NatureColors.darkGray,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32), // Reduced from 48 for mobile
              
              // Loading Indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(NatureColors.primaryGreen),
                strokeWidth: 2.5, // Reduced from 3 for mobile
              ),
              const SizedBox(height: 16),
              const Text(
                'Initializing AgriMix...',
                style: TextStyle(
                  fontSize: 13, // Reduced from 14 for mobile
                  color: NatureColors.mediumGray,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Please wait while we set up your experience',
                style: TextStyle(
                  fontSize: 11, // Reduced from 12 for mobile
                  color: NatureColors.lightGray,
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
