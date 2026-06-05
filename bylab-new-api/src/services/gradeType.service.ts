import prisma from '../prisma/client';

export const getAllGradeTypes = (schoolId?: string) => {
  return prisma.gradeType.findMany({
    where: schoolId ? { schoolId } : {},
    orderBy: { name: 'asc' },
  });
};

export const getGradeTypeById = (id: string, schoolId?: string) => {
  return prisma.gradeType.findUnique({
    where: { 
      id,
      ...(schoolId ? { schoolId } : {})
    },
  });
};

export const createGradeType = (data: { 
  name: string; 
  description?: string;
  isConcept?: boolean;
  isRecovery?: boolean;
  schoolId: string;
}) => {
  return prisma.gradeType.create({ data });
};

export const updateGradeType = (
  id: string, 
  data: Partial<{ name: string; description?: string; isConcept?: boolean; isRecovery?: boolean }>,
  schoolId?: string
) => {
  return prisma.gradeType.update({ 
    where: { 
      id,
      ...(schoolId ? { schoolId } : {})
    }, 
    data 
  });
};

export const deleteGradeType = (id: string, schoolId?: string) => {
  return prisma.gradeType.delete({ 
    where: { 
      id,
      ...(schoolId ? { schoolId } : {})
    } 
  });
}; 