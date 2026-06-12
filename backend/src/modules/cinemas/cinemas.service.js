// ============================================
// Cinemas Service
// ============================================
const prisma = require('../../config/database');

/**
 * Lấy danh sách rạp chiếu kèm thông tin phòng chiếu
 */
async function getCinemas() {
  return prisma.cinema.findMany({
    include: {
      rooms: {
        select: {
          id: true,
          name: true,
          totalSeats: true,
        },
      },
    },
    orderBy: { name: 'asc' },
  });
}

/**
 * Lấy chi tiết rạp chiếu kèm thông tin phòng chiếu và danh sách ghế
 */
async function getCinemaById(id) {
  const cinema = await prisma.cinema.findUnique({
    where: { id },
    include: {
      rooms: {
        include: {
          seats: {
            select: {
              id: true,
              row: true,
              number: true,
              type: true,
              status: true,
            },
            orderBy: [{ row: 'asc' }, { number: 'asc' }],
          },
        },
      },
    },
  });

  if (!cinema) {
    throw Object.assign(new Error('Cinema not found'), { statusCode: 404 });
  }

  return cinema;
}

module.exports = {
  getCinemas,
  getCinemaById,
};
