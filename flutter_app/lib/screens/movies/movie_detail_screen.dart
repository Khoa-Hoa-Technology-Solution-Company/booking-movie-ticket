import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/movie_service.dart';
import '../booking/seat_selection_screen.dart';

class MovieDetailScreen extends StatefulWidget {
  final String movieId;

  const MovieDetailScreen({super.key, required this.movieId});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _movie;
  List<dynamic> _showtimes = [];

  @override
  void initState() {
    super.initState();
    _loadMovieDetail();
  }

  Future<void> _loadMovieDetail() async {
    setState(() => _isLoading = true);
    try {
      final movie = await movieService.getMovieById(widget.movieId);
      setState(() {
        _movie = movie;
        _showtimes = movie['showtimes'] ?? [];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải chi tiết phim: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F1A),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFC084FC))),
      );
    }

    if (_movie == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F1A),
        body: Center(child: Text('Không tìm thấy thông tin phim', style: TextStyle(color: Colors.white54))),
      );
    }

    final posterUrl = _movie!['posterUrl'] ?? '';
    final rating = _movie!['rating'] ?? 0.0;
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Movie Poster Header Image with Back Button
            Stack(
              children: [
                Container(
                  height: 380,
                  foregroundDecoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Color(0xFF0F0F1A),
                      ],
                    ),
                  ),
                  child: Image.network(
                    posterUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.deepPurple.shade900, Colors.black],
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.movie_rounded, size: 80, color: Colors.white30),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),

            // Movie Information Detail
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _movie!['title'] ?? '',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Metadata Badges (Rating, Age, Duration, Genre)
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '$rating',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC084FC).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _movie!['ageRating'] ?? 'P',
                          style: const TextStyle(color: Color(0xFFC084FC), fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${_movie!['duration']} phút',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text(
                    _movie!['genre'] ?? '',
                    style: const TextStyle(color: Color(0xFFC084FC), fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Description
                  const Text(
                    'Nội dung phim',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _movie!['description'] ?? '',
                    style: const TextStyle(color: Colors.white70, height: 1.4, fontSize: 14),
                  ),
                  const SizedBox(height: 20),

                  // Cast & Crew
                  if (_movie!['director'] != null) ...[
                    RichText(
                      text: TextSpan(
                        text: 'Đạo diễn: ',
                        style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold),
                        children: [
                          TextSpan(text: _movie!['director'], style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.normal)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (_movie!['cast'] != null) ...[
                    RichText(
                      text: TextSpan(
                        text: 'Diễn viên: ',
                        style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold),
                        children: [
                          TextSpan(text: _movie!['cast'], style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.normal)),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 16),

                  // Showtimes list Grouped by Cinema
                  const Text(
                    'Chọn Suất Chiếu & Lịch Chiếu',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  _showtimes.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.0),
                            child: Text(
                              'Không có lịch chiếu nào khả dụng gần đây.',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _showtimes.length,
                          itemBuilder: (context, index) {
                            final showtime = _showtimes[index];
                            final startTime = DateTime.parse(showtime['startTime']).toLocal();
                            final roomName = showtime['room']?['name'] ?? 'Phòng';
                            final cinemaName = showtime['room']?['cinema']?['name'] ?? 'Rạp';
                            final price = showtime['price'] ?? 0.0;

                            final timeStr = DateFormat('HH:mm').format(startTime);
                            final dateStr = DateFormat('dd/MM/yyyy').format(startTime);

                            return Card(
                              color: const Color(0xFF16162A),
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                title: Text(
                                  cinemaName,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    '$roomName • Ngày $dateStr • Giá vé: ${formatter.format(price)}',
                                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                                  ),
                                ),
                                trailing: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SeatSelectionScreen(showtimeId: showtime['id']),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFC084FC),
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: Text(
                                    timeStr,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
