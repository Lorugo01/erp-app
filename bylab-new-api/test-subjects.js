const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function testSubjects() {
  try {
    console.log('🔍 Testando conexão com banco...');
    
    // Verificar se a tabela existe e tem dados
    const subjects = await prisma.subjectType.findMany();
    console.log('✅ Tabela SubjectType encontrada');
    console.log(`📊 Quantidade de disciplinas: ${subjects.length}`);
    
    if (subjects.length > 0) {
      console.log('📝 Primeira disciplina:', subjects[0]);
    } else {
      console.log('⚠️ Nenhuma disciplina encontrada na tabela');
    }
    
  } catch (error) {
    console.error('❌ Erro:', error);
  } finally {
    await prisma.$disconnect();
  }
}

testSubjects();
