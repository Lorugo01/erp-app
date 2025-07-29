import { Router } from 'express';
import * as UserController from '../controllers/user.controller';
import { upload } from '../middlewares/upload.middleware';

const router = Router();

function asyncHandler(fn: any) {
  return (req: any, res: any, next: any) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
}

router.get('/', asyncHandler(UserController.getAllUsers));
router.get('/:id', asyncHandler(UserController.getUserById));
router.post('/', asyncHandler(UserController.create));
router.put('/:id', asyncHandler(UserController.update));
router.post('/:id/photo', upload.single('photo'), asyncHandler(UserController.uploadPhoto));
router.delete('/:id', asyncHandler(UserController.deleteUser));

export default router; 