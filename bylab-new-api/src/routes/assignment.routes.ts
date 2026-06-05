import { Router } from 'express';
import * as AssignmentController from '../controllers/assignment.controller';
import { upload } from '../middlewares/upload.middleware';
import { authenticateToken } from '../middlewares/auth.middleware';

const router = Router();

// CRUD de assignments
router.get('/class/:id', AssignmentController.getAssignmentsByClass);
router.post('/class/:id', AssignmentController.createAssignment);
router.post('/upload', authenticateToken, upload.single('file'), AssignmentController.uploadFile);
router.post('/:id/file', authenticateToken, upload.single('file'), AssignmentController.uploadAssignmentFile);
router.delete('/:id', AssignmentController.deleteAssignment);

// Entregas dos alunos
router.get('/:id/submissions', AssignmentController.getSubmissionsByAssignment);
router.post(
  '/:id/submissions',
  authenticateToken,
  upload.single('file'),
  AssignmentController.createSubmission,
);

export default router; 