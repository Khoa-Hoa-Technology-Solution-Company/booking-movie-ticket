import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/movie.dart';
import 'movie_detail_screen.dart';

class MovieSearchDelegate extends SearchDelegate<Movie?> {
  final List<Movie> movies;

  MovieSearchDelegate({required this.movies})
      : super(
          searchFieldLabel: 'Tìm kiếm tên phim, thể loại...',
          searchFieldStyle: const TextStyle(color: Colors.white, fontSize: 16),
        );

  @override
  ThemeData appBarTheme(BuildContext context) {
    Theme.of(context); // Lắng nghe theme
    return ThemeData(
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 18),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 15),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: Icon(Icons.clear_rounded, color: AppColors.textSecondary),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildMovieList(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildMovieList(context);
  }

  Widget _buildMovieList(BuildContext context) {
    final cleanQuery = query.trim().toLowerCase();
    
    final filteredMovies = movies.where((movie) {
      final titleMatch = movie.title.toLowerCase().contains(cleanQuery);
      final genreMatch = movie.genre != null && movie.genre!.toLowerCase().contains(cleanQuery);
      final directorMatch = movie.director != null && movie.director!.toLowerCase().contains(cleanQuery);
      return titleMatch || genreMatch || directorMatch;
    }).toList();

    if (filteredMovies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy phim phù hợp với "$query"',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredMovies.length,
      itemBuilder: (context, index) {
        final movie = filteredMovies[index];
        return Card(
          color: AppColors.surface,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              close(context, movie);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MovieDetailScreen(movieId: movie.id),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // Poster Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: movie.posterUrl ?? '',
                      width: 70,
                      height: 95,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        width: 70,
                        height: 95,
                        color: Colors.grey.shade800,
                        child: const Icon(Icons.movie, color: Colors.white54),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Movie Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movie.title,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.star_rounded, size: 16, color: Colors.amber.shade400),
                            const SizedBox(width: 4),
                            Text(
                              movie.rating.toStringAsFixed(1),
                              style: TextStyle(
                                color: Colors.amber.shade400,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.access_time_rounded, size: 14, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              '${movie.duration} phút',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (movie.genre != null && movie.genre!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(30),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              movie.genre!,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
