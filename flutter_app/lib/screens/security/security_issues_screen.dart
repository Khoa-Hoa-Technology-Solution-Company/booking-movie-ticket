import 'package:flutter/material.dart';
import '../../services/security_service.dart';

class SecurityIssuesScreen extends StatefulWidget {
  const SecurityIssuesScreen({super.key});

  @override
  State<SecurityIssuesScreen> createState() => _SecurityIssuesScreenState();
}

class _SecurityIssuesScreenState extends State<SecurityIssuesScreen> {
  bool _isLoading = false;
  List<dynamic> _issues = [];

  @override
  void initState() {
    super.initState();
    _loadIssues();
  }

  Future<void> _loadIssues() async {
    setState(() => _isLoading = true);
    try {
      final issues = await securityService.getIssues();
      setState(() {
        _issues = issues;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tải được danh sách sự cố: $e')),
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
        title: const Text('Sự Cố Bảo Mật', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF16162A),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC084FC)))
          : RefreshIndicator(
              onRefresh: _loadIssues,
              color: const Color(0xFFC084FC),
              child: _issues.isEmpty
                  ? _buildSuccessView()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _issues.length,
                      itemBuilder: (context, index) {
                        final issue = _issues[index];
                        final String severity = issue['severity'] ?? 'LOW';
                        
                        Color severityColor = Colors.blue;
                        if (severity == 'CRITICAL' || severity == 'HIGH') {
                          severityColor = Colors.redAccent;
                        } else if (severity == 'MEDIUM') {
                          severityColor = Colors.amberAccent;
                        }

                        return Card(
                          color: const Color(0xFF16162A),
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: severityColor.withOpacity(0.3), width: 1),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        issue['title'] ?? 'Cảnh báo bảo mật',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: severityColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        severity,
                                        style: TextStyle(
                                          color: severityColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  issue['description'] ?? '',
                                  style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
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

  Widget _buildSuccessView() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 46,
              backgroundColor: Colors.green,
              child: Icon(Icons.check_circle_outline, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tài Khoản An Toàn!',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 8),
            const Text(
              'Không phát hiện thấy sự cố bảo mật nào. Tài khoản của bạn đã được tối ưu hóa bảo vệ tốt nhất.',
              style: TextStyle(color: Colors.white54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
