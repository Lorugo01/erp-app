import { Request, Response, NextFunction } from 'express';
import * as GradePeriodService from '../services/gradePeriod.service';

export const getAll = async (req: Request, res: Response) => {
  try {
    const user = req.user;
    const periods = await GradePeriodService.getAllGradePeriods(user?.schoolId);
    res.json(periods);
  } catch (error) {
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

export const getById = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const user = req.user;
    const period = await GradePeriodService.getGradePeriodById(req.params.id, user?.schoolId);
    if (!period) {
      return res.status(404).json({ error: 'Período não encontrado' });
    }
    res.json(period);
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
    
    const periodData = {
      ...req.body,
      schoolId: user.schoolId
    };
    
    const period = await GradePeriodService.createGradePeriod(periodData);
    res.status(201).json(period);
  } catch (error) {
    next(error);
  }
};

export const update = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const user = req.user;
    const period = await GradePeriodService.updateGradePeriod(req.params.id, req.body, user?.schoolId);
    res.json(period);
  } catch (error) {
    next(error);
  }
};

export const remove = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const user = req.user;
    await GradePeriodService.deleteGradePeriod(req.params.id, user?.schoolId);
    res.status(204).send();
  } catch (error) {
    next(error);
  }
}; 