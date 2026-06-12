// ============================================
// Seed Data
// Tạo dữ liệu mẫu: phim, rạp, phòng, ghế, lịch chiếu
// Chạy: node prisma/seed.js
// ============================================
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Seeding database...\n');

  // ===================== MOVIES =====================
  console.log('🎬 Creating movies...');

  const movies = await Promise.all([
    prisma.movie.create({
      data: {
        title: 'Avengers: Doomsday',
        description: 'The Avengers must assemble once more to face their most dangerous threat yet - Doctor Doom, who wields unimaginable power that threatens to unravel the very fabric of the multiverse.',
        posterUrl: 'https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/f/2e317a1c-f1ce-4a5f-90db-d88cc01db2d0/djyh7h2-d0dd3eb7-ade6-4245-ad14-f843b4cf7df2.png/v1/fill/w_1280,h_2027,q_80,strp/avengers_doomsday_poster_hd_2027_4k_by_mrandrew7w7_djyh7h2-fullview.jpg?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1cm46YXBwOjdlMGQxODg5ODIyNjQzNzNhNWYwZDQxNWVhMGQyNmUwIiwiaXNzIjoidXJuOmFwcDo3ZTBkMTg4OTgyMjY0MzczYTVmMGQ0MTVlYTBkMjZlMCIsIm9iaiI6W1t7ImhlaWdodCI6Ijw9MjAyNyIsInBhdGgiOiJcL2ZcLzJlMzE3YTFjLWYxY2UtNGE1Zi05MGRiLWQ4OGNjMDFkYjJkMFwvZGp5aDdoMi1kMGRkM2ViNy1hZGU2LTQyNDUtYWQxNC1mODQzYjRjZjdkZjIucG5nIiwid2lkdGgiOiI8PTEyODAifV1dLCJhdWQiOlsidXJuOnNlcnZpY2U6aW1hZ2Uub3BlcmF0aW9ucyJdfQ.F0tPUEt8UhfhosZKOzP0IZAPNtpsQKR-ZKR0RKiukQQ',
        trailerUrl: 'https://youtube.com/watch?v=example1',
        duration: 150,
        ageRating: 'C13',
        genre: 'Action, Sci-Fi, Adventure',
        director: 'Joe Russo, Anthony Russo',
        cast: 'Robert Downey Jr., Chris Evans, Scarlett Johansson',
        releaseDate: new Date('2026-05-01'),
        status: 'NOW_SHOWING',
        rating: 8.5,
      },
    }),
    prisma.movie.create({
      data: {
        title: 'Inside Out 3',
        description: 'Riley is now in college and encounters a whole new set of emotions as she navigates adult life, friendships, and the challenges of growing up.',
        posterUrl: 'https://tse2.mm.bing.net/th/id/OIP.23N9PBfGye0SMsaYqGHX9QHaJ4?r=0&rs=1&pid=ImgDetMain&o=7&rm=3',
        duration: 105,
        ageRating: 'P',
        genre: 'Animation, Comedy, Family',
        director: 'Kelsey Mann',
        cast: 'Amy Poehler, Phyllis Smith, Lewis Black',
        releaseDate: new Date('2026-06-20'),
        status: 'NOW_SHOWING',
        rating: 8.2,
      },
    }),
    prisma.movie.create({
      data: {
        title: 'The Batman 2',
        description: 'Bruce Wayne continues his crusade against crime in Gotham City, facing a new villain who threatens to expose the dark secrets of the Wayne family.',
        posterUrl: 'https://tse1.mm.bing.net/th/id/OIP.iIIjvG_ZpyoZA_ex8hmwwwHaKb?r=0&rs=1&pid=ImgDetMain&o=7&rm=3',
        trailerUrl: 'https://youtube.com/watch?v=example3',
        duration: 165,
        ageRating: 'C16',
        genre: 'Action, Crime, Drama',
        director: 'Matt Reeves',
        cast: 'Robert Pattinson, Zoë Kravitz, Colin Farrell',
        releaseDate: new Date('2026-07-15'),
        status: 'COMING_SOON',
        rating: 0,
      },
    }),
    prisma.movie.create({
      data: {
        title: 'Spirited Away 2: Return to the Spirit World',
        description: 'Chihiro, now an adult, is mysteriously drawn back to the spirit world when strange events begin occurring in the real world.',
        posterUrl: 'https://musicart.xboxlive.com/7/aa355100-0000-0000-0000-000000000002/504/image.jpg?w=1920&h=1080',
        duration: 130,
        ageRating: 'P',
        genre: 'Animation, Fantasy, Adventure',
        director: 'Hayao Miyazaki',
        cast: 'Rumi Hiiragi, Miyu Irino',
        releaseDate: new Date('2026-06-01'),
        status: 'NOW_SHOWING',
        rating: 9.0,
      },
    }),
    prisma.movie.create({
      data: {
        title: 'Fast & Furious 11',
        description: 'Dom Toretto and his family face their ultimate challenge as a global conspiracy threatens everything they have built.',
        posterUrl: 'https://th.bing.com/th/id/R.df69bcfaab035f431d8bc7ed1abf0b40?rik=TVbgQr0ELDnXZw&pid=ImgRaw&r=0',
        duration: 140,
        ageRating: 'C13',
        genre: 'Action, Thriller',
        director: 'Louis Leterrier',
        cast: 'Vin Diesel, Michelle Rodriguez, Jason Momoa',
        releaseDate: new Date('2026-08-01'),
        status: 'COMING_SOON',
        rating: 0,
      },
    }),
    prisma.movie.create({
      data: {
        title: 'Doraemon: Nobita và Cuộc Phiêu Lưu Vũ Trụ',
        description: 'Nobita và nhóm bạn cùng Doraemon khám phá một hành tinh bí ẩn nơi có một nền văn minh cổ đại đang đối mặt với nguy hiểm.',
        posterUrl: 'https://i.vietgiaitri.com/2022/4/28/phim-dien-anh-doraemon-nobita-va-cuoc-chien-vu-tru-ti-hon-2021-san-sang-ra-mat-mua-he-nay-e19-6423605.png',
        duration: 100,
        ageRating: 'P',
        genre: 'Animation, Adventure, Comedy',
        director: 'Shinnosuke Yakuwa',
        cast: 'Wasabi Mizuta, Megumi Ohara',
        releaseDate: new Date('2026-05-25'),
        status: 'NOW_SHOWING',
        rating: 7.8,
      },
    }),
  ]);

  console.log(`   ✅ Created ${movies.length} movies`);

  // ===================== CINEMAS =====================
  console.log('🏢 Creating cinemas...');

  const cinemas = await Promise.all([
    prisma.cinema.create({
      data: {
        name: 'CGV Vincom Center',
        address: '72 Lê Thánh Tôn, Quận 1',
        city: 'Hồ Chí Minh',
        imageUrl: 'https://citytowerbinhduong.com/wp-content/uploads/2025/10/rap-cgv-vincom-center-landmark-81-hien-dai.jpg',
      },
    }),
    prisma.cinema.create({
      data: {
        name: 'Lotte Cinema Nowzone',
        address: '235 Nguyễn Văn Cừ, Quận 1',
        city: 'Hồ Chí Minh',
        imageUrl: 'https://toplist.vn/images/800px/lotte-cinema-nowzone-1000919.jpg',
      },
    }),
    prisma.cinema.create({
      data: {
        name: 'Galaxy Cinema Nguyễn Du',
        address: '116 Nguyễn Du, Quận 1',
        city: 'Hồ Chí Minh',
        imageUrl: 'https://tse3.mm.bing.net/th/id/OIP.6VROMp0ml2_9LxW4zklTFwHaE8?r=0&rs=1&pid=ImgDetMain&o=7&rm=3',
      },
    }),
  ]);

  console.log(`   ✅ Created ${cinemas.length} cinemas`);

  // ===================== ROOMS =====================
  console.log('🎭 Creating rooms...');

  const rooms = [];
  for (const cinema of cinemas) {
    const roomsData = [
      { name: 'Room 1', totalSeats: 80 },
      { name: 'Room 2', totalSeats: 60 },
      { name: 'IMAX', totalSeats: 120 },
    ];

    for (const roomData of roomsData) {
      const room = await prisma.room.create({
        data: {
          cinemaId: cinema.id,
          name: roomData.name,
          totalSeats: roomData.totalSeats,
        },
      });
      rooms.push(room);
    }
  }

  console.log(`   ✅ Created ${rooms.length} rooms`);

  // ===================== SEATS =====================
  console.log('💺 Creating seats...');

  let totalSeats = 0;
  for (const room of rooms) {
    const rows = room.totalSeats <= 60 ? ['A', 'B', 'C', 'D', 'E', 'F']
      : room.totalSeats <= 80 ? ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H']
        : ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'];
    const seatsPerRow = Math.ceil(room.totalSeats / rows.length);

    const seatsData = [];
    for (const row of rows) {
      for (let num = 1; num <= seatsPerRow; num++) {
        let type = 'STANDARD';
        // Hàng cuối cùng là VIP
        if (row === rows[rows.length - 1] || row === rows[rows.length - 2]) {
          type = 'VIP';
        }
        // Ghế cặp ở hàng cuối
        if (row === rows[rows.length - 1] && num % 2 === 0 && num > seatsPerRow - 4) {
          type = 'COUPLE';
        }

        seatsData.push({
          roomId: room.id,
          row,
          number: num,
          type,
          status: 'AVAILABLE',
        });
      }
    }

    await prisma.seat.createMany({ data: seatsData });
    totalSeats += seatsData.length;
  }

  console.log(`   ✅ Created ${totalSeats} seats`);

  // ===================== SHOWTIMES =====================
  console.log('🕐 Creating showtimes...');

  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  let showtimeCount = 0;

  // Tạo lịch chiếu cho 3 ngày tới
  const nowShowingMovies = movies.filter(m => m.status === 'NOW_SHOWING');

  for (let dayOffset = 0; dayOffset < 3; dayOffset++) {
    const date = new Date(today);
    date.setDate(date.getDate() + dayOffset);

    for (const movie of nowShowingMovies) {
      // Mỗi phim chiếu ở 2 rạp khác nhau
      const selectedRooms = rooms.slice(dayOffset * 3, dayOffset * 3 + 2);

      for (const room of selectedRooms) {
        const times = ['09:00', '13:00', '16:30', '19:30', '22:00'];

        for (const time of times) {
          const [hours, minutes] = time.split(':').map(Number);
          const startTime = new Date(date);
          startTime.setHours(hours, minutes, 0, 0);

          // Bỏ qua suất đã qua
          if (startTime < now) continue;

          const endTime = new Date(startTime);
          endTime.setMinutes(endTime.getMinutes() + movie.duration + 15); // +15 phút nghỉ

          // Giá vé: 75k - 120k tùy giờ
          let price = 75000;
          if (hours >= 17) price = 95000;
          if (hours >= 19) price = 120000;
          if (room.name === 'IMAX') price += 30000;

          await prisma.showtime.create({
            data: {
              movieId: movie.id,
              roomId: room.id,
              startTime,
              endTime,
              price,
            },
          });
          showtimeCount++;
        }
      }
    }
  }

  console.log(`   ✅ Created ${showtimeCount} showtimes`);

  // ===================== PROMOTIONS =====================
  console.log('🎁 Creating promotions...');

  await prisma.promotion.createMany({
    data: [
      {
        code: 'WELCOME10',
        discountPercent: 10,
        maxDiscount: 30000,
        minPurchase: 100000,
        startDate: new Date('2026-01-01'),
        endDate: new Date('2026-12-31'),
        active: true,
        usageLimit: 1000,
      },
      {
        code: 'STUDENT20',
        discountPercent: 20,
        maxDiscount: 50000,
        minPurchase: 75000,
        startDate: new Date('2026-01-01'),
        endDate: new Date('2026-12-31'),
        active: true,
        usageLimit: 500,
      },
      {
        code: 'WEEKEND15',
        discountPercent: 15,
        maxDiscount: 40000,
        startDate: new Date('2026-06-01'),
        endDate: new Date('2026-08-31'),
        active: true,
      },
    ],
  });

  console.log('   ✅ Created 3 promotions');

  // ===================== ADMIN USER =====================
  console.log('👤 Creating admin user...');

  const argon2 = require('argon2');
  const adminPassword = await argon2.hash('Admin@123', {
    type: argon2.argon2id,
    memoryCost: 65536,
    timeCost: 3,
    parallelism: 4,
  });

  await prisma.user.upsert({
    where: { email: 'admin@movieapp.com' },
    update: {},
    create: {
      name: 'Admin',
      email: 'admin@movieapp.com',
      passwordHash: adminPassword,
      emailVerified: true,
      role: 'ADMIN',
    },
  });

  console.log('   ✅ Admin user created (admin@movieapp.com / Admin@123)');

  console.log('\n🎉 Seeding completed successfully!\n');
}

main()
  .catch((e) => {
    console.error('❌ Seed error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
