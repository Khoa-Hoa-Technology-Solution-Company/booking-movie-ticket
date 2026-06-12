import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/security_service.dart';

class LoginHistoryScreen extends StatefulWidget {
  const LoginHistoryScreen({super.key});

  @override
  State<LoginHistoryScreen> createState() => _LoginHistoryScreenState();
}

class _LoginHistoryScreenState extends State<LoginHistoryScreen> {
  bool _isLoading = false;
  List<dynamic> _items = [];
  int _page = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final data = await securityService.getLoginHistory(page: _page, limit: 15);
      setState(() {
        _items = data['items'] ?? [];
        final pagination = data['pagination'];
        if (pagination != null) {
          _totalPages = pagination['totalPages'] ?? 1;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tải được lịch sử: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        title: const Text('Lịch Sử Đăng Nhập', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF16162A),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading && _items.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC084FC)))
          : Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      setState(() => _page = 1);
                      await _loadHistory();
                    },
                    color: const Color(0xFFC084FC),
                    child: _items.isEmpty
                        ? const Center(
                            child: Text('Chưa có lịch sử đăng nhập nào', style: TextStyle(color: Colors.white54)),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _items.length,
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              final bool success = item['success'] ?? false;
                              final bool suspicious = item['suspicious'] ?? false;
                              
                              final date = DateTime.parse(item['createdAt']).toLocal();
                              final dateStr = DateFormat('dd/MM/yyyy HH:mm:add').format(date); // wait, HH:mm:ss is better
                              final dateStrFormatted = DateFormat('dd/MM/yyyy HH:mm:ss').format(date);

                              Color indicatorColor = success ? Colors.green : Colors.red;
                              if (suspicious) indicatorColor = Colors.amber;

                              IconData indicatorIcon = success ? Icons.check_circle_outline : Icons.error_outline;
                              if (suspicious) indicatorIcon = Icons.gpp_maybe;

                              return Card(
                                color: const Color(0xFF16162A),
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: suspicious 
                                      ? const BorderSide(color: Colors.amber, width: 1)
                                      : BorderSide.none,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Left indicator icon
                                      CircleAvatar(
                                        backgroundColor: indicatorColor.withOpacity(0.1),
                                        child: Icon(indicatorIcon, color: indicatorColor),
                                      ),
                                      const SizedBox(width: 16),
                                      
                                      // Content details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['email'] ?? item['deviceName'] ?? 'Thiết bị không rõ',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'IP: ${item['ipAddress'] ?? 'Unkown'} • ${item['userAgent'] ?? ''}',
                                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              dateStrFormatted,
                                              style: const TextStyle(color: Color(0xFFC084FC), fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                            if (!success && item['reason'] != null) ...[
                                              const SizedBox(height: 6),
                                              Text(
                                                'Lý do thất bại: ${item['reason']}',
                                                style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                              ),
                                            ]
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
                ),
                
                // Pagination Buttons
                if (_totalPages > 1)
                  Container(
                    color: const Color(0xFF16162A),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, color: Colors.white),
                          onPressed: _page > 1
                              ? () {
                                  setState(() => _page--);
                                  _loadHistory();
                                }
                              : null,
                        ),
                        Text('Trang $_page / $_totalPages', style: const TextStyle(color: Colors.white)),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, color: Colors.white),
                          onPressed: _page < _totalPages
                              ? () {
                                  setState(() => _page++);
                                  _loadHistory();
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
