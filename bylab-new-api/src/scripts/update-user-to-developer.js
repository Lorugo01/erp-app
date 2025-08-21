const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function updateUserToDeveloper() {
  try {
    console.log('Atualizando usuário para DEVELOPER...');
    
    // Buscar o usuário pelo email
    const user = await prisma.user.findUnique({
      where: { email: 'dev@bylab.com' },
    });

    if (!user) {
      console.log('❌ Usuário dev@bylab.com não encontrado');
      return;
    }

    console.log('Usuário encontrado:', user);

    // Atualizar para role DEVELOPER
    const updatedUser = await prisma.user.update({
      where: { email: 'dev@bylab.com' },
      data: { role: 'DEVELOPER' },
    });

    console.log('✅ Usuário atualizado para DEVELOPER:', updatedUser);
    
  } catch (error) {
    console.error('❌ Erro:', error);
  } finally {
    await prisma.$disconnect();
  }
}

updateUserToDeveloper();
