import cors from 'cors';
import dotenv from 'dotenv';
import express from 'express';
import path from 'path';
import https from 'https';
import http from 'http';
import fs from 'fs';

import studentRoutes from './routes/student.routes';
import teacherRoutes from './routes/teacher.routes';
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
import schoolRoutes from './routes/school.routes';

dotenv.config();

const app = express();

const HOST = process.env.HOST || '0.0.0.0';
const HTTP_PORT = Number(process.env.HTTP_PORT || process.env.PORT || 3000);
const HTTPS_PORT = Number(process.env.HTTPS_PORT || 3001);
const ENABLE_HTTPS = process.env.ENABLE_HTTPS === 'true';

const corsOrigin = process.env.CORS_ORIGIN;

if (!corsOrigin || corsOrigin === '*') {
  app.use(cors());
} else {
  app.use(
    cors({
      origin: corsOrigin.split(',').map((origin) => origin.trim()),
    }),
  );
}
app.use(express.json());

app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

app.use('/auth', authRoutes);
app.use('/users', userRoutes);
app.use('/students', studentRoutes);
app.use('/teachers', teacherRoutes);
app.use('/subjects', subjectRoutes);
app.use('/attendances', attendanceRoutes);
app.use('/enrollments', enrollmentRoutes);
app.use('/lessons', lessonRoutes);
app.use('/classes', classRoutes);
app.use('/chats', chatRoutes);
app.use('/grades', gradeRoutes);
app.use('/grade-types', gradeTypeRoutes);
app.use('/grade-periods', gradePeriodRoutes);
app.use('/assignments', assignmentRoutes);
app.use('/schools', schoolRoutes);

app.get('/', (req, res) => {
  res.json({
    status: 'ok',
    service: 'bylab-new-api',
    httpPort: HTTP_PORT,
    httpsEnabled: ENABLE_HTTPS,
  });
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy' });
});

const httpServer = http.createServer(app);
httpServer.listen(HTTP_PORT, HOST, () => {
  console.log(`Servidor HTTP rodando em http://${HOST}:${HTTP_PORT}`);
});

if (ENABLE_HTTPS) {
  try {
    const sslOptions = {
      key: fs.readFileSync(path.join(__dirname, '../ssl/private.key')),
      cert: fs.readFileSync(path.join(__dirname, '../ssl/certificate.crt')),
    };

    const httpsServer = https.createServer(sslOptions, app);
    httpsServer.listen(HTTPS_PORT, HOST, () => {
      console.log(`Servidor HTTPS rodando em https://${HOST}:${HTTPS_PORT}`);
    });
  } catch (error: any) {
    console.log('Erro ao iniciar servidor HTTPS:', error.message);
    console.log('Continuando apenas com HTTP...');
  }
}
