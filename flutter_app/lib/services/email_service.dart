import 'package:flutter/foundation.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../models/booking.dart';

abstract class IEmailService {
  Future<void> sendTicketConfirmationEmail(Booking booking);
  Future<void> sendHoldExpiredEmail(Booking booking);
}

class EmailService implements IEmailService {
  final _supabase = sb.Supabase.instance.client;

  // Cấu hình SMTP nạp qua --dart-define
  static const String _smtpHost = String.fromEnvironment('SMTP_HOST', defaultValue: '');
  static const int _smtpPort = int.fromEnvironment('SMTP_PORT', defaultValue: 587);
  static const String _smtpUser = String.fromEnvironment('SMTP_USER', defaultValue: '');
  static const String _smtpPass = String.fromEnvironment('SMTP_PASS', defaultValue: '');

  @override
  Future<void> sendTicketConfirmationEmail(Booking booking) async {
    String email = _supabase.auth.currentUser?.email ?? '';
    if (email.isEmpty && booking.userId.isNotEmpty) {
      try {
        final userRes = await _supabase
            .from('users')
            .select('email')
            .eq('id', booking.userId)
            .maybeSingle();
        email = userRes?['email'] as String? ?? '';
      } catch (e) {
        debugPrint('[EmailService] Không thể lấy email từ DB: $e');
      }
    }

    if (email.isEmpty) {
      debugPrint('[EmailService] Không tìm thấy email của người dùng để gửi vé.');
      return;
    }

    final String htmlBody = _buildTicketHtml(booking);

    // Chế độ DEMO nếu không có cấu hình SMTP
    if (_smtpHost.isEmpty || _smtpUser.isEmpty || _smtpPass.isEmpty) {
      debugPrint('==================================================');
      debugPrint('[DEMO MODE - EMAIL SERVICE]');
      debugPrint('Thông số cấu hình SMTP trống. In thông tin vé ra console.');
      debugPrint('To: $email');
      debugPrint('Subject: Vé Xem Phim của Bạn - Đơn hàng #${booking.id}');
      debugPrint('Nội dung HTML:\n$htmlBody');
      debugPrint('==================================================');
      return;
    }

    // Sử dụng helper gmail() tối ưu cho Gmail SMTP
    final SmtpServer smtpServer = _smtpHost.contains('gmail')
        ? gmail(_smtpUser, _smtpPass)
        : SmtpServer(
            _smtpHost,
            port: _smtpPort,
            username: _smtpUser,
            password: _smtpPass,
            ssl: _smtpPort == 465,
          );

    final message = Message()
      ..from = Address(_smtpUser, 'MovieTicket')
      ..recipients.add(email)
      ..subject = 'Vé Xem Phim Của Bạn - Đơn hàng #${booking.id}'
      ..html = htmlBody;

    try {
      final sendReport = await send(message, smtpServer);
      debugPrint('[EmailService] Gửi email vé thành công tới $email: $sendReport');
    } catch (e) {
      debugPrint('[EmailService] Lỗi khi gửi email vé qua SMTP tới $email: $e');
      rethrow;
    }
  }

  @override
  Future<void> sendHoldExpiredEmail(Booking booking) async {
    String email = _supabase.auth.currentUser?.email ?? '';
    if (email.isEmpty && booking.userId.isNotEmpty) {
      try {
        final userRes = await _supabase
            .from('users')
            .select('email')
            .eq('id', booking.userId)
            .maybeSingle();
        email = userRes?['email'] as String? ?? '';
      } catch (e) {
        debugPrint('[EmailService] Không thể lấy email từ DB: $e');
      }
    }

    if (email.isEmpty) {
      debugPrint('[EmailService] Không tìm thấy email của người dùng để gửi vé hết hạn.');
      return;
    }

    final String htmlBody = _buildHoldExpiredHtml(booking);

    if (_smtpHost.isEmpty || _smtpUser.isEmpty || _smtpPass.isEmpty) {
      debugPrint('==================================================');
      debugPrint('[DEMO MODE - EMAIL EXPIRED HOLD SERVICE]');
      debugPrint('To: $email');
      debugPrint('Subject: Thông Báo Hết Hạn Giữ Vé - Đơn hàng #${booking.id}');
      debugPrint('Nội dung HTML:\n$htmlBody');
      debugPrint('==================================================');
      return;
    }

    final SmtpServer smtpServer = _smtpHost.contains('gmail')
        ? gmail(_smtpUser, _smtpPass)
        : SmtpServer(
            _smtpHost,
            port: _smtpPort,
            username: _smtpUser,
            password: _smtpPass,
            ssl: _smtpPort == 465,
          );

    final message = Message()
      ..from = Address(_smtpUser, 'MovieTicket')
      ..recipients.add(email)
      ..subject = 'Thông Báo Hết Hạn Giữ Vé - Đơn Hàng #${booking.id}'
      ..html = htmlBody;

    try {
      final sendReport = await send(message, smtpServer);
      debugPrint('[EmailService] Gửi email thông báo hết hạn giữ vé thành công tới $email: $sendReport');
    } catch (e) {
      debugPrint('[EmailService] Lỗi khi gửi email hết hạn giữ vé qua SMTP tới $email: $e');
    }
  }

