import 'package:flutter/material.dart';

// Enhanced Nature-inspired color palette
class NatureColors {
  // Primary greens (various shades of nature green)
  static const Color primaryGreen = Color(0xFF2E7D32); // Forest green
  static const Color lightGreen = Color(0xFF4CAF50); // Fresh green
  static const Color darkGreen = Color(0xFF1B5E20); // Deep forest
  static const Color accentGreen = Color(0xFF66BB6A); // Light accent green
  static const Color vibrantGreen = Color(0xFF388E3C); // Vibrant forest
  static const Color mintGreen = Color(0xFF81C784); // Soft mint
  
  // Earth tones
  static const Color earthBrown = Color(0xFF8D6E63); // Rich earth brown
  static const Color lightBrown = Color(0xFFBCAAA4); // Light earth
  static const Color sandyBeige = Color(0xFFF5F5DC); // Sandy beige
  
  // Sky and water tones
  static const Color skyBlue = Color(0xFF87CEEB); // Sky blue
  static const Color deepBlue = Color(0xFF1976D2); // Deep blue
  static const Color waterBlue = Color(0xFF4FC3F7); // Water blue
  
  // Neutral colors with better contrast
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFFAFAFA);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color mediumGray = Color(0xFF757575); // Improved contrast
  static const Color darkGray = Color(0xFF424242);
  static const Color pureBlack = Color(0xFF000000);
  static const Color textDark = Color(0xFF212121); // High contrast text
  
  // Nature-inspired backgrounds
  static const Color natureBackground = Color(0xFFF1F8E9); // Very light green tint
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color surfaceBackground = Color(0xFFF8F9FA);
  static const Color leafBackground = Color(0xFFE8F5E8); // Subtle leaf green
  
  // Status colors
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFD32F2F);
  static const Color infoBlue = Color(0xFF2196F3);
}

// Mobile-optimized responsive breakpoints
class ResponsiveBreakpoints {
  static const double mobileSmall = 320;
  static const double mobileMedium = 375;
  static const double mobileLarge = 414;
  static const double tabletSmall = 768;
  static const double tabletLarge = 1024;
}

