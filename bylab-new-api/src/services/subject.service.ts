import prisma from '../prisma/client';

export const getAllSubjects = (schoolId?: string, role?: string) => {
  // DEVELOPER pode ver todas as disciplinas
  if (role === 'DEVELOPER') {
    return prisma.subject.findMany({
      include: {
        class: true,
        teacher: true,
        lessons: true,
      },
    });
  }

  // Outros usuários só veem disciplinas da sua escola
  if (!schoolId) {
    throw new Error('School ID é obrigatório para usuários não-developer');
  }

  return prisma.subject.findMany({
    where: {
      schoolId: schoolId
    },
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
}, schoolId?: string, role?: string) => {
  // Verificar se a turma existe e obter o schoolId dela
  const turma = await prisma.class.findUnique({
    where: { id: data.classId },
    select: { id: true, name: true, schoolId: true }
  });

  if (!turma) throw new Error('Turma não encontrada');

  // Verificar se o professor existe e obter o schoolId dele
  const professor = await prisma.teacher.findUnique({
    where: { id: data.teacherId },
    select: { id: true, schoolId: true }
  });

  if (!professor) throw new Error('Professor não encontrado');

  // Verificar se a turma e o professor são da mesma escola
  if (turma.schoolId !== professor.schoolId) {
    throw new Error('Turma e professor devem ser da mesma escola');
  }

  // Para usuários não-developer, verificar se estão criando na escola correta
  if (role !== 'DEVELOPER' && schoolId && turma.schoolId !== schoolId) {
    throw new Error('Não é possível criar disciplina em escola diferente da sua');
  }

  const subjectLabel = getSubjectLabel(data.type);
  const name = `${subjectLabel} - ${turma.name}`;

  return prisma.subject.create({
    data: {
      ...data,
      name,
      schoolId: turma.schoolId // Usar o schoolId da turma
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
