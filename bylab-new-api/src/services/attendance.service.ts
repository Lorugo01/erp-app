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
      lesson: {
        include: {
          subject: true,
          class: true,
          teacher: true
        }
      },
    },
  });

  if (!attendance) {
    throw new Error('Frequência não encontrada');
  }

  return attendance;
};

export const createAttendance = async (data: {
  studentId: string;
  lessonId: string;
  status?: string;
  justification?: string;
  present?: boolean; // Para compatibilidade
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

  // 3. Preparar dados para criação
  const createData: any = {
    studentId: data.studentId,
    lessonId: data.lessonId,
    status: data.status || (data.present === true ? 'PRESENT' : 'ABSENT'),
    justification: data.justification,
    present: data.present !== undefined ? data.present : (data.status === 'PRESENT')
  };

  // 4. Criar presença
  return prisma.attendance.create({ data: createData });
};

// 4. Criar presença em massa
export const createBulkAttendance = async (data: {
  lessonId: string;
  presences: { 
    studentId: string; 
    present?: boolean; 
    status?: string; 
    justification?: string; 
  }[];
}) => {
  const lesson = await prisma.lesson.findUnique({
    where: { id: data.lessonId },
    select: { classId: true }
  });

  if (!lesson) throw new Error('Aula não encontrada');

  const created = [];

  // Primeiro, deletar attendances existentes para esta aula
  await prisma.attendance.deleteMany({
    where: { lessonId: data.lessonId }
  });

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

    // Preparar dados para criação
    const createData: any = {
      lessonId: data.lessonId,
      studentId: p.studentId,
      status: p.status || (p.present === true ? 'PRESENT' : 'ABSENT'),
      justification: p.justification,
      present: p.present !== undefined ? p.present : (p.status === 'PRESENT')
    };

    const attendance = await prisma.attendance.create({
      data: createData
    });

    created.push(attendance);
  }

  return created;
};

export const updateAttendance = async (id: string, data: Partial<{
  present?: boolean;
  status?: string;
  justification?: string;
}>) => {
  // Preparar dados para atualização
  const updateData: any = {};
  
  if (data.status !== undefined) {
    updateData.status = data.status;
    updateData.present = data.status === 'PRESENT';
  } else if (data.present !== undefined) {
    updateData.present = data.present;
    updateData.status = data.present ? 'PRESENT' : 'ABSENT';
  }
  
  if (data.justification !== undefined) {
    updateData.justification = data.justification;
  }

  return prisma.attendance.update({
    where: { id },
    data: updateData,
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

export const deleteAttendance = async (id: string) => {
  return prisma.attendance.delete({
    where: { id },
  });
};

// Novo método para buscar attendance por lesson ID
export const getAttendanceByLesson = async (lessonId: string) => {
  if (!lessonId || typeof lessonId !== 'string' || lessonId.length < 10) {
    throw new Error('ID da aula inválido');
  }

  return prisma.attendance.findMany({
    where: { lessonId },
    include: {
      student: {
        select: {
          id: true,
          name: true,
          registrationNumber: true,
          profilePicture: true
        }
      },
      lesson: {
        include: {
          subject: true,
          class: true,
          teacher: true
        }
      },
    },
    orderBy: {
      student: {
        name: 'asc'
      }
    }
  });
};

// Novo método para buscar attendance por student ID
export const getAttendanceByStudent = async (studentId: string) => {
  if (!studentId || typeof studentId !== 'string' || studentId.length < 10) {
    throw new Error('ID do aluno inválido');
  }

  return prisma.attendance.findMany({
    where: { studentId },
    include: {
      student: {
        select: {
          id: true,
          name: true,
          registrationNumber: true,
          profilePicture: true
        }
      },
      lesson: {
        include: {
          subject: true,
          class: true,
          teacher: true
        }
      },
    },
    orderBy: [
      {
        lesson: {
          date: 'desc'
        }
      },
      {
        student: {
          name: 'asc'
        }
      }
    ]
  });
};
