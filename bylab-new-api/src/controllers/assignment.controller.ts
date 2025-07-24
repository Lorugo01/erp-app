import { Request, Response, NextFunction } from 'express';
import * as AssignmentService from '../services/assignment.service';
import path from 'path';
import prisma from '../prisma/client';

export const getAssignmentsByClass = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const classId = req.params.id;
    const assignments = await AssignmentService.getAssignmentsByClass(classId);
    res.json(assignments);
  } catch (error) {
    next(error);
  }
};

export const createAssignment = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const classId = req.params.id;
    const assignment = await AssignmentService.createAssignment(classId, req.body);
    res.status(201).json(assignment);
  } catch (error) {
    next(error);
  }
};

export const getSubmissionsByAssignment = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const assignmentId = req.params.id;
    const submissions = await AssignmentService.getSubmissionsByAssignment(assignmentId);
    res.json(submissions);
  } catch (error) {
    next(error);
  }
};

export const createSubmission = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const assignmentId = req.params.id;
    const submission = await AssignmentService.createSubmission(assignmentId, req.body);
    res.status(201).json(submission);
  } catch (error) {
    next(error);
  }
};

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