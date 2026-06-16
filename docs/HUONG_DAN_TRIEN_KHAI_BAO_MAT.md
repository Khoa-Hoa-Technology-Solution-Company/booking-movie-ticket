# Hướng Dẫn Từng Bước Triển Khai Bảo Mật Tài Khoản (Developer Integration Guide)

Tài liệu này hướng dẫn chi tiết cách tự xây dựng (implement) hệ thống bảo mật tài khoản từ con số 0 cho các nhóm khác đang làm đồ án tích hợp **Node.js Express + Prisma (MySQL)** và **Flutter**.

---

## 🛠️ Bước 1: Thiết Kế Cơ Sở Dữ Liệu (Database Schema)

Để lưu trữ các thông tin bảo mật, hệ thống cần tối thiểu 5 bảng sau trong file `schema.prisma`. 

Các nhóm chỉ cần copy và điều chỉnh cấu trúc này vào file `schema.prisma` của mình:

```prisma
// 1. Bảng User (Tài khoản người dùng)
model User {
  id                  Int       @id @default(autoincrement())
  name                String    @db.VarChar(100)
  email               String?   @unique @db.VarChar(255)
  phoneNumber         String?   @unique @map("phone_number") @db.VarChar(20)
  passwordHash        String    @map("password_hash") @db.VarChar(255)
  emailVerified       Boolean   @default(false) @map("email_verified")
  phoneVerified       Boolean   @default(false) @map("phone_verified")
  twoFactorEnabled    Boolean   @default(false) @map("two_factor_enabled")
  failedLoginAttempts Int       @default(0) @map("failed_login_attempts")
  lockedUntil         DateTime? @map("locked_until")
  lastLoginAt         DateTime? @map("last_login_at")
  createdAt           DateTime  @default(now()) @map("created_at")

  // Các quan hệ bảo mật
  verificationCodes VerificationCode[]
  refreshTokens     RefreshToken[]
  loginHistory      LoginHistory[]
  securityAlerts    SecurityAlert[]
}

// 2. Bảng VerificationCode (Lưu mã xác minh & OTP)
enum VerificationCodeType {
  EMAIL_VERIFY
  PHONE_VERIFY
  OTP_LOGIN
  PASSWORD_RESET
}

model VerificationCode {
  id        Int                  @id @default(autoincrement())
  userId    Int                  @map("user_id")
  codeHash  String               @map("code_hash") @db.VarChar(255) // Chỉ lưu SHA-256 hash
  type      VerificationCodeType
  expiresAt DateTime             @map("expires_at")
  used      Boolean              @default(false)
  attempts  Int                  @default(0) // Số lần nhập sai mã này
  createdAt DateTime             @default(now()) @map("created_at")

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)
}

// 3. Bảng RefreshToken (Lưu vết token làm mới để rotate)
model RefreshToken {
  id        Int      @id @default(autoincrement())
  userId    Int      @map("user_id")
  tokenHash String   @map("token_hash") @db.VarChar(255) // Chỉ lưu hash của refresh token
  expiresAt DateTime @map("expires_at")
  revoked   Boolean  @default(false) // Đã bị thu hồi/đăng xuất hay chưa
  createdAt DateTime @default(now()) @map("created_at")

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)
}

// 4. Bảng LoginHistory (Lịch sử đăng nhập)
model LoginHistory {
  id         Int      @id @default(autoincrement())
  userId     Int?     @map("user_id")
  email      String?  @db.VarChar(255)
  ipAddress  String?  @map("ip_address") @db.VarChar(45)
  userAgent  String?  @map("user_agent") @db.VarChar(500)
  deviceName String?  @map("device_name") @db.VarChar(255)
  success    Boolean  // Đăng nhập thành công hay không
  reason     String?  @db.VarChar(255) // Lý do thất bại (nếu có)
  suspicious Boolean  @default(false)  // Đánh dấu thiết bị lạ đáng ngờ
  createdAt  DateTime @default(now()) @map("created_at")

  user User? @relation(fields: [userId], references: [id], onDelete: SetNull)
}

// 5. Bảng SecurityAlert (Nhật ký cảnh báo bảo mật)
enum AlertSeverity {
  LOW
  MEDIUM
  HIGH
  CRITICAL
}

model SecurityAlert {
  id        Int           @id @default(autoincrement())
  userId    Int           @map("user_id")
  type      String        @db.VarChar(50) // e.g., "ACCOUNT_LOCKED", "SUSPICIOUS_LOGIN"
  message   String        @db.VarChar(500)
  severity  AlertSeverity @default(MEDIUM)
  read      Boolean       @default(false)
  createdAt DateTime      @default(now()) @map("created_at")

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)
}
```

