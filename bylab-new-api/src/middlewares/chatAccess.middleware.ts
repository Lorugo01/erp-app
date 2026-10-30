import { Request, Response, NextFunction } from 'express';
import prisma from '../prisma/client';

const isDeveloper = (req: Request) => req.user?.role === 'DEVELOPER';

// Conversas são privadas: só participantes (ou developer) acessam,
// nem professor nem admin da escola leem o chat de um aluno.
export const requireChatParticipant = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const chat = await prisma.chat.findUnique({
      where: { id: req.params.id },
      select: { participants: { where: { user_id: req.user?.id }, select: { id: true } } },
    });
    if (!chat) {
      return res.status(404).json({ error: 'Chat não encontrado' });
    }
    if (!isDeveloper(req) && chat.participants.length === 0) {
      return res.status(403).json({ error: 'Acesso negado: você não participa deste chat' });
    }
    next();
  } catch (error) {
    next(error);
  }
};

// Cada usuário lista apenas os próprios chats
export const requireOwnUserParam = (req: Request, res: Response, next: NextFunction) => {
  if (!isDeveloper(req) && req.params.userId !== req.user?.id) {
    return res.status(403).json({ error: 'Acesso negado: chats de outro usuário' });
  }
  next();
};

// Sair do chat é livre; remover outra pessoa exige perfil de staff
export const requireParticipantRemoval = (req: Request, res: Response, next: NextFunction) => {
  const isStaff = ['DEVELOPER', 'ADMIN', 'TEACHER'].includes(req.user?.role || '');
  if (!isStaff && req.params.userId !== req.user?.id) {
    return res.status(403).json({ error: 'Acesso negado: não é possível remover outro participante' });
  }
  next();
};

// A mensagem precisa ser deste chat; só o autor altera (mensagens da IA não têm autor)
export const requireMessageOwner = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const message = await prisma.message.findUnique({
      where: { id: req.params.messageId },
      select: { chat_id: true, user_id: true },
    });
    if (!message || message.chat_id !== req.params.id) {
      return res.status(404).json({ error: 'Mensagem não encontrada' });
    }
    if (!isDeveloper(req) && message.user_id && message.user_id !== req.user?.id) {
      return res.status(403).json({ error: 'Acesso negado: mensagem de outro usuário' });
    }
    next();
  } catch (error) {
    next(error);
  }
};
