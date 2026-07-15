require('../scripts/load-env');

const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcrypt');

const prisma = new PrismaClient();

const DOMAIN = 'globaltec.com';
const SCHOOL_NAME = 'GlobalTEC Demo';
const DEFAULT_STUDENT_PASSWORD = 'aluno123';
const DEFAULT_TEACHER_PASSWORD = 'prof123';

const USERS = {
  developer: { email: `dev@${DOMAIN}`, password: 'dev123', role: 'DEVELOPER' },
  admin: { email: `admin@${DOMAIN}`, password: 'admin123', role: 'ADMIN' },
};

const TEACHERS = [
  { email: `prof@${DOMAIN}`, name: 'Prof. João Silva', password: DEFAULT_TEACHER_PASSWORD },
  { email: `prof.ana@${DOMAIN}`, name: 'Profa. Ana Santos', password: DEFAULT_TEACHER_PASSWORD },
  { email: `prof.carlos@${DOMAIN}`, name: 'Prof. Carlos Mendes', password: DEFAULT_TEACHER_PASSWORD },
  { email: `prof.patricia@${DOMAIN}`, name: 'Profa. Patrícia Lima', password: DEFAULT_TEACHER_PASSWORD },
];

const STUDENTS = [
  { email: `aluno@${DOMAIN}`, name: 'Maria Aluno', registrationNumber: '2025001' },
  { email: `aluno.pedro@${DOMAIN}`, name: 'Pedro Oliveira', registrationNumber: '2025002' },
  { email: `aluno.julia@${DOMAIN}`, name: 'Julia Ferreira', registrationNumber: '2025003' },
  { email: `aluno.lucas@${DOMAIN}`, name: 'Lucas Souza', registrationNumber: '2025004' },
  { email: `aluno.beatriz@${DOMAIN}`, name: 'Beatriz Costa', registrationNumber: '2025005' },
  { email: `aluno.rafael@${DOMAIN}`, name: 'Rafael Martins', registrationNumber: '2025006' },
  { email: `aluno.camila@${DOMAIN}`, name: 'Camila Ribeiro', registrationNumber: '2025007' },
  { email: `aluno.gustavo@${DOMAIN}`, name: 'Gustavo Almeida', registrationNumber: '2025008' },
  { email: `aluno.larissa@${DOMAIN}`, name: 'Larissa Gomes', registrationNumber: '2025009' },
  { email: `aluno.felipe@${DOMAIN}`, name: 'Felipe Barbosa', registrationNumber: '2025010' },
  { email: `aluno.isabela@${DOMAIN}`, name: 'Isabela Nunes', registrationNumber: '2025011' },
  { email: `aluno.thiago@${DOMAIN}`, name: 'Thiago Carvalho', registrationNumber: '2025012' },
];

const SUBJECT_CATALOG = [
  { type: 'MATEMATICA', name: 'Matemática', teacherEmail: `prof@${DOMAIN}` },
  { type: 'HISTORIA', name: 'História', teacherEmail: `prof.ana@${DOMAIN}` },
  { type: 'CIENCIAS', name: 'Ciências', teacherEmail: `prof.carlos@${DOMAIN}` },
  { type: 'GEOGRAFIA', name: 'Geografia', teacherEmail: `prof.carlos@${DOMAIN}` },
  { type: 'EDUCACAO_FISICA', name: 'Educação Física', teacherEmail: `prof@${DOMAIN}` },
  { type: 'ARTE', name: 'Arte', teacherEmail: `prof.patricia@${DOMAIN}` },
  { type: 'LINGUA_INGLESA', name: 'Língua Inglesa', teacherEmail: `prof.patricia@${DOMAIN}` },
  { type: 'CONTEUDO_INTERDISCIPLINAR', name: 'Português', teacherEmail: `prof.ana@${DOMAIN}` },
];

