import { Request, Response, NextFunction } from 'express';
import * as AssignmentService from '../services/assignment.service';
import prisma from '../prisma/client';

// Listar assignments de uma turma
export const getAssignmentsByClass = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const classId = req.params.id;
    const assignments = await AssignmentService.getAssignmentsByClass(classId);
    res.json(assignments);
  } catch (error) {
    console.error('Erro ao buscar assignments:', error);
    next(error);
  }
};

// Criar assignment para uma turma
export const createAssignment = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const classId = req.params.id;
    const assignment = await AssignmentService.createAssignment(classId, req.body);
    res.status(201).json(assignment);
  } catch (error) {
    console.error('Erro ao criar assignment:', error);
    next(error);
  }
};

// Deletar assignment por ID
export const deleteAssignment = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const assignmentId = req.params.id;
    console.log('Tentando deletar assignment:', assignmentId);
    await AssignmentService.deleteAssignment(assignmentId);
    console.log('Assignment deletado com sucesso!');
    res.status(204).send();
  } catch (error: any) {
    console.error('Erro ao deletar assignment:', error);
    res.status(500).json({ error: error.message, stack: error.stack });
  }
};

// Listar submissões de uma assignment
export const getSubmissionsByAssignment = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const assignmentId = req.params.id;
    const submissions = await AssignmentService.getSubmissionsByAssignment(assignmentId);
    res.json(submissions);
  } catch (error) {
    console.error('Erro ao buscar submissions:', error);
    next(error);
  }
};

// Criar submissão para uma assignment
export const createSubmission = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const assignmentId = req.params.id;
    const submission = await AssignmentService.createSubmission(assignmentId, req.body);
    res.status(201).json(submission);
  } catch (error) {
    console.error('Erro ao criar submission:', error);
    next(error);
  }
};

// Upload de arquivo para assignment
export function uploadAssignmentFile(req: Request, res: Response, next: NextFunction) {
  const assignmentId = req.params.id;
  if (!req.file) return res.status(400).json({ error: 'Arquivo não enviado' });
  const fileUrl = `/uploads/${req.file.filename}`;
  prisma.assignment.update({
    where: { id: assignmentId },
    data: { fileUrl },
  })
    .then(() => res.status(200).json({ fileUrl }))
    .catch(next);
}

// Upload de arquivo para submissão
export function uploadSubmissionFile(req: Request, res: Response, next: NextFunction) {
  const submissionId = req.params.id;
  if (!req.file) return res.status(400).json({ error: 'Arquivo não enviado' });
  const fileUrl = `/uploads/${req.file.filename}`;
  prisma.assignmentSubmission.update({
    where: { id: submissionId },
    data: { fileUrl },
  })
    .then(() => res.status(200).json({ fileUrl }))
    .catch(next);
} 