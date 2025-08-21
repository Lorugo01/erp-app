import { Router } from 'express';
import { SchoolController } from '../controllers/school.controller';

const router = Router();

// Rotas para escolas
router.post('/', SchoolController.create);
router.get('/', SchoolController.list);
router.get('/:id', SchoolController.findById);
router.put('/:id', SchoolController.update);
router.delete('/:id', SchoolController.delete);
router.get('/:id/stats', SchoolController.getStats);

export default router;
