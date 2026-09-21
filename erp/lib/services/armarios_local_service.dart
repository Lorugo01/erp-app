import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/armarios_local_config.dart';
import '../utils/user_friendly_error.dart';

/// Controle direto dos ESPs na rede local (HTTP :80 /api).
/// Inventário de itens fica no SharedPreferences (sem TecaAI online).
class ArmariosLocalService {
  ArmariosLocalService._();

  static const _itemsKey = 'armarios_local_items_v1';
  static const _ipOverridesKey = 'armarios_local_ip_overrides_v1';

  static final Map<String, ArmarioOnline> _lastDiscovery = {};

  static Map<String, ArmarioOnline> get lastDiscovery =>
      Map.unmodifiable(_lastDiscovery);

  static bool get anyOnline => _lastDiscovery.values.any((a) => a.online);

  // ─── Descoberta ───────────────────────────────────────────────────────────

  /// Varre IPs esperados (+ overrides) e identifica pelo título HTML do painel.
  static Future<List<ArmarioOnline>> discover({
    bool scanSubnetExtras = false,
  }) async {
    final overrides = await _loadIpOverrides();
    final results = <String, ArmarioOnline>{};

    // 1) IPs conhecidos do firmware + overrides salvos
    final probes = <_ProbeJob>[];
    for (final def in ArmariosLocalConfig.catalog) {
      final ip = overrides[def.id] ?? def.expectedIp;
      probes.add(_ProbeJob(preferredId: def.id, ip: ip));
    }

    // 2) Varredura leve no range 180–189 (rede BYLAB padrão)
    if (scanSubnetExtras) {
      for (var host = 180; host <= 189; host++) {
        final ip = '${ArmariosLocalConfig.defaultSubnetPrefix}$host';
        if (probes.any((p) => p.ip == ip)) continue;
        probes.add(_ProbeJob(preferredId: null, ip: ip));
      }
    }

    final futures = probes.map((job) => _probeIp(job.ip));
    final found = await Future.wait(futures);

    for (var i = 0; i < probes.length; i++) {
      final job = probes[i];
      final match = found[i];
      if (match == null) {
        if (job.preferredId != null) {
          final def = ArmariosLocalConfig.byId(job.preferredId!)!;
          results[def.id] = ArmarioOnline(
            def: def,
            ip: job.ip,
            online: false,
          );
        }
        continue;
      }

      results[match.id] = ArmarioOnline(
        def: match,
        ip: job.ip,
        online: true,
      );
      // Persiste IP real se diferente do esperado
      if (job.ip != match.expectedIp) {
        overrides[match.id] = job.ip;
      }
    }

    // Garante todos do catálogo no mapa
    for (final def in ArmariosLocalConfig.catalog) {
      results.putIfAbsent(
        def.id,
        () => ArmarioOnline(
          def: def,
          ip: overrides[def.id] ?? def.expectedIp,
          online: false,
        ),
      );
    }

    await _saveIpOverrides(overrides);
    _lastDiscovery
      ..clear()
      ..addAll(results);

    final list = results.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    return list;
  }

  static Future<ArmarioDef?> _probeIp(String ip) async {
    try {
      final uri = Uri.parse('http://$ip:${ArmariosLocalConfig.httpPort}/');
      final res = await http
          .get(uri)
          .timeout(ArmariosLocalConfig.probeTimeout);
      if (res.statusCode != 200) return null;
      return ArmariosLocalConfig.byTitleHint(res.body);
    } catch (_) {
      return null;
    }
  }

  // ─── Comandos HTTP (firmware /api?alvo=&cmd=&valor=) ──────────────────────

  static Future<ArmarioCmdResult> sendCommand({
    required String ip,
    required String alvo,
    required String cmd,
    String valor = '',
  }) async {
    try {
      final uri = Uri.http(
        '$ip:${ArmariosLocalConfig.httpPort}',
        '/api',
        {
          'alvo': alvo,
          'cmd': cmd,
          'valor': valor,
        },
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        return ArmarioCmdResult(
          success: true,
          message: 'OK $alvo,$cmd,$valor',
        );
      }
      return ArmarioCmdResult(
        success: false,
        message: 'HTTP ${res.statusCode}',
      );
    } catch (e) {
      return ArmarioCmdResult(
        success: false,
        message: userErrorMessage(e),
      );
    }
  }

