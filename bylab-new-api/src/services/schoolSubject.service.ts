import prisma from '../prisma/client';

export function getSubjectLabel(type: string): string {
  const map: Record<string, string> = {
    LINGUA_INGLESA: 'Língua Inglesa',
    ARTE: 'Arte',
    EDUCACAO_FISICA: 'Educação Física',
    MATEMATICA: 'Matemática',
    CIENCIAS: 'Ciências',
    HISTORIA: 'História',
    GEOGRAFIA: 'Geografia',
    ENSINO_RELIGIOSO: 'Ensino Religioso',
    BIOLOGIA: 'Biologia',
    FISICA: 'Física',
    QUIMICA: 'Química',
    FILOSOFIA: 'Filosofia',
    SOCIOLOGIA: 'Sociologia',
    CONTEUDO_INTERDISCIPLINAR: 'Conteúdo Interdisciplinar',
  };
  return map[type] || type;
}

async function assertSchoolAccess(
  schoolId: string | undefined,
  role: string | undefined,
  targetSchoolId: string,
) {
  if (role === 'DEVELOPER') return;
  if (!schoolId || schoolId !== targetSchoolId) {
    throw new Error('Acesso negado a esta escola');
  }
}

export const getAllSchoolSubjects = async (
  schoolId?: string,
  role?: string,
) => {
  if (role !== 'DEVELOPER' && !schoolId) {
    throw new Error('School ID é obrigatório');
  }

  const list = await prisma.schoolSubject.findMany({
    where: role === 'DEVELOPER' && !schoolId ? undefined : { schoolId },
    include: {
      offerings: {
        include: {
          class: {
            include: {
              enrollments: {
                where: { current: true },
                select: { id: true, studentId: true },
              },
            },
          },
          teacher: true,
        },
      },
    },
    orderBy: { name: 'asc' },
  });

  return list.map((item) => {
    const classIds = new Set(item.offerings.map((o) => o.classId));
    const teacherIds = new Set(
      item.offerings.map((o) => o.teacherId).filter(Boolean),
    );
    const studentIds = new Set<string>();
    for (const offering of item.offerings) {
      for (const enrollment of offering.class?.enrollments ?? []) {
        studentIds.add(enrollment.studentId);
      }
    }

    return {
      ...item,
      classCount: classIds.size,
      teacherCount: teacherIds.size,
      studentCount: studentIds.size,
      offeringCount: item.offerings.length,
    };
  });
};

export const getSchoolSubjectById = async (id: string) => {
  const item = await prisma.schoolSubject.findUnique({
    where: { id },
    include: {
      offerings: {
        include: {
          class: {
            include: {
              enrollments: {
                where: { current: true },
                select: { id: true, studentId: true },
              },
            },
          },
          teacher: true,
        },
      },
    },
  });
  if (!item) throw new Error('Matéria não encontrada');
  return item;
};

export const createSchoolSubject = async (
  data: { type: string; name?: string; description?: string },
  schoolId?: string,
  role?: string,
) => {
  if (!schoolId && role !== 'DEVELOPER') {
    throw new Error('School ID é obrigatório');
  }
  if (!schoolId) {
    throw new Error('Informe a escola para criar a matéria');
  }

  const name = data.name?.trim() || getSubjectLabel(data.type);

  const existing = await prisma.schoolSubject.findUnique({
    where: {
      schoolId_type: {
        schoolId,
        type: data.type as any,
      },
    },
  });
  if (existing) {
    throw new Error('Já existe uma matéria deste tipo nesta escola');
  }

  return prisma.schoolSubject.create({
    data: {
      schoolId,
      type: data.type as any,
      name,
      description: data.description?.trim() || null,
    },
  });
};

