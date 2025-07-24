import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export const getAllUsers = async (_: Request, res: Response) => {
  const users = await prisma.user.findMany({
    include: {
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
};

export const getUserById = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    
    const user = await prisma.user.findUnique({
      where: { id },
      include: {
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
    res.status(400).json({ error: (error as Error).message });
  }
};

export const deleteUser = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    
    // Verificar se o usuário existe
    const user = await prisma.user.findUnique({
      where: { id },
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
    res.status(400).json({ error: (error as Error).message });
  }
}; 