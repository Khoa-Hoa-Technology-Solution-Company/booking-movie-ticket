
class MovieService {
  // Bản đồ lưu ghế đã đặt của từng lịch chiếu (Showtime ID -> Danh sách Seat ID đã đặt)
  static final Map<int, List<int>> bookedSeatIdsByShowtime = {};

  // Dữ liệu Phim tĩnh
  final List<Map<String, dynamic>> _movies = [
    {
      'id': 1,
      'title': 'Dune: Hành Tinh Cát - Phần 2',
      'description': 'Hành trình tiếp theo của Paul Atreides khi anh đồng hành cùng Chani và người Fremen để tìm kiếm sự trả thù chống lại những kẻ đã hủy hoại gia đình mình. Đối mặt với sự lựa chọn giữa tình yêu của cuộc đời mình và số phận của vũ trụ, Paul cố gắng ngăn chặn một tương lai khủng khiếp mà chỉ anh mới có thể thấy trước.',
      'posterUrl': 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=500&q=80',
      'trailerUrl': 'https://www.youtube.com/watch?v=Way9Dexny3w',
      'duration': 166,
      'ageRating': 'C16',
      'genre': 'Hành động, Khoa học viễn tưởng, Phiêu lưu',
      'director': 'Denis Villeneuve',
      'cast': 'Timothée Chalamet, Zendaya, Rebecca Ferguson, Josh Brolin',
      'releaseDate': '2024-03-01',
      'status': 'NOW_SHOWING',
      'rating': 8.8,
    },
    {
      'id': 2,
      'title': 'Godzilla x Kong: Đế Chế Mới',
      'description': 'Hai thực thể khổng lồ Godzilla và Kong sẽ cùng nhau đối đầu với một mối đe dọa mới xuất hiện từ sâu thẳm thế giới, thách thức sự tồn tại của cả hai loài khổng lồ và toàn nhân loại. Bộ phim sẽ đi sâu vào lịch sử của các Titan này và nguồn gốc của Đảo Đầu Lâu.',
      'posterUrl': 'https://images.unsplash.com/photo-1594909122845-11baa439b7bf?w=500&q=80',
      'trailerUrl': 'https://www.youtube.com/watch?v=lV1OOlGwExM',
      'duration': 115,
      'ageRating': 'C13',
      'genre': 'Hành động, Giả tưởng, Khoa học viễn tưởng',
      'director': 'Adam Wingard',
      'cast': 'Rebecca Hall, Brian Tyree Henry, Dan Stevens, Kaylee Hottle',
      'releaseDate': '2024-03-29',
      'status': 'NOW_SHOWING',
      'rating': 8.2,
    },
    {
      'id': 3,
      'title': 'Những Mảnh Ghép Cảm Xúc 2 (Inside Out 2)',
      'description': 'Quay trở lại với tâm trí của cô bé Riley khi bước vào tuổi dậy thì. Trụ sở đầu não lúc này trải qua một đợt nâng cấp bất ngờ để nhường chỗ cho những Cảm Xúc mới: Lo Âu (Anxiety), Ghen Tị (Envy), Chán Nản (Ennui), và Xấu Hổ (Embarrassment). Các cảm xúc cũ như Vui Vẻ, Buồn Bã, Giận Dữ, Sợ Hãi và Ghê Tởm phải học cách đối phó với những người bạn mới này.',
      'posterUrl': 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=500&q=80',
      'trailerUrl': '',
      'duration': 96,
      'ageRating': 'P',
      'genre': 'Hoạt hình, Hài hước, Gia đình',
      'director': 'Kelsey Mann',
      'cast': 'Amy Poehler, Maya Hawke, Kensington Tallman, Liza Lapira',
      'releaseDate': '2024-06-14',
      'status': 'COMING_SOON',
      'rating': 9.0,
    },
    {
      'id': 4,
      'title': 'Deadpool & Wolverine',
      'description': 'Kẻ lắm lời Deadpool sẽ hợp tác cùng với người sói Wolverine trong một nhiệm vụ vô cùng điên rồ của Tổ chức Phương sai Thời gian (TVA). Cặp đôi trái ngược này hứa hẹn sẽ mang đến những trận chiến mãn nhãn và những tràng cười sảng khoái, thay đổi hoàn toàn cục diện của MCU.',
      'posterUrl': 'https://images.unsplash.com/photo-1478720568477-152d9b164e26?w=500&q=80',
      'trailerUrl': '',
      'duration': 127,
      'ageRating': 'C18',
      'genre': 'Hành động, Hài hước, Khoa học viễn tưởng',
      'director': 'Shawn Levy',
      'cast': 'Ryan Reynolds, Hugh Jackman, Emma Corrin, Morena Baccarin',
      'releaseDate': '2024-07-26',
      'status': 'COMING_SOON',
      'rating': 8.5,
    }
  ];

