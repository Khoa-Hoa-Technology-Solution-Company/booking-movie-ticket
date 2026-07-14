# Cinema Security App - Design System (MASTER)

Tài liệu này là **Source of Truth** (Nguồn sự thật duy nhất) về thiết kế giao diện cho ứng dụng Đặt Vé Xem Phim & Bảo Mật Tài Khoản (Flutter + Supabase). Các quyết định về màu sắc, kiểu chữ, khoảng cách và hành vi tương tác (UX) phải tuân theo các chỉ dẫn dưới đây.

---

## 1. Hệ Màu Sắc (Color Palette) - Obsidian Cinema Theme

Hệ màu được lấy cảm hứng từ không gian rạp chiếu phim hiện đại (nền tối huyền bí kết hợp với các dải đèn neon tương phản cao).

| Vai trò | Mã màu HEX | Tên màu | Mục đích sử dụng |
| :--- | :--- | :--- | :--- |
| **Primary (Chính)** | `0xFFC084FC` | Neon Lavender | Nút bấm chính, viền tiêu điểm, tiêu đề đặc sắc, biểu tượng active. |
| **Secondary (Phụ)** | `0xFF8B5CF6` | Royal Violet | Gradient nút bấm, thanh tiến trình, tiêu đề phụ. |
| **Accent (Điểm nhấn)** | `0xFFF59E0B` | Golden Amber | Đánh giá sao, ghế VIP, thông báo khẩn cấp, vé được chọn. |
| **Success (Thành công)** | `0xFF10B981` | Emerald Green | Ghế đang chọn, thông báo thanh toán thành công, mã QR vé. |
| **Danger (Nguy hiểm)** | `0xFFEF4444` | Crimson Red | Ghế đôi (Couple), hủy đặt vé, lỗi bảo mật, đăng xuất. |
| **Background (Nền ứng dụng)** | `0xFF0F0F1A` | Obsidian Black | Nền sâu của toàn bộ ứng dụng (tránh dùng màu đen tuyền `#000000`). |
| **Surface (Bề mặt thẻ)** | `0xFF16162A` | Deep Indigo Surface | Nền của các thẻ (Card), Bottom Sheet, Hộp thoại và thanh AppBar. |
| **Border (Đường viền)** | `0x15FFFFFF` | Translucent White | Viền kính (Glassmorphism), phân chia các khu vực nhẹ nhàng. |

---

## 2. Hệ Thống Kiểu Chữ (Typography)

* **Font chữ chính:** `Outfit` hoặc `Inter` (Sans-serif hình học hiện đại, hiển thị xuất sắc trên màn hình di động).
* **Font chữ kỹ thuật:** `Roboto Mono` hoặc `Courier New` (sử dụng cho các dãy số ghế, mã đặt vé, mã OTP bảo mật, thời gian suất chiếu).

### Phân cấp cỡ chữ (Typography Scale):
1. **Title Large:** `24pt`, Bold, Line-height: `1.2` (Tên phim, Tên rạp lớn).
2. **Title Medium:** `18pt`, SemiBold, Line-height: `1.3` (Tiêu đề các phân mục: Chọn ghế, Chọn bắp nước).
3. **Body Text:** `14pt`, Regular, Line-height: `1.4`, Color: `Colors.white70` (Mô tả phim, thông tin suất chiếu).
4. **Caption/Technical:** `12pt`, Regular/Mono, Color: `Colors.white54` (Mã vé, Số hàng ghế, Giờ chiếu nhỏ).

---

## 3. Quy Tắc Khoảng Cách & Bố Cục (Layout & Spacing)

Tuân thủ nguyên tắc **nhịp điệu 8dp (8dp Grid System)** để tạo giao diện cân đối:
* **Gutter ngoài (Lề màn hình):** Luôn là `16dp` hoặc `20dp` (padding cho nội dung chính so với mép điện thoại).
* **Khoảng cách giữa các phần tử phụ:** `4dp` hoặc `8dp` (khoảng cách giữa icon và chữ, khoảng cách giữa các ghế).
* **Khoảng cách giữa các thẻ/nhóm:** `12dp` hoặc `16dp` (khoảng cách giữa các phim trong danh sách).
* **Khoảng cách giữa các phần lớn (Section Spacing):** `24dp` hoặc `32dp`.

### Bo góc (Border Radius):
* **Ghế ngồi:** `8dp` (tạo cảm giác mềm mại giống ghế rạp).
* **Thẻ phim / Card bắp nước:** `12dp` hoặc `16dp`.
* **Bottom Sheet thanh toán / Hộp thoại vé QR:** `24dp` (Bo hai góc trên).

---

## 4. Thiết Kế Trạng Thái Ghế Ngồi (Seat Selection UX)

Sơ đồ ghế ngồi động 2D cần tuân thủ bảng màu tương tác sau:

```
[Standard - Trống]     [VIP - Trống]         [Couple - Trống]
  Viền White54           Viền Golden Amber     Viền Crimson Red
  Nền trong suốt         Nền trong suốt        Nền trong suốt

[Đang chọn]            [Đã bán/Khóa]         [Bảo trì/Hỏng]
  Nền Emerald Green      Nền Dark Charcoal     Nền Dark Grey
  Chữ màu đen            Icon Lock             Icon Construction (Búa sửa chữa)
```

---

## 5. Hướng Dẫn Tương Tác & Phản Hồi (Interaction & Feedback)

1. **Hiệu ứng nhấn nút (Tap Feedback):** 
   * Tất cả nút bấm (`Button`, `Pressable`, `ListTile`) phải có hiệu ứng gợn sóng (Ripple) hoặc mờ dần (Opacity: `0.6`) khi chạm. Thời gian phản hồi từ `80ms` đến `150ms`.
2. **Thời gian chuyển trang (Transitions):**
   * Sử dụng hiệu ứng trượt hoặc mờ dần từ `150ms` đến `300ms`. 
3. **Diện tích chạm tối thiểu (Touch Target):**
   * Mọi phần tử click được (kể cả icon nhỏ hoặc nút tăng/giảm số lượng bắp nước) phải có kích thước vùng chạm tối thiểu là **`44x44dp`**. Nếu icon quá nhỏ, hãy sử dụng `Padding` để mở rộng vùng click mà không làm biến dạng icon.
4. **Trạng thái vô hiệu hóa (Disabled State):**
   * Nút bấm chưa chọn ghế hoặc khi đang thực hiện thanh toán phải có Opacity giảm xuống `0.4`, không nhận sự kiện click và hiển thị biểu tượng loading xoay tròn nếu đang xử lý.
