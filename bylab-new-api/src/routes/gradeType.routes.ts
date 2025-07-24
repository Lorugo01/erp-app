import { Router } from 'express';
import * as GradeTypeController from '../controllers/gradeType.controller';

const router = Router();

router.get('/', GradeTypeController.getAll);
router.get('/:id', GradeTypeController.getById);
router.post('/', GradeTypeController.create);
router.put('/:id', GradeTypeController.update);
router.delete('/:id', GradeTypeController.remove);

export default router; 