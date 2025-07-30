import { Router } from 'express';
import * as StudentController from '../controllers/student.controller';
import { upload } from '../middlewares/upload.middleware';

const router = Router();

router.get('/', StudentController.getAll);
router.get('/user/:userId', StudentController.getByUserId);
router.get('/:id', StudentController.getById);
router.get('/search/:name', StudentController.getByName);
router.get('/registration/:registrationNumber', StudentController.getByRegistrationNumber);
router.get('/:id/current-class', StudentController.getCurrentClass);
router.get('/:studentId/subjects', StudentController.getStudentSubjects);

router.post('/', StudentController.create);
router.put('/:id', StudentController.update);
router.post('/:id/photo', upload.single('photo'), StudentController.uploadPhoto);
router.delete('/:id', StudentController.remove);

export default router;