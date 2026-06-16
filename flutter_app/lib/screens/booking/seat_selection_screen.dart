import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/movie_service.dart';
import '../../services/booking_service.dart';

class SeatSelectionScreen extends StatefulWidget {
  final String showtimeId;

  const SeatSelectionScreen({super.key, required this.showtimeId});

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _showtime;
  List<dynamic> _seats = [];
  final Set<int> _selectedSeatIds = {};
  
  final _promoController = TextEditingController();
  String? _appliedPromoCode;
  double _discountedAmount = 0.0;
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    _loadSeatLayout();
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  Future<void> _loadSeatLayout() async {
    setState(() => _isLoading = true);
    try {
      final showtime = await movieService.getShowtimeById(widget.showtimeId);
      setState(() {
        _showtime = showtime;
        _seats = showtime['seats'] ?? [];
        _selectedSeatIds.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải sơ đồ ghế: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _calculateSubtotal() {
    if (_showtime == null) return 0.0;
    final double basePrice = (_showtime!['price'] as num).toDouble();
    double subtotal = 0.0;

    for (var seatId in _selectedSeatIds) {
      final seat = _seats.firstWhere((s) => s['id'] == seatId);
      double seatPrice = basePrice;
      if (seat['type'] == 'VIP') {
        seatPrice += 20000;
      } else if (seat['type'] == 'COUPLE') {
        seatPrice += 40000;
      }
      subtotal += seatPrice;
    }
    return subtotal;
  }

  void _toggleSeat(dynamic seat) {
    if (seat['isBooked'] == true || seat['status'] != 'AVAILABLE') return;
    
    final int id = seat['id'];
    setState(() {
      if (_selectedSeatIds.contains(id)) {
        _selectedSeatIds.remove(id);
      } else {
        _selectedSeatIds.add(id);
      }
    });
  }

  Future<void> _handleBookTickets() async {
    if (_selectedSeatIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất 1 ghế')),
      );
      return;
    }

    setState(() => _isBooking = true);
    try {
      final subtotal = _calculateSubtotal();
      final promo = _promoController.text.trim();

      // Convert selected integer ids to string seatIds (e.g. 'A1', 'B5')
      final selectedSeatCodes = _selectedSeatIds.map((id) {
        final seat = _seats.firstWhere((s) => s['id'] == id);
        return seat['seatId'] as String;
      }).toList();

      debugPrint('[SeatSelectionScreen] Requesting booking: showtimeId=${widget.showtimeId}, seatIds=$selectedSeatCodes');

      // 1. Tạo đơn đặt vé PENDING
      final bookingResult = await bookingService.createBooking(
        showtimeId: widget.showtimeId,
        seatIds: selectedSeatCodes,
        promotionCode: promo.isNotEmpty ? promo : null,
      );

      final String bookingId = bookingResult['bookingId'] as String;
      final double totalAmount = (bookingResult['totalAmount'] as num).toDouble();
      debugPrint('[SeatSelectionScreen] Booking created successfully: ID=$bookingId, Amount=$totalAmount');

      if (mounted) {
        // 2. Hiển thị Dialog xác nhận thanh toán Demo
        _showPaymentConfirmationDialog(bookingId, totalAmount);
      }
    } catch (e) {
      debugPrint('[SeatSelectionScreen] Booking creation failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đặt vé thất bại: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  void _showPaymentConfirmationDialog(String bookingId, double totalAmount) {
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
              title: const Text('Thanh Toán Vé', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bạn đang thanh toán đơn đặt vé số:', style: TextStyle(color: Colors.white70)),
                  Text('#$bookingId', style: const TextStyle(color: Color(0xFFC084FC), fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Phương thức:', style: TextStyle(color: Colors.white70)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.purple.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                        child: const Text('Ví Điện Tử Demo', style: TextStyle(color: Color(0xFFC084FC), fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng tiền:', style: TextStyle(color: Colors.white70)),
                      Text(formatter.format(totalAmount), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 20)),
                    ],
                  ),
                ],
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
                      debugPrint('[SeatSelectionScreen] Initiating payment for booking: $bookingId');
                      final result = await bookingService.confirmDemoPayment(bookingId);
                      debugPrint('[SeatSelectionScreen] Payment successful for booking: $bookingId');
                      if (mounted) {
                        Navigator.pop(context); // Đóng dialog thanh toán
                        _showTicketDialog(result); // Hiện vé xem phim kèm mã QR
                      }
                    } catch (e) {
                      debugPrint('[SeatSelectionScreen] Payment confirmation failed: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Thanh toán thất bại: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC084FC), foregroundColor: Colors.black),
                  child: isPaying
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Text('Thanh Toán', style: TextStyle(fontWeight: FontWeight.bold)),
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
    final booking = result['booking'];
    final String ticketCode = ticket['ticketCode'] ?? '';
    final String qrCodeUrl = ticket['qrCode'] ?? '';
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1B4B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars, color: Colors.amber, size: 60),
                const SizedBox(height: 12),
                const Text('Đặt Vé Thành Công!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                const SizedBox(height: 8),
                const Text('Cảm ơn bạn đã mua vé. Vé của bạn đã được kích hoạt.', style: TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                
                // QR Code
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(12),
                    height: 200,
                    width: 200,
                    child: Image.network(
                      qrCodeUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: CircularProgressIndicator(color: Colors.purple));
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Ticket Code Text
                Text(
                  'MÃ VÉ: $ticketCode',
                  style: const TextStyle(color: Color(0xFFC084FC), fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.5),
                ),
                const SizedBox(height: 20),
                
                const Divider(color: Colors.white10),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tổng thanh toán:', style: TextStyle(color: Colors.white54, fontSize: 13)),
                    Text(formatter.format(booking['totalAmount']), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Đóng Dialog vé
                  Navigator.pop(context); // Quay về màn hình chi tiết phim
                  _loadSeatLayout(); // Reset layout
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC084FC),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Hoàn Thành', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F1A),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFC084FC))),
      );
    }

    // Group seats by row
    final Map<String, List<dynamic>> seatsByRow = {};
    for (var seat in _seats) {
      final String r = seat['row'] ?? '';
      seatsByRow.putIfAbsent(r, () => []).add(seat);
    }

    final double subtotal = _calculateSubtotal();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        title: const Text('Chọn Ghế', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF16162A),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Screen Indicator
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFFC084FC),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFC084FC).withOpacity(0.5), blurRadius: 10, spreadRadius: 2),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(child: Text('MÀN HÌNH CHIẾU', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 4))),
          const SizedBox(height: 32),

