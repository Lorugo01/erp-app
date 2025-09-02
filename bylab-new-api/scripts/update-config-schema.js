const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function updateConfigSchema() {
  try {
    console.log('🔄 Atualizando schema das configurações...');

    // Verificar se já existe configuração
    let config = await prisma.config.findFirst();

    if (config) {
      console.log('📝 Configuração existente encontrada, atualizando...');
      
      // Atualizar com novos campos
      config = await prisma.config.update({
        where: { id: 1 },
        data: {
          // Manter campos existentes
          evaluationModel: config.evaluationModel || 'TRADICIONAL',
          minGrade: config.minGrade || 5.0,
          minAttendance: config.minAttendance || 75.0,
          
          // Adicionar novos campos com valores padrão
          currentAcademicYear: config.currentAcademicYear || '2024',
          enrollmentPeriodStart: config.enrollmentPeriodStart || '01/12/2024',
          enrollmentPeriodEnd: config.enrollmentPeriodEnd || '31/01/2025',
          operatingHoursStart: config.operatingHoursStart || '07:00',
          operatingHoursEnd: config.operatingHoursEnd || '18:00',
          evaluationType: config.evaluationType || 'NUMERICO',
          passingGrade: config.passingGrade || 7.0,
          evaluationPeriods: config.evaluationPeriods || '4 Bimestres',
          maxClassCapacity: config.maxClassCapacity || 35,
          weeklyWorkload: config.weeklyWorkload || 25,
          maxLoginAttempts: config.maxLoginAttempts || 3,
          sessionTimeout: config.sessionTimeout || 30,
          requirePasswordChange: config.requirePasswordChange || false,
          enableDebugLogs: config.enableDebugLogs || false,
          validateSSLCert: config.validateSSLCert || true,
          autoBackupEnabled: config.autoBackupEnabled || true,
          backupFrequency: config.backupFrequency || 'DIARIO',
          retentionDays: config.retentionDays || 30,
          updatedAt: new Date(),
        },
      });
    } else {
      console.log('🆕 Criando nova configuração padrão...');
      
      // Criar nova configuração
      config = await prisma.config.create({
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
    }

    console.log('✅ Schema das configurações atualizado com sucesso!');
    console.log('📊 Configuração atual:', config);

  } catch (error) {
    console.error('❌ Erro ao atualizar schema:', error);
  } finally {
    await prisma.$disconnect();
  }
}

// Executar se chamado diretamente
if (require.main === module) {
  updateConfigSchema();
}

module.exports = { updateConfigSchema };
