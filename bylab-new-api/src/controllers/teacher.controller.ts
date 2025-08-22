import { Request, Response, NextFunction } from 'express';
import * as TeacherService from '../services/teacher.service';
import { renameStudentPhoto } from '../middlewares/upload.middleware';
import path from 'path';
import fs from 'fs';
import prisma from '../prisma/client';

export const getAll = async (req: Request, res: Response) => {
  try {
    // DEVELOPER pode ver todos os professores de todas as escolas
    // Outros usuários só veem professores da sua escola
    const whereClause = req.user?.role === 'DEVELOPER'
      ? {}
      : { schoolId: req.user?.schoolId };

    const teachers = await TeacherService.getAllTeachers(whereClause);
    res.json(teachers);
  } catch (error) {
    res.status(500).json({ error: (error as Error).message });
  }
};

export const getById = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const teacherId = req.params.id;
    const user = req.user;
    
    // Verificar se o usuário tem acesso ao professor
    const teacher = await prisma.teacher.findUnique({
      where: { id: teacherId },
      select: { id: true, schoolId: true }
    });
    
    if (!teacher) {
      return res.status(404).json({ error: 'Professor não encontrado' });
    }
    
    // DEVELOPER pode ver professores de qualquer escola
    // Outros usuários só podem ver professores da sua escola
    if (user?.role !== 'DEVELOPER' && user?.schoolId && teacher.schoolId !== user.schoolId) {
      return res.status(403).json({ error: 'Acesso negado a este professor' });
    }
    
    const teacherDetails = await TeacherService.getTeacherById(teacherId);
    res.json(teacherDetails);
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
    const subjectId = req.query.subjectId as string;
    const classes = await TeacherService.getTeacherClasses(teacherId, subjectId);
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

    // DEVELOPER pode criar professores em qualquer escola ou sem escola
    // ADMIN só pode criar professores na sua escola
    let schoolId: string | undefined;
    if (req.user?.role === 'DEVELOPER') {
      schoolId = req.body.schoolId; // Developer can specify schoolId or leave it undefined
    } else {
      schoolId = req.user?.schoolId; // Admin can only create in their own school
    }

    const teacher = await TeacherService.createTeacher({ 
      name, 
      email, 
      schoolId: schoolId 
    });
    
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

export const uploadPhoto = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;
    
    if (!req.file) {
      return res.status(400).json({ error: 'Nenhuma foto foi enviada' });
    }

    const tempFilePath = req.file.path;
    const photoUrl = await TeacherService.uploadTeacherPhoto(id, tempFilePath);
    
    res.json({ 
      message: 'Foto do professor atualizada com sucesso!',
      photoUrl 
    });
  } catch (error) {
    next(error);
  }
};
