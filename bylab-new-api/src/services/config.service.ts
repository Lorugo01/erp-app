import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export class ConfigService {
  // Buscar todas as configurações
  async getConfig() {
    let config = await prisma.config.findFirst();
    
    if (!config) {
      // Se não existir, criar com valores padrão
      config = await this.createDefaultConfig();
    }
    
    return config;
  }

  // Atualizar configurações
  async updateConfig(configData: any) {
    let config = await prisma.config.findFirst();
    
    if (!config) {
      // Se não existir, criar com valores padrão
      config = await this.createDefaultConfig();
    }

    // Atualizar apenas os campos fornecidos
    const updatedConfig = await prisma.config.update({
      where: { id: 1 },
      data: {
        ...configData,
        updatedAt: new Date(),
      },
    });

    return updatedConfig;
  }

  // Resetar para valores padrão
  async resetToDefaults() {
    const defaultConfig = await this.createDefaultConfig();
    return defaultConfig;
  }

  // Buscar configuração por chave
  async getConfigByKey(key: string) {
    const config = await this.getConfig();
    return (config as any)[key];
  }

  // Atualizar configuração por chave
  async updateConfigByKey(key: string, value: any) {
    const updateData: any = {};
    updateData[key] = value;
    updateData.updatedAt = new Date();

    const updatedConfig = await prisma.config.update({
      where: { id: 1 },
      data: updateData,
    });

    return updatedConfig;
  }

  // Criar configuração padrão
  private async createDefaultConfig() {
    const defaultConfig = {
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
    };

    return await prisma.config.create({
      data: defaultConfig,
    });
  }

  // Buscar configurações específicas para o sistema de notas
  async getGradeConfig() {
    const config = await this.getConfig();
    return {
      evaluationModel: config.evaluationModel,
      minGrade: config.minGrade,
      evaluationType: config.evaluationType,
      passingGrade: config.passingGrade,
      evaluationPeriods: config.evaluationPeriods,
    };
  }

  // Buscar configurações específicas para turmas
  async getClassConfig() {
    const config = await this.getConfig();
    return {
      maxClassCapacity: config.maxClassCapacity,
      weeklyWorkload: config.weeklyWorkload,
    };
  }

  // Buscar configurações específicas para usuários
  async getUserConfig() {
    const config = await this.getConfig();
    return {
      maxLoginAttempts: config.maxLoginAttempts,
      sessionTimeout: config.sessionTimeout,
      requirePasswordChange: config.requirePasswordChange,
    };
  }
}
