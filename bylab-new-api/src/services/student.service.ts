import prisma from '../prisma/client';
import { hash } from 'bcrypt';
import { Role } from '@prisma/client';
import path from 'path';
import fs from 'fs';

export const getAllStudents = (whereClause?: any) => {
  return prisma.student.findMany({
    where: whereClause,
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
  schoolId?: string;
}) => {
  if (!data.registrationNumber) {
    throw new Error('Número de matrícula é obrigatório');
  }

  // Verifica se já existe um aluno com o mesmo número de matrícula na mesma escola
  if (data.schoolId) {
    const existingStudent = await prisma.student.findFirst({
      where: { 
        registrationNumber: data.registrationNumber,
        schoolId: data.schoolId
      }
    });

    if (existingStudent) {
      throw new Error('Já existe um aluno com este número de matrícula nesta escola');
    }
  }

  // Verifica se já existe um usuário com o mesmo email na mesma escola
  if (data.schoolId) {
    const existingUser = await prisma.user.findFirst({
      where: { 
        email: data.email,
        schoolId: data.schoolId
      }
    });

    if (existingUser) {
      throw new Error('Já existe um usuário com este email nesta escola');
    }
  } else {
    // Se não tiver escola, verifica globalmente
    const existingUser = await prisma.user.findUnique({
      where: { email: data.email }
    });

    if (existingUser) {
      throw new Error('Já existe um usuário com este email');
    }
  }

  // Cria o usuário primeiro
  const hashedPassword = await hash('123456', 10);
  
  const user = await prisma.user.create({
    data: {
      email: data.email,
      password: hashedPassword,
      role: Role.STUDENT,
      schoolId: data.schoolId,
    }
  });

  // Cria o estudante vinculado ao usuário
  const student = await prisma.student.create({
    data: {
      name: data.name,
      email: data.email,
      registrationNumber: data.registrationNumber,
      profilePicture: data.profilePicture,
      userId: user.id,
      schoolId: data.schoolId,
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
        include: { 
          class: { 
            include: { 
              subjects: {
                include: {
                  teacher: {
                    select: {
                      id: true,
                      name: true,
                      photoUrl: true
                    }
                  }
                }
              } 
            } 
          } 
        }
      },
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

export const getStudentSubjects = async (studentId: string) => {
  const student = await prisma.student.findUnique({
    where: { id: studentId },
    include: {
      enrollments: {
        where: { current: true },
        include: { 
          class: { 
            include: { 
              subjects: {
                include: {
                  teacher: {
                    select: {
                      id: true,
                      name: true,
                      photoUrl: true
                    }
                  }
                }
              } 
            } 
          } 
        }
      }
    },
  });

  if (!student) {
    throw new Error('Estudante não encontrado');
  }

  // Extrai as disciplinas das turmas atuais do aluno
  const subjects = student.enrollments
    .flatMap(enrollment => enrollment.class?.subjects || [])
    .filter(subject => subject != null)
    .map(subject => ({
      id: subject.id,
      name: subject.name,
      type: subject.type,
      teacher: subject.teacher ? {
        id: subject.teacher.id,
        name: subject.teacher.name,
        photoUrl: subject.teacher.photoUrl
      } : null,
      class: subject.class ? {
        id: subject.class.id,
        name: subject.class.name,
        grade: subject.class.grade,
        letter: subject.class.letter
      } : null
    }));

  return subjects;
};

export const uploadStudentPhoto = async (studentId: string, tempFilePath: string): Promise<string> => {
  try {
    // Verifica se o aluno existe
    const student = await prisma.student.findUnique({
      where: { id: studentId },
    });

    if (!student) {
      throw new Error('Aluno não encontrado');
    }

    // Renomeia o arquivo com o ID do aluno
    const uploadDir = path.join(__dirname, '../../uploads');
    const fileName = path.basename(tempFilePath);
    const ext = path.extname(fileName);
    const newFileName = `student-${studentId}${ext}`;
    const newFilePath = path.join(uploadDir, newFileName);

    // Remove arquivo anterior se existir
    if (fs.existsSync(newFilePath)) {
      fs.unlinkSync(newFilePath);
    }

    // Renomeia o arquivo
    fs.renameSync(tempFilePath, newFilePath);

    // Atualiza o aluno com a URL da foto
    const photoUrl = `/uploads/${newFileName}`;
    await prisma.student.update({
      where: { id: studentId },
      data: { profilePicture: photoUrl },
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
