import prisma from '../prisma/client';
import {
  ensureSchoolSubject,
  getSubjectLabel,
} from './schoolSubject.service';

export { getSubjectLabel };

export const getAllSubjects = (schoolId?: string, role?: string) => {
  if (role === 'DEVELOPER') {
    return prisma.subject.findMany({
      include: {
        class: true,
        teacher: true,
        lessons: true,
        schoolSubject: true,
      },
    });
  }

  if (!schoolId) {
    throw new Error('School ID é obrigatório para usuários não-developer');
  }

  return prisma.subject.findMany({
    where: {
      schoolId: schoolId,
    },
    include: {
      class: true,
      teacher: true,
      lessons: true,
      schoolSubject: true,
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
      schoolSubject: true,
    },
  });

  if (!subject) {
    throw new Error('Disciplina não encontrada');
  }

  return subject;
};

export const createSubject = async (
  data: {
    type: string;
    classId: string;
    teacherId: string;
    name?: string;
  },
  schoolId?: string,
  role?: string,
) => {
  const turma = await prisma.class.findUnique({
    where: { id: data.classId },
    select: { id: true, name: true, schoolId: true },
  });

  if (!turma) throw new Error('Turma não encontrada');

  const professor = await prisma.teacher.findUnique({
    where: { id: data.teacherId },
    select: { id: true, schoolId: true },
  });

  if (!professor) throw new Error('Professor não encontrado');

  if (turma.schoolId !== professor.schoolId) {
    throw new Error('Turma e professor devem ser da mesma escola');
  }

  if (role !== 'DEVELOPER' && schoolId && turma.schoolId !== schoolId) {
    throw new Error(
      'Não é possível criar disciplina em escola diferente da sua',
    );
  }

  const existing = await prisma.subject.findFirst({
    where: { classId: data.classId, type: data.type as any },
  });
  if (existing) {
    throw new Error('Esta matéria já está vinculada a esta turma');
  }

  const catalog = await ensureSchoolSubject(
    turma.schoolId,
    data.type,
    data.name,
  );

  return prisma.subject.create({
    data: {
      type: data.type as any,
      classId: data.classId,
      teacherId: data.teacherId,
      name: catalog.name,
      schoolId: turma.schoolId,
      schoolSubjectId: catalog.id,
    },
    include: {
      class: true,
      teacher: true,
      schoolSubject: true,
    },
  });
};

export const getSubjectsByClassId = async (classId: string) => {
  return prisma.subject.findMany({
    where: { classId },
    include: {
      class: true,
      teacher: true,
      lessons: true,
      schoolSubject: true,
    },
  });
};

export const getSubjectsByClassIdAndTeacher = async (
  classId: string,
  teacherId: string,
) => {
  return prisma.subject.findMany({
    where: {
      classId,
      teacherId,
    },
    include: {
      class: true,
      teacher: true,
      lessons: true,
      schoolSubject: true,
    },
  });
};

export const updateSubject = (
  id: string,
  data: {
    name?: string;
    classId?: string;
    teacherId?: string;
  },
) => {
  return prisma.subject.update({
    where: { id },
    data,
    include: {
      class: true,
      teacher: true,
      schoolSubject: true,
    },
  });
};

export const deleteSubject = (id: string) => {
  return prisma.subject.delete({
    where: { id },
  });
};
