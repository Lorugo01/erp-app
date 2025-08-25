import prisma from '../prisma/client';

// Retorna o nome da turma baseado no grade e turno
function getGradeLabel(grade: number): string {
  const labels = [
    "1º Ano", "2º Ano", "3º Ano", "4º Ano", "5º Ano", "6º Ano",
    "7º Ano", "8º Ano", "9º Ano", "1ª Série", "2ª Série", "3ª Série"
  ];
  return labels[grade - 1] || `Ano ${grade}`;
}

export const getAllClasses = () => {
  return prisma.class.findMany({
    include: {
      enrollments: {
        include: { student: true }
      },
      subjects: {
        include: { teacher: true }
      },
      lessons: true,
    },
    orderBy: { academicYear: 'desc' }
  });
};

export const getClassById = async (id: string) => {
  if (!id || typeof id !== 'string' || id.length < 10) {
    throw new Error('ID inválido');
  }

  const turma = await prisma.class.findUnique({
    where: { id },
    include: {
      enrollments: {
        where: { current: true }, // Filtrar apenas matrículas atuais
        include: { student: true }
      },
      subjects: {
        include: { teacher: true }
      },
      lessons: true,
    },
  });

  if (!turma) throw new Error('Turma não encontrada');

  return turma;
};

export const getClassesByYear = (year: number) => {
  return prisma.class.findMany({
    where: { academicYear: year },
    include: {
      enrollments: {
        include: { student: true }
      },
      subjects: {
        include: { teacher: true }
      },
      lessons: true,
    },
  });
};

export const getClassesByGrade = (grade: number) => {
  return prisma.class.findMany({
    where: { grade },
    include: {
      enrollments: {
        include: { student: true }
      },
      subjects: {
        include: { teacher: true }
      },
      lessons: true,
    },
  });
};

export const getClassesByShift = (shift: 'MATUTINO' | 'VESPERTINO' | 'NOTURNO') => {
  return prisma.class.findMany({
    where: { shift },
    include: {
      enrollments: {
        include: { student: true }
      },
      subjects: {
        include: { teacher: true }
      },
      lessons: true,
    },
  });
};

export const getClassesByName = (name: string) => {
  return prisma.class.findMany({
    where: {
      name: {
        contains: name,
        mode: 'insensitive'
      }
    },
    include: {
      enrollments: {
        include: { student: true }
      },
      subjects: {
        include: { teacher: true }
      },
      lessons: true,
    },
  });
};

export const createClass = async (data: {
  grade: number;
  letter: string;
  academicYear: number;
  shift: 'MATUTINO' | 'VESPERTINO' | 'NOTURNO';
  evaluationModel?: string;
}) => {
  // Se evaluationModel não for fornecido, buscar da configuração padrão
  let finalEvaluationModel = data.evaluationModel;
  if (!finalEvaluationModel) {
    const config = await prisma.config.findFirst();
    finalEvaluationModel = config?.evaluationModel || 'TRADICIONAL';
  }

  const gradeLabel = getGradeLabel(data.grade);
  const turmaLetra = data.letter.toUpperCase();
  const name = `${gradeLabel} ${turmaLetra} ${data.academicYear} - ${data.shift}`;

  return prisma.class.create({
    data: {
      ...data,
      evaluationModel: finalEvaluationModel,
      letter: turmaLetra,
      name
    }
  });
};

export const updateClass = async (id: string, data: {
  grade?: number;
  letter?: string;
  academicYear?: number;
  shift?: 'MATUTINO' | 'VESPERTINO' | 'NOTURNO';
}) => {
  // Busca a turma atual para ter os dados existentes
  const turmaAtual = await prisma.class.findUnique({
    where: { id }
  });

  if (!turmaAtual) {
    throw new Error('Turma não encontrada');
  }

  // Combina os dados existentes com as atualizações
  const dadosAtualizados = {
    ...turmaAtual,
    ...data,
    letter: data.letter ? data.letter.toUpperCase() : turmaAtual.letter
  };

  // Gera o novo nome da turma
  const gradeLabel = getGradeLabel(dadosAtualizados.grade);
  const name = `${gradeLabel} ${dadosAtualizados.letter} ${dadosAtualizados.academicYear} - ${dadosAtualizados.shift}`;

  // Atualiza a turma com todos os dados
  return prisma.class.update({
    where: { id },
    data: {
      ...data,
      letter: data.letter ? data.letter.toUpperCase() : undefined,
      name
    },
    include: {
      enrollments: {
        where: { current: true },
        include: { student: true }
      },
      subjects: {
        include: { teacher: true }
      },
      lessons: true,
    }
  });
};

export const deleteClass = (id: string) => {
  return prisma.class.delete({
    where: { id },
  });
};

export const getClassStudents = async (classId: string) => {
  const classData = await prisma.class.findUnique({
    where: { id: classId },
    include: {
      enrollments: {
        where: { current: true }, // Filtrar apenas matrículas atuais
        include: {
          student: {
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
        }
      }
    }
  });

  if (!classData) {
    throw new Error('Turma não encontrada');
  }

  // Retorna apenas os alunos (sem as informações de matrícula)
  return classData.enrollments.map(enrollment => enrollment.student);
};
