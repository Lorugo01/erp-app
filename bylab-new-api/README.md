# Bylab API - Sistema de Gestão Escolar

API REST para gerenciamento de uma instituição de ensino, desenvolvida com Node.js, TypeScript, Express e Prisma.

## 🚀 Funcionalidades

- Gestão de Alunos
- Gestão de Professores
- Gestão de Turmas
- Gestão de Disciplinas
- Controle de Frequência
- Matrículas
- Registro de Aulas
- Sistema de Chat com suporte a arquivos

## 🛠️ Tecnologias

- Node.js
- TypeScript
- Express
- Prisma ORM
- PostgreSQL
- CORS
- Dotenv
- Bcrypt (criptografia de senhas)

## 📋 Pré-requisitos

- Node.js (versão LTS recomendada)
- PostgreSQL
- npm ou yarn

## 🔧 Instalação

1. Clone o repositório:
```bash
git clone https://github.com/seu-usuario/bylab-new-api.git
cd bylab-new-api
```

2. Instale as dependências:
```bash
npm install
```

3. Configure as variáveis de ambiente:
Crie um arquivo `.env` na raiz do projeto com as seguintes variáveis:
```env
DATABASE_URL="postgresql://usuario:senha@localhost:5432/bylab_db"
PORT=3001
```

4. Execute as migrações do banco de dados:
```bash
npx prisma migrate dev
```

## 🚀 Executando o projeto

Para desenvolvimento:
```bash
npm run dev
```

## 📁 Estrutura do Projeto

```
src/
├── controllers/    # Controladores da aplicação
├── routes/         # Definição das rotas
├── services/       # Lógica de negócios
├── middlewares/    # Middlewares do Express
├── prisma/         # Configuração do Prisma
└── index.ts        # Arquivo principal
```

## 📚 Endpoints da API

### Sistema de Chat
- `GET /chats` - Lista todos os chats
- `POST /chats` - Cria um novo chat
- `GET /chats/:id` - Obtém um chat específico
- `PUT /chats/:id` - Atualiza um chat
- `DELETE /chats/:id` - Remove um chat
- `GET /chats/:id/participants` - Lista participantes de um chat
- `POST /chats/:id/participants` - Adiciona participante ao chat
- `DELETE /chats/:id/participants/:userId` - Remove participante do chat
- `GET /chats/:id/messages` - Lista mensagens de um chat
- `POST /chats/:id/messages` - Envia mensagem (com suporte a arquivos)
- `PUT /chats/:id/messages/:messageId` - Atualiza mensagem
- `DELETE /chats/:id/messages/:messageId` - Remove mensagem
- `GET /chats/user/:userId` - Lista chats de um usuário

**Documentação completa do chat:** [CHAT_API.md](./CHAT_API.md)

### Alunos
- `GET /students` - Lista todos os alunos
- `POST /students` - Cria um novo aluno
  ```json
  {
    "name": "Raimundo José",
    "email": "mundinho@escola.com",
    "registrationNumber": "2024001"
  }
  ```
  **Resposta de Sucesso (201 Created):**
  ```json
  {
    "message": "Aluno criado com sucesso! Um usuário foi criado automaticamente com senha padrão: 123456",
    "student": {
      "id": "uuid-do-aluno",
      "name": "Raimundo José",
      "email": "mundinho@escola.com",
      "registrationNumber": "2024001",
      "profilePicture": "/uploads/d284d3d0-410b-462d-a5a1-c71f776d2d63.jpg",
      "createdAt": "2024-03-20T10:00:00.000Z"
    },
    "user": {
      "id": "uuid-do-usuario",
      "email": "mundinho@escola.com",
      "role": "STUDENT",
      "createdAt": "2024-03-20T10:00:00.000Z"
    }
  }
  ```
  **Observações:**
  - Cria automaticamente um usuário com senha padrão "123456"
  - Permite upload de foto de perfil (campo `photo` no Form Data)
  - Email e número de matrícula devem ser únicos
  - As imagens de perfil são nomeadas com o ID do aluno (ex: `d284d3d0-410b-462d-a5a1-c71f776d2d63.jpg`)

**Exemplo de Requisição no Insomnia:**
1. **Método:** `POST`
2. **URL:** `http://localhost:3001/students`
3. **Headers:** Deixe o Insomnia definir automaticamente
4. **Body (Form):**
   - `name`: "João Silva Santos"
   - `email`: "joao.silva@escola.com"
   - `registrationNumber`: "2024001"
   - `photo`: [arquivo de imagem - opcional]

