import { Request, Response, NextFunction } from 'express';
import * as SubjectService from '../services/subject.service';

export const getAll = async (req: Request, res: Response) => {
  try {
    const user = req.user;
    const subjects = await SubjectService.getAllSubjects(user?.schoolId, user?.role);
    res.json(subjects);
  } catch (error) {
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
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
  try {
    const user = req.user;
    const subject = await SubjectService.createSubject(req.body, user?.schoolId, user?.role);
    res.status(201).json(subject);
  } catch (error: any) {
    res.status(500).json({ error: error.message || 'Erro interno do servidor' });
  }
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

export const getByClassIdAndTeacher = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const classId = req.params.classId;
    const teacherId = req.params.teacherId;
    
    if (!classId) return res.status(400).json({ error: 'classId é obrigatório' });
    if (!teacherId) return res.status(400).json({ error: 'teacherId é obrigatório' });
    
    const subjects = await SubjectService.getSubjectsByClassIdAndTeacher(classId, teacherId);
    res.json(subjects);
  } catch (error) {
    next(error);
  }
};
