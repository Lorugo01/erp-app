import prisma from '../prisma/client';

export const createEnrollment = async (data: {
  studentId: string;
  classId: string;
  year: number;
  current?: boolean;
}) => {
  // Zera current anterior se necessário
  if (data.current) {
    await prisma.enrollment.updateMany({
      where: {
        studentId: data.studentId,
        current: true
      },
      data: { current: false }
    });
  }

  return prisma.enrollment.create({ data });
};

export const getAllEnrollments = () => {
  return prisma.enrollment.findMany({
    include: { student: true, class: true }
  });
};

export const getEnrollmentById = async (id: string) => {
  const enrollment = await prisma.enrollment.findUnique({
    where: { id },
    include: { student: true, class: true }
  });

  if (!enrollment) throw new Error('Matrícula não encontrada');

  return enrollment;
};

export const getEnrollmentsByStudentId = (studentId: string) => {
  return prisma.enrollment.findMany({
    where: { studentId },
    orderBy: { year: 'desc' },
    include: { class: true }
  });
};

export const getCurrentClassOfStudent = async (studentId: string) => {
  const enrollment = await prisma.enrollment.findFirst({
    where: {
      studentId,
      current: true
    },
    include: {
      class: true
    }
  });

  if (!enrollment) {
    throw new Error('Aluno não está matriculado atualmente em nenhuma turma');
  }

  return enrollment.class;
};

export const updateEnrollment = (id: string, data: {
  current?: boolean;
}) => {
  return prisma.enrollment.update({
    where: { id },
    data
  });
};

export const deleteEnrollment = (id: string) => {
  return prisma.enrollment.delete({
    where: { id }
  });
};
