import { Router } from 'express';
import * as UserController from '../controllers/user.controller';

const router = Router();

function asyncHandler(fn: any) {
  return (req: any, res: any, next: any) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
}

router.get('/', asyncHandler(UserController.getAllUsers));
router.get('/:id', asyncHandler(UserController.getUserById));
router.delete('/:id', asyncHandler(UserController.deleteUser));

export default router; 