**Após a criação, o aluno poderá fazer login usando:**
- **Email:** joao.silva@escola.com
- **Senha:** 123456
- `GET /students/:id` - Obtém um aluno específico
- `PUT /students/:id` - Atualiza um aluno
  ```json
  {
    "name": "João Silva Jr.",
    "email": "joaojr@escola.com"
  }
  ```
- `DELETE /students/:id` - Remove um aluno
  **Resposta de Sucesso (200 OK):**
  ```json
  {
    "message": "Aluno e usuário vinculado foram deletados com sucesso!"
  }
  ```
  **Observações:**
  - Deleta tanto o aluno quanto o usuário vinculado a ele
  - Remove automaticamente o acesso ao sistema do usuário
- `GET /students/:id/current-class` - Busca turma atual do aluno
- `GET /students/search/:name` - Busca aluno por nome

### Professores
- `GET /teachers` - Lista todos os professores
- `POST /teachers` - Cria um novo professor
  ```json
  {
    "name": "Welton José",
    "email": "ze.welton@escola.com"
  }
  ```
  **Resposta de Sucesso (201 Created):**
  ```json
  {
    "message": "Professor criado com sucesso! Um usuário foi criado automaticamente com senha padrão: 123456",
    "teacher": {
      "id": "uuid-do-professor",
      "name": "Welton José",
      "email": "ze.welton@escola.com",
      "createdAt": "2024-03-20T10:00:00.000Z"
    },
    "user": {
      "id": "uuid-do-usuario",
      "email": "ze.welton@escola.com",
      "role": "TEACHER",
      "createdAt": "2024-03-20T10:00:00.000Z"
    }
  }
  ```
  **Observações:**
  - Cria automaticamente um usuário com senha padrão "123456"
  - Email deve ser único no sistema
  - Após a criação, o professor poderá fazer login usando o email e senha "123456"
- `GET /teachers/:id` - Obtém um professor específico
- `PUT /teachers/:id` - Atualiza um professor
  ```json
  {
    "name": "Ana S. Lima",
    "email": "ana.lima@escola.com"
  }
  ```
- `DELETE /teachers/:id` - Remove um professor
  **Resposta de Sucesso (200 OK):**
  ```json
  {
    "message": "Professor e usuário vinculado foram deletados com sucesso!"
  }
  ```
  **Observações:**
  - Deleta tanto o professor quanto o usuário vinculado a ele
  - Remove automaticamente o acesso ao sistema do usuário
- `GET /teachers/search/:name` - Busca professor por nome

### Turmas
- `GET /classes` - Lista todas as turmas
- `POST /classes` - Cria uma nova turma
  ```json
  {
    "grade": 9,
    "letter": "a",
    "academicYear": 2025,
    "shift": "VESPERTINO"
  }
  ```
- `GET /classes/:id` - Obtém uma turma específica
- `PUT /classes/:id` - Atualiza uma turma
  ```json
  {
    "grade": 9,
    "academicYear": 2026,
    "shift": "MATUTINO"
  }
  ```
- `DELETE /classes/:id` - Remove uma turma
- `GET /classes/year/:year` - Filtra turmas por ano letivo
- `GET /classes/grade/:grade` - Filtra turmas por nível
- `GET /classes/shift/:shift` - Filtra turmas por turno

### Disciplinas
- `GET /subjects` - Lista todas as disciplinas
- `POST /subjects` - Cria uma nova disciplina
  ```json
  {
    "type": "MATEMATICA",
    "classId": "cb6d2fd5-33a7-459f-bb3e-a21aa02d19bd",
    "teacherId": "9067a638-e8e6-4a1e-bc31-af482cf17604"
  }
  ```
- `GET /subjects/:id` - Obtém uma disciplina específica
- `PUT /subjects/:id` - Atualiza uma disciplina
  ```json
  {
    "name": "Matemática Aplicada",
    "teacherId": "UUID_NOVO_PROFESSOR"
  }
  ```
- `DELETE /subjects/:id` - Remove uma disciplina

### Matrículas
- `GET /enrollments` - Lista todas as matrículas
- `POST /enrollments` - Cria uma nova matrícula
  ```json
  {
    "studentId": "4e7fbee2-f019-45b0-afd5-9b4e7bec7ad5",
    "classId": "58911467-4260-46e5-86ba-142a8a1918c5",
    "year": 2025,
    "current": true
  }
  ```
