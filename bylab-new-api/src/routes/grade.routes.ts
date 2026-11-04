import { Router } from 'express';
import * as GradeController from '../controllers/grade.controller';
import { authenticateToken } from '../middlewares/auth.middleware';
import { requireStaff } from '../middlewares/assignmentAccess.middleware';
import {
  requireBodyStudent,
  requireBodySubjectOwner,
  requireGradeAccess,
  requireGradeSubjectOwner,
  requireStudentParam,
  requireSubjectParam,
} from '../middlewares/academicAccess.middleware';

const router = Router();

router.use(authenticateToken);

// Rota do boletim consolidado (deve vir antes de /:id para não conflitar)
router.get('/boletim/:studentId', requireStudentParam, GradeController.getBoletim);

router.get('/', requireStaff, GradeController.getAll);
router.get('/:id', requireGradeAccess, GradeController.getById);
router.post('/', requireStaff, requireBodyStudent, requireBodySubjectOwner, GradeController.create);
router.put(
  '/:id',
  requireStaff,
  requireGradeAccess,
  requireGradeSubjectOwner,
  requireBodyStudent,
  requireBodySubjectOwner,
  GradeController.update,
);
router.delete('/:id', requireStaff, requireGradeAccess, requireGradeSubjectOwner, GradeController.remove);
router.get('/student/:studentId', requireStudentParam, GradeController.getByStudent);
router.get('/subject/:subjectId', requireStaff, requireSubjectParam, GradeController.getBySubject);

export default router; 