import prisma from '../prisma/client';

export const getAllGrades = () => {
  return prisma.grade.findMany({
    include: {
      student: true,
      subject: true,
      type: true,
      period: true,
    },
    orderBy: { date: 'desc' },
  });
};

export const getGradeById = (id: string) => {
  return prisma.grade.findUnique({
    where: { id },
    include: {
      student: true,
      subject: true,
      type: true,
      period: true,
    },
  });
};

export const createGrade = async (data: {
  studentId: string;
  subjectId: string;
  typeId: string;
  periodId: string;
  value?: number;
  concept?: string;
  date?: Date;
}) => {
  const { studentId, subjectId, typeId, periodId, value, concept, date } = data;

  // Verifica se já existe nota desse tipo para o mesmo aluno, disciplina e período
  const existing = await prisma.grade.findFirst({
    where: {
      studentId,
      subjectId,
      typeId,
      periodId,
    },
  });

  if (existing) {
    throw new Error('Já existe uma nota desse tipo para este aluno, disciplina e período.');
  }

  return prisma.grade.create({
    data: { studentId, subjectId, typeId, periodId, value, concept, date },
  });
};

export const updateGrade = async (
  id: string,
  data: Partial<{
    studentId: string;
    subjectId: string;
    typeId: string;
    periodId: string;
    value?: number;
    concept?: string;
    date?: Date;
  }>
) => {
  const { studentId, subjectId, typeId, periodId, value, concept, date } = data;

  // Se for atualizar os campos que compõem a chave de unicidade, verifica duplicidade
  if (studentId && subjectId && typeId && periodId) {
    const existing = await prisma.grade.findFirst({
      where: {
        studentId,
        subjectId,
        typeId,
        periodId,
        NOT: { id },
      },
    });
    if (existing) {
      throw new Error('Já existe uma nota desse tipo para este aluno, disciplina e período.');
    }
  }

  return prisma.grade.update({
    where: { id },
    data: { studentId, subjectId, typeId, periodId, value, concept, date },
  });
};

export const deleteGrade = (id: string) => {
  return prisma.grade.delete({ where: { id } });
};

export const getGradesByStudentId = (studentId: string) => {
  return prisma.grade.findMany({
    where: { studentId },
    include: {
      subject: true,
      type: true,
      period: true,
    },
    orderBy: { date: 'desc' },
  });
};

export const getGradesBySubjectId = (subjectId: string) => {
  return prisma.grade.findMany({
    where: { subjectId },
    include: {
      student: true,
      type: true,
      period: true,
    },
    orderBy: { date: 'desc' },
  });
};

// Utilitário: calcula média simples de um array de números
function calcularMedia(valores: number[]): number {
  if (!valores.length) return 0;
  return Number((valores.reduce((a, b) => a + b, 0) / valores.length).toFixed(2));
}

// Função auxiliar para calcular a média considerando recuperações
const isRecoveryGrade = (grade: any) =>
  grade.type?.isRecovery === true ||
  ['RECUPERACAO', 'RECUPERACAO_FINAL'].includes(grade.typeId);

const calculateFinalGrade = (grades: any[]) => {
  const regularGrades = grades.filter(g => !isRecoveryGrade(g));
  const recoveryGrades = grades.filter(g => isRecoveryGrade(g));

  if (regularGrades.length === 0) return 0;

  let finalGrades = [...regularGrades];

  let minGradeIndex = 0;
  for (let i = 1; i < finalGrades.length; i++) {
    if ((finalGrades[i].value ?? 0) < (finalGrades[minGradeIndex].value ?? 0)) {
      minGradeIndex = i;
    }
  }

  const minValue = finalGrades[minGradeIndex].value ?? 0;
  const bestRecovery = recoveryGrades.reduce<any | null>((best, grade) => {
    if (grade.value == null) return best;
    if (!best || grade.value > best.value) return grade;
    return best;
  }, null);

  if (bestRecovery && bestRecovery.value > minValue) {
    finalGrades[minGradeIndex] = bestRecovery;
  }

  const sum = finalGrades.reduce((acc, grade) => acc + (grade.value || 0), 0);
  const average = sum / finalGrades.length;
  
  return Number(average.toFixed(1));
};

