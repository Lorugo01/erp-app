import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

// Estender a interface Request para incluir o schoolId
declare global {
  namespace Express {
    interface Request {
      user?: {
        id: string;
        email: string;
        role: string;
        schoolId?: string;
      };
    }
  }
}

export const authenticateToken = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

    if (!token) {
      return res.status(401).json({ error: 'Token de acesso não fornecido' });
    }

    // Verificar o token JWT
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key') as any;
    
    // Buscar o usuário no banco para obter informações atualizadas
    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      select: {
        id: true,
        email: true,
        role: true,
        schoolId: true,
      },
    });

    if (!user) {
      return res.status(401).json({ error: 'Usuário não encontrado' });
    }

    // Adicionar informações do usuário à requisição
    req.user = user;
    next();
  } catch (error) {
    if (error instanceof jwt.JsonWebTokenError) {
      return res.status(403).json({ error: 'Token inválido' });
    }
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
};

// Middleware para verificar se o usuário tem acesso a uma escola específica
export const checkSchoolAccess = (req: Request, res: Response, next: NextFunction) => {
  const userSchoolId = req.user?.schoolId;
  const requestedSchoolId = req.params.schoolId || req.body.schoolId;

  // DEVELOPER pode acessar qualquer escola (mesmo sem ter escola)
  if (req.user?.role === 'DEVELOPER') {
    return next();
  }

  // Outros usuários precisam ter escola
  if (!userSchoolId) {
    return res.status(401).json({ error: 'Usuário não tem escola associada' });
  }

  // Outros usuários só podem acessar sua própria escola
  if (requestedSchoolId && requestedSchoolId !== userSchoolId) {
    return res.status(403).json({ error: 'Acesso negado: escola diferente da sua' });
  }

  next();
};

// Middleware para verificar se o usuário é DEVELOPER
export const requireDeveloper = (req: Request, res: Response, next: NextFunction) => {
  if (req.user?.role !== 'DEVELOPER') {
    return res.status(403).json({ error: 'Acesso negado: requer permissão de desenvolvedor' });
  }
  next();
};

// Middleware para verificar se o usuário é ADMIN ou DEVELOPER
export const requireAdminOrDeveloper = (req: Request, res: Response, next: NextFunction) => {
  if (!['ADMIN', 'DEVELOPER'].includes(req.user?.role || '')) {
    return res.status(403).json({ error: 'Acesso negado: requer permissão de administrador ou desenvolvedor' });
  }
  next();
};
