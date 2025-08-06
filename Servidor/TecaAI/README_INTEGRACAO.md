# 🔗 Integração ERP-TecaAI

## 📋 Visão Geral

Este sistema integra o **API_Rpi.py** (servidor TCP) com o **ERP API** (servidor Flask) em um único processo, permitindo que ambos os servidores funcionem simultaneamente.

## 🚀 Como Usar

### 1. Instalação de Dependências

```bash
# Instalar dependências do Flask
pip install flask flask-cors

# Verificar se todas as dependências estão instaladas
pip install -r requirements.txt
```

### 2. Executar o Sistema Integrado

```bash
# Navegar para o diretório
cd Servidor/TecaAI

# Executar o sistema integrado
python API_Rpi.py
```

## 🏗️ Arquitetura

### Servidores em Execução

1. **Servidor TCP (API_Rpi.py)**
   - **Porta:** 5000
   - **Função:** Comunicação com TecaAI, controle de dispositivos
   - **Protocolo:** TCP com JSON

2. **Servidor Flask (ERP API)**
   - **Porta:** 5001
   - **Função:** API REST para frontend Flutter
   - **Protocolo:** HTTP/HTTPS

### Fluxo de Comunicação

```
Flutter App → HTTP/5001 → Flask API → TCP/5000 → TecaAI → ESP32
```

## 📊 Endpoints Disponíveis

### Servidor Flask (Porta 5001)

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| `GET` | `/health` | Status do servidor |
| `POST` | `/ask` | Perguntas para IA |
| `POST` | `/locate` | Localizar itens |
| `POST` | `/control` | Controlar dispositivos |
| `GET` | `/items` | Listar itens |
| `POST` | `/items` | Adicionar item |
| `GET` | `/history` | Histórico de comandos |
| `GET` | `/stats` | Estatísticas |

### Exemplos de Uso

#### 1. Health Check
```bash
curl http://localhost:5001/health
```

#### 2. Pergunta para IA
```bash
curl -X POST http://localhost:5001/ask \
  -H "Content-Type: application/json" \
  -d '{
    "question": "O que é um cilindro volumétrico?",
    "voice": "Teca",
    "user_id": "user123",
    "user_role": "student"
  }'
```

#### 3. Localizar Item
```bash
curl -X POST http://localhost:5001/locate \
  -H "Content-Type: application/json" \
  -d '{
    "item": "cilindro volumetrico",
    "user_id": "user123",
    "user_role": "student"
  }'
```

#### 4. Listar Itens
```bash
curl http://localhost:5001/items
```

#### 5. Adicionar Item
```bash
curl -X POST http://localhost:5001/items \
  -H "Content-Type: application/json" \
  -d '{
    "nome": "novo_item",
    "posicao": "f1s1",
    "esp_ip": "192.168.100.184",
    "user_id": "admin123",
    "user_role": "admin"
  }'
```

## 🔧 Configuração

### Variáveis de Ambiente

```python
# Configurações do TecaAI
TECAAI_HOST = "localhost"
TECAAI_PORT = 5000

# Configurações do Flask
FLASK_HOST = "0.0.0.0"
FLASK_PORT = 5001
```

### Bancos de Dados

1. **`erp_tecaai.db`** - Histórico de comandos do ERP
2. **`localizações/localizacoes.db`** - Itens do laboratório
3. **`cache.db`** - Cache de respostas da IA

## 🐛 Troubleshooting

### Problemas Comuns

1. **Erro de Importação Flask**
   ```bash
   pip install flask flask-cors
   ```

2. **Porta já em uso**
   ```bash
   # Verificar processos
   netstat -tulpn | grep :5001
   
   # Matar processo
   kill -9 <PID>
   ```

3. **Banco de dados não encontrado**
   ```bash
   # Verificar se o arquivo existe
   ls -la localizações/localizacoes.db
   ```

4. **Erro de comunicação TCP**
   - Verificar se o servidor TCP está rodando na porta 5000
   - Verificar firewall e configurações de rede

### Logs

Os logs são salvos em:
- **`servidor.log`** - Logs gerais do sistema
- **Console** - Logs em tempo real

## 📈 Monitoramento

### Estatísticas

Acesse `/stats` para ver:
- Total de comandos
- Comandos por tipo
- Comandos por usuário
- Taxa de sucesso

### Histórico

Acesse `/history` para ver:
- Histórico completo de comandos
- Filtros por usuário
- Limite de registros

## 🔄 Atualizações

### Adicionar Novos Endpoints

1. Adicione a rota no final do arquivo `API_Rpi.py`
2. Implemente a lógica necessária
3. Teste a integração

### Modificar Configurações

1. Edite as constantes no início do arquivo
2. Reinicie o servidor
3. Verifique se as mudanças foram aplicadas

## 🎯 Próximos Passos

1. **Autenticação:** Implementar sistema de autenticação
2. **Rate Limiting:** Limitar requisições por usuário
3. **WebSocket:** Comunicação em tempo real
4. **Docker:** Containerização do sistema
5. **Load Balancer:** Balanceamento de carga

## 📞 Suporte

Para problemas ou dúvidas:
1. Verifique os logs em `servidor.log`
2. Teste os endpoints individualmente
3. Verifique a conectividade de rede
4. Consulte a documentação do TecaAI 