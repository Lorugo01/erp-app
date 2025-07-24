import { Request, Response, NextFunction } from 'express';
import * as ChatService from '../services/chat.service';
import path from 'path';
import fs from 'fs';

// Chat Controllers
export const getAllChats = async (_: Request, res: Response) => {
  try {
    const chats = await ChatService.getAllChats();
    res.json(chats);
  } catch (error) {
    res.status(500).json({ error: (error as Error).message });
  }
};

export const getChatById = async (req: Request, res: Response) => {
  try {
    const chat = await ChatService.getChatById(req.params.id);
    res.json(chat);
  } catch (error) {
    res.status(404).json({ error: (error as Error).message });
  }
};

export const createChat = async (req: Request, res: Response) => {
  try {
    const { title, participants } = req.body;
    
    if (!title) {
      return res.status(400).json({ error: 'Título do chat é obrigatório' });
    }

    const chat = await ChatService.createChat({ title, participants });
    res.status(201).json(chat);
  } catch (error) {
    res.status(400).json({ error: (error as Error).message });
  }
};

export const updateChat = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { title } = req.body;
    
    const chat = await ChatService.updateChat(id, { title });
    res.json(chat);
  } catch (error) {
    res.status(400).json({ error: (error as Error).message });
  }
};

export const deleteChat = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    await ChatService.deleteChat(id);
    res.status(200).json({ message: 'Chat deletado com sucesso!' });
  } catch (error) {
    res.status(400).json({ error: (error as Error).message });
  }
};

// Participant Controllers
export const getChatParticipants = async (req: Request, res: Response) => {
  try {
    const participants = await ChatService.getChatParticipants(req.params.id);
    res.json(participants);
  } catch (error) {
    res.status(404).json({ error: (error as Error).message });
  }
};

export const addParticipant = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { userId } = req.body;
    
    if (!userId) {
      return res.status(400).json({ error: 'ID do usuário é obrigatório' });
    }

    const participant = await ChatService.addParticipant(id, userId);
    res.status(201).json(participant);
  } catch (error) {
    res.status(400).json({ error: (error as Error).message });
  }
};

export const removeParticipant = async (req: Request, res: Response) => {
  try {
    const { id, userId } = req.params;
    await ChatService.removeParticipant(id, userId);
    res.status(200).json({ message: 'Participante removido com sucesso!' });
  } catch (error) {
    res.status(400).json({ error: (error as Error).message });
  }
};

// Message Controllers
export const getChatMessages = async (req: Request, res: Response) => {
  try {
    const messages = await ChatService.getChatMessages(req.params.id);
    res.json(messages);
  } catch (error) {
    res.status(404).json({ error: (error as Error).message });
  }
};

export const sendMessage = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { content, userId, isAI } = req.body;
    
    if (!content) {
      return res.status(400).json({ error: 'Conteúdo é obrigatório' });
    }

    // Se não for mensagem da IA, userId é obrigatório
    if (!isAI && !userId) {
      return res.status(400).json({ error: 'ID do usuário é obrigatório para mensagens de usuário' });
    }

    // Só verifica participação se não for IA
    if (!isAI && userId) {
      const isParticipant = await ChatService.isUserParticipant(id, userId);
      if (!isParticipant) {
        return res.status(403).json({ error: 'Usuário não é participante deste chat' });
      }
    }

    let fileData = undefined;
    if (req.file) {
      const filePath = `/uploads/${req.file.filename}`;
      fileData = {
        file_path: filePath,
        file_name: req.file.originalname,
        file_type: req.file.mimetype
      };
    }

    // userId deve ser null para IA
    const realUserId = isAI ? null : userId;

    const message = await ChatService.sendMessage(id, realUserId, content, fileData);
    res.status(201).json(message);
  } catch (error) {
    res.status(400).json({ error: (error as Error).message });
  }
};

export const updateMessage = async (req: Request, res: Response) => {
  try {
    const { id, messageId } = req.params;
    const { content } = req.body;
    
    const message = await ChatService.updateMessage(messageId, content);
    res.json(message);
  } catch (error) {
    res.status(400).json({ error: (error as Error).message });
  }
};

export const deleteMessage = async (req: Request, res: Response) => {
  try {
    const { messageId } = req.params;
    await ChatService.deleteMessage(messageId);
    res.status(200).json({ message: 'Mensagem deletada com sucesso!' });
  } catch (error) {
    res.status(400).json({ error: (error as Error).message });
  }
};

// User Chat Controllers
export const getUserChats = async (req: Request, res: Response) => {
  try {
    const chats = await ChatService.getUserChats(req.params.userId);
    res.json(chats);
  } catch (error) {
    res.status(404).json({ error: (error as Error).message });
  }
}; 