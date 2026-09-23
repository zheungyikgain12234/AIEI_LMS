import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' show FlutterQuillLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/config/supabase_env.dart';
import 'package:stitch_aiei_lms/core/theme/app_colors.dart';
import 'package:stitch_aiei_lms/presentation/screens/login/login_screen.dart';

/// Lets pushed screens (e.g. course grading) tell screens beneath them
/// (e.g. the student course catalogue) to refresh when the user navigates
/// back, so server-side changes aren't hidden behind stale provider state.
final routeObserver = RouteObserver<ModalRoute<void>>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!SupabaseEnv.isConfigured) {
    throw StateError(
      'Supabase is not configured. Run with '
      '--dart-define-from-file=supabase.env.json (see supabase.env.json.example).',
    );
  }

  await Supabase.initialize(
    url: SupabaseEnv.url,
    anonKey: SupabaseEnv.anonKey,
  );

  runApp(
    const ProviderScope(
      child: AieiLmsApp(),
    ),
  );
}

class AieiLmsApp extends StatelessWidget {
  const AieiLmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AIEI Learning Management System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.secondary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
        ),
      ),
      localizationsDelegates: const [
        FlutterQuillLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      navigatorObservers: [routeObserver],
      home: const LoginScreen(),
    );
  }
}
