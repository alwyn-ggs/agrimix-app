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
  
  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF121212); // Deep dark background
  static const Color darkSurface = Color(0xFF1E1E1E); // Surface color
  static const Color darkCard = Color(0xFF2C2C2C); // Card background
  static const Color darkElevated = Color(0xFF333333); // Elevated surfaces
  static const Color darkBorder = Color(0xFF404040); // Borders
  static const Color darkDivider = Color(0xFF505050); // Dividers
  
  // Dark Theme Text Colors
  static const Color darkTextPrimary = Color(0xFFE8E8E8); // Primary text
  static const Color darkTextSecondary = Color(0xFFB0B0B0); // Secondary text
  static const Color darkTextDisabled = Color(0xFF707070); // Disabled text
  static const Color darkTextHint = Color(0xFF808080); // Hint text
  
  // Dark Theme Green Accents
  static const Color darkGreenBright = Color(0xFF66BB6A); // Bright green for dark mode
  static const Color darkGreenLight = Color(0xFF81C784); // Light green accent
  static const Color darkGreenAccent = Color(0xFF4CAF50); // Accent green
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
      primary: NatureColors.darkGreenBright,
      secondary: NatureColors.darkGreenLight,
      surface: NatureColors.darkSurface,
      error: NatureColors.errorRed,
      onPrimary: NatureColors.pureBlack,
      onSecondary: NatureColors.pureBlack,
      onSurface: NatureColors.darkTextPrimary,
      onError: NatureColors.pureWhite,
      brightness: Brightness.dark,
      surfaceContainerHighest: NatureColors.darkCard,
      outline: NatureColors.darkBorder,
    ),
    scaffoldBackgroundColor: NatureColors.darkBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: NatureColors.darkGreen,
      foregroundColor: NatureColors.pureWhite,
      elevation: 0,
      centerTitle: true,
      shadowColor: NatureColors.darkGreenBright.withAlpha((0.2 * 255).round()),
      titleTextStyle: const TextStyle(
        color: NatureColors.pureWhite,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: const IconThemeData(
        color: NatureColors.pureWhite,
        size: 24,
      ),
    ),
    cardTheme: CardThemeData(
      color: NatureColors.darkCard,
      elevation: 3,
      shadowColor: NatureColors.darkGreenBright.withAlpha((0.15 * 255).round()),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: NatureColors.darkBorder.withAlpha((0.5 * 255).round()),
          width: 1,
        ),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: NatureColors.darkGreenBright,
        foregroundColor: NatureColors.pureBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: 2,
        shadowColor: NatureColors.darkGreenBright.withAlpha((0.4 * 255).round()),
        minimumSize: const Size(120, 44),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: NatureColors.darkGreenBright,
        foregroundColor: NatureColors.pureBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: 2,
        shadowColor: NatureColors.darkGreenBright.withAlpha((0.4 * 255).round()),
        minimumSize: const Size(120, 44),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: NatureColors.darkGreenBright,
        side: const BorderSide(color: NatureColors.darkGreenBright, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        minimumSize: const Size(120, 44),
        backgroundColor: Colors.transparent,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: NatureColors.darkGreenBright,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(44, 44),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: NatureColors.darkDivider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: NatureColors.darkDivider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: NatureColors.darkGreenBright, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: NatureColors.errorRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: NatureColors.errorRed, width: 2),
      ),
      filled: true,
      fillColor: NatureColors.darkCard,
      labelStyle: const TextStyle(color: NatureColors.darkTextSecondary, fontSize: 14),
      hintStyle: const TextStyle(color: NatureColors.darkTextHint, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      prefixIconColor: NatureColors.darkTextSecondary,
      suffixIconColor: NatureColors.darkTextSecondary,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: NatureColors.darkSurface,
      indicatorColor: NatureColors.darkGreenBright.withAlpha((0.3 * 255).round()),
      elevation: 8,
      shadowColor: Colors.black.withAlpha((0.3 * 255).round()),
      labelTextStyle: const WidgetStatePropertyAll(
        TextStyle(color: NatureColors.darkTextPrimary, fontWeight: FontWeight.w500, fontSize: 12),
      ),
      iconTheme: const WidgetStatePropertyAll(
        IconThemeData(color: NatureColors.darkTextSecondary, size: 24),
      ),
      height: 60,
    ),
    dividerTheme: const DividerThemeData(
      color: NatureColors.darkDivider,
      thickness: 1,
      space: 1,
    ),
    listTileTheme: ListTileThemeData(
      textColor: NatureColors.darkTextPrimary,
      iconColor: NatureColors.darkTextSecondary,
      tileColor: Colors.transparent,
      selectedTileColor: NatureColors.darkGreenBright.withAlpha((0.15 * 255).round()),
      selectedColor: NatureColors.darkGreenBright,
    ),
    iconTheme: const IconThemeData(
      color: NatureColors.darkTextSecondary,
      size: 24,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return NatureColors.darkGreenBright;
        }
        return NatureColors.darkTextDisabled;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return NatureColors.darkGreenBright.withAlpha((0.5 * 255).round());
        }
        return NatureColors.darkBorder;
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return NatureColors.darkGreenBright;
        }
        return Colors.transparent;
      }),
      checkColor: const WidgetStatePropertyAll(NatureColors.pureBlack),
      side: const BorderSide(color: NatureColors.darkBorder, width: 2),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return NatureColors.darkGreenBright;
        }
        return NatureColors.darkBorder;
      }),
    ),
    textTheme: const TextTheme(
      // Display styles - brighter text
      displayLarge: TextStyle(color: NatureColors.darkTextPrimary, fontWeight: FontWeight.bold, fontSize: 28),
      displayMedium: TextStyle(color: NatureColors.darkTextPrimary, fontWeight: FontWeight.bold, fontSize: 24),
      displaySmall: TextStyle(color: NatureColors.darkTextPrimary, fontWeight: FontWeight.bold, fontSize: 20),
      
      // Headline styles
      headlineLarge: TextStyle(color: NatureColors.darkTextPrimary, fontWeight: FontWeight.bold, fontSize: 22),
      headlineMedium: TextStyle(color: NatureColors.darkTextPrimary, fontWeight: FontWeight.bold, fontSize: 18),
      headlineSmall: TextStyle(color: NatureColors.darkTextPrimary, fontWeight: FontWeight.bold, fontSize: 16),
      
      // Title styles
      titleLarge: TextStyle(color: NatureColors.darkTextPrimary, fontWeight: FontWeight.w600, fontSize: 18),
      titleMedium: TextStyle(color: NatureColors.darkTextPrimary, fontWeight: FontWeight.w600, fontSize: 16),
      titleSmall: TextStyle(color: NatureColors.darkTextPrimary, fontWeight: FontWeight.w600, fontSize: 14),
      
      // Body styles - better contrast
      bodyLarge: TextStyle(color: NatureColors.darkTextPrimary, fontSize: 16, height: 1.5),
      bodyMedium: TextStyle(color: NatureColors.darkTextPrimary, fontSize: 14, height: 1.4),
      bodySmall: TextStyle(color: NatureColors.darkTextSecondary, fontSize: 12, height: 1.3),
      
      // Label styles
      labelLarge: TextStyle(color: NatureColors.darkTextPrimary, fontWeight: FontWeight.w500, fontSize: 14),
      labelMedium: TextStyle(color: NatureColors.darkTextPrimary, fontWeight: FontWeight.w500, fontSize: 12),
      labelSmall: TextStyle(color: NatureColors.darkTextSecondary, fontWeight: FontWeight.w500, fontSize: 10),
    ),
    visualDensity: VisualDensity.compact,
  );
}