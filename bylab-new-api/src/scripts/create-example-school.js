const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function createExampleSchool() {
  try {
    console.log('Criando escola de exemplo...');
    
    const school = await prisma.school.create({
      data: {
        name: 'Escola Exemplo ByLAB',
        address: 'Rua das Flores, 123 - São Paulo, SP',
        phone: '(11) 3333-4444',
        email: 'contato@escolaexemplo.com',
        website: 'https://escolaexemplo.com',
      },
    });

    console.log('✅ Escola criada com sucesso:', school);
    
    // Criar um usuário admin para esta escola
    const admin = await prisma.user.create({
      data: {
        email: 'admin@escolaexemplo.com',
        password: '$2b$10$example.hash.here', // senha: admin123
        role: 'ADMIN',
        schoolId: school.id,
      },
    });

    console.log('✅ Admin criado para a escola:', admin.email);
    
  } catch (error) {
    console.error('❌ Erro:', error);
  } finally {
    await prisma.$disconnect();
  }
}

createExampleSchool();
