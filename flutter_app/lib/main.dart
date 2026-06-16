import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'screens/auth/login_screen.dart';
import 'services/auth_service.dart';
import 'services/security_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  bool loggedIn = false;
  debugPrint("[STARTUP] Khoi dong ung dung...");
  
  try {
    debugPrint("[STARTUP] Dang khoi tao Firebase...");
    await Firebase.initializeApp().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        debugPrint("[STARTUP] Firebase initialization timed out after 5s");
        throw TimeoutException("Firebase initialization timed out");
      },
    );
    debugPrint("[STARTUP] Firebase khoi tao thanh cong!");
    
    loggedIn = await authService.isLoggedIn();
    if (loggedIn) {
      final dashboard = await securityService.getDashboard();
      final bool twoFactorEnabled = dashboard['twoFactorEnabled'] ?? false;
      if (twoFactorEnabled) {
        final bool twoFactorVerified = await securityService.isTwoFactorVerifiedForSession();
        if (!twoFactorVerified) {
          debugPrint("[STARTUP] Tai khoan bat 2FA nhung phien chua xac thuc. Yeu cau dang nhap lai.");
          await authService.logout();
          loggedIn = false;
        }
      }
    }
    debugPrint("[STARTUP] Kiem tra login tu dong: loggedIn = $loggedIn");
  } catch (e) {
    debugPrint("[STARTUP] Loi khoi tao Firebase hoac login check: $e");
  }

  debugPrint("[STARTUP] Chay runApp voi initialScreen");
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
