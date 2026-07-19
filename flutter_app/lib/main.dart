import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (SupabaseConfig.url != 'YOUR_SUPABASE_URL' &&
      SupabaseConfig.anonKey != 'YOUR_SUPABASE_ANON_KEY') {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  } else {
    debugPrint('⚠️ Supabase chưa được cấu hình!');
  }

  final bool loggedIn = await authService.isLoggedIn();

  runApp(MovieApp(initialScreen: loggedIn ? const App() : const LoginScreen()));
}

class MovieApp extends StatelessWidget {
  final Widget initialScreen;
  const MovieApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeNotifier,
      builder: (context, _) {
        return MaterialApp(
          title: 'Movie Ticket Booking',
          debugShowCheckedModeBanner: false,
          themeMode: themeNotifier.mode,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: initialScreen,
        );
      },
    );
  }
}
