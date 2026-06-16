const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

/**
 * Helper to determine seat price
 */
function calculateSeatPrice(seatId, basePrice) {
  if (!seatId || seatId.length === 0) return basePrice;
  const row = seatId.charAt(0).toUpperCase();
  if (["B", "C", "D"].includes(row)) {
    return basePrice + 20000; // VIP adds 20,000 VND
  } else if (row === "F") {
    return basePrice + 40000; // Couple adds 40,000 VND
  }
  return basePrice;
}

/**
 * 1. Create Booking (Callable Function with Transaction)
 */
exports.createBooking = onCall(async (request) => {
  // Enforce authentication
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Yêu cầu đăng nhập trước khi thực hiện đặt vé.");
  }

  const { showtimeId, seatIds, promotionCode } = request.data;
  const userId = request.auth.uid;

  if (!showtimeId || !seatIds || !Array.isArray(seatIds) || seatIds.length === 0) {
    throw new HttpsError("invalid-argument", "Thiếu tham số lịch chiếu hoặc danh sách ghế.");
  }

  console.log(`[createBooking] User: ${userId} requesting showtime: ${showtimeId}, seats: ${seatIds.join(", ")}`);

  const result = await db.runTransaction(async (transaction) => {
    // 1. Check showtime exists
    const showtimeRef = db.collection("showtimes").doc(showtimeId);
    const showtimeDoc = await transaction.get(showtimeRef);
    if (!showtimeDoc.exists) {
      throw new HttpsError("not-found", "Không tìm thấy lịch chiếu đã chọn.");
    }
    const showtime = showtimeDoc.data();
    const basePrice = showtime.price;

    // 2. Validate seat availability (Prevent double booking)
    for (const seatId of seatIds) {
      const seatLockRef = db.collection("booking_seats").doc(`${showtimeId}_${seatId}`);
      const seatLockDoc = await transaction.get(seatLockRef);
      if (seatLockDoc.exists) {
        console.warn(`[createBooking] Conflict detected! Seat ${seatId} for showtime ${showtimeId} is already booked.`);
        throw new HttpsError("already-exists", `Ghế ${seatId} đã có người đặt trước.`);
      }
    }

    // 3. Verify promotion code
    let discountPercent = 0;
    if (promotionCode) {
      const promoRef = db.collection("promotions").doc(promotionCode.toUpperCase());
      const promoDoc = await transaction.get(promoRef);
      if (promoDoc.exists) {
        const promo = promoDoc.data();
        const now = admin.firestore.Timestamp.now();
        if (promo.active && promo.startDate.toDate() <= now.toDate() && promo.endDate.toDate() >= now.toDate()) {
          discountPercent = promo.discountPercent || 0;
        }
      }
    }

    // 4. Calculate total amount
    let subtotal = 0;
    const seatNamesList = [];
    for (const seatId of seatIds) {
      const price = calculateSeatPrice(seatId, basePrice);
      subtotal += price;
      seatNamesList.push(seatId);
    }

    const discountAmount = subtotal * (discountPercent / 100);
    const totalAmount = subtotal - discountAmount;

    // 5. Create Booking Document
    const bookingRef = db.collection("bookings").doc();
    const bookingId = bookingRef.id;
    const now = admin.firestore.Timestamp.now();
    const expiresAt = admin.firestore.Timestamp.fromMillis(now.toMillis() + 5 * 60 * 1000); // 5 mins expiration

    transaction.set(bookingRef, {
      id: bookingId,
      userId: userId,
      showtimeId: showtimeId,
      totalAmount: totalAmount,
      status: "PENDING",
      createdAt: now,
      expiresAt: expiresAt,
      promotionCode: promotionCode || null,
      seatIds: seatIds,
      seatNames: seatNamesList.join(", ")
    });

    // 6. Create Booking Seats documents (locks the seats)
    for (const seatId of seatIds) {
      const seatLockRef = db.collection("booking_seats").doc(`${showtimeId}_${seatId}`);
      transaction.set(seatLockRef, {
        showtimeId: showtimeId,
        seatId: seatId,
        bookingId: bookingId,
        userId: userId,
        createdAt: now
      });
    }

    console.log(`[createBooking] Success. Booking ID: ${bookingId}, Total Amount: ${totalAmount}`);
    return { bookingId, totalAmount };
  });

  return result;
});

