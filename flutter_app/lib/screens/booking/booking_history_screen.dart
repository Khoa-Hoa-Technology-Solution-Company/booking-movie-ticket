import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/booking_service.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  bool _isLoading = false;
  List<dynamic> _bookings = [];

  @override
  void initState() {
    super.initState();
    _loadBookingHistory();
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

  Future<void> _handlePayment(String bookingId, double totalAmount) async {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    
    showDialog(
      context: context,
      builder: (context) {
        bool isPaying = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1B4B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Thanh Toán Vé', style: TextStyle(color: Colors.white)),
              content: Text(
                'Thanh toán số tiền ${formatter.format(totalAmount)} cho đặt vé #${bookingId}?',
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
                      debugPrint('[BookingHistoryScreen] Confirming payment for booking: $bookingId');
                      final result = await bookingService.confirmDemoPayment(bookingId);
                      debugPrint('[BookingHistoryScreen] Payment confirmed successfully for booking: $bookingId');
                      if (mounted) {
                        Navigator.pop(context); // Đóng dialog thanh toán
                        _showTicketDialog(result);
                        _loadBookingHistory(); // Reload history
                      }
                    } catch (e) {
                      debugPrint('[BookingHistoryScreen] Payment confirmation failed: $e');
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
                      : const Text('Xác nhận', style: TextStyle(color: Colors.black)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleCancel(String bookingId) async {
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
                      debugPrint('[BookingHistoryScreen] Requesting cancellation for booking: $bookingId');
                      await bookingService.cancelBooking(bookingId);
                      debugPrint('[BookingHistoryScreen] Booking cancelled successfully: $bookingId');
                      if (mounted) {
                        Navigator.pop(context); // Đóng dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã hủy đặt vé thành công!'), backgroundColor: Colors.green),
                        );
                        _loadBookingHistory(); // Reload history
                      }
                    } catch (e) {
                      debugPrint('[BookingHistoryScreen] Cancellation failed: $e');
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

  void _showTicketDialog(Map<String, dynamic> result) {
    final ticket = result['ticket'];
    final String ticketCode = ticket['ticketCode'] ?? '';
    final String qrCodeUrl = ticket['qrCode'] ?? '';

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
                  child: Image.network(
                    qrCodeUrl,
                    fit: BoxFit.contain,
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
                        final showtime = booking['showtime'];
                        final movie = showtime?['movie'];
                        final room = showtime?['room'];
                        final cinema = room?['cinema'];
                        final bookingSeats = booking['bookingSeats'] ?? [];
                        final tickets = booking['tickets'] ?? [];
                        
                        final double totalAmount = (booking['totalAmount'] as num).toDouble();
                        final String movieTitle = movie?['title'] ?? 'Phim';
                        final String cinemaName = cinema?['name'] ?? 'Rạp';
                        final String roomName = room?['name'] ?? 'Phòng';
                        final String dateStr = showtime != null 
                            ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(showtime['startTime']).toLocal())
                            : '';
                        final String seatNames = bookingSeats.map((bs) => '${bs['seat']?['row'] ?? ''}${bs['seat']?['number'] ?? ''}').join(', ');

                        Color statusColor = Colors.grey;
                        String statusText = 'PENDING';
                        if (booking['status'] == 'CONFIRMED') {
                          statusColor = Colors.green;
                          statusText = 'ĐÃ THANH TOÁN';
                        } else if (booking['status'] == 'CANCELLED') {
                          statusColor = Colors.red;
                          statusText = 'ĐÃ HỦY';
                        } else if (booking['status'] == 'EXPIRED') {
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
                                      'Mã đặt vé: #${booking['id']}',
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
                                Text('$cinemaName - $roomName', style: const TextStyle(color: Colors.white70, fontSize: 13)),
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
                                    if (booking['status'] == 'PENDING')
                                      Row(
                                        children: [
                                          TextButton(
                                            onPressed: () => _handleCancel(booking['id']),
                                            child: const Text('Hủy', style: TextStyle(color: Colors.redAccent)),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            onPressed: () => _handlePayment(booking['id'], totalAmount),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                            child: const Text('Thanh Toán', style: TextStyle(color: Colors.white, fontSize: 12)),
                                          ),
                                        ],
                                      )
                                    else if (booking['status'] == 'CONFIRMED' && tickets.isNotEmpty)
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          _showTicketDialog({
                                            'ticket': tickets[0],
                                            'booking': booking,
                                          });
                                        },
                                        icon: const Icon(Icons.qr_code, size: 16),
                                        label: const Text('Xem Vé QR', style: TextStyle(fontSize: 12)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFC084FC),
                                          foregroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
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
