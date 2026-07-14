# BỘ DỮ LIỆU DEMO THÊM PHIM MỚI (FOR DEMO DAY)

Tài liệu này chứa bộ dữ liệu mẫu chi tiết (gồm Text Form và SQL) của 2 bộ phim bom tấn để phục vụ việc demo tính năng **Thêm phim mới** và kiểm tra trạng thái **Đang chiếu (NOW_SHOWING) / Sắp chiếu (COMING_SOON)**.

---

## 🎬 PHIM 1: DEADPOOL & WOLVERINE (Đang chiếu - NOW_SHOWING)

### 📋 Dữ liệu nhập Form Admin

* **Tên phim (Title):** `Deadpool & Wolverine`
* **Thể loại (Genre):** `Hành động, Hài hước, Viễn tưởng`
* **Thời lượng (Duration):** `128`
* **Đạo diễn (Director):** `Shawn Levy`
* **Diễn viên (Cast):** `Ryan Reynolds, Hugh Jackman, Emma Corrin, Morena Baccarin`
* **Độ tuổi (Age Rating):** `C18`
* **Ngày phát hành (Release Date):** `2026-07-27`
* **Trạng thái (Status):** `NOW_SHOWING`
* **Điểm số (Rating):** `8.8`
* **Poster URL (Hình ảnh):** 
  `https://img.phimtv.cv/images/deadpool-va-wolverine/gKjB6s1sElrjr2giLiXbaUsGOUU.jpg`
* **Trailer URL (YouTube):** 
  `https://www.youtube.com/watch?v=73_1biulkYg`
* **Mô tả (Description):** 
  `Wolverine đang hồi phục sau những chấn thương thì anh tình cờ gặp Deadpool, người đã du hành thời gian để tìm kiếm sự giúp đỡ nhằm đánh bại một kẻ thù chung. Họ bắt buộc phải hợp tác với nhau trong một sứ mệnh đầy điên rồ để giải cứu đa vũ trụ.`

---

## 🎬 PHIM 2: SPIDER-MAN: BEYOND THE SPIDER-VERSE (Sắp chiếu - COMING_SOON)

### 📋 Dữ liệu nhập Form Admin

* **Tên phim (Title):** `Spider-Man: Beyond the Spider-Verse`
* **Thể loại (Genre):** `Hoạt hình, Hành động, Phiêu lưu, Viễn tưởng`
* **Thời lượng (Duration):** `140`
* **Đạo diễn (Director):** `Joaquim Dos Santos, Kemp Powers`
* **Diễn viên (Cast):** `Shameik Moore, Hailee Steinfeld, Oscar Isaac, Jason Schwartzman`
* **Độ tuổi (Age Rating):** `C13`
* **Ngày phát hành (Release Date):** `2026-12-18`
* **Trạng thái (Status):** `COMING_SOON`
* **Điểm số (Rating):** `9.2`
* **Poster URL (Hình ảnh):** 
  `https://tse3.mm.bing.net/th/id/OIP.bjwstJSnsBzjCXvtwdi1swAAAA?r=0&w=344&h=510&rs=1&pid=ImgDetMain&o=7&rm=3`
* **Trailer URL (YouTube):** 
  `https://www.youtube.com/watch?v=g4H129N5Gbg`
* **Mô tả (Description):** 
  `Hành trình tiếp theo của Miles Morales khi cậu phải đối mặt với phiên bản đen tối của chính mình ở Trái Đất 42. Cùng với Gwen Stacy và một biệt đội Nhện mới, Miles phải tìm cách cứu gia đình mình và toàn bộ mạng lưới đa vũ trụ khỏi âm mưu hủy diệt của The Spot.`

---

## 💻 SQL Script (Chèn trực tiếp bằng Database SQL Editor)

Nếu muốn chèn trực tiếp bằng SQL để test nhanh, anh hãy copy và chạy câu lệnh dưới đây trong Supabase SQL Editor:

```sql
INSERT INTO movies (title, description, poster_url, trailer_url, duration, age_rating, genre, director, "cast", release_date, status, rating)
VALUES
(
  'Deadpool & Wolverine',
  'Wolverine đang hồi phục sau những chấn thương thì anh tình cờ gặp Deadpool, người đã du hành thời gian để tìm kiếm sự giúp đỡ nhằm đánh bại một kẻ thù chung. Họ bắt buộc phải hợp tác với nhau trong một sứ mệnh đầy điên rồ để giải cứu đa vũ trụ.',
  'https://tse3.mm.bing.net/th/id/OIP.4yQYvE2_c3_FwG2Wc-g-0AHaK1?pid=ImgDetMain',
  'https://www.youtube.com/watch?v=73_1biulkYg',
  128,
  'C18',
  'Hành động, Hài hước, Viễn tưởng',
  'Shawn Levy',
  'Ryan Reynolds, Hugh Jackman, Emma Corrin, Morena Baccarin',
  '2026-07-27',
  'NOW_SHOWING',
  8.8
),
(
  'Spider-Man: Beyond the Spider-Verse',
  'Hành trình tiếp theo của Miles Morales khi cậu phải đối mặt với phiên bản đen tối của chính mình ở Trái Đất 42. Cùng với Gwen Stacy và một biệt đội Nhện mới, Miles phải tìm cách cứu gia đình mình và toàn bộ mạng lưới đa vũ trụ khỏi âm mưu hủy diệt của The Spot.',
  'https://tse2.mm.bing.net/th/id/OIP.x_9G8V-n7DkXUv9XqG7L2AHaJ4?pid=ImgDetMain',
  'https://www.youtube.com/watch?v=g4H129N5Gbg',
  140,
  'C13',
  'Hoạt hình, Hành động, Phiêu lưu, Viễn tưởng',
  'Joaquim Dos Santos, Kemp Powers',
  'Shameik Moore, Hailee Steinfeld, Oscar Isaac, Jason Schwartzman',
  '2026-12-18',
  'COMING_SOON',
  9.2
);
```
