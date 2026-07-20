import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../core/theme/app_theme.dart';
import '../../models/security.dart';
import '../../models/booking.dart';
import '../../services/booking_service.dart';
import '../booking/booking_history_screen.dart';
import '../security/login_history_screen.dart';
import '../security/security_alerts_screen.dart';
import '../security/security_dashboard_screen.dart';

class NoticeScreen extends StatefulWidget {
  const NoticeScreen({super.key});

  @override
  State<NoticeScreen> createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen> {
  final _supabase = sb.Supabase.instance.client;

  Stream<List<SecurityAlert>> _getAlertsStream() {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      return Stream.value([]);
    }
    
    // Sử dụng Supabase Realtime Stream tự động lắng nghe cập nhật của bảng dưới DB
    return _supabase
        .from('security_alerts')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUserId)
        .order('created_at', ascending: false)
        .map((list) => list.map((json) => SecurityAlert.fromJson(json)).toList());
  }

  Future<void> _handleAlertTap(SecurityAlert alert) async {
    final type = alert.type;
    final metadata = alert.metadata;

    if (type == 'BOOKING_SUCCESS' && metadata != null && metadata['booking_id'] != null) {
      final bookingId = metadata['booking_id'] as int;
      _showLoadingDialog();
      try {
        final booking = await bookingService.getBookingById(bookingId);
        if (mounted) {
          Navigator.pop(context); // Đóng Loading Dialog
          _showTicketDialog(booking);
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Đóng Loading Dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không tải được thông tin vé: $e'), backgroundColor: AppColors.danger),
          );
        }
      }
    } else if (type == 'NEW_DEVICE_LOGIN' || type == 'MANY_FAILED_ATTEMPTS' || type == 'ACCOUNT_LOCKED') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginHistoryScreen()),
      );
    } else if (type == '2FA_TOGGLED' || type == 'TWO_FACTOR_DISABLED') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SecurityDashboardScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SecurityAlertsScreen()),
      );
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  void _showTicketDialog(Booking booking) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: TicketDialogContent(booking: booking),
        );
      },
    );
  }

  Future<void> _deleteAlert(int id) async {
    try {
      await _supabase.from('security_alerts').delete().eq('id', id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa thông báo thành công')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể xóa thông báo: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context); // Lắng nghe theme thay đổi
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Thông Báo & Tác Vụ', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<SecurityAlert>>(
        stream: _getAlertsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Đã xảy ra lỗi khi tải thông báo: ${snapshot.error}',
                style: TextStyle(color: AppColors.danger),
              ),
            );
          }

          final alerts = snapshot.data ?? [];
          if (alerts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, color: AppColors.textMuted, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'Không có thông báo nào dành cho bạn',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
              final String severity = alert.severity;
              final String type = alert.type;
              final String message = alert.message;
              final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(alert.createdAt);

              Color severityColor = Colors.blue;
              IconData icon = Icons.info_outline;

              if (type == 'BOOKING_SUCCESS') {
                severityColor = Colors.green;
                icon = Icons.movie_creation_outlined;
              } else if (severity == 'CRITICAL' || severity == 'HIGH') {
                severityColor = Colors.redAccent;
                icon = Icons.gpp_bad_outlined;
              } else if (severity == 'MEDIUM') {
                severityColor = Colors.amber;
                icon = Icons.gpp_maybe_outlined;
              } else {
                severityColor = Colors.blueAccent;
                icon = Icons.info_outline;
              }

              return Dismissible(
                key: Key(alert.id.toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => _deleteAlert(alert.id),
                child: Card(
                  color: AppColors.surface,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: severityColor.withAlpha(51), width: 1.5),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _handleAlertTap(alert),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: severityColor.withAlpha(25),
                            child: Icon(icon, color: severityColor),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: severityColor.withAlpha(38),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        type == 'BOOKING_SUCCESS' ? 'ĐẶT VÉ THÀNH CÔNG' : type,
                                        style: TextStyle(
                                          color: severityColor,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      dateStr,
                                      style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  message,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (type == 'BOOKING_SUCCESS') ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.confirmation_number_outlined,
                                        color: AppColors.primary,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Xem cuống vé ngay',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
