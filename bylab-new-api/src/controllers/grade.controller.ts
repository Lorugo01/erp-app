import { Request, Response, NextFunction } from 'express';
import * as GradeService from '../services/grade.service';

export const getAll = async (_: Request, res: Response) => {
  const grades = await GradeService.getAllGrades();
  res.json(grades);
};

export const getById = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const grade = await GradeService.getGradeById(req.params.id);
    res.json(grade);
  } catch (error) {
    next(error);
  }
};

export const create = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const grade = await GradeService.createGrade(req.body);
    res.status(201).json(grade);
  } catch (error) {
    next(error);
  }
};

export const update = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const grade = await GradeService.updateGrade(req.params.id, req.body);
    res.json(grade);
  } catch (error) {
    next(error);
  }
};

export const remove = async (req: Request, res: Response, next: NextFunction) => {
  try {
    await GradeService.deleteGrade(req.params.id);
    res.status(204).send();
  } catch (error) {
    next(error);
  }
};

export const getByStudent = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const grades = await GradeService.getGradesByStudentId(req.params.studentId);
    res.json(grades);
  } catch (error) {
    next(error);
  }
};

export const getBySubject = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const grades = await GradeService.getGradesBySubjectId(req.params.subjectId);
    res.json(grades);
  } catch (error) {
    next(error);
  }
};

// Novo endpoint: Boletim consolidado do aluno
export const getBoletim = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const boletim = await GradeService.getBoletimCompleto(req.params.studentId);
    res.json(boletim);
  } catch (error) {
    next(error);
  }
}; 