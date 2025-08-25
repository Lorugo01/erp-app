const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function setupDefaultConfig() {
  try {
    console.log('🔧 Configurando valores padrão...');
    
    // Verificar se já existe configuração
    const existingConfig = await prisma.config.findFirst();
    
    if (existingConfig) {
      console.log('✅ Configuração já existe:', existingConfig);
      return;
    }

    // Criar configuração padrão
    const config = await prisma.config.create({
      data: {
        id: 1,
        evaluationModel: 'TRADICIONAL',
        minGrade: 5.0,
        minAttendance: 75.0
      }
    });

    console.log('✅ Configuração padrão criada:', config);

  } catch (error) {
    console.error('❌ Erro ao configurar:', error);
  } finally {
    await prisma.$disconnect();
  }
}

setupDefaultConfig();