/**
 * 2. Confirm Demo Payment (Callable Function with Transaction)
 */
exports.confirmDemoPayment = onCall(async (request) => {
  // Enforce authentication
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Yêu cầu đăng nhập để thanh toán.");
  }

  const { bookingId } = request.data;
  if (!bookingId) {
    throw new HttpsError("invalid-argument", "Thiếu mã đặt vé.");
  }

  const userId = request.auth.uid;
  console.log(`[confirmDemoPayment] User: ${userId} confirming payment for booking: ${bookingId}`);

  const result = await db.runTransaction(async (transaction) => {
    // 1. Verify booking exists
    const bookingRef = db.collection("bookings").doc(bookingId);
    const bookingDoc = await transaction.get(bookingRef);
    if (!bookingDoc.exists) {
      throw new HttpsError("not-found", "Không tìm thấy thông tin đặt vé.");
    }

    // 2. Verify booking belongs to user (Security requirement)
    const booking = bookingDoc.data();
    if (booking.userId !== userId) {
      console.error(`[confirmDemoPayment] Unauthorized access attempt by ${userId} on booking ${bookingId} owned by ${booking.userId}`);
      throw new HttpsError("permission-denied", "Bạn không có quyền thanh toán đơn đặt vé này.");
    }

    if (booking.status !== "PENDING") {
      throw new HttpsError("failed-precondition", "Trạng thái đặt vé không hợp lệ hoặc đã thanh toán/hủy.");
    }

    const now = admin.firestore.Timestamp.now();

    // Generate random Ticket Code (8 letters/numbers)
    const ticketCode = Math.random().toString(36).substring(2, 10).toUpperCase();
    const qrCode = `https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=${ticketCode}`;

    // Update Booking status to CONFIRMED
    transaction.update(bookingRef, {
      status: "CONFIRMED",
      updatedAt: now
    });

    // Create Ticket document with seat, showtime, and userId info
    const ticketRef = db.collection("tickets").doc();
    const ticketData = {
      id: ticketRef.id,
      bookingId: bookingId,
      ticketCode: ticketCode,
      qrCode: qrCode,
      status: "VALID",
      createdAt: now,
      userId: booking.userId,
      showtimeId: booking.showtimeId,
      seatIds: booking.seatIds,
      seatNames: booking.seatNames
    };
    transaction.set(ticketRef, ticketData);

    // Create Payment document
    const paymentRef = db.collection("payments").doc();
    transaction.set(paymentRef, {
      id: paymentRef.id,
      bookingId: bookingId,
      method: "DEMO",
      amount: booking.totalAmount,
      status: "PAID",
      transactionCode: `TX_${ticketCode}`,
      createdAt: now
    });

    console.log(`[confirmDemoPayment] Success. Booking: ${bookingId} marked as CONFIRMED. Ticket Code: ${ticketCode}`);
    return {
      success: true,
      ticket: ticketData,
      booking: {
        id: bookingId,
        totalAmount: booking.totalAmount,
        status: "CONFIRMED",
        seatIds: booking.seatIds,
        seatNames: booking.seatNames,
        showtimeId: booking.showtimeId,
        userId: booking.userId
      }
    };
  });

  return result;
});

/**
 * 3. Cancel Booking (Callable Function with Transaction)
 */
