import { Request, Response, NextFunction } from 'express';
import { PrismaClient } from '@prisma/client';
import * as UserService from '../services/user.service';

const prisma = new PrismaClient();

export const getAllUsers = async (req: Request, res: Response) => {
  try {
    // DEVELOPER pode ver todos os usuários de todas as escolas
    // Outros usuários só veem usuários da sua escola
    const whereClause = req.user?.role === 'DEVELOPER' 
      ? {} 
      : { schoolId: req.user?.schoolId };

    const users = await prisma.user.findMany({
      where: whereClause,
      select: {
        id: true,
        email: true,
        role: true,
        photoUrl: true,
        createdAt: true,
        schoolId: true,
        student: {
          select: {
            id: true,
            name: true,
            registrationNumber: true,
            profilePicture: true,
            createdAt: true,
          }
        },
        teacher: {
          select: {
            id: true,
            name: true,
            createdAt: true,
          }
        }
      },
      orderBy: {
        createdAt: 'desc'
      }
    });

    res.json(users);
  } catch (error) {
    res.status(500).json({ error: (error as Error).message });
  }
};

export const getById = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    // Verificar se o usuário solicitado pertence à mesma escola
    // DEVELOPER pode acessar qualquer usuário
    const whereClause = req.user?.role === 'DEVELOPER' 
      ? { id } 
      : { id, schoolId: req.user?.schoolId };
    
    const user = await prisma.user.findUnique({
      where: whereClause,
      select: {
        id: true,
        email: true,
        role: true,
        photoUrl: true,
        createdAt: true,
        schoolId: true,
        student: {
          select: {
            id: true,
            name: true,
            registrationNumber: true,
            profilePicture: true,
            createdAt: true,
          }
        },
        teacher: {
          select: {
            id: true,
            name: true,
            createdAt: true,
          }
        }
      }
    });

    if (!user) {
      return res.status(404).json({ error: 'Usuário não encontrado' });
    }

    res.json(user);
  } catch (error) {
    res.status(500).json({ error: (error as Error).message });
  }
};

export const getUserById = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    // Verificar se o usuário solicitado pertence à mesma escola
    // DEVELOPER pode acessar qualquer usuário
    const whereClause = req.user?.role === 'DEVELOPER' 
      ? { id } 
      : { id, schoolId: req.user?.schoolId };
    
    const user = await prisma.user.findUnique({
      where: whereClause,
      select: {
        id: true,
        email: true,
        role: true,
        photoUrl: true,
        createdAt: true,
        schoolId: true,
        student: {
          select: {
            id: true,
            name: true,
            registrationNumber: true,
            profilePicture: true,
            createdAt: true,
          }
        },
        teacher: {
          select: {
            id: true,
            name: true,
            createdAt: true,
          }
        }
      }
    });

    if (!user) {
      return res.status(404).json({ error: 'Usuário não encontrado' });
    }

    res.json(user);
  } catch (error) {
    res.status(500).json({ error: (error as Error).message });
  }
};

export const create = async (req: Request, res: Response) => {
  try {
    const { email, password, role } = req.body;

    // Verificar se o usuário tem permissão para criar usuários
    if (!['ADMIN', 'DEVELOPER'].includes(req.user?.role || '')) {
      return res.status(403).json({ error: 'Acesso negado: requer permissão de administrador ou desenvolvedor' });
    }

    // DEVELOPER pode criar usuários em qualquer escola ou sem escola
    // ADMIN só pode criar usuários na sua escola
    let schoolId: string | undefined;
    if (req.user?.role === 'DEVELOPER') {
      schoolId = req.body.schoolId;
    } else {
      schoolId = req.user?.schoolId;
    }
    
    const user = await prisma.user.create({
      data: {
        email,
        password,
        role,
        schoolId,
      },
    });

    res.status(201).json(user);
  } catch (error) {
    res.status(500).json({ error: (error as Error).message });
  }
};

