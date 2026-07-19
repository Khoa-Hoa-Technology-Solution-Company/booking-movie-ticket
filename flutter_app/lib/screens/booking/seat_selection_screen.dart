import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../services/movie_service.dart';
import '../../models/showtime.dart';
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

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    if (_isLoading || _showtimeDetail == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
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

          // === SEAT GRID (InteractiveViewer Zoom & Pan) ===
          Expanded(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 2.5,
              constrained: false, // Cho phép vuốt cuộn tự do cả 2 hướng
              child: Padding(
                padding: const EdgeInsets.all(24.0),
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

          // === BOTTOM BAR ===
          Container(
            decoration: BoxDecoration(
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
                            prefixIcon: Icon(Icons.local_offer_outlined, color: AppColors.textMuted, size: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _appliedPromo != null ? _removePromotion : _applyPromotion,
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
                                style: TextStyle(color: AppColors.textMuted, fontSize: 11,
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
                        opacity: (_selectedSeatIds.isEmpty || _isLoading) ? 0.4 : 1.0,
                        child: GestureDetector(
                          onTap: (_selectedSeatIds.isEmpty || _isLoading) ? null : _handleBookTickets,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(AppRadius.button),
                              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                            ),
                            child: Row(
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
          border: Border.fromBorderSide(BorderSide(color: AppColors.border)),
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 6,
          children: const [
            _LegendItem(color: Color(0xFFB0B0C8), label: 'Thường'),
            _LegendItem(color: Color(0xFFF97316), label: 'VIP (Viền đôi)', isVip: true),
            _LegendItem(color: Color(0xFFEF4444), label: 'Đôi (♥)', isCouple: true),
            _LegendItem(color: Color(0xFF4ADE80), label: 'Đang chọn (✓)', filled: true, isSelected: true),
            _LegendItem(color: Color(0xFFF59E0B), label: 'Đang giữ', filled: true, isHeld: true),
            _LegendItem(color: Color(0xFF2D2D3E), label: 'Đã đặt (✕)', filled: true, locked: true),
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
  final bool isVip;
  final bool isCouple;
  final bool isSelected;
  final bool isHeld;

  const _LegendItem({
    required this.color,
    required this.label,
    this.filled = false,
    this.locked = false,
    this.isVip = false,
    this.isCouple = false,
    this.isSelected = false,
    this.isHeld = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget shape;
    if (isVip) {
      shape = Container(
        width: 14,
        height: 14,
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 0.8),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 1.2),
            borderRadius: BorderRadius.circular(2.5),
          ),
        ),
      );
    } else {
      shape = Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: filled ? color : color.withOpacity(0.15),
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: locked
              ? const Icon(Icons.close_rounded, size: 8, color: Colors.white38)
              : isCouple
                  ? const Icon(Icons.favorite_rounded, size: 8, color: Colors.white)
                  : isSelected
                      ? const Icon(Icons.check_rounded, size: 8, color: Colors.black)
                      : isHeld
                          ? const Icon(Icons.person_outline, size: 8, color: Colors.white)
                          : null,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        shape,
        const SizedBox(width: 5),
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
      ],
    );
  }
}
