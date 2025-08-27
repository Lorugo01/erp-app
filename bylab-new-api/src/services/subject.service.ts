import prisma from '../prisma/client';

export const getAllSubjects = () => {
  return prisma.subject.findMany({
    include: {
      class: true,
      teacher: true,
      lessons: true,
      subjectType: true,
    },
  });
};

export const getSubjectById = async (id: string) => {
  if (!id || typeof id !== 'string' || id.length < 10) {
    throw new Error('ID inválido');
  }

  const subject = await prisma.subject.findUnique({
    where: { id },
    include: {
      class: true,
      teacher: true,
      lessons: true,
      subjectType: true,
    },
  });

  if (!subject) {
    throw new Error('Disciplina não encontrada');
  }

  return subject;
};

export const createSubject = async (data: {
  subjectTypeId: string;
  classId: string;
  teacherId: string;
}) => {
  const turma = await prisma.class.findUnique({
    where: { id: data.classId }
  });

  if (!turma) throw new Error('Turma não encontrada');

  const subjectType = await prisma.subjectType.findUnique({
    where: { id: data.subjectTypeId }
  });

  if (!subjectType) throw new Error('Tipo de disciplina não encontrado');

  const name = `${subjectType.name} - ${turma.name}`;

  return prisma.subject.create({
    data: {
      subjectTypeId: data.subjectTypeId,
      classId: data.classId,
      teacherId: data.teacherId,
      name
    }
  });
};

export const getSubjectsByClassId = async (classId: string) => {
  return prisma.subject.findMany({
    where: { classId },
    include: {
      class: true,
      teacher: true,
      lessons: true,
      subjectType: true,
    },
  });
};

export const getSubjectsByClassIdAndTeacher = async (classId: string, teacherId: string) => {
  return prisma.subject.findMany({
    where: { 
      classId,
      teacherId 
    },
    include: {
      class: true,
      teacher: true,
      lessons: true,
      subjectType: true,
    },
  });
};



export const updateSubject = (id: string, data: {
  name?: string;
  classId?: string;
  teacherId?: string;
  subjectTypeId?: string;
}) => {
  return prisma.subject.update({
    where: { id },
    data,
  });
};

export const deleteSubject = (id: string) => {
  return prisma.subject.delete({
    where: { id },
  });
};