  // Dữ liệu Rạp chiếu phim tĩnh
  final List<Map<String, dynamic>> _cinemas = [
    {
      'id': 1,
      'name': 'CGV Vincom Landmark 81',
      'address': 'Tầng B1, TTTM Vincom Landmark 81, 720A Điện Biên Phủ, Q. Bình Thạnh, TP.HCM',
      'city': 'TP.HCM',
      'imageUrl': 'https://images.unsplash.com/photo-1517604931442-7e0c8ed2963c?w=500&q=80',
    },
    {
      'id': 2,
      'name': 'Lotte Cinema Cantavil An Phú',
      'address': 'Tầng 7, Cantavil Premier, Xa Lộ Hà Nội, P. An Phú, Quận 2, TP.HCM',
      'city': 'TP.HCM',
      'imageUrl': 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=500&q=80',
    },
    {
      'id': 3,
      'name': 'BHD Star Thảo Điền',
      'address': 'Tầng 5, Vincom Mega Mall Thảo Điền, Xa Lộ Hà Nội, Quận 2, TP.HCM',
      'city': 'TP.HCM',
      'imageUrl': 'https://images.unsplash.com/photo-1517604931442-7e0c8ed2963c?w=500&q=80',
    }
  ];

  // Tạo Lịch chiếu động (offset ngày hiện tại để lịch chiếu luôn ở tương lai)
  List<Map<String, dynamic>> _generateShowtimes() {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowStr = '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
    final dayAfter = now.add(const Duration(days: 2));
    final dayAfterStr = '${dayAfter.year}-${dayAfter.month.toString().padLeft(2, '0')}-${dayAfter.day.toString().padLeft(2, '0')}';

    return [
      // Dune 2 (id: 1)
      {
        'id': 101,
        'movieId': 1,
        'cinemaId': 1,
        'roomName': 'Cinema 1 (IMAX)',
        'startTime': '$todayStr 14:00:00',
        'endTime': '$todayStr 16:46:00',
        'price': 150000.0,
      },
      {
        'id': 102,
        'movieId': 1,
        'cinemaId': 1,
        'roomName': 'Cinema 1 (IMAX)',
        'startTime': '$todayStr 20:30:00',
        'endTime': '$todayStr 23:16:00',
        'price': 150000.0,
      },
      {
        'id': 103,
        'movieId': 1,
        'cinemaId': 2,
        'roomName': 'Lotte Superplex',
        'startTime': '$tomorrowStr 17:00:00',
        'endTime': '$tomorrowStr 19:46:00',
        'price': 120000.0,
      },
      // Godzilla x Kong (id: 2)
      {
        'id': 201,
        'movieId': 2,
        'cinemaId': 1,
        'roomName': 'Cinema 3',
        'startTime': '$todayStr 15:30:00',
        'endTime': '$todayStr 17:25:00',
        'price': 110000.0,
      },
      {
        'id': 202,
        'movieId': 2,
        'cinemaId': 3,
        'roomName': 'Room Gold Class',
        'startTime': '$tomorrowStr 19:00:00',
        'endTime': '$tomorrowStr 20:55:00',
        'price': 220000.0,
      },
      {
        'id': 203,
        'movieId': 2,
        'cinemaId': 2,
        'roomName': 'Cinema 5',
        'startTime': '$dayAfterStr 21:00:00',
        'endTime': '$dayAfterStr 22:55:00',
        'price': 100000.0,
      }
    ];
  }

