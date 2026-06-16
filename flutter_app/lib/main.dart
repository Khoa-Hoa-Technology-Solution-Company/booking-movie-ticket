import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app.dart';
import 'screens/auth/login_screen.dart';
import 'services/auth_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kDebugMode) {
    try {
      String host = '127.0.0.1';
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        host = '10.0.2.2';
      }
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
      debugPrint('[Firebase] Connected to local Emulators (Auth: 9099, Firestore: 8080, Functions: 5001) on host: $host');
    } catch (e) {
      debugPrint('[Firebase] Error connecting to emulators: $e');
    }
  }

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
          primary: Color(0xFFC084FC), // Purple accent
          secondary: Color(0xFF8B5CF6), // Dark violet
          surface: Color(0xFF16162A), // Card surface
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: initialScreen,
    );
  }
}
