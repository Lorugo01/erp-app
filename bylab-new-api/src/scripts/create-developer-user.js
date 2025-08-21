const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function createDeveloperUser() {
  try {
    console.log('Criando usuário desenvolvedor...');
    
    // Primeiro, vamos verificar se o role DEVELOPER existe
    const roles = await prisma.$queryRaw`
      SELECT unnest(enum_range(NULL::"Role")) as role;
    `;
    
    console.log('Roles disponíveis:', roles);
    
    // Criar usuário desenvolvedor
    const developer = await prisma.user.create({
      data: {
        email: 'dev@bylab.com',
        password: '$2b$10$example.hash.here', // senha: dev123
        role: 'DEVELOPER',
        schoolId: 'default-school-id',
      },
    });

    console.log('✅ Desenvolvedor criado com sucesso:', developer);
    
  } catch (error) {
    console.error('❌ Erro:', error);
  } finally {
    await prisma.$disconnect();
  }
}

createDeveloperUser();