  String _buildHoldExpiredHtml(Booking booking) {
    final showtime = booking.showtime;
    final movie = showtime?.movie;
    final cinema = showtime?.cinema;
    final room = showtime?.room;
    final seats = booking.seats ?? [];
    
    final movieTitle = movie?.title ?? 'Phim';
    final cinemaName = cinema?.name ?? 'Rạp';
    final roomName = room?.name ?? 'Phòng';
    final seatNames = seats.map((s) => '${s.row}${s.number}').join(', ');

    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>Thông Báo Hết Hạn Giữ Vé</title>
      <style>
        body { font-family: Arial, sans-serif; background-color: #f4f4f9; margin: 0; padding: 20px; color: #333333; }
        .card { max-width: 500px; margin: 0 auto; background-color: #ffffff; border-radius: 16px; box-shadow: 0 4px 12px rgba(0,0,0,0.1); overflow: hidden; border: 1px solid #e0e0e0; }
        .header { background: linear-gradient(135deg, #ef4444, #991b1b); padding: 24px; text-align: center; color: #ffffff; }
        .header h1 { margin: 0; font-size: 22px; font-weight: bold; letter-spacing: 1px; color: #ffffff; }
        .header p { margin: 5px 0 0 0; font-size: 12px; color: #fecaca; letter-spacing: 1px; }
        .content { padding: 24px; line-height: 1.6; }
        .warning-box { background-color: #fef2f2; border-left: 4px solid #ef4444; padding: 12px 16px; margin-bottom: 20px; border-radius: 4px; }
        .warning-box p { margin: 0; font-size: 13px; color: #991b1b; font-weight: bold; }
        .info-row { display: flex; margin-bottom: 12px; border-bottom: 1px dashed #f0f0f0; padding-bottom: 8px; }
        .info-label { width: 140px; color: #666666; font-size: 13px; font-weight: bold; }
        .info-value { flex: 1; font-size: 13px; color: #333333; font-weight: bold; }
        .footer { background-color: #fafafa; padding: 16px; text-align: center; font-size: 11px; color: #999999; border-top: 1px solid #eeeeee; }
      </style>
    </head>
    <body>
      <div class="card">
        <div class="header">
          <h1>HẾT HẠN GIỮ VÉ</h1>
          <p>MOVIETICKET BOOKING</p>
        </div>
        <div class="content">
          <div class="warning-box">
            <p>Đơn đặt vé #${booking.id} đã hết 5 phút giữ chỗ và tự động bị hủy. Các vị trí ghế của bạn đã được giải phóng cho người khác chọn đặt.</p>
          </div>
          
          <div class="info-row">
            <div class="info-label">PHIM:</div>
            <div class="info-value">$movieTitle</div>
          </div>
          
          <div class="info-row">
            <div class="info-label">RẠP & PHÒNG:</div>
            <div class="info-value">$cinemaName - $roomName</div>
          </div>
          
          <div class="info-row">
            <div class="info-label">SỐ GHẾ GIẢI PHÓNG:</div>
            <div class="info-value" style="color: #ef4444;">$seatNames</div>
          </div>
          
          <p style="font-size: 13px; color: #666666; text-align: center; margin-top: 20px;">Nếu bạn vẫn có nhu cầu xem phim, vui lòng mở ứng dụng và tiến hành chọn lại suất chiếu mới.</p>
        </div>
        <div class="footer">
          Cảm ơn bạn đã sử dụng dịch vụ MovieTicket!<br>
          © 2026 MovieTicket Solution. All rights reserved.
        </div>
      </div>
    </body>
    </html>
    ''';
  }

  String _buildTicketHtml(Booking booking) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final showtime = booking.showtime;
    final movie = showtime?.movie;
    final cinema = showtime?.cinema;
    final room = showtime?.room;
    final seats = booking.seats ?? [];
    
    final movieTitle = movie?.title ?? 'Phim';
    final cinemaName = cinema?.name ?? 'Rạp';
    final roomName = room?.name ?? 'Phòng';
    final dateStr = showtime != null 
        ? DateFormat('dd/MM/yyyy HH:mm').format(showtime.startTime)
        : '';
    final seatNames = seats.map((s) => '${s.row}${s.number}').join(', ');
    final ticketCode = booking.ticket?.ticketCode ?? '';
    final totalAmountStr = formatter.format(booking.totalAmount);
    
    String foodHtml = '';
    if (booking.orderItems != null && booking.orderItems!.isNotEmpty) {
      foodHtml = '<p style="margin: 6px 0; font-size: 13px;"><strong>Bắp nước kèm theo:</strong> ' + 
          booking.orderItems!.map((item) => '${item.itemName} (x${item.quantity})').join(', ') + 
          '</p>';
    }

    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>Vé Xem Phim</title>
      <style>
        body { font-family: Arial, sans-serif; background-color: #f4f4f9; margin: 0; padding: 20px; color: #333333; }
        .card { max-width: 500px; margin: 0 auto; background-color: #ffffff; border-radius: 16px; box-shadow: 0 4px 12px rgba(0,0,0,0.1); overflow: hidden; border: 1px solid #e0e0e0; }
        .header { background: linear-gradient(135deg, #1e1b4b, #0f0f1a); padding: 24px; text-align: center; color: #ffffff; }
        .header h1 { margin: 0; font-size: 24px; font-weight: bold; letter-spacing: 1px; color: #ffffff; }
        .header p { margin: 5px 0 0 0; font-size: 12px; color: #a5b4fc; letter-spacing: 1.5px; }
        .content { padding: 24px; line-height: 1.6; }
        .movie-title { font-size: 20px; font-weight: bold; color: #1e1b4b; margin-top: 0; margin-bottom: 16px; }
        .info-row { display: flex; margin-bottom: 12px; border-bottom: 1px dashed #f0f0f0; padding-bottom: 8px; }
        .info-label { width: 140px; color: #666666; font-size: 13px; font-weight: bold; }
        .info-value { flex: 1; font-size: 13px; color: #333333; font-weight: bold; }
        .ticket-code { background-color: #f3f4f6; border: 2px dashed #c084fc; border-radius: 8px; padding: 12px; text-align: center; margin: 20px 0; }
        .ticket-code span { font-family: monospace; font-size: 18px; font-weight: bold; color: #c084fc; letter-spacing: 1.5px; }
        .footer { background-color: #fafafa; padding: 16px; text-align: center; font-size: 11px; color: #999999; border-top: 1px solid #eeeeee; }
      </style>
    </head>
    <body>
      <div class="card">
        <div class="header">
          <h1>VÉ XEM PHIM</h1>
          <p>MOVIETICKET BOOKING</p>
        </div>
        <div class="content">
          <div class="movie-title">$movieTitle</div>
          
          <div class="info-row">
            <div class="info-label">RẠP & PHÒNG:</div>
            <div class="info-value">$cinemaName - $roomName</div>
          </div>
          
          <div class="info-row">
            <div class="info-label">THỜI GIAN:</div>
            <div class="info-value">$dateStr</div>
          </div>
          
          <div class="info-row">
            <div class="info-label">SỐ GHẾ:</div>
            <div class="info-value">$seatNames</div>
          </div>
          
          $foodHtml
          
          <div class="info-row">
            <div class="info-label">TỔNG TIỀN:</div>
            <div class="info-value" style="color: #22c55e;">$totalAmountStr</div>
          </div>
          
          <div class="ticket-code">
            <p style="margin: 0 0 8px 0; font-size: 11px; color: #666666; font-weight: bold;">MÃ VÉ CỦA BẠN</p>
            <span>$ticketCode</span>
          </div>
          
          <p style="font-size: 12px; color: #666666; text-align: center; margin-top: 10px;">Vui lòng trình mã vé trên tại quầy vé để in vé cứng vào phòng chiếu.</p>
        </div>
        <div class="footer">
          Cảm ơn bạn đã lựa chọn MovieTicket!<br>
          © 2026 MovieTicket Solution. All rights reserved.
        </div>
      </div>
    </body>
    </html>
    ''';
  }
}

final emailService = EmailService();
