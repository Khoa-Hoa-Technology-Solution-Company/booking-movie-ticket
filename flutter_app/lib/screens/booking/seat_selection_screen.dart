import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/payment_config.dart';
import '../../core/theme/app_theme.dart';
import '../../services/movie_service.dart';
import '../../services/booking_service.dart';
import '../../models/showtime.dart';
import '../../models/booking.dart';
import 'food_selection_screen.dart';
import '../../widgets/booking_components.dart';

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

  // Supabase Realtime Subscriptions
  StreamSubscription<List<Map<String, dynamic>>>? _seatHoldsSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _bookingsSubscription;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _loadSeatLayout();
    if (mounted) {
      _subscribeToRealtime();
    }
  }

  @override
  void dispose() {
    _unsubscribeFromRealtime();
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

  Future<void> _loadSeatLayoutSilently() async {
    try {
      final showtimeDetail = await movieService.getShowtimeDetail(
        widget.showtimeId,
      );
      if (!mounted) return;
      setState(() {
        _showtimeDetail = showtimeDetail;
        
        // Lọc bỏ những ghế không còn khả dụng cho user hiện tại (đã bị người khác đặt hoặc giữ)
        final List<int> noLongerAvailable = [];
        for (var seatId in _selectedSeatIds) {
          final seatIndex = showtimeDetail.seats.indexWhere((s) => s.id == seatId);
          if (seatIndex == -1) {
            noLongerAvailable.add(seatId);
          } else {
            final seat = showtimeDetail.seats[seatIndex];
            if (seat.status == SeatStatus.booked || seat.status == SeatStatus.held || seat.status == SeatStatus.maintenance) {
              noLongerAvailable.add(seatId);
            }
          }
        }
        
        if (noLongerAvailable.isNotEmpty) {
          _selectedSeatIds.removeAll(noLongerAvailable);
          _recalculateDiscount();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Một số ghế bạn đang chọn đã bị người khác giữ hoặc thanh toán!'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      });
    } catch (e) {
      debugPrint('Lỗi cập nhật sơ đồ ghế ngầm: $e');
    }
  }

  void _subscribeToRealtime() {
    final supabase = Supabase.instance.client;
    
    // 1. Lắng nghe thay đổi trên bảng seat_holds cho showtime này
    _seatHoldsSubscription = supabase
        .from('seat_holds')
        .stream(primaryKey: ['id'])
        .eq('showtime_id', widget.showtimeId)
        .listen((data) {
          debugPrint('Supabase Realtime (seat_holds) fired. Total holds: ${data.length}');
          _loadSeatLayoutSilently();
        });

    // 2. Lắng nghe thay đổi trên bảng bookings cho showtime này
    _bookingsSubscription = supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('showtime_id', widget.showtimeId)
        .listen((data) {
          debugPrint('Supabase Realtime (bookings) fired. Total bookings: ${data.length}');
          _loadSeatLayoutSilently();
        });
  }

  void _unsubscribeFromRealtime() {
    _seatHoldsSubscription?.cancel();
    _seatHoldsSubscription = null;
    _bookingsSubscription?.cancel();
    _bookingsSubscription = null;
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

  void _handleBookTickets() {
    if (_selectedSeatIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất 1 ghế')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FoodSelectionScreen(
          showtimeId: widget.showtimeId,
          selectedSeatIds: _selectedSeatIds.toList(),
          promotionCode: _appliedPromo != null ? _appliedPromo!['code'] as String : null,
        ),
      ),
    ).then((_) {
      // Reload seat layout when returning to check holds or update UI
      _loadSeatLayout();
    });
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
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    if (_isLoading || _showtimeDetail == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final showtime = _showtimeDetail!.showtime;
    final room = showtime.room;
    final int totalRows = room?.totalRows ?? 10;
    final int totalColumns = room?.totalColumns ?? 10;

    final List<List<Seat?>> grid = List.generate(
      totalRows, (_) => List.filled(totalColumns, null),
    );
    for (var seat in _showtimeDetail!.seats) {
      final int rIdx = seat.positionY - 1;
      final int cIdx = seat.positionX - 1;
      if (rIdx >= 0 && rIdx < totalRows && cIdx >= 0 && cIdx < totalColumns) {
        grid[rIdx][cIdx] = seat;
      }

    }

    final double subtotal = _calculateSubtotal();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Chọn Ghế', style: AppTextStyles.titleSmall),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // === SHOWTIME INFO STRIP ===
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                const Icon(Icons.movie_outlined, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    showtime.movie?.title ?? 'Phim',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDim,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    DateFormat('HH:mm - dd/MM').format(showtime.startTime),
                    style: GoogleFonts.robotoMono(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          // === SCREEN INDICATOR ===
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * 0.65,
                  height: 5,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.45), blurRadius: 12, spreadRadius: 2)],
                  ),
                ),
                const SizedBox(height: 6),
                Text('MÀN HÌNH CHIẾU',
                  style: GoogleFonts.robotoMono(color: AppColors.textMuted, fontSize: 9, letterSpacing: 3)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // === LEGEND ===
          _buildLegends(),
          const SizedBox(height: 16),

          // === SEAT GRID ===
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: List.generate(totalRows, (rowIdx) {
                      String rowLetter = '';
                      for (int col = 0; col < totalColumns; col++) {
                        if (grid[rowIdx][col] != null) { rowLetter = grid[rowIdx][col]!.row; break; }
                      }
                      if (rowLetter.isEmpty) rowLetter = String.fromCharCode(65 + rowIdx);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 22,
                              child: Text(rowLetter, style: AppTextStyles.seatLabel.copyWith(color: AppColors.textMuted)),
                            ),
                            ...List.generate(totalColumns, (colIdx) {
                              final seat = grid[rowIdx][colIdx];
                              if (seat == null) return const SizedBox(width: 32, height: 32);
                              final bool isSelected = _selectedSeatIds.contains(seat.id);
                              return SeatWidget(seat: seat, isSelected: isSelected, onTap: () => _toggleSeat(seat));
                            }),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),

          // === BOTTOM BAR ===
          Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Promo row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _promoController,
                          enabled: _appliedPromo == null,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Mã khuyến mãi (VD: WELCOME10)',
                            hintStyle: AppTextStyles.caption,
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            prefixIcon: const Icon(Icons.local_offer_outlined, color: AppColors.textMuted, size: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _isValidatingPromo ? null : (_appliedPromo != null ? _removePromotion : _applyPromotion),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            color: _appliedPromo != null ? AppColors.danger.withOpacity(0.12) : AppColors.primaryDim,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _appliedPromo != null ? AppColors.danger.withOpacity(0.3) : AppColors.primary.withOpacity(0.3)),
                          ),
                          child: _isValidatingPromo
                              ? const SizedBox(width: 14, height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                              : Text(
                                  _appliedPromo != null ? 'Hủy' : 'Áp dụng',
                                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold,
                                    color: _appliedPromo != null ? AppColors.danger : AppColors.primary),
                                ),
                        ),
                      ),
                    ],
                  ),
                  if (_promoError != null) ...[
                    const SizedBox(height: 4),
                    Text(_promoError!, style: const TextStyle(color: AppColors.danger, fontSize: 11)),
                  ],
                  if (_appliedPromo != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '✓ Giảm ${_appliedPromo!["discount_percent"]}%${_appliedPromo!["max_discount"] != null ? " (Tối đa ${formatter.format(_appliedPromo!["max_discount"])})" : ""}',
                      style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Pricing + confirm
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_discountAmount > 0) ...[
                              Text(formatter.format(subtotal),
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 11,
                                  decoration: TextDecoration.lineThrough)),
                              Text('- ${formatter.format(_discountAmount)}',
                                style: const TextStyle(color: AppColors.success, fontSize: 11)),
                            ],
                            Text(
                              _selectedSeatIds.isEmpty ? 'Chọn ghế để tiếp tục' : '${_selectedSeatIds.length} ghế đã chọn',
                              style: AppTextStyles.caption,
                            ),
                            Text(
                              formatter.format(subtotal - _discountAmount),
                              style: AppTextStyles.price,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Opacity(
                        opacity: (_selectedSeatIds.isEmpty || _isBooking) ? 0.4 : 1.0,
                        child: GestureDetector(
                          onTap: (_selectedSeatIds.isEmpty || _isBooking) ? null : _handleBookTickets,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(AppRadius.button),
                              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                            ),
                            child: _isBooking
                                ? const SizedBox(width: 20, height: 20,
                                    child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.restaurant_menu_rounded, size: 16, color: Colors.black),
                                      const SizedBox(width: 6),
                                      Text('Tiếp Tục',
                                        style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black)),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegends() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: const Border.fromBorderSide(BorderSide(color: AppColors.border)),
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 6,
          children: const [
            _LegendItem(color: Color(0xFFB0B0C8), label: 'Thường'),
            _LegendItem(color: Color(0xFFF97316), label: 'VIP'),
            _LegendItem(color: Color(0xFFEF4444), label: 'Đôi'),
            _LegendItem(color: Color(0xFF4ADE80), label: 'Đang chọn', filled: true),
            _LegendItem(color: Color(0xFFF59E0B), label: 'Đang giữ', filled: true),
            _LegendItem(color: Color(0xFF2D2D3E), label: 'Đã đặt', filled: true, locked: true),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool filled;
  final bool locked;

  const _LegendItem({
    required this.color,
    required this.label,
    this.filled = false,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: filled ? color : color.withOpacity(0.15),
            border: Border.all(color: color, width: 1.5),
            borderRadius: BorderRadius.circular(AppRadius.seat / 2),
          ),
          child: locked
              ? const Icon(Icons.lock_rounded, size: 8, color: Colors.white38)
              : null,
        ),
        const SizedBox(width: 5),
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
      ],
    );
  }
}
