import crypto from 'crypto';
import { Request, Response, NextFunction } from 'express';
import { storageConfig } from '../config/storage.config';

// Anexos de atividades, entregas e chat só abrem com link assinado e
// temporário (pedido em POST /storage/sign). Fotos de perfil, logos e demais
// imagens continuam públicas porque os apps as exibem direto.
const PROTECTED_FOLDERS = ['assignments', 'submissions', 'chat', '_temp'];
const SIGNED_URL_TTL_SECONDS = 10 * 60;

const secret = () => process.env.JWT_SECRET || 'your-secret-key';

const signature = (path: string, exp: number) =>
  crypto.createHmac('sha256', secret()).update(`${path}:${exp}`).digest('base64url');

// path relativo ao prefixo, ex.: "/submissions/arquivo.pdf"
export const isProtectedUploadPath = (path: string) => {
  const [first = ''] = path.replace(/^\/+/, '').split('/');
  // Arquivos antigos do chat ficaram na raiz com o nome temporário do multer
  return PROTECTED_FOLDERS.includes(first) || first.startsWith('temp-');
};

// fileUrl como gravado no banco ("/uploads/..."); devolve o link assinado
export const signUploadUrl = (fileUrl: string) => {
  const exp = Math.floor(Date.now() / 1000) + SIGNED_URL_TTL_SECONDS;
  const query = `exp=${exp}&sig=${signature(fileUrl, exp)}`;
  return { url: `${fileUrl}${fileUrl.includes('?') ? '&' : '?'}${query}`, expiresAt: new Date(exp * 1000) };
};

const isValidSignature = (fileUrl: string, exp: number, sig: string) => {
  if (!Number.isFinite(exp) || exp < Date.now() / 1000) return false;
  const expected = Buffer.from(signature(fileUrl, exp));
  const received = Buffer.from(sig);
  return expected.length === received.length && crypto.timingSafeEqual(expected, received);
};

// Montado antes do express.static em storageConfig.publicPathPrefix
export const protectUploads = (req: Request, res: Response, next: NextFunction) => {
  let path: string;
  try {
    path = decodeURIComponent(req.path);
  } catch {
    return res.status(400).json({ error: 'Caminho inválido' });
  }
  if (path.includes('..')) {
    return res.status(400).json({ error: 'Caminho inválido' });
  }
  if (!isProtectedUploadPath(path)) {
    return next();
  }
  const exp = Number(req.query.exp);
  const sig = typeof req.query.sig === 'string' ? req.query.sig : '';
  if (!isValidSignature(`${storageConfig.publicPathPrefix}${path}`, exp, sig)) {
    return res.status(403).json({ error: 'Link do arquivo inválido ou expirado' });
  }
  next();
};
