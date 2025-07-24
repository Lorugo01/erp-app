import { Router } from 'express';
import * as GradeController from '../controllers/grade.controller';

const router = Router();

// Rota do boletim consolidado (deve vir antes de /:id para não conflitar)
router.get('/boletim/:studentId', GradeController.getBoletim);

router.get('/', GradeController.getAll);
router.get('/:id', GradeController.getById);
router.post('/', GradeController.create);
router.put('/:id', GradeController.update);
router.delete('/:id', GradeController.remove);
router.get('/student/:studentId', GradeController.getByStudent);
router.get('/subject/:subjectId', GradeController.getBySubject);

export default router; 