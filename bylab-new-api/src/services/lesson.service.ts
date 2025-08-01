import prisma from '../prisma/client';

export const getAllLessons = () => {
  return prisma.lesson.findMany({
    include: {
      class: true,
      subject: true,
      teacher: true,
      attendances: true,
    },
    orderBy: { date: 'desc' }
  });
};

export const getLessonById = async (id: string) => {
  if (!id || typeof id !== 'string' || id.length < 10) {
    throw new Error('ID inválido');
  }

  const lesson = await prisma.lesson.findUnique({
    where: { id },
    include: {
      class: true,
      subject: true,
      teacher: true,
      attendances: true,
    },
  });

  if (!lesson) {
    throw new Error('Aula não encontrada');
  }

  return lesson;
};

export const createLesson = (data: {
  date: Date | string;
  classId: string;
  subjectId: string;
  teacherId: string;
}) => {
  return prisma.lesson.create({ 
    data: {
      ...data,
      date: new Date(data.date)
    }
  });
};

export const updateLesson = (id: string, data: {
  date?: Date | string;
  classId?: string;
  subjectId?: string;
  teacherId?: string;
}) => {
  return prisma.lesson.update({
    where: { id },
    data: {
      ...data,
      date: data.date ? new Date(data.date) : undefined
    },
  });
};

export const deleteLesson = (id: string) => {
  return prisma.lesson.delete({
    where: { id },
  });
};

export const getOrCreateLessonByClassDate = async (data: {
  classId: string;
  date: Date | string;
  subjectId: string;
  teacherId: string;
}) => {
  const lessonDate = new Date(data.date);
  
  // Busca uma lesson existente para a turma, data, disciplina e professor
  let lesson = await prisma.lesson.findFirst({
    where: {
      classId: data.classId,
      subjectId: data.subjectId,
      teacherId: data.teacherId,
      date: lessonDate,
    },
  });
  
  if (!lesson) {
    lesson = await prisma.lesson.create({ 
      data: {
        classId: data.classId,
        subjectId: data.subjectId,
        teacherId: data.teacherId,
        date: lessonDate
      }
    });
  }
  
  return lesson;
};

export const getLessonsByClass = async (classId: string) => {
  if (!classId || typeof classId !== 'string' || classId.length < 10) {
    throw new Error('ID da turma inválido');
  }

  return prisma.lesson.findMany({
    where: { classId },
    include: {
      class: true,
      subject: true,
      teacher: true,
      attendances: true,
    },
    orderBy: { date: 'asc' }
  });
};
