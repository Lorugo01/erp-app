import { PrismaClient, Role, User } from '@prisma/client';
import { hash, compare } from 'bcrypt';
import jwt from 'jsonwebtoken';

const prisma = new PrismaClient();

interface CreateUserDTO {
  email: string;
  password: string;
  role: Role;
  name: string;
  schoolId?: string;
}

interface CreateAdminDTO {
  email: string;
  password: string;
  schoolId?: string;
}

interface LoginDTO {
  email: string;
  password: string;
}

export class AuthService {
  async createUser(data: CreateUserDTO) {
    const hashedPassword = await hash(data.password, 10);

    // DEVELOPER não precisa de escola, outros usuários sim
    let schoolId: string | undefined;
    if (data.role === Role.DEVELOPER) {
      schoolId = undefined;
    } else {
      schoolId = data.schoolId || 'default-school-id';
    }

    const user = await prisma.user.create({
      data: {
        email: data.email,
        password: hashedPassword,
        role: data.role,
        schoolId: schoolId,
      },
      include: {
        student: true,
        teacher: true
      }
    });

    // Se for STUDENT ou TEACHER, criar o respectivo registro (só se tiver schoolId)
    if (data.role === Role.STUDENT && schoolId) {
      await prisma.student.create({
        data: {
          name: data.name,
          email: data.email,
          userId: user.id,
          schoolId: schoolId,
        },
      });
    } else if (data.role === Role.TEACHER && schoolId) {
      await prisma.teacher.create({
        data: {
          name: data.name,
          email: data.email,
          userId: user.id,
          schoolId: schoolId,
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
    
    // Gerar token JWT para o novo usuário
    const token = jwt.sign(
      { 
        userId: userWithoutPassword.id, 
        email: userWithoutPassword.email, 
        role: userWithoutPassword.role,
        schoolId: userWithoutPassword.schoolId 
      },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '24h' }
    );

    return {
      ...userWithoutPassword,
      token,
    };
  }

  async createAdmin(data: CreateAdminDTO) {
    const hashedPassword = await hash(data.password, 10);

    // ADMIN precisa de escola
    const schoolId = data.schoolId || 'default-school-id';

    const user = await prisma.user.create({
      data: {
        email: data.email,
        password: hashedPassword,
        role: Role.ADMIN,
        schoolId: schoolId,
      },
    });

    const { password, ...userWithoutPassword } = user;
    
    // Gerar token JWT para o novo admin
    const token = jwt.sign(
      { 
        userId: userWithoutPassword.id, 
        email: userWithoutPassword.email, 
        role: userWithoutPassword.role,
        schoolId: userWithoutPassword.schoolId 
      },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '24h' }
    );

    return {
      ...userWithoutPassword,
      token,
    };
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

    // Gerar token JWT
    const token = jwt.sign(
      { 
        userId: user.id, 
        email: user.email, 
        role: user.role,
        schoolId: user.schoolId 
      },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '24h' }
    );

    const { password, ...userWithoutPassword } = user;
    return {
      ...userWithoutPassword,
      token,
    };
  }
} 