import prisma from '../prisma/client';
import { hash } from 'bcrypt';
import { Role } from '@prisma/client';

export const getAllStudents = () => {
  return prisma.student.findMany({
    include: {
      enrollments: {
        where: { current: true },
        include: { class: true }
      },
      attendances: true,
      user: {
        select: {
          id: true,
          email: true,
          role: true,
          createdAt: true
        }
      }
    },
    orderBy: { createdAt: 'desc' }
  });
};

export const getStudentById = async (id: string) => {
  if (!id || typeof id !== 'string' || id.length < 10) {
    throw new Error('ID inválido');
  }

  const student = await prisma.student.findUnique({
    where: { id },
    include: {
      enrollments: {
        orderBy: { year: 'desc' },
        include: { class: { include: { subjects: true } } }
      },
      attendances: true,
      user: {
        select: {
          id: true,
          email: true,
          role: true,
          createdAt: true
        }
      }
    },
  });

  if (!student) {
    throw new Error('Estudante não encontrado');
  }

  return student;
};

export const getStudentsByName = async (name: string) => {
  return prisma.student.findMany({
    where: {
      name: {
        contains: name,
        mode: 'insensitive'
      }
    },
    include: {
      enrollments: {
        where: { current: true },
        include: { class: true }
      }
    }
  });
};

export const getStudentByRegistrationNumber = async (registrationNumber: string) => {
  const student = await prisma.student.findUnique({
    where: { registrationNumber },
    include: {
      enrollments: {
        where: { current: true },
        include: { class: true }
      }
    }
  });

  if (!student) {
    throw new Error('Estudante não encontrado');
  }

  return student;
};

export const createStudent = async (data: {
  name: string;
  email: string;
  registrationNumber: string;
  profilePicture?: string;
}) => {
  if (!data.registrationNumber) {
    throw new Error('Número de matrícula é obrigatório');
  }

  // Verifica se já existe um aluno com o mesmo número de matrícula
  const existingStudent = await prisma.student.findUnique({
    where: { registrationNumber: data.registrationNumber }
  });

  if (existingStudent) {
    throw new Error('Já existe um aluno com este número de matrícula');
  }

  // Verifica se já existe um usuário com o mesmo email
  const existingUser = await prisma.user.findUnique({
    where: { email: data.email }
  });

  if (existingUser) {
    throw new Error('Já existe um usuário com este email');
  }

  // Cria o usuário primeiro
  const hashedPassword = await hash('123456', 10);
  
  const user = await prisma.user.create({
    data: {
      email: data.email,
      password: hashedPassword,
      role: Role.STUDENT,
    }
  });

  // Cria o estudante vinculado ao usuário
  const student = await prisma.student.create({
    data: {
      name: data.name,
      email: data.email,
      registrationNumber: data.registrationNumber,
      profilePicture: data.profilePicture,
      userId: user.id
    },
    include: {
      user: {
        select: {
          id: true,
          email: true,
          role: true,
          createdAt: true
        }
      }
    }
  });

  return student;
};

export const updateStudent = async (id: string, data: {
  name?: string;
  email?: string;
  registrationNumber?: string;
  profilePicture?: string;
  phone?: string;
  address?: string;
  birthDate?: string;
}) => {
  // Se estiver atualizando o número de matrícula, verifica se já existe
  if (data.registrationNumber) {
    const existingStudent = await prisma.student.findFirst({
      where: {
        registrationNumber: data.registrationNumber,
        NOT: { id }
      }
    });

    if (existingStudent) {
      throw new Error('Já existe um aluno com este número de matrícula');
    }
  }

  // Se estiver atualizando o email, verifica se já existe
  if (data.email) {
    const existingStudent = await prisma.student.findFirst({
      where: {
        email: data.email,
        NOT: { id }
      }
    });

    if (existingStudent) {
      throw new Error('Já existe um aluno com este email');
    }
  }

  return prisma.student.update({
    where: { id },
    data: {
      ...data,
      birthDate: data.birthDate ? new Date(data.birthDate) : undefined,
    },
    include: {
      user: {
        select: {
          id: true,
          email: true,
          role: true,
          createdAt: true
        }
      }
    }
  });
};

export const deleteStudent = async (id: string) => {
  // Primeiro, busca o estudante para obter o userId
  const student = await prisma.student.findUnique({
    where: { id },
    select: { userId: true }
  });

  if (!student) {
    throw new Error('Estudante não encontrado');
  }

  // Se o estudante tem um usuário vinculado, deleta o usuário primeiro
  if (student.userId) {
    await prisma.user.delete({
      where: { id: student.userId }
    });
  }

  // Deleta o estudante
  return prisma.student.delete({
    where: { id }
  });
};

export const getStudentByUserId = async (userId: string) => {
  if (!userId || typeof userId !== 'string' || userId.length < 10) {
    throw new Error('ID de usuário inválido');
  }

  const student = await prisma.student.findUnique({
    where: { userId },
    include: {
      enrollments: {
        orderBy: { year: 'desc' },
        include: { class: true }
      },
      attendances: true,
    },
  });

  if (!student) {
    throw new Error('Estudante não encontrado');
  }

  return student;
};
