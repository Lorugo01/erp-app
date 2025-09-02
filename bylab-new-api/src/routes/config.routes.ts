import { Router } from 'express';
import { ConfigController } from '../controllers/config.controller';

const router = Router();
const configController = new ConfigController();

// Buscar todas as configurações
router.get('/', (req, res) => configController.getConfig(req, res));

// Atualizar todas as configurações
router.put('/', (req, res) => configController.updateConfig(req, res));

// Resetar configurações para padrão
router.post('/reset', (req, res) => configController.resetConfig(req, res));

// Buscar configuração específica por chave
router.get('/:key', (req, res) => configController.getConfigByKey(req, res));

// Atualizar configuração específica por chave
router.put('/:key', (req, res) => configController.updateConfigByKey(req, res));

export default router;
