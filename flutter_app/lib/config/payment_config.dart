class PaymentConfig {
  /// Ngân hàng nhận tiền thanh toán (Ví dụ: MBBank, Vietcombank, Techcombank, ACB...)
  static const String sepayBank = String.fromEnvironment(
    'SEPAY_BANK',
    defaultValue: 'Vietinbank',
  );

  /// Số tài khoản ngân hàng nhận tiền
  static const String sepayAccountNumber = String.fromEnvironment(
    'SEPAY_ACCOUNT_NUMBER',
    defaultValue: '101877359786',
  );

  /// Tên chủ tài khoản ngân hàng (viết hoa không dấu)
  static const String sepayAccountName = String.fromEnvironment(
    'SEPAY_ACCOUNT_NAME',
    defaultValue: 'PHAN LY VAN KHOA',
  );

  /// Token bảo mật dùng để xác thực webhook gửi từ SePay sang Supabase
  /// Giá trị này cần trùng khớp với mã token được cấu hình ở webhook SePay Dashboard
  /// và biến v_sepay_key trong hàm RPC sepay_webhook của Supabase.
  static const String sepaySecretToken = String.fromEnvironment(
    'SEPAY_SECRET_TOKEN',
    defaultValue: 'sepay_secret_token_123456',
  );
}
