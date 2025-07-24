import { Router } from 'express';
import * as AttendanceController from '../controllers/attendance.controller';

const router = Router();

router.get('/', AttendanceController.getAll);
router.get('/:id', AttendanceController.getById);
router.post('/', AttendanceController.create);
router.post('/bulk', AttendanceController.createBulk);
router.put('/:id', AttendanceController.update);
router.delete('/:id', AttendanceController.remove);

export default router;
