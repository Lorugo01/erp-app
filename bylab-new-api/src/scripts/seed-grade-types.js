// Script para inserir tipos de nota padrão na tabela GradeType
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('Iniciando seed dos tipos de nota...');
  
  const gradeTypes = [
    { id: 'PROVA_1', name: 'Prova 1', description: 'Primeira prova', isConcept: false },
    { id: 'PROVA_2', name: 'Prova 2', description: 'Segunda prova', isConcept: false },
    { id: 'TRABALHO', name: 'Trabalho', description: 'Trabalho/atividade avaliativa', isConcept: false },
    { id: 'RECUPERACAO', name: 'Recuperação', description: 'Prova de recuperação', isConcept: false },
    { id: 'RECUPERACAO_FINAL', name: 'Recuperação Final', description: 'Prova de recuperação final', isConcept: false },
  ];

  for (const type of gradeTypes) {
    await prisma.gradeType.upsert({
      where: { id: type.id },
      update: type,
      create: type,
    });
    console.log(`Tipo de nota '${type.name}' garantido no banco.`);
  }
  
  console.log('Seed de tipos de nota concluído!');
}

main()
  .catch((e) => {
    console.error('Erro ao executar seed:', e);
  })
  .finally(async () => {
    await prisma.$disconnect();
  }); 