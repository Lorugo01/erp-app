import { Request, Response, NextFunction } from 'express';
import * as AssignmentService from '../services/assignment.service';
import { StorageService } from '../services/storage.service';
import prisma from '../prisma/client';
import { canManageSubject } from '../middlewares/academicAccess.middleware';

// O prazo vai até o fim do dia de entrega no horário de Brasília (UTC-3).
// dueDate é gravado como meia-noite do dia escolhido.
export const submissionDeadline = (dueDate: Date) =>
  new Date(Date.UTC(dueDate.getUTCFullYear(), dueDate.getUTCMonth(), dueDate.getUTCDate() + 1, 3));

const isWithinDeadline = (dueDate: Date) => Date.now() < submissionDeadline(dueDate).getTime();

// Aluno logado (null para staff)
const findOwnStudent = (req: Request) =>
  prisma.student.findUnique({ where: { userId: req.user!.id }, select: { id: true } });

// Listar assignments de uma turma
export const getAssignmentsByClass = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const classId = req.params.id;
    const { subjectId } = req.query;
    
    let assignments;
    if (subjectId && typeof subjectId === 'string') {
      assignments = await AssignmentService.getAssignmentsByClassAndSubject(classId, subjectId);
    } else {
      assignments = await AssignmentService.getAssignmentsByClass(classId);
    }
    
    res.json(assignments);
  } catch (error) {
    console.error('Erro ao buscar assignments:', error);
    next(error);
  }
};

// Criar assignment para uma turma
export const createAssignment = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const classId = req.params.id;
    const { subjectId, ...assignmentData } = req.body;
    
    if (!subjectId) {
      return res.status(400).json({ error: 'subjectId é obrigatório' });
    }

    const subject = await prisma.subject.findUnique({ where: { id: subjectId }, select: { classId: true } });
    if (subject?.classId !== classId) {
      return res.status(400).json({ error: 'A disciplina não pertence a esta turma' });
    }

    const assignment = await AssignmentService.createAssignment(classId, subjectId, assignmentData);
    res.status(201).json(assignment);
  } catch (error) {
    console.error('Erro ao criar assignment:', error);
    next(error);
  }
};

// Deletar assignment por ID
export const deleteAssignment = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const assignmentId = req.params.id;
    console.log('Tentando deletar assignment:', assignmentId);
    await AssignmentService.deleteAssignment(assignmentId);
    console.log('Assignment deletado com sucesso!');
    res.status(204).send();
  } catch (error: any) {
    console.error('Erro ao deletar assignment:', error);
    res.status(500).json({ error: error.message, stack: error.stack });
  }
};

// Listar submissões de uma assignment
export const getSubmissionsByAssignment = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const assignmentId = req.params.id;
    const submissions = await AssignmentService.getSubmissionsByAssignment(assignmentId);
    res.json(submissions);
  } catch (error) {
    console.error('Erro ao buscar submissions:', error);
    next(error);
  }
};

// Criar submissão para uma assignment
export const createSubmission = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const assignmentId = req.params.id;
    const { studentId, description } = req.body;

    // Aluno só entrega em nome próprio
    if (req.user?.role === 'STUDENT') {
      const student = await prisma.student.findUnique({
        where: { userId: req.user.id },
        select: { id: true },
      });
      if (!student || student.id !== studentId) {
        return res.status(403).json({ error: 'Acesso negado: entrega de outro aluno' });
      }
    }

    if (!req.file && !description?.trim()) {
      return res.status(400).json({ error: 'Envie um texto ou um arquivo' });
    }

    // Uma entrega por aluno; depois disso, o aluno edita a existente
    const existing = await prisma.assignmentSubmission.findFirst({
      where: { assignmentId, studentId },
      select: { id: true },
    });
    if (existing) {
      return res.status(409).json({ error: 'Você já entregou esta atividade. Edite a entrega existente.' });
    }

    let fileUrl = null;
    if (req.file) {
      const stored = await StorageService.registerFromMulterFile(
        req.file,
        'submissions',
        req.user?.id,
      );
      fileUrl = stored.fileUrl;
    }
    
    const submission = await AssignmentService.createSubmission(assignmentId, {
      studentId,
      description,
      fileUrl
    });
    
    res.status(201).json(submission);
  } catch (error) {
    console.error('Erro ao criar submission:', error);
    next(error);
  }
};

// Entrega do aluno logado, com o prazo de edição
export const getMySubmission = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const student = await findOwnStudent(req);
    if (!student) {
      return res.status(403).json({ error: 'Acesso negado: apenas alunos têm entrega própria' });
    }
    const assignment = await prisma.assignment.findUnique({
      where: { id: req.params.id },
      select: { dueDate: true },
    });
    const submission = await prisma.assignmentSubmission.findFirst({
      where: { assignmentId: req.params.id, studentId: student.id },
    });
    res.json({
      submission,
      deadline: submissionDeadline(assignment!.dueDate),
      canEdit: isWithinDeadline(assignment!.dueDate),
    });
  } catch (error) {
    next(error);
  }
};

