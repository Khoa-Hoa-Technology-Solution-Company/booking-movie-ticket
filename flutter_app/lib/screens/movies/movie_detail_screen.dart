import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/movie.dart';
import '../../models/showtime.dart';
import '../../services/movie_service.dart';
import '../booking/seat_selection_screen.dart';

class MovieDetailScreen extends StatefulWidget {
  final int movieId;
  const MovieDetailScreen({super.key, required this.movieId});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool _isLoading = false;
  Movie? _movie;
  List<Showtime> _showtimes = [];

  @override
  void initState() {
    super.initState();
    _loadMovieDetail();
  }

  Future<void> _loadMovieDetail() async {
    setState(() => _isLoading = true);
    try {
      final movie = await movieService.getMovieById(widget.movieId);
      final showtimes = await movieService.getShowtimes(movieId: widget.movieId);
      setState(() {
        _movie = movie;
        _showtimes = showtimes;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không thể tải chi tiết phim: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (_movie == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Không tìm thấy thông tin phim', style: TextStyle(color: AppColors.textMuted))),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(_movie!.title, style: AppTextStyles.titleLarge),
                  const SizedBox(height: 10),

                  // Metadata row
                  _buildMetadataRow(),
                  const SizedBox(height: 14),

                  // Genre
                  if (_movie!.genre != null)
                    Wrap(
                      spacing: 6,
                      children: _movie!.genre!.split(',').map((g) =>
                        AppBadge(label: g.trim(), color: AppColors.primaryDim, textColor: AppColors.primary)
                      ).toList(),
                    ),
                  const SizedBox(height: AppSpacing.lg),

                  // Description
                  Text('Nội dung phim', style: AppTextStyles.titleSmall),
                  const SizedBox(height: 8),
                  Text(_movie!.description, style: AppTextStyles.body),
                  const SizedBox(height: AppSpacing.lg),

                  // Director & Cast
                  if (_movie!.director != null) _buildInfoRow('🎬 Đạo diễn', _movie!.director!),
                  if (_movie!.cast != null) _buildInfoRow('🎭 Diễn viên', _movie!.cast!),
                  const SizedBox(height: AppSpacing.xl),

                  // Divider
                  Container(height: 1, color: AppColors.border),
                  const SizedBox(height: AppSpacing.lg),

                  // Showtimes
                  Text('Chọn Suất Chiếu', style: AppTextStyles.titleMedium),
                  const SizedBox(height: AppSpacing.md),
                  _showtimes.isEmpty
                      ? _buildEmptyShowtimes()
                      : _buildShowtimeList(),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // === SLIVER APP BAR WITH POSTER ===
  SliverAppBar _buildSliverAppBar(BuildContext context) {
    final posterUrl = _movie!.posterUrl ?? '';
    return SliverAppBar(
      expandedHeight: 360,
      pinned: true,
      backgroundColor: AppColors.surface,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Poster image
            if (posterUrl.isNotEmpty)
              Image.network(posterUrl, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [Color(0xFF1E1B4B), Colors.black],
                    ),
                  ),
                  child: const Center(child: Icon(Icons.movie_rounded, size: 80, color: AppColors.textMuted)),
                ),
              )
            else
              Container(color: AppColors.surfaceHigh),
            // Gradient scrim
            const DecoratedBox(decoration: BoxDecoration(gradient: AppColors.posterScrim)),
            // Rating bottom-left
            Positioned(
              bottom: 16, left: AppSpacing.lg,
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: AppColors.accent, size: 18),
                  const SizedBox(width: 4),
                  Text('${_movie!.rating}', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time_rounded, color: AppColors.textSecondary, size: 16),
                  const SizedBox(width: 4),
                  Text('${_movie!.duration} phút', style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === METADATA ROW (rating, age, duration) ===
  Widget _buildMetadataRow() {
    return Row(
      children: [
        const Icon(Icons.star_rounded, color: AppColors.accent, size: 16),
        const SizedBox(width: 4),
        Text('${_movie!.rating}', style: AppTextStyles.bodyBold.copyWith(color: AppColors.accent)),
        const SizedBox(width: 12),
        AppBadge(label: _movie!.ageRating ?? 'P'),
        const SizedBox(width: 12),
        const Icon(Icons.access_time_rounded, color: AppColors.textMuted, size: 14),
        const SizedBox(width: 4),
        Text('${_movie!.duration} phút', style: AppTextStyles.body),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          text: '$label: ',
          style: AppTextStyles.body.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w600),
          children: [TextSpan(text: value, style: AppTextStyles.body)],
        ),
      ),
    );
  }

  Widget _buildEmptyShowtimes() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.event_busy_rounded, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text('Không có lịch chiếu khả dụng', style: AppTextStyles.body),
        ],
      ),
    );
  }

  // === SHOWTIME LIST (grouped by date) ===
  Widget _buildShowtimeList() {
    // Group by date
    final Map<String, List<Showtime>> grouped = {};
    for (final st in _showtimes) {
      final dateKey = DateFormat('dd/MM/yyyy').format(st.startTime);
      grouped.putIfAbsent(dateKey, () => []).add(st);
    }

    return Column(
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date label
            Padding(
              padding: const EdgeInsets.only(bottom: 10, top: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDim,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(entry.key,
                      style: GoogleFonts.robotoMono(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            // Showtime chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: entry.value.map((st) => _ShowtimeChip(showtime: st)).toList(),
            ),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }
}

// === SHOWTIME CHIP ===
class _ShowtimeChip extends StatelessWidget {
  final Showtime showtime;
  const _ShowtimeChip({required this.showtime});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final timeStr = DateFormat('HH:mm').format(showtime.startTime);
    final cinemaName = showtime.cinema?.name ?? 'Rạp';
    final roomName = showtime.room?.name ?? 'Phòng';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SeatSelectionScreen(showtimeId: showtime.id)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.05), blurRadius: 8)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(timeStr,
              style: GoogleFonts.robotoMono(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 4),
            Text(cinemaName, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
            Text(roomName, style: AppTextStyles.caption),
            const SizedBox(height: 4),
            Text(formatter.format(showtime.price),
              style: GoogleFonts.outfit(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