  /// Lấy danh sách phim đang chiếu
  Future<List<dynamic>> getNowShowing() async {
    return _movies.where((m) => m['status'] == 'NOW_SHOWING').toList();
  }

  /// Lấy danh sách phim sắp chiếu
  Future<List<dynamic>> getComingSoon() async {
    return _movies.where((m) => m['status'] == 'COMING_SOON').toList();
  }

  /// Lấy chi tiết phim theo ID
  Future<Map<String, dynamic>> getMovieById(int id) async {
    final movie = _movies.firstWhere((m) => m['id'] == id, orElse: () => throw Exception('Không tìm thấy phim'));
    
    // Gắn danh sách lịch chiếu của phim này
    final showtimes = _generateShowtimes().where((s) => s['movieId'] == id).toList();
    
    return {
      ...movie,
      'showtimes': showtimes,
    };
  }

  /// Lấy danh sách rạp
  Future<List<dynamic>> getCinemas() async {
    return _cinemas;
  }

  /// Lấy lịch chiếu được lọc
  Future<List<dynamic>> getShowtimes({
    int? movieId,
    int? cinemaId,
    String? date,
  }) async {
    var list = _generateShowtimes();

    if (movieId != null) {
      list = list.where((s) => s['movieId'] == movieId).toList();
    }
    if (cinemaId != null) {
      list = list.where((s) => s['cinemaId'] == cinemaId).toList();
    }
    if (date != null) {
      list = list.where((s) => s['startTime'].startsWith(date)).toList();
    }

    // Gắn thêm thông tin phim và rạp cho lịch chiếu
    return list.map((showtime) {
      final movie = _movies.firstWhere((m) => m['id'] == showtime['movieId']);
      final cinema = _cinemas.firstWhere((c) => c['id'] == showtime['cinemaId']);
      return {
        ...showtime,
        'movie': movie,
        'cinema': cinema,
      };
    }).toList();
  }

  /// Lấy chi tiết lịch chiếu và sơ đồ ghế
  Future<Map<String, dynamic>> getShowtimeById(int id) async {
    final showtimes = _generateShowtimes();
    final showtime = showtimes.firstWhere((s) => s['id'] == id, orElse: () => throw Exception('Không tìm thấy lịch chiếu'));
    final movie = _movies.firstWhere((m) => m['id'] == showtime['movieId']);
    final cinema = _cinemas.firstWhere((c) => c['id'] == showtime['cinemaId']);

    // Tạo danh sách 80 ghế (Hàng A-H, Cột 1-10)
    final List<Map<String, dynamic>> seats = [];
    final bookedIds = bookedSeatIdsByShowtime[id] ?? [];

    final rows = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
    int seatIndex = 1;

    for (var row in rows) {
      for (int num = 1; num <= 10; num++) {
        final seatId = seatIndex++;
        final isBooked = bookedIds.contains(seatId);
        final bool isVip = row == 'E' || row == 'F';

        seats.add({
          'id': seatId,
          'row': row,
          'number': num,
          'type': isVip ? 'VIP' : 'STANDARD',
          'status': isBooked ? 'RESERVED' : 'AVAILABLE',
          'price': showtime['price'] * (isVip ? 1.2 : 1.0),
        });
      }
    }

    return {
      ...showtime,
      'movie': movie,
      'cinema': cinema,
      'seats': seats,
    };
  }
}

final movieService = MovieService();
