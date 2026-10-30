import { Request, Response, NextFunction } from 'express';
import prisma from '../prisma/client';

const STAFF_ROLES = ['DEVELOPER', 'ADMIN', 'TEACHER'];

export const canAccessSchool = (req: Request, schoolId: string) =>
  req.user?.role === 'DEVELOPER' || req.user?.schoolId === schoolId;

// Só professor, admin ou developer (criar/excluir atividades e ver entregas)
export const requireStaff = (req: Request, res: Response, next: NextFunction) => {
  if (!STAFF_ROLES.includes(req.user?.role || '')) {
    return res.status(403).json({ error: 'Acesso negado: requer perfil de professor ou administrador' });
  }
  next();
};

// A turma de :id precisa ser da escola do usuário
export const requireClassAccess = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const classRecord = await prisma.class.findUnique({
      where: { id: req.params.id },
      select: { schoolId: true },
    });
    if (!classRecord) {
      return res.status(404).json({ error: 'Turma não encontrada' });
    }
    if (!canAccessSchool(req, classRecord.schoolId)) {
      return res.status(403).json({ error: 'Acesso negado: turma de outra escola' });
    }
    next();
  } catch (error) {
    next(error);
  }
};

// A atividade de :id precisa ser de uma turma da escola do usuário
export const requireAssignmentAccess = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const assignment = await prisma.assignment.findUnique({
      where: { id: req.params.id },
      select: { class: { select: { schoolId: true } } },
    });
    if (!assignment) {
      return res.status(404).json({ error: 'Atividade não encontrada' });
    }
    if (!canAccessSchool(req, assignment.class.schoolId)) {
      return res.status(403).json({ error: 'Acesso negado: atividade de outra escola' });
    }
    next();
  } catch (error) {
    next(error);
  }
};
