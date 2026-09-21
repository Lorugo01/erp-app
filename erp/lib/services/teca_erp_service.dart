import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/armarios_local_config.dart';
import '../config/teca_erp_config.dart';
import '../services/armarios_local_service.dart';
import '../utils/user_friendly_error.dart';

/// Alocação de um item em armário + slot (fita/sessão).
class TecaAlocacao {
  final String armario;
  final int? fita;
  final int? sessao;
  final String? alocadoEm;

  const TecaAlocacao({
    required this.armario,
    this.fita,
    this.sessao,
    this.alocadoEm,
  });

  bool get temSlot => fita != null && sessao != null;

  String get label {
    if (!temSlot) return 'Armário $armario (sem slot)';
    return 'Armário $armario · Fita $fita · Sessão $sessao';
  }

  /// Posição no formato do firmware local: f{fita}s{sessao}
  String? get posicaoFirmware {
    if (!temSlot) return null;
    return 'f${fita}s$sessao';
  }

  factory TecaAlocacao.fromJson(Map<String, dynamic> json) {
    return TecaAlocacao(
      armario: (json['armario'] ?? '').toString().toUpperCase(),
      fita: json['fita'] is int
          ? json['fita'] as int
          : int.tryParse('${json['fita'] ?? ''}'),
      sessao: json['sessao'] is int
          ? json['sessao'] as int
          : int.tryParse('${json['sessao'] ?? ''}'),
      alocadoEm: json['alocado_em']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'armario': armario};
    if (fita != null) map['fita'] = fita;
    if (sessao != null) map['sessao'] = sessao;
    return map;
  }
}

class TecaItem {
  final int id;
  final String? codigo;
  final String nome;
  final String? descricao;
  final String? categoria;
  final String status;
  final String? criadoEm;
  final String? atualizadoEm;
  final TecaAlocacao? alocacao;

  const TecaItem({
    required this.id,
    this.codigo,
    required this.nome,
    this.descricao,
    this.categoria,
    required this.status,
    this.criadoEm,
    this.atualizadoEm,
    this.alocacao,
  });

  bool get temLocal => alocacao != null;

  String get statusLabel {
    switch (status) {
      case 'locado':
        return 'Locado';
      case 'manutencao':
        return 'Manutenção';
      default:
        return 'Disponível';
    }
  }

  factory TecaItem.fromJson(Map<String, dynamic> json) {
    TecaAlocacao? aloc;
    final raw = json['alocacao'];
    if (raw is Map) {
      aloc = TecaAlocacao.fromJson(Map<String, dynamic>.from(raw));
    }
    return TecaItem(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse('${json['id']}'),
      codigo: json['codigo']?.toString(),
      nome: json['nome']?.toString() ?? '',
      descricao: json['descricao']?.toString(),
      categoria: json['categoria']?.toString(),
      status: json['status']?.toString() ?? 'disponivel',
      criadoEm: json['criado_em']?.toString(),
      atualizadoEm: json['atualizado_em']?.toString(),
      alocacao: aloc,
    );
  }
}

class TecaArmarioResumo {
  final String letra;
  final int totalItens;

  const TecaArmarioResumo({required this.letra, required this.totalItens});

  factory TecaArmarioResumo.fromJson(Map<String, dynamic> json) {
    return TecaArmarioResumo(
      letra: (json['letra'] ?? '').toString().toUpperCase(),
      totalItens: json['total_itens'] is int
          ? json['total_itens'] as int
          : int.tryParse('${json['total_itens'] ?? 0}') ?? 0,
    );
  }
}

class TecaErpResult<T> {
  final bool success;
  final T? data;
  final String? error;
  final int? statusCode;

  const TecaErpResult({
    required this.success,
    this.data,
    this.error,
    this.statusCode,
  });
}

/// Cliente da API de locação Teca (`/erp/itens`, `/erp/armarios`, …).
class TecaErpService {
  TecaErpService._();

  static Duration get _timeout =>
      Duration(seconds: TecaErpConfig.requestTimeout);

