import { Request, Response, NextFunction } from 'express';
import * as ClassService from '../services/class.service';
import * as EventService from '../services/event.service';
import * as SubjectService from '../services/subject.service';
import prisma from '../prisma/client';

export const getAll = async (req: Request, res: Response) => {
  try {
    // DEVELOPER pode ver todas as turmas de todas as escolas
    // Outros usuários só veem turmas da sua escola
    const whereClause = req.user?.role === 'DEVELOPER'
      ? {}
      : { schoolId: req.user?.schoolId };

    const classes = await ClassService.getAllClasses(whereClause);
    res.json(classes);
  } catch (error) {
    res.status(500).json({ error: (error as Error).message });
  }
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
    const user = req.user;
    
    // Verificar se o usuário tem acesso à turma
    const turma = await prisma.class.findUnique({
      where: { id: classId },
      select: { id: true, schoolId: true }
    });
    
    if (!turma) {
      return res.status(404).json({ error: 'Turma não encontrada' });
    }
    
    // DEVELOPER pode ver eventos de qualquer turma
    // Outros usuários só podem ver eventos de turmas da sua escola
    if (user?.role !== 'DEVELOPER' && user?.schoolId && turma.schoolId !== user.schoolId) {
      return res.status(403).json({ error: 'Acesso negado a esta turma' });
    }
    
    const events = await EventService.getEventsByClassId(classId);
    res.json(events);
  } catch (error) {
    next(error);
  }
};

export const addEvent = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const classId = req.params.id;
    const user = req.user;
    const event = await EventService.createEvent(
      { ...req.body, classId }, 
      user?.schoolId, 
      user?.role
    );
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
  try {
    const { grade, letter, academicYear, shift, evaluationModel } = req.body;
    
    if (!grade || !letter || !academicYear || !shift || !evaluationModel) {
      return res.status(400).json({ 
        error: 'Todos os campos são obrigatórios: grade, letter, academicYear, shift, evaluationModel' 
      });
    }

    // DEVELOPER pode criar turmas em qualquer escola ou sem escola
    // ADMIN só pode criar turmas na sua escola
    let schoolId: string | undefined;
    if (req.user?.role === 'DEVELOPER') {
      schoolId = req.body.schoolId; // Developer can specify schoolId or leave it undefined
    } else {
      schoolId = req.user?.schoolId; // Admin can only create in their own school
    }

    if (!schoolId) {
      return res.status(400).json({ 
        error: 'schoolId é obrigatório para criar turmas' 
      });
    }

    const turma = await ClassService.createClass({
      grade,
      letter,
      academicYear,
      shift,
      evaluationModel,
      schoolId
    });
    
    res.status(201).json(turma);
  } catch (error) {
    res.status(400).json({ error: (error as Error).message });
  }
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
    const { teacherId, type } = req.body;
    const user = (req as any).user;

    // Cria offering via catálogo SchoolSubject (não duplica "Matemática" por turma)
    const subject = await SubjectService.createSubject(
      {
        type: type || 'CONTEUDO_INTERDISCIPLINAR',
        classId,
        teacherId,
      },
      user?.schoolId,
      user?.role,
    );
    res.status(201).json(subject);
  } catch (error) {
    if (error instanceof Error) {
      if (
        error.message === 'Turma não encontrada' ||
        error.message === 'Professor não encontrado'
      ) {
        res.status(404).json({ error: error.message });
        return;
      }
      if (
        error.message.includes('mesma escola') ||
        error.message.includes('já está vinculada') ||
        error.message.includes('escola diferente')
      ) {
        res.status(400).json({ error: error.message });
        return;
      }
    }
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
