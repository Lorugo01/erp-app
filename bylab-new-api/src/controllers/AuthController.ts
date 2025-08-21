import { Request, Response } from 'express';
import { AuthService } from '../services/AuthService';

export class AuthController {
  private authService: AuthService;

  constructor() {
    this.authService = new AuthService();
  }

  async register(req: Request, res: Response) {
    try {
      const { email, password, role, name, schoolId } = req.body;
      const user = await this.authService.createUser({ email, password, role, name, schoolId });
      return res.status(201).json(user);
    } catch (error) {
      return res.status(400).json({ error: error.message });
    }
  }

  async registerAdmin(req: Request, res: Response) {
    try {
      const { email, password, schoolId } = req.body;
      const admin = await this.authService.createAdmin({ email, password, schoolId });
      return res.status(201).json(admin);
    } catch (error) {
      return res.status(400).json({ error: error.message });
    }
  }

  async login(req: Request, res: Response) {
    try {
      const { email, password } = req.body;
      const user = await this.authService.login({ email, password });
      return res.status(200).json(user);
    } catch (error) {
      return res.status(401).json({ error: error.message });
    }
  }
} 