Sau khi cấu hình schema, chạy lệnh tạo migration và cập nhật DB:
```bash
npx prisma migrate dev --name init_security_tables
```

---

## 🔒 Bước 2: Triển Khai Phía Backend (Node.js & Express)

### 2.1. Cấu hình mã hóa mật khẩu an toàn
Cài đặt thư viện `argon2` để băm mật khẩu và `crypto` để sinh mã/hash SHA-256:
```bash
npm install argon2
```

Tạo helper mã hóa (ví dụ: `src/utils/crypto.js`):
```javascript
const argon2 = require('argon2');
const crypto = require('crypto');

// Băm mật khẩu bằng Argon2id
async function hashPassword(password) {
  return argon2.hash(password, {
    type: argon2.argon2id, // Chống GPU cracking rất mạnh
    memoryCost: 65536,    // 64MB RAM
    timeCost: 3,          // 3 vòng lặp
    parallelism: 4        // 4 luồng xử lý
  });
}

// Kiểm tra mật khẩu đúng/sai
async function verifyPassword(password, hash) {
  return argon2.verify(hash, password);
}

// Băm mã OTP/Token bằng SHA-256 (tránh lưu mã thô trong database)
function hashSHA256(value) {
  return crypto.createHash('sha256').update(value).digest('hex');
}

// Sinh mã ngẫu nhiên 6 số
function generateVerificationCode() {
  return crypto.randomInt(100000, 999999).toString();
}

module.exports = { hashPassword, verifyPassword, hashSHA256, generateVerificationCode };
```

### 2.2. Xây dựng logic đăng nhập phân nhánh 2FA
Luồng đăng nhập xử lý:
1. Kiểm tra tài khoản có bị khóa hay không.
2. Kiểm tra mật khẩu $\rightarrow$ nếu sai tăng số lần thử (`failedLoginAttempts`), quá 5 lần thì ghi nhận thời gian khóa (`lockedUntil`).
3. Nếu mật khẩu đúng $\rightarrow$ kiểm tra xem tài khoản có bật 2FA (`twoFactorEnabled`) không.
    *   **Có bật 2FA**: Sinh mã OTP 6 số $\rightarrow$ băm SHA-256 lưu DB $\rightarrow$ gửi mã về Email $\rightarrow$ Trả về Client cờ `requireOtp: true`.
    *   **Không bật 2FA**: Tiến hành cấp JWT Access Token và Refresh Token ngay.

