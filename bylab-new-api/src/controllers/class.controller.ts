import { Request, Response, NextFunction } from 'express';
import * as ClassService from '../services/class.service';
import * as EventService from '../services/event.service';
import prisma from '../prisma/client';

export const getAll = async (_: Request, res: Response) => {
  const classes = await ClassService.getAllClasses();
  res.json(classes);
};

export const getById = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const turma = await ClassService.getClassById(req.params.id);
    res.json(turma);
  } catch (error) {
    next(error);
  }
};

export const getByYear = async (req: Request, res: Response) => {
  const year = parseInt(req.params.year, 10);
  const turmas = await ClassService.getClassesByYear(year);
  res.json(turmas);
};

export const getByGrade = async (req: Request, res: Response) => {
  const grade = parseInt(req.params.grade, 10);
  const turmas = await ClassService.getClassesByGrade(grade);
  res.json(turmas);
};

export const getByShift = async (req: Request, res: Response) => {
  const shift = req.params.shift.toUpperCase() as 'MATUTINO' | 'VESPERTINO' | 'NOTURNO';
  const turmas = await ClassService.getClassesByShift(shift);
  res.json(turmas);
};

export const getByName = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const name = req.params.name;
    const turmas = await ClassService.getClassesByName(name);
    res.json(turmas);
  } catch (error) {
    next(error);
  }
};

export const getEvents = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const classId = req.params.id;
    const events = await EventService.getEventsByClassId(classId);
    res.json(events);
  } catch (error) {
    next(error);
  }
};

export const addEvent = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const classId = req.params.id;
    const event = await EventService.createEvent({ ...req.body, classId });
    res.status(201).json(event);
  } catch (error) {
    next(error);
  }
};

export const updateEvent = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { eventId } = req.params;
    const event = await EventService.updateEvent(eventId, req.body);
    res.json(event);
  } catch (error) {
    next(error);
  }
};

export const deleteEvent = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { eventId } = req.params;
    await EventService.deleteEvent(eventId);
    res.status(204).send();
  } catch (error) {
    next(error);
  }
};

export const create = async (req: Request, res: Response) => {
  const turma = await ClassService.createClass(req.body);
  res.status(201).json(turma);
};

export const update = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;
    const turma = await ClassService.updateClass(id, req.body);
    res.json(turma);
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'Turma não encontrada') {
        res.status(404).json({ error: error.message });
        return;
      }
    }
    next(error);
  }
};

export const remove = async (req: Request, res: Response) => {
  const { id } = req.params;
  await ClassService.deleteClass(id);
  res.status(204).send();
};

export const addTeacherToClass = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const classId = req.params.id;
    const { teacherId } = req.body;
    // Busca um SubjectType genérico ou cria um se não existir
    let subjectType = await prisma.subjectType.findFirst({
      where: { name: 'CONTEUDO_INTERDISCIPLINAR' }
    });
    
    if (!subjectType) {
      subjectType = await prisma.subjectType.create({
        data: {
          name: 'CONTEUDO_INTERDISCIPLINAR',
          description: 'Conteúdo Interdisciplinar',
          isEvaluative: true
        }
      });
    }

    // Cria um Subject genérico para vincular o professor à turma
    const subject = await prisma.subject.create({
      data: {
        name: 'GENERICA',
        subjectTypeId: subjectType.id,
        classId,
        teacherId,
      }
    });
    res.status(201).json(subject);
  } catch (error) {
    next(error);
  }
};

export const getClassStudents = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const classId = req.params.id;
    const students = await ClassService.getClassStudents(classId);
    res.json(students);
  } catch (error) {
    next(error);
  }
};
