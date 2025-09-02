import cors from 'cors';
import dotenv from 'dotenv';
import express from 'express';
import path from 'path';
import https from 'https';
import http from 'http';
import fs from 'fs';

import studentRoutes from './routes/student.routes';
import teacherRoutes from './routes/teacher.routes';
import subjectsRoutes from './routes/subjects.routes';
import subjectRoutes from './routes/subject.routes';
import enrollmentRoutes from './routes/enrollment.routes';
import attendanceRoutes from './routes/attendance.routes';
import lessonRoutes from './routes/lesson.routes';
import classRoutes from './routes/class.routes';
import chatRoutes from './routes/chat.routes';
import userRoutes from './routes/user.routes';
import { authRoutes } from './routes/auth.routes';
import gradeRoutes from './routes/grade.routes';
import gradeTypeRoutes from './routes/gradeType.routes';
import gradePeriodRoutes from './routes/gradePeriod.routes';
import assignmentRoutes from './routes/assignment.routes';
import configRoutes from './routes/config.routes';

dotenv.config();

const app = express();

// Middlewares
app.use(cors());
app.use(express.json());

// Configuração para servir arquivos estáticos da pasta uploads
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// Rotas
app.use('/auth', authRoutes);
app.use('/users', userRoutes);
app.use('/students', studentRoutes);
app.use('/teachers', teacherRoutes);
app.use('/subjects', subjectsRoutes); // Rotas de disciplinas (types, etc.)
app.use('/subject', subjectRoutes); // Rotas de matéria específica
app.use('/attendances', attendanceRoutes);
app.use('/enrollments', enrollmentRoutes);
app.use('/lessons', lessonRoutes);
app.use('/classes', classRoutes);
app.use('/chats', chatRoutes);
app.use('/grades', gradeRoutes);
app.use('/grade-types', gradeTypeRoutes);
app.use('/grade-periods', gradePeriodRoutes);
app.use('/assignments', assignmentRoutes);
app.use('/config', configRoutes);

// Rota de teste
app.get('/', (req, res) => {
  res.send('bylab-new-api rodando com HTTP e HTTPS.');
});

const PORT = process.env.PORT || 3001;
const HTTP_PORT = 3000;

// Iniciar servidor HTTP
const httpServer = http.createServer(app);
httpServer.listen(HTTP_PORT, () => {
  console.log(`Servidor HTTP rodando na porta ${HTTP_PORT}`);
});

// Configuração SSL e inicialização do servidor HTTPS
try {
  const sslOptions = {
    key: fs.readFileSync(path.join(__dirname, '../ssl/private.key')),
    cert: fs.readFileSync(path.join(__dirname, '../ssl/certificate.crt'))
  };
  
  const httpsServer = https.createServer(sslOptions, app);
  httpsServer.listen(PORT, () => {
    console.log(`Servidor HTTPS rodando na porta ${PORT}`);
  });
} catch (error: any) {
  console.log('Erro ao iniciar servidor HTTPS:', error.message);
  console.log('Continuando apenas com HTTP...');
}
