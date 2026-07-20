import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class PaymentCountdownTimer extends StatefulWidget {
  final DateTime createdAt;
  final int timeoutMinutes;
  final VoidCallback? onTimerExpired;
  final double fontSize;
  final bool compact;

  const PaymentCountdownTimer({
    super.key,
    required this.createdAt,
    this.timeoutMinutes = 5,
    this.onTimerExpired,
    this.fontSize = 13.0,
    this.compact = false,
  });

  @override
  State<PaymentCountdownTimer> createState() => _PaymentCountdownTimerState();
}

class _PaymentCountdownTimerState extends State<PaymentCountdownTimer> {
  Timer? _timer;
  late int _remainingSeconds;
  bool _hasTriggeredExpired = false;

  @override
  void initState() {
    super.initState();
    _calculateRemainingSeconds();
    if (_remainingSeconds <= 0) {
      if (!_hasTriggeredExpired) {
        _hasTriggeredExpired = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && widget.onTimerExpired != null) {
            widget.onTimerExpired!();
          }
        });
      }
    } else {
      _startTimer();
    }
  }

  void _calculateRemainingSeconds() {
    final expireTime = widget.createdAt.add(Duration(minutes: widget.timeoutMinutes));
    final now = DateTime.now();
    final diff = expireTime.difference(now).inSeconds;
    _remainingSeconds = diff > 0 ? diff : 0;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      _calculateRemainingSeconds();

      if (_remainingSeconds <= 0) {
        timer.cancel();
        if (!_hasTriggeredExpired) {
          _hasTriggeredExpired = true;
          if (widget.onTimerExpired != null) {
            widget.onTimerExpired!();
          }
        }
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context); // Lắng nghe theme đổi
    final timeStr = _formatTime(_remainingSeconds);

    Color badgeBgColor;
    Color textColor;

    if (_remainingSeconds > 120) {
      badgeBgColor = Colors.amber.withAlpha(30);
      textColor = Colors.amber.shade400;
    } else if (_remainingSeconds > 60) {
      badgeBgColor = Colors.orange.withAlpha(35);
      textColor = Colors.orangeAccent;
    } else {
      badgeBgColor = AppColors.danger.withAlpha(45);
      textColor = AppColors.danger;
    }

    if (widget.compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: badgeBgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: textColor.withAlpha(100), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, size: widget.fontSize + 2, color: textColor),
            const SizedBox(width: 4),
            Text(
              timeStr,
              style: TextStyle(
                color: textColor,
                fontSize: widget.fontSize,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: badgeBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withAlpha(120), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer_sharp, size: widget.fontSize + 4, color: textColor),
          const SizedBox(width: 8),
          Text(
            'Thời gian giữ ghế còn lại: ',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: widget.fontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            timeStr,
            style: TextStyle(
              color: textColor,
              fontSize: widget.fontSize + 2,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
