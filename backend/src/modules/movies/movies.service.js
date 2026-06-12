// ============================================
// Movies Service
// Quản lý phim - hiện tại: listing + detail
// Sau này mở rộng: CRUD cho admin
// ============================================
const prisma = require('../../config/database');

/**
 * Lấy danh sách phim đang chiếu
 */
async function getNowShowing() {
  return prisma.movie.findMany({
    where: { status: 'NOW_SHOWING' },
    orderBy: { releaseDate: 'desc' },
    select: {
      id: true,
      title: true,
      posterUrl: true,
      duration: true,
      ageRating: true,
      genre: true,
      rating: true,
      releaseDate: true,
      status: true,
    },
  });
}

/**
 * Lấy danh sách phim sắp chiếu
 */
async function getComingSoon() {
  return prisma.movie.findMany({
    where: { status: 'COMING_SOON' },
    orderBy: { releaseDate: 'asc' },
    select: {
      id: true,
      title: true,
      posterUrl: true,
      duration: true,
      ageRating: true,
      genre: true,
      rating: true,
      releaseDate: true,
      status: true,
    },
  });
}

/**
 * Lấy chi tiết phim theo ID
 */
async function getMovieById(id) {
  const movie = await prisma.movie.findUnique({
    where: { id },
    include: {
      showtimes: {
        where: {
          startTime: { gte: new Date() },
        },
        include: {
          room: {
            include: {
              cinema: {
                select: { id: true, name: true, address: true, city: true },
              },
            },
          },
        },
        orderBy: { startTime: 'asc' },
      },
    },
  });

  if (!movie) {
    throw Object.assign(new Error('Movie not found'), { statusCode: 404 });
  }

  return movie;
}

/**
 * Lấy tất cả phim (cho admin)
 */
async function getAllMovies(page = 1, limit = 20) {
  const skip = (page - 1) * limit;

  const [movies, total] = await Promise.all([
    prisma.movie.findMany({
      orderBy: { createdAt: 'desc' },
      skip,
      take: limit,
    }),
    prisma.movie.count(),
  ]);

  return {
    movies,
    pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
  };
}

module.exports = {
  getNowShowing,
  getComingSoon,
  getMovieById,
  getAllMovies,
};
