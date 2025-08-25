const http = require('http');

function testAttendance() {
  console.log('🧪 Testando rotas de attendance...');
  
  // Testar rota de attendance por lesson
  const options = {
    hostname: 'localhost',
    port: 3000,
    path: '/attendance/lesson/test-lesson-id',
    method: 'GET'
  };

  const req = http.request(options, (res) => {
    console.log(`📡 Status: ${res.statusCode}`);
    
    let data = '';
    res.on('data', (chunk) => {
      data += chunk;
    });
    
    res.on('end', () => {
      console.log('📄 Resposta:', data);
      
      if (res.statusCode === 200) {
        try {
          const attendances = JSON.parse(data);
          console.log('✅ Sucesso! Attendances encontrados:', attendances.length);
        } catch (e) {
          console.log('❌ Erro ao parsear resposta');
        }
      } else {
        console.log('❌ Erro na requisição');
      }
    });
  });

  req.on('error', (e) => {
    console.error('❌ Erro de conexão:', e.message);
  });

  req.end();
}

testAttendance();
