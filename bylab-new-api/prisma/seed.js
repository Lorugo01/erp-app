const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcrypt');

const prisma = new PrismaClient();

const DOMAIN = 'globaltec.com';
const SCHOOL_NAME = 'GlobalTEC Demo';

const USERS = {
  developer: {
    email: `dev@${DOMAIN}`,
    password: 'dev123',
    role: 'DEVELOPER',
  },
  admin: {
    email: `admin@${DOMAIN}`,
    password: 'admin123',
    role: 'ADMIN',
  },
  teacher: {
    email: `prof@${DOMAIN}`,
    password: 'prof123',
    role: 'TEACHER',
    name: 'Prof. João Silva',
  },
  student: {
    email: `aluno@${DOMAIN}`,
    password: 'aluno123',
    role: 'STUDENT',
    name: 'Maria Aluno',
    registrationNumber: '2025001',
  },
};

async function upsertDeveloper() {
  const hashedPassword = await bcrypt.hash(USERS.developer.password, 10);
  return prisma.user.upsert({
    where: { email: USERS.developer.email },
    update: { role: 'DEVELOPER', schoolId: null, password: hashedPassword },
    create: {
      email: USERS.developer.email,
      password: hashedPassword,
      role: 'DEVELOPER',
      schoolId: null,
    },
  });
}

async function upsertSchool() {
  const schoolEmail = `contato@${DOMAIN}`;
  const existing = await prisma.school.findFirst({
    where: { email: schoolEmail },
  });
  if (existing) {
    return prisma.school.update({
      where: { id: existing.id },
      data: {
        name: SCHOOL_NAME,
        website: `https://${DOMAIN}`,
      },
    });
  }

  return prisma.school.create({
    data: {
      name: SCHOOL_NAME,
      address: 'Av. Demo, 100 - São Paulo, SP',
      phone: '(11) 3000-0000',
      email: schoolEmail,
      website: `https://${DOMAIN}`,
    },
  });
}

async function upsertAdmin(schoolId) {
  const hashedPassword = await bcrypt.hash(USERS.admin.password, 10);
  return prisma.user.upsert({
    where: { email: USERS.admin.email },
    update: { role: 'ADMIN', schoolId, password: hashedPassword },
    create: {
      email: USERS.admin.email,
      password: hashedPassword,
      role: 'ADMIN',
      schoolId,
    },
  });
}

async function upsertTeacher(schoolId) {
  const hashedPassword = await bcrypt.hash(USERS.teacher.password, 10);
  const user = await prisma.user.upsert({
    where: { email: USERS.teacher.email },
    update: { role: 'TEACHER', schoolId, password: hashedPassword },
    create: {
      email: USERS.teacher.email,
      password: hashedPassword,
      role: 'TEACHER',
      schoolId,
    },
  });

  const existingTeacher = await prisma.teacher.findFirst({
    where: { email: USERS.teacher.email },
  });
  if (existingTeacher) {
    return prisma.teacher.update({
      where: { id: existingTeacher.id },
      data: { userId: user.id, schoolId, name: USERS.teacher.name },
    });
  }

  return prisma.teacher.create({
    data: {
      name: USERS.teacher.name,
      email: USERS.teacher.email,
      userId: user.id,
      schoolId,
    },
  });
}

async function upsertStudent(schoolId) {
  const hashedPassword = await bcrypt.hash(USERS.student.password, 10);
  const user = await prisma.user.upsert({
    where: { email: USERS.student.email },
    update: { role: 'STUDENT', schoolId, password: hashedPassword },
    create: {
      email: USERS.student.email,
      password: hashedPassword,
      role: 'STUDENT',
      schoolId,
    },
  });

  const existingStudent = await prisma.student.findFirst({
    where: { email: USERS.student.email },
  });
  if (existingStudent) {
    return prisma.student.update({
      where: { id: existingStudent.id },
      data: {
        userId: user.id,
        schoolId,
        name: USERS.student.name,
        registrationNumber: USERS.student.registrationNumber,
      },
    });
  }

  return prisma.student.create({
    data: {
      name: USERS.student.name,
      email: USERS.student.email,
      userId: user.id,
      schoolId,
      registrationNumber: USERS.student.registrationNumber,
    },
  });
}

async function seedGradeTypes(schoolId) {
  const gradeTypes = [
    { name: 'Prova 1', description: 'Primeira prova', isConcept: false },
    { name: 'Prova 2', description: 'Segunda prova', isConcept: false },
    { name: 'Trabalho', description: 'Trabalho/atividade avaliativa', isConcept: false },
  ];

  for (const type of gradeTypes) {
    const existing = await prisma.gradeType.findFirst({
      where: { name: type.name, schoolId },
    });
    if (existing) {
      await prisma.gradeType.update({
        where: { id: existing.id },
        data: type,
      });
    } else {
      await prisma.gradeType.create({ data: { ...type, schoolId } });
    }
  }
}

async function seedGradePeriods(schoolId) {
  const periods = [
    { name: '1º Bimestre', order: 1 },
    { name: '2º Bimestre', order: 2 },
    { name: '3º Bimestre', order: 3 },
    { name: '4º Bimestre', order: 4 },
    { name: 'Recuperação Final', order: 5 },
  ];

  for (const period of periods) {
    const existing = await prisma.gradePeriod.findFirst({
      where: { name: period.name, schoolId },
    });
    if (!existing) {
      await prisma.gradePeriod.create({ data: { ...period, schoolId } });
    }
  }
}

async function seedConfig(schoolId) {
  await prisma.config.upsert({
    where: { schoolId },
    update: {},
    create: {
      schoolId,
      evaluationModel: 'BIMESTRAL',
      minGrade: 5.0,
      minAttendance: 75.0,
    },
  });
}

async function main() {
  console.log('Iniciando seed GlobalTEC...\n');

  await upsertDeveloper();
  const school = await upsertSchool();
  await upsertAdmin(school.id);
  await upsertTeacher(school.id);
  await upsertStudent(school.id);
  await seedGradeTypes(school.id);
  await seedGradePeriods(school.id);
  await seedConfig(school.id);

  const users = await prisma.user.findMany({
    where: {
      email: { endsWith: `@${DOMAIN}` },
    },
    select: {
      email: true,
      role: true,
      school: { select: { name: true } },
    },
    orderBy: { role: 'asc' },
  });

  console.log('Seed concluído!\n');
  console.log('=== USUÁRIOS PARA LOGIN (demonstração) ===\n');
  console.log('| Papel      | Email                  | Senha     | Escola           |');
  console.log('|------------|------------------------|-----------|------------------|');
  console.log(`| DEVELOPER  | ${USERS.developer.email.padEnd(22)} | ${USERS.developer.password.padEnd(9)} | (acesso global)  |`);
  console.log(`| ADMIN      | ${USERS.admin.email.padEnd(22)} | ${USERS.admin.password.padEnd(9)} | ${SCHOOL_NAME.padEnd(16)} |`);
  console.log(`| TEACHER    | ${USERS.teacher.email.padEnd(22)} | ${USERS.teacher.password.padEnd(9)} | ${SCHOOL_NAME.padEnd(16)} |`);
  console.log(`| STUDENT    | ${USERS.student.email.padEnd(22)} | ${USERS.student.password.padEnd(9)} | ${SCHOOL_NAME.padEnd(16)} |`);
  console.log(`\nUsuários @${DOMAIN} no banco: ${users.length}`);
}

main()
  .catch((error) => {
    console.error('Erro ao executar seed:', error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
