import { Router } from 'express';
import * as ChatController from '../controllers/chat.controller';
import { upload } from '../middlewares/upload.middleware';

const chatRoutes = Router();

// Rotas para chats
chatRoutes.get('/', ChatController.getAllChats);
chatRoutes.post('/', ChatController.createChat);
chatRoutes.get('/:id', ChatController.getChatById);
chatRoutes.put('/:id', ChatController.updateChat);
chatRoutes.delete('/:id', ChatController.deleteChat);

// Rotas para participantes
chatRoutes.get('/:id/participants', ChatController.getChatParticipants);
chatRoutes.post('/:id/participants', ChatController.addParticipant);
chatRoutes.delete('/:id/participants/:userId', ChatController.removeParticipant);

// Rotas para mensagens
chatRoutes.get('/:id/messages', ChatController.getChatMessages);
chatRoutes.post('/:id/messages', upload.single('file'), ChatController.sendMessage);
chatRoutes.put('/:id/messages/:messageId', ChatController.updateMessage);
chatRoutes.delete('/:id/messages/:messageId', ChatController.deleteMessage);

// Rota para buscar chats de um usuário
chatRoutes.get('/user/:userId', ChatController.getUserChats);

export default chatRoutes; 