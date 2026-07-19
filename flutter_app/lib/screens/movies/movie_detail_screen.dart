import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/movie.dart';
import '../../models/showtime.dart';
import '../../services/movie_service.dart';
import '../booking/seat_selection_screen.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/location_service.dart';
import '../../models/cinema.dart';
import '../../widgets/booking_components.dart';

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

  // Bộ lọc Hãng Rạp & Ngày Xem
  String? _selectedBrand;
  DateTime? _selectedDate;

  // Định vị rạp chiếu phim gần đây
  Map<int, CinemaDistanceResult> _cinemaDistances = {};

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
      
      // Chỉ giữ lại các suất chiếu chưa diễn ra (trong tương lai)
      final now = DateTime.now();
      final futureShowtimes = showtimes.where((st) => st.startTime.isAfter(now)).toList();
      
      setState(() {
        _movie = movie;
        _showtimes = futureShowtimes;

        // Cài đặt mặc định hãng rạp và ngày xem đầu tiên có sẵn
        final brands = getAvailableBrands();
        if (brands.isNotEmpty) {
          _selectedBrand = brands.contains('CGV') ? 'CGV' : brands.first;
          final dates = getAvailableDatesForBrand(_selectedBrand);
          if (dates.isNotEmpty) {
            _selectedDate = dates.first;
          }
        }
      });

      // Lấy toạ độ GPS và tính toán khoảng cách
      _fetchLocationAndDistances(futureShowtimes);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không thể tải chi tiết phim: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchLocationAndDistances(List<Showtime> showtimes) async {
    final cinemas = showtimes
        .map((st) => st.cinema)
        .whereType<Cinema>()
        // Loại bỏ rạp trùng lặp
        .fold<Map<int, Cinema>>({}, (map, c) => map..putIfAbsent(c.id, () => c))
        .values
        .toList();

    if (cinemas.isEmpty) return;

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
            _cinemaDistances = distances;
          });
        }
      }
    } catch (e) {
      debugPrint('Lỗi tải vị trí rạp chi tiết: $e');
    }
  }

  // --- HÀM TRỢ GIÚP BỘ LỌC LỊCH CHIẾU ---
  
  Set<String> getAvailableBrands() {
    final brands = <String>{};
    for (final st in _showtimes) {
      final name = st.cinema?.name ?? '';
      if (name.toUpperCase().startsWith('CGV')) {
        brands.add('CGV');
      } else if (name.toUpperCase().startsWith('LOTTE')) {
        brands.add('Lotte');
      } else if (name.toUpperCase().startsWith('GALAXY')) {
        brands.add('Galaxy');
      } else if (name.toUpperCase().startsWith('BHD')) {
        brands.add('BHD');
      } else {
        final firstWord = name.split(' ').first;
        if (firstWord.isNotEmpty) brands.add(firstWord);
      }
    }
    return brands;
  }

  List<DateTime> getAvailableDatesForBrand(String? brand) {
    final dates = <DateTime>[];
    final dateKeys = <String>{};
    for (final st in _showtimes) {
      if (brand != null && !_cinemaMatchesBrand(st.cinema?.name, brand)) {
        continue;
      }
      final dateKey = DateFormat('yyyy-MM-dd').format(st.startTime);
      if (!dateKeys.contains(dateKey)) {
        dateKeys.add(dateKey);
        dates.add(DateTime(st.startTime.year, st.startTime.month, st.startTime.day));
      }
    }
    dates.sort();
    return dates;
  }

  Map<Cinema, List<Showtime>> getShowtimesForBrandAndDate(String? brand, DateTime? date) {
    final Map<Cinema, List<Showtime>> grouped = {};
    if (date == null) return grouped;

    final targetDateStr = DateFormat('yyyy-MM-dd').format(date);
    for (final st in _showtimes) {
      if (brand != null && !_cinemaMatchesBrand(st.cinema?.name, brand)) {
        continue;
      }
      final stDateStr = DateFormat('yyyy-MM-dd').format(st.startTime);
      if (stDateStr == targetDateStr) {
        if (st.cinema != null) {
          final existingCinema = grouped.keys.firstWhere(
            (c) => c.id == st.cinema!.id,
            orElse: () => st.cinema!,
          );
          grouped.putIfAbsent(existingCinema, () => []).add(st);
        }
      }
    }
    return grouped;
  }

  bool _cinemaMatchesBrand(String? name, String brand) {
    if (name == null) return false;
    return name.toUpperCase().startsWith(brand.toUpperCase());
  }

  String _getWeekdayString(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Hôm nay';
    }
    final tomorrow = now.add(const Duration(days: 1));
    if (date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day) {
      return 'Ngày mai';
    }

    switch (date.weekday) {
      case DateTime.monday: return 'Thứ 2';
      case DateTime.tuesday: return 'Thứ 3';
      case DateTime.wednesday: return 'Thứ 4';
      case DateTime.thursday: return 'Thứ 5';
      case DateTime.friday: return 'Thứ 6';
      case DateTime.saturday: return 'Thứ 7';
      case DateTime.sunday: return 'Chủ Nhật';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context); // Đăng ký lắng nghe sự kiện đổi theme để vẽ lại giao diện lập tức
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (_movie == null) {
      return Scaffold(
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
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBrandSelector(),
                            const SizedBox(height: AppSpacing.md),
                            _buildDateSelector(),
                            const SizedBox(height: AppSpacing.lg),
                            _buildGroupedShowtimes(),
                          ],
                        ),
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
                  child: Center(child: Icon(Icons.movie_rounded, size: 80, color: AppColors.textMuted)),
                ),
              )
            else
              Container(color: AppColors.surfaceHigh),
            // Gradient scrim
            DecoratedBox(decoration: BoxDecoration(gradient: AppColors.posterScrim)),
            // Rating bottom-left
            Positioned(
              bottom: 16, left: AppSpacing.lg,
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: AppColors.accent, size: 18),
                  const SizedBox(width: 4),
                  Text('${_movie!.rating}', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time_rounded, color: AppColors.textSecondary, size: 16),
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
        Icon(Icons.access_time_rounded, color: AppColors.textMuted, size: 14),
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
    if (_movie?.status == MovieStatus.comingSoon) {
      final releaseDateStr = _movie!.releaseDate != null
          ? DateFormat('dd/MM/yyyy').format(_movie!.releaseDate!)
          : 'Sắp ra mắt';
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(Icons.stars_rounded, size: 48, color: AppColors.accent),
            const SizedBox(height: 12),
            Text(
              'Phim Sắp Khởi Chiếu',
              style: AppTextStyles.bodyBold.copyWith(color: AppColors.accent, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Dự kiến công chiếu: $releaseDateStr',
              style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            Text(
              'Suất chiếu sẽ được mở bán khi phim chính thức công chiếu.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.event_busy_rounded, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text('Không có lịch chiếu khả dụng', style: AppTextStyles.body),
        ],
      ),
    );
  }

  // === BRAND SELECTOR ===
  Widget _buildBrandSelector() {
    final brands = getAvailableBrands().toList();
    if (brands.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hãng Rạp', style: AppTextStyles.bodyBold.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: brands.length,
            itemBuilder: (context, index) {
              final brand = brands[index];
              final isSelected = _selectedBrand == brand;

              Color brandColor = AppColors.primary;
              if (brand.toUpperCase() == 'CGV') brandColor = const Color(0xFFE50914);
              if (brand.toUpperCase() == 'LOTTE') brandColor = const Color(0xFFD32F2F);
              if (brand.toUpperCase() == 'GALAXY') brandColor = const Color(0xFFFF9800);
              if (brand.toUpperCase() == 'BHD') brandColor = const Color(0xFF4CAF50);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedBrand = brand;
                    final dates = getAvailableDatesForBrand(brand);
                    _selectedDate = dates.isNotEmpty ? dates.first : null;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? brandColor.withOpacity(0.15) : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? brandColor : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(color: brandColor.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))
                    ] : null,
                  ),
                  child: Center(
                    child: Text(
                      brand,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? brandColor : AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // === DATE SELECTOR ===
  Widget _buildDateSelector() {
    final dates = getAvailableDatesForBrand(_selectedBrand);
    if (dates.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ngày Xem', style: AppTextStyles.bodyBold.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: 76,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: dates.length,
            itemBuilder: (context, index) {
              final date = dates[index];
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
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: 1,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                    ] : null,
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
        ),
      ],
    );
  }

  // === GROUPED SHOWTIMES BY CINEMA ===
  Widget _buildGroupedShowtimes() {
    final grouped = getShowtimesForBrandAndDate(_selectedBrand, _selectedDate);
    if (grouped.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.event_busy_rounded, size: 40, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text('Không có suất chiếu vào ngày này', style: AppTextStyles.body),
          ],
        ),
      );
    }

    return Column(
      children: grouped.entries.map((entry) {
        final cinema = entry.key;
        final showtimes = entry.value;
        final distanceResult = _cinemaDistances[cinema.id];

        return CinemaShowtimeCard(
          cinema: cinema,
          showtimes: showtimes,
          distanceResult: distanceResult,
          onShowtimeTap: (st) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SeatSelectionScreen(showtimeId: st.id)),
            );
          },
        );
      }).toList(),
    );
  }
}
