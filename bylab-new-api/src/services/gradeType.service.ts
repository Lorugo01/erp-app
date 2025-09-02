import prisma from '../prisma/client';

export const getAllGradeTypes = () => {
  return prisma.gradeType.findMany({
    orderBy: { name: 'asc' },
  });
};

export const getGradeTypeById = (id: string) => {
  return prisma.gradeType.findUnique({
    where: { id },
  });
};

export const createGradeType = (data: { 
  name: string; 
  description?: string; 
  isConcept?: boolean;
  isRecovery?: boolean;
}) => {
  return prisma.gradeType.create({ data });
};

export const updateGradeType = (id: string, data: Partial<{ 
  name: string; 
  description?: string; 
  isConcept?: boolean;
  isRecovery?: boolean;
}>) => {
  return prisma.gradeType.update({ where: { id }, data });
};

export const deleteGradeType = (id: string) => {
  return prisma.gradeType.delete({ where: { id } });
}; 