import prisma from '../prisma/client';

export const getAllGradePeriods = () => {
  return prisma.gradePeriod.findMany({
    orderBy: { order: 'asc' },
  });
};

export const getGradePeriodById = (id: string) => {
  return prisma.gradePeriod.findUnique({
    where: { id },
  });
};

export const createGradePeriod = (data: {
  name: string;
  order: number;
}) => {
  return prisma.gradePeriod.create({ data });
};

export const updateGradePeriod = (
  id: string,
  data: Partial<{
    name: string;
    order: number;
  }>
) => {
  return prisma.gradePeriod.update({
    where: { id },
    data,
  });
};

export const deleteGradePeriod = (id: string) => {
  return prisma.gradePeriod.delete({
    where: { id },
  });
}; 