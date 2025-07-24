import { Request, Response, NextFunction } from 'express';
import * as SubjectService from '../services/subject.service';

export const getAll = async (_: Request, res: Response) => {
  const subjects = await SubjectService.getAllSubjects();
  res.json(subjects);
};

export const getById = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const subject = await SubjectService.getSubjectById(req.params.id);
    res.json(subject);
  } catch (error) {
    next(error);
  }
};

export const create = async (req: Request, res: Response) => {
  const subject = await SubjectService.createSubject(req.body);
  res.status(201).json(subject);
};

export const update = async (req: Request, res: Response) => {
  const { id } = req.params;
  const subject = await SubjectService.updateSubject(id, req.body);
  res.json(subject);
};

export const remove = async (req: Request, res: Response) => {
  const { id } = req.params;
  await SubjectService.deleteSubject(id);
  res.status(204).send();
};

export const getByClassId = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const classId = req.params.classId;
    if (!classId) return res.status(400).json({ error: 'classId é obrigatório' });
    const subjects = await SubjectService.getSubjectsByClassId(classId);
    res.json(subjects);
  } catch (error) {
    next(error);
  }
};
