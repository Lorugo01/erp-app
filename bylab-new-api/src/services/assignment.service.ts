import prisma from '../prisma/client';

export const getAssignmentsByClass = async (classId: string) => {
  return prisma.assignment.findMany({
    where: { classId },
    include: { subject: true },
    orderBy: { dueDate: 'asc' },
  });
};

export const getAssignmentsByClassAndSubject = async (classId: string, subjectId: string) => {
  return prisma.assignment.findMany({
    where: { 
      classId,
      subjectId 
    },
    include: { subject: true },
    orderBy: { dueDate: 'asc' },
  });
};

export const createAssignment = async (classId: string, subjectId: string, data: any) => {
  return prisma.assignment.create({
    data: {
      classId,
      subjectId,
      description: data.description,
      dueDate: new Date(data.dueDate),
      fileUrl: data.fileUrl ?? null,
    },
    include: { subject: true },
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