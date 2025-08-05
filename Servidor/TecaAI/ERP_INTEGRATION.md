# 🔗 Integração ERP-TecaAI

## 📋 Visão Geral

Este documento explica como o sistema ERP pode acessar e controlar o TecaAI através de uma API REST intermediária.

## 🏗️ Arquitetura da Integração

```
┌─────────────┐    HTTP/REST    ┌─────────────┐    TCP Socket    ┌─────────────┐
│    ERP      │ ──────────────► │   Bridge    │ ──────────────► │   TecaAI    │
│  (Flutter)  │                 │   (Flask)   │                 │   (Python)  │
└─────────────┘                 └─────────────┘                 └─────────────┘
```

### **Componentes:**

1. **ERP (Flutter)**: Interface do usuário
2. **Bridge API (Flask)**: API REST que traduz requisições HTTP para TCP
3. **TecaAI (Python)**: Sistema de IA robótica

## 🚀 Como Usar

### **1. Iniciar os Servidores**

```bash
# Terminal 1 - TecaAI (porta 5000)
cd Servidor/TecaAI
python API_Rpi.py

# Terminal 2 - Bridge API (porta 5001)
cd Servidor/TecaAI
python erp_api.py

# Terminal 3 - ERP (Flutter)
cd erp
flutter run
```

### **2. Acessar a Demo no ERP**

1. Faça login como administrador
2. Navegue para a tela "TecaAI - Demonstração"
3. Teste as funcionalidades disponíveis

## 📡 Endpoints da API Bridge

### **Health Check**
```http
GET /health
```
**Resposta:**
```json
{
  "status": "online",
  "service": "ERP-TecaAI Bridge",
  "timestamp": "2025-01-15T10:00:00.000Z"
}
```

### **Fazer Pergunta para IA**
```http
POST /ask
Content-Type: application/json

{
  "question": "O que é um cilindro volumétrico?",
  "voice": "Teca",
  "user_id": "uuid-do-usuario",
  "user_role": "admin"
}
```

### **Localizar Item**
```http
POST /locate
Content-Type: application/json

{
  "item": "cilindro volumétrico",
  "user_id": "uuid-do-usuario",
  "user_role": "admin"
}
```

### **Controlar Dispositivo**
```http
POST /control
Content-Type: application/json

{
  "command": "ligue a luz",
  "user_id": "uuid-do-usuario",
  "user_role": "admin"
}
```

### **Obter Informações do Item**
```http
POST /item-info
Content-Type: application/json

{
  "item": "cilindro volumétrico",
  "user_id": "uuid-do-usuario",
  "user_role": "admin"
}
```

### **Histórico de Comandos**
```http
GET /history?user_id=uuid&limit=50
```

### **Estatísticas**
```http
GET /stats
```

## 🎯 Casos de Uso

### **1. Professor faz pergunta sobre equipamento**
```dart
final response = await TecaAIService.askQuestion(
  question: "Como usar um microscópio?",
  user: currentUser,
  voice: "Teca"
);
```

### **2. Aluno localiza material**
```dart
final response = await TecaAIService.locateItem(
  item: "tubo de ensaio",
  user: currentUser
);
```

### **3. Administrador controla ambiente**
```dart
final response = await TecaAIService.controlDevice(
  command: "ligue a luz",
  user: currentUser
);
```

### **4. Sistema automático de segurança**
```dart
final response = await TecaAIService.executePredefinedCommand(
  commandKey: "alarme_fumaca",
  user: systemUser
);
```

## 🔧 Configuração

### **Variáveis de Ambiente**

No arquivo `erp_api.py`:
```python
TECAAI_HOST = "localhost"  # IP do TecaAI
TECAAI_PORT = 5000         # Porta do TecaAI
```

No arquivo `tecaai_service.dart`:
```dart
static const String baseUrl = 'http://192.168.18.15:5001';  // IP da Bridge API
```

### **Dependências Python**
```bash
pip install flask flask-cors
```

## 📊 Monitoramento

### **Logs**
- **TecaAI**: `Servidor/TecaAI/servidor.log`
- **Bridge API**: Logs no console
- **ERP**: Logs no console do Flutter

### **Banco de Dados**
- **TecaAI**: `cache.db`, `comandos.db`
- **Bridge API**: `erp_tecaai.db`

### **Métricas Disponíveis**
- Total de comandos
- Taxa de sucesso
- Comandos por tipo
- Comandos por usuário
- Histórico detalhado

## 🛡️ Segurança

### **Validações**
- Tamanho máximo de perguntas (500 caracteres)
- Tamanho máximo de comandos (100 caracteres)
- Validação de vozes permitidas
- Timeout de conexão (10 segundos)

### **Logs de Auditoria**
- Todos os comandos são registrados
- Identificação do usuário
- Timestamp de execução
- Status de sucesso/erro

## 🔄 Fluxo de Dados

### **1. Pergunta para IA**
```
ERP → Bridge API → TecaAI → IA (Ollama) → Resposta → ERP
```

### **2. Localização de Item**
```
ERP → Bridge API → TecaAI → Banco de Dados → ESP32 → LEDs
```

### **3. Controle de Dispositivo**
```
ERP → Bridge API → TecaAI → ESP32 → Ação Física
```

## 🚨 Troubleshooting

### **Problema: TecaAI não responde**
```bash
# Verificar se o servidor está rodando
netstat -an | grep 5000

# Verificar logs
tail -f Servidor/TecaAI/servidor.log
```

### **Problema: Bridge API não conecta**
```bash
# Verificar se a porta está livre
netstat -an | grep 5001

# Testar conexão manual
curl http://localhost:5001/health
```

### **Problema: ERP não conecta**
```dart
// Verificar IP da Bridge API
final connected = await TecaAIService.checkConnection();
print('Conectado: $connected');
```

## 📈 Próximos Passos

### **Melhorias Planejadas**
1. **Autenticação JWT** na Bridge API
2. **Rate Limiting** para evitar spam
3. **WebSocket** para comunicação em tempo real
4. **Notificações push** para eventos importantes
5. **Dashboard** de monitoramento em tempo real

### **Integrações Futuras**
1. **Agendamento** de comandos automáticos
2. **Sincronização** com calendário escolar
3. **Relatórios** de uso do laboratório
4. **Controle de acesso** baseado em permissões
5. **Integração** com sistema de alarmes

## 📞 Suporte

Para dúvidas ou problemas:
1. Verificar logs de erro
2. Testar conectividade entre componentes
3. Validar configurações de IP/porta
4. Verificar dependências instaladas 