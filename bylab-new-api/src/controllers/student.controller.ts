import { Request, Response, NextFunction } from 'express';
import * as StudentService from '../services/student.service';
import * as EnrollmentService from '../services/enrollment.service';
import path from 'path';
import { renameStudentPhoto } from '../middlewares/upload.middleware';
import fs from 'fs';

export const getAll = async (_: Request, res: Response) => {
  const students = await StudentService.getAllStudents();
  res.json(students);
};

export const getById = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const student = await StudentService.getStudentById(req.params.id);
    res.json(student);
  } catch (error) {
    next(error);
  }
};

export const getByName = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const students = await StudentService.getStudentsByName(req.params.name);
    res.json(students);
  } catch (error) {
    next(error);
  }
};

export const getByRegistrationNumber = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const student = await StudentService.getStudentByRegistrationNumber(req.params.registrationNumber);
    res.json(student);
  } catch (error) {
    next(error);
  }
};

export const getCurrentClass = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const turma = await EnrollmentService.getCurrentClassOfStudent(req.params.id);
    res.json(turma);
  } catch (error) {
    next(error);
  }
};

export const getByUserId = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const student = await StudentService.getStudentByUserId(req.params.userId);
    res.json(student);
  } catch (error) {
    next(error);
  }
};

export const create = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { name, email, registrationNumber } = req.body;
    
    if (!name || !email || !registrationNumber) {
      return res.status(400).json({ error: 'Nome, email e número de matrícula são obrigatórios' });
    }

    // Salva o arquivo temporário se foi enviado
    const tempFilePath = req.file ? path.join(__dirname, '../../uploads', req.file.filename) : undefined;
    let profilePicture: string | undefined = undefined;

    // Cria o aluno e usuário
    const student = await StudentService.createStudent({
      name,
      email,
      registrationNumber,
      profilePicture
    });
    
    // Se tiver arquivo temporário, renomeia para o ID do aluno
    if (tempFilePath && fs.existsSync(tempFilePath)) {
      const newFileName = renameStudentPhoto(tempFilePath, student.id);
      profilePicture = `/uploads/${newFileName}`;
      
      // Atualiza o aluno com o caminho da foto
      await StudentService.updateStudent(student.id, { profilePicture });
      student.profilePicture = profilePicture;
    }
    
    // Retorna resposta com informações do usuário criado
    res.status(201).json({
      message: 'Aluno criado com sucesso! Um usuário foi criado automaticamente com senha padrão: 123456',
      student: {
        id: student.id,
        name: student.name,
        email: student.email,
        registrationNumber: student.registrationNumber,
        profilePicture: student.profilePicture,
        createdAt: student.createdAt
      },
      user: student.user
    });
  } catch (error) {
    next(error);
  }
};

export const update = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;
    const { name, email, registrationNumber, phone, address, birthDate } = req.body;
    
    // Verifica se o aluno existe
    const existingStudent = await StudentService.getStudentById(id);
    
    // Salva o arquivo temporário se foi enviado
    const tempFilePath = req.file ? path.join(__dirname, '../../uploads', req.file.filename) : undefined;
    
    // Define profilePicture como string | undefined
    let profilePicture: string | undefined = existingStudent.profilePicture || undefined;
    
    // Se tiver arquivo temporário, renomeia para o ID do aluno
    if (tempFilePath && fs.existsSync(tempFilePath)) {
      // Se já existir uma foto antiga, exclui
      if (existingStudent.profilePicture) {
        const oldFilePath = path.join(__dirname, '../..', existingStudent.profilePicture);
        if (fs.existsSync(oldFilePath)) {
          fs.unlinkSync(oldFilePath);
        }
      }
      
      const newFileName = renameStudentPhoto(tempFilePath, id);
      profilePicture = `/uploads/${newFileName}`;
    }

    const student = await StudentService.updateStudent(id, {
      name,
      email,
      registrationNumber,
      profilePicture,
      phone,
      address,
      birthDate,
    });
    
    res.json(student);
  } catch (error) {
    next(error);
  }
};

export const remove = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;
    await StudentService.deleteStudent(id);
    res.status(200).json({ 
      message: 'Aluno e usuário vinculado foram deletados com sucesso!' 
    });
  } catch (error) {
    next(error);
  }
};

export const uploadPhoto = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;
    
    if (!req.file) {
      return res.status(400).json({ error: 'Nenhuma foto foi enviada' });
    }

    const tempFilePath = req.file.path;
    const photoUrl = await StudentService.uploadStudentPhoto(id, tempFilePath);
    
    res.json({ 
      message: 'Foto do aluno atualizada com sucesso!',
      photoUrl 
    });
  } catch (error) {
    next(error);
  }
};
