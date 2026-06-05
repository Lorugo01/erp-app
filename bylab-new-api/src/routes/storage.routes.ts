import { Router } from 'express';
import * as StorageController from '../controllers/storage.controller';
import { upload } from '../middlewares/upload.middleware';
import { authenticateToken } from '../middlewares/auth.middleware';

const router = Router();

router.use(authenticateToken);

router.get('/', StorageController.listFiles);
router.post('/upload', upload.single('file'), StorageController.uploadFile);
router.get('/:id', StorageController.getFileById);
router.delete('/:id', StorageController.deleteFile);

export default router;
