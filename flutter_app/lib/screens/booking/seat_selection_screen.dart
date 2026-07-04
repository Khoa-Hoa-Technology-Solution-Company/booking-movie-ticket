import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/payment_config.dart';
import '../../services/movie_service.dart';
import '../../services/booking_service.dart';
import '../../models/showtime.dart';
import '../../models/booking.dart';

class SeatSelectionScreen extends StatefulWidget {
  final int showtimeId;

  const SeatSelectionScreen({super.key, required this.showtimeId});

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  bool _isLoading = false;
  ShowtimeDetail? _showtimeDetail;
  final Set<int> _selectedSeatIds = {};

  final _promoController = TextEditingController();
  bool _isBooking = false;

  // Trạng thái mã khuyến mãi
  Map<String, dynamic>? _appliedPromo;
  double _discountAmount = 0.0;
  bool _isValidatingPromo = false;
  String? _promoError;

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

  void _recalculateDiscount() {
    if (_appliedPromo == null) return;
    final subtotal = _calculateSubtotal();
    final minPurchase = (_appliedPromo!['min_purchase'] as num?)?.toDouble() ?? 0.0;
    
    if (subtotal < minPurchase) {
      setState(() {
        _appliedPromo = null;
        _discountAmount = 0.0;
        _promoError = 'Chưa đạt giá trị đơn hàng tối thiểu để áp dụng mã';
      });
      return;
    }

    final discountPercent = _appliedPromo!['discount_percent'] as int;
    final maxDiscount = (_appliedPromo!['max_discount'] as num?)?.toDouble();
    double discount = subtotal * (discountPercent / 100);
    if (maxDiscount != null && discount > maxDiscount) {
      discount = maxDiscount;
    }

    setState(() {
      _discountAmount = discount;
    });
  }

  Future<void> _applyPromotion() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isValidatingPromo = true;
      _promoError = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('promotions')
          .select()
          .eq('code', code)
          .eq('active', true)
          .maybeSingle();

      if (response == null) {
        setState(() {
          _promoError = 'Mã khuyến mãi không tồn tại hoặc đã hết hạn';
          _appliedPromo = null;
          _discountAmount = 0.0;
        });
        return;
      }

      final startDate = DateTime.parse(response['start_date'] as String);
      final endDate = DateTime.parse(response['end_date'] as String);
      final now = DateTime.now();

      if (now.isBefore(startDate) || now.isAfter(endDate)) {
        setState(() {
          _promoError = 'Mã khuyến mãi chưa có hiệu lực hoặc đã hết hạn';
          _appliedPromo = null;
          _discountAmount = 0.0;
        });
        return;
      }

      final usageLimit = response['usage_limit'] as int?;
      final usageCount = response['usage_count'] as int? ?? 0;
      if (usageLimit != null && usageCount >= usageLimit) {
        setState(() {
          _promoError = 'Mã khuyến mãi đã hết lượt sử dụng';
          _appliedPromo = null;
          _discountAmount = 0.0;
        });
        return;
      }

      final minPurchase = (response['min_purchase'] as num?)?.toDouble() ?? 0.0;
      final subtotal = _calculateSubtotal();
      if (subtotal < minPurchase) {
        final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
        setState(() {
          _promoError = 'Đơn hàng tối thiểu phải từ ${formatter.format(minPurchase)}';
          _appliedPromo = null;
          _discountAmount = 0.0;
        });
        return;
      }

      final discountPercent = response['discount_percent'] as int;
      final maxDiscount = (response['max_discount'] as num?)?.toDouble();
      double discount = subtotal * (discountPercent / 100);
      if (maxDiscount != null && discount > maxDiscount) {
        discount = maxDiscount;
      }

