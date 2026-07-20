import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/movie.dart';
import '../../models/cinema.dart';
import '../../services/movie_service.dart';
import 'movie_detail_screen.dart';
import 'movie_list_screen.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/location_service.dart';
import '../../widgets/booking_components.dart';
import '../booking/cinema_detail_screen.dart';
import '../profile/notice_screen.dart';
import 'movie_search_delegate.dart';

class HomeMovieScreen extends StatefulWidget {
  const HomeMovieScreen({super.key});

  @override
  State<HomeMovieScreen> createState() => _HomeMovieScreenState();
}

class _HomeMovieScreenState extends State<HomeMovieScreen> {
  bool _isLoading = false;
  List<Movie> _nowShowing = [];
  List<Cinema> _cinemas = [];

  // Định vị người dùng & API Khoảng cách rạp
  Position? _userPosition;
  Map<int, CinemaDistanceResult> _cinemaDistances = {};
  bool _isLocating = false;

  // Auto-scroll carousel
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;
  int _bannerIndex = 0;

  static const _banners = [
    _BannerData(
      tag: 'ƯU ĐÃI ĐẶC BIỆT',
      title: 'Giảm 10% vé đầu tiên\nNhập mã WELCOME10',
      gradientColors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
    ),
    _BannerData(
      tag: 'THÀNH VIÊN',
      title: 'Tích điểm mỗi lần đặt vé\nĐổi ưu đãi không giới hạn',
      gradientColors: [Color(0xFF0EA5E9), Color(0xFF8B5CF6)],
    ),
    _BannerData(
      tag: 'CUỐI TUẦN',
      title: 'Bắp + Nước chỉ 45.000đ\nMua vé bất kỳ ngày T7, CN',
      gradientColors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _startBannerAutoScroll();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  void _startBannerAutoScroll() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_bannerController.hasClients) {
        _bannerIndex = (_bannerIndex + 1) % _banners.length;
        _bannerController.animateToPage(
          _bannerIndex,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final movies = await movieService.getNowShowing();
      final cinemas = await movieService.getCinemas();
      setState(() {
        _nowShowing = movies;
        _cinemas = cinemas;
      });

      // Lấy vị trí và tính khoảng cách song song sau khi đã load xong thông tin cơ bản
      _fetchLocationAndDistances(cinemas);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tải được dữ liệu: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchLocationAndDistances(List<Cinema> cinemas) async {
    if (mounted) setState(() => _isLocating = true);
    try {
      final pos = await LocationService.instance.getCurrentPosition();
      if (mounted) {
        final distances = await LocationService.instance.calculateDistances(
          userLat: pos.latitude,
          userLng: pos.longitude,
          cinemas: cinemas,
        );

        if (mounted) {
          setState(() {
            _userPosition = pos;
            _cinemaDistances = distances;

            // Sắp xếp danh sách rạp theo khoảng cách từ gần đến xa
            _cinemas.sort((a, b) {
              final distA = _cinemaDistances[a.id]?.distanceKm ?? double.infinity;
              final distB = _cinemaDistances[b.id]?.distanceKm ?? double.infinity;
              return distA.compareTo(distB);
            });
          });
        }
      }
    } catch (e) {
      debugPrint('Lỗi xử lý khoảng cách rạp: $e');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context); // Đăng ký lắng nghe sự kiện đổi theme để vẽ lại giao diện lập tức
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.local_movies_rounded, color: Colors.black, size: 20),
            ),
            const SizedBox(width: 10),
            Text('MovieTicket',
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: 0.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search_rounded, color: AppColors.textSecondary),
            onPressed: () {
              showSearch(
                context: context,
                delegate: MovieSearchDelegate(movies: _nowShowing),
              );
            },
            tooltip: 'Tìm kiếm',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Icon(Icons.notifications_none_rounded, color: AppColors.textSecondary),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NoticeScreen()),
              ),
              tooltip: 'Thông báo',
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === AUTO-SCROLL BANNER CAROUSEL ===
              _buildBannerCarousel(),
              const SizedBox(height: AppSpacing.xl),

              // === NOW SHOWING SECTION ===
              _buildSectionHeader(
                title: 'Phim Đang Chiếu',
                onViewAll: () => Navigator.push(context,
                  _slideRoute(const MovieListScreen())),
              ),
              const SizedBox(height: AppSpacing.md),
              _isLoading ? _buildMovieCardShimmerRow() : _buildMovieCardRow(),
              const SizedBox(height: AppSpacing.xl),

