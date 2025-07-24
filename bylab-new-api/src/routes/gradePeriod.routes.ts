import { Router } from 'express';
import * as GradePeriodController from '../controllers/gradePeriod.controller';

const router = Router();

router.get('/', GradePeriodController.getAll);
router.get('/:id', GradePeriodController.getById);
router.post('/', GradePeriodController.create);
router.put('/:id', GradePeriodController.update);
router.delete('/:id', GradePeriodController.remove);

export default router; 