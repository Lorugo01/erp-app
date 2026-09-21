import { Router } from 'express';
import { AuthController } from '../controllers/AuthController';
import { authenticateToken } from '../middlewares/auth.middleware';

const authRoutes = Router();
const authController = new AuthController();

authRoutes.post('/register', (req, res) => authController.register(req, res));
authRoutes.post('/register/admin', (req, res) => authController.registerAdmin(req, res));
authRoutes.post('/login', (req, res) => authController.login(req, res));
authRoutes.post('/refresh', authenticateToken, (req, res) => authController.refresh(req, res));

export { authRoutes }; 