  static String _detailFromBody(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final detail = decoded['detail'] ?? decoded['error'] ?? decoded['message'];
        if (detail != null) return detail.toString();
      }
    } catch (_) {}
    if (body.trim().isEmpty) return 'Erro na API Teca';
    return body.length > 160 ? '${body.substring(0, 160)}…' : body;
  }

  static Future<TecaErpResult<bool>> checkConnection() async {
    try {
      final res = await http
          .get(Uri.parse(TecaErpConfig.armariosUrl()), headers: TecaErpConfig.headers)
          .timeout(_timeout);
      return TecaErpResult(
        success: res.statusCode >= 200 && res.statusCode < 300,
        data: res.statusCode >= 200 && res.statusCode < 300,
        statusCode: res.statusCode,
        error: res.statusCode >= 200 && res.statusCode < 300
            ? null
            : _detailFromBody(res.body),
      );
    } catch (e) {
      return TecaErpResult(success: false, data: false, error: userErrorMessage(e));
    }
  }

  static Future<TecaErpResult<List<TecaItem>>> listItens({
    String? q,
    String? categoria,
    String? status,
    String? armario,
  }) async {
    try {
      final params = <String, String>{};
      if (q != null && q.trim().isNotEmpty) params['q'] = q.trim();
      if (categoria != null && categoria.isNotEmpty) {
        params['categoria'] = categoria;
      }
      if (status != null && status.isNotEmpty) params['status'] = status;
      if (armario != null && armario.isNotEmpty) {
        params['armario'] = armario.toUpperCase();
      }
      final query = params.entries
          .map((e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
          .join('&');

      final res = await http
          .get(Uri.parse(TecaErpConfig.itensUrl(query)), headers: TecaErpConfig.headers)
          .timeout(_timeout);

      if (res.statusCode != 200) {
        return TecaErpResult(
          success: false,
          error: _detailFromBody(res.body),
          statusCode: res.statusCode,
        );
      }

      final decoded = jsonDecode(res.body);
      final list = <TecaItem>[];
      if (decoded is List) {
        for (final e in decoded) {
          if (e is Map) {
            list.add(TecaItem.fromJson(Map<String, dynamic>.from(e)));
          }
        }
      } else if (decoded is Map && decoded['items'] is List) {
        for (final e in decoded['items'] as List) {
          if (e is Map) {
            list.add(TecaItem.fromJson(Map<String, dynamic>.from(e)));
          }
        }
      }
      return TecaErpResult(success: true, data: list, statusCode: 200);
    } catch (e) {
      return TecaErpResult(success: false, error: userErrorMessage(e));
    }
  }

  static Future<TecaErpResult<TecaItem>> getItem(int id) async {
    try {
      final res = await http
          .get(Uri.parse(TecaErpConfig.itemUrl(id)), headers: TecaErpConfig.headers)
          .timeout(_timeout);
      if (res.statusCode == 404) {
        return const TecaErpResult(success: false, error: 'Item não encontrado', statusCode: 404);
      }
      if (res.statusCode != 200) {
        return TecaErpResult(
          success: false,
          error: _detailFromBody(res.body),
          statusCode: res.statusCode,
        );
      }
      final map = Map<String, dynamic>.from(jsonDecode(res.body) as Map);
      return TecaErpResult(success: true, data: TecaItem.fromJson(map));
    } catch (e) {
      return TecaErpResult(success: false, error: userErrorMessage(e));
    }
  }

  static Future<TecaErpResult<TecaItem>> createItem({
    required String nome,
    String? codigo,
    String? descricao,
    String? categoria,
  }) async {
    try {
      final body = <String, dynamic>{'nome': nome.trim()};
      if (codigo != null && codigo.trim().isNotEmpty) {
        body['codigo'] = codigo.trim();
      }
      if (descricao != null && descricao.trim().isNotEmpty) {
        body['descricao'] = descricao.trim();
      }
      if (categoria != null && categoria.trim().isNotEmpty) {
        body['categoria'] = categoria.trim();
      }

      final res = await http
          .post(
            Uri.parse(TecaErpConfig.itensUrl()),
            headers: TecaErpConfig.headers,
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (res.statusCode != 201 && res.statusCode != 200) {
        return TecaErpResult(
          success: false,
          error: _detailFromBody(res.body),
          statusCode: res.statusCode,
        );
      }
      final map = Map<String, dynamic>.from(jsonDecode(res.body) as Map);
      return TecaErpResult(
        success: true,
        data: TecaItem.fromJson(map),
        statusCode: res.statusCode,
      );
    } catch (e) {
      return TecaErpResult(success: false, error: userErrorMessage(e));
    }
  }

  static Future<TecaErpResult<TecaItem>> updateItem({
    required int id,
    String? nome,
    String? codigo,
    String? descricao,
    String? categoria,
    String? status,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (nome != null) body['nome'] = nome.trim();
      if (codigo != null) body['codigo'] = codigo.trim().isEmpty ? null : codigo.trim();
      if (descricao != null) {
        body['descricao'] =
            descricao.trim().isEmpty ? null : descricao.trim();
      }
      if (categoria != null) {
        body['categoria'] =
            categoria.trim().isEmpty ? null : categoria.trim();
      }
      if (status != null) body['status'] = status;

      final res = await http
          .patch(
            Uri.parse(TecaErpConfig.itemUrl(id)),
            headers: TecaErpConfig.headers,
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (res.statusCode != 200) {
        return TecaErpResult(
          success: false,
          error: _detailFromBody(res.body),
          statusCode: res.statusCode,
        );
      }
      final map = Map<String, dynamic>.from(jsonDecode(res.body) as Map);
      return TecaErpResult(success: true, data: TecaItem.fromJson(map));
    } catch (e) {
      return TecaErpResult(success: false, error: userErrorMessage(e));
    }
  }

  static Future<TecaErpResult<void>> deleteItem(int id) async {
    try {
      final res = await http
          .delete(Uri.parse(TecaErpConfig.itemUrl(id)), headers: TecaErpConfig.headers)
          .timeout(_timeout);
      if (res.statusCode == 204 || res.statusCode == 200) {
        return const TecaErpResult(success: true);
      }
      return TecaErpResult(
        success: false,
        error: _detailFromBody(res.body),
        statusCode: res.statusCode,
      );
    } catch (e) {
      return TecaErpResult(success: false, error: userErrorMessage(e));
    }
  }

  static Future<TecaErpResult<TecaItem>> setAlocacao({
    required int id,
    required String armario,
    int? fita,
    int? sessao,
  }) async {
    try {
      final body = <String, dynamic>{'armario': armario.toUpperCase()};
      if (fita != null && sessao != null) {
        body['fita'] = fita;
        body['sessao'] = sessao;
      }

      final res = await http
          .put(
            Uri.parse(TecaErpConfig.alocacaoUrl(id)),
            headers: TecaErpConfig.headers,
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (res.statusCode != 200) {
        return TecaErpResult(
          success: false,
          error: _detailFromBody(res.body),
          statusCode: res.statusCode,
        );
      }
      final map = Map<String, dynamic>.from(jsonDecode(res.body) as Map);
      return TecaErpResult(success: true, data: TecaItem.fromJson(map));
    } catch (e) {
      return TecaErpResult(success: false, error: userErrorMessage(e));
    }
  }

  static Future<TecaErpResult<TecaItem>> clearAlocacao(int id) async {
    try {
      final res = await http
          .delete(
            Uri.parse(TecaErpConfig.alocacaoUrl(id)),
            headers: TecaErpConfig.headers,
          )
          .timeout(_timeout);
      if (res.statusCode != 200) {
        return TecaErpResult(
          success: false,
          error: _detailFromBody(res.body),
          statusCode: res.statusCode,
        );
      }
      final map = Map<String, dynamic>.from(jsonDecode(res.body) as Map);
      return TecaErpResult(success: true, data: TecaItem.fromJson(map));
    } catch (e) {
      return TecaErpResult(success: false, error: userErrorMessage(e));
    }
  }

  static Future<TecaErpResult<List<TecaArmarioResumo>>> listArmarios() async {
    try {
      final res = await http
          .get(Uri.parse(TecaErpConfig.armariosUrl()), headers: TecaErpConfig.headers)
          .timeout(_timeout);
      if (res.statusCode != 200) {
        return TecaErpResult(
          success: false,
          error: _detailFromBody(res.body),
          statusCode: res.statusCode,
        );
      }
      final decoded = jsonDecode(res.body);
      final list = <TecaArmarioResumo>[];
      if (decoded is List) {
        for (final e in decoded) {
          if (e is Map) {
            list.add(TecaArmarioResumo.fromJson(Map<String, dynamic>.from(e)));
          }
        }
      }
      return TecaErpResult(success: true, data: list);
    } catch (e) {
      return TecaErpResult(success: false, error: userErrorMessage(e));
    }
  }

  static Future<TecaErpResult<TecaItem>> localizarPorNome(String nome) async {
    try {
      final res = await http
          .get(
            Uri.parse(TecaErpConfig.localizarUrl(nome)),
            headers: TecaErpConfig.headers,
          )
          .timeout(_timeout);
      if (res.statusCode == 404) {
        return const TecaErpResult(
          success: false,
          error: 'Item não encontrado',
          statusCode: 404,
        );
      }
      if (res.statusCode != 200) {
        return TecaErpResult(
          success: false,
          error: _detailFromBody(res.body),
          statusCode: res.statusCode,
        );
      }
      final map = Map<String, dynamic>.from(jsonDecode(res.body) as Map);
      return TecaErpResult(success: true, data: TecaItem.fromJson(map));
    } catch (e) {
      return TecaErpResult(success: false, error: userErrorMessage(e));
    }
  }

  /// Localiza no LED do ESP (rede local) usando a alocação da API.
  static Future<String> localizeOnEsp(TecaItem item) async {
    final aloc = item.alocacao;
    if (aloc == null) return 'Item sem alocação';
    if (!aloc.temSlot) {
      return 'Item no armário ${aloc.armario}, sem fita/sessão para LED';
    }

    await ArmariosLocalService.discover();
    final online = ArmariosLocalService.lastDiscovery[aloc.armario];
    final def = ArmariosLocalConfig.byId(aloc.armario);
    final ip = online?.ip ?? def?.expectedIp;
    if (ip == null || ip.isEmpty) {
      return 'IP do armário ${aloc.armario} desconhecido';
    }
    if (online != null && !online.online) {
      // Tenta mesmo assim (IP esperado)
    }

    final r = await ArmariosLocalService.locateSlot(
      ip: ip,
      fita: aloc.fita!,
      espaco: aloc.sessao!,
    );
    return r.success
        ? 'LED no Armário ${aloc.armario} · Fita ${aloc.fita} · Sessão ${aloc.sessao}'
        : r.message;
  }
}
