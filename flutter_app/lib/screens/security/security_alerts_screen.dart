import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/security_service.dart';
import '../../models/security.dart';
import '../../core/theme/app_theme.dart';

class SecurityAlertsScreen extends StatefulWidget {
  const SecurityAlertsScreen({super.key});

  @override
  State<SecurityAlertsScreen> createState() => _SecurityAlertsScreenState();
}

class _SecurityAlertsScreenState extends State<SecurityAlertsScreen> {
  bool _isLoading = false;
  List<SecurityAlert> _alerts = [];

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => _isLoading = true);
    try {
      final alerts = await securityService.getAlerts();
      setState(() {
        _alerts = alerts;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tải được cảnh báo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context); // Đăng ký lắng nghe sự kiện đổi theme để vẽ lại giao diện lập tức
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cảnh Báo Bảo Mật', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadAlerts,
              color: AppColors.primary,
              child: _alerts.isEmpty
                  ? Center(
                      child: Text('Không có cảnh báo bảo mật nào', style: TextStyle(color: AppColors.textSecondary)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _alerts.length,
                      itemBuilder: (context, index) {
                        final alert = _alerts[index];
                        final String severity = alert.severity;
                        final String type = alert.type;
                        final String message = alert.message;
                        final date = alert.createdAt;
                        final dateStr = DateFormat('dd/MM/yyyy HH:mm:ss').format(date);

                        Color severityColor = Colors.blue;
                        IconData icon = Icons.info_outline;

                        if (severity == 'CRITICAL' || severity == 'HIGH') {
                          severityColor = Colors.redAccent;
                          icon = Icons.gpp_bad;
                        } else if (severity == 'MEDIUM') {
                          severityColor = Colors.amberAccent;
                          icon = Icons.security_rounded;
                        } else {
                          severityColor = Colors.greenAccent;
                          icon = Icons.gpp_good;
                        }

                        return Card(
                          color: AppColors.surface,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: severityColor.withAlpha(51), width: 1.5),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(icon, color: severityColor, size: 28),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              type.replaceAll('_', ' '),
                                              style: TextStyle(
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            dateStr,
                                            style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        message,
                                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                                      ),
                                    ],
                                  ),
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
