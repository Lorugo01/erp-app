#include <WiFi.h>
#include <FastLED.h>
#include <WebServer.h>

// --- Configuração Geral ---
#define NUM_STRIPS        5
#define LEDS_PER_STRIP    96
#define LEDS_STRIP6      160

// Tamanho de cada sessão (número de LEDs) por fita
constexpr int sessionSizes[NUM_STRIPS] = {24, 24, 12, 12, 12};
// Número de sessões por fita (editar conforme necessidade)
constexpr int sessionsCount[NUM_STRIPS] = {3, 2, 8, 8, 8};

const char* ssid     = "BYLAB";
const char* password = "Byl@b2025";
IPAddress local_IP(192,168,18,181);
IPAddress gateway(192,168,18,1);
IPAddress subnet(255,255,255,0);

WebServer   httpServer(80);
WiFiServer  tcpServer(1234);

IPAddress alertServerIP(192,168,100,32);
const uint16_t alertServerPort = 9000;

constexpr uint8_t MUX_SIG_PIN = 32;
constexpr uint8_t MUX_S0 = 18, MUX_S1 = 19, MUX_S2 = 21, MUX_S3 = 22;

// Buffer circular para média de 10 leituras
static int sensorValues[12];
static int smokeReadings[12][10];
static uint8_t smokeIndex[12];
// Timestamp do primeiro evento acima do threshold para cada sensor
static unsigned long smokeDetectedTime[12] = {0};
const int smokeThreshold = 600;

// Pinos de LED
constexpr uint8_t PIN_STRIP1 = 4, PIN_STRIP2 = 5, PIN_STRIP3 = 12,
                  PIN_STRIP4 = 25, PIN_STRIP5 = 26, PIN_STRIP6 = 2;

// Buffers FastLED
CRGB leds[NUM_STRIPS][LEDS_PER_STRIP];
CRGB ledsExtra[LEDS_STRIP6];

// Modos de operação
enum SystemMode { NORMAL, DEMO, EMERGENCY };
SystemMode systemMode = NORMAL;

// Cores de demo
constexpr int NUM_DEMO_COLORS = 9;
CRGB demoColors[NUM_DEMO_COLORS] = {
  CRGB::Red, CRGB::Green, CRGB::Blue,
  CRGB::Yellow, CRGB::Purple, CRGB::Cyan,
  CRGB::White, CRGB::Orange, CRGB::HotPink
};
constexpr int ANIM_DELAY = 0.5;  // Reduzido de 7 para 3 para maior velocidade

// Converte nome em cor
CRGB corDeNome(const String &nome) {
  if (nome.equalsIgnoreCase("vermelho")) return CRGB::Red;
  if (nome.equalsIgnoreCase("verde"))    return CRGB::Green;
  if (nome.equalsIgnoreCase("azul"))     return CRGB::Blue;
  if (nome.equalsIgnoreCase("amarelo"))  return CRGB::Yellow;
  if (nome.equalsIgnoreCase("roxo"))     return CRGB::Purple;
  if (nome.equalsIgnoreCase("ciano"))    return CRGB::Cyan;
  if (nome.equalsIgnoreCase("branco"))   return CRGB::White;
  if (nome.equalsIgnoreCase("laranja"))  return CRGB::Orange;
  if (nome.equalsIgnoreCase("rosa"))     return CRGB::HotPink;
  if (nome.equalsIgnoreCase("preto") || nome.equalsIgnoreCase("off")) return CRGB::Black;
  return CRGB::White;
}

// Envia resposta Serial/TCP
void sendResponse(const String &resp, WiFiClient *c = nullptr) {
  Serial.println(resp);
  if (c && c->connected()) c->println(resp);
}

// Seleciona canal do MUX
void selectMux(uint8_t ch) {
  digitalWrite(MUX_S0, ch & 1);
  digitalWrite(MUX_S1, (ch >> 1) & 1);
  digitalWrite(MUX_S2, (ch >> 2) & 1);
  digitalWrite(MUX_S3, (ch >> 3) & 1);
}

// Lê e calcula média de 10 leituras por sensor
void readSensors() {
  for (uint8_t ch = 0; ch < 12; ch++) {
    selectMux(ch);
    delay(2);
    int raw = analogRead(MUX_SIG_PIN);
    smokeReadings[ch][smokeIndex[ch]] = raw;
    smokeIndex[ch] = (smokeIndex[ch] + 1) % 10;
    long sum = 0;
    for (int i = 0; i < 10; i++) sum += smokeReadings[ch][i];
    sensorValues[ch] = sum / 10;
  }
}

