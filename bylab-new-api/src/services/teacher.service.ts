import prisma from '../prisma/client';
import { hash } from 'bcrypt';
import { Role } from '@prisma/client';
import path from 'path';
import fs from 'fs';

export const getAllTeachers = () => {
  return prisma.teacher.findMany({
    include: {
      subjects: true,
      lessons: true,
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
};

export const getTeacherById = async (id: string) => {
  if (!id || typeof id !== 'string' || id.length < 10) {
    throw new Error('ID inválido');
  }

  const teacher = await prisma.teacher.findUnique({
    where: { id },
    include: {
      subjects: true,
      lessons: true,
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

  if (!teacher) {
    throw new Error('Professor não encontrado');
  }

  return teacher;
};

export const getTeachersByName = async (name: string) => {
  return prisma.teacher.findMany({
    where: {
      name: {
        contains: name,
        mode: 'insensitive'
      }
    },
    include: {
      subjects: {
        include: {
          class: true
        }
      },
      lessons: true,
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

export const createTeacher = async (data: {
  name: string;
  email: string;
}) => {
  // Verifica se já existe um usuário com o mesmo email
  const existingUser = await prisma.user.findUnique({
    where: { email: data.email }
  });

  if (existingUser) {
    throw new Error('Já existe um usuário com este email');
  }

  // Verifica se já existe um professor com o mesmo email
  const existingTeacher = await prisma.teacher.findUnique({
    where: { email: data.email }
  });

  if (existingTeacher) {
    throw new Error('Já existe um professor com este email');
  }

  // Cria o usuário primeiro
  const hashedPassword = await hash('123456', 10);
  
  const user = await prisma.user.create({
    data: {
      email: data.email,
      password: hashedPassword,
      role: Role.TEACHER,
    }
  });

  // Cria o professor vinculado ao usuário
  const teacher = await prisma.teacher.create({
    data: {
      name: data.name,
      email: data.email,
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

  return teacher;
};

export const getTeacherClasses = async (teacherId: string, subjectId?: string) => {
  const teacher = await prisma.teacher.findUnique({
    where: { id: teacherId },
    include: {
      subjects: {
        where: subjectId ? { subjectId } : undefined,
        include: {
          class: {
            include: {
              enrollments: {
                include: { student: true }
              },
              subjects: {
                where: {
                  teacherId: teacherId
                }
              }
            }
          }
        }
      }
    }
  });

  if (!teacher) {
    return []; // Retorna lista vazia se professor não encontrado
  }

  // Extrair as turmas únicas dos subjects e incluir as disciplinas do professor
  const uniqueClasses = teacher.subjects.reduce((acc, subject) => {
    const existingClass = acc.find(c => c.id === subject.class.id);
    if (!existingClass) {
      acc.push({
        ...subject.class,
        subjects: subject.class.subjects
      });
    }
    return acc;
  }, [] as any[]);

  return uniqueClasses;
};

export const updateTeacher = async (id: string, data: {
  name?: string;
  email?: string;
}) => {
  // Se estiver atualizando o email, verifica se já existe
  if (data.email) {
    const existingTeacher = await prisma.teacher.findFirst({
      where: {
        email: data.email,
        NOT: { id }
      }
    });

    if (existingTeacher) {
      throw new Error('Já existe um professor com este email');
    }
  }

  return prisma.teacher.update({
    where: { id },
    data,
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

export const deleteTeacher = async (id: string) => {
  // Primeiro, busca o professor para obter o userId
  const teacher = await prisma.teacher.findUnique({
    where: { id },
    select: { userId: true }
  });

  if (!teacher) {
    throw new Error('Professor não encontrado');
  }

  // Se o professor tem um usuário vinculado, deleta o usuário primeiro
  if (teacher.userId) {
    await prisma.user.delete({
      where: { id: teacher.userId }
    });
  }

  // Deleta o professor
  return prisma.teacher.delete({
    where: { id },
  });
};

export const uploadTeacherPhoto = async (teacherId: string, tempFilePath: string): Promise<string> => {
  try {
    // Verifica se o professor existe
    const teacher = await prisma.teacher.findUnique({
      where: { id: teacherId },
    });

    if (!teacher) {
      throw new Error('Professor não encontrado');
    }

    // Renomeia o arquivo com o ID do professor
    const uploadDir = path.join(__dirname, '../../uploads');
    const fileName = path.basename(tempFilePath);
    const ext = path.extname(fileName);
    const newFileName = `teacher-${teacherId}${ext}`;
    const newFilePath = path.join(uploadDir, newFileName);

    // Remove arquivo anterior se existir
    if (fs.existsSync(newFilePath)) {
      fs.unlinkSync(newFilePath);
    }

    // Renomeia o arquivo
    fs.renameSync(tempFilePath, newFilePath);

    // Atualiza o professor com a URL da foto
    const photoUrl = `/uploads/${newFileName}`;
    await prisma.teacher.update({
      where: { id: teacherId },
      data: { photoUrl },
    });

    return photoUrl;
  } catch (error) {
    // Remove arquivo temporário em caso de erro
    if (fs.existsSync(tempFilePath)) {
      fs.unlinkSync(tempFilePath);
    }
    throw error;
  }
};
