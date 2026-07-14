import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/security_service.dart';
import '../../services/user_service.dart';
import '../../models/user.dart';
import '../../models/security.dart';
import '../auth/login_screen.dart';
import '../admin/admin_dashboard_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  String _name = 'Khách';
  String _email = '';
  String _role = 'USER';
  bool _emailVerified = false;
  bool _twoFactorEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final User user = await userService.getProfile();
      final SecurityDashboard dashboard = await securityService.getDashboard();
      setState(() {
        _name = user.name;
        _email = user.email ?? '';
        _role = user.role == UserRole.admin ? 'ADMIN' : 'USER';
        _emailVerified = dashboard.emailVerified;
        _twoFactorEnabled = dashboard.twoFactorEnabled;
      });
    } catch (_) {
      // Bỏ qua lỗi kết nối
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Đăng Xuất', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              await authService.logout();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            child: const Text('Đăng Xuất', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditNameDialog() {
    final controller = TextEditingController(text: _name);
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Đổi Tên Hiển Thị', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Họ và tên',
                prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.textMuted),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ tên' : null,
            ),
          ),
          actions: [
            TextButton(onPressed: isSaving ? null : () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: AppColors.textMuted))),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                if (!formKey.currentState!.validate()) return;
                setDialogState(() => isSaving = true);
                try {
                  await userService.updateProfile(name: controller.text.trim());
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã cập nhật tên thành công!'), backgroundColor: AppColors.success));
                    _loadProfileData();
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Thất bại: $e'), backgroundColor: AppColors.danger));
                } finally {
                  setDialogState(() => isSaving = false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
              child: isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Text('Lưu', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPwCtrl = TextEditingController();
    final newPwCtrl = TextEditingController();
    final confirmPwCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Đổi Mật Khẩu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _pwField(controller: currentPwCtrl, label: 'Mật khẩu hiện tại',
                    validator: (v) => (v == null || v.isEmpty) ? 'Nhập mật khẩu cũ' : null),
                  const SizedBox(height: 14),
                  _pwField(controller: newPwCtrl, label: 'Mật khẩu mới',
                    validator: (v) => (v == null || v.length < 6) ? 'Ít nhất 6 ký tự' : null),
                  const SizedBox(height: 14),
                  _pwField(controller: confirmPwCtrl, label: 'Xác nhận mật khẩu mới',
                    validator: (v) => v != newPwCtrl.text ? 'Mật khẩu không trùng khớp' : null),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: isSaving ? null : () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: AppColors.textMuted))),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                if (!formKey.currentState!.validate()) return;
                setDialogState(() => isSaving = true);
                try {
                  await userService.changePassword(
                    currentPassword: currentPwCtrl.text,
                    newPassword: newPwCtrl.text,
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đổi mật khẩu thành công!'), backgroundColor: AppColors.success));
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Thất bại: $e'), backgroundColor: AppColors.danger));
                } finally {
                  setDialogState(() => isSaving = false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
              child: isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Text('Đổi Mật Khẩu', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pwField({required TextEditingController controller, required String label, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted, size: 18),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    final initials = _name.isNotEmpty ? _name[0].toUpperCase() : 'K';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading && _name == 'Khách'
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadProfileData,
              color: AppColors.primary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // === GRADIENT HEADER ===
                  SliverToBoxAdapter(child: _buildProfileHeader(initials)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Status badges
                        _buildStatusSection(),
                        const SizedBox(height: AppSpacing.xl),

                        // Section: Tài khoản
                        _buildSectionLabel('Tài Khoản'),
                        const SizedBox(height: AppSpacing.sm),
                        if (_role == 'ADMIN')
                          _buildMenuItem(
                            icon: Icons.admin_panel_settings_rounded,
                            color: AppColors.accent,
                            title: 'Quản Trị Hệ Thống',
                            subtitle: 'Quản lý phim, suất chiếu, doanh thu',
                            onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const AdminDashboardScreen())),
                          ),
                        _buildMenuItem(
                          icon: Icons.person_outline_rounded,
                          color: AppColors.primary,
                          title: 'Đổi tên hiển thị',
                          subtitle: 'Cập nhật họ tên tài khoản',
                          onTap: _showEditNameDialog,
                        ),
                        _buildMenuItem(
                          icon: Icons.lock_reset_rounded,
                          color: AppColors.primary,
                          title: 'Đổi mật khẩu',
                          subtitle: 'Thay đổi mật khẩu đăng nhập',
                          onTap: _showChangePasswordDialog,
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Section: Ứng dụng
                        _buildSectionLabel('Ứng Dụng'),
                        const SizedBox(height: AppSpacing.sm),
                        _buildMenuItem(
                          icon: Icons.notifications_none_rounded,
                          color: const Color(0xFF06B6D4),
                          title: 'Thông báo',
                          subtitle: 'Cài đặt thông báo đẩy',
                          onTap: () {},
                        ),
                        _buildMenuItem(
                          icon: Icons.help_outline_rounded,
                          color: const Color(0xFF10B981),
                          title: 'Trợ giúp & Hỗ trợ',
                          subtitle: 'Câu hỏi thường gặp, liên hệ',
                          onTap: () {},
                        ),
                        _buildMenuItem(
                          icon: Icons.info_outline_rounded,
                          color: AppColors.textMuted,
                          title: 'Điều khoản & Chính sách',
                          subtitle: 'Thông tin pháp lý, quyền riêng tư',
                          onTap: () {},
                        ),
                        const SizedBox(height: AppSpacing.xxl),

                        // Logout button
                        _buildLogoutButton(),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader(String initials) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1B4B), Color(0xFF0F0F1A)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            children: [
              // Avatar with gradient ring
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                    ),
                    child: Center(
                      child: Text(initials,
                        style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.black)),
                    ),
                  ),
                  GestureDetector(
                    onTap: _showEditNameDialog,
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: const Icon(Icons.edit_rounded, size: 14, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(_name, style: AppTextStyles.titleLarge),
              const SizedBox(height: 4),
              Text(_email.isNotEmpty ? _email : 'MovieTicket User',
                style: AppTextStyles.body),
              const SizedBox(height: 12),
              // Role badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  gradient: _role == 'ADMIN'
                      ? const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFEF4444)])
                      : null,
                  color: _role == 'ADMIN' ? null : AppColors.primaryDim,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _role == 'ADMIN' ? Icons.verified_rounded : Icons.person_rounded,
                      size: 14,
                      color: _role == 'ADMIN' ? Colors.white : AppColors.primary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _role == 'ADMIN' ? 'Quản Trị Viên' : 'Thành Viên',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _role == 'ADMIN' ? Colors.white : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    return Row(
      children: [
        Expanded(child: _buildStatusBadge(
          icon: Icons.mark_email_read_rounded,
          label: 'Email xác minh',
          isActive: _emailVerified,
          activeColor: AppColors.success,
        )),
        const SizedBox(width: 12),
        Expanded(child: _buildStatusBadge(
          icon: Icons.security_rounded,
          label: 'Bảo mật 2FA',
          isActive: _twoFactorEnabled,
          activeColor: AppColors.primary,
        )),
      ],
    );
  }

  Widget _buildStatusBadge({required IconData icon, required String label, required bool isActive, required Color activeColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: isActive ? activeColor.withOpacity(0.08) : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? activeColor.withOpacity(0.4) : AppColors.border,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: isActive ? activeColor : AppColors.textMuted, size: 30),
          const SizedBox(height: 6),
          Text(label,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : AppColors.textMuted,
            )),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isActive ? activeColor.withOpacity(0.15) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isActive ? 'Đã bật' : 'Chưa bật',
              style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold,
                color: isActive ? activeColor : AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(label,
        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600,
          color: AppColors.textMuted, letterSpacing: 1.0)),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: const Border.fromBorderSide(BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyBold),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _handleLogout,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.danger.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(color: AppColors.danger.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: AppColors.danger, size: 20),
            const SizedBox(width: 8),
            Text('Đăng Xuất',
              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.danger)),
          ],
        ),
      ),
    );
  }
}
