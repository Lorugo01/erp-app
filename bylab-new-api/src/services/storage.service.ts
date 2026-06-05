import fs from 'fs';
import path from 'path';
import { randomUUID } from 'crypto';
import prisma from '../prisma/client';
import {
  storageConfig,
  STORAGE_CATEGORIES,
  StorageCategory,
} from '../config/storage.config';

export interface StoredFileResult {
  id: string;
  originalName: string;
  storedName: string;
  mimeType: string;
  size: number;
  category: StorageCategory;
  relativePath: string;
  fileUrl: string;
  url: string;
  createdAt: Date;
}

export class StorageService {
  static ensureRootDir(): void {
    if (!fs.existsSync(storageConfig.rootDir)) {
      fs.mkdirSync(storageConfig.rootDir, { recursive: true });
    }
  }

  static normalizeCategory(value?: string): StorageCategory {
    const normalized = (value || 'general').toLowerCase();
    if (STORAGE_CATEGORIES.includes(normalized as StorageCategory)) {
      return normalized as StorageCategory;
    }
    return 'general';
  }

  static getCategoryDir(category: StorageCategory): string {
    const now = new Date();
    const year = String(now.getFullYear());
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const dir = path.join(storageConfig.rootDir, category, year, month);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    return dir;
  }

  static sanitizeExtension(originalName: string): string {
    const ext = path.extname(originalName).toLowerCase().replace(/[^a-z0-9.]/g, '');
    return ext || '';
  }

  static isAllowedFile(originalName: string, mimeType: string): boolean {
    const extension = this.sanitizeExtension(originalName).replace('.', '');
    if (extension && storageConfig.allowedExtensions.includes(extension)) {
      return true;
    }
    return storageConfig.allowedMimeTypes.includes(mimeType);
  }

  static generateStoredName(originalName: string): string {
    const ext = this.sanitizeExtension(originalName);
    return `${randomUUID()}${ext}`;
  }

  static buildRelativePath(category: StorageCategory, storedName: string): string {
    const now = new Date();
    const year = String(now.getFullYear());
    const month = String(now.getMonth() + 1).padStart(2, '0');
    return path.posix.join(category, year, month, storedName);
  }

  static getPublicUrl(relativePath: string): string {
    const normalized = relativePath.split(path.sep).join('/');
    return `${storageConfig.publicPathPrefix}/${normalized}`;
  }

  static getAbsolutePath(relativePath: string): string {
    return path.join(storageConfig.rootDir, relativePath);
  }

  static async registerFromMulterFile(
    file: Express.Multer.File,
    category?: string,
    uploadedById?: string,
  ): Promise<StoredFileResult> {
    this.ensureRootDir();

    if (!this.isAllowedFile(file.originalname, file.mimetype)) {
      if (file.path && fs.existsSync(file.path)) {
        this.deletePhysicalFile(file.path);
      }
      throw new Error('Tipo de arquivo não permitido');
    }

    const normalizedCategory = this.normalizeCategory(category);
    const targetDir = this.getCategoryDir(normalizedCategory);
    const storedName = this.generateStoredName(file.originalname);
    const targetPath = path.join(targetDir, storedName);

    if (file.path && fs.existsSync(file.path)) {
      fs.renameSync(file.path, targetPath);
    } else {
      throw new Error('Arquivo temporário não encontrado');
    }

    const relativePath = this.buildRelativePath(normalizedCategory, storedName);
    const publicUrl = this.getPublicUrl(relativePath);

    const record = await prisma.storedFile.create({
      data: {
        originalName: file.originalname,
        storedName,
        mimeType: file.mimetype,
        size: file.size,
        category: normalizedCategory,
        relativePath: relativePath.split(path.sep).join('/'),
        publicUrl,
        uploadedById: uploadedById ?? null,
      },
    });

    return {
      id: record.id,
      originalName: record.originalName,
      storedName: record.storedName,
      mimeType: record.mimeType,
      size: record.size,
      category: record.category as StorageCategory,
      relativePath: record.relativePath,
      fileUrl: record.publicUrl,
      url: record.publicUrl,
      createdAt: record.createdAt,
    };
  }

  static deletePhysicalFile(absolutePath: string): void {
    if (fs.existsSync(absolutePath)) {
      fs.unlinkSync(absolutePath);
    }
  }

  static async getById(id: string) {
    return prisma.storedFile.findUnique({ where: { id } });
  }

  static async deleteById(id: string): Promise<void> {
    const record = await prisma.storedFile.findUnique({ where: { id } });
    if (!record) {
      throw new Error('Arquivo não encontrado');
    }

    const absolutePath = this.getAbsolutePath(record.relativePath);
    this.deletePhysicalFile(absolutePath);
    await prisma.storedFile.delete({ where: { id } });
  }

  static async listRecent(limit = 50, category?: string) {
    return prisma.storedFile.findMany({
      where: category ? { category: this.normalizeCategory(category) } : undefined,
      orderBy: { createdAt: 'desc' },
      take: limit,
    });
  }
}
