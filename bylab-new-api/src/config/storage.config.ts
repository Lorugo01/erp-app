import path from 'path';

export const STORAGE_CATEGORIES = [
  'assignments',
  'submissions',
  'profiles',
  'chat',
  'general',
] as const;

export type StorageCategory = (typeof STORAGE_CATEGORIES)[number];

export const storageConfig = {
  /** Diretório raiz dos arquivos (sobrescrevível via UPLOAD_DIR) */
  rootDir: process.env.UPLOAD_DIR || path.join(__dirname, '../../uploads'),
  /** Prefixo público servido pelo Express */
  publicPathPrefix: '/uploads',
  maxFileSizeBytes: Number(process.env.UPLOAD_MAX_SIZE_MB || 10) * 1024 * 1024,
  allowedExtensions: [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'pdf',
    'doc',
    'docx',
    'txt',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
    'zip',
  ],
  allowedMimeTypes: [
    'image/jpeg',
    'image/pjpeg',
    'image/png',
    'image/gif',
    'image/webp',
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'text/plain',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'application/zip',
    'application/x-zip-compressed',
    'application/octet-stream',
  ],
};
