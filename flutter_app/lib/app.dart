import 'dart:async';
import 'package:flutter/material.dart';
import 'screens/movies/home_movie_screen.dart';
import 'screens/movies/movie_list_screen.dart';
import 'screens/booking/booking_history_screen.dart';
import 'screens/security/security_dashboard_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/auth/login_screen.dart';
import 'services/auth_service.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  int _currentIndex = 0;
  StreamSubscription? _authSubscription;

  final List<Widget> _screens = [
    const HomeMovieScreen(),
    const MovieListScreen(),
    const BookingHistoryScreen(),
    const SecurityDashboardScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Đăng ký lắng nghe thay đổi trạng thái đăng nhập từ Supabase
    _authSubscription = authService.onAuthStateChanged.listen((user) {
      if (user == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phiên đăng nhập đã kết thúc.'),
            backgroundColor: Colors.amber,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A), // Obsidian Background
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF16162A),
        selectedItemColor: const Color(0xFFC084FC), // Glowing Purple
        unselectedItemColor: Colors.white54,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.movie_filter_rounded),
            label: 'Phim',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_num_rounded),
            label: 'Vé của tôi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shield_rounded),
            label: 'Bảo mật',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }
}
