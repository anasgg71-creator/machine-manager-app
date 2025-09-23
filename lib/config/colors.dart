import 'package:flutter/material.dart';

class AppColors {
  // Primary colors - Beautiful purple theme from design
  static const Color primary = Color(0xFF6A57FF);
  static const Color primaryDark = Color(0xFF5541E6);
  static const Color primaryLight = Color(0xFFECE8FF);

  // Secondary colors
  static const Color secondary = Color(0xFF03DAC6);
  static const Color secondaryDark = Color(0xFF00695C);
  static const Color secondaryLight = Color(0xFF4DB6AC);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFE8F5E8);
  static const Color error = Color(0xFFB00020);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color warning = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFFE3F2FD);

  // Priority colors
  static const Color priorityLow = Color(0xFF4CAF50);
  static const Color priorityMedium = Color(0xFFFF9800);
  static const Color priorityHigh = Color(0xFFFF5722);
  static const Color priorityCritical = Color(0xFFD32F2F);

  // Text colors - Matching design palette
  static const Color textPrimary = Color(0xFF231628);
  static const Color textSecondary = Color(0xFF898491);
  static const Color textHint = Color(0xFF9E9E9E);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFF231628);

  // Background colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFFEEEEEE);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF8F9FA);

  // Border colors
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFEEEEEE);
  static const Color borderDark = Color(0xFFBDBDBD);
  static const Color divider = Color(0xFFE0E0E0);

  // Chat colors
  static const Color chatBubbleOwn = Color(0xFF2196F3);
  static const Color chatBubbleOther = Color(0xFFEEEEEE);
  static const Color chatBackground = Color(0xFFF8F9FA);
  static const Color onlineStatus = Color(0xFF4CAF50);
  static const Color offlineStatus = Color(0xFF9E9E9E);

  // Card colors
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardShadow = Color(0x1F000000);
  static const Color cardBorder = Color(0xFFE6E3EB);

  // Button colors
  static const Color buttonPrimary = Color(0xFF2196F3);
  static const Color buttonSecondary = Color(0xFFEEEEEE);
  static const Color buttonText = Color(0xFFFFFFFF);
  static const Color buttonTextSecondary = Color(0xFF212121);
  static const Color buttonDisabled = Color(0xFFBDBDBD);

  // Team/Leaderboard colors
  static const Color goldMedal = Color(0xFFFFD700);
  static const Color silverMedal = Color(0xFFC0C0C0);
  static const Color bronzeMedal = Color(0xFFCD7F32);
  static const Color leaderboardBackground = Color(0xFFF8F9FF);

  // Machine status colors
  static const Color machineOperational = Color(0xFF4CAF50);
  static const Color machineMaintenance = Color(0xFFFF9800);
  static const Color machineDown = Color(0xFFD32F2F);
  static const Color machineRetired = Color(0xFF9E9E9E);

  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFFF9800), Color(0xFFE65100)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient errorGradient = LinearGradient(
    colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadow colors
  static const Color shadowLight = Color(0x0A000000);
  static const Color shadowMedium = Color(0x1F000000);
  static const Color shadowDark = Color(0x3D000000);

  // Input field colors - Modern design
  static const Color inputBackground = Color(0xFFF5F5F5);
  static const Color inputBorder = Color(0xFFE0E0E0);
  static const Color inputFocused = Color(0xFF6A57FF);

  // Ticket status colors
  static Color getTicketStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return info;
      case 'in_progress':
        return warning;
      case 'resolved':
        return success;
      case 'closed':
        return textSecondary;
      default:
        return textSecondary;
    }
  }

  // Priority colors
  static Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return priorityLow;
      case 'medium':
        return priorityMedium;
      case 'high':
        return priorityHigh;
      case 'critical':
        return priorityCritical;
      default:
        return textSecondary;
    }
  }

  // Machine status colors
  static Color getMachineStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'operational':
        return machineOperational;
      case 'maintenance':
        return machineMaintenance;
      case 'down':
        return machineDown;
      case 'retired':
        return machineRetired;
      default:
        return textSecondary;
    }
  }

  // Create Material Color Swatch
  static MaterialColor createMaterialColor(Color color) {
    final strengths = <double>[.05];
    final swatch = <int, Color>{};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }

    for (final strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }

    return MaterialColor(color.value, swatch);
  }
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      primarySwatch: AppColors.createMaterialColor(AppColors.primary),
      scaffoldBackgroundColor: AppColors.background,
      cardColor: AppColors.cardBackground,
      dividerColor: AppColors.divider,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
        ),
        bodySmall: TextStyle(
          color: AppColors.textHint,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        filled: true,
        fillColor: AppColors.inputBackground,
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}