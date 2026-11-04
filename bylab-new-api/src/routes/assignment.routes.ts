import { Router } from 'express';
import * as AssignmentController from '../controllers/assignment.controller';
import { upload } from '../middlewares/upload.middleware';
import { authenticateToken } from '../middlewares/auth.middleware';
import {
  requireAssignmentAccess,
  requireClassAccess,
  requireStaff,
} from '../middlewares/assignmentAccess.middleware';
import {
  requireAssignmentSubjectOwner,
  requireBodySubjectOwner,
} from '../middlewares/academicAccess.middleware';

const router = Router();

router.use(authenticateToken);

// CRUD de assignments
router.get('/class/:id', requireClassAccess, AssignmentController.getAssignmentsByClass);
router.post(
  '/class/:id',
  requireStaff,
  requireClassAccess,
  requireBodySubjectOwner,
  AssignmentController.createAssignment,
);
router.post('/upload', requireStaff, upload.single('file'), AssignmentController.uploadFile);
router.post('/duplicate', requireStaff, AssignmentController.duplicateAssignment);
router.get(
  '/:id/duplicate-targets',
  requireStaff,
  requireAssignmentAccess,
  requireAssignmentSubjectOwner,
  AssignmentController.getDuplicateTargets,
);
router.post(
  '/:id/file',
  requireStaff,
  requireAssignmentAccess,
  requireAssignmentSubjectOwner,
  upload.single('file'),
  AssignmentController.uploadAssignmentFile,
);
router.delete(
  '/:id',
  requireStaff,
  requireAssignmentAccess,
  requireAssignmentSubjectOwner,
  AssignmentController.deleteAssignment,
);

// Entregas dos alunos
router.get(
  '/:id/submissions',
  requireStaff,
  requireAssignmentAccess,
  requireAssignmentSubjectOwner,
  AssignmentController.getSubmissionsByAssignment,
);
router.post(
  '/:id/submissions',
  requireAssignmentAccess,
  upload.single('file'),
  AssignmentController.createSubmission,
);
// Entrega do próprio aluno: ver sempre, editar só dentro do prazo
router.get('/:id/submissions/mine', requireAssignmentAccess, AssignmentController.getMySubmission);
router.put(
  '/:id/submissions/mine',
  requireAssignmentAccess,
  upload.single('file'),
  AssignmentController.updateMySubmission,
);

export default router; 