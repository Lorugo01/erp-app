import { Request, Response, NextFunction } from 'express';
import * as AttendanceService from '../services/attendance.service';

export const getAll = async (_: Request, res: Response) => {
  const attendances = await AttendanceService.getAllAttendances();
  res.json(attendances);
};

export const getById = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const attendance = await AttendanceService.getAttendanceById(req.params.id);
    res.json(attendance);
  } catch (error) {
    next(error);
  }
};

export const create = async (req: Request, res: Response) => {
  const attendance = await AttendanceService.createAttendance(req.body);
  res.status(201).json(attendance);
};

export const createBulk = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { lessonId, presences } = req.body;

    const result = await AttendanceService.createBulkAttendance({ lessonId, presences });
    res.status(201).json(result);
  } catch (error) {
    next(error);
  }
};

export const update = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;
    const attendance = await AttendanceService.updateAttendance(id, req.body);
    res.json(attendance);
  } catch (error) {
    next(error);
  }
};

export const remove = async (req: Request, res: Response, next: NextFunction) => {
  try {
    await AttendanceService.deleteAttendance(req.params.id);
    res.status(204).send();
  } catch (error) {
    next(error);
  }
};

// Novo método para buscar attendance por lesson ID
export const getByLesson = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { lessonId } = req.params;
    const attendances = await AttendanceService.getAttendanceByLesson(lessonId);
    res.json(attendances);
  } catch (error) {
    next(error);
  }
};
