# Hướng Dẫn Thuyết Trình Đồ Án (Slide Outline & Q&A Guide)

Tài liệu này cung cấp cấu trúc Slide, kịch bản thuyết trình (khoảng 10-15 phút) và bộ câu hỏi phản biện của Giảng viên kèm gợi ý trả lời mẫu để nhóm đạt điểm tối đa.

---

## 📊 PHẦN 1: DÀN Ý CHI TIẾT 8 SLIDE THUYẾT TRÌNH

### Slide 1: Giới thiệu Đề tài & Thành viên
*   **Tiêu đề**: Ứng Dụng Đặt Vé Xem Phim Tích Hợp Hệ Thống Bảo Mật Tài Khoản (Movie Ticket Booking App with Account Security).
*   **Nội dung**: Tên đề tài, Tên các thành viên trong nhóm, Giảng viên hướng dẫn.
*   **Ý tưởng nói**: Giới thiệu ngắn gọn thành viên và nhấn mạnh: Đề tài của nhóm là ứng dụng đặt vé xem phim hoàn chỉnh nhưng tập trung sâu vào phân hệ **Bảo mật tài khoản** theo tiêu chuẩn hiện đại để bảo vệ quyền lợi người dùng và thông tin giao dịch đặt vé.

### Slide 2: Đặt vấn đề & Các mối đe dọa (Why Security?)
*   **Nội dung**: Các lỗ hổng bảo mật phổ biến trong ứng dụng đặt vé:
    *   Tấn công brute-force dò mật khẩu liên tục.
    *   Lộ cơ sở dữ liệu làm rò rỉ mật khẩu thô của khách hàng.
    *   Đăng nhập trái phép từ thiết bị lạ để chiếm đoạt vé hoặc thông tin cá nhân.
    *   Kẻ xấu đánh cắp phiên đăng nhập (Session Hijacking).
*   **Ý tưởng nói**: Chỉ ra rằng việc bảo mật tài khoản không chỉ là đăng nhập/đăng ký thông thường mà cần có các giải pháp chống tấn công chủ động để bảo vệ người dùng trước các nguy cơ thực tế.

### Slide 3: Giải pháp kiến trúc hệ thống (Technical Stack)
*   **Nội dung**: Sơ đồ Stack công nghệ của dự án:
    *   **Mobile Client**: Flutter (Material 3 UI, thư viện Dio kết nối API, `flutter_secure_storage` để lưu token bảo mật).
    *   **Backend API**: Node.js Express + Prisma ORM.
    *   **Database**: MySQL chạy qua Docker Compose.
*   **Ý tưởng nói**: Nhóm sử dụng mô hình Client-Server. Backend viết trên Node.js dùng Prisma giúp chống SQL Injection, Client viết bằng Flutter đảm bảo giao diện Material 3 trực quan và bảo mật thiết bị tốt.

### Slide 4: Các tính năng bảo mật đắt giá (Core Security Features)
*   **Nội dung**: Liệt kê 6 lá chắn bảo mật của hệ thống:
    1.  Mã hóa mật khẩu bằng thuật toán **Argon2id**.
    2.  Tự động **khóa tài khoản tạm thời 5 phút** khi nhập sai mật khẩu 5 lần.
    3.  **Xác minh Email / SĐT** qua mã xác thực 6 số có hạn dùng và cooldown chống spam.
    4.  **Xác thực 2 yếu tố (2FA)** yêu cầu OTP đăng nhập.
    5.  **Phát hiện đăng nhập thiết bị lạ** và ghi lịch sử đăng nhập chi tiết.
    6.  **Security Dashboard** chấm điểm bảo mật (Security Score) trực quan.