exports.cancelBooking = onCall(async (request) => {
  // Enforce authentication
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Yêu cầu đăng nhập.");
  }

  const { bookingId } = request.data;
  if (!bookingId) {
    throw new HttpsError("invalid-argument", "Thiếu mã đặt vé.");
  }

  const userId = request.auth.uid;
  console.log(`[cancelBooking] User: ${userId} cancelling booking: ${bookingId}`);

  const result = await db.runTransaction(async (transaction) => {
    // 1. Verify booking exists
    const bookingRef = db.collection("bookings").doc(bookingId);
    const bookingDoc = await transaction.get(bookingRef);
    if (!bookingDoc.exists) {
      throw new HttpsError("not-found", "Không tìm thấy thông tin đặt vé.");
    }

    // 2. Verify booking belongs to user (Security requirement)
    const booking = bookingDoc.data();
    if (booking.userId !== userId) {
      console.error(`[cancelBooking] Unauthorized cancel attempt by ${userId} on booking ${bookingId} owned by ${booking.userId}`);
      throw new HttpsError("permission-denied", "Bạn không có quyền hủy đơn đặt vé này.");
    }

    if (booking.status !== "PENDING") {
      throw new HttpsError("failed-precondition", "Chỉ có thể hủy những đặt vé chưa thanh toán (PENDING).");
    }

    // 3. Release all booked seats corresponding to this bookingId
    const showtimeId = booking.showtimeId;
    for (const seatId of booking.seatIds) {
      const seatLockRef = db.collection("booking_seats").doc(`${showtimeId}_${seatId}`);
      transaction.delete(seatLockRef);
    }

    // 4. Update booking status to CANCELLED
    transaction.update(bookingRef, {
      status: "CANCELLED",
      updatedAt: admin.firestore.Timestamp.now()
    });

    console.log(`[cancelBooking] Success. Booking: ${bookingId} has been CANCELLED and seats released.`);
    return { success: true };
  });

  return result;
});

/**
 * 4. Get Email By Phone Number (Callable Function for secure unauthenticated login lookup)
 */
exports.getEmailByPhone = onCall(async (request) => {
  const { phoneNumber } = request.data;
  if (!phoneNumber) {
    throw new HttpsError("invalid-argument", "Thiếu số điện thoại.");
  }
  const query = await db.collection("users").where("phoneNumber", "==", phoneNumber).limit(1).get();
  if (query.empty) {
    throw new HttpsError("not-found", "Không tìm thấy tài khoản với số điện thoại này.");
  }
  return { email: query.docs[0].data().email };
});

/**
 * 5. Record Failed Login Attempt (Callable Function for secure lockout counter and login history logging)
 */
exports.recordFailedLogin = onCall(async (request) => {
  const { email, reason, deviceName } = request.data;
  if (!email) {
    throw new HttpsError("invalid-argument", "Thiếu email.");
  }

  const query = await db.collection("users").where("email", "==", email).limit(1).get();
  if (query.empty) {
    return { success: false, message: "User not found" };
  }

  const userRef = query.docs[0].ref;
  const userData = query.docs[0].data();
  const userId = query.docs[0].id;

  const failedAttempts = (userData.failedLoginAttempts || 0) + 1;
  const updates = { failedLoginAttempts: failedAttempts };

  if (failedAttempts >= 5) {
    const lockUntil = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + 5 * 60 * 1000) // 5 minutes lock
    );
    updates.lockedUntil = lockUntil;

    // Create security alert
    await db.collection("security_alerts").add({
      userId: userId,
      type: "ACCOUNT_LOCKED",
      message: "Tài khoản của bạn đã bị khóa tạm thời 5 phút do đăng nhập sai nhiều lần.",
      severity: "HIGH",
      read: false,
      createdAt: admin.firestore.Timestamp.now()
    });
  }

  await userRef.update(updates);

  // Write to login_history
  await db.collection("login_history").add({
    userId: userId,
    email: email,
    ipAddress: "127.0.0.1",
    userAgent: "Mobile App/Web",
    deviceName: deviceName || "Unknown Device",
    success: false,
    reason: reason || "Wrong password",
    suspicious: failedAttempts >= 5,
    createdAt: admin.firestore.Timestamp.now()
  });

  return { success: true, locked: failedAttempts >= 5 };
});

