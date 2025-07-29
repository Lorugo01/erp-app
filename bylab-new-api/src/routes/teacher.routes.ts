import { Router } from 'express';
import * as TeacherController from '../controllers/teacher.controller';
import { upload } from '../middlewares/upload.middleware';

const router = Router();

router.get('/', TeacherController.getAll);
router.get('/:id/classes', TeacherController.getTeacherClasses);
router.get('/:id', TeacherController.getById);
router.get('/search/:name', TeacherController.getByName);
router.post('/', TeacherController.create);
router.put('/:id', TeacherController.update);
router.post('/:id/photo', upload.single('photo'), TeacherController.uploadPhoto);
router.delete('/:id', TeacherController.remove);

export default router;
