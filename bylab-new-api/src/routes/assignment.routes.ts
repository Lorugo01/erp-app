import { Router } from 'express';
import * as AssignmentController from '../controllers/assignment.controller';

const router = Router();

// Entregas dos alunos
router.get('/assignments/:id/submissions', AssignmentController.getSubmissionsByAssignment);
router.post('/assignments/:id/submissions', AssignmentController.createSubmission);

export default router; 