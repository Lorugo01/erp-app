import { Router } from 'express';
import * as EnrollmentController from '../controllers/enrollment.controller';

const router = Router();

router.get('/', EnrollmentController.getAll);
router.get('/:id', EnrollmentController.getById);
router.get('/student/:studentId', EnrollmentController.getByStudent);
router.post('/', EnrollmentController.create);
router.put('/:id', EnrollmentController.update);
router.delete('/:id', EnrollmentController.remove);

export default router;
