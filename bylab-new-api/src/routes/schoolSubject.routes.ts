import { Router } from 'express';
import * as SchoolSubjectController from '../controllers/schoolSubject.controller';
import {
  authenticateToken,
  requireAdminOrDeveloper,
} from '../middlewares/auth.middleware';

const router = Router();

router.get('/', authenticateToken, SchoolSubjectController.getAll);
router.post(
  '/',
  authenticateToken,
  requireAdminOrDeveloper,
  SchoolSubjectController.create,
);

// Rotas específicas antes de /:id
router.delete(
  '/offerings/:offeringId',
  authenticateToken,
  requireAdminOrDeveloper,
  SchoolSubjectController.removeOffering,
);
router.post(
  '/:id/offerings',
  authenticateToken,
  requireAdminOrDeveloper,
  SchoolSubjectController.createOffering,
);

router.get('/:id', authenticateToken, SchoolSubjectController.getById);
router.put(
  '/:id',
  authenticateToken,
  requireAdminOrDeveloper,
  SchoolSubjectController.update,
);
router.delete(
  '/:id',
  authenticateToken,
  requireAdminOrDeveloper,
  SchoolSubjectController.remove,
);

export default router;
