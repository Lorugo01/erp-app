import { Router } from 'express';
import * as LessonController from '../controllers/lesson.controller';

const router = Router();

router.get('/', LessonController.getAll);
router.get('/:id', LessonController.getById);
router.post('/', LessonController.create);
router.put('/:id', LessonController.update);
router.delete('/:id', LessonController.remove);

export default router;
