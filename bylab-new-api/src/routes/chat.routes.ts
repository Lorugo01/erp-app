import { Router } from 'express';
import * as ChatController from '../controllers/chat.controller';
import { upload } from '../middlewares/upload.middleware';
import { authenticateToken, requireDeveloper } from '../middlewares/auth.middleware';
import {
  requireChatParticipant,
  requireMessageOwner,
  requireOwnUserParam,
  requireParticipantRemoval,
} from '../middlewares/chatAccess.middleware';

const chatRoutes = Router();

chatRoutes.use(authenticateToken);

// Rotas para chats
chatRoutes.get('/', requireDeveloper, ChatController.getAllChats);
chatRoutes.post('/', ChatController.createChat);
chatRoutes.get('/:id', requireChatParticipant, ChatController.getChatById);
chatRoutes.put('/:id', requireChatParticipant, ChatController.updateChat);
chatRoutes.delete('/:id', requireChatParticipant, ChatController.deleteChat);

// Rotas para participantes
chatRoutes.get('/:id/participants', requireChatParticipant, ChatController.getChatParticipants);
chatRoutes.post('/:id/participants', requireChatParticipant, ChatController.addParticipant);
chatRoutes.delete(
  '/:id/participants/:userId',
  requireChatParticipant,
  requireParticipantRemoval,
  ChatController.removeParticipant,
);

// Rotas para mensagens
chatRoutes.get('/:id/messages', requireChatParticipant, ChatController.getChatMessages);
chatRoutes.post(
  '/:id/messages',
  requireChatParticipant,
  upload.single('file'),
  ChatController.sendMessage,
);
chatRoutes.put(
  '/:id/messages/:messageId',
  requireChatParticipant,
  requireMessageOwner,
  ChatController.updateMessage,
);
chatRoutes.delete(
  '/:id/messages/:messageId',
  requireChatParticipant,
  requireMessageOwner,
  ChatController.deleteMessage,
);

// Rota para buscar chats de um usuário
chatRoutes.get('/user/:userId', requireOwnUserParam, ChatController.getUserChats);

export default chatRoutes; 