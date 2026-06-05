import { Request, Response, NextFunction } from 'express';
import { StorageService } from '../services/storage.service';

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
