import { Router } from 'express';
import * as AssignmentController from '../controllers/assignment.controller';
import { upload } from '../middlewares/upload.middleware';
import { authenticateToken } from '../middlewares/auth.middleware';
import {
  requireAssignmentAccess,
  requireClassAccess,
  requireStaff,
} from '../middlewares/assignmentAccess.middleware';

const router = Router();

router.use(authenticateToken);

// CRUD de assignments
router.get('/class/:id', requireClassAccess, AssignmentController.getAssignmentsByClass);
router.post('/class/:id', requireStaff, requireClassAccess, AssignmentController.createAssignment);
router.post('/upload', requireStaff, upload.single('file'), AssignmentController.uploadFile);
router.post(
  '/:id/file',
  requireStaff,
  requireAssignmentAccess,
  upload.single('file'),
  AssignmentController.uploadAssignmentFile,
);
router.delete('/:id', requireStaff, requireAssignmentAccess, AssignmentController.deleteAssignment);

// Entregas dos alunos
router.get(
  '/:id/submissions',
  requireStaff,
  requireAssignmentAccess,
  AssignmentController.getSubmissionsByAssignment,
);
router.post(
  '/:id/submissions',
  requireAssignmentAccess,
  upload.single('file'),
  AssignmentController.createSubmission,
);

export default router; 