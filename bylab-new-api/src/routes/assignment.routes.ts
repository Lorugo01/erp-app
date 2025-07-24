import { Router } from 'express';
import * as AssignmentController from '../controllers/assignment.controller';

const router = Router();

// CRUD de assignments
router.get('/class/:id', AssignmentController.getAssignmentsByClass); // Listar assignments de uma turma
router.post('/class/:id', AssignmentController.createAssignment); // Criar assignment para uma turma
router.delete('/:id', AssignmentController.deleteAssignment); // Deletar assignment por ID

// Entregas dos alunos
router.get('/:id/submissions', AssignmentController.getSubmissionsByAssignment);
router.post('/:id/submissions', AssignmentController.createSubmission);

export default router; 