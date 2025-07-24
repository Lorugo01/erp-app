import { Request, Response, NextFunction } from 'express';
import * as GradeTypeService from '../services/gradeType.service';

export const getAll = async (_: Request, res: Response) => {
  const types = await GradeTypeService.getAllGradeTypes();
  res.json(types);
};

export const getById = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const type = await GradeTypeService.getGradeTypeById(req.params.id);
    res.json(type);
  } catch (error) {
    next(error);
  }
};

export const create = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const type = await GradeTypeService.createGradeType(req.body);
    res.status(201).json(type);
  } catch (error) {
    next(error);
  }
};

export const update = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const type = await GradeTypeService.updateGradeType(req.params.id, req.body);
    res.json(type);
  } catch (error) {
    next(error);
  }
};

export const remove = async (req: Request, res: Response, next: NextFunction) => {
  try {
    await GradeTypeService.deleteGradeType(req.params.id);
    res.status(204).send();
  } catch (error) {
    next(error);
  }
}; 