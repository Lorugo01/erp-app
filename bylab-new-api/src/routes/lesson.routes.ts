import { Router } from 'express';
import * as LessonController from '../controllers/lesson.controller';
import { authenticateToken } from '../middlewares/auth.middleware';
import { requireStaff } from '../middlewares/assignmentAccess.middleware';
import {
  requireBodyClass,
  requireLessonDuplication,
  requireLessonParam,
} from '../middlewares/academicAccess.middleware';

const router = Router();

router.use(authenticateToken, requireStaff);

router.post('/', requireBodyClass, LessonController.create);
router.post('/get-or-create', requireBodyClass, LessonController.getOrCreate);
router.post('/duplicate', requireLessonDuplication, LessonController.duplicate);
router.get('/:id', requireLessonParam('id'), LessonController.getById);
router.put('/:id', requireLessonParam('id'), LessonController.update);
router.delete('/:id', requireLessonParam('id'), LessonController.remove);

export default router;