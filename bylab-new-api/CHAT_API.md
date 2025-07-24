# Sistema de Chat - API Documentation 

## 📋 Visão Geral

O sistema de chat permite comunicação entre usuários da plataforma escolar, com suporte a mensagens de texto e envio de arquivos.

## 🔗 Endpoints

### Chats

#### Listar todos os chats
```
GET /chats
```
**Resposta:**
```json
[
  {
    "id": "uuid-do-chat",
    "title": "Chat da Turma 9ºA",
    "created_at": "2025-01-15T10:00:00.000Z",
    "participants": [ ... ],
    "messages": [ ... ]
  }
]
```

#### Criar um novo chat
```
POST /chats
```
**Body:**
```json
{
  "title": "Chat da Turma 9ºA",
  "participants": ["uuid-usuario-1", "uuid-usuario-2"]
}
```

#### Buscar chat por ID
```
GET /chats/:id
```

#### Atualizar chat
```
PUT /chats/:id
```
**Body:**
```json
{
  "title": "Novo título do chat"
}
```

#### Deletar chat
```
DELETE /chats/:id
```

### Participantes

#### Listar participantes de um chat
```
GET /chats/:id/participants
```

#### Adicionar participante
```
POST /chats/:id/participants
```
**Body:**
```json
{
  "userId": "uuid-do-usuario"
}
```

#### Remover participante
```
DELETE /chats/:id/participants/:userId
```

### Mensagens

#### Listar mensagens de um chat
```
GET /chats/:id/messages
```

#### Enviar mensagem
```
POST /chats/:id/messages
```
**Body (Form Data ou JSON):**
- `content`: "Conteúdo da mensagem" (obrigatório)
- `userId`: "uuid-do-usuario" (obrigatório para usuário, null para IA)
- `isAI`: true/false (opcional, default: false)
- `file`: [arquivo opcional]

**Exemplo para mensagem de usuário:**
```json
{
  "content": "Olá turma!",
  "userId": "uuid-do-usuario"
}
```

**Exemplo para mensagem da IA:**
```json
{
  "content": "Olá! Como posso ajudar?",
  "isAI": true
}
```

**Exemplo com arquivo (FormData):**
```javascript
const formData = new FormData();
formData.append('content', 'Aqui está o material da aula.');
formData.append('userId', 'uuid-do-usuario');
formData.append('file', arquivo); // opcional
```

#### Atualizar mensagem
```
PUT /chats/:id/messages/:messageId
```
**Body:**
```json
{
  "content": "Mensagem atualizada"
}
```

#### Deletar mensagem
```
DELETE /chats/:id/messages/:messageId
```

### Chats do Usuário

#### Listar chats de um usuário
```
GET /chats/user/:userId
```

## 📁 Tipos de Arquivo Suportados

### Imagens
- JPEG (.jpg, .jpeg)
- PNG (.png)
- GIF (.gif)

### Documentos
- PDF (.pdf)
- Word (.doc, .docx)
- Excel (.xls, .xlsx)
- Texto (.txt)

## 🔐 Segurança

- Apenas participantes podem enviar mensagens no chat
- Validação de usuário antes de adicionar como participante
- Verificação de existência de chat antes de operações
- Controle de acesso por participação

## 📊 Estrutura de Dados

### Chat
```typescript
{
  id: string;
  title: string;
  created_at: Date;
  participants: ChatParticipant[];
  messages: Message[];
}
```

### ChatParticipant
```typescript
{
  id: string;
  chat_id: string;
  user_id: string;
  user: User;
}
```

### Message
```typescript
{
  id: string;
  chat_id: string;
  user_id: string | null; // null para mensagens da IA
  content: string;
  created_at: Date;
  user: User | null; // null para mensagens da IA
  files: File[];
}
```

### File
```typescript
{
  id: string;
  message_id: string;
  file_path: string;
  file_name: string;
  file_type: string;
  uploaded_at: Date;
}
```

## 🚀 Exemplos de Uso

### 1. Criar um chat para uma turma
```javascript
const response = await fetch('/chats', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    title: 'Chat da Turma 9ºA - 2025',
    participants: ['uuid-professor', 'uuid-aluno-1', 'uuid-aluno-2']
  })
});
```

### 2. Enviar uma mensagem de usuário
```javascript
const response = await fetch('/chats/uuid-do-chat/messages', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    content: 'Olá turma!',
    userId: 'uuid-do-usuario'
  })
});
```

### 3. Enviar uma mensagem da IA
```javascript
const response = await fetch('/chats/uuid-do-chat/messages', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    content: 'Olá! Como posso ajudar?',
    isAI: true
  })
});
```

### 4. Enviar uma mensagem com arquivo
```javascript
const formData = new FormData();
formData.append('content', 'Aqui está o material da aula de hoje!');
formData.append('userId', 'uuid-professor');
formData.append('file', arquivoPDF);

const response = await fetch('/chats/uuid-do-chat/messages', {
  method: 'POST',
  body: formData
});
```

### 5. Buscar mensagens de um chat
```javascript
const response = await fetch('/chats/uuid-do-chat/messages');
const messages = await response.json();
```

## ⚠️ Observações

1. **Participação obrigatória**: Usuários só podem enviar mensagens se forem participantes do chat
2. **Arquivos**: Suporte a upload de arquivos com validação de tipo
3. **Ordenação**: Mensagens são ordenadas por data de criação (mais antigas primeiro)
4. **Relacionamentos**: Sistema inclui dados completos de usuários (student/teacher)
5. **Cascade**: Deletar um chat remove automaticamente participantes e mensagens
6. **Validação**: Verificações de existência e permissões em todas as operações
7. **Mensagens da IA**: Devem ser enviadas com `isAI: true` e sem `userId` (ou `userId: null`). 