  /// Localiza slot: pisca branco 5s no espaço (firmware cmd=espaco).
  static Future<ArmarioCmdResult> locateSlot({
    required String ip,
    required int fita,
    required int espaco,
  }) {
    return sendCommand(
      ip: ip,
      alvo: '$fita',
      cmd: 'espaco',
      valor: '$espaco',
    );
  }

  static Future<ArmarioCmdResult> locateItem(ArmarioItem item) async {
    final f = item.fita;
    final e = item.espaco;
    if (f == null || e == null) {
      return const ArmarioCmdResult(
        success: false,
        message: 'Posição inválida (use f{fita}s{espaco})',
      );
    }
    final online = _lastDiscovery[item.armarioId];
    final ip = online?.ip.isNotEmpty == true ? online!.ip : item.ip;
    return locateSlot(ip: ip, fita: f, espaco: e);
  }

  static Future<ArmarioCmdResult> setLuzes(String ip, bool on) {
    return sendCommand(
      ip: ip,
      alvo: 'luzes',
      cmd: on ? 'liga' : 'desliga',
      valor: on ? '1' : '0',
    );
  }

  static Future<ArmarioCmdResult> setApresentacao(String ip, bool on) {
    return sendCommand(
      ip: ip,
      alvo: 'apresentacao',
      cmd: on ? 'liga' : 'desliga',
      valor: on ? '1' : '0',
    );
  }

  static Future<ArmarioCmdResult> setEfeitoAll(String ip, String efeito) {
    return sendCommand(ip: ip, alvo: 'all', cmd: 'efeito', valor: efeito);
  }

  static Future<ArmarioCmdResult> desligarAll(String ip) {
    return sendCommand(ip: ip, alvo: 'all', cmd: 'desliga', valor: '0');
  }

  static Future<List<ArmarioCmdResult>> broadcastToOnline({
    required Future<ArmarioCmdResult> Function(ArmarioOnline a) action,
  }) async {
    final online = _lastDiscovery.values.where((a) => a.online).toList();
    if (online.isEmpty) {
      return [
        const ArmarioCmdResult(
          success: false,
          message: 'Nenhum armário online na rede local',
        ),
      ];
    }
    return Future.wait(online.map(action));
  }

  // ─── Inventário local ─────────────────────────────────────────────────────

  static Future<List<ArmarioItem>> getItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_itemsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map>()
          .map((e) => ArmarioItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('armarios items parse: $e');
      return [];
    }
  }

  static Future<void> _saveItems(List<ArmarioItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _itemsKey,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  static Future<ArmarioItem> addItem({
    required String nome,
    required String posicao,
    required String armarioId,
  }) async {
    final online = _lastDiscovery[armarioId];
    final def = ArmariosLocalConfig.byId(armarioId);
    final ip = online?.ip ?? def?.expectedIp ?? '';
    final items = await getItems();
    final id = items.isEmpty
        ? 1
        : items.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
    final item = ArmarioItem(
      id: id,
      nome: nome.trim(),
      posicao: posicao.trim().toLowerCase(),
      armarioId: armarioId,
      ip: ip,
    );
    items.add(item);
    await _saveItems(items);
    return item;
  }

  static Future<ArmarioItem?> updateItem({
    required int id,
    required String nome,
    required String posicao,
    required String armarioId,
  }) async {
    final items = await getItems();
    final idx = items.indexWhere((e) => e.id == id);
    if (idx < 0) return null;
    final online = _lastDiscovery[armarioId];
    final def = ArmariosLocalConfig.byId(armarioId);
    final updated = ArmarioItem(
      id: id,
      nome: nome.trim(),
      posicao: posicao.trim().toLowerCase(),
      armarioId: armarioId,
      ip: online?.ip ?? def?.expectedIp ?? items[idx].ip,
    );
    items[idx] = updated;
    await _saveItems(items);
    return updated;
  }

  static Future<bool> deleteItem(int id) async {
    final items = await getItems();
    final before = items.length;
    items.removeWhere((e) => e.id == id);
    if (items.length == before) return false;
    await _saveItems(items);
    return true;
  }

  // ─── Overrides de IP ──────────────────────────────────────────────────────

  static Future<Map<String, String>> _loadIpOverrides() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_ipOverridesKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {};
    }
  }

  static Future<void> _saveIpOverrides(Map<String, String> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ipOverridesKey, jsonEncode(map));
  }
}

class ArmarioCmdResult {
  final bool success;
  final String message;

  const ArmarioCmdResult({required this.success, required this.message});
}

class _ProbeJob {
  final String? preferredId;
  final String ip;
  _ProbeJob({required this.preferredId, required this.ip});
}
