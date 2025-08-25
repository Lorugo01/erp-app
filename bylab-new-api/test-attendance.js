const axios = require('axios');

const BASE_URL = 'http://localhost:3000';

// Token de teste (você pode precisar ajustar)
const TEST_TOKEN = 'seu_token_aqui'; // Substitua por um token válido

const headers = {
  'Content-Type': 'application/json',
  'Authorization': `Bearer ${TEST_TOKEN}`
};

// Dados de teste
const testData = {
  classId: 'test-class-id',
  subjectId: 'test-subject-id', 
  teacherId: 'test-teacher-id',
  date: new Date().toISOString(),
  students: [
    { id: 'student-1', name: 'Aluno Teste 1' },
    { id: 'student-2', name: 'Aluno Teste 2' }
  ]
};

async function testLessonGetOrCreate() {
  console.log('\n=== TESTANDO LESSON GET-OR-CREATE ===');
  
  try {
    const response = await axios.post(`${BASE_URL}/lessons/get-or-create`, {
      classId: testData.classId,
      subjectId: testData.subjectId,
      teacherId: testData.teacherId,
      date: testData.date
    }, { headers });
    
    console.log('✅ Lesson criada/encontrada:', response.data);
    return response.data;
  } catch (error) {
    console.log('❌ Erro ao criar/buscar lesson:');
    console.log('Status:', error.response?.status);
    console.log('Data:', error.response?.data);
    console.log('Message:', error.message);
    return null;
  }
}

async function testAttendanceBulk(lessonId) {
  console.log('\n=== TESTANDO ATTENDANCE BULK ===');
  
  const presences = [
    {
      studentId: 'student-1',
      status: 'PRESENT',
      justification: null,
      present: true
    },
    {
      studentId: 'student-2', 
      status: 'ABSENT',
      justification: null,
      present: false
    }
  ];
  
  try {
    const response = await axios.post(`${BASE_URL}/attendances/bulk`, {
      lessonId: lessonId,
      presences: presences
    }, { headers });
    
    console.log('✅ Frequência salva em bulk:', response.data);
    return response.data;
  } catch (error) {
    console.log('❌ Erro ao salvar frequência bulk:');
    console.log('Status:', error.response?.status);
    console.log('Data:', error.response?.data);
    console.log('Message:', error.message);
    return null;
  }
}

async function testAttendanceGetByLesson(lessonId) {
  console.log('\n=== TESTANDO GET ATTENDANCE BY LESSON ===');
  
  try {
    const response = await axios.get(`${BASE_URL}/attendances/lesson/${lessonId}`, { headers });
    
    console.log('✅ Frequência carregada:', response.data);
    return response.data;
  } catch (error) {
    console.log('❌ Erro ao carregar frequência:');
    console.log('Status:', error.response?.status);
    console.log('Data:', error.response?.data);
    console.log('Message:', error.message);
    return null;
  }
}

async function testWithoutAuth() {
  console.log('\n=== TESTANDO SEM AUTENTICAÇÃO ===');
  
  try {
    const response = await axios.post(`${BASE_URL}/lessons/get-or-create`, {
      classId: testData.classId,
      subjectId: testData.subjectId,
      teacherId: testData.teacherId,
      date: testData.date
    });
    
    console.log('✅ Funcionou sem auth:', response.data);
  } catch (error) {
    console.log('❌ Erro sem auth (esperado):');
    console.log('Status:', error.response?.status);
    console.log('Data:', error.response?.data);
  }
}

async function runTests() {
  console.log('🧪 INICIANDO TESTES DE ATTENDANCE/LESSON API');
  console.log('Base URL:', BASE_URL);
  
  // Teste sem auth primeiro
  await testWithoutAuth();
  
  // Teste com token (mesmo que inválido, para ver a estrutura de erro)
  const lesson = await testLessonGetOrCreate();
  
  if (lesson && lesson.id) {
    await testAttendanceBulk(lesson.id);
    await testAttendanceGetByLesson(lesson.id);
  }
  
  console.log('\n🏁 TESTES CONCLUÍDOS');
}

// Executar testes
runTests().catch(console.error);

