const admin = require("firebase-admin");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");

// If running in local emulator environment, set host
if (!process.env.FIRESTORE_EMULATOR_HOST) {
  process.env.FIRESTORE_EMULATOR_HOST = "localhost:8080";
  console.log("Setting FIRESTORE_EMULATOR_HOST to localhost:8080 (Emulator Mode)");
}

admin.initializeApp({
  projectId: "booking-movie-ticket-demo"
});

const db = getFirestore();

const movies = [
  {
    id: "movie_1",
    title: "Captain America: Brave New World",
    description: "Sam Wilson takes on the mantle of Captain America in this thrilling new adventure. Confronting global conspiracies and mysterious threats, he must prove what it truly means to lead with the shield.",
    posterUrl: "https://images.unsplash.com/photo-1534447677768-be436bb09401?auto=format&fit=crop&q=80&w=400",
    backdropUrl: "https://images.unsplash.com/photo-1509198397868-475647b2a1e5?auto=format&fit=crop&w=800",
    duration: 125,
    genre: "Hành Động, Viễn Tưởng",
    ageRating: "T13",
    language: "Tiếng Anh (Phụ đề Tiếng Việt)",
    releaseDate: Timestamp.fromDate(new Date()),
    status: "ACTIVE",
    rating: 8.5
  },
  {
    id: "movie_2",
    title: "Thunderbolts*",
    description: "A team of anti-heroes and reformed villains are sent on covert missions for the government, only to realize they might have been set up. Expect high-stakes action and team dynamics like never before.",
    posterUrl: "https://images.unsplash.com/photo-1569074187119-c87815b476da?auto=format&fit=crop&q=80&w=400",
    backdropUrl: "https://images.unsplash.com/photo-1534447677768-be436bb09401?auto=format&fit=crop&w=800",
    duration: 118,
    genre: "Hành Động, Phiêu Lưu",
    ageRating: "T16",
    language: "Tiếng Anh (Phụ đề Tiếng Việt)",
    releaseDate: Timestamp.fromDate(new Date()),
    status: "ACTIVE",
    rating: 8.2
  },
  {
    id: "movie_3",
    title: "Avengers: Doomsday",
    description: "The Earth's Mightiest Heroes face their ultimate challenge as a multiversal threat arises to restructure reality. A cinematic event that changes the Marvel Cinematic Universe forever.",
    posterUrl: "https://images.unsplash.com/photo-1478720568477-152d9b164e26?auto=format&fit=crop&q=80&w=400",
    backdropUrl: "https://images.unsplash.com/photo-1478720568477-152d9b164e26?auto=format&fit=crop&w=800",
    duration: 155,
    genre: "Hành Động, Khoa Học Viễn Tưởng",
    ageRating: "T13",
    language: "Tiếng Anh (Phụ đề Tiếng Việt)",
    releaseDate: Timestamp.fromDate(new Date("2026-05-01")),
    status: "COMING_SOON",
    rating: 9.0
  }
];

const cinemas = [
  {
    id: "cinema_1",
    name: "CGV Hùng Vương Plaza",
    address: "126 Hồng Bàng, Phường 12, Quận 5",
    city: "Hồ Chí Minh",
    phone: "1900 6017"
  },
  {
    id: "cinema_2",
    name: "Lotte Cinema Cantavil",
    address: "Tầng 7 Cantavil Premier, Song Hành, An Phú, Quận 2",
    city: "Hồ Chí Minh",
    phone: "028 3740 2323"
  },
  {
    id: "cinema_3",
    name: "BHD Star Cineplex Phạm Ngọc Thạch",
    address: "Tầng 8 Vincom Center, 2 Phạm Ngọc Thạch, Kim Liên, Đống Đa",
    city: "Hà Nội",
    phone: "1900 2099"
  }
];

const promotions = [
  {
    code: "WELCOME10",
    discountPercent: 10,
    startDate: Timestamp.fromDate(new Date("2026-01-01")),
    endDate: Timestamp.fromDate(new Date("2027-12-31")),
    active: true
  },
  {
    code: "SUPER20",
    discountPercent: 20,
    startDate: Timestamp.fromDate(new Date("2026-01-01")),
    endDate: Timestamp.fromDate(new Date("2027-12-31")),
    active: true
  }
];

async function seed() {
  console.log("Starting Firestore seeding...");

  // Write movies
  for (const movie of movies) {
    await db.collection("movies").doc(movie.id).set(movie);
    console.log(`Seeded movie: ${movie.title}`);
  }

  // Write cinemas
  for (const cinema of cinemas) {
    await db.collection("cinemas").doc(cinema.id).set(cinema);
    console.log(`Seeded cinema: ${cinema.name}`);
  }

  // Write promotions
  for (const promo of promotions) {
    await db.collection("promotions").doc(promo.code).set(promo);
    console.log(`Seeded promotion: ${promo.code}`);
  }

  // Generate showtimes dynamically for movies & cinemas (today/tomorrow)
  const now = new Date();
  const tomorrow = new Date();
  tomorrow.setDate(now.getDate() + 1);

  const times = [
    { startHour: 10, startMin: 0, endHour: 12, endMin: 0 },
    { startHour: 14, startMin: 30, endHour: 16, endMin: 30 },
    { startHour: 19, startMin: 0, endHour: 21, endMin: 0 },
    { startHour: 21, startMin: 30, endHour: 23, endMin: 30 }
  ];

  let showtimeCounter = 1;

  for (const movie of movies.filter(m => m.status === "ACTIVE")) {
    for (const cinema of cinemas) {
      // Seed today
      times.forEach((t, index) => {
        const startTime = new Date(now);
        startTime.setHours(t.startHour, t.startMin, 0, 0);

        const endTime = new Date(now);
        endTime.setHours(t.endHour, t.endMin, 0, 0);

        const showtimeId = `showtime_${showtimeCounter++}`;
        const showtime = {
          id: showtimeId,
          movieId: movie.id,
          roomName: `Phòng Chiếu ${index + 1}`,
          cinemaId: cinema.id,
          cinemaName: cinema.name,
          startTime: Timestamp.fromDate(startTime),
          endTime: Timestamp.fromDate(endTime),
          price: 75000,
          status: "OPEN"
        };
        db.collection("showtimes").doc(showtimeId).set(showtime);
      });

      // Seed tomorrow
      times.forEach((t, index) => {
        const startTime = new Date(tomorrow);
        startTime.setHours(t.startHour, t.startMin, 0, 0);

        const endTime = new Date(tomorrow);
        endTime.setHours(t.endHour, t.endMin, 0, 0);

        const showtimeId = `showtime_${showtimeCounter++}`;
        const showtime = {
          id: showtimeId,
          movieId: movie.id,
          roomName: `Phòng Chiếu ${index + 1}`,
          cinemaId: cinema.id,
          cinemaName: cinema.name,
          startTime: Timestamp.fromDate(startTime),
          endTime: Timestamp.fromDate(endTime),
          price: 75000,
          status: "OPEN"
        };
        db.collection("showtimes").doc(showtimeId).set(showtime);
      });
    }
  }

  console.log(`Seeded ${showtimeCounter - 1} showtimes.`);
  console.log("Firestore database seeding completed successfully!");
}

seed().catch(err => {
  console.error("Error seeding database:", err);
});
