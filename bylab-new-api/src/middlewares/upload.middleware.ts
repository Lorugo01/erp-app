import multer from 'multer';
import path from 'path';
import fs from 'fs';

// Garante que o diretório de uploads existe
const uploadDir = path.join(__dirname, '../../uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

// Configuração do armazenamento
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    // Gera um nome temporário para o arquivo
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const ext = path.extname(file.originalname);
    cb(null, `temp-${uniqueSuffix}${ext}`);
  }
});

// Filtro para aceitar imagens e documentos
const fileFilter = (req: Express.Request, file: Express.Multer.File, cb: multer.FileFilterCallback) => {
  const allowedMimes = [
    'image/jpeg',
    'image/pjpeg',
    'image/png',
    'image/gif',
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'text/plain',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  ];

  if (allowedMimes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Tipo de arquivo inválido. Apenas imagens e documentos são permitidos.'));
  }
};

// Função para renomear um arquivo com o ID do aluno
export const renameStudentPhoto = (tempFilePath: string, studentId: string): string => {
  if (!fs.existsSync(tempFilePath)) {
    throw new Error(`Arquivo temporário não encontrado: ${tempFilePath}`);
  }
  
  const uploadDir = path.join(__dirname, '../../uploads');
  const fileName = path.basename(tempFilePath);
  const ext = path.extname(fileName);
  const newFileName = `${studentId}${ext}`;
  const newFilePath = path.join(uploadDir, newFileName);
  
  // Renomeia o arquivo
  fs.renameSync(tempFilePath, newFilePath);
  
  return newFileName;
};

// Configuração do multer
export const upload = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: 10 * 1024 * 1024 // 10MB
  }
}); 

// Linha teste da PR