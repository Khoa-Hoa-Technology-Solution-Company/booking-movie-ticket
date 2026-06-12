// ============================================
// Bookings Service
// ============================================
const prisma = require('../../config/database');

/**
 * Tạo một đơn đặt vé mới
 */
async function createBooking(userId, { showtimeId, seatIds, promotionCode }) {
  // 1. Kiểm tra suất chiếu
  const showtime = await prisma.showtime.findUnique({
    where: { id: showtimeId },
    include: { room: true },
  });

  if (!showtime) {
    throw Object.assign(new Error('Showtime not found'), { statusCode: 404 });
  }

  // Đảm bảo suất chiếu chưa diễn ra
  if (new Date(showtime.startTime) < new Date()) {
    throw Object.assign(new Error('Showtime has already started or ended'), { statusCode: 400 });
  }

  // 2. Kiểm tra danh sách ghế chọn
  const seats = await prisma.seat.findMany({
    where: { id: { in: seatIds } },
  });

  if (seats.length !== seatIds.length) {
    throw Object.assign(new Error('Some selected seats do not exist'), { statusCode: 400 });
  }

  // Đảm bảo tất cả ghế thuộc phòng của suất chiếu
  const invalidSeats = seats.filter((s) => s.roomId !== showtime.roomId);
  if (invalidSeats.length > 0) {
    throw Object.assign(new Error('Some seats do not belong to this showtime room'), { statusCode: 400 });
  }

  // Đảm bảo tất cả ghế đang ở trạng thái trống/hoạt động
  const unavailableSeats = seats.filter((s) => s.status !== 'AVAILABLE');
  if (unavailableSeats.length > 0) {
    throw Object.assign(new Error('Some seats are currently unavailable/under maintenance'), { statusCode: 400 });
  }

  // 3. Kiểm tra xem có ghế nào đã được đặt trước chưa
  const alreadyBooked = await prisma.bookingSeat.findFirst({
    where: {
      seatId: { in: seatIds },
      booking: {
        showtimeId: showtimeId,
        status: { in: ['PENDING', 'CONFIRMED'] },
      },
    },
    include: {
      seat: true,
    },
  });

  if (alreadyBooked) {
    throw Object.assign(
      new Error(`Seat ${alreadyBooked.seat.row}${alreadyBooked.seat.number} is already booked`),
      { statusCode: 400 }
    );
  }

  // 4. Tính toán tổng số tiền (áp dụng phụ thu theo loại ghế)
  let totalAmount = 0;
  for (const seat of seats) {
    let seatPrice = showtime.price;
    if (seat.type === 'VIP') {
      seatPrice += 20000; // Phụ thu ghế VIP
    } else if (seat.type === 'COUPLE') {
      seatPrice += 40000; // Phụ thu ghế đôi
    }
    totalAmount += seatPrice;
  }

  // 5. Áp dụng mã khuyến mãi (Promotion)
  let promotion = null;
  let discountAmount = 0;
  if (promotionCode) {
    promotion = await prisma.promotion.findUnique({
      where: { code: promotionCode },
    });

    if (!promotion) {
      throw Object.assign(new Error('Invalid promotion code'), { statusCode: 400 });
    }
    if (!promotion.active) {
      throw Object.assign(new Error('Promotion code is inactive'), { statusCode: 400 });
    }

    const now = new Date();
    if (now < new Date(promotion.startDate) || now > new Date(promotion.endDate)) {
      throw Object.assign(new Error('Promotion code has expired or is not yet active'), { statusCode: 400 });
    }

    if (promotion.usageLimit !== null && promotion.usageCount >= promotion.usageLimit) {
      throw Object.assign(new Error('Promotion code usage limit has been reached'), { statusCode: 400 });
    }

    if (promotion.minPurchase !== null && totalAmount < promotion.minPurchase) {
      throw Object.assign(
        new Error(`Minimum purchase of ${promotion.minPurchase} VND is required to use this code`),
        { statusCode: 400 }
      );
    }

    // Tính toán discount
    discountAmount = (totalAmount * promotion.discountPercent) / 100;
    if (promotion.maxDiscount !== null && discountAmount > promotion.maxDiscount) {
      discountAmount = promotion.maxDiscount;
    }

    totalAmount -= discountAmount;
    if (totalAmount < 0) totalAmount = 0;
  }

  // 6. Thực hiện Booking trong database transaction
  const booking = await prisma.$transaction(async (tx) => {
    // Kiểm tra chéo lần cuối trong transaction để chống race condition
    const conflictingBooking = await tx.bookingSeat.findFirst({
      where: {
        seatId: { in: seatIds },
        booking: {
          showtimeId: showtimeId,
          status: { in: ['PENDING', 'CONFIRMED'] },
        },
      },
    });

    if (conflictingBooking) {
      throw Object.assign(
        new Error('One or more selected seats have just been booked. Please choose other seats.'),
        { statusCode: 400 }
      );
    }

    // Tạo booking
    const newBooking = await tx.booking.create({
      data: {
        userId,
        showtimeId,
        status: 'PENDING',
        totalAmount,
      },
    });

    // Tạo booking_seats
    const bookingSeatsData = seatIds.map((seatId) => ({
      bookingId: newBooking.id,
      seatId,
    }));

    await tx.bookingSeat.createMany({
      data: bookingSeatsData,
    });

    // Tăng lượt sử dụng mã khuyến mãi
    if (promotion) {
      await tx.promotion.update({
        where: { id: promotion.id },
        data: {
          usageCount: { increment: 1 },
        },
      });
    }

    return newBooking;
  });

  return booking;
}

