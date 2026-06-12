# Hướng Dẫn Bảo Mật Tài Khoản

## Hệ Thống Booking Movie Ticket

---

## Mục Lục

1. [Hướng Dẫn Cài Đặt](#0-hướng-dẫn-cài-đặt)
2. [Bảo Mật Tài Khoản](#1-bảo-mật-tài-khoản)
3. [Bảo Mật qua Email](#2-bảo-mật-qua-email)
4. [Bảo Mật bằng Mã OTP](#3-bảo-mật-bằng-mã-otp)
5. [Demo](#4-demo)

---

# 0. Hướng Dẫn Cài Đặt

Hướng dẫn này dành cho người cần **tự tay cài đặt dự án từ đầu** trên một máy tính mới hoặc máy chưa từng cài đặt dự án này. Nếu dự án đã được cài sẵn, bạn có thể bỏ qua phần này và chuyển sang phần **1. Bảo Mật Tài Khoản**.

---

## 0.1. Trước khi bắt đầu — Hiểu hệ thống

Phần này hướng dẫn bạn cài đặt và chạy hệ thống Booking Movie Ticket từ đầu trên **máy tính mới**, dành cho người chưa từng làm việc với dự án này. Bạn sẽ cài đặt **3 phần chính**:

| Phần | Vai trò | Cổng kết nối |
|------|---------|--------------|
| **Docker MySQL** | Lưu trữ dữ liệu (tài khoản, phim, vé...) | 3308 |
| **Backend (Node.js)** | Xử lý logic, xác thực, gửi email thật, cấp token đăng nhập | 5000 |
| **Flutter App** | Ứng dụng trên điện thoại Android để bạn sử dụng | Kết nối đến Backend |

**Thứ tự khởi động bắt buộc:**
Docker MySQL (chạy trước) → Backend → Flutter App

---

## 0.2. Công cụ cần cài đặt

### 2.1. Node.js (dùng cho Backend)

Node.js là phần mềm chạy phần "sau" của hệ thống — nơi xử lý đăng nhập, lưu dữ liệu, gửi email.

**Cách cài đặt:**

1. Truy cập trang: [https://nodejs.org](https://nodejs.org)
2. Tải bản **LTS** (bản ổn định, khuyến nghị) — hiện tại là **Node.js 20.x** hoặc cao hơn.
3. Nhấn đúp vào file đã tải để cài đặt. Cứ nhấn **Next** và **Install** cho đến khi xong.
4. Sau khi cài xong, mở **CMD** (nhấn `Win + R`, gõ `cmd`, nhấn Enter) và gõ:

```
node --version
```

Nếu hiển thị số phiên bản (ví dụ: `v20.x.x`) là cài thành công.

---

### 2.2. Docker Desktop (dùng cho MySQL)

Docker giúp bạn chạy MySQL (cơ sở dữ liệu) mà không cần cài MySQL trực tiếp lên máy. Nó giống như một "hộp chứa" độc lập không ảnh hưởng đến máy tính của bạn.

**Cách cài đặt:**

1. Truy cập: [https://www.docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop)
2. Tải **Docker Desktop** cho Windows.
3. Cài đặt — có thể cần khởi động lại máy.
4. Sau khi cài, mở **Docker Desktop** từ Start Menu. Chờ cho đến khi biểu tượng Docker ở góc dưới (taskbar) hiển thị **màu xanh** là được.

**Kiểm tra:** Mở CMD và gõ:

```
docker --version
```

Nếu hiển thị phiên bản là cài thành công.

---

### 2.3. Flutter SDK (dùng cho Ứng dụng di động)

Flutter là công cụ để tạo ứng dụng trên điện thoại Android. Chúng ta cần cài Flutter để chạy ứng dụng Booking Movie Ticket.

**Cách cài đặt chi tiết:**

**Bước 1:** Tải Flutter SDK

1. Truy cập: [https://docs.flutter.dev/get-started/install/windows](https://docs.flutter.dev/get-started/install/windows)
2. Tải file zip Flutter SDK (ví dụ: `flutter_windows_3.24_x64.zip`).

**Bước 2:** Giải nén

1. Tạo thư mục `C:\flutter` trên ổ C (hoặc bất kỳ đâu bạn thích).
2. Giải nén file zip đã tải vào thư mục đó. Sau khi giải nén, bạn sẽ có thư mục `C:\flutter\flutter` chứa các thư mục `bin`, `packages`, v.v.

**Bước 3:** Thiết lập biến môi trường PATH

Đây là bước quan trọng để máy tính nhận ra lệnh `flutter`.

1. Nhấn `Win + R`, gõ `sysdm.cpl`, nhấn Enter.
2. Tab **Advanced** → nút **Environment Variables**.
3. Trong ô **System variables**, tìm dòng **Path** và nhấn **Edit**.
4. Nhấn **New** và thêm đường dẫn: `C:\flutter\flutter\bin`
5. Nhấn **OK** → **OK** → **OK**.

**Bước 4:** Kiểm tra

Mở CMD mới (đóng CMD cũ nếu đang mở) và gõ:

```
flutter --version
```

Nếu hiển thị phiên bản Flutter là cài thành công.

**Bước 5:** Xác nhận Flutter hoạt động đầy đủ

Gõ lệnh sau trong CMD:

```
flutter doctor
```

Lệnh này sẽ kiểm tra tất cả các thành phần cần thiết. Nếu thấy dòng "Android toolchain" là ✅ (có màu xanh), nghĩa là đã sẵn sàng để chạy ứng dụng trên Android.

**Bước 6:** Bật Developer Mode trên Windows

Đây là bước **bắt buộc** nếu bạn chạy Flutter trên Windows.

1. Mở **Settings** (Cài đặt) của Windows.
2. Tìm **Developer settings** (Cài đặt nhà phát triển).
3. Bật **Developer Mode** lên.

---

## 0.3. Các bước cài đặt hệ thống (thực hiện một lần)

Sau khi đã cài đặt các công cụ ở trên, bạn thực hiện các bước sau **lần đầu tiên** để thiết lập hệ thống.

---

### Bước 1: Tạo file cấu hình (.env)

File `.env` chứa thông tin kết nối giữa các phần của hệ thống. Bạn chỉ cần làm bước này **một lần duy nhất**.

**1a. Mở thư mục dự án**

Mở thư mục chứa project: `e:\PRM393\booking-movie-ticket`

**1b. Tạo file `.env` tại thư mục gốc**

Trong thư mục `e:\PRM393\booking-movie-ticket`, tạo file mới tên là `.env`

Mở file `.env` vừa tạo bằng Notepad và dán nội dung sau:

```
PORT=5000
NODE_ENV=development
DATABASE_URL="mysql://root:root_password@localhost:3308/account_security_db"
JWT_ACCESS_SECRET=my_super_secret_access_key_123456
JWT_REFRESH_SECRET=my_super_secret_refresh_key_789012
JWT_ACCESS_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d
MAX_FAILED_ATTEMPTS=5
LOCKOUT_DURATION_MINUTES=5
EMAIL_CODE_EXPIRY_MINUTES=10
OTP_EXPIRY_MINUTES=5
RESEND_COOLDOWN_SECONDS=60
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email@gmail.com
SMTP_PASS=your_gmail_app_password
SMTP_FROM="Movie App <your_email@gmail.com>"
```

Lưu file lại.

> **Giải thích nhanh các dòng quan trọng:**
> - `PORT=5000` — Backend chạy trên cổng 5000.
> - `DATABASE_URL` — Địa chỉ kết nối đến MySQL đang chạy trên cổng 3308.
> - `JWT_ACCESS_SECRET` và `JWT_REFRESH_SECRET` — Các chuỗi bí mật để tạo token đăng nhập. Bạn có thể đổi thành chuỗi ngẫu nhiên khác, miễn là đủ dài (ít nhất 10 ký tự).
> - `SMTP_USER`, `SMTP_PASS` — Thông tin tài khoản email để hệ thống gửi mã xác minh và OTP. Xem mục **"Cấu hình email"** bên dưới để biết cách lấy các giá trị này.

**1c. Tạo file `.env` tại thư mục backend**

Sao chép file `.env` vừa tạo vào thư mục `backend` bên trong dự án. Nghĩa là bạn sẽ có file `.env` ở **hai nơi**:

- `e:\PRM393\booking-movie-ticket\.env` (thư mục gốc)
- `e:\PRM393\booking-movie-ticket\backend\.env` (thư mục backend)

Cả hai file nên có **cùng nội dung**.

---

### Bước 2: Cấu hình email để gửi mã xác minh (quan trọng)

Đây là bước quan trọng. Hệ thống sẽ gửi **email thật** chứa mã xác minh và mã OTP đến hộp thư của bạn. Để làm được điều này, bạn cần cấu hình một tài khoản email Gmail làm "người gửi".

**Cách lấy SMTP Password (App Password) từ Gmail:**

**Bước 1:** Đăng nhập tài khoản Google bạn muốn dùng làm người gửi (ví dụ: `your_email@gmail.com`).

**Bước 2:** Truy cập [https://myaccount.google.com/security](https://myaccount.google.com/security)

**Bước 3:** Tìm mục **"Xác minh 2 bước"** (2-Step Verification) và bật nó lên. Đây là bước bắt buộc trước khi tạo App Password.

**Bước 4:** Quay lại trang Security, tìm mục **"App passwords"** (Mật khẩu ứng dụng).

**Bước 5:** Chọn ứng dụng là **"Mail"** và thiết bị là **"Khác (Tên tùy chỉnh)"**. Đặt tên, ví dụ: `Movie App`.

**Bước 6:** Nhấn **Tạo**. Google sẽ hiển thị một chuỗi 16 ký tự gọi là **App Password** — đây là mật khẩu bạn dùng cho `SMTP_PASS` trong file `.env`.

**Bước 7:** Mở file `.env` và cập nhật các dòng:

```
SMTP_USER=your_email@gmail.com      ← Thay bằng email của bạn
SMTP_PASS=abcd efgh ijkl mnop      ← Thay bằng App Password Google vừa tạo
SMTP_FROM="Movie App <your_email@gmail.com>"  ← Thay bằng email của bạn
```

> **Lưu ý:** App Password là chuỗi 16 ký tự. Khi nhập vào `.env`, bạn nhập đúng chuỗi đó (không cần khoảng trắng).

---

### Bước 2: Khởi chạy MySQL (Docker)

MySQL là nơi lưu trữ tất cả dữ liệu: tài khoản, phim, vé, lịch sử đăng nhập.

**2a. Mở Docker Desktop**

Từ **Start Menu**, tìm và mở **Docker Desktop**.

Chờ cho biểu tượng Docker ở góc dưới màn hình (taskbar) chuyển sang **màu xanh**. Có thể mất 1-2 phút.

**2b. Mở CMD trong thư mục dự án**

Trong File Explorer, đi đến `e:\PRM393\booking-movie-ticket`. Click vào thanh địa chỉ, xóa hết và gõ `cmd`, nhấn Enter. Cửa sổ CMD sẽ mở đúng thư mục dự án.

**2c. Chạy lệnh khởi động MySQL**

```
docker compose up -d
```

**Chờ khoảng 1-2 phút** để Docker tải image MySQL lần đầu.

**2d. Kiểm tra MySQL đã chạy chưa**

```
docker compose ps
```

Nếu thấy cột **STATUS** hiển thị **"Up"**, nghĩa là MySQL đã hoạt động tốt.

> **Nếu thấy "Starting" hoặc "Unhealthy":** Đợi thêm 1-2 phút rồi gõ lại `docker compose ps`.

---

### Bước 3: Cài đặt và chạy Backend

Backend là "bộ não" xử lý mọi thứ: đăng nhập, tạo tài khoản, gửi mã OTP qua email, quản lý phim và vé.

**3a. Mở CMD trong thư mục backend**

Trong File Explorer, đi đến thư mục `backend` bên trong dự án. Mở CMD tại đây.

**3b. Cài đặt thư viện cần thiết**

```
npm install
```

Chờ khoảng 2-5 phút (lần đầu tiên sẽ tải nhiều thư viện). Nếu thấy dòng `added XXX packages in XmXs` là cài thành công.

**3c. Tạo bảng dữ liệu trong MySQL**

```
npx prisma migrate dev --name init
```

Lệnh này tạo các bảng trong MySQL: bảng users, verification_codes, login_history, security_alerts, movies, bookings, v.v. Nếu thấy thông báo thành công là được.

**3d. Nạp dữ liệu mẫu**

```
npm run seed
```

Lệnh này tạo sẵn dữ liệu để bạn dùng thử:

- **1 tài khoản Admin:** `admin@movieapp.com` / `Admin@123`
- **6 phim mẫu:** Avengers: Doomsday, Inside Out 3, The Batman 2, Spirited Away 2, Fast & Furious 11, Doraemon
- **3 rạp chiếu phim:** CGV Vincom Center, Lotte Cinema Nowzone, Galaxy Cinema Nguyễn Du
- **9 phòng chiếu:** 3 phòng mỗi rạp
- **3 chương trình khuyến mãi:** WELCOME10, STUDENT20, WEEKEND15

**3e. Khởi chạy Backend Server**

```
npm run dev
```

Nếu thấy dòng kiểu như:

```
🎬 Movie Ticket Booking App with Account Security
🚀 Server running on http://localhost:5000
📖 Environment: development
🔗 Health: http://localhost:5000/api/health
=======================================================
```

Backend đã chạy thành công. **Để cửa sổ CMD này mở** — đừng tắt nó.

---

### Bước 4: Chạy Ứng dụng Flutter

**4a. Mở CMD trong thư mục flutter_app**

Trong File Explorer, đi đến `e:\PRM393\booking-movie-ticket\flutter_app`. Mở CMD tại đây.

**4b. Cài đặt thư viện Flutter**

```
flutter pub get
```

Chờ cho đến khi thấy dòng `Got N dependencies` là thành công.

**4c. Kết nối thiết bị để chạy**

Bạn có **hai lựa chọn**:

**Cách A: Chạy trên điện thoại thật (khuyến nghị cho demo)**

1. Cắm điện thoại Android vào máy tính qua cáp USB.
2. Trên điện thoại, bật **USB Debugging**:
   - Vào **Settings** → **About phone** → nhấn **Build number** 7 lần để bật Developer Options.
   - Vào **Settings** → **Developer Options** → bật **USB Debugging**.
3. Trên màn hình điện thoại, nhấn **Allow** khi hiện thông báo "Allow USB debugging".

**Cách B: Chạy trên máy ảo Android (Android Emulator)**

1. Mở **Android Studio** → **AVD Manager** (Device Manager).
2. Tạo một máy ảo Android (ví dụ: Pixel 6, Android 14).
3. Nhấn nút **Play** để khởi động máy ảo.

**4d. Chạy ứng dụng**

```
flutter run
```

Ứng dụng sẽ tự động cài đặt và mở trên thiết bị đã kết nối.

**Lần đầu chạy** có thể mất 3-10 phút để build. Các lần sau sẽ nhanh hơn.

> **Nếu chạy trên điện thoại thật và gặp lỗi kết nối:** Bạn cần tìm địa chỉ IP của máy tính và cấu hình lại. Xem mục **"Cấu hình kết nối cho điện thoại thật"** bên dưới.

---

## 0.4. Cấu hình kết nối cho điện thoại thật

Khi chạy ứng dụng trên **điện thoại thật** (không phải máy ảo), ứng dụng không thể dùng `localhost` hoặc `10.0.2.2` vì điện thoại không phải là máy tính của bạn. Điện thoại cần kết nối qua **địa chỉ IP** của máy tính trong cùng mạng Wi-Fi.

**Bước 1: Tìm địa chỉ IP của máy tính**

1. Mở CMD và gõ:

```
ipconfig
```

2. Tìm dòng **IPv4 Address** trong phần **Wireless LAN adapter Wi-Fi**.
3. Ghi nhớ số IP đó (ví dụ: `192.168.1.5`).

**Bước 2: Sửa địa chỉ API trong Flutter**

Mở file `flutter_app\lib\config\app_config.dart` bằng Notepad.

Thay đổi dòng:

```
static const String _emulatorUrl = 'http://10.0.2.2:5000/api';
```

thành:

```
static const String _emulatorUrl = 'http://192.168.1.5:5000/api';
```

(thay `192.168.1.5` bằng địa chỉ IP của máy tính bạn vừa tìm được ở Bước 1)

Lưu file lại.

**Bước 3: Khởi động lại Backend**

Tắt cửa sổ CMD đang chạy backend (nhấn `Ctrl + C`), sau đó gõ lại:

```
npm run dev
```

**Bước 4: Chạy lại ứng dụng Flutter**

```
flutter run
```

**Lưu ý quan trọng:**

- Máy tính và điện thoại phải kết nối **cùng một mạng Wi-Fi**.
- Mỗi lần máy tính khởi động lại, địa chỉ IP có thể thay đổi. Nếu ứng dụng không kết nối được, hãy kiểm tra lại IP mới và cập nhật lại ở Bước 2.
- Tham khảo mục **0.7** (xử lý lỗi) nếu gặp vấn đề kết nối.

---

## 0.5. Cách khởi động hệ thống (sau khi đã cài đặt lần đầu)

Sau khi đã hoàn tất các bước cài đặt ở trên, **mỗi lần muốn sử dụng** bạn chỉ cần thực hiện:

### Lần sử dụng thường xuyên

```
Bước 1: Mở Docker Desktop  →  chờ biểu tượng xanh
Bước 2: Kiểm tra MySQL đang chạy:
         docker compose ps
         (Nếu thấy "Up" → OK. Nếu không → chạy "docker compose up -d")
Bước 3: Mở CMD trong thư mục backend → npm run dev
Bước 4: Mở CMD trong thư mục flutter_app → flutter run
```

---

## 0.6. Nhận mã xác minh và OTP

Hệ thống gửi **email thật** đến địa chỉ email bạn đã cấu hình trong `.env` (dòng `SMTP_USER`).

**Bảng phân biệt cách nhận mã:**

| Loại mã | Cách nhận | Ghi chú |
|---------|-----------|---------|
| **Mã xác minh email** | Email thật | Gửi đến hộp thư `SMTP_USER` |
| **Mã OTP (2FA)** | Email thật | Gửi đến hộp thư `SMTP_USER` |
| **Mã xác minh điện thoại** | Cửa sổ CMD đang chạy backend | Mã hiển thị trong cửa sổ CMD |

**Ví dụ email xác minh bạn nhận được:**

```
Tiêu đề: [Movie App] Xác minh email của bạn
Nội dung:
  Xin chào,
  Mã xác minh của bạn là: 847291
  Mã này có hiệu lực trong 10 phút.
  Nếu bạn không yêu cầu, vui lòng bỏ qua email này.
```

---

## 0.7. Xử lý lỗi thường gặp khi cài đặt

### Lỗi: "npm is not recognized"

**Nguyên nhân:** Node.js chưa được cài đặt đúng cách hoặc chưa được thêm vào PATH.

**Cách xử lý:**

1. Gỡ cài đặt Node.js.
2. Tải và cài lại Node.js từ [nodejs.org](https://nodejs.org). Chọn bản **LTS**.
3. Sau khi cài xong, **đóng CMD cũ** và mở CMD mới, gõ `node --version`.

---

### Lỗi: "docker: command not found"

**Nguyên nhân:** Docker chưa được cài hoặc chưa khởi động.

**Cách xử lý:**

1. Mở **Docker Desktop** từ Start Menu.
2. Chờ cho đến khi biểu tượng ở taskbar chuyển sang **màu xanh** (có thể mất 1-3 phút).
3. Nếu Docker không khởi động được, thử khởi động lại máy tính.

---

### Lỗi: MySQL container bị dừng hoặc "Exit (1)"

**Nguyên nhân:** Cổng 3308 trên máy tính đã bị chiếm bởi ứng dụng khác.

**Cách xử lý:**

1. Mở CMD, gõ:

```
netstat -ano | findstr :3308
```

2. Nếu thấy số PID (cột cuối), mở **Task Manager** → tab **Details** → tìm PID đó và **End Task**.
3. Sau đó chạy lại:

```
docker compose up -d
```

---

### Lỗi: "Building with plugins requires symlink support"

**Nguyên nhân:** Windows chưa bật Developer Mode.

**Cách xử lý:**

1. Mở **Settings** → tìm **Developer settings**.
2. Bật **Developer Mode** lên.
3. Thử lại lệnh `flutter pub get`.

---

### Lỗi: Ứng dụng Flutter không kết nối được Backend

**Nguyên nhân phổ biến nhất:** Địa chỉ IP không đúng.

**Cách xử lý:**

1. Kiểm tra điện thoại và máy tính có kết nối **cùng một mạng Wi-Fi** không.
2. Tìm lại địa chỉ IP của máy tính (`ipconfig` trong CMD).
3. Mở file `flutter_app/lib/config/app_config.dart` và cập nhật IP mới.
4. Khởi động lại Backend và chạy lại `flutter run`.

---

### Lỗi: "Prisma migration failed"

**Nguyên nhân:** Database chưa sẵn sàng hoặc cấu hình sai.

**Cách xử lý:**

1. Đảm bảo Docker MySQL đang chạy: `docker compose ps` → thấy "Up".
2. Kiểm tra file `.env` trong thư mục `backend` có đúng nội dung không.
3. Chạy lệnh reset:

```
npx prisma migrate reset
```

4. Sau đó chạy lại:

```
npm run seed
npm run dev
```

---

### Lỗi: Điện thoại không nhận ra thiết bị USB

**Cách xử lý:**

1. Rút cáp USB và cắm lại.
2. Trên điện thoại, nhấn **Revoke USB debugging authorizations** trong Developer Options, sau đó cắm lại và nhấn **Allow**.
3. Thử lệnh `adb devices` trong CMD để kiểm tra. Nếu thấy thiết bị trong danh sách là kết nối thành công.
4. Nếu vẫn không được, thử **khởi động lại cả điện thoại và máy tính**.

---

### Lỗi: Không gửi được email (mã xác minh không đến)

**Nguyên nhân phổ biến:**

- **Chưa bật 2-Step Verification** trên tài khoản Google.
- **App Password** chưa được tạo hoặc nhập sai trong `.env`.
- Email bị lọc vào thư mục Spam.

**Cách xử lý:**

1. Đảm bảo đã bật **2-Step Verification** trên tài khoản Google.
2. Tạo **App Password** mới và cập nhật vào file `.env`.
3. Khởi động lại Backend (`npm run dev`) sau khi sửa `.env`.
4. Kiểm tra thư mục **Spam** trong email.

---

## 0.8. Tài khoản dùng thử

Sau khi chạy `npm run seed`, hệ thống đã có sẵn một tài khoản **Admin**:

| | |
|---|---|
| **Email** | `admin@movieapp.com` |
| **Mật khẩu** | `Admin@123` |

Bạn có thể đăng nhập ngay với tài khoản này để trải nghiệm các tính năng bảo mật mà không cần đăng ký mới.

---

## 0.9. Thông tin kết nối tóm tắt

| Thành phần | Địa chỉ / Cổng | Ghi chú |
|-----------|---------------|---------|
| MySQL (Docker) | `localhost:3308` | Chỉ dùng cho backend |
| Backend API | `http://localhost:5000/api` | Chạy trên máy tính |
| Health Check | `http://localhost:5000/api/health` | Kiểm tra backend |
| Flutter (Emulator) | Kết nối qua `10.0.2.2:5000` | Điện thoại ảo |
| Flutter (Điện thoại thật) | `http://<IP máy>:5000/api` | Cần cùng Wi-Fi |

---

## 0.10. Danh sách kiểm tra trước khi Demo

Trước khi bắt đầu demo tính năng bảo mật, hãy đảm bảo tất cả các mục sau:

- [ ] Docker Desktop đang mở và MySQL đang chạy (biểu tượng xanh ở taskbar).
- [ ] Cửa sổ CMD đang chạy `npm run dev` (backend trên cổng 5000).
- [ ] Ứng dụng Flutter đã được chạy trên thiết bị (điện thoại thật hoặc máy ảo).
- [ ] File `.env` đã được cấu hình đúng với SMTP email (App Password Gmail).
- [ ] Bạn đã thử đăng nhập với tài khoản `admin@movieapp.com` / `Admin@123` để xác nhận mọi thứ hoạt động.

---

# 1. Bảo Mật Tài Khoản

## 1.1. Khái niệm

### Mật khẩu mạnh là gì?

Mật khẩu mạnh giống như một chiếc khóa cửa tốt — nó khiến kẻ xấu khó có thể bẻ khóa để vào nhà bạn hơn. Một mật khẩu yếu như "123456" thì bất kỳ ai cũng có thể đoán ra trong vài giây. Một mật khẩu mạnh giống như một chiếc ổ khóa phức tạp — mất rất nhiều thời gian để phá.

### Mật khẩu trong hệ thống cần đáp ứng những gì?

Hệ thống yêu cầu mật khẩu phải có **ít nhất 8 ký tự** và phải chứa đủ **4 loại ký tự**:

- **Chữ hoa** — ví dụ: `A`, `B`, `C`
- **Chữ thường** — ví dụ: `a`, `b`, `c`
- **Chữ số** — ví dụ: `1`, `2`, `3`
- **Ký tự đặc biệt** — ví dụ: `@`, `#`, `$`, `!`

**Ví dụ thực tế:**
| Mật khẩu | Đủ mạnh? | Vì sao |
|----------|----------|---------|
| `Password@123` | ✅ Có | Đủ 8 ký tự, có chữ hoa, chữ thường, số, ký tự đặc biệt |
| `password123` | ❌ Không | Thiếu chữ hoa và ký tự đặc biệt |
| `MatKhau` | ❌ Không | Thiếu chữ số và ký tự đặc biệt |
| `P@ss1` | ❌ Không | Chỉ có 5 ký tự, chưa đủ 8 |

### Hệ thống tự khóa khi nhập sai mật khẩu

Nếu bạn nhập sai mật khẩu **5 lần liên tiếp**, hệ thống sẽ **tự động khóa tài khoản trong 5 phút**. Điều này giống như khi bạn nhập sai mã PIN ngân hàng nhiều lần — thẻ ATM sẽ bị nuốt để bảo vệ tài khoản của bạn.

---

## 1.2. Mục đích

### Tại sao cần mật khẩu mạnh?

- **Ngăn chặn kẻ gian đoán mật khẩu:** Kẻ xấu dùng phần mềm tự động thử hàng triệu mật khẩu phổ biến (như "123456", "password", "abc123"). Mật khẩu mạnh khiến phương pháp này mất hàng nghìn năm để thành công.
- **Bảo vệ thông tin cá nhân:** Tài khoản của bạn chứa lịch sử đặt vé, thông tin cá nhân. Không ai muốn người lạ biết được mình hay xem phim gì.
- **Ngăn chặn chiếm đoạt tài khoản:** Nếu ai đó đăng nhập được vào tài khoản của bạn, họ có thể đặt vé, hủy vé, hoặc thay đổi thông tin cá nhân của bạn.

### Nếu không có cơ chế này thì sao?

- Tài khoản của bạn có thể bị **chiếm đoạt trong vài phút** bằng cách thử các mật khẩu phổ biến.
- Kẻ gian có thể **đặt vé bằng thẻ của bạn** hoặc xem lịch sử giao dịch.
- Không có cơ chế khóa tài khoản → kẻ gian có thể **thử mật khẩu vô hạn** cho đến khi đúng.

---

## 1.3. Hệ thống hoạt động như thế nào

### Quy trình bảo vệ mật khẩu

```
Người dùng nhập mật khẩu
        ↓
Hệ thống kiểm tra độ mạnh
        ↓
[Tuân theo quy tắc]
        ↓
Mật khẩu được mã hóa và lưu trữ
        ↓
Lần đăng nhập tiếp theo:
        ↓
Người dùng nhập mật khẩu
        ↓
Hệ thống so sánh với bản mã hóa
        ↓
[Đúng] → Cho phép đăng nhập
[Sai] → Ghi nhận lần thử thất bại
        ↓
[Sai 5 lần liên tiếp]
        ↓
Tài khoản bị khóa tự động 5 phút
```

### Quy trình khóa tài khoản tự động

```
Lần đăng nhập thất bại thứ 1
        ↓
Ghi nhận: 1 lần thử sai
        ↓
Lần đăng nhập thất bại thứ 2
        ↓
Ghi nhận: 2 lần thử sai
        ↓
Lần đăng nhập thất bại thứ 3
        ↓
Ghi nhận: 3 lần thử sai
        ↓
Lần đăng nhập thất bại thứ 4
        ↓
Ghi nhận: 4 lần thử sai
        ↓
Lần đăng nhập thất bại thứ 5
        ↓
Tài khoản bị KHÓA trong 5 phút
        ↓
Hệ thống gửi cảnh báo bảo mật cho bạn
```

---

## 1.4. Áp dụng trong hệ thống Booking Movie Ticket

### Vị trí người dùng thấy cơ chế bảo mật

- **Màn hình đăng ký:** Khi tạo tài khoản mới, bạn sẽ thấy ô nhập mật khẩu với các quy tắc bên dưới.
- **Màn hình đăng nhập:** Khi nhập sai mật khẩu, hệ thống sẽ hiển thị số lần còn lại.
- **Màn hình bảo mật:** Vào tab "Bảo mật" trên ứng dụng để xem tình trạng bảo mật tài khoản.
- **Màn hình đổi mật khẩu:** Trong phần hồ sơ, bạn có thể thay đổi mật khẩu.

### Người dùng thao tác gì

1. Nhập mật khẩu theo đúng quy tắc (8 ký tự, có hoa, thường, số, ký tự đặc biệt).
2. Nhập lại mật khẩu để xác nhận (phải giống hệt mật khẩu vừa nhập).
3. Lưu mật khẩu vào trí nhớ hoặc sử dụng trình quản lý mật khẩu.

---

## 1.5. Hướng dẫn trải nghiệm

### Trải nghiệm tạo mật khẩu mạnh

**Bước 1:**
Mở ứng dụng và nhấn nút **"Đăng ký"** trên màn hình đăng nhập.

**Bước 2:**
Điền thông tin: Họ tên, Email (hoặc Số điện thoại).

**Bước 3:**
Nhập mật khẩu mới vào ô **"Mật khẩu"**. Hãy thử nhập một mật khẩu yếu trước để xem hệ thống báo lỗi.

**Bước 4:**
Nhập mật khẩu yếu, ví dụ: `password123`

**Bước 5:**
Nhấn nút **"Đăng Ký"** — bạn sẽ thấy hệ thống hiển thị thông báo lỗi yêu cầu mật khẩu phải có chữ hoa, chữ thường, số và ký tự đặc biệt.

**Bước 6:**
Bây giờ nhập mật khẩu mạnh, ví dụ: `MovieTicket@2026` — hệ thống sẽ chấp nhận.

**Bước 7:**
Nhập lại mật khẩu vào ô **"Xác nhận mật khẩu"** để hoàn tất đăng ký.

### Trải nghiệm khóa tài khoản

**Bước 1:**
Đăng nhập với email đã đăng ký, nhưng **nhập sai mật khẩu 5 lần liên tiếp**.

**Bước 2:**
Ở lần thứ 5, hệ thống sẽ hiển thị thông báo: **"Tài khoản đã bị tạm khóa trong 5 phút do đăng nhập sai nhiều lần."**

**Bước 3:**
Chờ 5 phút, sau đó thử đăng nhập lại với mật khẩu đúng.

---

## 1.6. Kết quả mong đợi

### Khi tạo mật khẩu đúng quy tắc

- Mật khẩu được chấp nhận, tài khoản được tạo thành công.
- Bạn nhận được thông báo yêu cầu xác minh email hoặc số điện thoại.

### Khi tạo mật khẩu yếu

- Hệ thống hiển thị thông báo lỗi rõ ràng, ví dụ:
  - *"Mật khẩu phải có ít nhất 8 ký tự"*
  - *"Mật khẩu phải chứa ít nhất 1 chữ in hoa"*
  - *"Mật khẩu phải chứa ít nhất 1 chữ số"*
  - *"Mật khẩu phải chứa ít nhất 1 ký tự đặc biệt (@, #, $,...)"*

### Khi tài khoản bị khóa

- Màn hình hiển thị thông báo khóa kèm thời gian chờ.
- Bạn không thể thử đăng nhập thêm trong thời gian khóa.
- Sau 5 phút, bạn có thể thử lại.

---

## 1.7. Các lỗi thường gặp

### Lỗi: "Mật khẩu không đủ mạnh"

**Nguyên nhân:** Mật khẩu của bạn thiếu một trong các yếu tố: chữ hoa, chữ thường, chữ số, hoặc ký tự đặc biệt.

**Cách xử lý:** Đọc kỹ thông báo lỗi và bổ sung phần còn thiếu. Ví dụ: `MatKhau123!` thành `MatKhau@123`.

### Lỗi: "Mật khẩu xác nhận không khớp"

**Nguyên nhân:** Bạn nhập mật khẩu ở hai ô khác nhau.

**Cách xử lý:** Kiểm tra lại và nhập chính xác giống nhau ở cả hai ô.

### Lỗi: "Tài khoản đã bị tạm khóa"

**Nguyên nhân:** Bạn đã nhập sai mật khẩu 5 lần liên tiếp.

**Cách xử lý:** Chờ 5 phút rồi thử lại với mật khẩu đúng. Nếu không nhớ mật khẩu, hãy liên hệ bộ phận hỗ trợ.

### Lỗi: Quên mật khẩu

**Nguyên nhân:** Không nhớ mật khẩu đã đặt.

**Cách xử lý:** Hiện tại hãy tạo tài khoản mới với email khác. (Chức năng đặt lại mật khẩu qua email đang được phát triển.)

---

# 2. Bảo Mật qua Email

## 2.1. Khái niệm

### Xác minh email là gì?

Xác minh email giống như việc bạn xác nhận danh tính bằng chứng minh nhân dân. Khi bạn đăng ký tài khoản bằng email, hệ thống cần đảm bảo rằng email đó thực sự thuộc về bạn, không phải ai đó nhập đại một email của người khác.

### Cách thức hoạt động bằng ngôn ngữ đời thường

Khi bạn đăng ký với email `minh@gmail.com`:

1. Hệ thống gửi một ** lá thư điện tử** (email) đến hộp thư `minh@gmail.com` của bạn.
2. Trong lá thư đó có một **mã số bí mật 6 chữ số**.
3. Bạn mở email, nhìn mã đó, rồi nhập vào ứng dụng để xác nhận: "Đúng rồi, email này là của tôi."

Điều này giống như bưu điện gửi thư xác nhận đến địa chỉ nhà bạn — nếu bạn nhận được thư tại địa chỉ đó, có nghĩa là địa chỉ đó là thật.

### Mã xác minh có thời hạn bao lâu?

Mã xác minh email chỉ **có hiệu lực trong 10 phút**. Giống như mã OTP của ngân hàng, nếu bạn không nhập trong thời gian này, mã sẽ hết hạn và bạn cần yêu cầu gửi mã mới.

### Nếu nhập sai mã quá nhiều lần thì sao?

Bạn chỉ được **nhập sai tối đa 5 lần** cho mỗi mã xác minh. Sau 5 lần sai, mã đó bị vô hiệu hóa và bạn phải yêu cầu hệ thống gửi mã mới.

---

## 2.2. Mục đích

### Tại sao cần xác minh email?

- **Xác nhận danh tính thật:** Đảm bảo người đăng ký thực sự sở hữu địa chỉ email đó. Nếu không có xác minh, kẻ xấu có thể đăng ký bằng email của người khác.
- **Phục hồi tài khoản:** Khi bạn quên mật khẩu, hệ thống sẽ gửi mã đặt lại đến email đã xác minh. Nếu email không được xác minh, bạn không thể lấy lại mật khẩu.
- **Nhận thông báo bảo mật:** Hệ thống sẽ gửi cảnh báo qua email khi phát hiện đăng nhập bất thường. Nếu email không được xác minh, bạn sẽ không nhận được cảnh báo.
- **Tăng điểm bảo mật:** Tài khoản có email đã xác minh sẽ có điểm bảo mật cao hơn, được bảo vệ tốt hơn.

### Nếu không xác minh email thì sao?

- Tài khoản bị **đánh dấu là chưa xác nhận**, giảm điểm bảo mật.
- Bạn **không thể nhận cảnh báo bảo mật** qua email khi có đăng nhập lạ.
- Bạn **không thể khôi phục tài khoản** nếu quên mật khẩu.
- Hệ thống có thể **hạn chế một số tính năng** đối với tài khoản chưa xác minh.

---

## 2.3. Hệ thống hoạt động như thế nào

### Quy trình xác minh email

```
Bước 1: Người dùng đăng ký tài khoản
        ↓
Bước 2: Nhập địa chỉ email
        ↓
Bước 3: Hệ thống gửi mã 6 chữ số đến email
        ↓
Bước 4: Người dùng kiểm tra hộp thư email
        ↓
Bước 5: Người dùng nhập mã vào ứng dụng
        ↓
Bước 6: Hệ thống kiểm tra mã
        ↓
[Mã đúng và còn hạn]
        ↓
Email được xác minh thành công
Tài khoản chính thức hoạt động
```

### Quy trình gửi lại mã

```
Người dùng không nhận được email
        ↓
Nhấn nút "Gửi lại mã"
        ↓
Hệ thống kiểm tra: đã đủ 60 giây chưa?
        ↓
[Chưa đủ 60 giây]
        ↓
Hiển thị thông báo: "Vui lòng chờ Xs trước khi gửi lại"
        ↓
[Đã đủ 60 giây]
        ↓
Hệ thống gửi mã mới (mã cũ bị vô hiệu hóa)
        ↓
Đếm ngược 60 giây trước khi cho gửi lại tiếp
```

### Quy trình nhập sai mã

```
Người dùng nhập mã sai
        ↓
Ghi nhận: 1 lần nhập sai
        ↓
Hệ thống thông báo: "Mã không chính xác. Vui lòng thử lại."
        ↓
Người dùng nhập sai lần 2, 3, 4...
        ↓
Nhập sai lần thứ 5
        ↓
Mã bị vô hiệu hóa
        ↓
Hệ thống yêu cầu: "Mã đã hết hạn. Vui lòng gửi lại mã mới."
```

---

## 2.4. Áp dụng trong hệ thống Booking Movie Ticket

### Vị trí người dùng thấy cơ chế xác minh email

- **Màn hình đăng ký:** Sau khi đăng ký thành công, nếu bạn nhập email, ứng dụng sẽ chuyển đến màn hình xác minh email.
- **Màn hình xác minh email:** Hiển thị ô nhập mã 6 chữ số với hướng dẫn kiểm tra email.
- **Màn hình bảo mật:** Trong tab "Bảo mật", bạn có thể thấy trạng thái xác minh email: ✅ Đã xác minh hoặc ❌ Chưa xác minh.

### Người dùng sẽ nhìn thấy gì?

1. Sau khi đăng ký, màn hình hiển thị thông báo: *"Xác thực Email: Mã kích hoạt đã được gửi!"*
2. Màn hình xác minh hiển thị email của bạn (ví dụ: `hoang123@gmail.com`) và hướng dẫn: *"Chúng tôi đã gửi mã xác nhận 6 chữ số vào địa chỉ email của bạn."*
3. Có ô nhập số lớn ở giữa màn hình để nhập mã.
4. Nút **"Gửi lại mã"** với đếm ngược 60 giây nếu chưa đủ thời gian.

### Người dùng cần thao tác gì?

1. Mở ứng dụng email trên điện thoại hoặc máy tính.
2. Tìm email từ hệ thống Booking Movie Ticket.
3. Nhớ hoặc sao chép mã 6 chữ số trong email.
4. Quay lại ứng dụng và nhập mã đó.
5. Nhấn **"Xác Nhận"**.

---

## 2.5. Hướng dẫn trải nghiệm

### Trải nghiệm xác minh email lần đầu

**Bước 1:**
Mở ứng dụng Booking Movie Ticket. Nhấn **"Đăng ký"** trên màn hình đăng nhập.

**Bước 2:**
Điền thông tin:
- Họ và tên: `Nguyễn Văn Minh`
- Email: nhập địa chỉ email thật của bạn (ví dụ: `minh@gmail.com`)
- Mật khẩu: `MovieTicket@2026`
- Xác nhận mật khẩu: `MovieTicket@2026`

**Bước 3:**
Nhấn **"Đăng Ký"**. Bạn sẽ thấy thông báo màu vàng: *"Xác thực Email: Mã kích hoạt đã được gửi!"*

**Bước 4:**
Mở ứng dụng email (Gmail, Outlook, v.v.) trên điện thoại.

**Bước 5:**
Tìm email từ hệ thống Booking Movie Ticket. Email sẽ có tiêu đề liên quan đến xác minh tài khoản.

**Bước 6:**
Mở email và tìm mã 6 chữ số (ví dụ: `847291`).

**Bước 7:**
 Quay lại ứng dụng, nhập mã 6 chữ số vào ô trống.

**Bước 8:**
Nhấn **"Xác Nhận"**. Bạn sẽ thấy thông báo màu xanh: *"Xác minh thành công! Hãy đăng nhập."*

### Trải nghiệm gửi lại mã

**Bước 1:**
Sau khi đăng ký, nếu bạn chưa nhận được email, chờ đủ **60 giây**.

**Bước 2:**
Nhấn nút **"Gửi lại mã xác minh"**. (Nếu chưa đủ 60 giây, nút sẽ hiển thị thời gian chờ, ví dụ: "Gửi lại mã sau 45s".)

**Bước 3:**
Kiểm tra lại hộp thư email, tìm email mới.

**Bước 4:**
Nhập mã mới và xác nhận.

### Trải nghiệm nhập sai mã

**Bước 1:**
Nhập một mã sai bất kỳ (ví dụ: `000000`) và nhấn **"Xác Nhận"**.

**Bước 2:**
Bạn sẽ thấy thông báo: *"Mã không chính xác. Vui lòng thử lại."*

**Bước 3:**
Nhập sai thêm 4 lần nữa. Ở lần thứ 5, hệ thống sẽ thông báo: *"Mã đã hết hạn. Vui lòng gửi lại mã mới."*

**Bước 4:**
Nhấn **"Gửi lại mã xác minh"** và nhập mã mới.

---

## 2.6. Kết quả mong đợi

### Xác minh thành công

- Thông báo màu xanh hiển thị: *"Xác minh thành công! Hãy đăng nhập."*
- Ứng dụng tự động chuyển về màn hình đăng nhập.
- Tài khoản của bạn đã được xác minh email.
- Trong màn hình "Trung Tâm Bảo Mật", trạng thái email sẽ hiển thị ✅ Đã xác minh.

### Xác minh thất bại

- **Sai mã:** Thông báo đỏ *"Mã không chính xác. Vui lòng thử lại."*
- **Mã hết hạn:** Thông báo *"Mã đã hết hạn. Vui lòng gửi lại mã mới."*
- **Hết lượt nhập:** Sau 5 lần sai, mã bị vô hiệu hóa, phải yêu cầu mã mới.

---

## 2.7. Các lỗi thường gặp

### Không nhận được email xác minh

**Nguyên nhân phổ biến:**

- Email bị lọc vào thư mục **Spam/Junk** (thư rác).
- Email bị lọc vào thư mục **Quảng cáo**.
- Địa chỉ email nhập sai khi đăng ký.
- Hệ thống email đang bận hoặc chậm.

**Cách xử lý:**

1. Kiểm tra thư mục **Spam** và **Quảng cáo** trong email.
2. Đợi 2-3 phút vì email có thể đến chậm.
3. Nếu vẫn không thấy, nhấn **"Gửi lại mã"** sau 60 giây.
4. Kiểm tra lại email đã nhập đúng chưa.

### Email nằm trong thư mục Spam

**Cách xử lý:**

1. Mở thư mục **Spam** trong email.
2. Tìm email từ hệ thống Booking Movie Ticket.
3. Nhấp vào email và chọn **"Không phải thư rác"** hoặc **"Đánh dấu là hợp lệ"**.
4. Các email tiếp theo sẽ vào hộp thư chính.

### Mã xác minh hết hạn

**Nguyên nhân:** Đã quá **10 phút** kể từ khi nhận được email.

**Cách xử lý:**

1. Nhấn **"Gửi lại mã xác minh"**.
2. Kiểm tra email mới.
3. Nhập mã mới trong vòng 10 phút.

### Nhập sai mã 5 lần

**Nguyên nhân:** Đã nhập sai mã quá 5 lần liên tiếp.

**Cách xử lý:**

1. Nhấn **"Gửi lại mã xác minh"**.
2. Sử dụng mã mới để xác minh.
3. Lần này hãy cẩn thận hơn khi nhập mã.

### Không có email trong hộp thư

**Cách xử lý:**

1. Đảm bảo địa chỉ email nhập đúng khi đăng ký.
2. Thử đăng ký lại với cùng email — hệ thống sẽ gửi mã mới.
3. Kiểm tra với nhà cung cấp email (Gmail, Outlook, v.v.) xem có vấn đề gì không.

---

# 3. Bảo Mật bằng Mã OTP

## 3.1. Khái niệm

### OTP là gì?

**OTP** là viết tắt của **One-Time Password** — tức "Mật khẩu dùng một lần". Giống như mã xác minh email, nhưng OTP được sử dụng trong một trường hợp đặc biệt: **mỗi khi bạn đăng nhập** khi đã bật tính năng xác thực hai lớp (2FA).

### Xác thực hai lớp (2FA) là gì?

Hãy tưởng tượng bạn vào một tòa nhà có hai cánh cửa liên tiếp:

- **Cửa thứ nhất:** Bạn cần mật khẩu để mở (lớp 1 — thứ bạn BIẾT).
- **Cửa thứ hai:** Bạn cần chìa khóa để mở (lớp 2 — thứ bạn CÓ).

Nếu kẻ gian có mật khẩu của bạn nhưng không có chìa khóa, họ vẫn không thể vào được. Đó chính là ý tưởng của xác thực hai lớp.

**Trong hệ thống của chúng ta:**

- **Lớp 1:** Mật khẩu (thứ bạn biết).
- **Lớp 2:** Mã OTP được gửi qua email (thứ bạn nhận được).

### Khi nào cần nhập OTP?

Bạn chỉ cần nhập OTP khi:

1. Bạn **đã bật tính năng 2FA** trong cài đặt bảo mật.
2. Bạn đang **đăng nhập** vào tài khoản.

### Mã OTP có khác gì mã xác minh email?

| Tiêu chí | Mã xác minh email | Mã OTP |
|----------|-------------------|--------|
| **Khi nào dùng?** | Lần đầu xác nhận email | Mỗi lần đăng nhập (khi bật 2FA) |
| **Thời hạn** | 10 phút | 5 phút |
| **Tần suất** | Chỉ một lần | Mỗi lần đăng nhập |
| **Mục đích** | Xác nhận email là thật | Đảm bảo đúng chủ tài khoản đang đăng nhập |

### Ví dụ thực tế trong cuộc sống

Khi bạn chuyển tiền qua app ngân hàng:

1. Bạn nhập mật khẩu app (lớp 1).
2. Ngân hàng gửi mã OTP qua tin nhắn SMS (lớp 2).
3. Bạn nhập mã OTP để xác nhận giao dịch.

Hệ thống Booking Movie Ticket hoạt động tương tự, nhưng mã được gửi qua email thay vì tin nhắn SMS.

---

## 3.2. Mục đích

### Tại sao cần xác thực hai lớp (2FA)?

- **Bảo vệ khi mật khẩu bị lộ:** Nếu kẻ gian biết mật khẩu của bạn (qua việc đoán, lấy trộm, hoặc từ vụ rò rỉ dữ liệu website khác), họ vẫn không thể đăng nhập được vì cần thêm mã OTP.
- **Phòng ngừa đăng nhập trái phép:** Ngay cả khi ai đó có mật khẩu của bạn, họ sẽ không nhận được mã OTP vì mã được gửi đến email của bạn.
- **Cảnh báo khi có người lạ cố đăng nhập:** Nếu bạn nhận được email chứa mã OTP mà bạn không yêu cầu, đó là dấu hiệu ai đó đang cố truy cập tài khoản của bạn.

### Nếu không có 2FA thì sao?

- Chỉ cần mật khẩu là đủ để đăng nhập.
- Nếu mật khẩu bị lộ, kẻ gian có thể **toàn quyền kiểm soát tài khoản**: đặt vé, hủy vé, xem lịch sử, thay đổi thông tin cá nhân.
- Không có lớp bảo vệ thứ hai khi mật khẩu bị xâm phạm.

---

## 3.3. Hệ thống hoạt động như thế nào

### Quy trình bật 2FA

```
Người dùng vào màn hình Trung Tâm Bảo Mật
        ↓
Nhìn thấy công tắc 2FA (mặc định: TẮT)
        ↓
Nhấn công tắc để BẬT
        ↓
Hệ thống ghi nhận: 2FA đã được bật
        ↓
Từ lần đăng nhập tiếp theo
        ↓
Yêu cầu thêm bước xác thực OTP
```

### Quy trình đăng nhập khi có 2FA

```
Bước 1: Người dùng nhập email/phone + mật khẩu
        ↓
Bước 2: Hệ thống kiểm tra mật khẩu → ĐÚNG
        ↓
Bước 3: Hệ thống thấy 2FA đang BẬT
        ↓
Bước 4: Gửi mã OTP 6 chữ số đến email của người dùng
        ↓
Bước 5: Hiển thị màn hình nhập OTP
        ↓
Bước 6: Người dùng mở email, đọc mã OTP
        ↓
Bước 7: Người dùng nhập mã OTP vào ứng dụng
        ↓
Bước 8: Hệ thống kiểm tra mã OTP
        ↓
[Mã đúng, còn hạn, chưa sử dụng]
        ↓
Đăng nhập thành công ✓
```

### Quy trình OTP hết hạn hoặc bị nhập sai

```
Người dùng nhập OTP sai
        ↓
Ghi nhận: 1 lần nhập sai
        ↓
Thông báo: "Mã OTP không chính xác"
        ↓
Nhập sai lần 2, 3, 4...
        ↓
Nhập sai lần thứ 5
        ↓
OTP bị vô hiệu hóa
        ↓
Hệ thống tạo cảnh báo bảo mật:
"Có người đang cố xác thực OTP nhiều lần"
        ↓
Người dùng phải đăng nhập lại từ đầu
để nhận OTP mới
```

---

## 3.4. Áp dụng trong hệ thống Booking Movie Ticket

### Vị trí người dùng thấy cơ chế OTP

- **Màn hình Trung Tâm Bảo Mật (tab Bảo mật):** Có công tắc bật/tắt 2FA ngay phía dưới thẻ Điểm Bảo Mật.
- **Màn hình đăng nhập:** Khi bật 2FA, sau khi nhập đúng mật khẩu, ứng dụng sẽ chuyển đến màn hình nhập OTP.
- **Màn hình nhập OTP:** Màn hình riêng với ô nhập số 6 chữ số và nhãn "Mã Bảo Mật OTP".

### Người dùng sẽ nhìn thấy gì?

**Khi bật 2FA thành công:**

- Công tắc 2FA chuyển sang màu tím (bật).
- Thông báo màu xanh: *"Đã BẬT xác thực 2 lớp (2FA) thành công!"*
- Điểm bảo mật tăng lên.

**Khi đăng nhập với 2FA:**

1. Nhập email và mật khẩu → nhấn "Đăng Nhập".
2. Mật khẩu đúng → thông báo màu vàng: *"Yêu cầu OTP: Mã bảo mật đã được gửi!"*
3. Màn hình chuyển sang màn hình nhập OTP.
4. Hướng dẫn: *"Tài khoản của bạn đã được bảo vệ bằng 2FA. Vui lòng nhập mã OTP đã gửi qua email."*
5. Hiển thị email của bạn bên dưới hướng dẫn.

### Người dùng cần thao tác gì?

**Bật 2FA:**

1. Mở ứng dụng, vào tab **"Bảo mật"** (biểu tượng khiên).
2. Tìm dòng **"Xác thực 2 bước (2FA)"**.
3. Gạt công tắc sang **BẬT**.
4. Đọc thông báo thành công.

**Đăng nhập khi có 2FA:**

1. Nhập email/phone và mật khẩu → nhấn "Đăng Nhập".
2. Đợi chuyển sang màn hình OTP.
3. Mở email, tìm mã OTP.
4. Nhập mã 6 chữ số vào ứng dụng.
5. Nhấn **"Xác Nhận OTP"**.

---

## 3.5. Hướng dẫn trải nghiệm

### Trải nghiệm bật tính năng 2FA

**Bước 1:**
Đảm bảo bạn đã đăng nhập vào ứng dụng.

**Bước 2:**
Nhấn vào tab **"Bảo mật"** ở thanh điều hướng dưới cùng (biểu tượng chiếc khiên 🛡️).

**Bước 3:**
Trên màn hình **Trung Tâm Bảo Mật**, bạn sẽ thấy:

- Thẻ **Điểm Bảo Mật Tài Khoản** — cho biết mức độ an toàn của tài khoản.
- Dòng **"Xác thực 2 bước (2FA)"** với công tắc bên phải.

**Bước 4:**
Nhấn (gạt) công tắc **2FA** sang bên phải để bật. Công tắc sẽ chuyển sang **màu tím**.

**Bước 5:**
Bạn sẽ thấy thông báo màu xanh: *"Đã BẬT xác thực 2 lớp (2FA) thành công!"*

**Bước 6:**
Quan sát **Điểm Bảo Mật** — điểm số sẽ tăng lên vì bạn đã có thêm lớp bảo vệ.

### Trải nghiệm đăng nhập với 2FA

**Bước 1:**
Đăng xuất khỏi ứng dụng bằng cách vào tab **"Hồ sơ"** → nhấn **"Đăng Xuất"**.

**Bước 2:**
Trên màn hình đăng nhập, nhập **email** và **mật khẩu** của tài khoản đã bật 2FA.

**Bước 3:**
Nhấn **"Đăng Nhập"**.

**Bước 4:**
Mật khẩu đúng → thông báo màu vàng xuất hiện: *"Yêu cầu OTP: Mã bảo mật đã được gửi!"*

**Bước 5:**
Màn hình chuyển sang **"Mã Bảo Mật OTP"**. Bạn sẽ thấy email của mình được hiển thị.

**Bước 6:**
Mở email, tìm email từ hệ thống Booking Movie Ticket.

**Bước 7:**
Trong email, tìm dòng chứa mã 6 chữ số (ví dụ: `394827`).

**Bước 8:**
 Quay lại ứng dụng, nhập mã đó vào ô trống.

**Bước 9:**
Nhấn **"Xác Nhận OTP"**.

**Bước 10:**
Thông báo màu xanh: *"Xác thực OTP thành công. Đăng nhập thành công!"* — Ứng dụng đưa bạn vào màn hình chính.

### Trải nghiệm tắt tính năng 2FA

**Bước 1:**
Vào tab **"Bảo mật"**.

**Bước 2:**
Gạt công tắc **2FA** sang bên trái để tắt.

**Bước 3:**
Công tắc chuyển về màu xám.

**Bước 4:**
Thông báo: *"Đã TẮT xác thực 2 lớp (2FA)."*

**Bước 5:**
Từ lần đăng nhập tiếp theo, bạn chỉ cần nhập email và mật khẩu, không cần nhập OTP nữa.

---

## 3.6. Kết quả mong đợi

### Bật 2FA thành công

- Công tắc 2FA chuyển sang **màu tím** (bật).
- Thông báo xanh: *"Đã BẬT xác thực 2 lớp (2FA) thành công!"*
- Điểm bảo mật trên thẻ **Trung Tâm Bảo Mật** tăng thêm **20 điểm**.
- Trong thẻ **Các kênh liên lạc & Xác minh**, trạng thái hiển thị đầy đủ.

### Đăng nhập với 2FA thành công

- Sau khi nhập đúng OTP, thông báo xanh: *"Xác thực OTP thành công. Đăng nhập thành công!"*
- Ứng dụng chuyển vào màn hình chính.
- Mã OTP đã sử dụng sẽ bị vô hiệu hóa ngay lập tức (không thể dùng lại).

### Nhập sai OTP

- Thông báo đỏ: *"Mã OTP không chính xác. Vui lòng thử lại."*
- Bạn có thể thử lại với cùng mã (nếu chưa đến lần thứ 5) hoặc yêu cầu đăng nhập lại để nhận mã mới.

### Nhập sai OTP 5 lần

- Thông báo thông báo OTP bị vô hiệu hóa.
- Hệ thống tạo **cảnh báo bảo mật** ghi nhận ai đó đang cố xác thực OTP sai nhiều lần.
- Bạn phải nhập lại email và mật khẩu để nhận OTP mới.

---

## 3.7. Các lỗi thường gặp

### Không nhận được email chứa mã OTP

**Nguyên nhân:** Giống như không nhận được email xác minh — có thể bị lọc vào Spam.

**Cách xử lý:**

1. Kiểm tra thư mục **Spam/Junk** trong email.
2. Đợi 1-2 phút vì email có thể đến chậm.
3. Nếu cần, quay lại màn hình đăng nhập và thử đăng nhập lại để nhận mã mới.

### Mã OTP hết hạn

**Nguyên nhân:** Mã OTP chỉ có hiệu lực trong **5 phút** — thời gian ngắn hơn mã xác minh email.

**Cách xử lý:**

1. Quay lại màn hình đăng nhập.
2. Đăng nhập lại (nhập email và mật khẩu) để nhận mã OTP mới.
3. Nhập mã mới trong vòng 5 phút.

### Nhập sai OTP nhiều lần

**Nguyên nhân:** Nhập sai mã 5 lần liên tiếp → hệ thống vô hiệu hóa mã đó.

**Cách xử lý:**

1. Quay lại màn hình đăng nhập.
2. Đăng nhập lại để nhận mã OTP mới.
3. Lần này hãy cẩn thận khi nhập mã từ email.

### Không hiểu tại sao mình nhận được mã OTP mà không đăng nhập

**Nguyên nhân:** Có thể ai đó đang cố đăng nhập vào tài khoản của bạn bằng mật khẩu đúng.

**Cách xử lý:**

1. **Không cung cấp mã OTP** cho bất kỳ ai, kể cả nhân viên hỗ trợ.
2. Kiểm tra **Lịch sử đăng nhập** trong tab Bảo mật để xem có đăng nhập lạ không.
3. Kiểm tra **Cảnh báo bảo mật** để xem có thông báo nào.
4. Nếu phát hiện đăng nhập lạ, hãy **đổi mật khẩu ngay**.

---

# 4. Demo

## 4.1. Kịch bản Demo hoàn chỉnh

### Thông tin demo

- **Người trình bày:** Thực hiện các thao tác trên ứng dụng Flutter.
- **Khán giả:** Giảng viên hoặc khách hàng.
- **Thời gian ước tính:** 15-20 phút.

---

### Phần 1: Giới thiệu hệ thống bảo mật (2 phút)

**Người trình bày:**

> "Chào mọi người! Hôm nay tôi sẽ giới thiệu về các cơ chế bảo mật trong hệ thống Booking Movie Ticket của chúng tôi.
>
> Hệ thống của chúng tôi có **4 lớp bảo mật chính**:
>
> 1. **Mật khẩu mạnh** — bắt buộc tối thiểu 8 ký tự, có chữ hoa, chữ thường, số và ký tự đặc biệt.
> 2. **Xác minh email** — khi đăng ký, bạn cần xác nhận email là thật qua mã 6 chữ số.
> 3. **Xác thực hai lớp (2FA)** — khi bật, mỗi lần đăng nhập đều cần thêm mã OTP từ email.
> 4. **Tự động khóa tài khoản** — nếu nhập sai mật khẩu 5 lần, tài khoản sẽ bị khóa 5 phút.
>
> Tôi sẽ demo từng phần để mọi người thấy rõ cách hoạt động."

---

### Phần 2: Đăng ký và xác minh email (5 phút)

**Bước 1: Đăng ký tài khoản**

**Người trình bày:**

> "Đầu tiên, tôi sẽ đăng ký một tài khoản mới. Tôi sẽ sử dụng mật khẩu yếu trước để các bạn thấy hệ thống có cơ chế kiểm tra."

**Thao tác:**

1. Mở ứng dụng → nhấn **"Đăng ký"**.
2. Nhập: Họ tên = `Demo User`, Email = `demo@example.com`, Mật khẩu = `weakpass`.
3. Nhấn **"Đăng Ký"**.

**Hệ thống phản hồi:**

- Thông báo lỗi hiển thị các yêu cầu mật khẩu chưa đạt.

**Người trình bày:**

> "Các bạn thấy không? Hệ thống không cho phép đặt mật khẩu yếu. Bây giờ tôi sẽ nhập mật khẩu đủ mạnh."

**Thao tác:**

1. Xóa mật khẩu cũ, nhập: `MovieTicket@2026`.
2. Nhập lại: `MovieTicket@2026`.
3. Nhấn **"Đăng Ký"**.

**Hệ thống phản hồi:**

- Thông báo vàng: *"Xác thực Email: Mã kích hoạt đã được gửi!"*
- Chuyển sang màn hình xác minh email.

---

**Bước 2: Xác minh email**

**Người trình bày:**

> "Tôi sẽ mở email để lấy mã xác minh. Trong demo này, email sẽ đến hộp thư của tôi."

**Thao tác:**

1. Mở email `demo@example.com` trên điện thoại/máy tính.
2. Tìm email từ Booking Movie Ticket.
3. Sao chép mã 6 chữ số.
4. Quay lại ứng dụng, nhập mã.
5. Nhấn **"Xác Nhận"**.

**Hệ thống phản hồi:**

- Thông báo xanh: *"Xác minh thành công! Hãy đăng nhập."*
- Chuyển về màn hình đăng nhập.

**Người trình bày:**

> "Email đã được xác minh thành công. Bây giờ tài khoản đã chính thức hoạt động. Các bạn có thể thấy trạng thái 'Đã xác minh Email' trong màn hình bảo mật."

---

### Phần 3: Đăng nhập thông thường (2 phút)

**Người trình bày:**

> "Bây giờ tôi sẽ đăng nhập vào tài khoản vừa tạo. Vì chưa bật 2FA nên chỉ cần email và mật khẩu."

**Thao tác:**

1. Nhập email: `demo@example.com`.
2. Nhập mật khẩu: `MovieTicket@2026`.
3. Nhấn **"Đăng Nhập"**.

**Hệ thống phản hồi:**

- Thông báo xanh: *"Đăng nhập thành công!"*
- Chuyển vào màn hình chính của ứng dụng.

**Người trình bày:**

> "Đăng nhập thành công. Các bạn thấy thanh điều hướng ở dưới có 5 tab: Trang chủ, Phim, Vé của tôi, Bảo mật và Hồ sơ."

---

### Phần 4: Khóa tài khoản tự động (3 phút)

**Người trình bày:**

> "Bây giờ tôi sẽ demo cơ chế khóa tài khoản. Tôi sẽ đăng xuất và nhập sai mật khẩu 5 lần liên tiếp."

**Thao tác:**

1. Vào tab **"Hồ sơ"** → nhấn **"Đăng Xuất"**.
2. Trên màn hình đăng nhập, nhập email: `demo@example.com`.
3. Nhập sai mật khẩu: `WrongPass1!` → nhấn "Đăng Nhập".
4. Lặp lại bước 3 thêm 4 lần nữa.

**Hệ thống phản hồi (từng bước):**

- Lần 1-4: Thông báo đỏ về sai mật khẩu.
- Lần 5: Thông báo đỏ: *"Tài khoản đã bị tạm khóa trong 5 phút do đăng nhập sai nhiều lần."*

**Người trình bày:**

> "Các bạn thấy không? Sau 5 lần nhập sai, tài khoản bị khóa tự động trong 5 phút. Đây là cơ chế bảo vệ tài khoản khỏi kẻ gian cố thử nhiều mật khẩu."

> "Bây giờ tôi sẽ đợi 5 phút hoặc chuyển sang phần tiếp theo, sau đó quay lại để đăng nhập thành công."

---

### Phần 5: Bật 2FA và đăng nhập với OTP (5 phút)

**Người trình bày:**

> "Bây giờ tôi sẽ bật tính năng xác thực hai lớp (2FA) cho tài khoản này."

**Thao tác:**

1. Đăng nhập thành công (sau khi hết thời gian khóa hoặc thử lại với mật khẩu đúng).
2. Nhấn vào tab **"Bảo mật"** (biểu tượng khiên).

**Hệ thống phản hồi:**

- Màn hình **Trung Tâm Bảo Mật** hiển thị với:
  - Thẻ **Điểm Bảo Mật Tài Khoản**: hiển thị số điểm hiện tại.
  - Công tắc **Xác thực 2 bước (2FA)**: màu xám (tắt).

**Người trình bày:**

> "Các bạn thấy thanh điểm bảo mật ở đây. Tôi sẽ bật 2FA để tăng điểm bảo mật."

**Thao tác:**

1. Gạt công tắc **2FA** sang BẬT.

**Hệ thống phản hồi:**

- Công tắc chuyển sang màu tím.
- Thông báo xanh: *"Đã BẬT xác thực 2 lớp (2FA) thành công!"*
- Thanh điểm bảo mật tăng lên.

**Người trình bày:**

> "2FA đã được bật. Điểm bảo mật tăng từ [số cũ] lên [số mới]. Từ lần đăng nhập tiếp theo, hệ thống sẽ yêu cầu thêm mã OTP."

**Thao tác:**

1. Vào tab **"Hồ sơ"** → nhấn **"Đăng Xuất"**.

---

**Bước tiếp: Đăng nhập với 2FA**

**Người trình bày:**

> "Bây giờ tôi sẽ đăng nhập lại. Các bạn sẽ thấy hệ thống yêu cầu thêm bước xác thực OTP."

**Thao tác:**

1. Nhập email: `demo@example.com`.
2. Nhập mật khẩu: `MovieTicket@2026`.
3. Nhấn **"Đăng Nhập"**.

**Hệ thống phản hồi:**

- Thông báo vàng: *"Yêu cầu OTP: Mã bảo mật đã được gửi!"*
- Chuyển sang màn hình **"Mã Bảo Mật OTP"**.
- Hiển thị email: `demo@example.com`.

**Người trình bày:**

> "Các bạn thấy không? Mật khẩu đúng, nhưng hệ thống yêu cầu thêm mã OTP. Tôi sẽ lấy mã từ email."

**Thao tác:**

1. Mở email `demo@example.com`.
2. Tìm email chứa mã OTP.
3. Sao chép mã 6 chữ số.
4. Quay lại ứng dụng, nhập mã.
5. Nhấn **"Xác Nhận OTP"**.

**Hệ thống phản hồi:**

- Thông báo xanh: *"Xác thực OTP thành công. Đăng nhập thành công!"*
- Chuyển vào màn hình chính.

**Người trình bày:**

> "Đăng nhập thành công với 2 lớp bảo vệ. Bây giờ tôi sẽ xem lại lịch sử đăng nhập để các bạn thấy hệ thống ghi nhận tất cả hoạt động."

---

### Phần 6: Kiểm tra lịch sử đăng nhập và cảnh báo (3 phút)

**Người trình bày:**

> "Trong tab Bảo mật, tôi có thể xem chi tiết lịch sử đăng nhập và các cảnh báo bảo mật."

**Thao tác:**

1. Vào tab **"Bảo mật"**.
2. Nhấn vào **"Lịch sử đăng nhập thiết bị"**.

**Hệ thống phản hồi:**

- Danh sách các lần đăng nhập hiển thị với:
  - Biểu tượng xanh ✅ cho đăng nhập thành công.
  - Biểu tượng đỏ ❌ cho đăng nhập thất bại.
  - Biểu tượng vàng ⚠️ cho đăng nhập đáng nghi (nếu có).
  - Thông tin: thiết bị, địa chỉ IP, thời gian.

**Người trình bày:**

> "Các bạn thấy hệ thống ghi lại tất cả các lần đăng nhập, kể cả thành công và thất bại. Nếu có đăng nhập từ thiết bị lạ hoặc địa chỉ IP lạ, hệ thống sẽ đánh dấu là 'đáng nghi'."

**Thao tác:**

1. Nhấn quay lại.
2. Nhấn vào **"Cảnh báo và Nhật ký bảo mật"**.

**Hệ thống phản hồi:**

- Danh sách các cảnh báo bảo mật (nếu có), ví dụ:
  - "OTP_BRUTE_FORCE" — khi có người cố nhập OTP sai nhiều lần.
  - "ACCOUNT_LOCKED" — khi tài khoản bị khóa.

**Người trình bày:**

> "Đây là nơi hệ thống thông báo cho bạn khi phát hiện hoạt động bất thường. Nếu bạn thấy cảnh báo mà không phải do mình gây ra, hãy đổi mật khẩu ngay."

---

## 4.2. Câu hỏi thường gặp (FAQ)

### Cơ bản về bảo mật

**Hỏi: Tại sao mật khẩu phải phức tạp như vậy?**

Trả lời: Mật khẩu đơn giản như "123456" hoặc "password" có thể bị đoán ra trong vài giây bằng phần mềm tự động. Mật khẩu mạnh giống như ổ khóa phức tạp — kẻ gian cần rất nhiều thời gian để phá. Quy tắc 8 ký tự trở lên với đủ 4 loại ký tự là mức tối thiểu được khuyến nghị bởi các chuyên gia bảo mật trên thế giới.

---

**Hỏi: Hệ thống có lưu mật khẩu ở dạng chữ thường không?**

Trả lời: Không. Hệ thống sử dụng thuật toán **Argon2id** — một trong những thuật toán mã hóa mật khẩu mạnh nhất hiện nay. Mật khẩu của bạn được "băm" (hash) thành một chuỗi ký tự dài trước khi lưu vào cơ sở dữ liệu. Ngay cả khi ai đó trộm dữ liệu, họ cũng không thể đọc được mật khẩu gốc.

---

**Hỏi: Nếu tôi nhập sai mật khẩu 5 lần thì sao?**

Trả lời: Tài khoản sẽ bị **tạm khóa trong 5 phút**. Điều này ngăn kẻ gian sử dụng phần mềm tự động thử hàng triệu mật khẩu. Sau 5 phút, bạn có thể thử lại. Nếu bạn quên mật khẩu, hãy chờ hết thời gian khóa rồi thử đăng nhập với mật khẩu đúng.

---

### Về xác minh email

**Hỏi: Tại sao tôi cần xác minh email?**

Trả lời: Xác minh email giống như xác nhận địa chỉ nhà bằng thư xác nhận. Nếu bạn không xác minh email, hệ thống không biết chắc email đó có thật sự là của bạn hay không. Email đã xác minh còn giúp bạn nhận cảnh báo bảo mật và phục hồi tài khoản khi quên mật khẩu.

---

**Hỏi: Mã xác minh có thời hạn bao lâu?**

Trả lời: Mã xác minh email có hiệu lực trong **10 phút**. Nếu hết hạn, hãy nhấn "Gửi lại mã" để nhận mã mới.

---

**Hỏi: Tôi không nhận được email xác minh. Phải làm sao?**

Trả lời: Hãy kiểm tra theo thứ tự:

1. Thư mục **Spam/Junk** trong email.
2. Thư mục **Quảng cáo**.
3. Đợi 2-3 phút vì email có thể đến chậm.
4. Nhấn **"Gửi lại mã"** (sau 60 giây) để nhận mã mới.

---

**Hỏi: Tôi có thể bỏ qua xác minh email không?**

Trả lời: Không bắt buộc, nhưng nếu không xác minh, tài khoản sẽ có **điểm bảo mật thấp hơn** và bị **hạn chế một số tính năng**. Điểm bảo mật cho email đã xác minh là +30 điểm — đây là phần điểm lớn nhất trong tổng điểm.

---

### Về OTP và 2FA

**Hỏi: 2FA là gì và tại sao nên bật?**

Trả lời: **2FA (Xác thực hai lớp)** là tính năng yêu cầu thêm một bước xác thực ngoài mật khẩu mỗi khi đăng nhập. Nên bật vì: nếu kẻ gian biết mật khẩu của bạn (qua đoán, lấy trộm, hoặc vụ rò rỉ dữ liệu website khác), họ vẫn **không thể đăng nhập** vì cần thêm mã OTP chỉ gửi đến email của bạn. Bật 2FA tăng thêm **20 điểm** vào điểm bảo mật.

---

**Hỏi: Mã OTP khác gì mã xác minh email?**

Trả lời: Mã xác minh email dùng **một lần duy nhất** khi bạn mới đăng ký để xác nhận email là thật. Mã OTP dùng **mỗi lần đăng nhập** khi bạn đã bật 2FA. Mã xác minh có hiệu lực **10 phút**, mã OTP có hiệu lực **5 phút**.

---

**Hỏi: Mã OTP có thể dùng lại được không?**

Trả lời: Không. Mỗi mã OTP chỉ có thể sử dụng **một lần duy nhất**. Sau khi nhập đúng, mã đó bị vô hiệu hóa ngay lập tức.

---

**Hỏi: Tôi nhận được mã OTP mà không có ai đăng nhập. Có sao không?**

Trả lời: **Có thể ai đó đang cố đăng nhập vào tài khoản của bạn** bằng mật khẩu đúng. Hãy:

1. **Không cung cấp mã OTP cho ai**, kể cả người tự xưng là nhân viên hỗ trợ.
2. Kiểm tra **Lịch sử đăng nhập** trong tab Bảo mật.
3. Kiểm tra **Cảnh báo bảo mật** xem có thông báo nào.
4. **Đổi mật khẩu ngay** nếu phát hiện đăng nhập lạ.

---

**Hỏi: Tôi có thể tắt 2FA không?**

Trả lời: Có. Bạn có thể tắt 2FA bất cứ lúc nào trong mục **Trung Tâm Bảo Mật**. Tuy nhiên, sau khi tắt, điểm bảo mật sẽ giảm và lần đăng nhập tiếp theo sẽ chỉ cần mật khẩu (không cần OTP). Khuyến nghị nên **bật 2FA** để bảo vệ tài khoản tốt hơn.

---

### Về điểm bảo mật

**Hỏi: Điểm bảo mật là gì?**

Trả lời: Điểm bảo mật là thang điểm từ **0 đến 100** cho biết mức độ an toàn của tài khoản. Điểm càng cao, tài khoản càng được bảo vệ tốt. Điểm được tính dựa trên:

- ✅ Email đã xác minh: +30 điểm
- ✅ Số điện thoại đã xác minh: +25 điểm
- ✅ Có số điện thoại: +15 điểm
- ✅ Đã bật 2FA: +20 điểm
- ✅ Ít lần đăng nhập thất bại: +15 điểm
- ✅ Không có đăng nhập đáng nghi: +15 điểm
- ✅ Tài khoản không bị khóa: +20 điểm

---

**Hỏi: Điểm bảo mật bao nhiêu là đủ?**

Trả lời:

- **Dưới 50 điểm (đỏ):** Cần cải thiện ngay. Tài khoản có nhiều rủi ro.
- **50-74 điểm (vàng):** Khá ổn nhưng nên bật thêm 2FA hoặc xác minh số điện thoại.
- **75-100 điểm (xanh):** Tài khoản được bảo vệ tốt. Mục tiêu nên đạt được.

---

### Về đăng nhập và thiết bị

**Hỏi: Hệ thống ghi nhận những thông tin gì khi tôi đăng nhập?**

Trả lời: Hệ thống ghi lại:

- **Email/phone** bạn dùng để đăng nhập.
- **Loại thiết bị** (điện thoại Android, iPhone, trình duyệt web...).
- **Địa chỉ IP** (số nhận dạng vị trí kết nối internet của bạn).
- **Thời gian** đăng nhập.
- **Kết quả** — thành công hay thất bại, và lý do nếu thất bại.

**Không có thông tin gì** bị ghi lại khi bạn chưa thực hiện thao tác đăng nhập.

---

**Hỏi: Tôi đăng nhập từ thiết bị mới. Có sao không?**

Trả lời: Đăng nhập từ thiết bị mới là bình thường — bạn có thể dùng điện thoại mới, máy tính mới, hoặc đăng nhập từ thiết bị khác. Hệ thống sẽ ghi nhận thiết bị mới trong **Lịch sử đăng nhập**. Nếu đó thực sự là bạn, không có vấn đề gì.

---

**Hỏi: Tôi thấy đăng nhập lạ trong lịch sử. Phải làm sao?**

Trả lời: Nếu bạn nhận ra có đăng nhập từ thiết bị hoặc địa điểm mà bạn không sử dụng:

1. **Đổi mật khẩu ngay lập tức.**
2. **Bật 2FA** nếu chưa bật.
3. **Đăng xuất** khỏi tất cả các thiết bị khác (tính năng đang phát triển).
4. Kiểm tra và **xóa các đăng nhập đáng nghi** trong lịch sử.
5. Liên hệ bộ phận hỗ trợ nếu cần.

---

### Về kỹ thuật (dành cho giảng viên)

**Hỏi: Thuật toán băm mật khẩu sử dụng là gì?**

Trả lời: Hệ thống sử dụng **Argon2id** — thuật toán băm mật khẩu thuộc họ Argon2, đạt giải thưởng Password Hashing Competition. Argon2id được thiết kế để chống lại cả tấn công GPU và tấn công kênh bên, và được khuyến nghị bởi nhiều tổ chức bảo mật quốc tế.

---

**Hỏi: Token đăng nhập (JWT) hoạt động như thế nào?**

Trả lời: Khi bạn đăng nhập thành công, hệ thống cấp hai loại token:

- **Access Token (thẻ vào cửa):** Có hiệu lực **15 phút**. Dùng để xác thực mỗi khi gọi API (lấy thông tin phim, đặt vé...). Hết 15 phút → phải làm mới.
- **Refresh Token (thẻ gia hạn):** Có hiệu lực **7 ngày**. Dùng để xin cấp Access Token mới khi hết hạn mà không cần đăng nhập lại.

Việc tách thành hai token giúp giảm thiểu rủi ro: nếu Access Token bị lộ, kẻ gian chỉ có **15 phút** để sử dụng, trong khi Refresh Token được lưu trữ an toàn trong cơ sở dữ liệu dưới dạng băm.

---

**Hỏi: Rate limiting (giới hạn tần suất) hoạt động ra sao?**

Trả lời: Hệ thống giới hạn số lần gọi API trong một khoảng thời gian:

| Hành động | Giới hạn | Thời gian |
|-----------|----------|-----------|
| Đăng nhập | 10 lần | mỗi 15 phút |
| Đăng ký | 5 lần | mỗi 15 phút |
| Xác minh email | 10 lần | mỗi 15 phút |
| Xác minh OTP | 5 lần | mỗi 15 phút |
| Gửi lại mã | 3 lần | mỗi 15 phút |

Điều này ngăn phần mềm tự động thử đăng nhập hoặc spam yêu cầu gửi mã.

---

**Hỏi: Các cảnh báo bảo mật được tạo trong những trường hợp nào?**

Trả lời: Hệ thống tự động tạo cảnh báo bảo mật trong các tình huống:

- **ACCOUNT_LOCKED** — Tài khoản bị khóa do nhập sai mật khẩu nhiều lần. Mức độ: CAO.
- **SUSPICIOUS_LOGIN** — Có đăng nhập từ thiết bị hoặc địa chỉ IP chưa từng thấy. Mức độ: TRUNG BÌNH.
- **OTP_BRUTE_FORCE** — Có người cố nhập OTP sai nhiều lần liên tiếp. Mức độ: CAO.
- **TWO_FACTOR_ENABLED** — Người dùng bật 2FA. Mức độ: THẤP.
- **TWO_FACTOR_DISABLED** — Người dùng tắt 2FA. Mức độ: TRUNG BÌNH.

---

## 4.3. Bảng tóm tắt các cơ chế bảo mật

| Cơ chế | Mô tả | Thông số | Lợi ích |
|--------|-------|----------|---------|
| **Mật khẩu mạnh** | Bắt buộc đủ 8 ký tự, hoa, thường, số, ký tự đặc biệt | Tối thiểu 8 ký tự | Ngăn kẻ gian đoán mật khẩu |
| **Băm mật khẩu** | Argon2id — thuật toán băm tiên tiến | 64MB RAM, 3 vòng lặp | Không ai đọc được mật khẩu gốc |
| **Khóa tài khoản** | Tự động khóa khi nhập sai nhiều lần | 5 lần sai → khóa 5 phút | Ngăn tấn công đoán mật khẩu tự động |
| **Xác minh email** | Gửi mã 6 chữ số qua email khi đăng ký | 10 phút, tối đa 5 lần nhập | Xác nhận email là thật, phục hồi tài khoản |
| **Xác thực 2 lớp (2FA)** | Yêu cầu thêm mã OTP qua email khi đăng nhập | 5 phút, tối đa 5 lần nhập | Bảo vệ khi mật khẩu bị lộ |
| **Điểm bảo mật** | Thang điểm 0-100 đánh giá mức độ an toàn | Tối đa 100 điểm | Giúp người dùng biết tình trạng bảo mật |
| **Lịch sử đăng nhập** | Ghi lại tất cả lần đăng nhập | Thiết bị, IP, thời gian | Phát hiện đăng nhập lạ |
| **Cảnh báo bảo mật** | Thông báo khi phát hiện hoạt động bất thường | 5 loại cảnh báo | Cảnh báo sớm nguy cơ |
| **Access Token** | Thẻ xác thực ngắn hạn | 15 phút | Giảm thiểu rủi ro khi bị lộ |
| **Refresh Token** | Thẻ gia hạn dài hạn, lưu dạng băm | 7 ngày, có thể thu hồi | Đăng nhập liên tục mà vẫn an toàn |
| **Giới hạn tần suất** | Giới hạn số lần gọi API | 3-10 lần / 15 phút | Ngăn spam và tấn công tự động |

---

*Tài liệu hướng dẫn bảo mật — Hệ thống Booking Movie Ticket*
*Phiên bản 1.0 — 2026*
