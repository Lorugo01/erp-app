const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function populatePeriods() {
  try {
    // Verificar se já existem períodos
    const existingPeriods = await prisma.gradePeriod.findMany();
    
    if (existingPeriods.length === 0) {
      // Criar períodos básicos
      const periods = [
        { name: '1º Bimestre', order: 1 },
        { name: '2º Bimestre', order: 2 },
        { name: '3º Bimestre', order: 3 },
        { name: '4º Bimestre', order: 4 },
        { name: 'Recuperação Final', order: 5 },
      ];

      for (const period of periods) {
        await prisma.gradePeriod.create({
          data: period,
        });
      }

      console.log('Períodos avaliativos criados com sucesso!');
    } else {
      console.log('Períodos já existem no banco de dados.');
    }
  } catch (error) {
    console.error('Erro ao criar períodos:', error);
  } finally {
    await prisma.$disconnect();
  }
}

populatePeriods(); 