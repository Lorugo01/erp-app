import { Router } from 'express';
import * as ClassController from '../controllers/class.controller';
import * as AssignmentController from '../controllers/assignment.controller';
import { authenticateToken, requireAdminOrDeveloper } from '../middlewares/auth.middleware';

const router = Router();

router.get('/', authenticateToken, ClassController.getAll);
router.get('/:id', authenticateToken, ClassController.getById);
router.get('/year/:year', authenticateToken, ClassController.getByYear);
router.get('/grade/:grade', authenticateToken, ClassController.getByGrade);
router.get('/shift/:shift', authenticateToken, ClassController.getByShift);
router.get('/search/:name', authenticateToken, ClassController.getByName);
router.get('/:id/events', authenticateToken, ClassController.getEvents);
router.get('/:id/students', authenticateToken, ClassController.getClassStudents);
router.post('/:id/events', authenticateToken, requireAdminOrDeveloper, ClassController.addEvent);
router.put('/events/:eventId', authenticateToken, requireAdminOrDeveloper, ClassController.updateEvent);
router.delete('/events/:eventId', authenticateToken, requireAdminOrDeveloper, ClassController.deleteEvent);

router.post('/', authenticateToken, requireAdminOrDeveloper, ClassController.create);
router.put('/:id', authenticateToken, requireAdminOrDeveloper, ClassController.update);
router.delete('/:id', authenticateToken, requireAdminOrDeveloper, ClassController.remove);
router.post('/:id/teachers', authenticateToken, requireAdminOrDeveloper, ClassController.addTeacherToClass);

// Rotas de assignments (atividades)
router.get('/:id/assignments', authenticateToken, AssignmentController.getAssignmentsByClass);
router.post('/:id/assignments', authenticateToken, requireAdminOrDeveloper, AssignmentController.createAssignment);

export default router;
