import { Request, Response, NextFunction } from 'express';
import * as EnrollmentService from '../services/enrollment.service';

export const create = async (req: Request, res: Response) => {
  try {
    const enrollment = await EnrollmentService.createEnrollment(req.body);
    res.status(201).json(enrollment);
  } catch (error: any) {
    if (error.message.includes('já está matriculado')) {
      res.status(400).json({ error: error.message });
    } else {
      res.status(500).json({ error: 'Erro interno do servidor' });
    }
  }
};

export const getAll = async (_: Request, res: Response) => {
  const enrollments = await EnrollmentService.getAllEnrollments();
  res.json({ items: enrollments });
};

export const getById = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const enrollment = await EnrollmentService.getEnrollmentById(req.params.id);
    res.json(enrollment);
  } catch (error) {
    next(error);
  }
};

export const getByStudent = async (req: Request, res: Response) => {
  const enrollments = await EnrollmentService.getEnrollmentsByStudentId(req.params.studentId);
  res.json(enrollments);
};

export const update = async (req: Request, res: Response) => {
  const updated = await EnrollmentService.updateEnrollment(req.params.id, req.body);
  res.json(updated);
};

export const remove = async (req: Request, res: Response) => {
  await EnrollmentService.deleteEnrollment(req.params.id);
  res.status(204).send();
};
