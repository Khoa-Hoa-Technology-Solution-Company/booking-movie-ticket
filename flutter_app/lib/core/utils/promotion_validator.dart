class PromotionValidationResult {
  final bool isValid;
  final String? errorMessage;

  PromotionValidationResult._({required this.isValid, this.errorMessage});

  factory PromotionValidationResult.valid() =>
      PromotionValidationResult._(isValid: true);
  factory PromotionValidationResult.invalid(String message) =>
      PromotionValidationResult._(isValid: false, errorMessage: message);
}

class PromotionValidator {
  /// Kiểm tra tính hợp lệ của mã khuyến mãi dựa trên các ràng buộc:
  /// 1. Trạng thái hoạt động (active = true)
  /// 2. Thời hạn áp dụng (start_date <= today <= end_date)
  /// 3. Lượt sử dụng (usage_count < usage_limit)
  /// 4. Giá trị đơn hàng tối thiểu (totalAmount >= min_purchase)
  static PromotionValidationResult validate({
    required Map<String, dynamic> promo,
    required double purchaseAmount,
    required DateTime now,
  }) {
    // 1. Kiểm tra trạng thái kích hoạt
    final active = promo['active'] as bool? ?? false;
    if (!active) {
      return PromotionValidationResult.invalid('Mã khuyến mãi đã bị vô hiệu hóa.');
    }

    // 2. Kiểm tra giá trị đơn hàng tối thiểu
    final minPurchase = (promo['min_purchase'] as num?)?.toDouble() ?? 0.0;
    if (purchaseAmount < minPurchase) {
      return PromotionValidationResult.invalid(
          'Đơn hàng chưa đạt giá trị tối thiểu ${minPurchase.toStringAsFixed(0)}đ để áp dụng mã.');
    }

    // 3. Kiểm tra thời hạn áp dụng (bỏ qua giờ để so sánh ngày)
    final startDateStr = promo['start_date'] as String?;
    final endDateStr = promo['end_date'] as String?;
    if (startDateStr != null && endDateStr != null) {
      try {
        final startDate = DateTime.parse(startDateStr);
        final endDate = DateTime.parse(endDateStr);

        final today = DateTime(now.year, now.month, now.day);
        final startDay = DateTime(startDate.year, startDate.month, startDate.day);
        final endDay = DateTime(endDate.year, endDate.month, endDate.day);

        if (today.isBefore(startDay)) {
          return PromotionValidationResult.invalid('Mã khuyến mãi chưa đến thời gian áp dụng.');
        }
        if (today.isAfter(endDay)) {
          return PromotionValidationResult.invalid('Mã khuyến mãi đã hết hạn sử dụng.');
        }
      } catch (_) {
        return PromotionValidationResult.invalid('Định dạng thời gian của mã không hợp lệ.');
      }
    }

    // 4. Kiểm tra giới hạn lượt sử dụng
    final usageLimit = promo['usage_limit'] as int?;
    final usageCount = promo['usage_count'] as int? ?? 0;
    if (usageLimit != null && usageCount >= usageLimit) {
      return PromotionValidationResult.invalid('Mã khuyến mãi đã hết lượt sử dụng.');
    }

    return PromotionValidationResult.valid();
  }
}
