// ============================================
// Payments Service
// ============================================
const prisma = require('../../config/database');

/**
 * Xác nhận thanh toán demo
 */
async function confirmDemoPayment(userId, userRole, { bookingId }) {
  // 1. Tìm đặt vé
  const booking = await prisma.booking.findUnique({
    where: { id: bookingId },
  });

  if (!booking) {
    throw Object.assign(new Error('Booking not found'), { statusCode: 404 });
  }

  // 2. Kiểm tra quyền sở hữu
  if (booking.userId !== userId && userRole !== 'ADMIN') {
    throw Object.assign(new Error('Access denied'), { statusCode: 403 });
  }

  // 3. Chỉ thanh toán cho booking PENDING
  if (booking.status !== 'PENDING') {
    throw Object.assign(
      new Error(`Booking status is ${booking.status}. Only PENDING bookings can be paid.`),
      { statusCode: 400 }
    );
  }

  // 4. Thực hiện thanh toán và xuất vé trong transaction
  const result = await prisma.$transaction(async (tx) => {
    // Check lại lần nữa chống race condition
    const currentBooking = await tx.booking.findUnique({
      where: { id: bookingId },
    });

    if (currentBooking.status !== 'PENDING') {
      throw Object.assign(new Error('Booking status has changed and is no longer PENDING'), { statusCode: 400 });
    }

    // A. Cập nhật trạng thái Booking sang CONFIRMED
    const updatedBooking = await tx.booking.update({
      where: { id: bookingId },
      data: {
        status: 'CONFIRMED',
      },
    });

    // B. Tạo bản ghi thanh toán Payment
    const transactionCode = `TXN-${Date.now()}-${Math.floor(1000 + Math.random() * 9000)}`;
    const payment = await tx.payment.create({
      data: {
        bookingId,
        method: 'E_WALLET',
        status: 'COMPLETED',
        amount: booking.totalAmount,
        transactionCode,
      },
    });

    // C. Tạo vé Ticket
    const ticketCode = `TKT-${Math.random().toString(36).substring(2, 10).toUpperCase()}`;
    // Link QR code trỏ tới API sinh mã QR thật từ qrserver.com
    const qrCodeUrl = `https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=${ticketCode}`;
    const ticket = await tx.ticket.create({
      data: {
        bookingId,
        ticketCode,
        qrCode: qrCodeUrl,
        status: 'ACTIVE',
      },
    });

    return {
      booking: updatedBooking,
      payment,
      ticket,
    };
  });

  return result;
}

module.exports = {
  confirmDemoPayment,
};