export const getGradesByStudent = async (studentId: string) => {
  const grades = await prisma.grade.findMany({
    where: { studentId },
    include: {
      student: true,
      subject: true,
      type: true,
      period: true
    },
    orderBy: [
      { period: { startDate: 'asc' } },
      { type: { name: 'asc' } }
    ]
  });

  // Agrupar notas por período e disciplina
  const groupedGrades = grades.reduce((acc, grade) => {
    const key = `${grade.periodId}-${grade.subjectId}`;
    if (!acc[key]) {
      acc[key] = [];
    }
    acc[key].push(grade);
    return acc;
  }, {} as Record<string, any[]>);

  // Calcular médias finais considerando recuperações
  for (const key in groupedGrades) {
    const gradesGroup = groupedGrades[key];
    const average = calculateFinalGrade(gradesGroup);
    
    // Adicionar a média calculada a cada nota do grupo
    gradesGroup.forEach(grade => {
      grade.calculatedAverage = average;
      // Adicionar flag para indicar se a nota foi substituída
      if (isRecoveryGrade(grade)) {
        const regularGrades = gradesGroup.filter(g => !isRecoveryGrade(g));
        if (regularGrades.length === 0) return;
        const minRegularGrade = Math.min(...regularGrades.map(g => g.value ?? 0));
        grade.replacedGrade = (grade.value ?? 0) > minRegularGrade;
      }
    });
  }

  return grades;
};

// Utilitário: retorna status de aprovação por nota e frequência
export async function getBoletimCompleto(studentId: string) {
  // Busca todas as notas do aluno
  const grades = await prisma.grade.findMany({
    where: { studentId },
    include: {
      subject: true,
      type: true,
      period: true,
    },
    orderBy: { date: 'asc' },
  });

  // Busca todas as disciplinas do aluno
  const enrollments = await prisma.enrollment.findMany({
    where: { studentId },
    include: { class: { include: { subjects: true } } },
  });
  const subjects = enrollments.flatMap(e => e.class.subjects);

  // Busca frequência
  const attendances = await prisma.attendance.findMany({
    where: { studentId },
    include: { lesson: { include: { subject: true } } },
  });

  // Busca configuração global
  const config = await prisma.config.findFirst();
  const minGrade = config?.minGrade ?? 5.0;
  const minAttendance = config?.minAttendance ?? 75.0;

  // Agrupa boletim por disciplina
  const boletim = subjects.map(subject => {
    // Notas/conceitos dessa disciplina
    const gradesDisc = grades.filter(g => g.subjectId === subject.id);
    // Agrupa por período
    const periodos = Array.from(new Set(gradesDisc.map(g => g.period?.name)));
    const notasPorPeriodo = periodos.map(periodo => {
      const notasPeriodo = gradesDisc.filter(g => g.period?.name === periodo && g.type?.isConcept === false && g.value !== null);
      return {
        periodo,
        notas: notasPeriodo.map(n => n.value),
        media: calcularMedia(notasPeriodo.map(n => n.value as number)),
      };
    });
    // Média anual (todas as notas numéricas)
    const todasNotas = gradesDisc.filter(g => g.type?.isConcept === false && g.value !== null).map(g => g.value as number);
    const mediaFinal = calcularMedia(todasNotas);
    // Conceitos (se houver)
    const conceitos = gradesDisc.filter(g => g.type?.isConcept === true && g.concept !== null).map(g => g.concept);
    // Recuperação (se houver)
    const rec = gradesDisc.find(g => g.type?.isRecovery === true);
    let mediaComRec = mediaFinal;
    if (rec && rec.value !== null && (rec.value as number) > mediaFinal) {
      mediaComRec = rec.value as number;
    }
    // Frequência
    const totalAulas = attendances.filter(a => a.lesson.subjectId === subject.id).length;
    const presencas = attendances.filter(a => a.lesson.subjectId === subject.id && a.present).length;
    const freq = totalAulas > 0 ? Number(((presencas / totalAulas) * 100).toFixed(2)) : 100;
    // Status
    let status = 'Aprovado';
    if (mediaComRec < minGrade) status = 'Reprovado por nota';
    if (freq < minAttendance) status = 'Reprovado por frequência';
    if (mediaComRec < minGrade && freq < minAttendance) status = 'Reprovado por nota e frequência';
    return {
      disciplina: subject.name,
      periodos: notasPorPeriodo,
      conceitos,
      mediaFinal,
      mediaComRec,
      frequencia: freq,
      status,
    };
  });
  return boletim;
} 