Đoạn code cốt lõi xử lý Đăng nhập:
```javascript
// POST /auth/login
async function login(req, res) {
  const { identifier, password, deviceName } = req.body;

  // 1. Tìm user
  const user = await prisma.user.findFirst({
    where: { OR: [{ email: identifier }, { phoneNumber: identifier }] }
  });
  if (!user) return res.status(401).json({ success: false, message: 'Sai tài khoản hoặc mật khẩu' });

  // 2. Kiểm tra trạng thái khóa tài khoản
  if (user.lockedUntil && user.lockedUntil > new Date()) {
    const minutesLeft = Math.ceil((user.lockedUntil - new Date()) / 60000);
    return res.status(423).json({ success: false, message: `Tài khoản tạm khóa. Thử lại sau ${minutesLeft} phút.` });
  }

  // 3. Khớp mật khẩu
  const isCorrect = await verifyPassword(password, user.passwordHash);
  if (!isCorrect) {
    const attempts = user.failedLoginAttempts + 1;
    const updateData = { failedLoginAttempts: attempts };
    
    if (attempts >= 5) {
      updateData.lockedUntil = new Date(Date.now() + 5 * 60 * 1000); // Khóa 5 phút
      // Tạo bản ghi SecurityAlert
      await prisma.securityAlert.create({
        data: { userId: user.id, type: 'ACCOUNT_LOCKED', severity: 'HIGH', message: 'Tài khoản bị khóa do đăng nhập sai 5 lần.' }
      });
    }
    
    await prisma.user.update({ where: { id: user.id }, data: updateData });
    return res.status(401).json({ success: false, message: 'Sai tài khoản hoặc mật khẩu.' });
  }

  // 4. Reset số lần nhập sai nếu đăng nhập thành công bước mật khẩu
  await prisma.user.update({
    where: { id: user.id },
    data: { failedLoginAttempts: 0, lockedUntil: null }
  });

  // 5. Kiểm tra 2FA
  if (user.twoFactorEnabled) {
    const otpCode = generateVerificationCode();
    // Vô hiệu hóa OTP cũ
    await prisma.verificationCode.updateMany({
      where: { userId: user.id, type: 'OTP_LOGIN', used: false },
      data: { used: true }
    });
    // Lưu OTP mới dạng SHA-256 hash
    await prisma.verificationCode.create({
      data: {
        userId: user.id,
        codeHash: hashSHA256(otpCode),
        type: 'OTP_LOGIN',
        expiresAt: new Date(Date.now() + 5 * 60 * 1000) // Hạn 5 phút
      }
    });

    // In mã OTP ra Console (hoặc gửi Email thực tế qua nodemailer)
    console.log(`🔑 OTP ĐĂNG NHẬP CHO USER: ${otpCode}`);

    return res.json({
      success: true,
      data: { requireOtp: true, identifier: identifier, message: 'Yêu cầu OTP xác thực 2 lớp.' }
    });
  }

  // 6. Cấp token (nếu không bật 2FA)
  const tokens = await issueTokens(user.id);
  // Ghi lịch sử đăng nhập & kiểm tra thiết bị lạ
  await processDeviceLogin(user.id, deviceName, req);

  return res.json({ success: true, data: tokens });
}
```

### 2.3. Kiểm tra thiết bị lạ (Suspicious Device Check)
Khi đăng nhập thành công, hệ thống đối chiếu tên thiết bị gửi lên với lịch sử đăng nhập trước đó:

```javascript
async function processDeviceLogin(userId, deviceName, req) {
  // Lấy các thiết bị đã từng login thành công trước đây
  const previousLogins = await prisma.loginHistory.findMany({
    where: { userId, success: true },
    distinct: ['deviceName'],
    select: { deviceName: true }
  });

  // Nếu đã từng có lịch sử và thiết bị hiện tại chưa có trong danh sách -> Thiết bị lạ!
  const isNewDevice = previousLogins.length > 0 && 
                      !previousLogins.some(h => h.deviceName === deviceName);

  if (isNewDevice) {
    // Tạo cảnh báo bảo mật thiết bị lạ
    await prisma.securityAlert.create({
      data: {
        userId,
        type: 'SUSPICIOUS_LOGIN',
        severity: 'MEDIUM',
        message: `Đăng nhập mới từ thiết bị lạ: ${deviceName}`
      }
    });
    // Gửi email cảnh báo (nếu có cấu hình)
  }

  // Ghi nhận lịch sử đăng nhập hiện tại
  await prisma.loginHistory.create({
    data: {
      userId,
      deviceName,
      ipAddress: req.ip || req.headers['x-forwarded-for'],
      userAgent: req.headers['user-agent'],
      success: true,
      suspicious: isNewDevice
    }
  });
}
```

