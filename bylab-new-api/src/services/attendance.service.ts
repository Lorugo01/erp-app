import prisma from '../prisma/client';

export const getAllAttendances = () => {
  return prisma.attendance.findMany({
    include: {
      student: true,
      lesson: {
        include: {
          subject: true,
          class: true,
          teacher: true
        }
      },
    },
  });
};

export const getAttendanceById = async (id: string) => {
  if (!id || typeof id !== 'string' || id.length < 10) {
    throw new Error('ID inválido');
  }

  const attendance = await prisma.attendance.findUnique({
    where: { id },
    include: {
      student: true,
      lesson: true,
    },
  });

  if (!attendance) {
    throw new Error('Presença não encontrada');
  }

  return attendance;
};

export const createAttendance = async (data: {
  studentId: string;
  lessonId: string;
  present: boolean;
}) => {
  // 1. Buscar a aula
  const lesson = await prisma.lesson.findUnique({
    where: { id: data.lessonId },
    select: { classId: true }
  });

  if (!lesson) {
    throw new Error('Aula não encontrada');
  }

  // 2. Verificar matrícula ativa do aluno na turma da aula
  const isEnrolled = await prisma.enrollment.findFirst({
    where: {
      studentId: data.studentId,
      classId: lesson.classId,
      current: true
    }
  });

  if (!isEnrolled) {
    throw new Error('Aluno não está matriculado atualmente na turma desta aula');
  }

  // 3. Criar presença
  return prisma.attendance.create({ data });
};

// 4. Criar presença em massa
export const createBulkAttendance = async (data: {
  lessonId: string;
  presences: { studentId: string; present: boolean }[];
}) => {
  const lesson = await prisma.lesson.findUnique({
    where: { id: data.lessonId },
    select: { classId: true }
  });

  if (!lesson) throw new Error('Aula não encontrada');

  const created = [];

  for (const p of data.presences) {
    const isEnrolled = await prisma.enrollment.findFirst({
      where: {
        studentId: p.studentId,
        classId: lesson.classId,
        current: true
      }
    });

    if (!isEnrolled) {
      throw new Error(`Aluno ${p.studentId} não está matriculado atualmente na turma desta aula`);
    }

    const attendance = await prisma.attendance.create({
      data: {
        lessonId: data.lessonId,
        studentId: p.studentId,
        present: p.present
      }
    });

    created.push(attendance);
  }

  return created;
};


export const updateAttendance = (id: string, data: {
  present?: boolean;
}) => {
  return prisma.attendance.update({
    where: { id },
    data,
  });
};

export const deleteAttendance = (id: string) => {
  return prisma.attendance.delete({
    where: { id },
  });
};
