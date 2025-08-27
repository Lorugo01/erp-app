import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../config/environment.dart';

class TecaAIResponse {
  final bool success;
  final String? response;
  final String? error;
  final String timestamp;

  TecaAIResponse({
    required this.success,
    this.response,
    this.error,
    required this.timestamp,
  });

  factory TecaAIResponse.fromJson(Map<String, dynamic> json) {
    return TecaAIResponse(
      success: json['success'] ?? false,
      response: json['response'],
      error: json['error'],
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class TecaAICommandHistory {
  final int id;
  final String userId;
  final String userRole;
  final String commandType;
  final String parameter;
  final String response;
  final bool success;
  final String timestamp;

  TecaAICommandHistory({
    required this.id,
    required this.userId,
    required this.userRole,
    required this.commandType,
    required this.parameter,
    required this.response,
    required this.success,
    required this.timestamp,
  });

  factory TecaAICommandHistory.fromJson(Map<String, dynamic> json) {
    return TecaAICommandHistory(
      id: json['id'],
      userId: json['user_id'],
      userRole: json['user_role'],
      commandType: json['command_type'],
      parameter: json['parameter'],
      response: json['response'],
      success: json['success'],
      timestamp: json['timestamp'],
    );
  }
}

class TecaAIStats {
  final int totalCommands;
  final Map<String, int> commandsByType;
  final Map<String, int> commandsByUser;
  final double successRate;

  TecaAIStats({
    required this.totalCommands,
    required this.commandsByType,
    required this.commandsByUser,
    required this.successRate,
  });

  factory TecaAIStats.fromJson(Map<String, dynamic> json) {
    return TecaAIStats(
      totalCommands: json['total_commands'],
      commandsByType: Map<String, int>.from(json['commands_by_type']),
      commandsByUser: Map<String, int>.from(json['commands_by_user']),
      successRate: json['success_rate'].toDouble(),
    );
  }
}

class TecaAIItem {
  final int? id;
  final String nome;
  final String posicao;
  final String posicaoOriginal;
  final String espIp;
  final String espIpOriginal;

  TecaAIItem({
    this.id,
    required this.nome,
    required this.posicao,
    required this.posicaoOriginal,
    required this.espIp,
    required this.espIpOriginal,
  });

  factory TecaAIItem.fromJson(Map<String, dynamic> json) {
    return TecaAIItem(
      id: json['id'],
      nome: json['nome'] ?? '',
      posicao: json['posicao'] ?? '',
      posicaoOriginal: json['posicao_original'] ?? '',
      espIp: json['esp_ip'] ?? '',
      espIpOriginal: json['esp_ip_original'] ?? '',
    );
  }
}

class TecaAIService {
  // URL base da API TecaAI - agora centralizada
  static String get baseUrl => EnvironmentConfig.tecaaiBaseUrl;

  // Timeout para requisições - agora centralizado
  static Duration get requestTimeout =>
      Duration(seconds: EnvironmentConfig.tecaaiRequestTimeout);

  // Headers padrão
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
  };

  // Endpoints específicos do TecaAI
  static const String healthEndpoint = '/health';
  static const String askEndpoint = '/ask';
  static const String locateEndpoint = '/locate';
  static const String controlEndpoint = '/control';
  static const String itemInfoEndpoint = '/item-info';
  static const String historyEndpoint = '/history';
  static const String statsEndpoint = '/stats';
  static const String itemsEndpoint = '/items';

  // Métodos utilitários para construir URLs completas
  static String getHealthUrl() =>
      EnvironmentConfig.getTecaAIUrl(healthEndpoint);
  static String getAskUrl() => EnvironmentConfig.getTecaAIUrl(askEndpoint);
  static String getLocateUrl() =>
      EnvironmentConfig.getTecaAIUrl(locateEndpoint);
  static String getControlUrl() =>
      EnvironmentConfig.getTecaAIUrl(controlEndpoint);
  static String getItemInfoUrl() =>
      EnvironmentConfig.getTecaAIUrl(itemInfoEndpoint);
  static String getHistoryUrl() =>
      EnvironmentConfig.getTecaAIUrl(historyEndpoint);
  static String getStatsUrl() => EnvironmentConfig.getTecaAIUrl(statsEndpoint);
  static String getItemsUrl() => EnvironmentConfig.getTecaAIUrl(itemsEndpoint);
  static String getItemUrl(int itemId) =>
      EnvironmentConfig.getTecaAIUrl('$itemsEndpoint/$itemId');

  // Comandos pré-definidos para facilitar o uso
  static const Map<String, String> predefinedCommands = {
    'ligar_luz': 'ligue a luz',
    'desligar_luz': 'desligue a luz',
    'modo_festa_on': 'ligue modo festa',
    'modo_festa_off': 'desligue modo festa',
    'alarme_fumaca': 'os alarmes de fumaça foram acionados',
  };

  /// Verifica se a API TecaAI está online
  static Future<bool> checkConnection() async {
    try {
      final response = await http
          .get(Uri.parse(getHealthUrl()), headers: defaultHeaders)
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Faz uma pergunta para a IA
  static Future<TecaAIResponse> askQuestion({
    required String question,
    required User user,
    String voice = 'Teca',
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(getAskUrl()),
            headers: defaultHeaders,
            body: jsonEncode({
              'question': question,
              'voice': voice,
              'user_id': user.id,
              'user_role': user.role.toString().split('.').last,
            }),
          )
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return TecaAIResponse.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        return TecaAIResponse(
          success: false,
          error: error['error'] ?? 'Erro na comunicação com TecaAI',
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      return TecaAIResponse(
        success: false,
        error: 'Erro de conexão: $e',
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  /// Localiza um item no laboratório
  static Future<TecaAIResponse> locateItem({
    required String item,
    required User user,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(getLocateUrl()),
            headers: defaultHeaders,
            body: jsonEncode({
              'item': item,
              'user_id': user.id,
              'user_role': user.role.toString().split('.').last,
            }),
          )
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return TecaAIResponse.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        return TecaAIResponse(
          success: false,
          error: error['error'] ?? 'Erro ao localizar item',
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      return TecaAIResponse(
        success: false,
        error: 'Erro de conexão: $e',
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  /// Controla dispositivos (LEDs, etc.)
  static Future<TecaAIResponse> controlDevice({
    required String command,
    required User user,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(getControlUrl()),
            headers: defaultHeaders,
            body: jsonEncode({
              'command': command,
              'user_id': user.id,
              'user_role': user.role.toString().split('.').last,
            }),
          )
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return TecaAIResponse.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        return TecaAIResponse(
          success: false,
          error: error['error'] ?? 'Erro ao executar comando',
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      return TecaAIResponse(
        success: false,
        error: 'Erro de conexão: $e',
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  /// Obtém informações sobre um item
  static Future<TecaAIResponse> getItemInfo({
    required String item,
    required User user,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(getItemInfoUrl()),
            headers: defaultHeaders,
            body: jsonEncode({
              'item': item,
              'user_id': user.id,
              'user_role': user.role.toString().split('.').last,
            }),
          )
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return TecaAIResponse.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        return TecaAIResponse(
          success: false,
          error: error['error'] ?? 'Erro ao obter informações do item',
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      return TecaAIResponse(
        success: false,
        error: 'Erro de conexão: $e',
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  /// Obtém histórico de comandos
  static Future<List<TecaAICommandHistory>> getCommandHistory({
    String? userId,
    int limit = 50,
  }) async {
    try {
      final uri = Uri.parse(getHistoryUrl()).replace(
        queryParameters: {
          if (userId != null) 'user_id': userId,
          'limit': limit.toString(),
        },
      );

      final response = await http
          .get(uri, headers: defaultHeaders)
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> historyList = data['history'];
          return historyList
              .map((item) => TecaAICommandHistory.fromJson(item))
              .toList();
        }
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  /// Obtém estatísticas de uso
  static Future<TecaAIStats?> getStats() async {
    try {
      final response = await http
          .get(Uri.parse(getStatsUrl()), headers: defaultHeaders)
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return TecaAIStats.fromJson(data['stats']);
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Obtém todos os itens disponíveis para localização
  static Future<List<TecaAIItem>> getAllItems() async {
    try {
      final response = await http
          .get(Uri.parse(getItemsUrl()), headers: defaultHeaders)
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> itemsList = data['items'];
          return itemsList.map((item) => TecaAIItem.fromJson(item)).toList();
        }
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  /// Adiciona um novo item
  static Future<TecaAIResponse> addItem({
    required String nome,
    required String posicao,
    required String espIp,
    required User user,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(getItemsUrl()),
            headers: defaultHeaders,
            body: jsonEncode({
              'nome': nome,
              'posicao': posicao,
              'esp_ip': espIp,
              'user_id': user.id,
              'user_role': user.role.toString().split('.').last,
            }),
          )
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return TecaAIResponse.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        return TecaAIResponse(
          success: false,
          error: error['error'] ?? 'Erro ao adicionar item',
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      return TecaAIResponse(
        success: false,
        error: 'Erro de conexão: $e',
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  /// Edita um item existente
  static Future<TecaAIResponse> editItem({
    required int itemId,
    required String nome,
    required String posicao,
    required String espIp,
    required User user,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse(getItemUrl(itemId)),
            headers: defaultHeaders,
            body: jsonEncode({
              'nome': nome,
              'posicao': posicao,
              'esp_ip': espIp,
              'user_id': user.id,
              'user_role': user.role.toString().split('.').last,
            }),
          )
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return TecaAIResponse.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        return TecaAIResponse(
          success: false,
          error: error['error'] ?? 'Erro ao editar item',
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      return TecaAIResponse(
        success: false,
        error: 'Erro de conexão: $e',
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  /// Remove um item
  static Future<TecaAIResponse> deleteItem({
    required int itemId,
    required User user,
  }) async {
    try {
      final response = await http
          .delete(
            Uri.parse(getItemUrl(itemId)),
            headers: defaultHeaders,
            body: jsonEncode({
              'user_id': user.id,
              'user_role': user.role.toString().split('.').last,
            }),
          )
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return TecaAIResponse.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        return TecaAIResponse(
          success: false,
          error: error['error'] ?? 'Erro ao remover item',
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      return TecaAIResponse(
        success: false,
        error: 'Erro de conexão: $e',
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  /// Executa um comando pré-definido
  static Future<TecaAIResponse> executePredefinedCommand({
    required String commandKey,
    required User user,
  }) async {
    final command = predefinedCommands[commandKey];
    if (command == null) {
      return TecaAIResponse(
        success: false,
        error: 'Comando pré-definido não encontrado',
        timestamp: DateTime.now().toIso8601String(),
      );
    }

    return controlDevice(command: command, user: user);
  }
}