### Slide 5: Biểu đồ luồng Đăng nhập xác thực 2 lớp (2FA Sequence Flow)
*   **Nội dung**: Đưa sơ đồ Sequence Diagram (từ file hướng dẫn bảo mật) lên slide.
*   **Ý tưởng nói**: Trình bày rõ ràng cơ chế rẽ nhánh: Khi user nhập đúng mật khẩu, hệ thống kiểm tra 2FA. Nếu bật 2FA, hệ thống chưa cấp Token đăng nhập ngay mà bắt buộc qua bước kiểm tra OTP thứ hai để ngăn ngừa mất tài khoản kể cả khi lộ mật khẩu.

### Slide 6: Demo thực tế ứng dụng (Live Demo)
*   **Nội dung**: Các bước sẽ demo trực tiếp cho Giảng viên xem:
    1.  Đăng ký tài khoản $\rightarrow$ Lấy mã verify email từ console/email thật để kích hoạt tài khoản.
    2.  Đăng nhập lần đầu $\rightarrow$ Show trang Security Dashboard với Điểm bảo mật ban đầu (thấp do chưa bật 2FA).
    3.  Bật tính năng 2FA $\rightarrow$ Điểm bảo mật tăng lên.
    4.  Đăng xuất $\rightarrow$ Đăng nhập lại để chứng minh luồng yêu cầu nhập mã OTP thứ 2.
    5.  Demo tính năng khóa tài khoản (nhập sai mật khẩu liên tiếp 5 lần).

### Slide 7: Kế hoạch mở rộng (Phase 2 - Movie Booking)
*   **Nội dung**:
    *   Triển khai phân hệ đặt vé: Danh sách phim, lịch chiếu, chọn ghế rạp phim.
    *   Thanh toán giả lập (Demo Payment) và xuất vé điện tử kèm mã QR.
*   **Ý tưởng nói**: Khẳng định dự án đang đi đúng tiến độ Phase 1 (Bảo mật tài khoản), sẵn sàng tích hợp các tính năng đặt vé và thanh toán ở giai đoạn tiếp theo.

### Slide 8: Lời cảm ơn & Q&A
*   **Nội dung**: Lời cảm ơn thầy cô và các bạn đã lắng nghe. Mở đầu phần Hỏi - Đáp.

---

## 🎤 PHẦN 2: BỘ CÂU HỎI PHẢN BIỆN THƯỜNG GẶP CỦA GIẢNG VIÊN

Hội đồng chấm đồ án thường sẽ xoáy sâu vào khía cạnh kỹ thuật bảo mật. Nhóm hãy chuẩn bị kỹ các câu trả lời dưới đây:

### ❓ Câu 1: Tại sao nhóm sử dụng Argon2id để hash mật khẩu mà không dùng Bcrypt hay MD5/SHA-256 thông thường?
*   **Trả lời**: 
    *   **MD5/SHA-256** là các hàm băm tốc độ cao, cực kỳ dễ bị tấn công giải mã bằng bảng tra cứu (Rainbow Table) hoặc chạy song song trên GPU/ASIC để bẻ khóa hàng triệu mật khẩu mỗi giây.
    *   **Bcrypt** là thuật toán tốt, tuy nhiên nó chỉ kiểm soát độ khó bằng chi phí thời gian (Time Cost/Work Factor) và không thể chống lại hiệu quả các hệ thống bẻ khóa phần cứng lớn (như chip ASIC hoặc giàn GPU lớn của kẻ tấn công).
    *   **Argon2id** là thuật toán thắng giải *Password Hashing Competition (PHC)*. Nó có 3 tham số cấu hình: **Time Cost** (thời gian), **Parallelism** (số luồng song song) và **Memory Cost** (lượng RAM sử dụng - nhóm cấu hình là 64MB). Việc yêu cầu bộ nhớ RAM lớn khiến kẻ tấn công không thể sử dụng năng lực tính toán cực nhanh của GPU hay chip ASIC để bẻ khóa mật khẩu hàng loạt, đảm bảo an toàn tuyệt đối ngay cả khi bị rò rỉ database.