      setState(() {
        _appliedPromo = response;
        _discountAmount = discount;
        _promoError = null;
      });
    } catch (e) {
      setState(() {
        _promoError = 'Lỗi kiểm tra mã: $e';
        _appliedPromo = null;
        _discountAmount = 0.0;
      });
    } finally {
      setState(() => _isValidatingPromo = false);
    }
  }

  void _removePromotion() {
    setState(() {
      _promoController.clear();
      _appliedPromo = null;
      _discountAmount = 0.0;
      _promoError = null;
    });
  }

  Future<void> _loadSeatLayout() async {
    setState(() => _isLoading = true);
    try {
      final showtimeDetail = await movieService.getShowtimeDetail(
        widget.showtimeId,
      );
      setState(() {
        _showtimeDetail = showtimeDetail;
        _selectedSeatIds.clear();
        _appliedPromo = null;
        _discountAmount = 0.0;
        _promoError = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể tải sơ đồ ghế: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _calculateSubtotal() {
    if (_showtimeDetail == null) return 0.0;
    final double basePrice = _showtimeDetail!.showtime.price;
    double subtotal = 0.0;

    for (var seatId in _selectedSeatIds) {
      final seat = _showtimeDetail!.seats.firstWhere((s) => s.id == seatId);
      double seatPrice = basePrice;
      if (seat.type == SeatType.vip) {
        seatPrice += 20000;
      } else if (seat.type == SeatType.couple) {
        seatPrice += 40000;
      }
      subtotal += seatPrice;
    }
    return subtotal;
  }

  void _toggleSeat(Seat seat) {
    if (seat.status == SeatStatus.booked ||
        seat.status == SeatStatus.maintenance) {
      return;
    }

    if (seat.status == SeatStatus.held) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ghế này đang được người khác giữ.')),
      );
      return;
    }

    final int id = seat.id;
    final isSelecting = !_selectedSeatIds.contains(id);

    setState(() {
      if (isSelecting) {
        _selectedSeatIds.add(id);
      } else {
        _selectedSeatIds.remove(id);
      }
      _recalculateDiscount();
    });

    _syncSeatHold(seat.id, isSelecting);
  }

  Future<void> _syncSeatHold(int seatId, bool isSelecting) async {
    final supabase = Supabase.instance.client;
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    try {
      if (isSelecting) {
        await supabase.from('seat_holds').insert({
          'seat_id': seatId,
          'showtime_id': widget.showtimeId,
          'user_id': currentUserId,
        });
      } else {
        await supabase.from('seat_holds').delete().match({
          'seat_id': seatId,
          'showtime_id': widget.showtimeId,
          'user_id': currentUserId,
        });
      }
    } catch (e) {
      if (isSelecting && mounted) {
        setState(() {
          _selectedSeatIds.remove(seatId);
          _recalculateDiscount();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ghế này đã bị người khác chọn trước!'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadSeatLayout(); // Tải lại sơ đồ ghế mới nhất
      }
    }
  }

  Future<void> _handleBookTickets() async {
    if (_selectedSeatIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất 1 ghế')),
      );
      return;
    }

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
                    _processBookingWithMethod('DEMO');
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
                    _processBookingWithMethod('SEPAY');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  Future<void> _processBookingWithMethod(String paymentMethod) async {
    setState(() => _isBooking = true);
    try {
      final promo = _appliedPromo != null ? _appliedPromo!['code'] as String : null;

      // 1. Tạo đơn đặt vé với phương thức thanh toán đã chọn
      final booking = await bookingService.createBooking(
        showtimeId: widget.showtimeId,
        seatIds: _selectedSeatIds.toList(),
        promotionCode: promo,
        paymentMethod: paymentMethod,
      );

      if (mounted) {
        if (paymentMethod == 'DEMO') {
          _showPaymentConfirmationDialog(booking);
        } else {
          _showSePayPaymentDialog(booking);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đặt vé thất bại: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  void _showSePayPaymentDialog(Booking booking) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final sepayAcc = PaymentConfig.sepayAccountNumber;
    final sepayBank = PaymentConfig.sepayBank;
    final sepayName = PaymentConfig.sepayAccountName;
    final transferAmount = booking.totalAmount.toInt();
    final transferContent = 'SEVQR VE${booking.id}';
    final qrUrl = 'https://qr.sepay.vn/img?acc=$sepayAcc&bank=$sepayBank&amount=$transferAmount&des=$transferContent';

    // Đăng ký realtime lắng nghe thay đổi trạng thái booking
    final supabase = Supabase.instance.client;
    
    // Tạo stream lắng nghe thay đổi của booking này
    final bookingStream = supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('id', booking.id)
        .listen((data) {
          if (data.isNotEmpty) {
            final statusStr = data.first['status'] as String;
            if (statusStr == 'CONFIRMED' && Navigator.canPop(context)) {
              Navigator.pop(context); // Đóng dialog SePay
              _loadSeatLayout();
              bookingService.getBookingById(booking.id).then((updatedBooking) {
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
                      formatter.format(booking.totalAmount),
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
                            final updated = await bookingService.getBookingById(booking.id);
                            if (updated.status == BookingStatus.confirmed) {
                              bookingStream.cancel();
                              if (context.mounted) {
                                Navigator.pop(context); // Đóng dialog
                                _loadSeatLayout();
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

  void _showPaymentConfirmationDialog(Booking booking) {
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                'Thanh Toán Vé',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bạn đang thanh toán đơn đặt vé số:',
                    style: TextStyle(color: Colors.white70),
                  ),
                  Text(
                    '#${booking.id}',
                    style: const TextStyle(
                      color: Color(0xFFC084FC),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Phương thức:',
                        style: TextStyle(color: Colors.white70),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC084FC).withAlpha(51),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Ví Điện Tử Demo',
                          style: TextStyle(
                            color: Color(0xFFC084FC),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tổng tiền:',
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        formatter.format(booking.totalAmount),
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isPaying ? null : () => Navigator.pop(context),
                  child: const Text(
                    'Hủy',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
                ElevatedButton(
                  onPressed: isPaying
                      ? null
                      : () async {
                          setDialogState(() => isPaying = true);
                          try {
                            final result = await bookingService.confirmPayment(
                              booking.id,
                            );
                            if (mounted) {
                              Navigator.pop(context); // Đóng dialog thanh toán
                              _showTicketDialog(
                                result,
                              ); // Hiện vé xem phim kèm mã QR
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Thanh toán thất bại: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC084FC),
                    foregroundColor: Colors.black,
                  ),
                  child: isPaying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Thanh Toán',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
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
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1B4B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars, color: Colors.amber, size: 60),
                const SizedBox(height: 12),
                const Text(
                  'Đặt Vé Thành Công!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Cảm ơn bạn đã mua vé. Vé của bạn đã được kích hoạt.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // QR Code generated locally
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(12),
                    height: 200,
                    width: 200,
                    child: QrImageView(
                      data: ticketCode,
                      version: QrVersions.auto,
                      size: 200.0,
                      gapless: false,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Ticket Code Text
                Text(
                  'MÃ VÉ: $ticketCode',
                  style: const TextStyle(
                    color: Color(0xFFC084FC),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 20),

                const Divider(color: Colors.white10),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tổng thanh toán:',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    Text(
                      formatter.format(booking.totalAmount),
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Hoàn Thành',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
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

    if (_isLoading || _showtimeDetail == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F1A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFC084FC)),
        ),
      );
    }

    // Group seats by row
    final Map<String, List<Seat>> seatsByRow = {};
    for (var seat in _showtimeDetail!.seats) {
      final String r = seat.row;
      seatsByRow.putIfAbsent(r, () => []).add(seat);
    }

    final double subtotal = _calculateSubtotal();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        title: const Text(
          'Chọn Ghế',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
                  BoxShadow(
                    color: const Color(0xFFC084FC).withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'MÀN HÌNH CHIẾU',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
                letterSpacing: 4,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Legend Indicators
          _buildLegends(),
          const SizedBox(height: 24),

          // Seat Grid
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
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
                              child: Text(
                                rowKey,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Seats List in Row
                            ...rowSeats.map((seat) {
                              final bool isSelected = _selectedSeatIds.contains(
                                seat.id,
                              );
                              final bool isBooked =
                                  seat.status == SeatStatus.booked;
                              final bool isMaintenance =
                                  seat.status == SeatStatus.maintenance;

                              Color seatColor = Colors.white24;
                              IconData? icon;

                              if (isBooked) {
                                seatColor = const Color(0xFF1E1E2E);
                                icon = Icons.lock_outline;
                              } else if (seat.status == SeatStatus.held) {
                                seatColor = Colors.orange.withOpacity(0.6);
                                icon = Icons.person_outline;
                              } else if (isMaintenance) {
                                seatColor = Colors.grey.shade800;
                                icon = Icons.construction;
                              } else if (isSelected) {
                                seatColor = const Color(
                                  0xFF4ADE80,
                                ); // Bright Green
                              } else {
                                if (seat.type == SeatType.vip) {
                                  seatColor = const Color(0xFFF97316); // Orange
                                } else if (seat.type == SeatType.couple) {
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
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? seatColor
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: seatColor,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: icon != null
                                        ? Icon(
                                            icon,
                                            color: Colors.white38,
                                            size: 16,
                                          )
                                        : Text(
                                            '${seat.number}',
                                            style: TextStyle(
                                              color: isSelected
                                                  ? Colors.black
                                                  : Colors.white70,
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
                  // Promo code input & apply button
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _promoController,
                          enabled: _appliedPromo == null,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Nhập mã khuyến mãi (ví dụ: WELCOME10)',
                            hintStyle: const TextStyle(
                              color: Colors.white30,
                              fontSize: 13,
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isValidatingPromo
                            ? null
                            : (_appliedPromo != null
                                ? _removePromotion
                                : _applyPromotion),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _appliedPromo != null
                              ? Colors.red.withOpacity(0.2)
                              : const Color(0xFFC084FC).withOpacity(0.2),
                          foregroundColor: _appliedPromo != null
                              ? Colors.red
                              : const Color(0xFFC084FC),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isValidatingPromo
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFC084FC),
                                ),
                              )
                            : Text(_appliedPromo != null ? 'Hủy' : 'Áp dụng'),
                      ),
                    ],
                  ),
                  if (_promoError != null) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        _promoError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                  if (_appliedPromo != null) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'Áp dụng thành công: Giảm ${_appliedPromo!['discount_percent']}%${_appliedPromo!['max_discount'] != null ? " (Tối đa ${formatter.format(_appliedPromo!['max_discount'])})" : ""}',
                        style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Pricing & Confirm Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_discountAmount > 0) ...[
                            Text(
                              'Tạm tính: ${formatter.format(subtotal)}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Khuyến mãi: -${formatter.format(_discountAmount)}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          Text(
                            _discountAmount > 0 ? 'Tổng cộng:' : 'Tạm tính:',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatter.format(subtotal - _discountAmount),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (_selectedSeatIds.isEmpty || _isBooking)
                              ? null
                              : _handleBookTickets,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC084FC),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isBooking
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Đặt Vé Ngay',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
        SizedBox(width: 12),
        _LegendItem(color: Color(0xFFF97316), label: 'VIP'),
        SizedBox(width: 12),
        _LegendItem(color: Color(0xFFEF4444), label: 'Ghế đôi'),
        SizedBox(width: 12),
        _LegendItem(color: Color(0xFF4ADE80), label: 'Đang chọn'),
        SizedBox(width: 12),
        _LegendItem(color: Colors.orange, label: 'Đang giữ', hasIcon: true),
        SizedBox(width: 12),
        _LegendItem(color: Color(0xFF1E1E2E), label: 'Đã đặt', hasIcon: true),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool hasIcon;

  const _LegendItem({
    required this.color,
    required this.label,
    this.hasIcon = false,
  });

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
          child: hasIcon
              ? const Icon(Icons.lock_outline, size: 10, color: Colors.white38)
              : null,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
      ],
    );
  }
}
