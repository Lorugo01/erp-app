const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcrypt');

const prisma = new PrismaClient();

async function createTestStudent() {
  try {
    // Criar usuário
    const hashedPassword = await bcrypt.hash('123456', 10);
    
    const user = await prisma.user.create({
      data: {
        email: 'luis2@aluno.com',
        password: hashedPassword,
        role: 'STUDENT',
      },
    });

    // Criar aluno
    const student = await prisma.student.create({
      data: {
        userId: user.id,
        name: 'Luis Aluno 2',
        email: 'luis2@aluno.com',
        registrationNumber: '654321',
        profilePicture: '/uploads/student-ba8b9c1e-f968-4a0d-b270-39e96aaf1bfa.png', // Usando uma foto existente
      },
    });

    console.log('Usuário aluno criado com sucesso!');
    console.log('User ID:', user.id);
    console.log('Student ID:', student.id);
    console.log('Email: luis@aluno.com');
    console.log('Senha: 123456');
    console.log('Foto: /uploads/student-ba8b9c1e-f968-4a0d-b270-39e96aaf1bfa.png');

  } catch (error) {
    console.error('Erro ao criar usuário aluno:', error);
  } finally {
    await prisma.$disconnect();
  }
}

createTestStudent(); 