// Aluno edita a própria entrega enquanto estiver no prazo
export const updateMySubmission = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const student = await findOwnStudent(req);
    if (!student) {
      return res.status(403).json({ error: 'Acesso negado: apenas alunos editam a própria entrega' });
    }
    const assignment = await prisma.assignment.findUnique({
      where: { id: req.params.id },
      select: { dueDate: true },
    });
    if (!isWithinDeadline(assignment!.dueDate)) {
      return res.status(403).json({ error: 'O prazo de entrega terminou; a entrega não pode mais ser editada' });
    }
    const submission = await prisma.assignmentSubmission.findFirst({
      where: { assignmentId: req.params.id, studentId: student.id },
    });
    if (!submission) {
      return res.status(404).json({ error: 'Entrega não encontrada' });
    }

    const description = typeof req.body?.description === 'string' ? req.body.description.trim() : undefined;
    const removeFile = req.body?.removeFile === 'true' || req.body?.removeFile === true;

    let fileUrl = submission.fileUrl;
    if (req.file) {
      const stored = await StorageService.registerFromMulterFile(req.file, 'submissions', req.user?.id);
      fileUrl = stored.fileUrl;
    } else if (removeFile) {
      fileUrl = null;
    }

    const finalDescription = description ?? submission.description;
    if (!fileUrl && !finalDescription?.trim()) {
      return res.status(400).json({ error: 'A entrega precisa de um texto ou um arquivo' });
    }

    const updated = await prisma.assignmentSubmission.update({
      where: { id: submission.id },
      data: { description: finalDescription, fileUrl, updatedAt: new Date() },
    });
    res.json(updated);
  } catch (error) {
    next(error);
  }
};

// Turmas para onde a atividade pode ser duplicada: mesma disciplina (tipo),
// mesma escola e, para professor, disciplinas que ele leciona
const findDuplicateTargets = async (req: Request, sourceAssignmentId: string) => {
  const source = await prisma.assignment.findUnique({
    where: { id: sourceAssignmentId },
    include: { subject: { select: { type: true, schoolId: true } } },
  });
  if (!source) return null;

  const subjects = await prisma.subject.findMany({
    where: {
      type: source.subject.type,
      schoolId: source.subject.schoolId,
      classId: { not: source.classId },
      ...(req.user?.role === 'TEACHER' ? { teacher: { userId: req.user.id } } : {}),
    },
    include: { class: { select: { id: true, name: true } } },
    orderBy: { class: { name: 'asc' } },
  });
  return { source, subjects };
};

export const getDuplicateTargets = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await findDuplicateTargets(req, req.params.id);
    if (!result) {
      return res.status(404).json({ error: 'Atividade não encontrada' });
    }
    res.json(result.subjects.map((s) => ({ id: s.class.id, name: s.class.name, subjectId: s.id })));
  } catch (error) {
    next(error);
  }
};

export const duplicateAssignment = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { sourceAssignmentId, targetClassIds, targetDate } = req.body ?? {};
    if (!sourceAssignmentId || !Array.isArray(targetClassIds) || targetClassIds.length === 0 || !targetDate) {
      return res.status(400).json({
        error: 'Campos obrigatórios: sourceAssignmentId, targetClassIds (array não vazio), targetDate',
      });
    }

    const owner = await prisma.assignment.findUnique({
      where: { id: sourceAssignmentId },
      select: { subject: { select: { schoolId: true, teacher: { select: { userId: true } } } } },
    });
    if (!owner) {
      return res.status(404).json({ error: 'Atividade não encontrada' });
    }
    if (!canManageSubject(req, owner.subject)) {
      return res.status(403).json({ error: 'Acesso negado: disciplina de outro professor' });
    }

    const result = await findDuplicateTargets(req, sourceAssignmentId);
    const byClass = new Map(result!.subjects.map((s) => [s.classId, s]));
    const invalid = targetClassIds.filter((id: string) => !byClass.has(id));
    if (invalid.length > 0) {
      return res.status(403).json({ error: 'Acesso negado: turma sem a mesma disciplina para você', invalid });
    }

    const { source } = result!;
    const created = await prisma.$transaction(
      targetClassIds.map((classId: string) =>
        prisma.assignment.create({
          data: {
            classId,
            subjectId: byClass.get(classId)!.id,
            description: source.description,
            dueDate: new Date(targetDate),
            fileUrl: source.fileUrl,
            bookId: source.bookId,
            bookTitle: source.bookTitle,
            bookCoverUrl: source.bookCoverUrl,
          },
        }),
      ),
    );
    res.status(201).json(created);
  } catch (error) {
    next(error);
  }
};

// Upload genérico de arquivo para atividades (legado — preferir POST /storage/upload)
export const uploadFile = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    if (!req.file) {
      res.status(400).json({ error: 'Arquivo não enviado' });
      return;
    }
    const stored = await StorageService.registerFromMulterFile(
      req.file,
      'assignments',
      req.user?.id,
    );
    res.status(201).json(stored);
  } catch (error) {
    next(error);
  }
};

// Upload de arquivo para assignment existente
export async function uploadAssignmentFile(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const assignmentId = req.params.id;
    if (!req.file) {
      res.status(400).json({ error: 'Arquivo não enviado' });
      return;
    }

    const stored = await StorageService.registerFromMulterFile(
      req.file,
      'assignments',
      req.user?.id,
    );

    await prisma.assignment.update({
      where: { id: assignmentId },
      data: { fileUrl: stored.fileUrl },
    });

    res.status(200).json(stored);
  } catch (error) {
    next(error);
  }
}

// Upload de arquivo para submissão
export async function uploadSubmissionFile(
  req: Request,
  res: Response,
  next: NextFunction,
) {
  try {
    const submissionId = req.params.id;
    if (!req.file) {
      res.status(400).json({ error: 'Arquivo não enviado' });
      return;
    }

    const stored = await StorageService.registerFromMulterFile(
      req.file,
      'submissions',
      req.user?.id,
    );

    await prisma.assignmentSubmission.update({
      where: { id: submissionId },
      data: { fileUrl: stored.fileUrl },
    });

    res.status(200).json(stored);
  } catch (error) {
    next(error);
  }
} 