export const updateSchoolSubject = async (
  id: string,
  data: { name?: string; description?: string; type?: string },
  schoolId?: string,
  role?: string,
) => {
  const current = await prisma.schoolSubject.findUnique({ where: { id } });
  if (!current) throw new Error('Matéria não encontrada');
  await assertSchoolAccess(schoolId, role, current.schoolId);

  if (data.type && data.type !== current.type) {
    const offerings = await prisma.subject.count({
      where: { schoolSubjectId: id },
    });
    if (offerings > 0) {
      throw new Error(
        'Não é possível alterar o tipo de uma matéria já vinculada a turmas',
      );
    }
    const clash = await prisma.schoolSubject.findUnique({
      where: {
        schoolId_type: {
          schoolId: current.schoolId,
          type: data.type as any,
        },
      },
    });
    if (clash) {
      throw new Error('Já existe uma matéria deste tipo nesta escola');
    }
  }

  const updated = await prisma.schoolSubject.update({
    where: { id },
    data: {
      name: data.name?.trim() || undefined,
      description:
        data.description === undefined
          ? undefined
          : data.description.trim() || null,
      type: data.type ? (data.type as any) : undefined,
    },
  });

  // Mantém o nome das ofertas alinhado ao catálogo
  if (data.name?.trim()) {
    await prisma.subject.updateMany({
      where: { schoolSubjectId: id },
      data: { name: data.name.trim() },
    });
  }

  return updated;
};

export const deleteSchoolSubject = async (
  id: string,
  schoolId?: string,
  role?: string,
) => {
  const current = await prisma.schoolSubject.findUnique({ where: { id } });
  if (!current) throw new Error('Matéria não encontrada');
  await assertSchoolAccess(schoolId, role, current.schoolId);

  const offerings = await prisma.subject.count({
    where: { schoolSubjectId: id },
  });
  if (offerings > 0) {
    throw new Error(
      'Remova os vínculos com as turmas antes de excluir a matéria do catálogo',
    );
  }

  await prisma.schoolSubject.delete({ where: { id } });
};

export const ensureSchoolSubject = async (
  schoolId: string,
  type: string,
  name?: string,
) => {
  const existing = await prisma.schoolSubject.findUnique({
    where: {
      schoolId_type: {
        schoolId,
        type: type as any,
      },
    },
  });
  if (existing) return existing;

  return prisma.schoolSubject.create({
    data: {
      schoolId,
      type: type as any,
      name: name?.trim() || getSubjectLabel(type),
    },
  });
};

export const createOffering = async (
  schoolSubjectId: string,
  data: { classId: string; teacherId: string },
  schoolId?: string,
  role?: string,
) => {
  const catalog = await prisma.schoolSubject.findUnique({
    where: { id: schoolSubjectId },
  });
  if (!catalog) throw new Error('Matéria não encontrada');
  await assertSchoolAccess(schoolId, role, catalog.schoolId);

  const turma = await prisma.class.findUnique({
    where: { id: data.classId },
    select: { id: true, name: true, schoolId: true },
  });
  if (!turma) throw new Error('Turma não encontrada');
  if (turma.schoolId !== catalog.schoolId) {
    throw new Error('Turma deve ser da mesma escola da matéria');
  }

  const professor = await prisma.teacher.findUnique({
    where: { id: data.teacherId },
    select: { id: true, schoolId: true },
  });
  if (!professor) throw new Error('Professor não encontrado');
  if (professor.schoolId !== catalog.schoolId) {
    throw new Error('Professor deve ser da mesma escola da matéria');
  }

  const existing = await prisma.subject.findFirst({
    where: { classId: data.classId, type: catalog.type },
  });
  if (existing) {
    throw new Error('Esta matéria já está vinculada a esta turma');
  }

  return prisma.subject.create({
    data: {
      name: catalog.name,
      type: catalog.type,
      classId: data.classId,
      teacherId: data.teacherId,
      schoolId: catalog.schoolId,
      schoolSubjectId: catalog.id,
    },
    include: {
      class: true,
      teacher: true,
      schoolSubject: true,
    },
  });
};

export const deleteOffering = async (
  offeringId: string,
  schoolId?: string,
  role?: string,
) => {
  const offering = await prisma.subject.findUnique({
    where: { id: offeringId },
  });
  if (!offering) throw new Error('Vínculo não encontrado');
  await assertSchoolAccess(schoolId, role, offering.schoolId);

  await prisma.subject.delete({ where: { id: offeringId } });
};
