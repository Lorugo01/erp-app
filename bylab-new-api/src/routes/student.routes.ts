import { Router } from 'express';
import * as StudentController from '../controllers/student.controller';
import { upload } from '../middlewares/upload.middleware';
import { authenticateToken, requireAdminOrDeveloper } from '../middlewares/auth.middleware';

const router = Router();

router.get('/', authenticateToken, StudentController.getAll);
router.get('/user/:userId', StudentController.getByUserId);
router.get('/:id', authenticateToken, StudentController.getById);
router.get('/search/:name', authenticateToken, StudentController.getByName);
router.get('/registration/:registrationNumber', authenticateToken, StudentController.getByRegistrationNumber);
router.get('/:id/current-class', authenticateToken, StudentController.getCurrentClass);
router.get('/:studentId/subjects', authenticateToken, StudentController.getStudentSubjects);

router.post('/', authenticateToken, requireAdminOrDeveloper, StudentController.create);
router.put('/:id', authenticateToken, requireAdminOrDeveloper, StudentController.update);
router.post('/:id/photo', authenticateToken, requireAdminOrDeveloper, upload.single('photo'), StudentController.uploadPhoto);
router.delete('/:id', authenticateToken, requireAdminOrDeveloper, StudentController.remove);

export default router;