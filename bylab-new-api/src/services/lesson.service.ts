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
  return prisma.lesson.create({ data });
};

export const updateLesson = (id: string, data: {
  date?: Date | string;
  classId?: string;
  subjectId?: string;
  teacherId?: string;
}) => {
  return prisma.lesson.update({
    where: { id },
    data,
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
  // Busca uma lesson existente para a turma, data, disciplina e professor
  let lesson = await prisma.lesson.findFirst({
    where: {
      classId: data.classId,
      subjectId: data.subjectId,
      teacherId: data.teacherId,
      date: new Date(data.date),
    },
  });
  if (!lesson) {
    lesson = await prisma.lesson.create({ data });
  }
  return lesson;
};
