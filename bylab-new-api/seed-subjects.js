const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

const defaultSubjects = [
  {
    type: 'MATEMATICA',
    description: 'Matemática básica e avançada',
    isEvaluative: true,
  },
  {
    type: 'PORTUGUES',
    description: 'Língua Portuguesa e Literatura',
    isEvaluative: true,
  },
  {
    type: 'CIENCIAS',
    description: 'Ciências Naturais',
    isEvaluative: true,
  },
  {
    type: 'HISTORIA',
    description: 'História Geral e do Brasil',
    isEvaluative: true,
  },
  {
    type: 'GEOGRAFIA',
    description: 'Geografia Geral e do Brasil',
    isEvaluative: true,
  },
  {
    type: 'EDUCACAO_FISICA',
    description: 'Educação Física e Esportes',
    isEvaluative: false,
  },
  {
    type: 'ARTE',
    description: 'Arte e Cultura',
    isEvaluative: false,
  },
  {
    type: 'LINGUA_INGLESA',
    description: 'Língua Inglesa',
    isEvaluative: true,
  },
  {
    type: 'BIOLOGIA',
    description: 'Biologia',
    isEvaluative: true,
  },
  {
    type: 'FISICA',
    description: 'Física',
    isEvaluative: true,
  },
  {
    type: 'QUIMICA',
    description: 'Química',
    isEvaluative: true,
  },
];

async function seedSubjects() {
  try {
    console.log('🌱 Iniciando seed de disciplinas...');
    
    // Verificar se já existem disciplinas
    const existingSubjects = await prisma.subjectType.findMany();
    
    if (existingSubjects.length > 0) {
      console.log(`✅ Já existem ${existingSubjects.length} disciplinas no banco`);
      return;
    }
    
    // Inserir disciplinas padrão
    const createdSubjects = await prisma.subjectType.createMany({
      data: defaultSubjects,
    });
    
    console.log(`✅ ${createdSubjects.count} disciplinas criadas com sucesso!`);
    
    // Listar disciplinas criadas
    const allSubjects = await prisma.subjectType.findMany({
      orderBy: { type: 'asc' },
    });
    
    console.log('📝 Disciplinas criadas:');
    allSubjects.forEach(subject => {
      console.log(`  - ${subject.type}: ${subject.description}`);
    });
    
  } catch (error) {
    console.error('❌ Erro ao criar disciplinas:', error);
  } finally {
    await prisma.$disconnect();
  }
}

seedSubjects();
