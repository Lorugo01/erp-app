import { Request, Response } from 'express';
import * as GradePeriodService from '../services/gradePeriod.service';

export const getAll = async (_: Request, res: Response) => {
  const periods = await GradePeriodService.getAllGradePeriods();
  res.json(periods);
};

export const getById = async (req: Request, res: Response) => {
  const period = await GradePeriodService.getGradePeriodById(req.params.id);
  res.json(period);
};

export const create = async (req: Request, res: Response) => {
  const period = await GradePeriodService.createGradePeriod(req.body);
  res.status(201).json(period);
};

export const update = async (req: Request, res: Response) => {
  const period = await GradePeriodService.updateGradePeriod(req.params.id, req.body);
  res.json(period);
};

export const remove = async (req: Request, res: Response) => {
  await GradePeriodService.deleteGradePeriod(req.params.id);
  res.status(204).send();
}; 