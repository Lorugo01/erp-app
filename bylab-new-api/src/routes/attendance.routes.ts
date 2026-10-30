import { Router } from 'express';
import * as AttendanceController from '../controllers/attendance.controller';
import { authenticateToken } from '../middlewares/auth.middleware';
import { requireStaff } from '../middlewares/assignmentAccess.middleware';
import {
  requireAttendanceAccess,
  requireBodyLesson,
  requireLessonParam,
  requireStudentParam,
} from '../middlewares/academicAccess.middleware';

const router = Router();

router.use(authenticateToken);

router.get('/', requireStaff, AttendanceController.getAll);
router.get('/student/:studentId', requireStudentParam, AttendanceController.getByStudent); // Nova rota
router.get('/lesson/:lessonId', requireStaff, requireLessonParam('lessonId'), AttendanceController.getByLesson);
router.get('/:id', requireAttendanceAccess, AttendanceController.getById);
router.post('/', requireStaff, requireBodyLesson, AttendanceController.create);
router.post('/bulk', requireStaff, requireBodyLesson, AttendanceController.createBulk);
router.put('/:id', requireStaff, requireAttendanceAccess, AttendanceController.update);
router.delete('/:id', requireStaff, requireAttendanceAccess, AttendanceController.remove);

export default router;
