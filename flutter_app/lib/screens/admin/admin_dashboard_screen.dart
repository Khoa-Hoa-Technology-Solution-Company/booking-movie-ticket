import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/admin_service.dart';
import '../../services/movie_service.dart';
import '../../models/movie.dart';
import '../../models/showtime.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        title: const Text('Quản Trị Hệ Thống', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF16162A),
        elevation: 0,
        centerTitle: true,
      ),
      body: IndexedStack(
        index: _currentTab,
        children: const [
          _AdminMoviesTab(),
          _AdminShowtimesTab(),
          _AdminCheckInTab(),
          _AdminPromotionsTab(),
          _AdminUsersTab(),
          _AdminAnalyticsTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (index) {
          setState(() => _currentTab = index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF16162A),
        selectedItemColor: const Color(0xFFC084FC),
        unselectedItemColor: Colors.white30,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        iconSize: 18,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.movie_rounded),
            label: 'Phim',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule_rounded),
            label: 'Suất Chiếu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner_rounded),
            label: 'Check-in',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer_rounded),
            label: 'Mã Giảm',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_rounded),
            label: 'User',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_rounded),
            label: 'Thống Kê',
          ),
        ],
      ),
    );
  }
}

// ========================================================
// 1. TAB QUẢN LÝ PHIM (CRUD MOVIES)
// ========================================================
class _AdminMoviesTab extends StatefulWidget {
  const _AdminMoviesTab();

  @override
  State<_AdminMoviesTab> createState() => _AdminMoviesTabState();
}

class _AdminMoviesTabState extends State<_AdminMoviesTab> {
  bool _isLoading = false;
  List<Movie> _movies = [];

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  Future<void> _loadMovies() async {
    setState(() => _isLoading = true);
    try {
      final nowShowing = await movieService.getNowShowing();
      final comingSoon = await movieService.getComingSoon();
      setState(() {
        _movies = [...nowShowing, ...comingSoon];
      });
    } catch (e) {
      _showSnackBar('Lỗi tải phim: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: color),
      );
    }
  }