- `GET /enrollments/:id` - Obtém uma matrícula específica
- `PUT /enrollments/:id` - Atualiza uma matrícula
- `DELETE /enrollments/:id` - Remove uma matrícula
- `GET /enrollments/student/:studentId` - Busca histórico de matrícula de um aluno

### Frequência
- `GET /attendances` - Lista todas as frequências
- `POST /attendances` - Registra uma nova frequência
  ```json
  {
    "studentId": "UUID_DO_ALUNO",
    "lessonId": "UUID_DA_AULA",
    "present": true
  }
  ```
- `POST /attendances/bulk` - Registra múltiplas frequências
  ```json
  {
    "lessonId": "fb8cf085-c2c8-43f9-ba7b-7d39b131d8d4",
    "presences": [
      { "studentId": "5bf5bb45-40b4-49f8-add9-4976ea80bd57", "present": true },
      { "studentId": "02b103c5-1c1c-4707-b85e-e3737a849a1c", "present": false }
    ]
  }
  ```
- `GET /attendances/:id` - Obtém uma frequência específica
- `PUT /attendances/:id` - Atualiza uma frequência
- `DELETE /attendances/:id` - Remove uma frequência

### Aulas
- `GET /lessons` - Lista todas as aulas
- `POST /lessons` - Cria uma nova aula
  ```json
  {
    "date": "2025-04-15T14:00:00.000Z",
    "classId": "3ab9b6ae-8298-420c-aab9-59871f605765",
    "subjectId": "7910ef7f-5d05-41d9-a4fb-68ae5b7d839b",
    "teacherId": "d5bb6ec0-6f55-45c9-888a-3920f0889321"
  }
  ```
- `GET /lessons/:id` - Obtém uma aula específica
- `PUT /lessons/:id` - Atualiza uma aula
  ```json
  {
    "date": "2025-04-18T08:00:00.000Z"
  }
  ```
- `DELETE /lessons/:id` - Remove uma aula

### Autenticação
O sistema possui três tipos de usuários: ADMIN, TEACHER e STUDENT. Cada tipo de usuário tem acesso a diferentes funcionalidades do sistema.

#### Registro de Usuários
- `POST /auth/register` - Registra um novo usuário
  ```json
  {
    "name": "Nome do Usuário",
    "email": "usuario@escola.com",
    "password": "123456",
    "role": "STUDENT"  // Pode ser: "ADMIN", "TEACHER" ou "STUDENT"
  }
  ```
  **Resposta de Sucesso (201 Created):**
  ```json
  {
    "id": "uuid-do-usuario",
    "email": "usuario@escola.com",
    "role": "STUDENT",
    "createdAt": "2024-03-20T10:00:00.000Z",
    "student": {
      "id": "uuid-do-estudante",
      "name": "Nome do Usuário",
      "registrationNumber": null
    }
  }
  ```

#### Login
- `POST /auth/login` - Realiza login no sistema
  ```json
  {
    "email": "usuario@escola.com",
    "password": "123456"
  }
  ```
  **Resposta de Sucesso (200 OK):**
  ```json
  {
    "id": "uuid-do-usuario",
    "email": "usuario@escola.com",
    "role": "STUDENT",
    "createdAt": "2024-03-20T10:00:00.000Z",
    "student": {
      "id": "uuid-do-estudante",
      "name": "Nome do Usuário"
    }
  }
  ```

#### Observações sobre Autenticação
1. O campo `role` no registro determina o tipo de usuário e suas permissões
2. Para professores (`role: "TEACHER"`), a resposta incluirá dados do professor em vez de student
3. Para administradores (`role: "ADMIN"`), a resposta não incluirá dados adicionais
4. Senhas são armazenadas de forma segura utilizando hash bcrypt
5. Em caso de erro de autenticação, será retornado status 401 com mensagem de erro
6. Emails devem ser únicos no sistema

## 📝 Modelo de Dados

O banco de dados possui as seguintes entidades principais:

- **User**: Sistema de autenticação e controle de acesso
- **Student**: Alunos
- **Teacher**: Professores
- **Class**: Turmas
- **Subject**: Disciplinas
- **Enrollment**: Matrículas
- **Lesson**: Aulas
- **Attendance**: Frequência

## 🤝 Contribuindo

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença ISC.

## ✒️ Autores

* **Seu Nome** - *Desenvolvimento* - [seu-usuario](https://github.com/seu-usuario) 