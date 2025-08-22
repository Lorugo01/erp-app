import { Request, Response, NextFunction } from 'express';
import * as GradeTypeService from '../services/gradeType.service';

export const getAll = async (req: Request, res: Response) => {
  try {
    const user = req.user;
    const types = await GradeTypeService.getAllGradeTypes(user?.schoolId);
    res.json(types);
  } catch (error) {
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

export const getById = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const user = req.user;
    const type = await GradeTypeService.getGradeTypeById(req.params.id, user?.schoolId);
    if (!type) {
      return res.status(404).json({ error: 'Tipo de nota não encontrado' });
    }
    res.json(type);
  } catch (error) {
    next(error);
  }
};

export const create = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const user = req.user;
    if (!user?.schoolId) {
      return res.status(400).json({ error: 'Escola não identificada' });
    }
    
    const typeData = {
      ...req.body,
      schoolId: user.schoolId
    };
    
    const type = await GradeTypeService.createGradeType(typeData);
    res.status(201).json(type);
  } catch (error) {
    next(error);
  }
};

export const update = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const user = req.user;
    const type = await GradeTypeService.updateGradeType(req.params.id, req.body, user?.schoolId);
    res.json(type);
  } catch (error) {
    next(error);
  }
};

export const remove = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const user = req.user;
    await GradeTypeService.deleteGradeType(req.params.id, user?.schoolId);
    res.status(204).send();
  } catch (error) {
    next(error);
  }
}; 