// Verifica alarme: dispara após 3s contínuos acima do threshold
void checkSmoke() {
  unsigned long now = millis();
  for (int i = 0; i < 12; i++) {
    if (sensorValues[i] > smokeThreshold) {
      if (smokeDetectedTime[i] == 0) {
        smokeDetectedTime[i] = now;
      } else if ((now - smokeDetectedTime[i]) >= 3000ul) {
        if (systemMode != EMERGENCY) {
          systemMode = EMERGENCY;
          WiFiClient a;
          if (a.connect(alertServerIP, alertServerPort)) {
            a.println("ALERTA: fumaça detectada por >3s!");
            a.stop();
          }
        }
      }
    } else {
      smokeDetectedTime[i] = 0;
    }
  }
}

// Animação TECA ON/OFF
void animacaoTecaOn() {
  Serial.println("[ESP32 DEBUG] Iniciando animação TECA ON");
  int c = LEDS_STRIP6/2;
  Serial.println("[ESP32 DEBUG] Centro da fita: LED " + String(c));
  
  // Expansão da luz do centro
  Serial.println("[ESP32 DEBUG] Fase 1: Expansão branca do centro");
  for (int i = 0; i <= c; i++) { 
    ledsExtra[c-i] = ledsExtra[c+i] = CRGB::White; 
    FastLED.show();
    delay(5);  // Reduzido de 10 para 5 para maior velocidade
  }
  delay(50);  // Reduzido de 100 para 50 para maior velocidade
  
  // Transição para azul
  Serial.println("[ESP32 DEBUG] Fase 2: Transição para azul");
  for (int i = 0; i <= c; i++) { 
    ledsExtra[c-i] = ledsExtra[c+i] = CRGB::Blue;  
    FastLED.show();
    delay(5);  // Reduzido de 10 para 5 para maior velocidade
  }
  Serial.println("[ESP32 DEBUG] Animação TECA ON concluída");
}

void animacaoTecaOff() {
  Serial.println("[ESP32 DEBUG] Iniciando animação TECA OFF");
  int c = LEDS_STRIP6/2;
  Serial.println("[ESP32 DEBUG] Centro da fita: LED " + String(c));
  
  // Apaga do centro para as extremidades
  Serial.println("[ESP32 DEBUG] Apagando do centro para as extremidades");
  for (int i = 0; i <= c; i++) { 
    ledsExtra[c-i] = ledsExtra[c+i] = CRGB::Black; 
    FastLED.show();
    delay(5);  // Reduzido de 10 para 5 para maior velocidade
  }
  Serial.println("[ESP32 DEBUG] Animação TECA OFF concluída");
}

// Demo: acende cumulativo e reseta após preencher
void animacaoDemo() {
  static int pos = 0, idx = 0;
  
  // Preenche todas as fitas
  for (int s = 0; s < NUM_STRIPS; s++) {
    for (int i = 0; i < LEDS_PER_STRIP; i++) {
      leds[s][i] = (i <= pos) ? demoColors[idx] : CRGB::Black;
    }
  }
  FastLED.show();
  delay(ANIM_DELAY);
  pos++;
  
  // Reseta quando completa uma fita
  if (pos >= LEDS_PER_STRIP) {
    Serial.println("[ESP32 DEBUG] Demo: Resetando animação (cor " + String(idx) + " completa)");
    delay(ANIM_DELAY * 10);  // Reduzido para transição mais rápida entre cores
    pos = 0;
    idx = (idx + 1) % NUM_DEMO_COLORS;
    Serial.println("[ESP32 DEBUG] Demo: Próxima cor " + String(idx) + " de " + String(NUM_DEMO_COLORS));
    FastLED.clear();
    FastLED.show();
  }
}

