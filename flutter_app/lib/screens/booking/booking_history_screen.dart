import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/payment_config.dart';
import '../../services/booking_service.dart';
import '../../models/booking.dart';

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
    final ticket = booking.ticket;
    final String ticketCode = ticket?.ticketCode ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1B4B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.confirmation_number, color: Color(0xFFC084FC), size: 50),
              const SizedBox(height: 12),
              const Text('Vé Xem Phim', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(12),
                  height: 180,
                  width: 180,
                  child: QrImageView(
                    data: ticketCode,
                    version: QrVersions.auto,
                    size: 180.0,
                    gapless: false,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'MÃ VÉ: $ticketCode',
                style: const TextStyle(color: Color(0xFFC084FC), fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2),
              ),
              const SizedBox(height: 8),
              const Text('Vui lòng đưa mã này tại quầy soát vé để vào phòng chiếu', style: TextStyle(color: Colors.white54, fontSize: 11), textAlign: TextAlign.center),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC084FC), foregroundColor: Colors.black),
                child: const Text('Đóng'),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        title: const Text('Vé Của Tôi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF16162A),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC084FC)))
          : RefreshIndicator(
              onRefresh: _loadBookingHistory,
              color: const Color(0xFFC084FC),
              child: _bookings.isEmpty
                  ? const Center(
                      child: Text('Bạn chưa đặt vé nào', style: TextStyle(color: Colors.white54, fontSize: 16)),
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
                        
                        final double totalAmount = booking.totalAmount;
                        final String movieTitle = movie?.title ?? 'Phim';
                        final String cinemaName = cinema?.name ?? 'Rạp';
                        final String roomName = room?.name ?? 'Phòng';
                        final String dateStr = showtime != null 
                            ? DateFormat('dd/MM/yyyy HH:mm').format(showtime.startTime)
                            : '';
                        final String seatNames = seats.map((s) => '${s.row}${s.number}').join(', ');

                        Color statusColor = Colors.grey;
                        String statusText = 'PENDING';
                        if (booking.status == BookingStatus.confirmed) {
                          statusColor = Colors.green;
                          statusText = 'ĐÃ THANH TOÁN';
                        } else if (booking.status == BookingStatus.cancelled) {
                          statusColor = Colors.red;
                          statusText = 'ĐÃ HỦY';
                        } else if (booking.status == BookingStatus.expired) {
                          statusColor = Colors.grey.shade700;
                          statusText = 'HẾT HẠN';
                        }

                        return Card(
                          color: const Color(0xFF16162A),
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
                                      style: const TextStyle(color: Colors.white54, fontSize: 12),
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
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 8),

                                // Cinema and Date
                                Text('$cinemaName - $roomName (${room?.roomType ?? '2D'})', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                const SizedBox(height: 4),
                                Text(dateStr, style: const TextStyle(color: Color(0xFFC084FC), fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                
                                // Seat list
                                Text('Danh sách ghế: $seatNames', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                const SizedBox(height: 12),
                                
                                const Divider(color: Colors.white10),
                                const SizedBox(height: 8),
                                
                                // Pricing and Action Buttons
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Tổng tiền:', style: TextStyle(color: Colors.white38, fontSize: 11)),
                                        Text(formatter.format(totalAmount), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                      ],
                                    ),
                                    
                                    // Actions: If Pending -> Pay / Cancel; If Confirmed -> View Ticket QR
                                    if (booking.status == BookingStatus.pending)
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
