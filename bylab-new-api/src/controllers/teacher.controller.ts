import { Request, Response, NextFunction } from 'express';
import * as TeacherService from '../services/teacher.service';

export const getAll = async (_: Request, res: Response) => {
  const teachers = await TeacherService.getAllTeachers();
  res.json(teachers);
};

export const getById = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const teacher = await TeacherService.getTeacherById(req.params.id);
    res.json(teacher);
  } catch (error) {
    next(error);
  }
};

export const getByName = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const teachers = await TeacherService.getTeachersByName(req.params.name);
    res.json(teachers);
  } catch (error) {
    next(error);
  }
};

export const getTeacherClasses = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const teacherId = req.params.id;
    const classes = await TeacherService.getTeacherClasses(teacherId);
    res.json(classes);
  } catch (error) {
    next(error);
  }
};


export const create = async (req: Request, res: Response) => {
  try {
    const { name, email } = req.body;
    
    if (!name || !email) {
      return res.status(400).json({ error: 'Nome e email são obrigatórios' });
    }

    const teacher = await TeacherService.createTeacher({ name, email });
    
    // Retorna resposta com informações do usuário criado
    res.status(201).json({
      message: 'Professor criado com sucesso! Um usuário foi criado automaticamente com senha padrão: 123456',
      teacher: {
        id: teacher.id,
        name: teacher.name,
        email: teacher.email,
        createdAt: teacher.createdAt
      },
      user: teacher.user
    });
  } catch (error) {
    res.status(400).json({ error: (error as Error).message });
  }
};

export const update = async (req: Request, res: Response) => {
  const { id } = req.params;
  const teacher = await TeacherService.updateTeacher(id, req.body);
  res.json(teacher);
};

export const remove = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    await TeacherService.deleteTeacher(id);
    res.status(200).json({ 
      message: 'Professor e usuário vinculado foram deletados com sucesso!' 
    });
  } catch (error) {
    res.status(400).json({ error: (error as Error).message });
  }
};
