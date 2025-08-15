import { Request, Response, NextFunction } from 'express';
import * as LessonService from '../services/lesson.service';

export const create = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const lesson = await LessonService.createLesson(req.body);
    res.status(201).json(lesson);
  } catch (error) {
    next(error);
  }
};

export const getById = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const lesson = await LessonService.getLessonById(req.params.id);
    if (!lesson) {
      return res.status(404).json({ error: 'Aula não encontrada' });
    }
    res.json(lesson);
  } catch (error) {
    next(error);
  }
};

export const getOrCreate = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { classId, subjectId, teacherId, date } = req.body;
    
    if (!classId || !subjectId || !teacherId || !date) {
      return res.status(400).json({ 
        error: 'Campos obrigatórios: classId, subjectId, teacherId, date' 
      });
    }

    const lesson = await LessonService.getOrCreateLesson({
      classId,
      subjectId,
      teacherId,
      date: new Date(date),
    });

    res.json(lesson);
  } catch (error) {
    next(error);
  }
};

export const duplicate = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const {
      sourceLessonId,
      targetClassIds,
      targetDate,
      teacherId,
      subjectId,
      copyAttendance = false,
      createNewLesson = true,
      attendanceData,
    } = req.body;

    if (!sourceLessonId || !targetClassIds || !Array.isArray(targetClassIds) || targetClassIds.length === 0) {
      return res.status(400).json({
        error: 'Campos obrigatórios: sourceLessonId, targetClassIds (array não vazio)',
      });
    }

    if (!targetDate || !teacherId || !subjectId) {
      return res.status(400).json({
        error: 'Campos obrigatórios: targetDate, teacherId, subjectId',
      });
    }

    const result = await LessonService.duplicateLesson({
      sourceLessonId,
      targetClassIds,
      targetDate: new Date(targetDate),
      teacherId,
      subjectId,
      copyAttendance,
      createNewLesson,
      attendanceData,
    });

    res.status(201).json(result);
  } catch (error) {
    next(error);
  }
};

export const update = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const lesson = await LessonService.updateLesson(req.params.id, req.body);
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