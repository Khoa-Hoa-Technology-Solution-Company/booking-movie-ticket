# HƯỚNG DẪN TÍCH HỢP FIREBASE AUTHENTICATION & KHỞI CHẠY DỰ ÁN

Tài liệu này hướng dẫn chi tiết từng bước cách thiết lập và cấu hình dịch vụ **Firebase Authentication** từ giao diện trang quản trị Web (Firebase Console) cho đến việc tích hợp, biên dịch và khởi chạy trên ứng dụng di động **Flutter** (Android).

---

## TỔNG QUAN HỆ THỐNG

Dự án **Movie Ticket Booking App** là ứng dụng đặt vé xem phim độc lập (Serverless/Standalone) trên client, sử dụng **Firebase Auth** để xử lý toàn bộ quá trình đăng ký, đăng nhập, quên mật khẩu và xác thực bảo mật 2 lớp (2FA). Tất cả các dữ liệu nghiệp vụ (danh sách phim, rạp, lịch chiếu, ghế ngồi, lịch sử đặt vé và lịch sử nhật ký bảo mật) được lưu trữ và mô phỏng cục bộ trên bộ nhớ đệm an toàn của thiết bị.

```
                  ┌────────────────────────────────────────┐
                  │          Giao diện Flutter             │
                  └───────────────────┬────────────────────┘
                                      │
                 ┌────────────────────┴────────────────────┐
                 ▼                                         ▼
   [Xác thực & Bảo mật tài khoản]              [Nghiệp vụ Đặt vé & Bảo mật]
   - Đăng nhập / Đăng ký qua Email             - Danh sách Phim, Rạp, Ghế ngồi
   - OTP 2FA (Console / Email Link)             - Lịch sử đặt vé & Nhật ký log
   - Quên & Đặt lại Mật khẩu                   - Lưu trữ cục bộ & In-Memory
                 │                                         │
                 ▼                                         ▼
   ┌────────────────────────────┐            ┌────────────────────────────┐
   │    Firebase Auth SDK       │            │   Local Storage Services   │
   └────────────────────────────┘            └────────────────────────────┘
```

---

## BƯỚC 1: TẠO DỰ ÁN TRÊN FIREBASE CONSOLE

