import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/movie_service.dart';
import 'seat_selection_screen.dart';

class ShowtimeScreen extends StatefulWidget {
  final String? movieId;

  const ShowtimeScreen({super.key, this.movieId});

  @override
  State<ShowtimeScreen> createState() => _ShowtimeScreenState();
}

class _ShowtimeScreenState extends State<ShowtimeScreen> {
  bool _isLoading = false;
  List<dynamic> _showtimes = [];

  @override
  void initState() {
    super.initState();
    _loadShowtimes();
  }

  Future<void> _loadShowtimes() async {
    setState(() => _isLoading = true);
    try {
      final showtimes = await movieService.getShowtimes(movieId: widget.movieId);
      setState(() {
        _showtimes = showtimes;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải lịch chiếu: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        title: const Text('Lịch Chiếu Toàn Hệ Thống', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF16162A),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC084FC)))
          : RefreshIndicator(
              onRefresh: _loadShowtimes,
              color: const Color(0xFFC084FC),
              child: _showtimes.isEmpty
                  ? const Center(
                      child: Text('Không có suất chiếu nào gần đây', style: TextStyle(color: Colors.white54, fontSize: 16)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _showtimes.length,
                      itemBuilder: (context, index) {
                        final showtime = _showtimes[index];
                        final movie = showtime['movie'];
                        final room = showtime['room'];
                        final cinema = room?['cinema'];
                        final price = showtime['price'] ?? 0.0;
                        final startTime = DateTime.parse(showtime['startTime']).toLocal();

                        final timeStr = DateFormat('HH:mm').format(startTime);
                        final dateStr = DateFormat('dd/MM/yyyy').format(startTime);
                        final movieTitle = movie?['title'] ?? 'Phim';

                        return Card(
                          color: const Color(0xFF16162A),
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 50,
                                  height: 70,
                                  color: Colors.white12,
                                  child: movie?['posterUrl'] != null
                                      ? Image.network(movie['posterUrl'], fit: BoxFit.cover)
                                      : const Icon(Icons.movie, color: Colors.white30),
                                ),
                              ),
                              title: Text(
                                movieTitle,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Text(
                                  '${cinema?['name'] ?? 'Rạp'} • ${room?['name'] ?? 'Phòng'}\nNgày $dateStr • Giá vé: ${formatter.format(price)}',
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
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