              // === CINEMAS SECTION ===
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
                child: Row(
                  children: [
                    Text('Rạp Phim Liên Kết', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    if (_isLocating)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      )
                    else if (_userPosition != null)
                      const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 14),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _isLoading ? _buildCinemaShimmerList() : _buildCinemaList(),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  // === BANNER CAROUSEL ===
  Widget _buildBannerCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 172,
          child: PageView.builder(
            controller: _bannerController,
            onPageChanged: (i) => setState(() => _bannerIndex = i),
            itemCount: _banners.length,
            itemBuilder: (context, i) => _buildBannerItem(_banners[i]),
          ),
        ),
        const SizedBox(height: 10),
        // Dot indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (i) {
            final active = i == _bannerIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.textMuted,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildBannerItem(_BannerData banner) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: banner.gradientColors,
        ),
        boxShadow: [BoxShadow(color: banner.gradientColors.last.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Stack(
        children: [
          Positioned(right: -20, bottom: -20,
            child: Opacity(opacity: 0.1,
              child: const Icon(Icons.local_activity, size: 200, color: Colors.white)),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                  child: Text(banner.tag,
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)),
                ),
                const SizedBox(height: 10),
                Text(banner.title,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold, height: 1.25)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // === SECTION HEADER ===
  Widget _buildSectionHeader({required String title, VoidCallback? onViewAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.titleMedium),
          if (onViewAll != null)
            GestureDetector(
              onTap: onViewAll,
              child: Text('Xem tất cả', style: GoogleFonts.outfit(color: AppColors.primary, fontSize: 13)),
            ),
        ],
      ),
    );
  }

  // === MOVIE CARD ROW ===
  Widget _buildMovieCardRow() {
    if (_nowShowing.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Không có phim nào đang chiếu', style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }
    return SizedBox(
      height: 290,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: _nowShowing.length,
        itemBuilder: (context, i) => _MoviePosterCard(movie: _nowShowing[i]),
      ),
    );
  }

  Widget _buildMovieCardShimmerRow() {
    return SizedBox(
      height: 290,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: 4,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBox(width: 160, height: 220, radius: AppRadius.cardLarge),
              const SizedBox(height: 8),
              ShimmerBox(width: 120, height: 14),
              const SizedBox(height: 4),
              ShimmerBox(width: 80, height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // === CINEMA LIST ===
  Widget _buildCinemaList() {
    if (_cinemas.isEmpty) return const SizedBox.shrink();
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      itemCount: _cinemas.length,
      itemBuilder: (context, i) {
        final cinema = _cinemas[i];
        return CinemaListTile(
          cinema: cinema,
          distanceResult: _cinemaDistances[cinema.id],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CinemaDetailScreen(
                  cinema: cinema,
                  distanceResult: _cinemaDistances[cinema.id],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCinemaShimmerList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Column(
        children: List.generate(3, (_) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ShimmerBox(width: double.infinity, height: 72, radius: AppRadius.card),
        )),
      ),
    );
  }
}

// === MOVIE POSTER CARD ===
class _MoviePosterCard extends StatelessWidget {
  final Movie movie;
  const _MoviePosterCard({required this.movie});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, _slideRoute(MovieDetailScreen(movieId: movie.id))),
      child: Container(
        width: 160,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster image
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.cardLarge),
              child: SizedBox(
                width: 160,
                height: 224,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(color: AppColors.surfaceHigh),
                    if ((movie.posterUrl ?? '').isNotEmpty)
                      Image.network(
                        movie.posterUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const _PosterFallback(),
                      ),
                    // Age rating overlay
                    Positioned(
                      top: 8, right: 8,
                      child: AppBadge(label: movie.ageRating ?? 'P'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(movie.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyBold,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star_rounded, color: AppColors.accent, size: 14),
                const SizedBox(width: 3),
                Text('${movie.rating}', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                const SizedBox(width: 8),
                Icon(Icons.access_time_rounded, color: AppColors.textMuted, size: 12),
                const SizedBox(width: 3),
                Text('${movie.duration}p', style: AppTextStyles.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// _CinemaListTile has been refactored and moved to booking_components.dart

class _PosterFallback extends StatelessWidget {
  const _PosterFallback();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1E1B4B), Colors.black],
        ),
      ),
      child: Center(child: Icon(Icons.movie_rounded, size: 48, color: AppColors.textMuted)),
    );
  }
}

class _BannerData {
  final String tag;
  final String title;
  final List<Color> gradientColors;
  const _BannerData({required this.tag, required this.title, required this.gradientColors});
}

// Custom slide page route
PageRoute _slideRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 280),
  );
}