// Processa comandos HTTP/TCP/Serial
void processCommand(const String &cmd, WiFiClient *c = nullptr) {
  String command = cmd;
  command.toLowerCase();
  command.trim();
  
  Serial.println("[ESP32 DEBUG] ==========================================");
  Serial.println("[ESP32 DEBUG] Comando recebido: '" + command + "'");
  Serial.println("[ESP32 DEBUG] Origem: " + String(c ? "TCP" : "Serial/HTTP"));
  Serial.println("[ESP32 DEBUG] Modo atual: " + String(systemMode == NORMAL ? "NORMAL" : systemMode == DEMO ? "DEMO" : "EMERGENCY"));
  Serial.println("[ESP32 DEBUG] ==========================================");
  
  if (command == "demo") {
    Serial.println("[ESP32 DEBUG] Executando: DEMO ON");
    // Zera timers de fumaça ao entrar em DEMO
    for (int i = 0; i < 12; i++) smokeDetectedTime[i] = 0;
    systemMode = DEMO;
    Serial.println("[ESP32 DEBUG] Modo alterado para: DEMO");
    sendResponse("DEMO ligado", c);
    
  } else if (command == "demo off") {
    Serial.println("[ESP32 DEBUG] Executando: DEMO OFF");
    systemMode = NORMAL;
  FastLED.clear();
  FastLED.show();
    Serial.println("[ESP32 DEBUG] Modo alterado para: NORMAL");
    Serial.println("[ESP32 DEBUG] LEDs limpos");
    sendResponse("DEMO desligado", c);
    
  } else if (command == "tecaon") {
    Serial.println("[ESP32 DEBUG] Executando: TECA ON");
    animacaoTecaOn();
    Serial.println("[ESP32 DEBUG] Animação TECA ON concluída");
    sendResponse("TECA on", c);
    
  } else if (command == "tecaoff") {
    Serial.println("[ESP32 DEBUG] Executando: TECA OFF");
    animacaoTecaOff();
    Serial.println("[ESP32 DEBUG] Animação TECA OFF concluída");
    sendResponse("TECA off", c);
    
  } else if (command.startsWith("allled ")) {
    String cor = command.substring(7);
    Serial.println("[ESP32 DEBUG] Executando: ALL LED " + cor);
    CRGB col = corDeNome(cor);
    Serial.println("[ESP32 DEBUG] Cor aplicada: " + String(col.r) + "," + String(col.g) + "," + String(col.b));
    
    for (int s = 0; s < NUM_STRIPS; s++) {
      for (int i = 0; i < LEDS_PER_STRIP; i++) {
        leds[s][i] = col;
    }
  }
  FastLED.show();
    Serial.println("[ESP32 DEBUG] Todas as fitas atualizadas");
    sendResponse("All LED " + cor, c);
    
  } else if (command.startsWith("fx")) {
    Serial.println("[ESP32 DEBUG] Executando comando FX: " + command);
    
    if (command.length() < 6) {
      Serial.println("[ESP32 DEBUG] ERRO: Formato inválido");
      sendResponse("FX inválido - formato: fx<fita><sessao> <cor>", c);
      return;
  }
  
    int f = command.charAt(2) - '1';
    int sec = command.charAt(4) - '1';
    
    Serial.println("[ESP32 DEBUG] Fita: " + String(f) + " (índice " + String(f) + ")");
    Serial.println("[ESP32 DEBUG] Sessão: " + String(sec) + " (índice " + String(sec) + ")");
    
    if (f < 0 || f >= NUM_STRIPS || sec < 0 || sec >= sessionsCount[f]) {
      Serial.println("[ESP32 DEBUG] ERRO: Fita ou sessão inválida");
      Serial.println("[ESP32 DEBUG] Fitas disponíveis: 0-" + String(NUM_STRIPS-1));
      Serial.println("[ESP32 DEBUG] Sessões na fita " + String(f) + ": 0-" + String(sessionsCount[f]-1));
      sendResponse("FX inválido - fita ou sessão fora do range", c);
    return;
  }
  
    String cor = command.substring(6);
    CRGB blinkColor = corDeNome(cor);
    int start = sec * sessionSizes[f];
    int len = sessionSizes[f];
    
    Serial.println("[ESP32 DEBUG] Cor: " + cor);
    Serial.println("[ESP32 DEBUG] LED inicial: " + String(start));
    Serial.println("[ESP32 DEBUG] LEDs na sessão: " + String(len));
  
  // Salva estado atual
    std::vector<CRGB> prev(len);
    bool uniformPrev = true;
    CRGB firstColor = leds[f][start];
    
    for (int i = 0; i < len; i++) {
      prev[i] = leds[f][start + i];
      if (leds[f][start + i] != firstColor) uniformPrev = false;
    }
    
    if (uniformPrev && firstColor == blinkColor) {
      blinkColor = CRGB::White;
      Serial.println("[ESP32 DEBUG] Sessão já estava na cor, piscando BRANCO");
    }
    
    Serial.println("[ESP32 DEBUG] Iniciando piscada (5 vezes)");
    for (int b = 0; b < 5; b++) {
      Serial.println("[ESP32 DEBUG] Piscada " + String(b+1) + "/5");
      
    // Acende
      for (int i = 0; i < len; i++) {
        leds[f][start + i] = blinkColor;
    }
    FastLED.show();
    delay(300);
    
      // Restaura
      for (int i = 0; i < len; i++) {
        leds[f][start + i] = prev[i];
    }
    FastLED.show();
    delay(300);
    }
    
    Serial.println("[ESP32 DEBUG] Piscada concluída");
    sendResponse("FX" + String(f+1) + "S" + String(sec+1) + " piscou em " + cor, c);
    
  } else if (command == "status") {
    Serial.println("[ESP32 DEBUG] Executando: STATUS");
    String status = "Status: Modo=" + String(systemMode == NORMAL ? "NORMAL" : systemMode == DEMO ? "DEMO" : "EMERGENCY");
    status += ", WiFi=" + String(WiFi.status() == WL_CONNECTED ? "CONECTADO" : "DESCONECTADO");
    status += ", IP=" + WiFi.localIP().toString();
    Serial.println("[ESP32 DEBUG] " + status);
    sendResponse(status, c);
    
  } else if (command == "sensors") {
    Serial.println("[ESP32 DEBUG] Executando: SENSORS");
    String sensorData = "Sensores: ";
    for (int i = 0; i < 12; i++) {
      sensorData += "S" + String(i+1) + "=" + String(sensorValues[i]);
      if (i < 11) sensorData += ", ";
    }
    Serial.println("[ESP32 DEBUG] " + sensorData);
    sendResponse(sensorData, c);
    
  } else if (command == "help") {
    Serial.println("[ESP32 DEBUG] Executando: HELP");
    String help = "Comandos disponíveis:\n";
    help += "- demo: Liga modo demo\n";
    help += "- demo off: Desliga modo demo\n";
    help += "- tecaon: Animação TECA ON\n";
    help += "- tecaoff: Animação TECA OFF\n";
    help += "- allled <cor>: Todas as fitas na cor\n";
    help += "- fx<fita><sessao> <cor>: Pisca sessão\n";
    help += "- status: Status do sistema\n";
    help += "- sensors: Valores dos sensores\n";
    help += "- help: Esta ajuda\n";
    help += "Cores: vermelho, verde, azul, amarelo, branco, preto, etc.";
    Serial.println("[ESP32 DEBUG] " + help);
    sendResponse(help, c);
    
  } else {
    Serial.println("[ESP32 DEBUG] ERRO: Comando não reconhecido: '" + command + "'");
    Serial.println("[ESP32 DEBUG] Digite 'help' para ver comandos disponíveis");
    sendResponse("Comando não reconhecido: " + command + " (digite 'help')", c);
  }
  
  Serial.println("[ESP32 DEBUG] ==========================================");
}

