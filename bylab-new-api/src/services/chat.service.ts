import prisma from '../prisma/client';

// Chat Services
export const getAllChats = () => {
  return prisma.chat.findMany({
    include: {
      participants: {
        include: {
          user: {
            select: {
              id: true,
              email: true,
              role: true,
              student: {
                select: {
                  id: true,
                  name: true
                }
              },
              teacher: {
                select: {
                  id: true,
                  name: true
                }
              }
            }
          }
        }
      },
      messages: {
        include: {
          user: {
            select: {
              id: true,
              email: true,
              role: true,
              student: {
                select: {
                  id: true,
                  name: true
                }
              },
              teacher: {
                select: {
                  id: true,
                  name: true
                }
              }
            }
          },
          files: true
        },
        orderBy: {
          created_at: 'asc'
        }
      }
    },
    orderBy: {
      created_at: 'desc'
    }
  });
};

export const getChatById = async (id: string) => {
  if (!id || typeof id !== 'string' || id.length < 10) {
    throw new Error('ID inválido');
  }

  const chat = await prisma.chat.findUnique({
    where: { id },
    include: {
      participants: {
        include: {
          user: {
            select: {
              id: true,
              email: true,
              role: true,
              student: {
                select: {
                  id: true,
                  name: true
                }
              },
              teacher: {
                select: {
                  id: true,
                  name: true
                }
              }
            }
          }
        }
      },
      messages: {
        include: {
          user: {
            select: {
              id: true,
              email: true,
              role: true,
              student: {
                select: {
                  id: true,
                  name: true
                }
              },
              teacher: {
                select: {
                  id: true,
                  name: true
                }
              }
            }
          },
          files: true
        },
        orderBy: {
          created_at: 'asc'
        }
      }
    }
  });

  if (!chat) {
    throw new Error('Chat não encontrado');
  }

  return chat;
};

export const createChat = async (data: {
  title: string;
  participants?: string[];
}) => {
  // Removido: Verificação de título único
  // const existingChat = await prisma.chat.findFirst({
  //   where: { title: data.title }
  // });
  // if (existingChat) {
  //   throw new Error('Já existe um chat com este título');
  // }

  // Cria o chat normalmente
  const chat = await prisma.chat.create({
    data: {
      title: data.title
    },
    include: {
      participants: {
        include: {
          user: {
            select: {
              id: true,
              email: true,
              role: true,
              student: {
                select: {
                  id: true,
                  name: true
                }
              },
              teacher: {
                select: {
                  id: true,
                  name: true
                }
              }
            }
          }
        }
      }
    }
  });

  // Adiciona participantes se fornecidos
  if (data.participants && data.participants.length > 0) {
    for (const userId of data.participants) {
      await addParticipant(chat.id, userId);
    }
  }

  return chat;
};

export const updateChat = async (id: string, data: {
  title?: string;
}) => {
  // Verifica se o chat existe
  const existingChat = await prisma.chat.findUnique({
    where: { id }
  });

  if (!existingChat) {
    throw new Error('Chat não encontrado');
  }

  // Se estiver atualizando o título, verifica se já existe
  if (data.title) {
    const chatWithSameTitle = await prisma.chat.findFirst({
      where: {
        title: data.title,
        NOT: { id }
      }
    });

    if (chatWithSameTitle) {
      throw new Error('Já existe um chat com este título');
    }
  }

  return prisma.chat.update({
    where: { id },
    data,
    include: {
      participants: {
        include: {
          user: {
            select: {
              id: true,
              email: true,
              role: true,
              student: {
                select: {
                  id: true,
                  name: true
                }
              },
              teacher: {
                select: {
                  id: true,
                  name: true
                }
              }
            }
          }
        }
      }
    }
  });
};

export const deleteChat = async (id: string) => {
  // Verifica se o chat existe
  const chat = await prisma.chat.findUnique({
    where: { id }
  });

  if (!chat) {
    throw new Error('Chat não encontrado');
  }

  // Deleta o chat (participantes e mensagens serão deletados automaticamente por CASCADE)
  return prisma.chat.delete({
    where: { id }
  });
};

// Participant Services
export const getChatParticipants = async (chatId: string) => {
  const participants = await prisma.chatparticipant.findMany({
    where: { chat_id: chatId },
    include: {
      user: {
        select: {
          id: true,
          email: true,
          role: true,
          student: {
            select: {
              id: true,
              name: true
            }
          },
          teacher: {
            select: {
              id: true,
              name: true
            }
          }
        }
      }
    }
  });

  return participants;
};

export const addParticipant = async (chatId: string, userId: string) => {
  // Verifica se o chat existe
  const chat = await prisma.chat.findUnique({
    where: { id: chatId }
  });

  if (!chat) {
    throw new Error('Chat não encontrado');
  }

  // Verifica se o usuário existe
  const user = await prisma.user.findUnique({
    where: { id: userId }
  });

  if (!user) {
    throw new Error('Usuário não encontrado');
  }

  // Verifica se o usuário já é participante
  const existingParticipant = await prisma.chatparticipant.findFirst({
    where: {
      chat_id: chatId,
      user_id: userId
    }
  });

  if (existingParticipant) {
    throw new Error('Usuário já é participante deste chat');
  }

  // Adiciona o participante
  return prisma.chatparticipant.create({
    data: {
      chat_id: chatId,
      user_id: userId
    },
    include: {
      user: {
        select: {
          id: true,
          email: true,
          role: true,
          student: {
            select: {
              id: true,
              name: true
            }
          },
          teacher: {
            select: {
              id: true,
              name: true
            }
          }
        }
      }
    }
  });
};

