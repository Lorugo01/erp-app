# 🔧 Configuração de Rede para Teste em Dispositivos Externos

## 📱 Problema
O app não consegue se conectar ao servidor quando testado em dispositivos externos à rede local.

## 🛠️ Soluções

### **Opção 1: Configurar IP Público (Recomendado)**

1. **Descobrir seu IP público:**
   ```bash
   # No Windows
   ipconfig
   
   # Ou acesse: https://whatismyipaddress.com
   ```

2. **Configurar Port Forwarding no Roteador:**
   - Acesse o painel do seu roteador (geralmente 192.168.1.1)
   - Configure port forwarding da porta 3000 para o IP da sua máquina
   - Exemplo: Porta 3000 → IP 192.168.18.15

3. **Atualizar a configuração no app:**
   ```dart
   // Em lib/config/environment.dart
   case Environment.development:
     return 'http://SEU_IP_PUBLICO:3000';
   ```

### **Opção 2: Usar ngrok (Para testes rápidos)**

1. **Instalar ngrok:**
   ```bash
   # Baixe em: https://ngrok.com/download
   ```

2. **Executar ngrok:**
   ```bash
   ngrok http 3000
   ```

3. **Usar a URL do ngrok:**
   ```dart
   // Em lib/config/environment.dart
   case Environment.development:
     return 'https://SEU_TUNEL_NGROK.ngrok.io';
   ```

### **Opção 3: Configurar Ambiente de Desenvolvimento**

1. **Para desenvolvimento local (mesma rede):**
   ```dart
   EnvironmentConfig.setEnvironment(Environment.development);
   ```

2. **Para produção:**
   ```dart
   EnvironmentConfig.setEnvironment(Environment.production);
   ```

## 🔄 Como Alterar a Configuração

### **Método 1: Alterar no código**
```dart
// Em lib/main.dart, adicione:
import 'config/environment.dart';

void main() {
  // Para desenvolvimento (IP da sua máquina)
  EnvironmentConfig.setEnvironment(Environment.development);
  
  // Para produção
  // EnvironmentConfig.setEnvironment(Environment.production);
  
  runApp(MyApp());
}
```

### **Método 2: Configuração dinâmica**
```dart
// Em lib/config/environment.dart, altere:
case Environment.development:
  return 'http://SEU_IP_PUBLICO:3000';
```

## 🔍 Verificação de Conectividade

1. **Teste no navegador:**
   ```
   http://SEU_IP:3000
   ```

2. **Teste com curl:**
   ```bash
   curl http://SEU_IP:3000
   ```

3. **Verificar firewall:**
   - Windows: Permitir porta 3000 no firewall
   - Roteador: Verificar se a porta está liberada

## 📋 Checklist

- [ ] IP público configurado
- [ ] Port forwarding configurado
- [ ] Firewall liberado
- [ ] Servidor rodando na porta 3000
- [ ] App configurado com o IP correto
- [ ] Teste de conectividade realizado

## 🚨 Troubleshooting

### **Erro: "Operation not permitted"**
- Verificar se o IP está correto
- Verificar se a porta está liberada
- Verificar se o servidor está rodando

### **Erro: "Connection timeout"**
- Verificar conectividade de rede
- Verificar configuração do roteador
- Testar com ngrok como alternativa

### **Erro: "Connection refused"**
- Verificar se o servidor está rodando
- Verificar se a porta está correta
- Verificar firewall local 