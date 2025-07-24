import prisma from '../prisma/client';

export const getAssignmentsByClass = async (classId: string) => {
  return prisma.assignment.findMany({
    where: { classId },
    orderBy: { dueDate: 'asc' },
  });
};

export const createAssignment = async (classId: string, data: any) => {
  return prisma.assignment.create({
    data: {
      classId,
      description: data.description,
      dueDate: new Date(data.dueDate),
      fileUrl: data.fileUrl ?? null,
    },
  });
};

export const deleteAssignment = async (assignmentId: string) => {
  return prisma.assignment.delete({
    where: { id: assignmentId },
  });
};

export const getSubmissionsByAssignment = async (assignmentId: string) => {
  return prisma.assignmentSubmission.findMany({
    where: { assignmentId },
    include: { student: true },
    orderBy: { submittedAt: 'desc' },
  });
};

export const createSubmission = async (assignmentId: string, data: any) => {
  return prisma.assignmentSubmission.create({
    data: {
      assignmentId,
      studentId: data.studentId,
      fileUrl: data.fileUrl ?? null,
      description: data.description ?? null,
    },
  });
}; 