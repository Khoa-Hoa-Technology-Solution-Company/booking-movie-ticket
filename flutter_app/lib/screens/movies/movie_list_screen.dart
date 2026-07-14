import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../models/movie.dart';
import '../../services/movie_service.dart';
import 'movie_detail_screen.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<Movie> _nowShowing = [];
  List<Movie> _comingSoon = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMovies();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMovies() async {
    setState(() => _isLoading = true);
    try {
      final nowShowing = await movieService.getNowShowing();
      final comingSoon = await movieService.getComingSoon();
      setState(() {
        _nowShowing = nowShowing;
        _comingSoon = comingSoon;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tải được danh sách phim: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Danh Sách Phim', style: AppTextStyles.titleSmall),
        backgroundColor: AppColors.surface,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.normal, fontSize: 14),
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'Đang chiếu'),
            Tab(text: 'Sắp chiếu'),
          ],
        ),
      ),
      body: _isLoading
          ? _buildShimmerGrid()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMovieGrid(_nowShowing, isNowShowing: true),
                _buildMovieGrid(_comingSoon, isNowShowing: false),
              ],
            ),
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.base),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, childAspectRatio: 0.62,
        crossAxisSpacing: 14, mainAxisSpacing: 14,
      ),
      itemCount: 6,
      itemBuilder: (context, i) => ShimmerBox(width: double.infinity, height: double.infinity, radius: AppRadius.card),
    );
  }

  Widget _buildMovieGrid(List<Movie> movies, {required bool isNowShowing}) {
    if (movies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.movie_filter_outlined, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text('Không có phim nào', style: AppTextStyles.body),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMovies,
      color: AppColors.primary,
      child: GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.base),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, childAspectRatio: 0.62,
          crossAxisSpacing: 14, mainAxisSpacing: 14,
        ),
        itemCount: movies.length,
        itemBuilder: (context, i) => _MovieGridCard(movie: movies[i], isNowShowing: isNowShowing),
      ),
    );
  }
}

class _MovieGridCard extends StatelessWidget {
  final Movie movie;
  final bool isNowShowing;
  const _MovieGridCard({required this.movie, required this.isNowShowing});

  @override
  Widget build(BuildContext context) {
    final posterUrl = movie.posterUrl ?? '';
    return GestureDetector(
      onTap: () => Navigator.push(context, _pageSlide(MovieDetailScreen(movieId: movie.id))),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          color: AppColors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Poster
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(color: AppColors.surfaceHigh),
                    if (posterUrl.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: posterUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const ShimmerBox(
                          width: double.infinity,
                          height: double.infinity,
                          radius: AppRadius.card,
                        ),
                        errorWidget: (context, url, error) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft, end: Alignment.bottomRight,
                              colors: [Color(0xFF1E1B4B), Colors.black],
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.movie_rounded, size: 42, color: AppColors.textMuted),
                          ),
                        ),
                      ),
                    // Gradient bottom
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
                            stops: const [0.6, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Age rating
                    Positioned(
                      top: 8, left: 8,
                      child: AppBadge(label: movie.ageRating ?? 'P'),
                    ),
                    // Status badge for coming soon
                    if (!isNowShowing)
                      Positioned(
                        bottom: 8, right: 8,
                        child: AppBadge(
                          label: 'Sắp chiếu',
                          color: AppColors.accent.withOpacity(0.15),
                          textColor: AppColors.accent,
                        ),
                      ),
                  ],
                ),
              ),
              // Info
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(movie.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyBold),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 11, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Text('${movie.duration}p', style: AppTextStyles.caption),
                        if (isNowShowing) ...[
                          const Spacer(),
                          const Icon(Icons.star_rounded, size: 12, color: AppColors.accent),
                          const SizedBox(width: 2),
                          Text('${movie.rating}', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

PageRoute _pageSlide(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) => SlideTransition(
      position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
          .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
      child: child,
    ),
    transitionDuration: const Duration(milliseconds: 280),
  );
}
