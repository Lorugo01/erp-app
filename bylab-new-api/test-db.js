const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function testConnection() {
  try {
    console.log('🔍 Testando conexão com o banco...');
    
    const config = await prisma.config.findFirst();
    console.log('✅ Configuração encontrada:', config);
    
    if (!config) {
      console.log('📝 Criando configuração padrão...');
      const newConfig = await prisma.config.create({
        data: {
          evaluationModel: 'TRADICIONAL',
          minGrade: 5.0,
          minAttendance: 75.0,
          currentAcademicYear: '2024',
          enrollmentPeriodStart: '01/12/2024',
          enrollmentPeriodEnd: '31/01/2025',
          operatingHoursStart: '07:00',
          operatingHoursEnd: '18:00',
          evaluationType: 'NUMERICO',
          passingGrade: 7.0,
          evaluationPeriods: '4 Bimestres',
          maxClassCapacity: 35,
          weeklyWorkload: 25,
          maxLoginAttempts: 3,
          sessionTimeout: 30,
          requirePasswordChange: false,
          enableDebugLogs: false,
          validateSSLCert: true,
          autoBackupEnabled: true,
          backupFrequency: 'DIARIO',
          retentionDays: 30,
        },
      });
      console.log('✅ Nova configuração criada:', newConfig);
    }
    
  } catch (error) {
    console.error('❌ Erro ao conectar com o banco:', error);
  } finally {
    await prisma.$disconnect();
  }
}

testConnection();
