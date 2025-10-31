import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'services/supabase_service.dart';
import 'services/ticket_expiration_service.dart';
import 'services/machine_seed_service.dart';
import 'providers/auth_provider.dart';
import 'providers/ticket_provider.dart';
import 'providers/language_provider.dart';
import 'config/colors.dart';
import 'config/constants.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'utils/test_ticket_creation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  try {
    await SupabaseService.initialize();
    print('✅ Supabase initialized successfully');
  } catch (e) {
    print('❌ Failed to initialize Supabase: $e');
    print('⚠️  Make sure to update your Supabase credentials in config/constants.dart');
  }

  // Initialize Ticket Expiration Service
  try {
    await TicketExpirationService.initialize();
    print('✅ Ticket Expiration Service initialized successfully');
  } catch (e) {
    print('❌ Failed to initialize Ticket Expiration Service: $e');
  }

  // Seed machines if empty
  try {
    await MachineSeedService.seedMachinesIfEmpty();
    print('✅ Machine seeding completed');
  } catch (e) {
    print('❌ Failed to seed machines: $e');
  }

  // Run tests to verify ticket creation
  try {
    await TestTicketCreation.runMachineTest();
    print('✅ Machine test completed');
  } catch (e) {
    print('❌ Failed to run machine test: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TicketProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            title: AppConstants.appName,
            theme: AppTheme.lightTheme,
            locale: languageProvider.currentLocale,
            supportedLocales: LanguageProvider.supportedLanguages
                .map((lang) => Locale(lang.code))
                .toList(),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const AuthWrapper(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading while checking auth state
        if (authProvider.isLoading) {
          return const SplashScreen();
        }

        // Show appropriate screen based on auth state
        if (authProvider.isAuthenticated) {
          return const DashboardScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo/Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowMedium,
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.precision_manufacturing,
                size: 64,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 32),

            // App Title
            const Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textOnPrimary,
              ),
            ),

            const SizedBox(height: 8),

            // Subtitle
            Text(
              'Industrial Machine Management',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textOnPrimary.withOpacity(0.8),
              ),
            ),

            const SizedBox(height: 48),

            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.textOnPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
