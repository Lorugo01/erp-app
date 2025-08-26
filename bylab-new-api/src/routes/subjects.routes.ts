import { Router } from 'express';
import { SubjectsController } from '../controllers/subjects.controller';

const subjectsRouter = Router();
const subjectsController = new SubjectsController();

// Rotas para tipos de disciplinas (matérias)
subjectsRouter.get('/types', subjectsController.getAllSubjectTypes);
subjectsRouter.get('/types/:id', subjectsController.getSubjectTypeById);
subjectsRouter.post('/types', subjectsController.createSubjectType);
subjectsRouter.put('/types/:id', subjectsController.updateSubjectType);
subjectsRouter.delete('/types/:id', subjectsController.deleteSubjectType);

// Rotas para disciplinas específicas de turmas
subjectsRouter.get('/class/:classId', subjectsController.getSubjectsByClass);
subjectsRouter.post('/class/:classId', subjectsController.addSubjectToClass);
subjectsRouter.delete('/class/:classId/:subjectId', subjectsController.removeSubjectFromClass);

// Rota para buscar disciplinas por professor
subjectsRouter.get('/teacher/:teacherId', subjectsController.getSubjectsByTeacher);

export default subjectsRouter;
