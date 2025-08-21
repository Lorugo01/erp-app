import { Router } from 'express';
import * as EnrollmentController from '../controllers/enrollment.controller';
import { authenticateToken, requireAdminOrDeveloper } from '../middlewares/auth.middleware';

const router = Router();

router.get('/', authenticateToken, EnrollmentController.getAll);
router.get('/:id', authenticateToken, EnrollmentController.getById);
router.get('/student/:studentId', authenticateToken, EnrollmentController.getByStudent);
router.post('/', authenticateToken, requireAdminOrDeveloper, EnrollmentController.create);
router.put('/:id', authenticateToken, requireAdminOrDeveloper, EnrollmentController.update);
router.delete('/:id', authenticateToken, requireAdminOrDeveloper, EnrollmentController.remove);

export default router;