          // Legend Indicators
          _buildLegends(),
          const SizedBox(height: 24),

          // Seat Grid
          Expanded(
            child: _seats.isEmpty
                ? const Center(child: Text('Đang tải sơ đồ ghế...', style: TextStyle(color: Colors.white54)))
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: seatsByRow.keys.map((rowKey) {
                          final rowSeats = seatsByRow[rowKey]!;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Row Letter Label Left
                                SizedBox(
                                  width: 24,
                                  child: Text(rowKey, style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                                ),
                                // Seats List in Row
                                ...rowSeats.map((seat) {
                                  final bool isSelected = _selectedSeatIds.contains(seat['id']);
                                  final bool isBooked = seat['isBooked'] == true;
                                  final bool isMaintenance = seat['status'] == 'MAINTENANCE';

                                  Color seatColor = Colors.white24;
                                  IconData? icon;

                                  if (isBooked) {
                                    seatColor = const Color(0xFF1E1E2E);
                                    icon = Icons.lock_outline;
                                  } else if (isMaintenance) {
                                    seatColor = Colors.grey.shade800;
                                    icon = Icons.construction;
                                  } else if (isSelected) {
                                    seatColor = const Color(0xFF4ADE80); // Bright Green
                                  } else {
                                    if (seat['type'] == 'VIP') {
                                      seatColor = const Color(0xFFF97316); // Orange
                                    } else if (seat['type'] == 'COUPLE') {
                                      seatColor = const Color(0xFFEF4444); // Red
                                    } else {
                                      seatColor = Colors.white54; // Standard
                                    }
                                  }

                                  return GestureDetector(
                                    onTap: () => _toggleSeat(seat),
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      decoration: BoxDecoration(
                                        color: isSelected ? seatColor : Colors.transparent,
                                        border: Border.all(color: seatColor, width: 2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: icon != null
                                            ? Icon(icon, color: Colors.white38, size: 16)
                                            : Text(
                                                '${seat['number']}',
                                                style: TextStyle(
                                                  color: isSelected ? Colors.black : Colors.white70,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),

          // Bottom Bar containing Total, Promo and Book Button
          Container(
            color: const Color(0xFF16162A),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Promo code
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _promoController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Nhập mã khuyến mãi (ví dụ: WELCOME10)',
                            hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Pricing & Confirm Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tạm tính:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            formatter.format(subtotal),
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (_selectedSeatIds.isEmpty || _isBooking) ? null : _handleBookTickets,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC084FC),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isBooking
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                              : const Text('Đặt Vé Ngay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegends() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(color: Colors.white54, label: 'Thường'),
        SizedBox(width: 16),
        _LegendItem(color: Color(0xFFF97316), label: 'VIP'),
        SizedBox(width: 16),
        _LegendItem(color: Color(0xFFEF4444), label: 'Ghế đôi'),
        SizedBox(width: 16),
        _LegendItem(color: Color(0xFF4ADE80), label: 'Đang chọn'),
        SizedBox(width: 16),
        _LegendItem(color: Color(0xFF1E1E2E), label: 'Đã đặt', hasIcon: true),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool hasIcon;

  const _LegendItem({required this.color, required this.label, this.hasIcon = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: hasIcon ? color : Colors.transparent,
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: hasIcon ? const Icon(Icons.lock_outline, size: 10, color: Colors.white38) : null,
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }
}
