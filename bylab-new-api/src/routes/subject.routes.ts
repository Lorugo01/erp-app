import { Router } from 'express';
import * as SubjectController from '../controllers/subject.controller';
import { authenticateToken, requireAdminOrDeveloper } from '../middlewares/auth.middleware';

const router = Router();

router.get('/', authenticateToken, SubjectController.getAll);
router.get('/:id', authenticateToken, SubjectController.getById);
router.post('/', authenticateToken, requireAdminOrDeveloper, SubjectController.create);
router.put('/:id', authenticateToken, requireAdminOrDeveloper, SubjectController.update);
router.delete('/:id', authenticateToken, requireAdminOrDeveloper, SubjectController.remove);
router.get('/class/:classId', authenticateToken, SubjectController.getByClassId);
router.get('/class/:classId/teacher/:teacherId', authenticateToken, SubjectController.getByClassIdAndTeacher);

export default router;
