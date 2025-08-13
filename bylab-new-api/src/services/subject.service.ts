import prisma from '../prisma/client';

export const getAllSubjects = () => {
  return prisma.subject.findMany({
    include: {
      class: true,
      teacher: true,
      lessons: true,
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
    },
  });

  if (!subject) {
    throw new Error('Disciplina não encontrada');
  }

  return subject;
};

export const createSubject = async (data: {
  type: string;
  classId: string;
  teacherId: string;
}) => {
  const turma = await prisma.class.findUnique({
    where: { id: data.classId }
  });

  if (!turma) throw new Error('Turma não encontrada');

  const subjectLabel = getSubjectLabel(data.type);
  const name = `${subjectLabel} - ${turma.name}`;

  return prisma.subject.create({
    data: {
      ...data,
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
    },
  });
};

function getSubjectLabel(type: string): string {
  const map = {
    LINGUA_INGLESA: "Língua Inglesa",
    ARTE: "Arte",
    EDUCACAO_FISICA: "Educação Física",
    MATEMATICA: "Matemática",
    CIENCIAS: "Ciências",
    HISTORIA: "História",
    GEOGRAFIA: "Geografia",
    ENSINO_RELIGIOSO: "Ensino Religioso",
    BIOLOGIA: "Biologia",
    FISICA: "Física",
    QUIMICA: "Química",
    FILOSOFIA: "Filosofia",
    SOCIOLOGIA: "Sociologia",
    CONTEUDO_INTERDISCIPLINAR: "Conteúdo Interdisciplinar"
  };

  return map[type as keyof typeof map] || type;
}

export const updateSubject = (id: string, data: {
  name?: string;
  classId?: string;
  teacherId?: string;
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
