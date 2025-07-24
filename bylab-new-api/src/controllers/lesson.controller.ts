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

export const update = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;
    const lesson = await LessonService.updateLesson(id, req.body);
    res.json(lesson);
  } catch (error) {
    next(error);
  }
};

export const remove = async (req: Request, res: Response, next: NextFunction) => {
  try {
    await LessonService.deleteLesson(req.params.id);
    res.status(204).send();
  } catch (error) {
    next(error);
  }
};

export const getOrCreateByClassDate = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { classId, date, subjectId, teacherId } = req.body;
    
    if (!classId || !date || !subjectId || !teacherId) {
      return res.status(400).json({ error: 'classId, date, subjectId e teacherId são obrigatórios' });
    }

    // Valida e converte a data
    const parsedDate = new Date(date);
    if (isNaN(parsedDate.getTime())) {
      return res.status(400).json({ error: 'Formato de data inválido. Use ISO-8601.' });
    }

    const lesson = await LessonService.getOrCreateLessonByClassDate({ 
      classId, 
      date: parsedDate, 
      subjectId, 
      teacherId 
    });
    res.json(lesson);
  } catch (error) {
    next(error);
  }
};
