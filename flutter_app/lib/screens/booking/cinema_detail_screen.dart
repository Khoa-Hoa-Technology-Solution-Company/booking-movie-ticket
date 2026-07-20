import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../models/cinema.dart';
import '../../models/movie.dart';
import '../../models/showtime.dart';
import '../../services/location_service.dart';
import '../../services/movie_service.dart';
import 'seat_selection_screen.dart';

class CinemaDetailScreen extends StatefulWidget {
  final Cinema cinema;
  final CinemaDistanceResult? distanceResult;

  const CinemaDetailScreen({
    super.key,
    required this.cinema,
    this.distanceResult,
  });

  @override
  State<CinemaDetailScreen> createState() => _CinemaDetailScreenState();
}

class _CinemaDetailScreenState extends State<CinemaDetailScreen> {
  bool _isLoading = false;
  List<Showtime> _showtimes = [];
  List<DateTime> _availableDates = [];
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadShowtimes();
  }

  Future<void> _loadShowtimes() async {
    setState(() => _isLoading = true);
    try {
      final showtimes = await movieService.getShowtimes(cinemaId: widget.cinema.id);
      
      // Lọc các ngày duy nhất có suất chiếu (bỏ qua giờ phút giây)
      final Set<DateTime> datesSet = {};
      for (var st in showtimes) {
        datesSet.add(DateTime(st.startTime.year, st.startTime.month, st.startTime.day));
      }
      final sortedDates = datesSet.toList()..sort();

      setState(() {
        _showtimes = showtimes;
        _availableDates = sortedDates;
        if (sortedDates.isNotEmpty) {
          _selectedDate = sortedDates.first;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải lịch chiếu: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getWeekdayString(DateTime date) {
    switch (date.weekday) {
      case 1: return 'T2';
      case 2: return 'T3';
      case 3: return 'T4';
      case 4: return 'T5';
      case 5: return 'T6';
      case 6: return 'T7';
      case 7: return 'CN';
      default: return '';
    }
  }

  // Lọc danh sách showtimes theo ngày được chọn
  List<Showtime> _getShowtimesForSelectedDate() {
    if (_selectedDate == null) return [];
    return _showtimes.where((st) {
      return st.startTime.year == _selectedDate!.year &&
          st.startTime.month == _selectedDate!.month &&
          st.startTime.day == _selectedDate!.day;
    }).toList();
  }

  // Nhóm showtimes theo Phim
  Map<Movie, List<Showtime>> _groupShowtimesByMovie(List<Showtime> showtimes) {
    final Map<Movie, List<Showtime>> map = {};
    for (var st in showtimes) {
      final movie = st.movie;
      if (movie != null) {
        final existingMovie = map.keys.firstWhere(
          (m) => m.id == movie.id,
          orElse: () => movie,
        );
        map.putIfAbsent(existingMovie, () => []).add(st);
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context); // Đăng ký lắng nghe sự kiện đổi theme để vẽ lại giao diện lập tức
    final filteredShowtimes = _getShowtimesForSelectedDate();
    final groupedMovies = _groupShowtimesByMovie(filteredShowtimes);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.cinema.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header info rạp
          _buildCinemaHeader(),

          // Date selector
          if (!_isLoading && _availableDates.isNotEmpty) _buildDateSelector(),

          // Movie list & showtimes
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _showtimes.isEmpty
                    ? _buildEmptyState('Rạp chưa có lịch chiếu nào gần đây.')
                    : filteredShowtimes.isEmpty
                        ? _buildEmptyState('Không có suất chiếu nào vào ngày này.')
                        : _buildMovieList(groupedMovies),
          ),
        ],
      ),
    );
  }

  Widget _buildCinemaHeader() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryDim,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.movie_creation_outlined, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.cinema.name,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.cinema.address,
                      style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (widget.distanceResult != null)
                GestureDetector(
                  onTap: (widget.cinema.latitude != null && widget.cinema.longitude != null)
                      ? () async {
                          final url = Uri.parse(
                            'https://www.google.com/maps/dir/?api=1&destination=${widget.cinema.latitude},${widget.cinema.longitude}',
                          );
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          } else {
                            await launchUrl(url, mode: LaunchMode.platformDefault);
                          }
                        }
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDim,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.near_me_rounded, color: AppColors.primary, size: 10),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.distanceResult!.distanceText} • ${widget.distanceResult!.durationText}',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                AppBadge(
                  label: widget.cinema.city,
                  color: Colors.white10,
                  textColor: AppColors.textSecondary,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      height: 76,
      color: AppColors.surface,
      padding: const EdgeInsets.only(bottom: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _availableDates.length,
        itemBuilder: (context, index) {
          final date = _availableDates[index];
          final isSelected = _selectedDate != null &&
              _selectedDate!.year == date.year &&
              _selectedDate!.month == date.month &&
              _selectedDate!.day == date.day;

          final weekdayStr = _getWeekdayString(date);
          final dayStr = DateFormat('dd').format(date);
          final monthStr = 'Th ${DateFormat('MM').format(date)}';

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              width: 64,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    weekdayStr,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: isSelected ? Colors.white70 : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dayStr,
                    style: GoogleFonts.robotoMono(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    monthStr,
                    style: GoogleFonts.outfit(
                      fontSize: 9,
                      color: isSelected ? Colors.white70 : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_rounded, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieList(Map<Movie, List<Showtime>> groupedMovies) {
    final list = groupedMovies.entries.toList();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final entry = list[index];
        final movie = entry.key;
        final showtimes = entry.value;

        return Card(
          color: AppColors.surface,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Poster phim
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 70,
                        height: 100,
                        color: Colors.white.withOpacity(0.05),
                        child: movie.posterUrl != null && movie.posterUrl!.isNotEmpty
                            ? Image.network(movie.posterUrl!, fit: BoxFit.cover)
                            : Icon(Icons.movie_outlined, color: AppColors.textMuted),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Thông tin chi tiết phim
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            movie.title,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (movie.genre != null)
                            Text(
                              movie.genre!,
                              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                            ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.access_time_rounded, color: AppColors.textMuted, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                '${movie.duration} phút',
                                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                              ),
                              if (movie.rating > 0) ...[
                                const SizedBox(width: 12),
                                Icon(Icons.star_rounded, color: AppColors.accent, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  movie.rating.toStringAsFixed(1),
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (movie.ageRating != null) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                movie.ageRating!,
                                style: GoogleFonts.robotoMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 12),
                // Wrap danh sách suất chiếu
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: showtimes.map((st) {
                    final timeStr = DateFormat('HH:mm').format(st.startTime);
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SeatSelectionScreen(showtimeId: st.id),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDim,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                        ),
                        child: Text(
                          timeStr,
                          style: GoogleFonts.robotoMono(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
