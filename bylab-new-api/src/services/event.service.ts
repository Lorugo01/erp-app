import prisma from '../prisma/client';

export const createEvent = async (data: any, schoolId?: string, role?: string) => {
  // Verificar se a turma existe e obter o schoolId dela
  const turma = await prisma.class.findUnique({
    where: { id: data.classId },
    select: { id: true, schoolId: true }
  });

  if (!turma) throw new Error('Turma não encontrada');

  // Para usuários não-developer, verificar se estão criando na escola correta
  if (role !== 'DEVELOPER' && schoolId && turma.schoolId !== schoolId) {
    throw new Error('Não é possível criar evento em escola diferente da sua');
  }

  return prisma.event.create({ 
    data: {
      ...data,
      schoolId: turma.schoolId // Usar o schoolId da turma
    }
  });
};

export const getEventsByClassId = async (classId: string) => {
  return prisma.event.findMany({
    where: { classId },
    include: {
      teacher: {
        include: {
          user: {
            select: {
              id: true,
              email: true,
              role: true,
              createdAt: true
            }
          }
        }
      }
    },
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