const SCHEDULE_SLOTS = [
  { dayOfWeek: 1, startTime: '07:30', endTime: '08:20', subjectType: 'MATEMATICA' },
  { dayOfWeek: 1, startTime: '08:20', endTime: '09:10', subjectType: 'CONTEUDO_INTERDISCIPLINAR' },
  { dayOfWeek: 1, startTime: '09:30', endTime: '10:20', subjectType: 'CIENCIAS' },
  { dayOfWeek: 2, startTime: '07:30', endTime: '08:20', subjectType: 'HISTORIA' },
  { dayOfWeek: 2, startTime: '08:20', endTime: '09:10', subjectType: 'GEOGRAFIA' },
  { dayOfWeek: 2, startTime: '09:30', endTime: '10:20', subjectType: 'ARTE' },
  { dayOfWeek: 3, startTime: '07:30', endTime: '08:20', subjectType: 'MATEMATICA' },
  { dayOfWeek: 3, startTime: '08:20', endTime: '09:10', subjectType: 'LINGUA_INGLESA' },
  { dayOfWeek: 3, startTime: '09:30', endTime: '10:20', subjectType: 'EDUCACAO_FISICA' },
  { dayOfWeek: 4, startTime: '07:30', endTime: '08:20', subjectType: 'CIENCIAS' },
  { dayOfWeek: 4, startTime: '08:20', endTime: '09:10', subjectType: 'CONTEUDO_INTERDISCIPLINAR' },
  { dayOfWeek: 5, startTime: '07:30', endTime: '08:20', subjectType: 'HISTORIA' },
  { dayOfWeek: 5, startTime: '08:20', endTime: '09:10', subjectType: 'GEOGRAFIA' },
];

async function hashPassword(password) {
  return bcrypt.hash(password, 10);
}