export const update = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { email, password, role } = req.body;

    // Verificar se o usuário tem permissão para atualizar usuários
    if (!['ADMIN', 'DEVELOPER'].includes(req.user?.role || '')) {
      return res.status(403).json({ error: 'Acesso negado: requer permissão de administrador ou desenvolvedor' });
    }

    // Verificar se o usuário a ser atualizado pertence à mesma escola
    // DEVELOPER pode atualizar qualquer usuário
    const whereClause = req.user?.role === 'DEVELOPER' 
      ? { id } 
      : { id, schoolId: req.user?.schoolId };
    
    const user = await prisma.user.update({
      where: whereClause,
      data: {
        email,
        password,
        role,
      },
    });

    res.json(user);
  } catch (error) {
    res.status(500).json({ error: (error as Error).message });
  }
};

export const remove = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    // Verificar se o usuário tem permissão para excluir usuários
    if (!['ADMIN', 'DEVELOPER'].includes(req.user?.role || '')) {
      return res.status(403).json({ error: 'Acesso negado: requer permissão de administrador ou desenvolvedor' });
    }

    // Verificar se o usuário a ser excluído pertence à mesma escola
    // DEVELOPER pode excluir qualquer usuário
    const whereClause = req.user?.role === 'DEVELOPER' 
      ? { id } 
      : { id, schoolId: req.user?.schoolId };
    
    // Verificar se o usuário existe
    const user = await prisma.user.findUnique({
      where: whereClause,
      include: {
        student: true,
        teacher: true
      }
    });

    if (!user) {
      return res.status(404).json({ error: 'Usuário não encontrado' });
    }

    // Não permitir exclusão de administradores
    if (user.role === 'ADMIN') {
      return res.status(403).json({ error: 'Não é permitido excluir administradores' });
    }

    // Excluir o usuário (isso também excluirá student/teacher devido ao cascade)
    await prisma.user.delete({
      where: { id }
    });

    res.status(204).send();
  } catch (error) {
    res.status(500).json({ error: (error as Error).message });
  }
};

export const deleteUser = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    // Verificar se o usuário tem permissão para excluir usuários
    if (!['ADMIN', 'DEVELOPER'].includes(req.user?.role || '')) {
      return res.status(403).json({ error: 'Acesso negado: requer permissão de administrador ou desenvolvedor' });
    }

    // Verificar se o usuário a ser excluído pertence à mesma escola
    // DEVELOPER pode excluir qualquer usuário
    const whereClause = req.user?.role === 'DEVELOPER' 
      ? { id } 
      : { id, schoolId: req.user?.schoolId };
    
    // Verificar se o usuário existe
    const user = await prisma.user.findUnique({
      where: whereClause,
      include: {
        student: true,
        teacher: true
      }
    });

    if (!user) {
      return res.status(404).json({ error: 'Usuário não encontrado' });
    }

    // Não permitir exclusão de administradores
    if (user.role === 'ADMIN') {
      return res.status(403).json({ error: 'Não é permitido excluir administradores' });
    }

    // Excluir o usuário (isso também excluirá student/teacher devido ao cascade)
    await prisma.user.delete({
      where: { id }
    });

    res.status(204).send();
  } catch (error) {
    res.status(500).json({ error: (error as Error).message });
  }
}; 

export const uploadPhoto = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;

    // Verificar se o usuário tem permissão para atualizar fotos
    if (!['ADMIN', 'DEVELOPER'].includes(req.user?.role || '')) {
      return res.status(403).json({ error: 'Acesso negado: requer permissão de administrador ou desenvolvedor' });
    }

    // Verificar se o usuário a ser atualizado pertence à mesma escola
    // DEVELOPER pode atualizar qualquer usuário
    const whereClause = req.user?.role === 'DEVELOPER' 
      ? { id } 
      : { id, schoolId: req.user?.schoolId };
    
    // Verificar se o usuário existe
    const user = await prisma.user.findUnique({
      where: whereClause,
      select: { id: true }
    });

    if (!user) {
      return res.status(404).json({ error: 'Usuário não encontrado' });
    }
    
    if (!req.file) {
      return res.status(400).json({ error: 'Nenhuma foto foi enviada' });
    }

    const tempFilePath = req.file.path;
    const photoUrl = await UserService.uploadUserPhoto(id, tempFilePath);
    
    res.json({ 
      message: 'Foto do usuário atualizada com sucesso!',
      photoUrl 
    });
  } catch (error) {
    next(error);
  }
}; 