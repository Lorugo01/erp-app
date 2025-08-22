import prisma from '../prisma/client';

export const getAllGradePeriods = (schoolId?: string) => {
  return prisma.gradePeriod.findMany({
    where: schoolId ? { schoolId } : {},
    orderBy: { order: 'asc' },
  });
};

export const getGradePeriodById = (id: string, schoolId?: string) => {
  return prisma.gradePeriod.findUnique({
    where: { 
      id,
      ...(schoolId ? { schoolId } : {})
    },
  });
};

export const createGradePeriod = (data: {
  name: string;
  order: number;
  schoolId: string;
  startDate?: Date;
  endDate?: Date;
}) => {
  return prisma.gradePeriod.create({ data });
};

export const updateGradePeriod = (
  id: string,
  data: Partial<{
    name: string;
    order: number;
    startDate: Date;
    endDate: Date;
  }>,
  schoolId?: string
) => {
  return prisma.gradePeriod.update({
    where: { 
      id,
      ...(schoolId ? { schoolId } : {})
    },
    data,
  });
};

export const deleteGradePeriod = (id: string, schoolId?: string) => {
  return prisma.gradePeriod.delete({
    where: { 
      id,
      ...(schoolId ? { schoolId } : {})
    },
  });
}; 