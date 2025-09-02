import { Request, Response } from 'express';
import { ConfigService } from '../services/config.service';

export class ConfigController {
  private configService: ConfigService;

  constructor() {
    this.configService = new ConfigService();
  }

  // Buscar todas as configurações
  async getConfig(req: Request, res: Response) {
    try {
      console.log('🔍 Buscando configurações...');
      const config = await this.configService.getConfig();
      console.log('✅ Configurações encontradas:', config);
      res.json(config);
    } catch (error) {
      console.error('❌ Erro ao buscar configurações:', error);
      res.status(500).json({ 
        error: 'Erro interno do servidor',
        details: error instanceof Error ? error.message : 'Erro desconhecido'
      });
    }
  }

  // Atualizar configurações
  async updateConfig(req: Request, res: Response) {
    try {
      console.log('📝 Atualizando configurações:', req.body);
      const configData = req.body;
      const updatedConfig = await this.configService.updateConfig(configData);
      console.log('✅ Configurações atualizadas:', updatedConfig);
      res.json(updatedConfig);
    } catch (error) {
      console.error('❌ Erro ao atualizar configurações:', error);
      res.status(500).json({ 
        error: 'Erro interno do servidor',
        details: error instanceof Error ? error.message : 'Erro desconhecido'
      });
    }
  }

  // Resetar configurações para padrão
  async resetConfig(req: Request, res: Response) {
    try {
      console.log('🔄 Resetando configurações...');
      const defaultConfig = await this.configService.resetToDefaults();
      console.log('✅ Configurações resetadas:', defaultConfig);
      res.json(defaultConfig);
    } catch (error) {
      console.error('❌ Erro ao resetar configurações:', error);
      res.status(500).json({ 
        error: 'Erro interno do servidor',
        details: error instanceof Error ? error.message : 'Erro desconhecido'
      });
    }
  }

  // Buscar configuração específica
  async getConfigByKey(req: Request, res: Response) {
    try {
      const { key } = req.params;
      console.log('🔍 Buscando configuração:', key);
      const value = await this.configService.getConfigByKey(key);
      console.log('✅ Valor encontrado:', value);
      res.json({ key, value });
    } catch (error) {
      console.error('❌ Erro ao buscar configuração:', error);
      res.status(500).json({ 
        error: 'Erro interno do servidor',
        details: error instanceof Error ? error.message : 'Erro desconhecido'
      });
    }
  }

  // Atualizar configuração específica
  async updateConfigByKey(req: Request, res: Response) {
    try {
      const { key } = req.params;
      const { value } = req.body;
      console.log('📝 Atualizando configuração:', key, '=', value);
      const updatedConfig = await this.configService.updateConfigByKey(key, value);
      console.log('✅ Configuração atualizada:', updatedConfig);
      res.json(updatedConfig);
    } catch (error) {
      console.error('❌ Erro ao atualizar configuração:', error);
      res.status(500).json({ 
        error: 'Erro interno do servidor',
        details: error instanceof Error ? error.message : 'Erro desconhecido'
      });
    }
  }
}
