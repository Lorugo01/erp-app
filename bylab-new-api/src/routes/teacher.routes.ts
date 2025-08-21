import { Router } from 'express';
import * as TeacherController from '../controllers/teacher.controller';
import { upload } from '../middlewares/upload.middleware';
import { authenticateToken, requireAdminOrDeveloper } from '../middlewares/auth.middleware';

const router = Router();

router.get('/', authenticateToken, TeacherController.getAll);
router.get('/:id/classes', authenticateToken, TeacherController.getTeacherClasses);
router.get('/:id', authenticateToken, TeacherController.getById);
router.get('/search/:name', authenticateToken, TeacherController.getByName);
router.post('/', authenticateToken, requireAdminOrDeveloper, TeacherController.create);
router.put('/:id', authenticateToken, requireAdminOrDeveloper, TeacherController.update);
router.post('/:id/photo', authenticateToken, requireAdminOrDeveloper, upload.single('photo'), TeacherController.uploadPhoto);
router.delete('/:id', authenticateToken, requireAdminOrDeveloper, TeacherController.remove);

export default router;
