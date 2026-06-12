// ============================================
// Showtimes Service
// ============================================
const prisma = require('../../config/database');

/**
 * Lấy danh sách lịch chiếu theo phim, rạp và ngày
 */
async function getShowtimes({ movieId, cinemaId, date }) {
  const where = {};

  if (movieId) {
    where.movieId = parseInt(movieId);
  }

  if (cinemaId) {
    where.room = {
      cinemaId: parseInt(cinemaId),
    };
  }

  if (date) {
    // Tìm kiếm trong cả ngày chỉ định
    const startOfDay = new Date(`${date}T00:00:00`);
    const endOfDay = new Date(`${date}T23:59:59.999`);
    where.startTime = {
      gte: startOfDay,
      lte: endOfDay,
    };
  } else {
    // Mặc định chỉ lấy các suất chiếu từ thời điểm hiện tại trở đi
    where.startTime = {
      gte: new Date(),
    };
  }

  return prisma.showtime.findMany({
    where,
    include: {
      movie: {
        select: {
          id: true,
          title: true,
          posterUrl: true,
          duration: true,
          ageRating: true,
          genre: true,
        },
      },
      room: {
        include: {
          cinema: {
            select: {
              id: true,
              name: true,
              address: true,
              city: true,
            },
          },
        },
      },
    },
    orderBy: { startTime: 'asc' },
  });
}

/**
 * Lấy chi tiết lịch chiếu và tình trạng ghế trống/đã đặt
 */
async function getShowtimeById(id) {
  const showtime = await prisma.showtime.findUnique({
    where: { id },
    include: {
      movie: true,
      room: {
        include: {
          cinema: true,
          seats: {
            orderBy: [{ row: 'asc' }, { number: 'asc' }],
          },
        },
      },
    },
  });

  if (!showtime) {
    throw Object.assign(new Error('Showtime not found'), { statusCode: 404 });
  }

  // Lấy danh sách các ghế đã được đặt cho suất chiếu này (booking PENDING hoặc CONFIRMED)
  const bookedSeats = await prisma.bookingSeat.findMany({
    where: {
      booking: {
        showtimeId: id,
        status: {
          in: ['PENDING', 'CONFIRMED'],
        },
      },
    },
    select: {
      seatId: true,
    },
  });

  const bookedSeatIds = new Set(bookedSeats.map((bs) => bs.seatId));

  // Trình bày sơ đồ ghế kèm cờ isBooked
  const seats = showtime.room.seats.map((seat) => ({
    id: seat.id,
    row: seat.row,
    number: seat.number,
    type: seat.type,
    status: seat.status,
    isBooked: bookedSeatIds.has(seat.id),
  }));

  // Tạo đối tượng response đẹp mắt
  const result = {
    id: showtime.id,
    startTime: showtime.startTime,
    endTime: showtime.endTime,
    price: showtime.price,
    movie: showtime.movie,
    cinema: showtime.room.cinema,
    room: {
      id: showtime.room.id,
      name: showtime.room.name,
      totalSeats: showtime.room.totalSeats,
    },
    seats,
  };

  return result;
}

module.exports = {
  getShowtimes,
  getShowtimeById,
};
