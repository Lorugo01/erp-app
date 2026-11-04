import { Router } from 'express';
import * as AttendanceController from '../controllers/attendance.controller';
import { authenticateToken } from '../middlewares/auth.middleware';
import { requireStaff } from '../middlewares/assignmentAccess.middleware';
import {
  requireAttendanceAccess,
  requireAttendanceSubjectOwner,
  requireBodyLesson,
  requireBodyLessonSubjectOwner,
  requireLessonParam,
  requireStudentParam,
} from '../middlewares/academicAccess.middleware';

const router = Router();

router.use(authenticateToken);

router.get('/', requireStaff, AttendanceController.getAll);
router.get('/student/:studentId', requireStudentParam, AttendanceController.getByStudent); // Nova rota
router.get('/lesson/:lessonId', requireStaff, requireLessonParam('lessonId'), AttendanceController.getByLesson);
router.get('/:id', requireAttendanceAccess, AttendanceController.getById);
router.post('/', requireStaff, requireBodyLesson, requireBodyLessonSubjectOwner, AttendanceController.create);
router.post('/bulk', requireStaff, requireBodyLesson, requireBodyLessonSubjectOwner, AttendanceController.createBulk);
router.put('/:id', requireStaff, requireAttendanceAccess, requireAttendanceSubjectOwner, AttendanceController.update);
router.delete('/:id', requireStaff, requireAttendanceAccess, requireAttendanceSubjectOwner, AttendanceController.remove);

export default router;