// Responsive helper functions
class ResponsiveHelper {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < ResponsiveBreakpoints.tabletSmall;
  }
  
  static bool isSmallMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < ResponsiveBreakpoints.mobileMedium;
  }
  
  static double getResponsiveFontSize(BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width >= ResponsiveBreakpoints.tabletLarge) {
      return desktop ?? tablet ?? mobile;
    } else if (width >= ResponsiveBreakpoints.tabletSmall) {
      return tablet ?? mobile;
    }
    return mobile;
  }
  
  static EdgeInsets getResponsivePadding(BuildContext context, {
    required EdgeInsets mobile,
    EdgeInsets? tablet,
    EdgeInsets? desktop,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width >= ResponsiveBreakpoints.tabletLarge) {
      return desktop ?? tablet ?? mobile;
    } else if (width >= ResponsiveBreakpoints.tabletSmall) {
      return tablet ?? mobile;
    }
    return mobile;
  }
}

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: NatureColors.primaryGreen,
      secondary: NatureColors.lightGreen,
      surface: NatureColors.surfaceBackground,
      error: NatureColors.errorRed,
      onPrimary: NatureColors.pureWhite,
      onSecondary: NatureColors.pureWhite,
      onSurface: NatureColors.textDark,
      onError: NatureColors.pureWhite,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: NatureColors.natureBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: NatureColors.primaryGreen,
      foregroundColor: NatureColors.pureWhite,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: NatureColors.pureWhite,
        fontSize: 18, // Reduced from 20 for mobile
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: NatureColors.cardBackground,
      elevation: 2, // Reduced from 3 for mobile
      shadowColor: NatureColors.primaryGreen.withAlpha((0.1 * 255).round()),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Reduced from 16
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Added margin for mobile
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: NatureColors.primaryGreen,
        foregroundColor: NatureColors.pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // Reduced from 12
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Reduced padding
        elevation: 1, // Reduced from 2
        shadowColor: NatureColors.primaryGreen.withAlpha((0.3 * 255).round()),
        minimumSize: const Size(120, 44), // Minimum touch target size
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: NatureColors.primaryGreen,
        foregroundColor: NatureColors.pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // Reduced from 12
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Reduced padding
        elevation: 1, // Reduced from 2
        shadowColor: NatureColors.primaryGreen.withAlpha((0.3 * 255).round()),
        minimumSize: const Size(120, 44), // Minimum touch target size
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: NatureColors.primaryGreen,
        side: const BorderSide(color: NatureColors.primaryGreen, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // Reduced from 12
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Reduced padding
        minimumSize: const Size(120, 44), // Minimum touch target size
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: NatureColors.primaryGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)), // Reduced from 8
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Reduced padding
        minimumSize: const Size(44, 44), // Minimum touch target size
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8), // Reduced from 12
        borderSide: const BorderSide(color: NatureColors.mediumGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8), // Reduced from 12
        borderSide: const BorderSide(color: NatureColors.mediumGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8), // Reduced from 12
        borderSide: const BorderSide(color: NatureColors.primaryGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8), // Reduced from 12
        borderSide: const BorderSide(color: NatureColors.errorRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8), // Reduced from 12
        borderSide: const BorderSide(color: NatureColors.errorRed, width: 2),
      ),
      filled: true,
      fillColor: NatureColors.pureWhite,
      labelStyle: const TextStyle(color: NatureColors.textDark, fontSize: 14), // Added font size
      hintStyle: const TextStyle(color: NatureColors.mediumGray, fontSize: 14), // Added font size
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16), // Added content padding
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: NatureColors.pureWhite,
      indicatorColor: NatureColors.lightGreen,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(color: NatureColors.textDark, fontWeight: FontWeight.w500, fontSize: 12), // Added font size
      ),
      iconTheme: WidgetStatePropertyAll(
        IconThemeData(color: NatureColors.mediumGray, size: 24), // Added size
      ),
      height: 60, // Fixed height for mobile
    ),
    textTheme: const TextTheme(
      // Display styles - reduced sizes for mobile
      displayLarge: TextStyle(color: NatureColors.textDark, fontWeight: FontWeight.bold, fontSize: 28),
      displayMedium: TextStyle(color: NatureColors.textDark, fontWeight: FontWeight.bold, fontSize: 24),
      displaySmall: TextStyle(color: NatureColors.textDark, fontWeight: FontWeight.bold, fontSize: 20),
      
      // Headline styles - reduced sizes for mobile
      headlineLarge: TextStyle(color: NatureColors.textDark, fontWeight: FontWeight.bold, fontSize: 22),
      headlineMedium: TextStyle(color: NatureColors.textDark, fontWeight: FontWeight.bold, fontSize: 18),
      headlineSmall: TextStyle(color: NatureColors.textDark, fontWeight: FontWeight.bold, fontSize: 16),
      
      // Title styles - reduced sizes for mobile
      titleLarge: TextStyle(color: NatureColors.textDark, fontWeight: FontWeight.w600, fontSize: 18),
      titleMedium: TextStyle(color: NatureColors.textDark, fontWeight: FontWeight.w600, fontSize: 16),
      titleSmall: TextStyle(color: NatureColors.textDark, fontWeight: FontWeight.w600, fontSize: 14),
      
      // Body styles - optimized for mobile readability
      bodyLarge: TextStyle(color: NatureColors.textDark, fontSize: 16, height: 1.5),
      bodyMedium: TextStyle(color: NatureColors.textDark, fontSize: 14, height: 1.4),
      bodySmall: TextStyle(color: NatureColors.mediumGray, fontSize: 12, height: 1.3),
      
      // Label styles - reduced sizes for mobile
      labelLarge: TextStyle(color: NatureColors.textDark, fontWeight: FontWeight.w500, fontSize: 14),
      labelMedium: TextStyle(color: NatureColors.textDark, fontWeight: FontWeight.w500, fontSize: 12),
      labelSmall: TextStyle(color: NatureColors.mediumGray, fontWeight: FontWeight.w500, fontSize: 10),
    ),
    visualDensity: VisualDensity.compact, // Changed from adaptivePlatformDensity for mobile optimization
  );
}