### ❓ Câu 2: Làm sao hệ thống nhận diện được đó là đăng nhập từ "Thiết bị lạ"?
*   **Trả lời**:
    *   Khi người dùng đăng nhập trên ứng dụng Flutter, ứng dụng sẽ lấy thông tin tên thiết bị của người dùng (ví dụ thông qua thư viện `device_info_plus` hoặc phân tích môi trường chạy để gửi trường `deviceName` như `"Android Device"`, `"iOS Device"`, `"Windows App"`,...).
    *   Backend Node.js khi nhận request đăng nhập thành công sẽ truy vấn bảng `login_history` của tài khoản này để lấy danh sách tất cả các `deviceName` đã từng đăng nhập thành công trước đó.
    *   Nếu `deviceName` gửi lên hiện tại không nằm trong danh sách các thiết bị tin cậy trước đây, Backend sẽ tự động gắn cờ `suspicious: true` vào bản ghi lịch sử mới, đồng thời tạo ra một `SecurityAlert` kiểu `SUSPICIOUS_LOGIN` và gửi email cảnh báo cho người dùng.

### ❓ Câu 3: Điểm bảo mật (Security Score) được tính toán như thế nào? Điểm này lưu ở bảng nào trong database?
*   **Trả lời**:
    *   Điểm bảo mật **không được lưu trực tiếp** vào database để tránh việc dữ liệu bị sai lệch hoặc không đồng bộ. Thay vào đó, điểm này được **tính toán động theo thời gian thực** mỗi khi người dùng truy cập trang Dashboard.
    *   Mỗi khi gọi API `/security/dashboard`, Backend sẽ lấy thông tin cấu hình tài khoản (Đã xác minh email/sđt chưa, có bật 2FA không, có lịch sử đăng nhập đáng ngờ nào không,...) rồi tính toán từ mốc **100 điểm** ban đầu, trừ dần theo mức độ rủi ro (Ví dụ: Chưa xác minh email -30đ, Chưa bật 2FA -20đ,...). Việc tính toán động giúp điểm số luôn phản ánh chính xác nhất trạng thái an toàn hiện thời của tài khoản.

### ❓ Câu 4: Nhóm lưu trữ JWT Token dưới Client Flutter như thế nào để đảm bảo hacker không lấy trộm được?
*   **Trả lời**:
    *   Nhóm **không sử dụng `SharedPreferences`** để lưu Access Token và Refresh Token, vì SharedPreferences chỉ lưu dữ liệu dạng file XML thô không mã hóa trên bộ nhớ máy, hacker có thể dễ dàng đọc được nếu thiết bị bị root/jailbreak.
    *   Thay vào đó, nhóm sử dụng thư viện `flutter_secure_storage`. Thư viện này tự động sử dụng phân hệ bảo mật phần cứng của hệ điều hành: **Keystore** trên Android và **Keychain** trên iOS để mã hóa toàn bộ dữ liệu token trước khi ghi xuống bộ nhớ của máy điện thoại. Kẻ xấu hoặc các ứng dụng độc hại khác không thể truy cập trái phép vào các token này.

### ❓ Câu 5: Tại sao trong bảng `refresh_tokens` lại chỉ lưu `tokenHash` thay vì lưu token gốc?
*   **Trả lời**:
    *   Refresh Token có thời hạn sống dài (trong dự án cấu hình là 7 ngày). Nếu kẻ tấn công có quyền truy cập vào database (SQL Injection hoặc rò rỉ file backup) và đọc được Refresh Token thô, chúng có thể sử dụng nó để tự cấp mới Access Token và chiếm đoạt vĩnh viễn phiên làm việc của người dùng.
    *   Vì vậy, nhóm chỉ lưu chuỗi băm **SHA-256** của Refresh Token (`tokenHash`). Khi người dùng gửi Refresh Token thô lên để gia hạn, backend sẽ băm mã đó rồi đối chiếu với database. Cách làm này đảm bảo dù database có bị lộ hoàn toàn, hacker cũng không thể lấy được Refresh Token thô của bất kỳ người dùng nào đang hoạt động.
