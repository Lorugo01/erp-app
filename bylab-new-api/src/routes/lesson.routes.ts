import { Router } from 'express';
import * as LessonController from '../controllers/lesson.controller';

const router = Router();

router.post('/', LessonController.create);
router.post('/get-or-create', LessonController.getOrCreate);
router.post('/duplicate', LessonController.duplicate);
router.get('/:id', LessonController.getById);
router.put('/:id', LessonController.update);
router.delete('/:id', LessonController.remove);

export default router;