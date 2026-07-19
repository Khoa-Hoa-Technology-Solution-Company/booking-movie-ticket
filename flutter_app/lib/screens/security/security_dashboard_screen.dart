import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/security_service.dart';
import '../../models/security.dart';
import 'security_issues_screen.dart';
import 'login_history_screen.dart';
import 'security_alerts_screen.dart';
import '../../core/theme/app_theme.dart';

class SecurityDashboardScreen extends StatefulWidget {
  const SecurityDashboardScreen({super.key});

  @override
  State<SecurityDashboardScreen> createState() => _SecurityDashboardScreenState();
}

class _SecurityDashboardScreenState extends State<SecurityDashboardScreen> {
  bool _isLoading = false;
  SecurityDashboard? _dashboardData;
  bool _twoFactorEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final data = await securityService.getDashboard();
      setState(() {
        _dashboardData = data;
        _twoFactorEnabled = data.twoFactorEnabled;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tải được thông tin bảo mật: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleToggle2FA(bool value) async {
    setState(() => _isLoading = true);
    try {
      final result = await securityService.toggle2FA(value);
      setState(() {
        _twoFactorEnabled = result;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value 
                ? 'Đã BẬT xác thực 2 lớp (2FA) thành công!' 
                : 'Đã TẮT xác thực 2 lớp (2FA).'),
            backgroundColor: Colors.green,
          ),
        );
      }
      // Reload dashboard to update security score
      await _loadDashboardData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Thao tác thất bại: $e'), backgroundColor: Colors.red),
        );
      }
      // Restore state if failed
      setState(() => _twoFactorEnabled = !value);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context); // Đăng ký lắng nghe sự kiện đổi theme để vẽ lại giao diện lập tức
    final theme = Theme.of(context);
    final security = _dashboardData;
    final int securityScore = security?.securityScore ?? 50;
    
    Color scoreColor = Colors.redAccent;
    if (securityScore >= 75) {
      scoreColor = Colors.greenAccent;
    } else if (securityScore >= 50) {
      scoreColor = Colors.amberAccent;
    }

    final lastLoginAt = security?.lastLoginAt;
    final lastLoginStr = lastLoginAt != null
      ? DateFormat('dd/MM/yyyy HH:mm').format(lastLoginAt)
      : 'Chưa có dữ liệu';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Trung Tâm Bảo Mật', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading && _dashboardData == null
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC084FC)))
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              color: const Color(0xFFC084FC),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Security Score Gauge
                    Card(
                      color: AppColors.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 130,
                                  height: 130,
                                  child: CircularProgressIndicator(
                                    value: securityScore / 100,
                                    strokeWidth: 12,
                                    backgroundColor: AppColors.border,
                                    color: scoreColor,
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '$securityScore%',
                                      style: theme.textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text('An toàn', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Điểm Bảo Mật Tài Khoản',
                              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              securityScore >= 75
                                  ? 'Tài khoản của bạn đang được bảo vệ rất tốt.'
                                  : 'Hãy khắc phục các sự cố bảo mật để bảo vệ tài khoản tốt hơn.',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Quick Toggle for 2FA/OTP
                    Card(
                      color: AppColors.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: SwitchListTile(
                        value: _twoFactorEnabled,
                        onChanged: _isLoading ? null : _handleToggle2FA,
                        title: Text(
                          'Xác thực 2 bước (2FA)',
                          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: Text(
                          'Yêu cầu nhập mã OTP gửi qua Email mỗi khi đăng nhập',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                        activeThumbColor: const Color(0xFFC084FC),
                        activeTrackColor: const Color(0xFFC084FC).withAlpha(76),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Kênh xác minh status
                    Card(
                      color: AppColors.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Các kênh liên lạc & Xác minh',
                              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                            _buildChannelStatus(
                              title: 'Địa chỉ Email',
                              value: security?.emailVerified == true ? 'Đã xác minh' : 'Chưa xác minh',
                              isVerified: security?.emailVerified == true,
                              hasChannel: security?.hasEmail == true,
                              icon: Icons.email,
                            ),
                            Divider(color: AppColors.border, height: 16),
                            _buildChannelStatus(
                              title: 'Số điện thoại',
                              value: 'Chưa liên kết',
                              isVerified: false,
                              hasChannel: false,
                              icon: Icons.phone,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Navigation Menu Options
                    Text('Báo cáo chi tiết', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    
                    _buildNavCard(
                      icon: Icons.warning_amber_rounded,
                      iconColor: Colors.amberAccent,
                      title: 'Sự cố bảo mật cần xử lý',
                      subtitle: 'Xem các cảnh báo lỗi hoặc khuyến nghị',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SecurityIssuesScreen()),
                        ).then((_) => _loadDashboardData());
                      },
                    ),
                    _buildNavCard(
                      icon: Icons.history_toggle_off_rounded,
                      iconColor: Colors.blueAccent,
                      title: 'Lịch sử đăng nhập thiết bị',
                      subtitle: 'Xem danh sách thiết bị và địa chỉ IP',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginHistoryScreen()),
                        );
                      },
                    ),
                    _buildNavCard(
                      icon: Icons.add_alert_rounded,
                      iconColor: Colors.redAccent,
                      title: 'Cảnh báo và Nhật ký bảo mật',
                      subtitle: 'Các cảnh báo đăng nhập lạ hoặc khóa acc',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SecurityAlertsScreen()),
                        );
                      },
                    ),

                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'Đăng nhập cuối: $lastLoginStr',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildChannelStatus({
    required String title,
    required String value,
    required bool isVerified,
    required bool hasChannel,
    required IconData icon,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 18),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
        Row(
          children: [
            if (!hasChannel)
              const Text('Chưa liên kết', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold))
            else
              Text(
                value,
                style: TextStyle(
                  color: isVerified ? Colors.greenAccent : Colors.redAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(width: 4),
            if (hasChannel)
              Icon(
                isVerified ? Icons.check_circle_outline : Icons.error_outline,
                color: isVerified ? Colors.greenAccent : Colors.redAccent,
                size: 14,
              )
            else
              const Icon(Icons.help_outline, color: Colors.grey, size: 14),
          ],
        ),
      ],
    );
  }

  Widget _buildNavCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        trailing: Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 16),
        onTap: onTap,
      ),
    );
  }
}
