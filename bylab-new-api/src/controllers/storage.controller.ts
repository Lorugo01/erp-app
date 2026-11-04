import { Request, Response, NextFunction } from 'express';
import { StorageService } from '../services/storage.service';
import prisma from '../prisma/client';
import { storageConfig } from '../config/storage.config';
import { isProtectedUploadPath, signUploadUrl } from '../middlewares/uploadAccess.middleware';

export const uploadFile = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    if (!req.file) {
      res.status(400).json({ error: 'Arquivo não enviado. Use o campo "file".' });
      return;
    }

    const category =
      (req.query.category as string) ||
      (req.body?.category as string) ||
      'general';

    const stored = await StorageService.registerFromMulterFile(
      req.file,
      category,
      req.user?.id,
    );

    res.status(201).json(stored);
  } catch (error) {
    next(error);
  }
};

export const getFileById = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const record = await StorageService.getById(req.params.id);
    if (!record) {
      res.status(404).json({ error: 'Arquivo não encontrado' });
      return;
    }
    res.json(record);
  } catch (error) {
    next(error);
  }
};

export const deleteFile = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    await StorageService.deleteById(req.params.id);
    res.status(204).send();
  } catch (error: any) {
    if (error.message === 'Arquivo não encontrado') {
      res.status(404).json({ error: error.message });
      return;
    }
    next(error);
  }
};

export const listFiles = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const limit = Math.min(Number(req.query.limit) || 50, 100);
    const category = req.query.category as string | undefined;
    const files = await StorageService.listRecent(limit, category);
    res.json(files);
  } catch (error) {
    next(error);
  }
};

// Link temporário para abrir um anexo protegido, se o usuário tiver acesso a ele
export const signFileUrl = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const fileUrl = typeof req.body?.fileUrl === 'string' ? req.body.fileUrl.trim() : '';
    if (!fileUrl.startsWith(`${storageConfig.publicPathPrefix}/`)) {
      return res.status(400).json({ error: 'fileUrl inválido' });
    }
    const relative = fileUrl.slice(storageConfig.publicPathPrefix.length);
    if (!isProtectedUploadPath(relative)) {
      return res.json({ url: fileUrl });
    }
    if (!(await canOpenUpload(req, fileUrl))) {
      return res.status(403).json({ error: 'Acesso negado ao arquivo' });
    }
    res.json(signUploadUrl(fileUrl));
  } catch (error) {
    next(error);
  }
};

// Quem pode abrir: anexo da atividade (escola da turma), entrega (o próprio
// aluno ou staff da escola), arquivo do chat (participantes) ou quem enviou
const canOpenUpload = async (req: Request, fileUrl: string) => {
  const user = req.user!;
  if (user.role === 'DEVELOPER') return true;
  const isStaff = user.role === 'ADMIN' || user.role === 'TEACHER';

  const uploaded = await prisma.storedFile.findFirst({
    where: { publicUrl: fileUrl, uploadedById: user.id },
    select: { id: true },
  });
  if (uploaded) return true;

  const assignment = await prisma.assignment.findFirst({
    where: { fileUrl, class: { schoolId: user.schoolId ?? '' } },
    select: { id: true },
  });
  if (assignment) return true;

  const submission = await prisma.assignmentSubmission.findFirst({
    where: { fileUrl },
    select: { student: { select: { userId: true, schoolId: true } } },
  });
  if (submission) {
    return submission.student.userId === user.id || (isStaff && submission.student.schoolId === user.schoolId);
  }

  const chatFile = await prisma.file.findFirst({
    where: { file_path: fileUrl, message: { chat: { participants: { some: { user_id: user.id } } } } },
    select: { id: true },
  });
  return !!chatFile;
};
