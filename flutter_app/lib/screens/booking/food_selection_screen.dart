import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/payment_config.dart';
import '../../core/theme/app_theme.dart';
import '../../models/food.dart';
import '../../models/booking.dart';
import '../../models/showtime.dart';
import '../../widgets/booking_components.dart';
import '../../services/booking_service.dart';
import '../../services/movie_service.dart';

class FoodSelectionScreen extends StatefulWidget {
  final int showtimeId;
  final List<int> selectedSeatIds;
  final String? promotionCode;

  const FoodSelectionScreen({
    super.key,
    required this.showtimeId,
    required this.selectedSeatIds,
    this.promotionCode,
  });

  @override
  State<FoodSelectionScreen> createState() => _FoodSelectionScreenState();
}

class _FoodSelectionScreenState extends State<FoodSelectionScreen> {
  bool _isLoading = true;
  bool _isBooking = false;
  List<Product> _products = [];
  List<Combo> _combos = [];
  
  // Cart state: Key is either 'p_{id}' or 'c_{id}'
  final Map<String, CartItem> _cart = {};

  double _seatsSubtotal = 0.0;
  double _discountAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;

      // 1. Fetch active products & combos
      final productsRes = await supabase.from('products').select().eq('is_active', true);
      final combosRes = await supabase.from('combos').select().eq('is_active', true);

      // 2. Fetch seats cost and calculate subtotal
      final showtimeDetail = await movieService.getShowtimeDetail(widget.showtimeId);
      final basePrice = showtimeDetail.showtime.price;

      double seatsCost = 0.0;
      for (var seatId in widget.selectedSeatIds) {
        final seat = showtimeDetail.seats.firstWhere((s) => s.id == seatId);
        double seatPrice = basePrice;
        if (seat.type == SeatType.vip) {
          seatPrice += 20000;
        } else if (seat.type == SeatType.couple) {
          seatPrice += 40000;
        }
        seatsCost += seatPrice;
      }

      // 3. Compute discount if promotion code exists
      double discount = 0.0;
      if (widget.promotionCode != null && widget.promotionCode!.isNotEmpty) {
        final promoJson = await supabase
            .from('promotions')
            .select()
            .eq('code', widget.promotionCode!)
            .eq('active', true)
            .maybeSingle();

        if (promoJson != null) {
          final discountPercent = promoJson['discount_percent'] as int;
          final maxDiscount = (promoJson['max_discount'] as num?)?.toDouble();
          final minPurchase = (promoJson['min_purchase'] as num?)?.toDouble() ?? 0.0;

          if (seatsCost >= minPurchase) {
            discount = seatsCost * (discountPercent / 100);
            if (maxDiscount != null && discount > maxDiscount) {
              discount = maxDiscount;
            }
          }
        }
      }

