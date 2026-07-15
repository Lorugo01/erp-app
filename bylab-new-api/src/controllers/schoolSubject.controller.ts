import { Request, Response, NextFunction } from 'express';
import * as SchoolSubjectService from '../services/schoolSubject.service';

export const getAll = async (req: Request, res: Response) => {
  try {
    const user = req.user;
    const items = await SchoolSubjectService.getAllSchoolSubjects(
      user?.schoolId,
      user?.role,
    );
    res.json(items);
  } catch (error: any) {
    res.status(400).json({ error: error.message || 'Erro interno do servidor' });
  }
};

export const getById = async (
  req: Request,
  res: Response,
  next: NextFunction,
) => {
  try {
    const item = await SchoolSubjectService.getSchoolSubjectById(req.params.id);
    res.json(item);
  } catch (error) {
    next(error);
  }
};

export const create = async (req: Request, res: Response) => {
  try {
    const user = req.user;
    const schoolId =
      user?.role === 'DEVELOPER'
        ? req.body.schoolId || user?.schoolId
        : user?.schoolId;
    const item = await SchoolSubjectService.createSchoolSubject(
      req.body,
      schoolId,
      user?.role,
    );
    res.status(201).json(item);
  } catch (error: any) {
    res.status(400).json({ error: error.message || 'Erro interno do servidor' });
  }
};

export const update = async (req: Request, res: Response) => {
  try {
    const user = req.user;
    const item = await SchoolSubjectService.updateSchoolSubject(
      req.params.id,
      req.body,
      user?.schoolId,
      user?.role,
    );
    res.json(item);
  } catch (error: any) {
    res.status(400).json({ error: error.message || 'Erro interno do servidor' });
  }
};

export const remove = async (req: Request, res: Response) => {
  try {
    const user = req.user;
    await SchoolSubjectService.deleteSchoolSubject(
      req.params.id,
      user?.schoolId,
      user?.role,
    );
    res.status(204).send();
  } catch (error: any) {
    res.status(400).json({ error: error.message || 'Erro interno do servidor' });
  }
};

export const createOffering = async (req: Request, res: Response) => {
  try {
    const user = req.user;
    const offering = await SchoolSubjectService.createOffering(
      req.params.id,
      req.body,
      user?.schoolId,
      user?.role,
    );
    res.status(201).json(offering);
  } catch (error: any) {
    res.status(400).json({ error: error.message || 'Erro interno do servidor' });
  }
};

export const removeOffering = async (req: Request, res: Response) => {
  try {
    const user = req.user;
    await SchoolSubjectService.deleteOffering(
      req.params.offeringId,
      user?.schoolId,
      user?.role,
    );
    res.status(204).send();
  } catch (error: any) {
    res.status(400).json({ error: error.message || 'Erro interno do servidor' });
  }
};