---

## 📱 Bước 3: Triển Khai Phía Frontend (Flutter Mobile)

### 3.1. Lưu trữ token bảo mật
Các nhóm KHÔNG được lưu JWT Token vào `SharedPreferences` thông thường vì dữ liệu dạng XML thô dễ bị root/jailbreak đọc được. Hãy sử dụng `flutter_secure_storage`.

Cài đặt package:
```yaml
dependencies:
  flutter_secure_storage: ^9.0.0
  dio: ^5.4.0
```

Tạo lớp quản lý lưu trữ (ví dụ: `lib/core/storage/token_storage.dart`):
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();

  static Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  static Future<String?> getAccessToken() async => await _storage.read(key: 'access_token');
  static Future<String?> getRefreshToken() async => await _storage.read(key: 'refresh_token');

  static Future<void> clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }
}
```

### 3.2. Xử lý rẽ nhánh luồng Đăng nhập trong Flutter
Khi người dùng ấn đăng nhập, kiểm tra thuộc tính `requireOtp` trả về từ API:

```dart
// Trong LoginScreen
Future<void> handleLogin() async {
  try {
    final response = await apiClient.post('/auth/login', data: {
      'identifier': identifierController.text.trim(),
      'password': passwordController.text,
      'deviceName': getDeviceName(), // Ví dụ: 'Android Emulator'
    });

    final data = response.data['data'];

    if (data['requireOtp'] == true) {
      // 1. Nếu cần 2FA OTP -> Điều hướng tới màn hình nhập OTP
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpScreen(identifier: data['identifier']),
        ),
      );
    } else {
      // 2. Đăng nhập thành công trực tiếp -> Lưu token & vào trang chủ
      await TokenStorage.saveTokens(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
      );
      Navigator.pushReplacementNamed(context, '/home');
    }
  } catch (e) {
    // Hiển thị lỗi ra Snackbar
    showSnackBar(e.toString());
  }
}
```

### 3.3. Hiển thị Dashboard Bảo mật (Security Dashboard)
Trên màn hình Bảo mật, gọi API `/security/dashboard` để lấy dữ liệu thống kê, và xây dựng giao diện hiển thị:
1.  **Vòng tròn Điểm bảo mật (Security Score)**: Thể hiện trực quan bằng widget `CircularProgressIndicator` màu sắc động (Đỏ dưới 50đ, Vàng từ 50-80đ, Xanh lá trên 80đ).
2.  **Trạng thái 2FA**: Nút `Switch` cho phép bật tắt nhanh trạng thái 2FA bằng cách gửi API `PATCH /security/toggle-2fa`.
3.  **Lịch sử thiết bị**: Một `ListView.builder` hiển thị các thiết bị đã đăng nhập. Nếu thiết bị nào có thuộc tính `suspicious: true` thì bôi đỏ hoặc gắn icon cảnh báo màu đỏ kế bên.

---

## 💡 Các Lưu Ý Quan Trọng Cho Nhóm Khác Khi Làm Theo

> [!IMPORTANT]
> 1. **Co-oldown Gửi Mã (Rate-limiting)**: Cần thiết lập chặn spam gửi mã liên tục để tránh tốn tài nguyên SMTP/SMS.
> 2. **Xóa tài khoản rác chưa kích hoạt**: Trong bảng `User`, nếu đăng ký dùng email trùng lặp nhưng bản ghi cũ chưa xác minh (`emailVerified = false`), hãy cho phép xóa bản ghi cũ trước khi tạo bản ghi mới để tránh kẹt tài khoản ảo.
> 3. **An toàn bảo mật tối thượng**:
>     * Tuyệt đối không lưu mật khẩu dạng md5 hoặc sha1 đơn giản. Phải dùng **Argon2** hoặc **Bcrypt**.
>     * Tuyệt đối không log thông tin nhạy cảm của người dùng (password, mã OTP) ra console của máy chủ Production.
