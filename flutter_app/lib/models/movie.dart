enum MovieStatus { comingSoon, nowShowing, ended }

class Movie {
  final int id;
  final String title;
  final String description;
  final String? posterUrl;
  final String? trailerUrl;
  final int duration;
  final String? ageRating;
  final String? genre;
  final String? director;
  final String? cast;
  final DateTime? releaseDate;
  final MovieStatus status;
  final double rating;

  const Movie({
    required this.id,
    required this.title,
    required this.description,
    this.posterUrl,
    this.trailerUrl,
    required this.duration,
    this.ageRating,
    this.genre,
    this.director,
    this.cast,
    this.releaseDate,
    required this.status,
    required this.rating,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    MovieStatus parseStatus(String? statusStr) {
      switch (statusStr) {
        case 'COMING_SOON': return MovieStatus.comingSoon;
        case 'NOW_SHOWING': return MovieStatus.nowShowing;
        case 'ENDED': return MovieStatus.ended;
        default: return MovieStatus.nowShowing;
      }
    }

    return Movie(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      posterUrl: json['poster_url'] as String?,
      trailerUrl: json['trailer_url'] as String?,
      duration: json['duration'] as int? ?? 0,
      ageRating: json['age_rating'] as String?,
      genre: json['genre'] as String?,
      director: json['director'] as String?,
      cast: json['cast'] as String?,
      releaseDate: json['release_date'] != null ? DateTime.parse(json['release_date'] as String) : null,
      status: parseStatus(json['status'] as String?),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'poster_url': posterUrl,
      'trailer_url': trailerUrl,
      'duration': duration,
      'age_rating': ageRating,
      'genre': genre,
      'director': director,
      'cast': cast,
      'release_date': releaseDate?.toIso8601String(),
      'status': status == MovieStatus.comingSoon
          ? 'COMING_SOON'
          : status == MovieStatus.ended
              ? 'ENDED'
              : 'NOW_SHOWING',
      'rating': rating,
    };
  }
}
