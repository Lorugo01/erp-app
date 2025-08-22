const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcrypt');

const prisma = new PrismaClient();

async function createDeveloperUser() {
  try {
    console.log('Criando usuário desenvolvedor...');
    
    // Primeiro, vamos verificar se o role DEVELOPER existe
    const roles = await prisma.$queryRaw`
      SELECT unnest(enum_range(NULL::"Role")) as role;
    `;
    
    console.log('Roles disponíveis:', roles);
    
    // Verificar se já existe um usuário com este email
    const existingUser = await prisma.user.findUnique({
      where: { email: 'dev@bylab.com' }
    });
    
    if (existingUser) {
      console.log('⚠️ Usuário dev@bylab.com já existe. Atualizando para DEVELOPER...');
      
      const updatedUser = await prisma.user.update({
        where: { email: 'dev@bylab.com' },
        data: { 
          role: 'DEVELOPER',
          schoolId: null // DEVELOPER não precisa de escola
        },
      });
      
      console.log('✅ Usuário atualizado para DEVELOPER:', updatedUser);
      return;
    }
    
    // Criar hash da senha (dev123)
    const hashedPassword = await bcrypt.hash('dev123', 10);
    
    // Criar usuário desenvolvedor
    const developer = await prisma.user.create({
      data: {
        email: 'dev@bylab.com',
        password: hashedPassword,
        role: 'DEVELOPER',
        schoolId: null, // DEVELOPER não precisa de escola
      },
    });

    console.log('✅ Desenvolvedor criado com sucesso!');
    console.log('📧 Email: dev@bylab.com');
    console.log('🔑 Senha: dev123');
    console.log('👤 Role: DEVELOPER');
    console.log('🏫 Escola: Nenhuma (acesso global)');
    
  } catch (error) {
    console.error('❌ Erro:', error);
  } finally {
    await prisma.$disconnect();
  }
}

createDeveloperUser();
