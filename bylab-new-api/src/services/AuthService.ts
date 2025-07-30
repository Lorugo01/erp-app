import { PrismaClient, Role, User } from '@prisma/client';
import { hash, compare } from 'bcrypt';

const prisma = new PrismaClient();

interface CreateUserDTO {
  email: string;
  password: string;
  role: Role;
  name: string;
}

interface CreateAdminDTO {
  email: string;
  password: string;
}

interface LoginDTO {
  email: string;
  password: string;
}

export class AuthService {
  async createUser(data: CreateUserDTO) {
    const hashedPassword = await hash(data.password, 10);

    const user = await prisma.user.create({
      data: {
        email: data.email,
        password: hashedPassword,
        role: data.role,
      },
      include: {
        student: true,
        teacher: true
      }
    });

    // Se for STUDENT ou TEACHER, criar o respectivo registro
    if (data.role === Role.STUDENT) {
      await prisma.student.create({
        data: {
          name: data.name,
          email: data.email,
          userId: user.id,
        },
      });
    } else if (data.role === Role.TEACHER) {
      await prisma.teacher.create({
        data: {
          name: data.name,
          email: data.email,
          userId: user.id,
        },
      });
    }

    // Buscar o usuário novamente para incluir as relações criadas
    const updatedUser = await prisma.user.findUnique({
      where: { id: user.id },
      include: {
        student: {
          select: {
            id: true,
            name: true,
            registrationNumber: true,
            profilePicture: true,
          }
        },
        teacher: {
          select: {
            id: true,
            name: true,
            photoUrl: true,
          }
        }
      }
    });

    const { password, ...userWithoutPassword } = updatedUser;
    return userWithoutPassword;
  }

  async createAdmin(data: CreateAdminDTO) {
    const hashedPassword = await hash(data.password, 10);

    const user = await prisma.user.create({
      data: {
        email: data.email,
        password: hashedPassword,
        role: Role.ADMIN,
      },
    });

    const { password, ...userWithoutPassword } = user;
    return userWithoutPassword;
  }

  async login(data: LoginDTO) {
    const user = await prisma.user.findUnique({
      where: { email: data.email },
      include: {
        student: {
          select: {
            id: true,
            name: true,
            registrationNumber: true,
            profilePicture: true,
          },
        },
        teacher: {
          select: {
            id: true,
            name: true,
            photoUrl: true,
          },
        },
      },
    });

    if (!user) {
      throw new Error('Usuário não encontrado');
    }

    const validPassword = await compare(data.password, user.password);
    if (!validPassword) {
      throw new Error('Senha inválida');
    }

    const { password, ...userWithoutPassword } = user;
    return userWithoutPassword;
  }
} 