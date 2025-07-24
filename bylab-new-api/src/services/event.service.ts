import prisma from '../prisma/client';

export const createEvent = async (data: any) => {
  return prisma.event.create({ data });
};

export const getEventsByClassId = async (classId: string) => {
  return prisma.event.findMany({
    where: { classId },
    orderBy: { startTime: 'asc' }
  });
};

export const updateEvent = async (id: string, data: any) => {
  return prisma.event.update({
    where: { id },
    data
  });
};

export const deleteEvent = async (id: string) => {
  return prisma.event.delete({
    where: { id }
  });
}; 