import { Request, Response, NextFunction } from 'express';
import prisma from '../prisma/client';
import { canAccessSchool } from './assignmentAccess.middleware';

type Denial = { status: number; error: string } | null;

const guard =
  (check: (req: Request) => Promise<Denial>) =>
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const denial = await check(req);
      if (denial) {
        return res.status(denial.status).json({ error: denial.error });
      }
      next();
    } catch (error) {
      next(error);
    }
  };

const notFound = (error: string): Denial => ({ status: 404, error });
const forbidden = (error: string): Denial => ({ status: 403, error: `Acesso negado: ${error}` });

const studentSelect = { schoolId: true, userId: true };
const lessonSelect = { class: { select: { schoolId: true } } };

// Staff vê os alunos da própria escola; aluno vê apenas os próprios dados
const denyStudent = (
  req: Request,
  student: { schoolId: string; userId: string | null } | null,
): Denial => {
  if (!student) return notFound('Aluno não encontrado');
  if (!canAccessSchool(req, student.schoolId)) return forbidden('aluno de outra escola');
  if (req.user?.role === 'STUDENT' && student.userId !== req.user.id) {
    return forbidden('dados de outro aluno');
  }
  return null;
};

const denyStudentById = async (req: Request, id: string): Promise<Denial> => {
  const student = await prisma.student.findUnique({ where: { id }, select: studentSelect });
  return denyStudent(req, student);
};

const denyLessonById = async (req: Request, id: string): Promise<Denial> => {
  const lesson = await prisma.lesson.findUnique({ where: { id }, select: lessonSelect });
  if (!lesson) return notFound('Aula não encontrada');
  return canAccessSchool(req, lesson.class.schoolId) ? null : forbidden('aula de outra escola');
};

const denyClassById = async (req: Request, id: string): Promise<Denial> => {
  const classRecord = await prisma.class.findUnique({ where: { id }, select: { schoolId: true } });
  if (!classRecord) return notFound('Turma não encontrada');
  return canAccessSchool(req, classRecord.schoolId) ? null : forbidden('turma de outra escola');
};

export const requireStudentParam = guard((req) => denyStudentById(req, req.params.studentId));

// studentId no corpo é opcional no PUT; quando vier, precisa ser acessível
export const requireBodyStudent = guard(async (req) =>
  req.body?.studentId ? denyStudentById(req, req.body.studentId) : null,
);

export const requireSubjectParam = guard(async (req) => {
  const subject = await prisma.subject.findUnique({
    where: { id: req.params.subjectId },
    select: { schoolId: true },
  });
  if (!subject) return notFound('Disciplina não encontrada');
  return canAccessSchool(req, subject.schoolId) ? null : forbidden('disciplina de outra escola');
});

export const requireGradeAccess = guard(async (req) => {
  const grade = await prisma.grade.findUnique({
    where: { id: req.params.id },
    select: { student: { select: studentSelect } },
  });
  return grade ? denyStudent(req, grade.student) : notFound('Nota não encontrada');
});

export const requireAttendanceAccess = guard(async (req) => {
  const attendance = await prisma.attendance.findUnique({
    where: { id: req.params.id },
    select: { student: { select: studentSelect } },
  });
  return attendance ? denyStudent(req, attendance.student) : notFound('Frequência não encontrada');
});

export const requireLessonParam = (param: 'id' | 'lessonId') =>
  guard((req) => denyLessonById(req, req.params[param]));

export const requireBodyLesson = guard(async (req) =>
  req.body?.lessonId ? denyLessonById(req, req.body.lessonId) : notFound('Aula não encontrada'),
);

export const requireBodyClass = guard(async (req) =>
  req.body?.classId ? denyClassById(req, req.body.classId) : null,
);

// Duplicar aula: a aula de origem e todas as turmas de destino
export const requireLessonDuplication = guard(async (req) => {
  const { sourceLessonId, targetClassIds } = req.body ?? {};
  if (sourceLessonId) {
    const denial = await denyLessonById(req, sourceLessonId);
    if (denial) return denial;
  }
  for (const classId of Array.isArray(targetClassIds) ? targetClassIds : []) {
    const denial = await denyClassById(req, classId);
    if (denial) return denial;
  }
  return null;
});

// --- Disciplina do professor ---------------------------------------------
// Admin e developer gerenciam qualquer disciplina da escola; o professor,
// só as que ele leciona (notas, presença, aulas e atividades).

const subjectSelect = { schoolId: true, teacher: { select: { userId: true } } };
type SubjectOwner = { schoolId: string; teacher: { userId: string | null } };

export const canManageSubject = (req: Request, subject: SubjectOwner) =>
  canAccessSchool(req, subject.schoolId) &&
  (req.user?.role !== 'TEACHER' || subject.teacher.userId === req.user.id);

const denySubject = (req: Request, subject: SubjectOwner | null): Denial => {
  if (!subject) return notFound('Disciplina não encontrada');
  return canManageSubject(req, subject) ? null : forbidden('disciplina de outro professor');
};

const denySubjectById = async (req: Request, id: string): Promise<Denial> =>
  denySubject(req, await prisma.subject.findUnique({ where: { id }, select: subjectSelect }));

// subjectId no corpo é opcional em alguns PUTs; quando vier, precisa ser do professor
export const requireBodySubjectOwner = guard(async (req) =>
  req.body?.subjectId ? denySubjectById(req, req.body.subjectId) : null,
);

export const requireAssignmentSubjectOwner = guard(async (req) => {
  const assignment = await prisma.assignment.findUnique({
    where: { id: req.params.id },
    select: { subject: { select: subjectSelect } },
  });
  return assignment ? denySubject(req, assignment.subject) : notFound('Atividade não encontrada');
});

export const requireGradeSubjectOwner = guard(async (req) => {
  const grade = await prisma.grade.findUnique({
    where: { id: req.params.id },
    select: { subject: { select: subjectSelect } },
  });
  return grade ? denySubject(req, grade.subject) : notFound('Nota não encontrada');
});

export const requireAttendanceSubjectOwner = guard(async (req) => {
  const attendance = await prisma.attendance.findUnique({
    where: { id: req.params.id },
    select: { lesson: { select: { subject: { select: subjectSelect } } } },
  });
  return attendance ? denySubject(req, attendance.lesson.subject) : notFound('Frequência não encontrada');
});

const denyLessonSubject = async (req: Request, id: string): Promise<Denial> => {
  const lesson = await prisma.lesson.findUnique({
    where: { id },
    select: { subject: { select: subjectSelect } },
  });
  return lesson ? denySubject(req, lesson.subject) : notFound('Aula não encontrada');
};

export const requireLessonSubjectOwner = guard((req) => denyLessonSubject(req, req.params.id));

export const requireBodyLessonSubjectOwner = guard(async (req) =>
  req.body?.lessonId ? denyLessonSubject(req, req.body.lessonId) : notFound('Aula não encontrada'),
);

export const requireSourceLessonSubjectOwner = guard(async (req) =>
  req.body?.sourceLessonId ? denyLessonSubject(req, req.body.sourceLessonId) : null,
);

// Developer vê qualquer escola; admin e professor, só a própria
export const requireOwnSchool = (req: Request, res: Response, next: NextFunction) => {
  if (!canAccessSchool(req, req.params.id)) {
    return res.status(403).json({ error: 'Acesso negado: escola diferente da sua' });
  }
  next();
};
