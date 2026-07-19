import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/payment_config.dart';
import '../../services/booking_service.dart';
import '../../models/booking.dart';
import '../../core/theme/app_theme.dart';

class BookingHistoryScreen extends StatefulWidget {
  final int currentTabIndex;

  const BookingHistoryScreen({super.key, required this.currentTabIndex});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  bool _isLoading = false;
  List<Booking> _bookings = [];

  @override
  void initState() {
    super.initState();
    _loadBookingHistory();
  }

  @override
  void didUpdateWidget(covariant BookingHistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Tự động tải lại dữ liệu khi người dùng chuyển sang tab "Vé của tôi" (tab index 2)
    if (widget.currentTabIndex == 2 && oldWidget.currentTabIndex != 2) {
      _loadBookingHistory();
    }
  }

  Future<void> _loadBookingHistory() async {
    setState(() => _isLoading = true);
    try {
      final bookings = await bookingService.getBookingHistory();
      setState(() {
        _bookings = bookings;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tải được lịch sử đặt vé: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handlePayment(int bookingId, double totalAmount) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16162A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chọn Phương Thức Thanh Toán',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.wallet, color: Color(0xFFC084FC)),
                  title: const Text('Ví Điện Tử Demo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Thanh toán và nhận vé ngay lập tức (Test)', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _processPaymentWithMethod(bookingId, totalAmount, 'DEMO');
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.account_balance, color: Color(0xFFC084FC)),
                  title: const Text('Chuyển Khoản Ngân Hàng (SePay)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Quét mã VietQR chuyển khoản tự động', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _processPaymentWithMethod(bookingId, totalAmount, 'SEPAY');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _processPaymentWithMethod(int bookingId, double totalAmount, String paymentMethod) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('payments')
          .update({'method': paymentMethod})
          .eq('booking_id', bookingId);
    } catch (e) {
      debugPrint('Lỗi cập nhật phương thức thanh toán: $e');
    }

    if (paymentMethod == 'DEMO') {
      _showDemoPaymentConfirmationDialog(bookingId, totalAmount);
    } else {
      _showSePayPaymentDialog(bookingId, totalAmount);
    }
  }

  void _showDemoPaymentConfirmationDialog(int bookingId, double totalAmount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isPaying = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF16162A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text('Thanh Toán Demo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: Text(
                'Bạn có chắc chắn muốn thanh toán số tiền ${formatter.format(totalAmount)} cho đặt vé #${bookingId} qua ví Demo?',
                style: const TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: isPaying ? null : () => Navigator.pop(context),
                  child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: isPaying ? null : () async {
                    setDialogState(() => isPaying = true);
                    try {
                      final confirmedBooking = await bookingService.confirmPayment(bookingId);
                      if (mounted) {
                        Navigator.pop(context);
                        _showTicketDialog(confirmedBooking);
                        _loadBookingHistory();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Thanh toán thất bại: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC084FC)),
                  child: isPaying
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Text('Xác nhận', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSePayPaymentDialog(int bookingId, double totalAmount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final sepayAcc = PaymentConfig.sepayAccountNumber;
    final sepayBank = PaymentConfig.sepayBank;
    final sepayName = PaymentConfig.sepayAccountName;
    final transferAmount = totalAmount.toInt();
    final transferContent = 'SEVQR VE$bookingId';
    final qrUrl = 'https://qr.sepay.vn/img?acc=$sepayAcc&bank=$sepayBank&amount=$transferAmount&des=$transferContent';

    final supabase = Supabase.instance.client;
    
    final bookingStream = supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('id', bookingId)
        .listen((data) {
          if (data.isNotEmpty) {
            final statusStr = data.first['status'] as String;
            if (statusStr == 'CONFIRMED' && Navigator.canPop(context)) {
              Navigator.pop(context);
              _loadBookingHistory();
              bookingService.getBookingById(bookingId).then((updatedBooking) {
                _showTicketDialog(updatedBooking);
              });
            }
          }
        });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isChecking = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF16162A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Thanh Toán SePay',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () {
                      bookingStream.cancel();
                      Navigator.pop(context);
                    },
                  )
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Quét mã VietQR dưới đây để thanh toán chuyển khoản nhanh:',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        qrUrl,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 200,
                            height: 200,
                            color: Colors.white.withOpacity(0.05),
                            child: const Center(
                              child: CircularProgressIndicator(color: Color(0xFFC084FC)),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 200,
                            height: 200,
                            color: Colors.red.withOpacity(0.1),
                            child: const Center(
                              child: Icon(Icons.broken_image, color: Colors.red, size: 40),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTransferInfoRow(
                      context, 
                      'Ngân hàng', 
                      sepayBank,
                      isCopyable: false,
                    ),
                    _buildTransferInfoRow(
                      context, 
                      'Số tài khoản', 
                      sepayAcc,
                      isCopyable: true,
                    ),
                    _buildTransferInfoRow(
                      context, 
                      'Tên tài khoản', 
                      sepayName,
                      isCopyable: false,
                    ),
                    _buildTransferInfoRow(
                      context, 
                      'Số tiền', 
                      formatter.format(totalAmount),
                      isCopyable: true,
                      copyValue: transferAmount.toString(),
                      valueColor: Colors.greenAccent,
                    ),
                    _buildTransferInfoRow(
                      context, 
                      'Nội dung', 
                      transferContent,
                      isCopyable: true,
                      valueColor: const Color(0xFFC084FC),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Color(0xFFC084FC),
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isChecking 
                              ? 'Đang kiểm tra hệ thống...' 
                              : 'Đang chờ hệ thống tự động xác nhận chuyển khoản...',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    bookingStream.cancel();
                    Navigator.pop(context);
                  },
                  child: const Text('Hủy / Đóng', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: isChecking
                      ? null
                      : () async {
                          setDialogState(() => isChecking = true);
                          try {
                            final updated = await bookingService.getBookingById(bookingId);
                            if (updated.status == BookingStatus.confirmed) {
                              bookingStream.cancel();
                              if (context.mounted) {
                                Navigator.pop(context);
                                _loadBookingHistory();
                                _showTicketDialog(updated);
                              }
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Hệ thống chưa nhận được thanh toán. Vui lòng kiểm tra lại sau ít phút.'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Lỗi khi kiểm tra: $e'), backgroundColor: Colors.red),
                              );
                            }
                          } finally {
                            setDialogState(() => isChecking = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC084FC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isChecking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                        )
                      : const Text('Tôi Đã Chuyển Khoản', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      bookingStream.cancel();
    });
  }

  Widget _buildTransferInfoRow(
    BuildContext context, 
    String label, 
    String value, {
    required bool isCopyable,
    String? copyValue,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    value,
                    style: TextStyle(
                      color: valueColor ?? Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isCopyable)
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: copyValue ?? value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã sao chép $label vào bộ nhớ tạm!'),
                          duration: const Duration(seconds: 1),
                          backgroundColor: const Color(0xFFC084FC),
                        ),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Icon(
                        Icons.copy,
                        color: Color(0xFFC084FC),
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCancel(int bookingId) async {
    showDialog(
      context: context,
      builder: (context) {
        bool isCancelling = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1B4B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Hủy Đặt Vé', style: TextStyle(color: Colors.white)),
              content: const Text(
                'Bạn có chắc chắn muốn hủy đặt vé này? Ghế đã chọn sẽ được giải phóng.',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: isCancelling ? null : () => Navigator.pop(context),
                  child: const Text('Không', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: isCancelling ? null : () async {
                    setDialogState(() => isCancelling = true);
                    try {
                      await bookingService.cancelBooking(bookingId);
                      if (mounted) {
                        Navigator.pop(context); // Đóng dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã hủy đặt vé thành công!'), backgroundColor: Colors.green),
                        );
                        _loadBookingHistory(); // Reload history
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Hủy đặt vé thất bại: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: isCancelling
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Xác nhận', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTicketDialog(Booking booking) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: _TicketDialogContent(booking: booking),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context); // Đăng ký lắng nghe sự kiện đổi theme để vẽ lại giao diện lập tức
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Vé Của Tôi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC084FC)))
          : RefreshIndicator(
              onRefresh: _loadBookingHistory,
              color: const Color(0xFFC084FC),
              child: _bookings.isEmpty
                  ? Center(
                      child: Text('Bạn chưa đặt vé nào', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _bookings.length,
                      itemBuilder: (context, index) {
                        final booking = _bookings[index];
                        final showtime = booking.showtime;
                        final movie = showtime?.movie;
                        final room = showtime?.room;
                        final cinema = showtime?.cinema;
                        final seats = booking.seats ?? [];

                        // ✅ Kiểm tra suất chiếu đã qua chưa (so sánh với giờ hiện tại)
                        final bool isShowtimePast = showtime != null
                            ? showtime.startTime.isBefore(DateTime.now())
                            : false;

                        final double totalAmount = booking.totalAmount;
                        final String movieTitle = movie?.title ?? 'Phim';
                        final String cinemaName = cinema?.name ?? 'Rạp';
                        final String roomName = room?.name ?? 'Phòng';
                        final String dateStr = showtime != null 
                            ? DateFormat('dd/MM/yyyy HH:mm').format(showtime.startTime)
                            : '';
                        final String seatNames = seats.map((s) => '${s.row}${s.number}').join(', ');

                        // ✅ Xác định màu & nhãn trạng thái
                        // Nếu PENDING mà suất chiếu đã qua → coi như HẾT HẠN
                        Color statusColor;
                        String statusText;
                        if (booking.status == BookingStatus.confirmed) {
                          statusColor = Colors.green;
                          statusText = 'ĐÃ THANH TOÁN';
                        } else if (booking.status == BookingStatus.cancelled) {
                          statusColor = Colors.red;
                          statusText = 'ĐÃ HỦY';
                        } else if (booking.status == BookingStatus.expired ||
                            (booking.status == BookingStatus.pending && isShowtimePast)) {
                          statusColor = Colors.grey.shade600;
                          statusText = 'HẾT HẠN';
                        } else {
                          // PENDING và suất chiếu chưa qua
                          statusColor = const Color(0xFFF59E0B);
                          statusText = 'CHỜ THANH TOÁN';
                        }

                        return Card(
                          color: AppColors.surface,
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header: Status & Booking ID
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Mã đặt vé: #${booking.id}',
                                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        statusText,
                                        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Movie Title
                                  Text(
                                    movieTitle,
                                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                const SizedBox(height: 8),

                                // Cinema and Date
                                  Text('$cinemaName - $roomName (${room?.roomType ?? '2D'})', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                const SizedBox(height: 4),
                                 // Ngày chiếu: đỏ nếu đã qua, tím nếu còn hạn
                                 Text(
                                   dateStr,
                                   style: TextStyle(
                                     color: isShowtimePast
                                         ? Colors.redAccent
                                         : const Color(0xFFC084FC),
                                     fontSize: 12,
                                     fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                 const SizedBox(height: 6),
                                 
                                 // Seat list
                                 Text('Danh sách ghế: $seatNames', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                 if (booking.orderItems != null && booking.orderItems!.isNotEmpty) ...[
                                   const SizedBox(height: 6),
                                   Text(
                                     'Bắp nước: ${booking.orderItems!.map((item) => '${item.itemName} (x${item.quantity})').join(', ')}',
                                     style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                   ),
                                 ],
                                 const SizedBox(height: 12),
                                 
                                 Divider(color: AppColors.border),
                                 const SizedBox(height: 8),
                                 
                                 // Pricing and Action Buttons
                                 Row(
                                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                   children: [
                                     Column(
                                       crossAxisAlignment: CrossAxisAlignment.start,
                                       children: [
                                         Text('Tổng tiền:', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                         Text(formatter.format(totalAmount), style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                                       ],
                                     ),
                                     
                                     // ✅ Actions theo trạng thái:
                                     // - PENDING + suất chiếu chưa qua → Hủy + Thanh Toán
                                     // - PENDING + suất chiếu ĐÃ QUA → Badge "Hết Hạn" (không cho thanh toán)
                                     // - CONFIRMED → Xem QR
                                     if (booking.status == BookingStatus.pending && !isShowtimePast)
                                       Row(
                                         children: [
                                           TextButton(
                                             onPressed: () => _handleCancel(booking.id),
                                             child: const Text('Hủy', style: TextStyle(color: Colors.redAccent)),
                                           ),
                                           const SizedBox(width: 8),
                                           ElevatedButton(
                                             onPressed: () => _handlePayment(booking.id, totalAmount),
                                             style: ElevatedButton.styleFrom(
                                               backgroundColor: Colors.green,
                                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                             ),
                                             child: const Text('Thanh Toán', style: TextStyle(color: Colors.white, fontSize: 12)),
                                           ),
                                         ],
                                       )
                                     else if (booking.status == BookingStatus.pending && isShowtimePast)
                                       // Pending nhưng suất đã qua → hiện hết hạn
                                       Container(
                                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                         decoration: BoxDecoration(
                                           color: Colors.grey.withOpacity(0.12),
                                           borderRadius: BorderRadius.circular(8),
                                           border: Border.all(color: Colors.grey.withOpacity(0.3)),
                                         ),
                                         child: Row(
                                           mainAxisSize: MainAxisSize.min,
                                           children: [
                                             Icon(Icons.event_busy_rounded, size: 13, color: Colors.grey.shade500),
                                             const SizedBox(width: 5),
                                             Text(
                                               'Hết Hạn',
                                               style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold),
                                             ),
                                           ],
                                         ),
                                       )
                                     else if (booking.status == BookingStatus.confirmed && booking.ticket != null)
                                       Builder(
                                         builder: (context) {
                                           final ticket = booking.ticket!;
                                           if (ticket.status == TicketStatus.used) {
                                             return Container(
                                               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                               decoration: BoxDecoration(
                                                 color: Colors.grey.withOpacity(0.1),
                                                 borderRadius: BorderRadius.circular(8),
                                                 border: Border.all(color: Colors.white24),
                                               ),
                                               child: const Text(
                                                 'Vé Đã Sử Dụng',
                                                 style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold),
                                               ),
                                             );
                                           } else if (ticket.status == TicketStatus.expired) {
                                             return Container(
                                               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                               decoration: BoxDecoration(
                                                 color: Colors.grey.shade900,
                                                 borderRadius: BorderRadius.circular(8),
                                               ),
                                               child: Text(
                                                 'Vé Đã Hết Hạn',
                                                 style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold),
                                               ),
                                             );
                                           } else {
                                             return ElevatedButton.icon(
                                               onPressed: () {
                                                 _showTicketDialog(booking);
                                               },
                                               icon: const Icon(Icons.qr_code, size: 16),
                                               label: const Text('Xem Vé QR', style: TextStyle(fontSize: 12)),
                                               style: ElevatedButton.styleFrom(
                                                 backgroundColor: const Color(0xFFC084FC),
                                                 foregroundColor: Colors.black,
                                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                               ),
                                             );
                                           }
                                         },
                                       ),
                                   ],
                                 ),
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

/// Giao diện thiết kế Vé vật lý bằng Clipper cắt góc lẹm răng cưa ở hai bên cuống vé
class TicketClipper extends CustomClipper<Path> {
  final double punchRadius;
  final double punchPositionY; // Tỷ lệ vị trí lẹm của vé từ đỉnh xuống (ví dụ: 0.6)

  TicketClipper({this.punchRadius = 10.0, this.punchPositionY = 0.58});

  @override
  Path getClip(Size size) {
    final path = Path();
    final double py = size.height * punchPositionY;

    // Bắt đầu từ góc trên bên trái
    path.moveTo(0.0, 0.0);
    // Đường ngang trên
    path.lineTo(size.width, 0.0);
    // Đi xuống cạnh phải tới trước vết xé cuống vé
    path.lineTo(size.width, py - punchRadius);
    // Vẽ nửa hình tròn khoét sâu vào trong vé (Cạnh phải)
    path.arcToPoint(
      Offset(size.width, py + punchRadius),
      radius: Radius.circular(punchRadius),
      clockwise: false,
    );
    // Đi tiếp xuống góc dưới bên phải
    path.lineTo(size.width, size.height);
    // Đường ngang dưới
    path.lineTo(0.0, size.height);
    // Đi lên cạnh trái tới vết xé cuống vé
    path.lineTo(0.0, py + punchRadius);
    // Vẽ nửa hình tròn khoét sâu vào trong vé (Cạnh trái)
    path.arcToPoint(
      Offset(0.0, py - punchRadius),
      radius: Radius.circular(punchRadius),
      clockwise: false,
    );
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// Hỗ trợ vẽ đường đứt nét (dashed line) chia cắt thân vé và cuống vé
class TicketSeparatorPainter extends CustomPainter {
  final Color color;
  final double width;

  TicketSeparatorPainter({this.color = Colors.white24, this.width = 1.5});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;

    const double dashWidth = 5.0;
    const double dashSpace = 4.0;
    double startX = 0.0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Widget Stateful quản lý giao diện cuống vé và tự động tăng 100% độ sáng màn hình
class _TicketDialogContent extends StatefulWidget {
  final Booking booking;

  const _TicketDialogContent({required this.booking});

  @override
  State<_TicketDialogContent> createState() => _TicketDialogContentState();
}

class _TicketDialogContentState extends State<_TicketDialogContent> {
  double? _originalBrightness;

  @override
  void initState() {
    super.initState();
    _setFullBrightness();
  }

  Future<void> _setFullBrightness() async {
    try {
      _originalBrightness = await ScreenBrightness().application;
      await ScreenBrightness().setApplicationScreenBrightness(1.0);
    } catch (e) {
      debugPrint('Lỗi khi thiết lập độ sáng 100%: $e');
    }
  }

  Future<void> _resetBrightness() async {
    try {
      if (_originalBrightness != null) {
        await ScreenBrightness().setApplicationScreenBrightness(_originalBrightness!);
      } else {
        await ScreenBrightness().resetApplicationScreenBrightness();
      }
    } catch (e) {
      debugPrint('Lỗi khi khôi phục độ sáng màn hình: $e');
    }
  }

  @override
  void dispose() {
    _resetBrightness();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final showtime = booking.showtime;
    final movie = showtime?.movie;
    final room = showtime?.room;
    final cinema = showtime?.cinema;
    final seats = booking.seats ?? [];

    final String movieTitle = movie?.title ?? 'Phim';
    final String cinemaName = cinema?.name ?? 'Rạp';
    final String roomName = room?.name ?? 'Phòng';
    final String dateStr = showtime != null 
        ? DateFormat('dd/MM/yyyy HH:mm').format(showtime.startTime)
        : '';
    final String seatNames = seats.map((s) => '${s.row}${s.number}').join(', ');
    final String ticketCode = booking.ticket?.ticketCode ?? '';

    return ClipPath(
      clipper: TicketClipper(punchRadius: 12.0, punchPositionY: 0.58),
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1B4B), // Elevated Indigo surface
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // === PHẦN THÂN VÉ (Thông tin chi tiết suất chiếu) ===
            Padding(
              padding: const EdgeInsets.all(22.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'VÉ XEM PHIM',
                        style: GoogleFonts.robotoMono(
                          color: const Color(0xFFC084FC),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 2.0,
                        ),
                      ),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Tên Phim (Bold và Lớn)
                  Text(
                    movieTitle,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Chi tiết cụ thể
                  _buildTicketInfoRow('RẠP & PHÒNG CHIẾU', '$cinemaName - $roomName (${room?.roomType ?? '2D'})'),
                  const SizedBox(height: 12),
                  _buildTicketInfoRow('THỜI GIAN CHIẾU', dateStr),
                  const SizedBox(height: 12),
                  _buildTicketInfoRow('SỐ GHẾ ĐÃ ĐẶT', seatNames),
                  
                  if (booking.orderItems != null && booking.orderItems!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildTicketInfoRow(
                      'BẮP NƯỚC KÈM THEO',
                      booking.orderItems!.map((item) => '${item.itemName} (x${item.quantity})').join(', '),
                    ),
                  ],
                ],
              ),
            ),

            // === ĐƯỜNG RĂNG CƯA PHÂN TÁCH CUỐNG VÉ ===
            CustomPaint(
              size: const Size(double.infinity, 1),
              painter: TicketSeparatorPainter(color: Colors.white12, width: 1.5),
            ),

            // === PHẦN CUỐNG VÉ (Mã QR Code Soát Vé) ===
            Padding(
              padding: const EdgeInsets.all(22.0),
              child: Column(
                children: [
                  // QR Code bọc trong hộp trắng tương phản cực cao
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFC084FC), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFC084FC).withOpacity(0.2),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    width: 170,
                    height: 170,
                    child: QrImageView(
                      data: ticketCode,
                      version: QrVersions.auto,
                      size: 170.0,
                      gapless: false,
                    ),
                  ),
                  const SizedBox(height: 14),
                  
                  // Mã String của Vé
                  Text(
                    'MÃ VÉ: $ticketCode',
                    style: GoogleFonts.robotoMono(
                      color: const Color(0xFFC084FC),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Trình mã này tại quầy để soát vé vào phòng',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF6B6B8A),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.robotoMono(
            color: const Color(0xFF6B6B8A), // textMuted
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
      ],
    );
  }
}
