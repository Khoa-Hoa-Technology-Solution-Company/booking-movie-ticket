import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/showtime.dart';
import '../../services/movie_service.dart';
import 'seat_selection_screen.dart';
import '../../widgets/booking_components.dart';

class ShowtimeScreen extends StatefulWidget {
  final int? movieId;

  const ShowtimeScreen({super.key, this.movieId});

  @override
  State<ShowtimeScreen> createState() => _ShowtimeScreenState();
}

class _ShowtimeScreenState extends State<ShowtimeScreen> {
  bool _isLoading = false;
  List<Showtime> _showtimes = [];

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
                        return ShowtimeListTile(
                          showtime: showtime,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SeatSelectionScreen(showtimeId: showtime.id),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
    );
  }
}
