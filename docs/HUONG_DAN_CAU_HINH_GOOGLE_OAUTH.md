# Hướng dẫn cấu hình Google OAuth 2.0 cho dự án Movie Ticket Booking

Tài liệu này hướng dẫn chi tiết các bước tạo và cấu hình **OAuth 2.0 Client IDs** trên Google Cloud Console để tích hợp tính năng đăng nhập Google (Google Sign-In) trên ứng dụng Flutter và Backend Node.js.

---

## Thông tin ứng dụng của bạn (Đã lấy tự động)
* **Package Name (Android):** `com.movieapp.flutter_app`
* **SHA-1 Fingerprint (Debug):** `28:7A:DF:3E:13:4D:40:9F:27:6D:6A:AC:CF:5D:60:75:82:44:4B:B3`

---

## BƯỚC 1: Truy cập Google Cloud Console
1. Mở trình duyệt và truy cập: [Google Cloud Console](https://console.cloud.google.com/)
2. Đăng nhập bằng tài khoản Google của bạn.

---

## BƯỚC 2: Tạo một Project mới (Nếu chưa có)
1. Ở thanh menu trên cùng, bấm vào danh sách dự án (bên cạnh logo "Google Cloud").
2. Bấm **New Project** (Dự án mới).
3. Nhập tên dự án: `Movie Ticket Booking` (hoặc tên tùy chọn).
4. Bấm **Create** (Tạo) và đợi khoảng 10 giây, sau đó chọn dự án vừa tạo từ thanh menu.

---

## BƯỚC 3: Cấu hình OAuth Consent Screen (Màn hình đồng ý)
Trước khi tạo Client ID, Google yêu cầu thiết lập màn hình hiển thị khi người dùng bấm đăng nhập.

1. Vào menu bên trái (nhấp vào icon 3 dấu gạch ngang) → **APIs & Services** (API & Dịch vụ) → **OAuth consent screen** (Màn hình đồng ý OAuth).
2. Chọn **User Type**:
   * Chọn **External** (Ngoại bộ - để bất kỳ ai có tài khoản Gmail cũng đăng nhập được).
   * Bấm **Create** (Tạo).
3. Nhập thông tin bắt buộc:
   * **App name:** `Movie Ticket Booking`
   * **User support email:** Chọn email của bạn.
   * **Developer contact information:** Nhập email của bạn.
   * Bấm **Save and Continue** (Lưu và tiếp tục).
4. Ở bước **Scopes** (Phạm vi):
   * **Trường hợp 1:** Nếu bạn đã thấy 3 quyền cơ bản (`.../auth/userinfo.email`, `.../auth/userinfo.profile`, `openid`) hiển thị sẵn trong bảng **"Your non-sensitive scopes"** (Phạm vi không nhạy cảm), bạn không cần bấm nút nào cả. Hãy cuộn xuống cuối trang và bấm **Save and Continue** (Lưu và tiếp tục).
   * **Trường hợp 2:** Nếu chưa có, bấm nút **Add or Remove Scopes** (Thêm hoặc xóa phạm vi). Một bảng menu phụ sẽ trượt ra từ bên phải màn hình:
     * Nhập `email` hoặc `profile` vào ô lọc/tìm kiếm ở đầu bảng menu phụ để tìm nhanh các quyền này.
     * Tích chọn ô vuông bên cạnh 3 quyền cơ bản: `.../auth/userinfo.email`, `.../auth/userinfo.profile`, và `openid`.
     * **Nút Update ở đâu?** Bạn hãy cuộn thanh cuộn của bảng menu phụ trượt ở bên phải (chứ không phải trang chính) xuống dưới cùng, bạn sẽ thấy nút **Update** (hoặc **Cập nhật**) màu xanh lam ở góc dưới bên trái của bảng menu phụ đó.
     * Sau khi bấm **Update**, bảng menu phụ sẽ đóng lại. Hãy cuộn trang chính xuống dưới cùng và bấm **Save and Continue** (Lưu và tiếp tục).
5. Ở bước **Test users**:
   * Thêm các email của bạn hoặc của thành viên trong nhóm để phục vụ chạy test khi ứng dụng ở chế độ Testing.
   * Bấm **Save and Continue**.
6. Bấm **Back to Dashboard**.

---

## BƯỚC 4: Tạo Credentials (Thông tin xác thực)

Chúng ta cần tạo **2 Client IDs**: 
1. **Web Application Client ID** (Cho Backend nhận dạng và verify token).
2. **Android Client ID** (Cho app Flutter chạy trên thiết bị Android).

### 1. Tạo Web Client ID (Quan trọng nhất)
1. Ở menu bên trái, chọn **Credentials** (Thông tin xác thực).
2. Bấm **+ Create Credentials** ở trên cùng → Chọn **OAuth client ID**.
3. Chọn **Application type**: **Web application** (Ứng dụng Web).
4. **Name:** `Web Client (Backend & Flutter Config)`
5. Bấm **Create** (Tạo).
6. Một cửa sổ hiện lên, hãy copy **Client ID** (Dạng `xxxxxx-xxxxxx.apps.googleusercontent.com`).
   > [!IMPORTANT]
   > Hãy lưu lại chuỗi này. Bạn sẽ cần paste nó vào file `.env` của backend ở biến `GOOGLE_CLIENT_ID` và cấu hình trong code Flutter.

### 2. Tạo Android Client ID (Cho App Mobile)
1. Vẫn tại trang **Credentials**, tiếp tục bấm **+ Create Credentials** → **OAuth client ID**.
2. Chọn **Application type**: **Android**.
3. **Name:** `Android Client (Flutter)`
4. Nhập chính xác thông tin:
   * **Package name:** `com.movieapp.flutter_app`
   * **SHA-1 certificate fingerprint:** `28:7A:DF:3E:13:4D:40:9F:27:6D:6A:AC:CF:5D:60:75:82:44:4B:B3`
5. Bấm **Create** (Tạo).
   > [!NOTE]
   > Client ID của Android này sẽ được sử dụng trực tiếp bởi package `google_sign_in` trên điện thoại Android của bạn để xác thực chữ ký của ứng dụng.

---

## BƯỚC 5: Cấu hình biến môi trường trên Backend

Mở file `.env` của thư mục `backend/` và cập nhật các dòng sau:

```env
GOOGLE_CLIENT_ID="[PASTE_WEB_CLIENT_ID_TAI_DAY]"
GOOGLE_ANDROID_CLIENT_ID="[PASTE_ANDROID_CLIENT_ID_TAI_DAY]"
```

*Ví dụ:*
```env
GOOGLE_CLIENT_ID="1234567890-abc123def456.apps.googleusercontent.com"
GOOGLE_ANDROID_CLIENT_ID="1234567890-xyz987uvw654.apps.googleusercontent.com"
```

Sau khi sửa xong file `.env`, hãy **khởi động lại Backend** để cập nhật biến môi trường:
```bash
npm run dev
```

---

## BƯỚC 6: Cấu hình trong Flutter App

Mở file [google_auth_service.dart](file:///d:/K8/Booking%20Movie%20Ticket/flutter_app/lib/services/google_auth_service.dart) và kiểm tra lại:

```dart
final GoogleSignIn _googleSignIn = GoogleSignIn(
  clientId: 'PASTE_WEB_CLIENT_ID_VAO_DAY', // Web Client ID dùng cho cả Android để lấy idToken
  scopes: ['email', 'profile'],
);
```

> [!TIP]
> Việc cấu hình `clientId` bằng **Web Client ID** trong code Flutter của Android/iOS là bắt buộc để Google trả về trường `idToken` (mã thông báo định danh dùng gửi lên Backend kiểm tra).

---

## BƯỚC 7: Chạy và kiểm tra kết quả

1. Mở Emulator hoặc cắm điện thoại Android của bạn (đảm bảo điện thoại đã cài đặt Google Play Services và có kết nối mạng).
2. Khởi chạy app Flutter:
   ```bash
   flutter run
   ```
3. Trên màn hình Đăng nhập (Login screen), bấm vào nút **"Tiếp tục với Google"**.
4. Chọn tài khoản Google của bạn. Hệ thống sẽ tiến hành đăng nhập, lấy ID Token, gửi cho Backend verify, và chuyển hướng bạn vào màn hình Home thành công!
