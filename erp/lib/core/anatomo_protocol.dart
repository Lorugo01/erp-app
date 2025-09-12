import 'dart:convert';

/// Modelos de protocolo para comunicação UDP com ESP32
class Protocol {
  /// Comando para enviar ao ESP32
  static Map<String, dynamic> createCommand({
    required String target,
    required String action,
    Map<String, dynamic>? params,
  }) {
    return {
      'type': 'cmd',
      'target': target,
      'action': action,
      'params': params ?? {},
    };
  }
  
  /// Ping para verificar conectividade
  static Map<String, dynamic> createPing({required String id}) {
    return {
      'type': 'ping',
      'id': id,
    };
  }
  
  /// ACK de resposta do ESP32
  static Map<String, dynamic> createAck({
    required bool ok,
    required String id,
    String? msg,
    String? espIp,
  }) {
    return {
      'type': 'ack',
      'ok': ok,
      'id': id,
      'msg': msg ?? '',
      'esp_ip': espIp,
    };
  }
  
  /// Telemetria do ESP32
  static Map<String, dynamic> createTelemetry({
    required String sensor,
    required dynamic value,
    String? unit,
  }) {
    return {
      'type': 'telemetry',
      'sensor': sensor,
      'value': value,
      'unit': unit ?? '',
    };
  }
}

/// Modelo de comando
class Command {
  final String type;
  final String target;
  final String action;
  final Map<String, dynamic> params;
  
  Command({
    required this.type,
    required this.target,
    required this.action,
    required this.params,
  });
  
  factory Command.fromJson(Map<String, dynamic> json) {
    return Command(
      type: json['type'] ?? '',
      target: json['target'] ?? '',
      action: json['action'] ?? '',
      params: Map<String, dynamic>.from(json['params'] ?? {}),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'target': target,
      'action': action,
      'params': params,
    };
  }
  
  String toJsonString() => jsonEncode(toJson());
}

/// Modelo de ACK
class Ack {
  final String type;
  final bool ok;
  final String id;
  final String msg;
  final String? espIp;
  
  Ack({
    required this.type,
    required this.ok,
    required this.id,
    required this.msg,
    this.espIp,
  });
  
  factory Ack.fromJson(Map<String, dynamic> json) {
    return Ack(
      type: json['type'] ?? '',
      ok: json['ok'] ?? false,
      id: json['id'] ?? '',
      msg: json['msg'] ?? '',
      espIp: json['esp_ip'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'ok': ok,
      'id': id,
      'msg': msg,
      if (espIp != null) 'esp_ip': espIp,
    };
  }
  
  String toJsonString() => jsonEncode(toJson());
}

/// Modelo de Ping
class Ping {
  final String type;
  final String id;
  
  Ping({
    required this.type,
    required this.id,
  });
  
  factory Ping.fromJson(Map<String, dynamic> json) {
    return Ping(
      type: json['type'] ?? '',
      id: json['id'] ?? '',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'id': id,
    };
  }
  
  String toJsonString() => jsonEncode(toJson());
}

/// Modelo de Telemetria
class Telemetry {
  final String type;
  final String sensor;
  final dynamic value;
  final String unit;
  
  Telemetry({
    required this.type,
    required this.sensor,
    required this.value,
    required this.unit,
  });
  
  factory Telemetry.fromJson(Map<String, dynamic> json) {
    return Telemetry(
      type: json['type'] ?? '',
      sensor: json['sensor'] ?? '',
      value: json['value'],
      unit: json['unit'] ?? '',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'sensor': sensor,
      'value': value,
      'unit': unit,
    };
  }
  
  String toJsonString() => jsonEncode(toJson());
}

/// Enum para partes do corpo anatômico
enum AnatomicalPart {
  cabeca('Cabeça', 'cabeca'),
  bracoDireito('Braço Direito', 'braco_direito'),
  bracoEsquerdo('Braço Esquerdo', 'braco_esquerdo'),
  torax('Tórax', 'torax'),
  pernaDireita('Perna Direita', 'perna_direita'),
  pernaEsquerda('Perna Esquerda', 'perna_esquerda');
  
  const AnatomicalPart(this.displayName, this.target);
  
  final String displayName;
  final String target;
}

/// Enum para ações disponíveis
enum Action {
  ledOn('Acender LED', 'led_on'),
  ledOff('Apagar LED', 'led_off'),
  servoMove('Mover Servo', 'servo_move'),
  sensorRead('Ler Sensor', 'sensor_read');
  
  const Action(this.displayName, this.action);
  
  final String displayName;
  final String action;
}

/// Enum para cores de LED
enum LedColor {
  red('Vermelho', '#FF0000'),
  green('Verde', '#00FF00'),
  blue('Azul', '#0000FF'),
  yellow('Amarelo', '#FFFF00'),
  purple('Roxo', '#800080'),
  cyan('Ciano', '#00FFFF'),
  white('Branco', '#FFFFFF'),
  orange('Laranja', '#FFA500'),
  pink('Rosa', '#FFC0CB');
  
  const LedColor(this.displayName, this.hex);
  
  final String displayName;
  final String hex;
}
