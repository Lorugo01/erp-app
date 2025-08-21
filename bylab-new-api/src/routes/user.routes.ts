import { Router } from 'express';
import * as UserController from '../controllers/user.controller';
import { upload } from '../middlewares/upload.middleware';
import { authenticateToken, requireAdminOrDeveloper } from '../middlewares/auth.middleware';

const router = Router();

function asyncHandler(fn: any) {
  return (req: any, res: any, next: any) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
}

router.get('/', authenticateToken, asyncHandler(UserController.getAllUsers));
router.get('/:id', authenticateToken, asyncHandler(UserController.getUserById));
router.post('/', authenticateToken, requireAdminOrDeveloper, asyncHandler(UserController.create));
router.put('/:id', authenticateToken, requireAdminOrDeveloper, asyncHandler(UserController.update));
router.post('/:id/photo', authenticateToken, requireAdminOrDeveloper, upload.single('photo'), asyncHandler(UserController.uploadPhoto));
router.delete('/:id', authenticateToken, requireAdminOrDeveloper, asyncHandler(UserController.deleteUser));

export default router; 