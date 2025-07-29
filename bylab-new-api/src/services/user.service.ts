import { PrismaClient } from '@prisma/client';
import path from 'path';
import fs from 'fs';

const prisma = new PrismaClient();

export const uploadUserPhoto = async (userId: string, tempFilePath: string): Promise<string> => {
  try {
    // Verifica se o usuário existe
    const user = await prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new Error('Usuário não encontrado');
    }

    // Renomeia o arquivo com o ID do usuário
    const uploadDir = path.join(__dirname, '../../uploads');
    const fileName = path.basename(tempFilePath);
    const ext = path.extname(fileName);
    const newFileName = `user-${userId}${ext}`;
    const newFilePath = path.join(uploadDir, newFileName);

    // Remove arquivo anterior se existir
    if (fs.existsSync(newFilePath)) {
      fs.unlinkSync(newFilePath);
    }

    // Renomeia o arquivo
    fs.renameSync(tempFilePath, newFilePath);

    // Atualiza o usuário com a URL da foto
    const photoUrl = `/uploads/${newFileName}`;
    await prisma.user.update({
      where: { id: userId },
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