import { Router } from 'express';
import * as LessonController from '../controllers/lesson.controller';
import { authenticateToken } from '../middlewares/auth.middleware';
import { requireStaff } from '../middlewares/assignmentAccess.middleware';
import {
  requireBodyClass,
  requireBodySubjectOwner,
  requireLessonDuplication,
  requireLessonParam,
  requireLessonSubjectOwner,
  requireSourceLessonSubjectOwner,
} from '../middlewares/academicAccess.middleware';

const router = Router();

router.use(authenticateToken, requireStaff);

router.post('/', requireBodyClass, requireBodySubjectOwner, LessonController.create);
router.post('/get-or-create', requireBodyClass, requireBodySubjectOwner, LessonController.getOrCreate);
router.post(
  '/duplicate',
  requireLessonDuplication,
  requireSourceLessonSubjectOwner,
  requireBodySubjectOwner,
  LessonController.duplicate,
);
router.get('/:id', requireLessonParam('id'), LessonController.getById);
router.put('/:id', requireLessonParam('id'), requireLessonSubjectOwner, LessonController.update);
router.delete('/:id', requireLessonParam('id'), requireLessonSubjectOwner, LessonController.remove);

export default router;