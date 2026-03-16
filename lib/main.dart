import 'package:flutter/material.dart';
import 'screens/main_container.dart';
import 'package:provider/provider.dart';
import 'core/supabase_config.dart';
import 'core/theme.dart';
import 'services/notification_service.dart';
import 'providers/auth_provider.dart';
import 'providers/pet_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/gamification_provider.dart';
import 'providers/affiliate_provider.dart';
import 'providers/social_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/onboarding/welcome_screen.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  await initializeDateFormatting('en_US', null);

  try {
    await SupabaseConfig.initialize();
    await NotificationService.initialize();
  } catch (e) {
    debugPrint('Initialization failed: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PetProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => GamificationProvider()),
        ChangeNotifierProvider(create: (_) => AffiliateProvider()),
        ChangeNotifierProvider(create: (_) => SocialProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const PattyApp(),
    ),
  );
}

class PattyApp extends StatelessWidget {
  const PattyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();

    return MaterialApp(
      title: 'Patty',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      locale: localeProvider.locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
        Locale('en', 'US'),
      ],
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isAuthenticated) {
      return const MainContainer();
    } else {
      return const WelcomeScreen();
    }
  }
}