      setState(() {
        _products = (productsRes as List).map((json) => Product.fromJson(json)).toList();
        _combos = (combosRes as List).map((json) => Combo.fromJson(json)).toList();
        _seatsSubtotal = seatsCost;
        _discountAmount = discount;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải bắp nước: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _getFoodSubtotal() {
    double total = 0.0;
    _cart.forEach((_, item) {
      total += item.totalAmount;
    });
    return total;
  }

  double _getTotalAmount() {
    return _seatsSubtotal + _getFoodSubtotal() - _discountAmount;
  }

  void _updateCartQuantity(String key, CartItem item, int delta) {
    setState(() {
      if (_cart.containsKey(key)) {
        final currentItem = _cart[key]!;
        currentItem.quantity += delta;
        if (currentItem.quantity <= 0) {
          _cart.remove(key);
        }
      } else if (delta > 0) {
        item.quantity = delta;
        _cart[key] = item;
      }
    });
  }

  Future<void> _handleCheckout() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
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
                Text(
                  'Chọn Phương Thức Thanh Toán',
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.wallet, color: AppColors.primary),
                  title: Text('Ví Điện Tử Demo', style: AppTextStyles.bodyBold),
                  subtitle: const Text('Thanh toán và nhận vé ngay lập tức (Test)', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _processCheckout('DEMO');
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.account_balance, color: AppColors.primary),
                  title: Text('Chuyển Khoản Ngân Hàng (SePay)', style: AppTextStyles.bodyBold),
                  subtitle: const Text('Quét mã VietQR chuyển khoản tự động', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _processCheckout('SEPAY');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _processCheckout(String paymentMethod) async {
    setState(() => _isBooking = true);
    try {
      final itemsList = _cart.values.toList();
      
      final booking = await bookingService.createBooking(
        showtimeId: widget.showtimeId,
        seatIds: widget.selectedSeatIds,
        foodItems: itemsList,
        promotionCode: widget.promotionCode,
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
          SnackBar(content: Text('Đặt vé thất bại: $e'), backgroundColor: AppColors.danger),
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

    final supabase = Supabase.instance.client;
    final bookingStream = supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('id', booking.id)
        .listen((data) {
          if (data.isNotEmpty) {
            final statusStr = data.first['status'] as String;
            if (statusStr == 'CONFIRMED' && Navigator.canPop(context)) {
              Navigator.pop(context);
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
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Thanh Toán SePay', style: AppTextStyles.titleMedium),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
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
                  children: [
                    const Text('Quét mã VietQR dưới đây để thanh toán chuyển khoản:', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
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
                            child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTransferRow('Ngân hàng', sepayBank, false),
                    _buildTransferRow('Số tài khoản', sepayAcc, true),
                    _buildTransferRow('Tên tài khoản', sepayName, false),
                    _buildTransferRow('Số tiền', formatter.format(booking.totalAmount), true, transferAmount.toString(), AppColors.success),
                    _buildTransferRow('Nội dung', transferContent, true, null, AppColors.primary),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
                        SizedBox(width: 10),
                        Expanded(child: Text('Đang chờ hệ thống tự động xác nhận chuyển khoản...', style: TextStyle(color: AppColors.textMuted, fontSize: 12))),
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
                  child: const Text('Hủy / Đóng', style: TextStyle(color: AppColors.textMuted)),
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
                                Navigator.pop(context);
                                _showTicketDialog(updated);
                              }
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Hệ thống chưa nhận được thanh toán. Vui lòng thử lại sau.'), backgroundColor: AppColors.accent),
                                );
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.danger),
                              );
                            }
                          } finally {
                            setDialogState(() => isChecking = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isChecking
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Text('Tôi Đã Chuyển Khoản', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            );
          },
        );
      },
    ).then((_) => bookingStream.cancel());
  }

  Widget _buildTransferRow(String label, String value, bool copyable, [String? copyVal, Color? valColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Expanded(child: SelectableText(value, style: TextStyle(color: valColor ?? Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
                if (copyable)
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: copyVal ?? value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đã sao chép $label!'), duration: const Duration(seconds: 1), backgroundColor: AppColors.primary),
                      );
                    },
                    child: const Icon(Icons.copy, color: AppColors.primary, size: 16),
                  )
              ],
            ),
          )
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
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text('Thanh Toán Vé', style: AppTextStyles.titleMedium),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bạn đang thanh toán đơn đặt vé số:', style: TextStyle(color: AppColors.textSecondary)),
                  Text('#${booking.id}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng tiền:', style: TextStyle(color: AppColors.textSecondary)),
                      Text(formatter.format(booking.totalAmount), style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 20)),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isPaying ? null : () => Navigator.pop(context),
                  child: const Text('Hủy', style: TextStyle(color: AppColors.textMuted)),
                ),
                ElevatedButton(
                  onPressed: isPaying
                      ? null
                      : () async {
                          setDialogState(() => isPaying = true);
                          try {
                            final result = await bookingService.confirmPayment(booking.id);
                            if (mounted) {
                              Navigator.pop(context);
                              _showTicketDialog(result);
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Thanh toán thất bại: $e'), backgroundColor: AppColors.danger),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
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

  void _showTicketDialog(Booking booking) {
    final ticket = booking.ticket;
    final String ticketCode = ticket?.ticketCode ?? '';
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceHigh,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars, color: AppColors.accent, size: 60),
                const SizedBox(height: 12),
                Text('Đặt Vé Thành Công!', style: AppTextStyles.titleMedium),
                const SizedBox(height: 8),
                const Text('Cảm ơn bạn đã mua vé. Vé của bạn đã được kích hoạt.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12), textAlign: TextAlign.center),
                const SizedBox(height: 24),
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
                Text('MÃ VÉ: $ticketCode', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.5)),
                const SizedBox(height: 20),
                const Divider(color: AppColors.border),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tổng thanh toán:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    Text(formatter.format(booking.totalAmount), style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
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
    final double foodSubtotal = _getFoodSubtotal();
    final double totalAmount = _getTotalAmount();

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Chọn Bắp Nước', style: AppTextStyles.titleSmall),
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recommended Combos
              if (_combos.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.stars_rounded, color: AppColors.accent, size: 20),
                    const SizedBox(width: 8),
                    Text('Combo Khuyến Nghị', style: AppTextStyles.titleSmall),
                  ],
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _combos.length,
                  itemBuilder: (context, index) {
                    final combo = _combos[index];
                    final key = 'c_${combo.id}';
                    final qty = _cart[key]?.quantity ?? 0;
                    return FoodCard(
                      name: combo.name,
                      description: combo.description,
                      price: combo.price,
                      quantity: qty,
                      isCombo: true,
                      onIncrement: () => _updateCartQuantity(key, CartItem(combo: combo, quantity: 1), 1),
                      onDecrement: () => _updateCartQuantity(key, CartItem(combo: combo, quantity: 1), -1),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],

              // Products list
              if (_products.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.local_cafe_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text('Sản Phẩm Lẻ', style: AppTextStyles.titleSmall),
                  ],
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    final key = 'p_${product.id}';
                    final qty = _cart[key]?.quantity ?? 0;
                    return FoodCard(
                      name: product.name,
                      price: product.price,
                      imageUrl: product.imageUrl,
                      quantity: qty,
                      isCombo: false,
                      onIncrement: () => _updateCartQuantity(key, CartItem(product: product, quantity: 1), 1),
                      onDecrement: () => _updateCartQuantity(key, CartItem(product: product, quantity: 1), -1),
                    );
                  },
                ),
              ],
              const SizedBox(height: 120), // Spacing for bottom bar
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        padding: const EdgeInsets.all(20),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Vé xem phim:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  Text(formatter.format(_seatsSubtotal), style: const TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
              if (_discountAmount > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Khuyến mãi vé:', style: TextStyle(color: AppColors.success, fontSize: 13)),
                    Text('-${formatter.format(_discountAmount)}', style: const TextStyle(color: AppColors.success, fontSize: 13)),
                  ],
                ),
              ],
              if (foodSubtotal > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Bắp nước:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    Text(formatter.format(foodSubtotal), style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ],
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(color: AppColors.border, height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tổng thanh toán:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(formatter.format(totalAmount), style: AppTextStyles.price),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(AppRadius.button),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isBooking ? null : _handleCheckout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.black,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isBooking
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                            : const Text('Thanh Toán', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
