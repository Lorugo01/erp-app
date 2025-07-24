import { Request, Response, NextFunction } from 'express';
import * as LessonService from '../services/lesson.service';

export const getAll = async (_: Request, res: Response) => {
  const lessons = await LessonService.getAllLessons();
  res.json(lessons);
};

export const getById = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const lesson = await LessonService.getLessonById(req.params.id);
    res.json(lesson);
  } catch (error) {
    next(error);
  }
};

export const create = async (req: Request, res: Response) => {
  const lesson = await LessonService.createLesson(req.body);
  res.status(201).json(lesson);
};

export const update = async (req: Request, res: Response) => {
  const { id } = req.params;
  const lesson = await LessonService.updateLesson(id, req.body);
  res.json(lesson);
};

export const remove = async (req: Request, res: Response) => {
  const { id } = req.params;
  await LessonService.deleteLesson(id);
  res.status(204).send();
};

export const getOrCreateByClassDate = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { classId, date, subjectId, teacherId } = req.body;
    if (!classId || !date || !subjectId || !teacherId) {
      return res.status(400).json({ error: 'classId, date, subjectId e teacherId são obrigatórios' });
    }
    const lesson = await LessonService.getOrCreateLessonByClassDate({ classId, date, subjectId, teacherId });
    res.json(lesson);
  } catch (error) {
    next(error);
  }
};
