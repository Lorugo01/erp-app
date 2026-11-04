import { Router } from 'express';
import { SchoolController } from '../controllers/school.controller';
import { authenticateToken, requireDeveloper } from '../middlewares/auth.middleware';
import { requireOwnSchool } from '../middlewares/academicAccess.middleware';

const router = Router();

router.use(authenticateToken);

// Rotas para escolas
router.post('/', requireDeveloper, SchoolController.create);
router.get('/', requireDeveloper, SchoolController.list);
router.get('/:id', requireOwnSchool, SchoolController.findById);
router.put('/:id', requireDeveloper, SchoolController.update);
router.delete('/:id', requireDeveloper, SchoolController.delete);
router.get('/:id/stats', requireOwnSchool, SchoolController.getStats);
router.get('/:id/integration', requireOwnSchool, SchoolController.getIntegration);

export default router;
