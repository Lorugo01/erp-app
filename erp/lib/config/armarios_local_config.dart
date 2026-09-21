/// Catálogo dos armários Bylab (firmware ESP32-S3).
/// Geometria de espaços espelha `qtdEspacosPorFita` de cada `armario_*/effects.h`.
class ArmariosLocalConfig {
  ArmariosLocalConfig._();

  static const String defaultSubnetPrefix = '192.168.18.';
  static const int httpPort = 80;
  static const int tcpPort = 1234;
  static const Duration probeTimeout = Duration(milliseconds: 900);

  /// Armários A–F conforme firmware em Armarios Bylab.
  static const List<ArmarioDef> catalog = [
    ArmarioDef(
      id: 'A',
      name: 'Armário A',
      expectedIp: '192.168.18.180',
      titleHint: 'Armario A',
      // TECA + 4 fitas: 3 + 3 + 1 + 2 gavetas
      espacosPorFita: [0, 3, 3, 1, 2],
      fitaLabels: [
        'TECA',
        'Fita 2 (3 slots)',
        'Fita 3 (3 slots)',
        'Fita 4 (1 slot)',
        'Gavetas',
      ],
      espacoLabelOverrides: {
        '5:1': 'Gaveta 1',
        '5:2': 'Gaveta 2',
      },
    ),
    ArmarioDef(
      id: 'B',
      name: 'Armário B',
      expectedIp: '192.168.18.181',
      titleHint: 'Armario B',
      espacosPorFita: [0, 3, 5, 5, 7, 5],
      fitaLabels: [
        'TECA',
        'Fita 2 (3 slots)',
        'Fita 3 (5 slots)',
        'Fita 4 (5 slots)',
        'Fita 5 (7 módulos)',
        'Gavetas (5)',
      ],
      espacoLabelOverrides: {
        '6:1': 'Gaveta 1',
        '6:2': 'Gaveta 2',
        '6:3': 'Gaveta 3',
        '6:4': 'Gaveta 4',
        '6:5': 'Gaveta 5',
      },
    ),
    ArmarioDef(
      id: 'C',
      name: 'Armário C',
      expectedIp: '192.168.18.182',
      titleHint: 'Armario C',
      espacosPorFita: [0, 4, 3, 3, 3, 4],
      fitaLabels: [
        'TECA',
        'Fita 2 (4 espaços)',
        'Fita 3 (3 espaços)',
        'Fita 4 (3 espaços)',
        'Fita 5 química (3)',
        'Gavetas (4)',
      ],
      espacoLabelOverrides: {
        '6:1': 'Gaveta 1',
        '6:2': 'Gaveta 2',
        '6:3': 'Gaveta 3',
        '6:4': 'Gaveta 4',
      },
    ),
    ArmarioDef(
      id: 'D',
      name: 'Armário D',
      expectedIp: '192.168.18.183',
      titleHint: 'Armario D',
      espacosPorFita: [0, 4, 4, 4, 3],
      fitaLabels: [
        'TECA',
        'Fita 2 (4 slots)',
        'Fita 3 (4 slots)',
        'Fita 4 (4 slots)',
        'Fita 5 (3 slots)',
      ],
    ),
    ArmarioDef(
      id: 'E',
      name: 'Armário E',
      expectedIp: '192.168.18.184',
      titleHint: 'Armario E',
      // 5 fitas × 8 espaços (ESPACOS_POR_FITA=8)
      espacosPorFita: [0, 8, 8, 8, 8, 8],
      fitaLabels: [
        'TECA',
        'Fita 2 (8 espaços)',
        'Fita 3 (8 espaços)',
        'Fita 4 (8 espaços)',
        'Fita 5 (8 espaços)',
        'Fita 6 (8 espaços)',
      ],
    ),
    ArmarioDef(
      id: 'F',
      name: 'Armário F',
      expectedIp: '192.168.18.185',
      titleHint: 'Armario F',
      // prat1→fita2 … prat5→fita6
      espacosPorFita: [0, 8, 1, 6, 8, 8],
      fitaLabels: [
        'TECA',
        'Prateleira 1 (8)',
        'Prateleira 2 terrários (1)',
        'Prateleira 3 (6)',
        'Prateleira 4 (8)',
        'Prateleira 5 (8)',
      ],
    ),
  ];

  static ArmarioDef? byId(String id) {
    for (final a in catalog) {
      if (a.id == id) return a;
    }
    return null;
  }

  static ArmarioDef? byTitleHint(String html) {
    final lower = html.toLowerCase();
    for (final a in catalog) {
      if (lower.contains(a.titleHint.toLowerCase())) return a;
    }
    return null;
  }

