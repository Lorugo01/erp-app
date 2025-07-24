import { Router } from 'express';
import * as ClassController from '../controllers/class.controller';
import * as AssignmentController from '../controllers/assignment.controller';

const router = Router();

router.get('/', ClassController.getAll);
router.get('/:id', ClassController.getById);
router.get('/year/:year', ClassController.getByYear);
router.get('/grade/:grade', ClassController.getByGrade);
router.get('/shift/:shift', ClassController.getByShift);
router.get('/search/:name', ClassController.getByName);
router.get('/:id/events', ClassController.getEvents);
router.get('/:id/students', ClassController.getClassStudents);
router.post('/:id/events', ClassController.addEvent);
router.put('/events/:eventId', ClassController.updateEvent);
router.delete('/events/:eventId', ClassController.deleteEvent);

router.post('/', ClassController.create);
router.put('/:id', ClassController.update);
router.delete('/:id', ClassController.remove);
router.post('/:id/teachers', ClassController.addTeacherToClass);

// Rotas de assignments (atividades)
router.get('/:id/assignments', AssignmentController.getAssignmentsByClass);
router.post('/:id/assignments', AssignmentController.createAssignment);

export default router;