export const removeParticipant = async (chatId: string, userId: string) => {
  // Verifica se o participante existe
  const participant = await prisma.chatparticipant.findFirst({
    where: {
      chat_id: chatId,
      user_id: userId
    }
  });

  if (!participant) {
    throw new Error('Participante não encontrado');
  }

  // Remove o participante
  return prisma.chatparticipant.delete({
    where: { id: participant.id }
  });
};

export const isUserParticipant = async (chatId: string, userId: string) => {
  const participant = await prisma.chatparticipant.findFirst({
    where: {
      chat_id: chatId,
      user_id: userId
    }
  });

  return !!participant;
};

// Message Services
export const getChatMessages = async (chatId: string) => {
  const messages = await prisma.message.findMany({
    where: { chat_id: chatId },
    include: {
      user: {
        select: {
          id: true,
          email: true,
          role: true,
          student: {
            select: {
              id: true,
              name: true
            }
          },
          teacher: {
            select: {
              id: true,
              name: true
            }
          }
        }
      },
      files: true
    },
    orderBy: {
      created_at: 'asc'
    }
  });

  return messages;
};

export const sendMessage = async (
  chatId: string,
  userId: string | null,
  content: string,
  fileData?: {
    file_path: string;
    file_name: string;
    file_type: string;
  }
) => {
  // Verifica se o chat existe
  const chat = await prisma.chat.findUnique({
    where: { id: chatId }
  });

  if (!chat) {
    throw new Error('Chat não encontrado');
  }

  // Só verifica usuário se userId não for nulo
  if (userId) {
  const user = await prisma.user.findUnique({
    where: { id: userId }
  });
  if (!user) {
    throw new Error('Usuário não encontrado');
    }
  }

  // Cria a mensagem
  const messageData: any = {
    chat_id: chatId,
    content
  };
  if (userId) {
    messageData.user_id = userId;
  }
  const message = await prisma.message.create({
    data: messageData,
    include: {
      user: {
        select: {
          id: true,
          email: true,
          role: true,
          student: {
            select: {
              id: true,
              name: true
            }
          },
          teacher: {
            select: {
              id: true,
              name: true
            }
          }
        }
      },
      files: true
    }
  });

  // Se há arquivo, cria o registro do arquivo
  if (fileData) {
    await prisma.file.create({
      data: {
        message_id: message.id,
        file_path: fileData.file_path,
        file_name: fileData.file_name,
        file_type: fileData.file_type
      }
    });
  }

  // Retorna a mensagem com o arquivo atualizado
  return prisma.message.findUnique({
    where: { id: message.id },
    include: {
      user: {
        select: {
          id: true,
          email: true,
          role: true,
          student: {
            select: {
              id: true,
              name: true
            }
          },
          teacher: {
            select: {
              id: true,
              name: true
            }
          }
        }
      },
      files: true
    }
  });
};

export const updateMessage = async (messageId: string, content: string) => {
  // Verifica se a mensagem existe
  const message = await prisma.message.findUnique({
    where: { id: messageId }
  });

  if (!message) {
    throw new Error('Mensagem não encontrada');
  }

  // Atualiza a mensagem
  return prisma.message.update({
    where: { id: messageId },
    data: { content },
    include: {
      user: {
        select: {
          id: true,
          email: true,
          role: true,
          student: {
            select: {
              id: true,
              name: true
            }
          },
          teacher: {
            select: {
              id: true,
              name: true
            }
          }
        }
      },
      files: true
    }
  });
};

export const deleteMessage = async (messageId: string) => {
  // Verifica se a mensagem existe
  const message = await prisma.message.findUnique({
    where: { id: messageId }
  });

  if (!message) {
    throw new Error('Mensagem não encontrada');
  }

  // Deleta a mensagem (arquivos serão deletados automaticamente por CASCADE)
  return prisma.message.delete({
    where: { id: messageId }
  });
};

// User Chat Services
export const getUserChats = async (userId: string) => {
  const chats = await prisma.chat.findMany({
    where: {
      participants: {
        some: {
          user_id: userId
        }
      }
    },
    include: {
      participants: {
        include: {
          user: {
            select: {
              id: true,
              email: true,
              role: true,
              student: {
                select: {
                  id: true,
                  name: true
                }
              },
              teacher: {
                select: {
                  id: true,
                  name: true
                }
              }
            }
          }
        }
      },
      messages: {
        include: {
          user: {
            select: {
              id: true,
              email: true,
              role: true,
              student: {
                select: {
                  id: true,
                  name: true
                }
              },
              teacher: {
                select: {
                  id: true,
                  name: true
                }
              }
            }
          },
          files: true
        },
        orderBy: {
          created_at: 'desc'
        },
        take: 1 // Pega apenas a última mensagem
      }
    },
    orderBy: {
      created_at: 'desc'
    }
  });

  return chats;
}; 