// Página /luz
void handleLight() {
  String html = "<html><body><h2>Controle LED</h2><form method='POST' action='/luz'>";
  html += "<button name='cmd' value='demo'>Demo</button> ";
  html += "<button name='cmd' value='demo off'>Demo Off</button><br>";
  html += "<button name='cmd' value='tecaon'>Teca ON</button> ";
  html += "<button name='cmd' value='tecaoff'>Teca OFF</button><br><h3>ALL LED</h3>";
  const char* cores[] = {"vermelho","verde","azul","amarelo","branco","preto"};
  for (auto&s: cores) html += "<button name='cmd' value='allled " + String(s) + "'>" + String(s) + "</button> ";
  html += "<h3>FX</h3>";
  for (int f = 1; f <= NUM_STRIPS; f++) {
    for (int s = 1; s <= sessionsCount[f-1]; s++)
      html += "<button name='cmd' value='fx" + String(f) + "s" + String(s) + " vermelho'>FX" + String(f) + "S" + String(s) + "</button> ";
    html += "<br>";
  }
  html += "</form></body></html>";
  httpServer.send(200, "text/html", html);
  if (httpServer.hasArg("cmd")) processCommand(httpServer.arg("cmd"), nullptr);
}

// Página /sensores
void handleSensors() {
  String html = "<html><body><h2>Sensores</h2><ul>";
  for (int i = 0; i < 12; i++) html += "<li>Sensor" + String(i+1) + ": " + String(sensorValues[i]) + "</li>";
  html += "</ul><script>setTimeout(()=>location.reload(),2000)</script></body></html>";
  httpServer.send(200, "text/html", html);
}