  Future<void> _deleteMovie(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16162A),
        title: const Text('Xác nhận xóa', style: TextStyle(color: Colors.white)),
        content: const Text('Bạn có chắc chắn muốn xóa phim này khỏi hệ thống?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await adminService.deleteMovie(id);
        _showSnackBar('Đã xóa phim thành công!', Colors.green);
        _loadMovies();
      } catch (e) {
        _showSnackBar('Xóa phim thất bại: $e', Colors.red);
      }
    }
  }

  void _openMovieForm([Movie? movie]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16162A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => _MovieFormBottomSheet(
        movie: movie,
        onSaved: () {
          Navigator.pop(context);
          _loadMovies();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openMovieForm(),
        backgroundColor: const Color(0xFFC084FC),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC084FC)))
          : RefreshIndicator(
              onRefresh: _loadMovies,
              child: _movies.isEmpty
                  ? const Center(child: Text('Chưa có phim nào', style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _movies.length,
                      itemBuilder: (context, index) {
                        final movie = _movies[index];
                        return Card(
                          color: const Color(0xFF1E1B4B).withOpacity(0.4),
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 45,
                                height: 60,
                                child: movie.posterUrl != null
                                    ? Image.network(movie.posterUrl!, fit: BoxFit.cover)
                                    : const Icon(Icons.movie, color: Colors.white24),
                              ),
                            ),
                            title: Text(movie.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Text('${movie.genre} • ${movie.duration} phút\nTrạng thái: ${movie.status.name.toUpperCase()}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(Icons.edit, color: Color(0xFFC084FC), size: 20), onPressed: () => _openMovieForm(movie)),
                                IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20), onPressed: () => _deleteMovie(movie.id)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

// Form Add/Edit Movie
class _MovieFormBottomSheet extends StatefulWidget {
  final Movie? movie;
  final VoidCallback onSaved;

  const _MovieFormBottomSheet({this.movie, required this.onSaved});

  @override
  State<_MovieFormBottomSheet> createState() => _MovieFormBottomSheetState();
}

class _MovieFormBottomSheetState extends State<_MovieFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _posterController = TextEditingController();
  final _trailerController = TextEditingController();
  final _durationController = TextEditingController();
  final _genreController = TextEditingController();
  final _directorController = TextEditingController();
  final _castController = TextEditingController();

  String _ageRating = 'P';
  String _status = 'NOW_SHOWING';
  DateTime? _releaseDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.movie != null) {
      final m = widget.movie!;
      _titleController.text = m.title;
      _descController.text = m.description;
      _posterController.text = m.posterUrl ?? '';
      _trailerController.text = m.trailerUrl ?? '';
      _durationController.text = m.duration.toString();
      _genreController.text = m.genre ?? '';
      _directorController.text = m.director ?? '';
      _castController.text = m.cast ?? '';
      _ageRating = m.ageRating ?? 'P';
      _status = m.status == MovieStatus.nowShowing
          ? 'NOW_SHOWING'
          : m.status == MovieStatus.comingSoon
              ? 'COMING_SOON'
              : 'ENDED';
      _releaseDate = m.releaseDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _posterController.dispose();
    _trailerController.dispose();
    _durationController.dispose();
    _genreController.dispose();
    _directorController.dispose();
    _castController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_releaseDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn ngày phát hành'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isSaving = true);
    final data = {
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'poster_url': _posterController.text.trim().isEmpty ? null : _posterController.text.trim(),
      'trailer_url': _trailerController.text.trim().isEmpty ? null : _trailerController.text.trim(),
      'duration': int.parse(_durationController.text),
      'genre': _genreController.text.trim(),
      'director': _directorController.text.trim(),
      'cast': _castController.text.trim(),
      'age_rating': _ageRating,
      'status': _status,
      'release_date': DateFormat('yyyy-MM-dd').format(_releaseDate!),
    };

    try {
      if (widget.movie == null) {
        await adminService.addMovie(data);
      } else {
        await adminService.updateMovie(widget.movie!.id, data);
      }
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lưu phim thất bại: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 20 + bottomInset),
      height: MediaQuery.of(context).size.height * 0.85,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.movie == null ? 'Thêm Phim Mới' : 'Cập Nhật Thông Tin Phim',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Title
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Tên phim', labelStyle: TextStyle(color: Colors.white70)),
                validator: (v) => v == null || v.trim().isEmpty ? 'Nhập tên phim' : null,
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: _descController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Mô tả ngắn', labelStyle: TextStyle(color: Colors.white70)),
                validator: (v) => v == null || v.trim().isEmpty ? 'Nhập mô tả' : null,
              ),
              const SizedBox(height: 12),

              // Duration & Genre
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Thời lượng (phút)', labelStyle: TextStyle(color: Colors.white70)),
                      validator: (v) => v == null || int.tryParse(v) == null ? 'Nhập thời lượng' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _genreController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Thể loại', labelStyle: TextStyle(color: Colors.white70)),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Nhập thể loại' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Age Rating & Status
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _ageRating,
                      dropdownColor: const Color(0xFF16162A),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Giới hạn độ tuổi', labelStyle: TextStyle(color: Colors.white70)),
                      items: ['P', 'C13', 'C16', 'C18'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                      onChanged: (v) => setState(() => _ageRating = v ?? 'P'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _status,
                      dropdownColor: const Color(0xFF16162A),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Trạng thái', labelStyle: TextStyle(color: Colors.white70)),
                      items: [
                        DropdownMenuItem(value: 'NOW_SHOWING', child: Text('Đang chiếu'.toUpperCase())),
                        DropdownMenuItem(value: 'COMING_SOON', child: Text('Sắp chiếu'.toUpperCase())),
                        DropdownMenuItem(value: 'ENDED', child: Text('Dừng chiếu'.toUpperCase())),
                      ].toList(),
                      onChanged: (v) => setState(() => _status = v ?? 'NOW_SHOWING'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Director & Cast
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _directorController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Đạo diễn', labelStyle: TextStyle(color: Colors.white70)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _castController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Diễn viên', labelStyle: TextStyle(color: Colors.white70)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Poster & Trailer URLs
              TextFormField(
                controller: _posterController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'URL Ảnh Poster', labelStyle: TextStyle(color: Colors.white70)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _trailerController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'URL Trailer Youtube (nếu có)', labelStyle: TextStyle(color: Colors.white70)),
              ),
              const SizedBox(height: 16),

              // Release Date
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _releaseDate == null
                      ? 'Chọn ngày phát hành'
                      : 'Ngày phát hành: ${DateFormat('dd/MM/yyyy').format(_releaseDate!)}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                trailing: const Icon(Icons.calendar_month, color: Color(0xFFC084FC)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _releaseDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => _releaseDate = picked);
                  }
                },
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC084FC),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : const Text('Lưu thông tin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ========================================================
// 2. TAB QUẢN LÝ SUẤT CHIẾU (SHOWTIME MANAGEMENT)
// ========================================================
class _AdminShowtimesTab extends StatefulWidget {
  const _AdminShowtimesTab();

  @override
  State<_AdminShowtimesTab> createState() => _AdminShowtimesTabState();
}

class _AdminShowtimesTabState extends State<_AdminShowtimesTab> {
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
      final showtimes = await movieService.getShowtimes();
      setState(() {
        _showtimes = showtimes;
      });
    } catch (e) {
      _showSnackBar('Lỗi tải lịch chiếu: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: color),
      );
    }
  }

  Future<void> _deleteShowtime(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16162A),
        title: const Text('Xác nhận xóa', style: TextStyle(color: Colors.white)),
        content: const Text('Bạn có muốn xóa lịch chiếu này không?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await adminService.deleteShowtime(id);
        _showSnackBar('Đã xóa lịch chiếu thành công!', Colors.green);
        _loadShowtimes();
      } catch (e) {
        _showSnackBar('Xóa lịch chiếu thất bại: $e', Colors.red);
      }
    }
  }

  void _openShowtimeForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16162A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => _ShowtimeFormBottomSheet(
        onSaved: () {
          Navigator.pop(context);
          _loadShowtimes();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _openShowtimeForm,
        backgroundColor: const Color(0xFFC084FC),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC084FC)))
          : RefreshIndicator(
              onRefresh: _loadShowtimes,
              child: _showtimes.isEmpty
                  ? const Center(child: Text('Chưa có suất chiếu nào', style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _showtimes.length,
                      itemBuilder: (context, index) {
                        final st = _showtimes[index];
                        final movieTitle = st.movie?.title ?? 'Phim';
                        final startStr = DateFormat('dd/MM/yyyy HH:mm').format(st.startTime);
                        final endStr = DateFormat('HH:mm').format(st.endTime);

                        return Card(
                          color: const Color(0xFF1E1B4B).withOpacity(0.4),
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            title: Text(movieTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                '${st.cinema?.name} - ${st.room?.name} (${st.room?.roomType})\n$startStr - $endStr\nGiá vé: ${formatter.format(st.price)}',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                              onPressed: () => _deleteShowtime(st.id),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

// Add Showtime Form
class _ShowtimeFormBottomSheet extends StatefulWidget {
  final VoidCallback onSaved;

  const _ShowtimeFormBottomSheet({required this.onSaved});

  @override
  State<_ShowtimeFormBottomSheet> createState() => _ShowtimeFormBottomSheetState();
}

class _ShowtimeFormBottomSheetState extends State<_ShowtimeFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();

  List<Movie> _movies = [];
  List<Map<String, dynamic>> _rooms = [];

  int? _selectedMovieId;
  int? _selectedRoomId;
  DateTime? _selectedDateTime;
  bool _isLoadingData = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadFormData();
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadFormData() async {
    try {
      final nowShowing = await movieService.getNowShowing();
      final rooms = await adminService.getRooms();
      setState(() {
        _movies = nowShowing;
        _rooms = rooms;
        _isLoadingData = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu mẫu: $e'), backgroundColor: Colors.red));
      Navigator.pop(context);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMovieId == null || _selectedRoomId == null || _selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isSaving = true);
    
    // Tìm phim để lấy thời lượng tính toán end_time
    final selectedMovie = _movies.firstWhere((m) => m.id == _selectedMovieId);
    final endTime = _selectedDateTime!.add(Duration(minutes: selectedMovie.duration + 15)); // 15 phút dọn phòng

    final data = {
      'movie_id': _selectedMovieId,
      'room_id': _selectedRoomId,
      'start_time': _selectedDateTime!.toUtc().toIso8601String(),
      'end_time': endTime.toUtc().toIso8601String(),
      'price': double.parse(_priceController.text),
    };

    try {
      await adminService.addShowtime(data);
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 20 + bottomInset),
      height: MediaQuery.of(context).size.height * 0.7,
      child: _isLoadingData
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC084FC)))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Tạo Suất Chiếu Mới',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Dropdown Movie
                    DropdownButtonFormField<int>(
                      dropdownColor: const Color(0xFF16162A),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Chọn phim', labelStyle: TextStyle(color: Colors.white70)),
                      items: _movies.map((m) => DropdownMenuItem(value: m.id, child: Text(m.title, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (v) => setState(() => _selectedMovieId = v),
                      validator: (v) => v == null ? 'Vui lòng chọn phim' : null,
                    ),
                    const SizedBox(height: 12),

                    // Dropdown Room
                    DropdownButtonFormField<int>(
                      dropdownColor: const Color(0xFF16162A),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Chọn phòng chiếu', labelStyle: TextStyle(color: Colors.white70)),
                      items: _rooms.map((r) {
                        final cinemaName = r['cinemas'] != null ? r['cinemas']['name'] : 'Rạp';
                        return DropdownMenuItem(
                          value: r['id'] as int,
                          child: Text('$cinemaName - ${r['name']} (${r['room_type']})', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedRoomId = v),
                      validator: (v) => v == null ? 'Vui lòng chọn phòng' : null,
                    ),
                    const SizedBox(height: 12),

                    // Price Input
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Giá vé cơ bản (đ)', labelStyle: TextStyle(color: Colors.white70)),
                      validator: (v) => v == null || double.tryParse(v) == null ? 'Nhập giá vé hợp lệ' : null,
                    ),
                    const SizedBox(height: 16),

                    // Showtime Date Time Picker
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _selectedDateTime == null
                            ? 'Chọn thời gian chiếu'
                            : 'Bắt đầu: ${DateFormat('dd/MM/yyyy HH:mm').format(_selectedDateTime!)}',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      trailing: const Icon(Icons.access_time_rounded, color: Color(0xFFC084FC)),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (date != null && mounted) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 9, minute: 0),
                          );
                          if (time != null) {
                            setState(() {
                              _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                            });
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Create Button
                    ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC084FC),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                          : const Text('Thêm suất chiếu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}


// ========================================================
// 3. TAB CHECK-IN VÉ (MANUAL CHECK-IN / QUICK TEST LIST)
// ========================================================
class _AdminCheckInTab extends StatefulWidget {
  const _AdminCheckInTab();

  @override
  State<_AdminCheckInTab> createState() => _AdminCheckInTabState();
}

class _AdminCheckInTabState extends State<_AdminCheckInTab> {
  final _codeController = TextEditingController();
  bool _isChecking = false;
  bool _isLoadingList = false;
  List<dynamic> _activeTickets = [];
  Map<String, dynamic>? _ticketInfo;
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadActiveTickets();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadActiveTickets() async {
    setState(() => _isLoadingList = true);
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('tickets')
          .select('*, bookings(*, showtimes(*, movies(*)), booking_seats(*, seats(*)))')
          .eq('status', 'ACTIVE')
          .order('created_at', ascending: false)
          .limit(10);
      setState(() {
        _activeTickets = response as List;
      });
    } catch (e) {
      debugPrint('Lỗi tải danh sách vé active: $e');
    } finally {
      setState(() => _isLoadingList = false);
    }
  }

  Future<void> _handleCheckIn(String code) async {
    if (code.trim().isEmpty) return;

    setState(() {
      _isChecking = true;
      _ticketInfo = null;
      _statusMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('tickets')
          .select('*, bookings(*, showtimes(*, rooms(*), movies(*)), booking_seats(*, seats(*)))')
          .eq('ticket_code', code.trim().toUpperCase())
          .maybeSingle();

      if (response == null) {
        setState(() {
          _statusMessage = 'Mã vé không tồn tại trên hệ thống!';
          _isSuccess = false;
        });
        return;
      }

      final ticketStatus = response['status'] as String;

      if (ticketStatus == 'USED') {
        setState(() {
          _statusMessage = 'Vé này đã được sử dụng trước đó!';
          _isSuccess = false;
          _ticketInfo = response;
        });
        return;
      }

      if (ticketStatus == 'EXPIRED' || ticketStatus == 'CANCELLED') {
        setState(() {
          _statusMessage = 'Vé này đã hết hạn hoặc bị hủy!';
          _isSuccess = false;
          _ticketInfo = response;
        });
        return;
      }

      // Đánh dấu vé thành USED
      await supabase
          .from('tickets')
          .update({'status': 'USED'})
          .eq('ticket_code', code.trim().toUpperCase());

      setState(() {
        _statusMessage = 'Check-in thành công! Vé hợp lệ.';
        _isSuccess = true;
        _ticketInfo = response;
      });

      _loadActiveTickets(); // Reload list
    } catch (e) {
      setState(() {
        _statusMessage = 'Lỗi check-in: $e';
        _isSuccess = false;
      });
    } finally {
      setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Manual Checkin Input Box
          Card(
            color: const Color(0xFF16162A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Soát vé & Check-in', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _codeController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Nhập mã vé (ví dụ: TKT-...)',
                            hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isChecking ? null : () => _handleCheckIn(_codeController.text),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC084FC),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isChecking
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                            : const Text('Check-in', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Check-in status display
          if (_statusMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isSuccess ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _isSuccess ? Colors.green : Colors.red),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_isSuccess ? Icons.check_circle_rounded : Icons.error_rounded, color: _isSuccess ? Colors.green : Colors.red),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: TextStyle(color: _isSuccess ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  if (_ticketInfo != null) ...[
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 6),
                    Text('Phim: ${_ticketInfo!['bookings']?['showtimes']?['movies']?['title'] ?? 'N/A'}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    Text('Phòng: ${_ticketInfo!['bookings']?['showtimes']?['rooms']?['name'] ?? 'N/A'}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    Text('Lịch chiếu: ${DateFormat('dd/MM HH:mm').format(DateTime.parse(_ticketInfo!['bookings']?['showtimes']?['start_time']))}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Quick testing list
          const Text('Vé chưa check-in mới bán', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoadingList
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFC084FC)))
                : _activeTickets.isEmpty
                    ? const Center(child: Text('Không có vé nào cần check-in', style: TextStyle(color: Colors.white24)))
                    : ListView.builder(
                        itemCount: _activeTickets.length,
                        itemBuilder: (context, index) {
                          final ticket = _activeTickets[index];
                          final code = ticket['ticket_code'] as String;
                          final movieTitle = ticket['bookings']?['showtimes']?['movies']?['title'] ?? 'Phim';
                          final seatsList = ticket['bookings']?['booking_seats'] as List? ?? [];
                          final seatNames = seatsList.map((s) => s['seats'] != null ? '${s['seats']['row']}${s['seats']['number']}' : '').join(', ');

                          return Card(
                            color: const Color(0xFF1E1B4B).withOpacity(0.2),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(code, style: const TextStyle(color: Color(0xFFC084FC), fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Text('$movieTitle • Ghế: $seatNames', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.white12, foregroundColor: Colors.white),
                                onPressed: () {
                                  _codeController.text = code;
                                  _handleCheckIn(code);
                                },
                                child: const Text('Quét vé', style: TextStyle(fontSize: 11)),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}


// ========================================================
// 4. TAB QUẢN LÝ MÃ KHUYẾN MÃI (PROMOTIONS CRUD)
// ========================================================
class _AdminPromotionsTab extends StatefulWidget {
  const _AdminPromotionsTab();

  @override
  State<_AdminPromotionsTab> createState() => _AdminPromotionsTabState();
}

class _AdminPromotionsTabState extends State<_AdminPromotionsTab> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _promos = [];

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  Future<void> _loadPromotions() async {
    setState(() => _isLoading = true);
    try {
      final promos = await adminService.getPromotions();
      setState(() {
        _promos = promos;
      });
    } catch (e) {
      _showSnackBar('Lỗi tải khuyến mãi: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: color),
      );
    }
  }

  Future<void> _deletePromo(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16162A),
        title: const Text('Xác nhận xóa', style: TextStyle(color: Colors.white)),
        content: const Text('Bạn có chắc chắn muốn xóa mã khuyến mãi này?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await adminService.deletePromotion(id);
        _showSnackBar('Đã xóa mã khuyến mãi thành công!', Colors.green);
        _loadPromotions();
      } catch (e) {
        _showSnackBar('Xóa mã thất bại: $e', Colors.red);
      }
    }
  }

  void _openPromoForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16162A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => _PromotionFormBottomSheet(
        onSaved: () {
          Navigator.pop(context);
          _loadPromotions();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _openPromoForm,
        backgroundColor: const Color(0xFFC084FC),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC084FC)))
          : RefreshIndicator(
              onRefresh: _loadPromotions,
              child: _promos.isEmpty
                  ? const Center(child: Text('Chưa có mã khuyến mãi nào', style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _promos.length,
                      itemBuilder: (context, index) {
                        final p = _promos[index];
                        final code = p['code'] as String;
                        final percent = p['discount_percent'] as int;
                        final minPurchase = (p['min_purchase'] as num?)?.toDouble() ?? 0.0;
                        final active = p['active'] == true;
                        final limit = p['usage_limit'] as int?;
                        final count = p['usage_count'] as int? ?? 0;

                        return Card(
                          color: const Color(0xFF1E1B4B).withOpacity(0.4),
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            title: Row(
                              children: [
                                Text(code, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: active ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(active ? 'KÍCH HOẠT' : 'KHÓA', style: TextStyle(color: active ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'Giảm giá $percent%\nĐơn tối thiểu: ${formatter.format(minPurchase)}\nĐã dùng: $count/${limit ?? "Không giới hạn"}',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                              onPressed: () => _deletePromo(p['id'] as int),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

// Add Promotion Form
class _PromotionFormBottomSheet extends StatefulWidget {
  final VoidCallback onSaved;

  const _PromotionFormBottomSheet({required this.onSaved});

  @override
  State<_PromotionFormBottomSheet> createState() => _PromotionFormBottomSheetState();
}

class _PromotionFormBottomSheetState extends State<_PromotionFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _percentController = TextEditingController();
  final _minController = TextEditingController();
  final _maxController = TextEditingController();
  final _limitController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _active = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _codeController.dispose();
    _percentController.dispose();
    _minController.dispose();
    _maxController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn thời gian bắt đầu & kết thúc'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isSaving = true);
    final data = {
      'code': _codeController.text.trim().toUpperCase(),
      'discount_percent': int.parse(_percentController.text),
      'min_purchase': _minController.text.trim().isEmpty ? null : double.parse(_minController.text),
      'max_discount': _maxController.text.trim().isEmpty ? null : double.parse(_maxController.text),
      'usage_limit': _limitController.text.trim().isEmpty ? null : int.parse(_limitController.text),
      'start_date': DateFormat('yyyy-MM-dd').format(_startDate!),
      'end_date': DateFormat('yyyy-MM-dd').format(_endDate!),
      'active': _active,
    };

    try {
      await adminService.addPromotion(data);
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Thêm mã khuyến mãi thất bại: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 20 + bottomInset),
      height: MediaQuery.of(context).size.height * 0.8,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Thêm Mã Khuyến Mãi Mới', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 20),

              // Code
              TextFormField(
                controller: _codeController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Mã code (ví dụ: TANG10)', labelStyle: TextStyle(color: Colors.white70)),
                validator: (v) => v == null || v.trim().isEmpty ? 'Nhập mã code' : null,
              ),
              const SizedBox(height: 12),

              // Percent & Limit
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _percentController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Giảm (%)', labelStyle: TextStyle(color: Colors.white70)),
                      validator: (v) => v == null || int.tryParse(v) == null ? 'Nhập tỉ lệ giảm' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _limitController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Giới hạn số lần dùng', labelStyle: TextStyle(color: Colors.white70)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Min Purchase & Max Discount
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Đơn tối thiểu (đ)', labelStyle: TextStyle(color: Colors.white70)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _maxController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Giảm tối đa (đ)', labelStyle: TextStyle(color: Colors.white70)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Start date & End date
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_startDate == null ? 'Bắt đầu' : DateFormat('dd/MM/yy').format(_startDate!), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      trailing: const Icon(Icons.date_range, color: Color(0xFFC084FC), size: 18),
                      onTap: () async {
                        final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2025), lastDate: DateTime(2030));
                        if (date != null) setState(() => _startDate = date);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_endDate == null ? 'Kết thúc' : DateFormat('dd/MM/yy').format(_endDate!), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      trailing: const Icon(Icons.date_range, color: Color(0xFFC084FC), size: 18),
                      onTap: () async {
                        final date = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 7)), firstDate: DateTime(2025), lastDate: DateTime(2030));
                        if (date != null) setState(() => _endDate = date);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Active Switch
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Kích hoạt mã sử dụng ngay', style: TextStyle(color: Colors.white70, fontSize: 14)),
                value: _active,
                activeColor: const Color(0xFFC084FC),
                onChanged: (v) => setState(() => _active = v),
              ),
              const SizedBox(height: 24),

              // Create Button
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC084FC),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : const Text('Thêm mã khuyến mãi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ========================================================
// 5. TAB QUẢN LÝ NGƯỜI DÙNG (USERS LIST & BLOCK/UNBLOCK)
// ========================================================
class _AdminUsersTab extends StatefulWidget {
  const _AdminUsersTab();

  @override
  State<_AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<_AdminUsersTab> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await adminService.getUsers();
      setState(() {
        _users = users;
      });
    } catch (e) {
      _showSnackBar('Lỗi tải người dùng: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: color),
      );
    }
  }

  Future<void> _toggleLock(Map<String, dynamic> user) async {
    final userId = user['id'] as String;
    final lockedUntilStr = user['locked_until'] as String?;
    final isLocked = lockedUntilStr != null && DateTime.parse(lockedUntilStr).isAfter(DateTime.now());

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16162A),
        title: Text(isLocked ? 'Mở khóa tài khoản' : 'Khóa tài khoản', style: const TextStyle(color: Colors.white)),
        content: Text(
          isLocked
              ? 'Bạn có muốn mở khóa tài khoản của ${user['name']}?'
              : 'Bạn có muốn khóa vĩnh viễn tài khoản của ${user['name']}? Người dùng sẽ không thể đăng nhập.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(isLocked ? 'Mở khóa' : 'Khóa', style: TextStyle(color: isLocked ? Colors.green : Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await adminService.toggleUserLock(userId, !isLocked);
        _showSnackBar(isLocked ? 'Đã mở khóa tài khoản thành công!' : 'Đã khóa tài khoản thành công!', Colors.green);
        _loadUsers();
      } catch (e) {
        _showSnackBar('Thao tác thất bại: $e', Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC084FC)))
          : RefreshIndicator(
              onRefresh: _loadUsers,
              child: _users.isEmpty
                  ? const Center(child: Text('Không có người dùng nào', style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        final name = user['name'] as String? ?? 'Chưa đặt tên';
                        final email = user['email'] as String? ?? 'Không có email';
                        final role = user['role'] as String? ?? 'USER';
                        
                        final lockedUntilStr = user['locked_until'] as String?;
                        final isLocked = lockedUntilStr != null && DateTime.parse(lockedUntilStr).isAfter(DateTime.now());

                        return Card(
                          color: const Color(0xFF1E1B4B).withOpacity(0.4),
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isLocked ? Colors.red.withOpacity(0.15) : const Color(0xFFC084FC).withOpacity(0.15),
                              child: Icon(
                                isLocked ? Icons.block : (role == 'ADMIN' ? Icons.admin_panel_settings : Icons.person),
                                color: isLocked ? Colors.red : const Color(0xFFC084FC),
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(width: 8),
                                if (role == 'ADMIN')
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.purple.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                                    child: const Text('ADMIN', style: TextStyle(color: Colors.purpleAccent, fontSize: 8, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                            subtitle: Text('$email\nTrạng thái: ${isLocked ? "BỊ KHÓA" : "HOẠT ĐỘNG"}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            isThreeLine: true,
                            trailing: role == 'ADMIN'
                                ? null // Không cho phép khóa tài khoản admin khác trực tiếp trên client
                                : ElevatedButton(
                                    onPressed: () => _toggleLock(user),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isLocked ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                                      foregroundColor: isLocked ? Colors.green : Colors.redAccent,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: Text(isLocked ? 'Mở Khóa' : 'Khóa', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}


// ========================================================
// 6. TAB THỐNG KÊ BÁO CÁO (ANALYTICS)
// ========================================================
class _AdminAnalyticsTab extends StatefulWidget {
  const _AdminAnalyticsTab();

  @override
  State<_AdminAnalyticsTab> createState() => _AdminAnalyticsTabState();
}

class _AdminAnalyticsTabState extends State<_AdminAnalyticsTab> {
  bool _isLoading = false;
  Map<String, dynamic>? _data;
  int _rangeDays = 30; // 30 days default

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    final end = DateTime.now();
    final start = end.subtract(Duration(days: _rangeDays));

    try {
      final summary = await adminService.getAnalytics(start, end);
      setState(() {
        _data = summary;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải thống kê: $e'), backgroundColor: Colors.red));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final double totalRevenue = (_data?['total_revenue'] as num?)?.toDouble() ?? 0.0;
    final int totalTickets = _data?['total_tickets'] as int? ?? 0;
    final List<dynamic> topMovies = _data?['top_movies'] ?? [];
    final List<dynamic> roomOccupancy = _data?['room_occupancy'] ?? [];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Filter Range
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Thống kê theo khoảng thời gian:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                DropdownButton<int>(
                  value: _rangeDays,
                  dropdownColor: const Color(0xFF16162A),
                  style: const TextStyle(color: Color(0xFFC084FC), fontWeight: FontWeight.bold),
                  items: const [
                    DropdownMenuItem(value: 7, child: Text('7 Ngày Qua')),
                    DropdownMenuItem(value: 30, child: Text('30 Ngày Qua')),
                    DropdownMenuItem(value: 90, child: Text('90 Ngày Qua')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _rangeDays = v;
                        _loadAnalytics();
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            _isLoading
                ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: Color(0xFFC084FC))))
                : Column(
                    children: [
                      // Overview Cards
                      Row(
                        children: [
                          Expanded(
                            child: _AnalyticsCard(
                              title: 'Doanh Thu',
                              value: formatter.format(totalRevenue),
                              icon: Icons.monetization_on_rounded,
                              iconColor: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _AnalyticsCard(
                              title: 'Vé Đã Bán',
                              value: '$totalTickets vé',
                              icon: Icons.confirmation_number_rounded,
                              iconColor: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Chart Top Movies
                      _SectionContainer(
                        title: 'Top Phim Doanh Thu Cao',
                        child: topMovies.isEmpty
                            ? const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: Text('Không có dữ liệu phim', style: TextStyle(color: Colors.white30))))
                            : Column(
                                children: topMovies.map((item) {
                                  final title = item['title'] as String? ?? 'Phim';
                                  final rev = (item['revenue'] as num?)?.toDouble() ?? 0.0;
                                  final maxRev = topMovies.isNotEmpty ? (topMovies.first['revenue'] as num?)?.toDouble() ?? 1.0 : 1.0;
                                  final percent = maxRev > 0 ? (rev / maxRev) : 0.0;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                                            Text(formatter.format(rev), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: Container(
                                            height: 8,
                                            width: double.infinity,
                                            color: Colors.white.withOpacity(0.05),
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Container(
                                                width: MediaQuery.of(context).size.width * 0.7 * percent,
                                                color: const Color(0xFFC084FC),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                      const SizedBox(height: 20),

                      // Showtime Occupancy Rates
                      _SectionContainer(
                        title: 'Tỉ Lệ Lấp Đầy Ghế Lịch Chiếu',
                        child: roomOccupancy.isEmpty
                            ? const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: Text('Không có suất chiếu', style: TextStyle(color: Colors.white30))))
                            : Column(
                                children: roomOccupancy.map((item) {
                                  final movie = item['movie_title'] as String? ?? 'Phim';
                                  final cinema = item['cinema_name'] as String? ?? 'Rạp';
                                  final rate = (item['occupancy_rate'] as num?)?.toDouble() ?? 0.0;
                                  final start = DateTime.parse(item['start_time'] as String).toLocal();
                                  final startStr = DateFormat('dd/MM HH:mm').format(start);

                                  Color rateColor = Colors.red;
                                  if (rate >= 60.0) rateColor = Colors.green;
                                  else if (rate >= 30.0) rateColor = Colors.amber;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(movie, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                              const SizedBox(height: 2),
                                              Text('$cinema • $startStr', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: rateColor.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '$rate%',
                                            style: TextStyle(color: rateColor, fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

// Custom widget for Analytics overview cards
class _AnalyticsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _AnalyticsCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              Icon(icon, color: iconColor, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// Section Container with Title
class _SectionContainer extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionContainer({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
