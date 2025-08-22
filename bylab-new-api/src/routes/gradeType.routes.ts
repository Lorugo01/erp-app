import { Router } from 'express';
import * as GradeTypeController from '../controllers/gradeType.controller';
import { authenticateToken, requireAdminOrDeveloper } from '../middlewares/auth.middleware';

const router = Router();

// Aplicar autenticação em todas as rotas
router.use(authenticateToken);

// Rotas de leitura
router.get('/', GradeTypeController.getAll);
router.get('/:id', GradeTypeController.getById);

// Rotas de escrita - requerem permissão de admin ou developer
router.post('/', requireAdminOrDeveloper, GradeTypeController.create);
router.put('/:id', requireAdminOrDeveloper, GradeTypeController.update);
router.delete('/:id', requireAdminOrDeveloper, GradeTypeController.remove);

export default router; 