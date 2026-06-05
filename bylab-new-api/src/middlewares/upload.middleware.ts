import multer from 'multer';
import path from 'path';
import fs from 'fs';
import { storageConfig } from '../config/storage.config';
import { StorageService } from '../services/storage.service';

StorageService.ensureRootDir();

const tempDir = path.join(storageConfig.rootDir, '_temp');
if (!fs.existsSync(tempDir)) {
  fs.mkdirSync(tempDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => {
    cb(null, tempDir);
  },
  filename: (_req, file, cb) => {
    const uniqueSuffix = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
    const ext = StorageService.sanitizeExtension(file.originalname);
    cb(null, `temp-${uniqueSuffix}${ext}`);
  },
});

const fileFilter = (
  _req: Express.Request,
  file: Express.Multer.File,
  cb: multer.FileFilterCallback,
) => {
  if (StorageService.isAllowedFile(file.originalname, file.mimetype)) {
    cb(null, true);
    return;
  }
  cb(new Error('Tipo de arquivo inválido. Apenas imagens e documentos são permitidos.'));
};

export const upload = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: storageConfig.maxFileSizeBytes,
  },
});

/** Renomeia foto de perfil com ID do aluno (legado) */
export const renameStudentPhoto = (tempFilePath: string, studentId: string): string => {
  if (!fs.existsSync(tempFilePath)) {
    throw new Error(`Arquivo temporário não encontrado: ${tempFilePath}`);
  }

  const profilesDir = StorageService.getCategoryDir('profiles');
  const ext = path.extname(tempFilePath);
  const newFileName = `${studentId}${ext}`;
  const newFilePath = path.join(profilesDir, newFileName);

  fs.renameSync(tempFilePath, newFilePath);

  return path.posix.join(
    'profiles',
    String(new Date().getFullYear()),
    String(new Date().getMonth() + 1).padStart(2, '0'),
    newFileName,
  );
};