async function upsertDeveloper() {
  const hashedPassword = await hashPassword(USERS.developer.password);
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
  const existing = await prisma.school.findFirst({ where: { email: schoolEmail } });
  if (existing) {
    return prisma.school.update({
      where: { id: existing.id },
      data: { name: SCHOOL_NAME, website: `https://${DOMAIN}` },
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
  const hashedPassword = await hashPassword(USERS.admin.password);
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

async function upsertTeacher({ email, name, password, schoolId }) {
  const hashedPassword = await hashPassword(password);
  const user = await prisma.user.upsert({
    where: { email },
    update: { role: 'TEACHER', schoolId, password: hashedPassword },
    create: { email, password: hashedPassword, role: 'TEACHER', schoolId },
  });

  const existing = await prisma.teacher.findFirst({ where: { email } });
  if (existing) {
    return prisma.teacher.update({
      where: { id: existing.id },
      data: { userId: user.id, schoolId, name },
    });
  }
  return prisma.teacher.create({
    data: { name, email, userId: user.id, schoolId },
  });
}

async function upsertStudent({ email, name, registrationNumber, schoolId }) {
  const hashedPassword = await hashPassword(DEFAULT_STUDENT_PASSWORD);
  const user = await prisma.user.upsert({
    where: { email },
    update: { role: 'STUDENT', schoolId, password: hashedPassword },
    create: { email, password: hashedPassword, role: 'STUDENT', schoolId },
  });

  const existing = await prisma.student.findFirst({ where: { email } });
  if (existing) {
    return prisma.student.update({
      where: { id: existing.id },
      data: { userId: user.id, schoolId, name, registrationNumber },
    });
  }
  return prisma.student.create({
    data: { name, email, userId: user.id, schoolId, registrationNumber },
  });
}

async function upsertClass(schoolId, { name, grade, letter, shift, academicYear }) {
  let classRecord = await prisma.class.findFirst({
    where: { schoolId, name },
  });
  if (!classRecord) {
    classRecord = await prisma.class.create({
      data: {
        name,
        grade,
        letter,
        academicYear,
        shift,
        evaluationModel: 'BIMESTRAL',
        schoolId,
      },
    });
  }
  return classRecord;
}

async function ensureSchoolSubject(schoolId, { type, name }) {
  const existing = await prisma.schoolSubject.findUnique({
    where: { schoolId_type: { schoolId, type } },
  });
  if (existing) {
    return prisma.schoolSubject.update({
      where: { id: existing.id },
      data: { name },
    });
  }
  return prisma.schoolSubject.create({
    data: { schoolId, type, name },
  });
}

async function ensureSubject(schoolId, classId, teacherId, { type, name }) {
  const catalog = await ensureSchoolSubject(schoolId, { type, name });

  const existing = await prisma.subject.findFirst({
    where: { classId, type },
  });
  if (existing) {
    return prisma.subject.update({
      where: { id: existing.id },
      data: {
        name: catalog.name,
        schoolId,
        teacherId,
        schoolSubjectId: catalog.id,
      },
    });
  }
  return prisma.subject.create({
    data: {
      name: catalog.name,
      type,
      classId,
      teacherId,
      schoolId,
      schoolSubjectId: catalog.id,
    },
  });
}

async function ensureEnrollment(studentId, classId, year) {
  const existing = await prisma.enrollment.findFirst({
    where: { studentId, classId, year },
  });
  if (existing) {
    return existing;
  }
  return prisma.enrollment.create({
    data: { studentId, classId, year, current: false },
  });
}

async function setCurrentEnrollment(studentId, classId, year) {
  await prisma.enrollment.updateMany({
    where: { studentId, current: true },
    data: { current: false },
  });

  const enrollment = await prisma.enrollment.findFirst({
    where: { studentId, classId, year },
  });

  if (enrollment) {
    return prisma.enrollment.update({
      where: { id: enrollment.id },
      data: { current: true },
    });
  }

  return prisma.enrollment.create({
    data: { studentId, classId, year, current: true },
  });
}

async function seedGradeTypes(schoolId) {
  const gradeTypes = [
    { name: 'Prova 1', description: 'Primeira prova', isConcept: false, isRecovery: false },
    { name: 'Prova 2', description: 'Segunda prova', isConcept: false, isRecovery: false },
    { name: 'Trabalho', description: 'Trabalho/atividade avaliativa', isConcept: false, isRecovery: false },
    { name: 'Recuperação', description: 'Substitui a menor nota do período', isConcept: false, isRecovery: true },
  ];

  const result = {};
  for (const type of gradeTypes) {
    const existing = await prisma.gradeType.findFirst({
      where: { name: type.name, schoolId },
    });
    if (existing) {
      result[type.name] = await prisma.gradeType.update({
        where: { id: existing.id },
        data: type,
      });
    } else {
      result[type.name] = await prisma.gradeType.create({
        data: { ...type, schoolId },
      });
    }
  }
  return result;
}

async function seedGradePeriods(schoolId) {
  const periods = [
    { name: '1º Bimestre', order: 1 },
    { name: '2º Bimestre', order: 2 },
    { name: '3º Bimestre', order: 3 },
    { name: '4º Bimestre', order: 4 },
    { name: 'Recuperação Final', order: 5 },
  ];

  const result = {};
  for (const period of periods) {
    let record = await prisma.gradePeriod.findFirst({
      where: { name: period.name, schoolId },
    });
    if (!record) {
      record = await prisma.gradePeriod.create({
        data: { ...period, schoolId },
      });
    }
    result[period.name] = record;
  }
  return result;
}

async function seedConfig(schoolId) {
  return prisma.config.upsert({
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

async function seedSubjectsForClass(schoolId, classRecord, teacherByEmail) {
  const subjects = {};
  for (const item of SUBJECT_CATALOG) {
    const teacher = teacherByEmail[item.teacherEmail];
    if (!teacher) continue;
    const subject = await ensureSubject(schoolId, classRecord.id, teacher.id, item);
    subjects[item.type] = subject;
  }
  return subjects;
}

async function seedScheduleEvents(schoolId, classRecord, subjects, teacherByEmail) {
  for (const slot of SCHEDULE_SLOTS) {
    const subject = subjects[slot.subjectType];
    if (!subject) continue;

    const title = `${subject.name} - ${classRecord.name}`;
    const existing = await prisma.event.findFirst({
      where: {
        classId: classRecord.id,
        dayOfWeek: slot.dayOfWeek,
        startTime: slot.startTime,
        title,
      },
    });

    if (!existing) {
      await prisma.event.create({
        data: {
          classId: classRecord.id,
          teacherId: subject.teacherId,
          schoolId,
          title,
          description: `Aula de ${subject.name}`,
          dayOfWeek: slot.dayOfWeek,
          startTime: slot.startTime,
          endTime: slot.endTime,
        },
      });
    }
  }
}

async function seedLessonsAndAttendance(classRecord, subject, students) {
  const lessonDates = [3, 5, 7, 10, 12].map((daysAgo) => {
    const date = new Date();
    date.setHours(8, 0, 0, 0);
    date.setDate(date.getDate() - daysAgo);
    return date;
  });

  for (const date of lessonDates) {
    const dayStart = new Date(date);
    dayStart.setHours(0, 0, 0, 0);
    const dayEnd = new Date(date);
    dayEnd.setHours(23, 59, 59, 999);

    let lesson = await prisma.lesson.findFirst({
      where: {
        subjectId: subject.id,
        classId: classRecord.id,
        date: { gte: dayStart, lte: dayEnd },
      },
    });

    if (!lesson) {
      lesson = await prisma.lesson.create({
        data: {
          date,
          subjectId: subject.id,
          classId: classRecord.id,
          teacherId: subject.teacherId,
        },
      });
    }

    for (let i = 0; i < students.length; i++) {
      const student = students[i];
      const existingAttendance = await prisma.attendance.findFirst({
        where: { lessonId: lesson.id, studentId: student.id },
      });
      if (existingAttendance) continue;

      let status = 'PRESENT';
      let present = true;
      let justification = null;

      if (i % 7 === 3) {
        status = 'ABSENT';
        present = false;
      } else if (i % 9 === 5) {
        status = 'JUSTIFIED_ABSENT';
        present = false;
        justification = 'Atestado médico';
      }

      await prisma.attendance.create({
        data: {
          lessonId: lesson.id,
          studentId: student.id,
          present,
          status,
          justification,
        },
      });
    }
  }
}

async function seedAssignments(classRecord, subjects) {
  const math = subjects.MATEMATICA;
  const port = subjects.CONTEUDO_INTERDISCIPLINAR;
  const science = subjects.CIENCIAS;

  const assignmentsData = [
    {
      subject: math,
      description: 'Lista de exercícios — Equações do 1º grau (cap. 3)',
      dueDays: 7,
    },
    {
      subject: math,
      description: 'Prova bimestral — Álgebra e funções',
      dueDays: 14,
    },
    {
      subject: port,
      description: 'Redação dissertativa: "A importância da leitura"',
      dueDays: 10,
    },
    {
      subject: science,
      description: 'Trabalho em grupo — Sistema solar e planetas',
      dueDays: 12,
    },
    {
      subject: science,
      description: 'Questionário sobre células e tecidos',
      dueDays: 5,
    },
  ];

  for (const item of assignmentsData) {
    if (!item.subject) continue;

    const existing = await prisma.assignment.findFirst({
      where: {
        classId: classRecord.id,
        subjectId: item.subject.id,
        description: item.description,
      },
    });
    if (existing) continue;

    const dueDate = new Date();
    dueDate.setDate(dueDate.getDate() + item.dueDays);

    await prisma.assignment.create({
      data: {
        classId: classRecord.id,
        subjectId: item.subject.id,
        description: item.description,
        dueDate,
        sentDate: new Date(),
      },
    });
  }
}

async function seedAssignmentSubmissions(classRecord, students) {
  const assignments = await prisma.assignment.findMany({
    where: { classId: classRecord.id },
    take: 3,
  });

  for (let i = 0; i < Math.min(students.length, 6); i++) {
    const student = students[i];
    for (const assignment of assignments) {
      const existing = await prisma.assignmentSubmission.findFirst({
        where: { assignmentId: assignment.id, studentId: student.id },
      });
      if (existing) continue;

      await prisma.assignmentSubmission.create({
        data: {
          assignmentId: assignment.id,
          studentId: student.id,
          description: `Entrega de ${student.name}`,
          submittedAt: new Date(),
        },
      });
    }
  }
}

async function seedGrades(students, subjects, gradeTypes, gradePeriods) {
  const period = gradePeriods['1º Bimestre'];
  const prova1 = gradeTypes['Prova 1'];
  const prova2 = gradeTypes['Prova 2'];
  const trabalho = gradeTypes['Trabalho'];

  const gradePlan = [
    { type: prova1, base: 7.5 },
    { type: prova2, base: 6.8 },
    { type: trabalho, base: 8.2 },
  ];

  const subjectList = [
    subjects.MATEMATICA,
    subjects.HISTORIA,
    subjects.CIENCIAS,
    subjects.CONTEUDO_INTERDISCIPLINAR,
  ].filter(Boolean);

  for (let s = 0; s < students.length; s++) {
    const student = students[s];
    for (const subject of subjectList) {
      for (let g = 0; g < gradePlan.length; g++) {
        const plan = gradePlan[g];
        const value = Math.min(10, Math.max(4, plan.base + ((s + g) % 4) * 0.5 - 1));

        const existing = await prisma.grade.findFirst({
          where: {
            studentId: student.id,
            subjectId: subject.id,
            typeId: plan.type.id,
            periodId: period.id,
          },
        });
        if (existing) continue;

        await prisma.grade.create({
          data: {
            studentId: student.id,
            subjectId: subject.id,
            typeId: plan.type.id,
            periodId: period.id,
            value: Number(value.toFixed(1)),
            date: new Date(),
          },
        });
      }
    }
  }
}

async function seedDemoData(schoolId) {
  const year = new Date().getFullYear();

  const teacherRecords = {};
  for (const teacher of TEACHERS) {
    teacherRecords[teacher.email] = await upsertTeacher({
      ...teacher,
      schoolId,
    });
  }

  const studentRecords = [];
  for (const student of STUDENTS) {
    studentRecords.push(
      await upsertStudent({ ...student, schoolId }),
    );
  }

  const class6A = await upsertClass(schoolId, {
    name: `6º Ano A ${year} - MATUTINO`,
    grade: 6,
    letter: 'A',
    shift: 'MATUTINO',
    academicYear: year,
  });

  const class6B = await upsertClass(schoolId, {
    name: `6º Ano B ${year} - MATUTINO`,
    grade: 6,
    letter: 'B',
    shift: 'MATUTINO',
    academicYear: year,
  });

  const class7A = await upsertClass(schoolId, {
    name: `7º Ano A ${year} - VESPERTINO`,
    grade: 7,
    letter: 'A',
    shift: 'VESPERTINO',
    academicYear: year,
  });

  const class8A = await upsertClass(schoolId, {
    name: `8º Ano A ${year} - MATUTINO`,
    grade: 8,
    letter: 'A',
    shift: 'MATUTINO',
    academicYear: year,
  });

  const classes = [class6A, class6B, class7A, class8A];
  const subjectsByClass = {};

  for (const classRecord of classes) {
    subjectsByClass[classRecord.id] = await seedSubjectsForClass(
      schoolId,
      classRecord,
      teacherRecords,
    );
    await seedScheduleEvents(
      schoolId,
      classRecord,
      subjectsByClass[classRecord.id],
      teacherRecords,
    );
    await seedAssignments(classRecord, subjectsByClass[classRecord.id]);
  }

  const enrollments6A = studentRecords.slice(0, 6);
  const enrollments6B = studentRecords.slice(6, 8);
  const enrollments7A = studentRecords.slice(8, 10);
  const enrollments8A = studentRecords.slice(10, 12);

  for (const student of enrollments6A) {
    await ensureEnrollment(student.id, class6A.id, year);
    await setCurrentEnrollment(student.id, class6A.id, year);
  }
  for (const student of enrollments6B) {
    await ensureEnrollment(student.id, class6B.id, year);
    await setCurrentEnrollment(student.id, class6B.id, year);
  }
  for (const student of enrollments7A) {
    await ensureEnrollment(student.id, class7A.id, year);
    await setCurrentEnrollment(student.id, class7A.id, year);
  }
  for (const student of enrollments8A) {
    await ensureEnrollment(student.id, class8A.id, year);
    await setCurrentEnrollment(student.id, class8A.id, year);
  }

  const math6A = subjectsByClass[class6A.id].MATEMATICA;
  if (math6A) {
    await seedLessonsAndAttendance(class6A, math6A, enrollments6A);
  }

  await seedAssignmentSubmissions(class6A, enrollments6A);

  const gradeTypes = await seedGradeTypes(schoolId);
  const gradePeriods = await seedGradePeriods(schoolId);
  await seedGrades(enrollments6A, subjectsByClass[class6A.id], gradeTypes, gradePeriods);

  return {
    teachers: Object.values(teacherRecords),
    students: studentRecords,
    classes,
  };
}

async function main() {
  console.log('Iniciando seed GlobalTEC (demonstração completa)...\n');

  await upsertDeveloper();
  const school = await upsertSchool();
  await upsertAdmin(school.id);

  const demo = await seedDemoData(school.id);
  await seedConfig(school.id);

  const counts = {
    teachers: await prisma.teacher.count({ where: { schoolId: school.id } }),
    students: await prisma.student.count({ where: { schoolId: school.id } }),
    classes: await prisma.class.count({ where: { schoolId: school.id } }),
    subjects: await prisma.subject.count({ where: { schoolId: school.id } }),
    enrollments: await prisma.enrollment.count(),
    lessons: await prisma.lesson.count(),
    attendances: await prisma.attendance.count(),
    events: await prisma.event.count({ where: { schoolId: school.id } }),
    assignments: await prisma.assignment.count(),
    submissions: await prisma.assignmentSubmission.count(),
    grades: await prisma.grade.count(),
  };

  console.log('Seed concluído!\n');
  console.log('=== RESUMO DOS DADOS ===\n');
  console.log(`Escola: ${SCHOOL_NAME}`);
  console.log(`Professores: ${counts.teachers}`);
  console.log(`Alunos: ${counts.students}`);
  console.log(`Turmas: ${counts.classes}`);
  console.log(`Disciplinas: ${counts.subjects}`);
  console.log(`Matrículas: ${counts.enrollments}`);
  console.log(`Aulas (lessons): ${counts.lessons}`);
  console.log(`Frequências: ${counts.attendances}`);
  console.log(`Eventos (agenda): ${counts.events}`);
  console.log(`Atividades: ${counts.assignments}`);
  console.log(`Entregas: ${counts.submissions}`);
  console.log(`Notas: ${counts.grades}`);

  console.log('\n=== LOGIN — ADMIN / DEV ===\n');
  console.log(`DEVELOPER  | ${USERS.developer.email} | ${USERS.developer.password}`);
  console.log(`ADMIN      | ${USERS.admin.email} | ${USERS.admin.password}`);

  console.log('\n=== LOGIN — PROFESSORES (senha: prof123) ===\n');
  for (const t of TEACHERS) {
    console.log(`TEACHER | ${t.email} | ${t.name}`);
  }

  console.log('\n=== LOGIN — ALUNOS (senha: aluno123) ===\n');
  for (const s of STUDENTS) {
    console.log(`STUDENT | ${s.email} | ${s.name} | Mat: ${s.registrationNumber}`);
  }

  console.log('\n=== TURMAS ===\n');
  for (const c of demo.classes) {
    const enrolled = await prisma.enrollment.count({
      where: { classId: c.id, current: true },
    });
    console.log(`- ${c.name} (${enrolled} alunos)`);
  }
}

main()
  .catch((error) => {
    console.error('Erro ao executar seed:', error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
