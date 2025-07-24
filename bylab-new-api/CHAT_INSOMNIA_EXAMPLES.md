# Exemplos de Requisições - Sistema de Chat

## 📋 Configuração no Insomnia

### 1. Criar Chat
**Método:** `POST`
**URL:** `http://localhost:3001/chats`
**Headers:**
```
Content-Type: application/json
```
**Body (JSON):**
```json
{
  "title": "Chat da Turma 9ºA - 2025",
  "participants": [
    "uuid-do-professor",
    "uuid-do-aluno-1",
    "uuid-do-aluno-2"
  ]
}
```

### 2. Listar Todos os Chats
**Método:** `GET`
**URL:** `http://localhost:3001/chats`

### 3. Buscar Chat por ID
**Método:** `GET`
**URL:** `http://localhost:3001/chats/uuid-do-chat`

### 4. Atualizar Chat
**Método:** `PUT`
**URL:** `http://localhost:3001/chats/uuid-do-chat`
**Headers:**
```
Content-Type: application/json
```
**Body (JSON):**
```json
{
  "title": "Chat da Turma 9ºA - Matemática"
}
```

### 5. Deletar Chat
**Método:** `DELETE`
**URL:** `http://localhost:3001/chats/uuid-do-chat`

### 6. Listar Participantes
**Método:** `GET`
**URL:** `http://localhost:3001/chats/uuid-do-chat/participants`

### 7. Adicionar Participante
**Método:** `POST`
**URL:** `http://localhost:3001/chats/uuid-do-chat/participants`
**Headers:**
```
Content-Type: application/json
```
**Body (JSON):**
```json
{
  "userId": "uuid-do-novo-usuario"
}
```

### 8. Remover Participante
**Método:** `DELETE`
**URL:** `http://localhost:3001/chats/uuid-do-chat/participants/uuid-do-usuario`

### 9. Listar Mensagens
**Método:** `GET`
**URL:** `http://localhost:3001/chats/uuid-do-chat/messages`

### 10. Enviar Mensagem (Texto)
**Método:** `POST`
**URL:** `http://localhost:3001/chats/uuid-do-chat/messages`
**Headers:**
```
Content-Type: application/json
```
**Body (JSON):**
```json
{
  "content": "Olá turma! Aqui está o material da aula de hoje.",
  "userId": "uuid-do-professor"
}
```

### 11. Enviar Mensagem com Arquivo
**Método:** `POST`
**URL:** `http://localhost:3001/chats/uuid-do-chat/messages`
**Headers:**
```
Content-Type: multipart/form-data
```
**Body (Form):**
- `content`: "Aqui está o material da aula de matemática"
- `userId`: "uuid-do-professor"
- `file`: [selecionar arquivo]

### 12. Atualizar Mensagem
**Método:** `PUT`
**URL:** `http://localhost:3001/chats/uuid-do-chat/messages/uuid-da-mensagem`
**Headers:**
```
Content-Type: application/json
```
**Body (JSON):**
```json
{
  "content": "Mensagem atualizada com correções"
}
```

### 13. Deletar Mensagem
**Método:** `DELETE`
**URL:** `http://localhost:3001/chats/uuid-do-chat/messages/uuid-da-mensagem`

### 14. Listar Chats de um Usuário
**Método:** `GET`
**URL:** `http://localhost:3001/chats/user/uuid-do-usuario`

## 🔄 Fluxo Típico de Uso

### 1. Criar Chat para uma Turma
```bash
# 1. Criar o chat
POST /chats
{
  "title": "Chat da Turma 9ºA - Matemática",
  "participants": ["professor-uuid", "aluno1-uuid", "aluno2-uuid"]
}

# 2. Verificar participantes
GET /chats/chat-uuid/participants

# 3. Enviar primeira mensagem
POST /chats/chat-uuid/messages
{
  "content": "Bem-vindos ao chat da turma!",
  "userId": "professor-uuid"
}
```

### 2. Compartilhar Material
```bash
# Enviar mensagem com arquivo
POST /chats/chat-uuid/messages (multipart/form-data)
- content: "Aqui está o material da aula de hoje"
- userId: "professor-uuid"
- file: [arquivo.pdf]
```

### 3. Gerenciar Participantes
```bash
# Adicionar novo aluno
POST /chats/chat-uuid/participants
{
  "userId": "novo-aluno-uuid"
}

# Remover participante
DELETE /chats/chat-uuid/participants/usuario-uuid
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

## ⚠️ Observações Importantes

1. **Participação obrigatória**: Usuários só podem enviar mensagens se forem participantes do chat
2. **Validação de arquivos**: Apenas tipos específicos são aceitos
3. **Tamanho de arquivo**: Limite de 10MB por arquivo
4. **Ordenação**: Mensagens são ordenadas por data de criação (mais antigas primeiro)
5. **Relacionamentos**: Respostas incluem dados completos de usuários (student/teacher)
6. **Cascade**: Deletar um chat remove automaticamente participantes e mensagens

## 🚨 Códigos de Erro Comuns

- `400`: Dados inválidos ou usuário já é participante
- `403`: Usuário não é participante do chat
- `404`: Chat, mensagem ou usuário não encontrado
- `500`: Erro interno do servidor 