void setup() {
  Serial.begin(115200);
  Serial.println("[ESP32 DEBUG] ==========================================");
  Serial.println("[ESP32 DEBUG] Iniciando ESP32 LED Control System...");
  Serial.println("[ESP32 DEBUG] ==========================================");
  
  Serial.println("[ESP32 DEBUG] Configurando WiFi...");
  WiFi.config(local_IP, gateway, subnet);
  WiFi.begin(ssid, password);
  
  Serial.print("[ESP32 DEBUG] Conectando ao WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println();
  Serial.println("[ESP32 DEBUG] WiFi conectado com sucesso!");
  Serial.print("[ESP32 DEBUG] IP Local: ");
  Serial.println(WiFi.localIP());
  
  Serial.println("[ESP32 DEBUG] Configurando servidores...");
  httpServer.on("/luz", HTTP_GET, handleLight);
  httpServer.on("/luz", HTTP_POST, handleLight);
  httpServer.on("/sensores", HTTP_GET, handleSensors);
  httpServer.begin(); 
  tcpServer.begin();
  Serial.println("[ESP32 DEBUG] Servidor HTTP: http://" + WiFi.localIP().toString());
  Serial.println("[ESP32 DEBUG] Servidor TCP: " + WiFi.localIP().toString() + ":1234");
  
  Serial.println("[ESP32 DEBUG] Configurando pinos do multiplexador...");
  pinMode(MUX_SIG_PIN, INPUT);
  pinMode(MUX_S0, OUTPUT);
  pinMode(MUX_S1, OUTPUT);
  pinMode(MUX_S2, OUTPUT);
  pinMode(MUX_S3, OUTPUT);
  
  Serial.println("[ESP32 DEBUG] Configurando fitas de LED...");
  FastLED.addLeds<WS2812B, PIN_STRIP1, GRB>(leds[0], LEDS_PER_STRIP);
  FastLED.addLeds<WS2812B, PIN_STRIP2, GRB>(leds[1], LEDS_PER_STRIP);
  FastLED.addLeds<WS2812B, PIN_STRIP3, GRB>(leds[2], LEDS_PER_STRIP);
  FastLED.addLeds<WS2812B, PIN_STRIP4, GRB>(leds[3], LEDS_PER_STRIP);
  FastLED.addLeds<WS2812B, PIN_STRIP5, GRB>(leds[4], LEDS_PER_STRIP);
  FastLED.addLeds<WS2812B, PIN_STRIP6, GRB>(ledsExtra, LEDS_STRIP6);
  
  Serial.println("[ESP32 DEBUG] Limpando LEDs...");
  FastLED.clear();
  FastLED.show();
  
  Serial.println("[ESP32 DEBUG] ==========================================");
  Serial.println("[ESP32 DEBUG] Sistema inicializado com sucesso!");
  Serial.println("[ESP32 DEBUG] Aguardando comandos via Serial/TCP/HTTP...");
  Serial.println("[ESP32 DEBUG] Digite 'help' para ver comandos disponíveis");
  Serial.println("[ESP32 DEBUG] ==========================================");
}

void loop() {
  // Atende clientes HTTP
  httpServer.handleClient();
  
  // Atende clientes TCP
  WiFiClient c = tcpServer.available();
  if (c) { 
    Serial.println("[ESP32 DEBUG] Cliente TCP conectado!");
    String l = c.readStringUntil('\n'); 
    l.trim(); 
    if (l.length()) {
      Serial.println("[ESP32 DEBUG] Comando TCP recebido: '" + l + "'");
      processCommand(l, &c); 
    }
    c.stop();
    Serial.println("[ESP32 DEBUG] Cliente TCP desconectado");
  }
  
  // Atende comandos via Serial
  if (Serial.available()) {
    String serialCommand = Serial.readStringUntil('\n');
    serialCommand.trim();
    if (serialCommand.length() > 0) {
      Serial.println("[ESP32 DEBUG] Comando Serial recebido: '" + serialCommand + "'");
      processCommand(serialCommand, nullptr);
    }
  }
  
  // Lê sensores
  readSensors();
  
  // Apenas checa fumaça em modo NORMAL
  if (systemMode == NORMAL) {
    checkSmoke();
  }
  
  // Executa animações baseadas no modo atual
  switch (systemMode) {
    case NORMAL:
      // Modo normal - sem animações
      break;
      
    case DEMO:
      animacaoDemo(); 
      break;
      
    case EMERGENCY:
      // Animação de emergência (pisca vermelho)
      for (int s = 0; s < NUM_STRIPS; s++) {
        for (int i = 0; i < LEDS_PER_STRIP; i++) {
          leds[s][i] = CRGB::Red;
        }
      }
      FastLED.show(); 
      delay(300);
      FastLED.clear(); 
      FastLED.show(); 
      delay(300);
      break;
  }
  
  // Pequeno delay para estabilidade
  delay(10);
}