1. Truy cập vào **[Firebase Console](https://console.firebase.google.com)** và đăng nhập bằng tài khoản Google (Gmail) của bạn.
2. Nhấn nút **Add project** (Tạo dự án).
3. Nhập tên dự án (ví dụ: `MovieTicketApp`) và nhấn **Continue**.
4. Bật hoặc tắt tính năng **Google Analytics** tùy theo nhu cầu (khuyến nghị tắt đối với môi trường học tập/demo) và nhấn **Create project**.
5. Đợi hệ thống hoàn thành khởi tạo dự án (khoảng 20 giây), sau đó nhấn **Continue** để chuyển đến trang tổng quan (Project Overview).

---

## BƯỚC 2: BẬT CÁC PHƯƠNG THỨC ĐĂNG NHẬP VÀ XÁC THỰC

### 1. Bật nhà cung cấp Email/Password
1. Ở menu bên trái, tìm mục **Build** và chọn **Authentication**.
2. Nhấn nút **Get started** ở màn hình giới thiệu.
3. Trong tab **Sign-in method**, nhấn vào dòng **Email/Password**.
4. Bật công tắc đầu tiên **Email/Password (Enable)** sang màu xanh và nhấn **Save**.

### 2. Bật tính năng gửi Email Link (Cho cơ chế gửi Email 2FA thực tế)
Để cho phép ứng dụng gửi email thật chứa liên kết xác thực 2 lớp qua hệ thống của Firebase:
1. Cũng tại cài đặt **Email/Password** trên, bật tiếp công tắc thứ hai: **Email link (passwordless sign-in)**.
2. Nhấn **Save** để lưu lại.
*(Lưu ý: Nếu không bật tùy chọn này, hệ thống sẽ tự động bắt lỗi và kích hoạt cơ chế dự phòng in mã OTP 6 số ra cửa sổ Debug Console/Terminal của Flutter).*

### 3. Cấu hình Email Templates (Tùy chỉnh tiêu đề và nội dung gửi đi)
1. Chuyển sang tab **Templates** trong mục Authentication.
2. Tại đây bạn có thể cấu hình nội dung cho:
   - **Email address verification**: Email gửi link xác minh tài khoản đăng ký mới.
   - **Password reset**: Email gửi link đổi mật khẩu khi chọn quên mật khẩu.
   - **Email link sign-in**: Email gửi liên kết đăng nhập (2FA).
3. Nhấn vào từng mục, sửa ngôn ngữ hiển thị (chuyển sang tiếng Việt) hoặc sửa tiêu đề theo ý muốn và nhấn **Save**.

---

## BƯỚC 3: ĐĂNG KÝ ỨNG DỤNG ANDROID TRONG FIREBASE

Để ứng dụng Flutter chạy trên Android có thể kết nối với dự án Firebase vừa tạo, bạn cần khai báo thông tin ứng dụng:

1. Tại trang **Project Overview** (Tổng quan dự án), nhấn vào biểu tượng **Android (🤖)** để thêm ứng dụng Android.
2. Nhập thông tin đăng ký ứng dụng:
   - **Android package name**: Bắt buộc phải khớp chính xác với `applicationId` cấu hình trong Flutter của bạn.
     - Tên gói mặc định của dự án này là: **`com.movieapp.flutter_app`**
   - **App nickname**: Nhập tên gợi nhớ (ví dụ: `Movie App Android`).
   - **Debug signing certificate SHA-1** (Không bắt buộc): Để trống.
3. Nhấn **Register app**.
4. Ở bước tiếp theo, nhấn nút **Download google-services.json** để tải tệp cấu hình Firebase về máy tính.
5. Di chuyển tệp `google-services.json` vừa tải xuống vào đúng thư mục sau trong dự án:
   - **`[Thư_mục_gốc_dự_án]/flutter_app/android/app/google-services.json`**
6. Nhấn **Next** -> **Next** -> **Go to console** trên trình duyệt để hoàn tất.

---

## BƯỚC 4: TÍCH HỢP FIREBASE SDK VÀO DỰ ÁN FLUTTER

Các tệp cấu hình Gradle của ứng dụng Android đã được thiết lập sẵn trong mã nguồn. Tuy nhiên, nếu bạn cài đặt mới, hãy kiểm tra và cấu hình đúng 2 tệp Gradle sau:

### 1. Tệp Gradle cấp dự án
Đường dẫn: [settings.gradle.kts](file:///d:/Workspace/su26-prm393/booking-movie-ticket/flutter_app/android/settings.gradle.kts)
Đảm bảo dòng khai báo plugin của Google Services tồn tại trong khối `plugins`:
```kotlin
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
    id("com.google.gms.google-services") version "4.4.1" apply false // Đảm bảo dòng này có mặt
}
```

### 2. Tệp Gradle cấp Module ứng dụng
Đường dẫn: [build.gradle.kts](file:///d:/Workspace/su26-prm393/booking-movie-ticket/flutter_app/android/app/build.gradle.kts)
Đảm bảo áp dụng plugin Google Services ở phần đầu file:
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // Đảm bảo dòng này có mặt để kích hoạt google-services.json
}
```

---

## BƯỚC 5: CẤU HÌNH VÀ CHẠY ỨNG DỤNG FLUTTER

### 1. Cài đặt các thư viện (Dependencies)
Mở cửa sổ Terminal/CMD tại thư mục [flutter_app](file:///d:/Workspace/su26-prm393/booking-movie-ticket/flutter_app) và chạy lệnh:
```bash
flutter pub get
```

### 2. Khởi tạo Firebase tại mã nguồn khởi động
Mở tệp tin [main.dart](file:///d:/Workspace/su26-prm393/booking-movie-ticket/flutter_app/lib/main.dart). Phương thức `main()` đã được cấu hình để gọi `Firebase.initializeApp()` để kết nối với Firebase trước khi chạy app:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        throw TimeoutException("Firebase initialization timed out");
      },
    );
  } catch (e) {
    debugPrint("Lỗi khởi tạo Firebase: $e");
  }
  runApp(const MovieApp(...));
}
```

### 3. Biên dịch và Chạy trên Thiết bị/Máy ảo
1. Kết nối điện thoại Android thật (đã bật USB Debugging) hoặc khởi động máy ảo Android (Emulator).
2. Chạy lệnh để biên dịch và khởi động ứng dụng trên thiết bị:
```bash
flutter run
```

---

## CÁC TÍNH NĂNG BẢO MẬT NỔI BẬT

### 1. Đăng ký & Xác minh Email
- Khi người dùng đăng ký mới bằng Email, Firebase Auth sẽ tạo tài khoản và tự động gửi một email chứa đường dẫn kích hoạt.
- App chuyển đến màn hình [verify_email_screen.dart](file:///d:/Workspace/su26-prm393/booking-movie-ticket/flutter_app/lib/screens/auth/verify_email_screen.dart). Người dùng cần mở hộp thư cá nhân, click vào liên kết xác minh từ Firebase, sau đó quay lại app nhấn **Tôi Đã Xác Minh Qua Link** để chính thức kích hoạt tài khoản.

### 2. Quên & Đặt lại Mật khẩu
- Người dùng chọn "Quên mật khẩu", nhập Email. App sẽ gửi yêu cầu reset mật khẩu thông qua Firebase.
- Người dùng nhận email chứa liên kết đặt lại mật khẩu của Firebase, nhấp vào liên kết để nhập mật khẩu mới trên giao diện web an toàn của Firebase mà không cần viết code xử lý riêng trên app.

### 3. Xác thực Bảo mật 2 lớp (2FA) kết hợp kép (Link + OTP)
Nếu người dùng bật **Xác thực 2 bước (2FA)** trong tab "Bảo mật" -> "Trung Tâm Bảo Mật":
- **Luồng Email Link (Môi trường sản xuất)**: Sau khi nhập đúng Email & Mật khẩu, Firebase Auth sẽ tự động gửi email chứa liên kết đăng nhập. Người dùng chỉ cần mở email, sao chép liên kết (bắt đầu bằng `https://...`) và dán vào ô nhập liệu trên app, nhấn **Xác Minh & Đăng Nhập** để hoàn tất đăng nhập.
- **Luồng OTP 6 số (Môi trường Demo / Không cấu hình)**: Nếu bạn chưa bật *Email Link* trên Firebase Console, app sẽ phát hiện lỗi và tự động sinh mã OTP 6 số. Hãy xem mã này tại cửa sổ **Debug Console/Terminal** chạy Flutter của bạn:
  ```text
  ==================================================
  [2FA OTP] MÃ XÁC THỰC 2 LỚP CỦA BẠN LÀ: 123456
  ==================================================
  ```
  Nhập mã `123456` này vào ô nhập mã trên app và nhấn xác nhận để hoàn tất đăng nhập.
- **Bảo vệ phiên hoạt động**: Nếu người dùng tắt app hoặc cố ý bỏ qua bước xác thực 2FA, tệp tin `main.dart` khi khởi động lại sẽ phát hiện phiên làm việc chưa xác thực 2FA và tự động hủy đăng nhập (logout), đưa người dùng trở lại màn hình đăng nhập.

---

## LỖI THƯỜNG GẶP & GIẢI PHÁP

### 1. Lỗi: "This operation is not allowed. This may be because the given sign-in provider is disabled..."
- **Nguyên nhân**: Bạn chưa kích hoạt tùy chọn phụ **Email link (passwordless sign-in)** trong cấu hình nhà cung cấp *Email/Password* trên Firebase Console.
- **Giải pháp**: 
  - Truy cập Firebase Console -> Authentication -> Sign-in method -> Nhấn sửa Email/Password -> Bật công tắc **Email link (passwordless sign-in)** và nhấn **Save**.
  - Hoặc đơn giản là sử dụng mã OTP 6 số in tại Debug Console/Terminal của bạn để vượt qua bước này khi chạy thử nghiệm (đã được lập trình sẵn cơ chế tự động bắt lỗi và fallback).

### 2. Lỗi: "google-services.json not found"
- **Nguyên nhân**: Chưa tải hoặc đặt sai vị trí tệp tin cấu hình.
- **Giải pháp**: Tải tệp `google-services.json` từ phần cài đặt dự án Android của Firebase Console và đặt vào đúng thư mục: `flutter_app/android/app/google-services.json`.

### 3. Lỗi: Phiên đăng nhập không lưu hoặc 2FA đòi mã liên tục khi hot-restart
- Giải pháp: Đây là hành vi bảo mật được lập trình sẵn. Mỗi khi ứng dụng bị tắt hoàn toàn hoặc hot-restart, nếu tài khoản có kích hoạt 2FA, người dùng bắt buộc phải xác nhận lại mã bảo mật để bảo vệ thông tin đặt vé và thông tin cá nhân.

---

## CHI TIẾT CƠ CHẾ HOẠT ĐỘNG CỦA CÁC LUỒNG XÁC THỰC BẢO MẬT

Dưới đây là chi tiết mã nguồn và sơ đồ logic xử lý của 3 luồng chức năng cốt lõi trên ứng dụng di động:

### 1. Luồng Đăng ký & Xác minh Email (Register & Email Verification)
Khi người dùng tạo tài khoản mới:
1. Giao diện [RegisterScreen](file:///d:/Workspace/su26-prm393/booking-movie-ticket/flutter_app/lib/screens/auth/register_screen.dart) gọi phương thức [AuthService.register](file:///d:/Workspace/su26-prm393/booking-movie-ticket/flutter_app/lib/services/auth_service.dart#L10) để yêu cầu đăng ký bằng email và mật khẩu qua Firebase.
2. Firebase Authentication tạo tài khoản và trả về đối tượng `User`. 
3. Ngay sau khi tạo thành công, hệ thống tự động kích hoạt [AuthService.sendEmailVerification](file:///d:/Workspace/su26-prm393/booking-movie-ticket/flutter_app/lib/services/auth_service.dart#L65) để gửi email chứa đường dẫn xác minh (Email Verification Link) của Firebase đến email người dùng.
4. Giao diện điều hướng người dùng tới màn hình [VerifyEmailScreen](file:///d:/Workspace/su26-prm393/booking-movie-ticket/flutter_app/lib/screens/auth/verify_email_screen.dart) ở chế độ xác minh email (`isTwoFactor = false`).
5. Người dùng truy cập hộp thư cá nhân, bấm vào liên kết xác minh từ Firebase. Sau đó quay lại ứng dụng và bấm nút **Tôi Đã Xác Minh Qua Link**.
6. Ứng dụng gọi [AuthService.checkEmailVerified](file:///d:/Workspace/su26-prm393/booking-movie-ticket/flutter_app/lib/services/auth_service.dart#L80), thực thi nạp lại thông tin bằng `user.reload()` để lấy trạng thái mới nhất từ Firebase. Nếu thuộc tính `emailVerified` của Firebase trả về `true`, người dùng sẽ được chuyển tới màn hình chính (Dashboard).

---

### 2. Luồng Đăng nhập & Kiểm tra Trạng thái 2FA (Login & 2FA Dispatch)
Khi người dùng đăng nhập vào ứng dụng:
1. Giao diện [LoginScreen](file:///d:/Workspace/su26-prm393/booking-movie-ticket/flutter_app/lib/screens/auth/login_screen.dart) thu thập email và mật khẩu, thực thi [AuthService.login](file:///d:/Workspace/su26-prm393/booking-movie-ticket/flutter_app/lib/services/auth_service.dart#L37).
2. Sau khi xác thực thông tin tài khoản thành công với Firebase, ứng dụng tiến hành ghi nhận lịch sử và kiểm tra thiết bị qua [SecurityService.recordLoginLog](file:///d:/Workspace/su26-prm393/booking-movie-ticket/flutter_app/lib/services/security_service.dart#L80) (để phát hiện các thiết bị lạ đăng nhập bất thường).
3. Ứng dụng kiểm tra cấu hình 2FA của tài khoản bằng cách gọi [SecurityService.getDashboard](file:///d:/Workspace/su26-prm393/booking-movie-ticket/flutter_app/lib/services/security_service.dart#L116) để lấy trường dữ liệu `twoFactorEnabled`.
4. **Trường hợp 2FA đang Tắt (Disabled):**
   - Phiên làm việc được đánh dấu là hợp lệ ngay lập tức bằng lệnh [SecurityService.setTwoFactorVerified(true)](file:///d:/Workspace/su26-prm393/booking-movie-ticket/flutter_app/lib/services/security_service.dart#L269).
   - Điều hướng trực tiếp người dùng vào màn hình chính của ứng dụng.
5. **Trường hợp 2FA đang Bật (Enabled):**
   - Đánh dấu phiên hiện tại chưa xác thực 2FA bằng lệnh [SecurityService.setTwoFactorVerified(false)](file:///d:/Workspace/su26-prm393/booking-movie-ticket/flutter_app/lib/services/security_service.dart#L269).
   - Sinh mã xác minh OTP 6 chữ số ngẫu nhiên qua [SecurityService.generate2FAOTP](file:///d:/Workspace/su26-prm393/booking-movie-ticket/flutter_app/lib/services/security_service.dart#L277) và in ra cửa sổ **Debug Console** để phục vụ việc kiểm thử nhanh trong quá trình phát triển (mã tự động hết hạn sau 5 phút).
   - Cố gắng gửi một liên kết đăng nhập chứa mã OTP đó qua Firebase bằng [AuthService.send2FASignInLink](file:///d:/Workspace/su26-prm393/booking-movie-ticket/flutter_app/lib/services/auth_service.dart#L106).
   - Điều hướng người dùng tới màn hình [VerifyEmailScreen](file:///d:/Workspace/su26-prm393/booking-movie-ticket/flutter_app/lib/screens/auth/verify_email_screen.dart) ở chế độ xác thực 2 lớp (`isTwoFactor = true`).

---

### 3. Luồng Xác thực 2FA & Bảo vệ Phiên làm việc (2FA & Session Protection)
Màn hình xác thực 2 lớp [VerifyEmailScreen](file:///d:/Workspace/su26-prm393/booking-movie-ticket/flutter_app/lib/screens/auth/verify_email_screen.dart) chấp nhận hai phương thức nhập liệu của người dùng:
1. **Phương thức 1: Nhập mã OTP 6 số**
   - Người dùng nhập mã OTP được in ở Debug Console hoặc nhận từ email.
   - Khi bấm **Xác Minh & Đăng Nhập**, ứng dụng gọi [SecurityService.verifyOTP](file:///d:/Workspace/su26-prm393/booking-movie-ticket/flutter_app/lib/services/security_service.dart#L286) để so khớp mã và kiểm tra hạn sử dụng.
2. **Phương thức 2: Dán liên kết đăng nhập (Firebase Sign-in Link)**
   - Người dùng sao chép liên kết dạng `https://...` từ email của Firebase và dán vào ô nhập liệu.
   - Ứng dụng kiểm tra và gọi [AuthService.verify2FALink](file:///d:/Workspace/su26-prm393/booking-movie-ticket/flutter_app/lib/services/auth_service.dart#L128) để Firebase tự xác thực liên kết đó.
3. Khi một trong hai phương thức xác thực thành công:
   - Ghi nhận trạng thái xác thực phiên làm việc bằng lệnh [SecurityService.setTwoFactorVerified(true)](file:///d:/Workspace/su26-prm393/booking-movie-ticket/flutter_app/lib/services/security_service.dart#L269).
   - Cho phép người dùng chuyển vào màn hình chính.
4. **Bảo vệ phiên làm việc khi khởi động lại ứng dụng:**
   - Khi người dùng tắt hẳn ứng dụng và mở lại (hoặc chạy lại ứng dụng), hàm khởi động `main()` trong [main.dart](file:///d:/Workspace/su26-prm393/booking-movie-ticket/flutter_app/lib/main.dart#L9) sẽ kiểm tra trạng thái tự động đăng nhập (Auto-login check).
   - Nếu phát hiện có phiên đăng nhập của Firebase (`authService.isLoggedIn() == true`) nhưng tài khoản có bật 2FA (`twoFactorEnabled == true`) và phiên hiện tại chưa được xác thực (`twoFactorVerified == false`), hệ thống sẽ lập tức gọi [AuthService.logout](file:///d:/Workspace/su26-prm393/booking-movie-ticket/flutter_app/lib/services/auth_service.dart#L95) để hủy bỏ phiên đăng nhập và buộc người dùng đăng nhập lại từ đầu. Điều này ngăn chặn việc vượt qua màn hình xác thực 2 lớp bằng cách tắt/mở lại app.
### 4. Hướng dẫn chi tiết từ Firebase: https://firebase.google.com/docs/auth/flutter/start
