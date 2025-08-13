import { Router } from 'express';
import * as SubjectController from '../controllers/subject.controller';

const router = Router();

router.get('/', SubjectController.getAll);
router.get('/:id', SubjectController.getById);
router.post('/', SubjectController.create);
router.put('/:id', SubjectController.update);
router.delete('/:id', SubjectController.remove);
router.get('/class/:classId', SubjectController.getByClassId);
router.get('/class/:classId/teacher/:teacherId', SubjectController.getByClassIdAndTeacher);

export default router;
