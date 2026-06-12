import  'package:flutter/material.dart';
import 'app.dart';
import 'screens/auth/login_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Kiểm tra trạng thái đăng nhập tự động
  final bool loggedIn = await authService.isLoggedIn();

  runApp(MovieApp(initialScreen: loggedIn ? const App() : const LoginScreen()));
}

class MovieApp extends StatelessWidget {
  final Widget initialScreen;

  const MovieApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movie Ticket Booking',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F1A), // Obsidian Black
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFC084FC),      // Purple accent
          secondary: Color(0xFF8B5CF6),    // Dark violet
          surface: Color(0xFF16162A),      // Card surface
          background: Color(0xFF0F0F1A),
          error: Colors.redAccent,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF16162A),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF16162A),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      home: initialScreen,
    );
  }
}
