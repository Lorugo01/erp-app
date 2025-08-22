import { Router } from 'express';
import * as GradePeriodController from '../controllers/gradePeriod.controller';
import { authenticateToken, requireAdminOrDeveloper } from '../middlewares/auth.middleware';

const router = Router();

// Aplicar autenticação em todas as rotas
router.use(authenticateToken);

// Rotas de leitura
router.get('/', GradePeriodController.getAll);
router.get('/:id', GradePeriodController.getById);

// Rotas de escrita - requerem permissão de admin ou developer
router.post('/', requireAdminOrDeveloper, GradePeriodController.create);
router.put('/:id', requireAdminOrDeveloper, GradePeriodController.update);
router.delete('/:id', requireAdminOrDeveloper, GradePeriodController.remove);

export default router; 