/**
 * Lịch sử đặt vé của User
 */
async function getBookingHistory(userId) {
  return prisma.booking.findMany({
    where: { userId },
    include: {
      showtime: {
        include: {
          movie: {
            select: {
              id: true,
              title: true,
              posterUrl: true,
              duration: true,
            },
          },
          room: {
            include: {
              cinema: {
                select: {
                  id: true,
                  name: true,
                  address: true,
                },
              },
            },
          },
        },
      },
      bookingSeats: {
        include: {
          seat: true,
        },
      },
      tickets: true,
    },
    orderBy: { createdAt: 'desc' },
  });
}

/**
 * Chi tiết đặt vé theo ID
 */
async function getBookingById(bookingId, userId, userRole) {
  const booking = await prisma.booking.findUnique({
    where: { id: bookingId },
    include: {
      showtime: {
        include: {
          movie: true,
          room: {
            include: {
              cinema: true,
            },
          },
        },
      },
      bookingSeats: {
        include: {
          seat: true,
        },
      },
      tickets: true,
      payment: true,
    },
  });

  if (!booking) {
    throw Object.assign(new Error('Booking not found'), { statusCode: 404 });
  }

  // Chỉ cho phép chính chủ xem hoặc Admin xem
  if (booking.userId !== userId && userRole !== 'ADMIN') {
    throw Object.assign(new Error('Access denied'), { statusCode: 403 });
  }

  return booking;
}

/**
 * Hủy đặt vé (Chỉ khi status là PENDING)
 */
async function cancelBooking(bookingId, userId, userRole) {
  const booking = await prisma.booking.findUnique({
    where: { id: bookingId },
  });

  if (!booking) {
    throw Object.assign(new Error('Booking not found'), { statusCode: 404 });
  }

  // Kiểm tra quyền hủy
  if (booking.userId !== userId && userRole !== 'ADMIN') {
    throw Object.assign(new Error('Access denied'), { statusCode: 403 });
  }

  if (booking.status !== 'PENDING') {
    throw Object.assign(new Error('Only pending bookings can be cancelled'), { statusCode: 400 });
  }

  return prisma.booking.update({
    where: { id: bookingId },
    data: { status: 'CANCELLED' },
  });
}

module.exports = {
  createBooking,
  getBookingHistory,
  getBookingById,
  cancelBooking,
};
