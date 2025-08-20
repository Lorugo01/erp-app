import prisma from '../prisma/client';

export const createLesson = async (data: {
  classId: string;
  subjectId: string;
  teacherId: string;
  date: Date;
  topic?: string;
  description?: string;
}) => {
  return prisma.lesson.create({
    data,
    include: {
      class: true,
      subject: true,
      teacher: true,
    },
  });
};

export const getLessonById = async (id: string) => {
  return prisma.lesson.findUnique({
    where: { id },
    include: {
      class: true,
      subject: true,
      teacher: true,
      attendances: {
        include: {
          student: true,
        },
      },
    },
  });
};

export const getOrCreateLesson = async (data: {
  classId: string;
  subjectId: string;
  teacherId: string;
  date: Date;
}) => {
  // Primeiro, tentar encontrar uma aula existente
  const existingLesson = await prisma.lesson.findFirst({
    where: {
      classId: data.classId,
      subjectId: data.subjectId,
      teacherId: data.teacherId,
      date: {
        gte: new Date(data.date.toDateString()),
        lt: new Date(new Date(data.date.toDateString()).getTime() + 24 * 60 * 60 * 1000),
      },
    },
    include: {
      class: true,
      subject: true,
      teacher: true,
    },
  });

  if (existingLesson) {
    return existingLesson;
  }

  // Se não existir, criar uma nova
  return createLesson(data);
};

export const duplicateLesson = async (data: {
  sourceLessonId: string;
  targetClassIds: string[];
  targetDate: Date;
  teacherId: string;
  subjectId: string;
  copyAttendance: boolean;
  createNewLesson: boolean;
  attendanceData?: {
    attendanceMap: Record<string, string | null>;
    justificationMap: Record<string, string>;
  };
}) => {
  const {
    sourceLessonId,
    targetClassIds,
    targetDate,
    teacherId,
    subjectId,
    copyAttendance,
    createNewLesson,
    attendanceData,
  } = data;

  // Buscar a aula origem
  const sourceLesson = await getLessonById(sourceLessonId);
  if (!sourceLesson) {
    throw new Error('Aula origem não encontrada');
  }

  const duplicatedLessons = [];

  for (const targetClassId of targetClassIds) {
    let targetLesson;

    if (createNewLesson) {
      // Criar ou buscar aula na turma de destino
      targetLesson = await getOrCreateLesson({
        classId: targetClassId,
        subjectId,
        teacherId,
        date: targetDate,
      });
    } else {
      // Buscar aula existente
      targetLesson = await prisma.lesson.findFirst({
        where: {
          classId: targetClassId,
          subjectId,
          teacherId,
          date: {
            gte: new Date(targetDate.toDateString()),
            lt: new Date(new Date(targetDate.toDateString()).getTime() + 24 * 60 * 60 * 1000),
          },
        },
      });

      if (!targetLesson) {
        throw new Error(`Nenhuma aula encontrada para a turma ${targetClassId} na data selecionada`);
      }
    }

    // Copiar frequência se solicitado
    if (copyAttendance && attendanceData) {
      // Buscar alunos da turma de destino
      const targetStudents = await prisma.student.findMany({
        where: {
          enrollments: {
            some: {
              classId: targetClassId,
              current: true,
            },
          },
        },
      });

      // Limpar frequências existentes para esta aula
      await prisma.attendance.deleteMany({
        where: { lessonId: targetLesson.id },
      });

      // Criar novas frequências baseadas no padrão da aula origem
      const attendanceRecords = [];
      
      for (const student of targetStudents) {
        // Mapear frequência do estudante correspondente da turma origem (se houver)
        const sourceStudentAttendance = sourceLesson.attendances.find(
          (att) => att.student.registrationNumber === student.registrationNumber
        );

        let status = 'PRESENT'; // Padrão
        let justification = null;

        if (sourceStudentAttendance) {
          status = sourceStudentAttendance.status || (sourceStudentAttendance.present ? 'PRESENT' : 'ABSENT');
          justification = sourceStudentAttendance.justification;
        } else if (attendanceData.attendanceMap[student.id]) {
          // Usar dados do mapa de frequência atual
          status = attendanceData.attendanceMap[student.id] || 'PRESENT';
          justification = status === 'JUSTIFIED_ABSENT' ? attendanceData.justificationMap[student.id] : null;
        }

        if (status !== 'PRESENT' || justification) {
          attendanceRecords.push({
            lessonId: targetLesson.id,
            studentId: student.id,
            status,
            justification,
            present: status === 'PRESENT',
          });
        }
      }

      // Criar registros de frequência em lote
      if (attendanceRecords.length > 0) {
        await prisma.attendance.createMany({
          data: attendanceRecords,
        });
      }
    }

    duplicatedLessons.push(targetLesson);
  }

  return {
    duplicatedCount: duplicatedLessons.length,
    lessons: duplicatedLessons,
  };
};

export const updateLesson = async (id: string, data: Partial<{
  topic: string;
  description: string;
  date: Date;
}>) => {
  return prisma.lesson.update({
    where: { id },
    data,
    include: {
      class: true,
      subject: true,
      teacher: true,
    },
  });
};

export const deleteLesson = async (id: string) => {
  return prisma.lesson.delete({
    where: { id },
  });
};