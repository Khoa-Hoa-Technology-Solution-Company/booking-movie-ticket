const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('🧹 Deleting unverified users...');
  
  const result = await prisma.user.deleteMany({
    where: {
      emailVerified: false
    }
  });
  
  console.log(`✅ Successfully deleted ${result.count} unverified user(s).`);
}

main()
  .catch((e) => {
    console.error('❌ Error deleting users:', e);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