  static const List<MapEntry<String, String>> efeitos = [
    MapEntry('arcoiris', 'Arco-íris'),
    MapEntry('fogo', 'Flame'),
    MapEntry('meteoro', 'Meteoro'),
    MapEntry('confete', 'Confete'),
    MapEntry('respirar', 'Respirar'),
    MapEntry('teatro', 'Teatro'),
    MapEntry('scanner', 'Scanner'),
    MapEntry('sparkle', 'Sparkle'),
    MapEntry('rainbow_chase', 'Rainbow Chase'),
    MapEntry('aurora', 'Aurora'),
    MapEntry('cometa', 'Cometa'),
    MapEntry('onda', 'Onda'),
  ];
}

/// Slot selecionável no cadastro (fita + sessão do firmware).
class ArmarioEspaco {
  final int fita;
  final int sessao;
  final String label;

  const ArmarioEspaco({
    required this.fita,
    required this.sessao,
    required this.label,
  });

  String get key => '$fita:$sessao';

  @override
  bool operator ==(Object other) =>
      other is ArmarioEspaco && other.fita == fita && other.sessao == sessao;

  @override
  int get hashCode => Object.hash(fita, sessao);
}

class ArmarioDef {
  final String id;
  final String name;
  final String expectedIp;
  final String titleHint;
  /// Índice 0 = TECA (sempre 0 espaços).
  final List<int> espacosPorFita;
  final List<String> fitaLabels;
  /// Chave `"fita:sessao"` → rótulo amigável (ex. Gaveta 1).
  final Map<String, String> espacoLabelOverrides;

  const ArmarioDef({
    required this.id,
    required this.name,
    required this.expectedIp,
    required this.titleHint,
    required this.espacosPorFita,
    this.fitaLabels = const [],
    this.espacoLabelOverrides = const {},
  });

  /// Fitas com slots (exclui TECA = índice 0).
  List<int> get fitasUteis {
    final out = <int>[];
    for (var i = 1; i < espacosPorFita.length; i++) {
      if (espacosPorFita[i] > 0) out.add(i);
    }
    return out;
  }

  int espacosDaFita(int fita) {
    if (fita < 0 || fita >= espacosPorFita.length) return 0;
    return espacosPorFita[fita];
  }

  String labelDaFita(int fita) {
    if (fita >= 0 && fita < fitaLabels.length && fitaLabels[fita].isNotEmpty) {
      return fitaLabels[fita];
    }
    return 'Fita $fita';
  }

  /// Todos os espaços selecionáveis deste armário (ordem firmware).
  List<ArmarioEspaco> get espacos {
    final list = <ArmarioEspaco>[];
    for (final f in fitasUteis) {
      final qtd = espacosDaFita(f);
      final fitaNome = labelDaFita(f);
      for (var s = 1; s <= qtd; s++) {
        final key = '$f:$s';
        final override = espacoLabelOverrides[key];
        list.add(
          ArmarioEspaco(
            fita: f,
            sessao: s,
            label: override ?? '$fitaNome · Espaço $s',
          ),
        );
      }
    }
    return list;
  }

  ArmarioEspaco? espacoPorFitaSessao(int fita, int sessao) {
    for (final e in espacos) {
      if (e.fita == fita && e.sessao == sessao) return e;
    }
    return null;
  }
}

/// Equipamento alocado em um slot (inventário local no app — legado).
class ArmarioItem {
  final int id;
  final String nome;
  /// Formato firmware: f{fita}s{espaco}
  final String posicao;
  final String armarioId;
  final String ip;

  const ArmarioItem({
    required this.id,
    required this.nome,
    required this.posicao,
    required this.armarioId,
    required this.ip,
  });

  int? get fita {
    final m = RegExp(r'^f(\d+)s(\d+)$', caseSensitive: false).firstMatch(posicao);
    return m == null ? null : int.tryParse(m.group(1)!);
  }

  int? get espaco {
    final m = RegExp(r'^f(\d+)s(\d+)$', caseSensitive: false).firstMatch(posicao);
    return m == null ? null : int.tryParse(m.group(2)!);
  }

  String get posicaoLabel {
    final f = fita;
    final e = espaco;
    if (f == null || e == null) return posicao;
    final def = ArmariosLocalConfig.byId(armarioId);
    final slot = def?.espacoPorFitaSessao(f, e);
    return slot?.label ?? 'Fita $f · Espaço $e';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'posicao': posicao,
        'armarioId': armarioId,
        'ip': ip,
      };

  factory ArmarioItem.fromJson(Map<String, dynamic> json) {
    return ArmarioItem(
      id: json['id'] as int,
      nome: json['nome'] as String? ?? '',
      posicao: json['posicao'] as String? ?? '',
      armarioId: json['armarioId'] as String? ??
          json['esp_ip'] as String? ??
          '',
      ip: json['ip'] as String? ??
          json['esp_ip_original'] as String? ??
          '',
    );
  }
}

class ArmarioOnline {
  final ArmarioDef def;
  final String ip;
  final bool online;

  const ArmarioOnline({
    required this.def,
    required this.ip,
    required this.online,
  });

  String get id => def.id;
  String get name => def.name;
}
