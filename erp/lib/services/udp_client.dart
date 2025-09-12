import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// Cliente UDP para comunicação com ESP32
class UdpClient {
  RawDatagramSocket? _socket;
  StreamController<String> _messageController = StreamController<String>.broadcast();
  Timer? _pingTimer;
  String? _lastPingId;
  int _consecutiveFailures = 0;
  
  // Configurações
  static const int DEFAULT_PORT = 42100;
  static const int MAX_MESSAGE_SIZE = 512;
  static const Duration PING_INTERVAL = Duration(seconds: 2);
  static const int MAX_FAILURES = 3;
  
  /// Stream de mensagens recebidas
  Stream<String> get onMessage => _messageController.stream;
  
  /// Verifica se o cliente está conectado
  bool get isConnected => _socket != null && _consecutiveFailures < MAX_FAILURES;
  
  /// Número de falhas consecutivas
  int get consecutiveFailures => _consecutiveFailures;
  
  /// Inicializa o cliente UDP
  Future<void> bind({required int port}) async {
    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
      _socket!.listen(_onDataReceived);
      debugPrint('UDP Client: Conectado na porta $port');
    } catch (e) {
      debugPrint('UDP Client: Erro ao conectar na porta $port: $e');
      rethrow;
    }
  }
  
  /// Envia uma mensagem para o ESP32
  Future<void> send(String host, int port, String message) async {
    if (_socket == null) {
      throw Exception('Socket não inicializado. Chame bind() primeiro.');
    }
    
    if (message.length > MAX_MESSAGE_SIZE) {
      throw Exception('Mensagem muito grande (máximo $MAX_MESSAGE_SIZE bytes)');
    }
    
    try {
      final data = Uint8List.fromList(utf8.encode(message));
      final address = InternetAddress(host);
      _socket!.send(data, address, port);
      debugPrint('UDP Client: Enviado para $host:$port - $message');
    } catch (e) {
      debugPrint('UDP Client: Erro ao enviar mensagem: $e');
      rethrow;
    }
  }
  
  /// Envia ping para verificar conectividade
  Future<void> sendPing(String host, int port) async {
    final pingId = DateTime.now().millisecondsSinceEpoch.toString();
    _lastPingId = pingId;
    
    final pingMessage = jsonEncode({
      'type': 'ping',
      'id': pingId,
    });
    
    await send(host, port, pingMessage);
  }
  
  /// Envia comando para o ESP32
  Future<void> sendCommand(String host, int port, Map<String, dynamic> command) async {
    final message = jsonEncode(command);
    await send(host, port, message);
  }
  
  /// Inicia loop de ping automático
  void startPingLoop(String host, int port) {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(PING_INTERVAL, (timer) async {
      try {
        await sendPing(host, port);
      } catch (e) {
        debugPrint('UDP Client: Erro no ping automático: $e');
        _consecutiveFailures++;
      }
    });
  }
  
  /// Para o loop de ping
  void stopPingLoop() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }
  
  /// Descoberta de ESP32 via broadcast
  Future<String?> discoverEsp32({int timeoutSeconds = 5}) async {
    try {
      // Envia ping broadcast
      final pingId = DateTime.now().millisecondsSinceEpoch.toString();
      final pingMessage = jsonEncode({
        'type': 'ping',
        'id': pingId,
      });
      
      final data = Uint8List.fromList(utf8.encode(pingMessage));
      final broadcastAddress = InternetAddress('255.255.255.255');
      
      _socket?.send(data, broadcastAddress, DEFAULT_PORT);
      debugPrint('UDP Client: Enviado ping de descoberta');
      
      // Aguarda resposta
      final completer = Completer<String?>();
      StreamSubscription<String>? subscription;
      
      subscription = onMessage.listen((message) {
        try {
          final data = jsonDecode(message);
          if (data['type'] == 'ack' && 
              data['id'] == pingId && 
              data['ok'] == true) {
            subscription?.cancel();
            completer.complete(data['esp_ip'] ?? '192.168.4.1');
          }
        } catch (e) {
          // Ignora mensagens inválidas
        }
      });
      
      // Timeout
      Timer(Duration(seconds: timeoutSeconds), () {
        subscription?.cancel();
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      });
      
      return await completer.future;
    } catch (e) {
      debugPrint('UDP Client: Erro na descoberta: $e');
      return null;
    }
  }
  
  /// Processa dados recebidos
  void _onDataReceived(RawSocketEvent event) {
    if (event == RawSocketEvent.read) {
      final datagram = _socket!.receive();
      if (datagram != null) {
        final message = String.fromCharCodes(datagram.data);
        debugPrint('UDP Client: Recebido de ${datagram.address.address}:${datagram.port} - $message');
        
        try {
          final data = jsonDecode(message);
          
          // Processa ACK de ping
          if (data['type'] == 'ack' && data['id'] == _lastPingId) {
            if (data['ok'] == true) {
              _consecutiveFailures = 0;
              debugPrint('UDP Client: Ping ACK recebido');
            } else {
              _consecutiveFailures++;
              debugPrint('UDP Client: Ping ACK com erro: ${data['msg']}');
            }
          }
          
          _messageController.add(message);
        } catch (e) {
          debugPrint('UDP Client: Erro ao processar mensagem: $e');
        }
      }
    }
  }
  
  /// Fecha a conexão
  void close() {
    _pingTimer?.cancel();
    _socket?.close();
    _socket = null;
    _messageController.close();
    debugPrint('UDP Client: Conexão fechada');
  }
}