ThemeData buildDarkTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: NatureColors.lightGreen,
      secondary: NatureColors.accentGreen,
      surface: Color(0xFF1E1E1E), // Darker surface for better contrast
      error: NatureColors.errorRed,
      onPrimary: NatureColors.pureBlack,
      onSecondary: NatureColors.pureBlack,
      onSurface: NatureColors.offWhite,
      onError: NatureColors.pureWhite,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212), // Darker background
    appBarTheme: const AppBarTheme(
      backgroundColor: NatureColors.darkGreen,
      foregroundColor: NatureColors.pureWhite,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: NatureColors.pureWhite,
        fontSize: 18, // Reduced from 20 for mobile
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF2D2D2D), // Darker card background
      elevation: 2, // Reduced from 3 for mobile
      shadowColor: NatureColors.lightGreen.withAlpha((0.1 * 255).round()),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Reduced from 16
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Added margin for mobile
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: NatureColors.lightGreen,
        foregroundColor: NatureColors.pureBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // Reduced from 12
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Reduced padding
        elevation: 1, // Reduced from 2
        shadowColor: NatureColors.lightGreen.withAlpha((0.3 * 255).round()),
        minimumSize: const Size(120, 44), // Minimum touch target size
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: NatureColors.lightGreen,
        foregroundColor: NatureColors.pureBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // Reduced from 12
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Reduced padding
        elevation: 1, // Reduced from 2
        shadowColor: NatureColors.lightGreen.withAlpha((0.3 * 255).round()),
        minimumSize: const Size(120, 44), // Minimum touch target size
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: NatureColors.lightGreen,
        side: const BorderSide(color: NatureColors.lightGreen, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // Reduced from 12
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Reduced padding
        minimumSize: const Size(120, 44), // Minimum touch target size
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: NatureColors.lightGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)), // Reduced from 8
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Reduced padding
        minimumSize: const Size(44, 44), // Minimum touch target size
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8), // Reduced from 12
        borderSide: const BorderSide(color: NatureColors.mediumGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8), // Reduced from 12
        borderSide: const BorderSide(color: NatureColors.mediumGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8), // Reduced from 12
        borderSide: const BorderSide(color: NatureColors.lightGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8), // Reduced from 12
        borderSide: const BorderSide(color: NatureColors.errorRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8), // Reduced from 12
        borderSide: const BorderSide(color: NatureColors.errorRed, width: 2),
      ),
      filled: true,
      fillColor: const Color(0xFF2D2D2D),
      labelStyle: const TextStyle(color: NatureColors.offWhite, fontSize: 14), // Added font size
      hintStyle: const TextStyle(color: NatureColors.mediumGray, fontSize: 14), // Added font size
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16), // Added content padding
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      indicatorColor: NatureColors.lightGreen,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(color: NatureColors.offWhite, fontWeight: FontWeight.w500, fontSize: 12), // Added font size
      ),
      iconTheme: WidgetStatePropertyAll(
        IconThemeData(color: NatureColors.mediumGray, size: 24), // Added size
      ),
      height: 60, // Fixed height for mobile
    ),
    textTheme: const TextTheme(
      // Display styles - reduced sizes for mobile
      displayLarge: TextStyle(color: NatureColors.offWhite, fontWeight: FontWeight.bold, fontSize: 28),
      displayMedium: TextStyle(color: NatureColors.offWhite, fontWeight: FontWeight.bold, fontSize: 24),
      displaySmall: TextStyle(color: NatureColors.offWhite, fontWeight: FontWeight.bold, fontSize: 20),
      
      // Headline styles - reduced sizes for mobile
      headlineLarge: TextStyle(color: NatureColors.offWhite, fontWeight: FontWeight.bold, fontSize: 22),
      headlineMedium: TextStyle(color: NatureColors.offWhite, fontWeight: FontWeight.bold, fontSize: 18),
      headlineSmall: TextStyle(color: NatureColors.offWhite, fontWeight: FontWeight.bold, fontSize: 16),
      
      // Title styles - reduced sizes for mobile
      titleLarge: TextStyle(color: NatureColors.offWhite, fontWeight: FontWeight.w600, fontSize: 18),
      titleMedium: TextStyle(color: NatureColors.offWhite, fontWeight: FontWeight.w600, fontSize: 16),
      titleSmall: TextStyle(color: NatureColors.offWhite, fontWeight: FontWeight.w600, fontSize: 14),
      
      // Body styles - optimized for mobile readability
      bodyLarge: TextStyle(color: NatureColors.offWhite, fontSize: 16, height: 1.5),
      bodyMedium: TextStyle(color: NatureColors.offWhite, fontSize: 14, height: 1.4),
      bodySmall: TextStyle(color: NatureColors.mediumGray, fontSize: 12, height: 1.3),
      
      // Label styles - reduced sizes for mobile
      labelLarge: TextStyle(color: NatureColors.offWhite, fontWeight: FontWeight.w500, fontSize: 14),
      labelMedium: TextStyle(color: NatureColors.offWhite, fontWeight: FontWeight.w500, fontSize: 12),
      labelSmall: TextStyle(color: NatureColors.mediumGray, fontWeight: FontWeight.w500, fontSize: 10),
    ),
    visualDensity: VisualDensity.compact, // Changed from adaptivePlatformDensity for mobile optimization
  );
}