# 🎬 Movie Ticket Booking App with Account Security

Ứng dụng đặt vé xem phim tích hợp các tính năng bảo mật tài khoản nâng cao. Dự án sử dụng stack công nghệ bao gồm **Flutter (Mobile client)**, **Node.js Express (Backend API)** và **MySQL (CSDL chạy qua Docker)**.

---

## 🛠️ Yêu cầu hệ thống (Prerequisites)

Trước khi bắt đầu, hãy đảm bảo máy tính của bạn đã cài đặt các công cụ sau:
1. **Node.js** (Phiên bản v18 trở lên)
2. **Flutter SDK** (Phiên bản 3.22 trở lên)
3. **Docker Desktop** (Để chạy container MySQL)
4. **Android SDK / Emulator** hoặc thiết bị thật để chạy app Flutter.

---

## 🚀 Hướng dẫn cài đặt & Khởi chạy dự án

### Bước 1: Thiết lập biến môi trường (.env)
Sao chép tệp cấu hình mẫu và tạo file `.env` ở thư mục gốc (Root) và thư mục `backend`:
1. Tại thư mục gốc, tạo file `.env` từ file `.env` mẫu:
   ```bash
   cp .env.example .env  # hoặc tự tạo thủ công .env
   ```
2. Sao chép nội dung `.env` đó vào thư mục `backend/.env` (hoặc copy từ `backend/.env.example`).
3. Đảm bảo cổng `PORT=3001` và cấu hình MySQL URL đúng định dạng:
   ```text
   DATABASE_URL="mysql://root:root_password@localhost:3308/account_security_db"
   ```

### Bước 2: Khởi chạy Database (MySQL Docker)
1. Mở Docker Desktop.
2. Tại thư mục gốc của dự án, khởi chạy container MySQL:
   ```bash
   docker compose up -d
   ```
3. Kiểm tra container đã hoạt động bình thường trên cổng `3308` bằng lệnh:
   ```bash
   docker compose ps
   ```

### Bước 3: Khởi chạy Node.js Backend API
1. Di chuyển vào thư mục `backend`:
   ```bash
   cd backend
   ```
2. Cài đặt các thư viện Node.js cần thiết:
   ```bash
   npm install
   ```
3. Tạo và áp dụng cấu trúc bảng (Migrations) vào Database:
   ```bash
   npx prisma migrate dev --name init
   ```
4. Nạp dữ liệu mẫu ban đầu (Phim, rạp, phòng chiếu, ghế ngồi, chương trình khuyến mãi, tài khoản admin):
   ```bash
   npm run seed
   ```
5. Khởi chạy Backend API Server (chạy ở chế độ Dev Watch trên cổng `3001`):
   ```bash
   npm run dev
   ```
   *API Health Check:* [http://localhost:3001/api/health](http://localhost:3001/api/health)

---

### Bước 4: Khởi chạy Ứng dụng Flutter (Mobile Client)
1. Kết nối điện thoại Android của bạn hoặc khởi động Android Emulator (ví dụ: qua Android Studio hoặc VS Code).
2. Di chuyển vào thư mục `flutter_app`:
   ```bash
   cd flutter_app
   ```
3. Lấy các package Flutter phụ thuộc:
   ```bash
   flutter pub get
   ```
4. Chạy ứng dụng trên thiết bị đã kết nối:
   ```bash
   flutter run
   ```

---

## 🛡️ Tài khoản dùng thử (Demo Credentials)

Sau khi seed dữ liệu thành công, bạn có thể đăng nhập bằng tài khoản Admin mặc định sau:
* **Email:** `admin@movieapp.com`
* **Mật khẩu:** `Admin@123`

---

## ❓ Xử lý lỗi thường gặp (Troubleshooting)

### 1. Lỗi Symlink khi chạy `flutter pub get` trên Windows
* **Lỗi:** `Building with plugins requires symlink support. Please enable Developer Mode...`
* **Cách sửa:** Bạn cần bật **Developer Mode (Chế độ nhà phát triển)** trong Windows Settings:
  1. Mở Cài đặt hệ thống Windows (nhấn `Win + I`).
  2. Tìm kiếm **Developer Settings** (Cấu hình nhà phát triển).
  3. Bật tùy chọn **Developer Mode** lên mức **On**.

### 2. Lỗi bị khóa/chặn do gửi quá nhiều yêu cầu đăng nhập
* **Lỗi:** `Too many login attempts. Please try again after 15 minutes.`
* **Cách sửa:** Hệ thống tự động giới hạn lượt gọi API để chống Brute Force. Trong môi trường phát triển (`NODE_ENV=development`), giới hạn này đã được nâng lên **1000 lần / 15 phút** để bạn thoải mái test mà không bị block.

---

## 📂 Danh mục tài liệu tham khảo dự án
Tất cả các tài liệu đặc tả thiết kế và kiến trúc được lưu trữ trong thư mục `docs/`:
* [PROJECT_CONTEXT.md](file:///d:/PRM/booking-movie-ticket/docs/PROJECT_CONTEXT.md) - Bối cảnh & định hướng dự án
* [DATABASE_DESIGN.md](file:///d:/PRM/booking-movie-ticket/docs/DATABASE_DESIGN.md) - Thiết kế lược đồ thực thể (Prisma/MySQL)
* [API_SPEC.md](file:///d:/PRM/booking-movie-ticket/docs/API_SPEC.md) - Tài liệu đặc tả các API endpoints
* [AI_RULES.md](file:///d:/PRM/booking-movie-ticket/docs/AI_RULES.md) - Quy định an toàn thông tin & bảo mật mật khẩu
