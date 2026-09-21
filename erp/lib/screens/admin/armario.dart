import 'package:flutter/material.dart';

import '../../config/armarios_local_config.dart';
import '../../config/teca_erp_config.dart';
import '../../services/armarios_local_service.dart';
import '../../services/teca_erp_service.dart';
import '../../utils/user_friendly_error.dart';

/// Front da API de locação Teca (`/erp/itens`) + controle LED na LAN.
class ArmariosScreen extends StatefulWidget {
  const ArmariosScreen({super.key});

  @override
  State<ArmariosScreen> createState() => _ArmariosScreenState();
}

class _ArmariosScreenState extends State<ArmariosScreen> {
  bool _loading = false;
  bool _apiOk = false;
  List<TecaItem> _items = [];
  List<TecaItem> _filtered = [];
  List<TecaArmarioResumo> _resumo = [];
  List<ArmarioOnline> _esps = [];
  TecaItem? _selected;
  String? _filterArmario;
  String? _filterStatus;
  String _lastMsg = '';
  final _searchCtrl = TextEditingController();

  static const _statusOptions = [
    ('', 'Todos'),
    ('disponivel', 'Disponível'),
    ('locado', 'Locado'),
    ('manutencao', 'Manutenção'),
  ];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() => _loading = true);
    try {
      final conn = await TecaErpService.checkConnection();
      final itens = await TecaErpService.listItens(
        armario: _filterArmario,
        status: _filterStatus,
        q: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      );
      final armarios = await TecaErpService.listArmarios();
      final esps = await ArmariosLocalService.discover();

      if (!mounted) return;
      setState(() {
        _apiOk = conn.success;
        _items = itens.data ?? [];
        _resumo = armarios.data ?? [];
        _esps = esps;
        _applyLocalFilter();
        _lastMsg = conn.success
            ? 'API Teca OK · ${_items.length} item(ns)'
            : (conn.error ?? 'API Teca indisponível');
      });

      if (!itens.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(itens.error ?? 'Falha ao listar itens'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _apiOk = false;
        _lastMsg = userErrorMessage(e);
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reloadItens() async {
    final itens = await TecaErpService.listItens(
      armario: _filterArmario,
      status: _filterStatus,
      q: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
    );
    final armarios = await TecaErpService.listArmarios();
    if (!mounted) return;
    setState(() {
      if (itens.success) {
        _items = itens.data ?? [];
        _applyLocalFilter();
      }
      if (armarios.success) _resumo = armarios.data ?? [];
    });
  }

  void _applyLocalFilter() {
    // Filtros principais já vão na API; aqui só garante seleção válida.
    _filtered = List<TecaItem>.from(_items);
  }

  /// Categorias já usadas nos itens (ordenadas), para o dropdown de cadastro.
  List<String> get _categoriasExistentes {
    final set = <String>{};
    for (final i in _items) {
      final c = i.categoria?.trim();
      if (c != null && c.isNotEmpty) set.add(c);
    }
    final list = set.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  Future<void> _locate(TecaItem item) async {
    setState(() => _loading = true);
    final msg = await TecaErpService.localizeOnEsp(item);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _selected = item;
      _lastMsg = msg;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: msg.startsWith('LED') ? Colors.green : Colors.orange,
      ),
    );
  }

  Future<void> _showCreateOrEdit({TecaItem? editing}) async {
    final nomeCtrl = TextEditingController(text: editing?.nome ?? '');
    final codigoCtrl = TextEditingController(text: editing?.codigo ?? '');
    final descCtrl = TextEditingController(text: editing?.descricao ?? '');
    final novaCatCtrl = TextEditingController();
    var status = editing?.status ?? 'disponivel';

    const nenhuma = '';
    const outra = '__outra__';
    final categorias = List<String>.from(_categoriasExistentes);
    final atual = editing?.categoria?.trim() ?? '';
    if (atual.isNotEmpty && !categorias.contains(atual)) {
      categorias.add(atual);
      categorias.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    }
    var categoriaSel = atual.isNotEmpty ? atual : nenhuma;
    var mostrarOutra = false;

    String armarioId = editing?.alocacao?.armario ??
        _filterArmario ??
        ArmariosLocalConfig.catalog.first.id;
    var def0 = ArmariosLocalConfig.byId(armarioId)!;
    int fitaSel = editing?.alocacao?.fita ?? def0.fitasUteis.first;
    if (!def0.fitasUteis.contains(fitaSel)) {
      fitaSel = def0.fitasUteis.first;
    }
    int sessaoSel = editing?.alocacao?.sessao ?? 1;
    if (sessaoSel < 1 || sessaoSel > def0.espacosDaFita(fitaSel)) {
      sessaoSel = 1;
    }
    var alocarAgora = editing == null || editing.temLocal;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final def = ArmariosLocalConfig.byId(armarioId)!;
          final fitas = def.fitasUteis;
          if (!fitas.contains(fitaSel)) fitaSel = fitas.first;
          final maxSessao = def.espacosDaFita(fitaSel);
          if (sessaoSel < 1 || sessaoSel > maxSessao) sessaoSel = 1;
          final espacosDaFita = def.espacos
              .where((e) => e.fita == fitaSel)
              .toList();

          return AlertDialog(
            title: Text(editing == null ? 'Novo item' : 'Editar item'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nomeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nome *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: codigoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Código (opcional, único)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: mostrarOutra ? outra : categoriaSel,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Categoria',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: nenhuma,
                        child: Text('Sem categoria'),
                      ),
                      ...categorias.map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      const DropdownMenuItem(
                        value: outra,
                        child: Text('Outra…'),
                      ),
                    ],
                    onChanged: (v) => setLocal(() {
                      if (v == outra) {
                        mostrarOutra = true;
                        categoriaSel = nenhuma;
                      } else {
                        mostrarOutra = false;
                        categoriaSel = v ?? nenhuma;
                      }
                    }),
                  ),
                  if (mostrarOutra) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: novaCatCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nova categoria',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Local no armário',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Escolha armário → fita → espaço (firmware)',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: armarioId,
                    decoration: const InputDecoration(
                      labelText: 'Armário *',
                      border: OutlineInputBorder(),
                    ),
                    items: ArmariosLocalConfig.catalog
                        .map(
                          (a) => DropdownMenuItem(
                            value: a.id,
                            child: Text(
                              '${a.name} (${a.espacos.length} espaços)',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setLocal(() {
                      armarioId = v ?? 'A';
                      final d = ArmariosLocalConfig.byId(armarioId)!;
                      fitaSel = d.fitasUteis.first;
                      sessaoSel = 1;
                    }),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Alocar ao salvar'),
                    subtitle: const Text('Desligado = só cadastra o item'),
                    value: alocarAgora,
                    onChanged: (v) => setLocal(() => alocarAgora = v),
                  ),
                  if (alocarAgora) ...[
                    DropdownButtonFormField<int>(
                      initialValue: fitaSel,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Fita *',
                        border: OutlineInputBorder(),
                      ),
                      items: fitas
                          .map(
                            (f) => DropdownMenuItem(
                              value: f,
                              child: Text(
                                def.labelDaFita(f),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setLocal(() {
                        fitaSel = v ?? fitas.first;
                        sessaoSel = 1;
                      }),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      initialValue: sessaoSel,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Espaço *',
                        border: const OutlineInputBorder(),
                        helperText:
                            '${espacosDaFita.length} espaço(s) nesta fita',
                      ),
                      items: espacosDaFita
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.sessao,
                              child: Text(
                                e.label.contains('·')
                                    ? e.label.split('·').last.trim()
                                    : e.label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setLocal(() => sessaoSel = v ?? 1),
                    ),
                  ],
                  if (editing != null) ...[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'disponivel',
                          child: Text('Disponível'),
                        ),
                        DropdownMenuItem(
                          value: 'locado',
                          child: Text('Locado'),
                        ),
                        DropdownMenuItem(
                          value: 'manutencao',
                          child: Text('Manutenção'),
                        ),
                      ],
                      onChanged: (v) => setLocal(() => status = v ?? status),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nomeCtrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx, true);
                },
                child: const Text('Salvar'),
              ),
            ],
          );
        },
      ),
    );

    if (ok != true) return;

    final categoriaSalvar = mostrarOutra
        ? novaCatCtrl.text.trim()
        : categoriaSel.trim();

    final result = editing == null
        ? await TecaErpService.createItem(
            nome: nomeCtrl.text,
            codigo: codigoCtrl.text,
            descricao: descCtrl.text,
            categoria: categoriaSalvar,
          )
        : await TecaErpService.updateItem(
            id: editing.id,
            nome: nomeCtrl.text,
            codigo: codigoCtrl.text,
            descricao: descCtrl.text,
            categoria: categoriaSalvar,
            status: status,
          );

    if (!result.success || result.data == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Erro ao salvar item'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    var item = result.data!;
    String msg = editing == null ? 'Item criado' : 'Item atualizado';

    if (alocarAgora) {
      final aloc = await TecaErpService.setAlocacao(
        id: item.id,
        armario: armarioId,
        fita: fitaSel,
        sessao: sessaoSel,
      );
      if (aloc.success && aloc.data != null) {
        item = aloc.data!;
        msg =
            '${editing == null ? 'Item criado' : 'Item atualizado'} em ${item.alocacao?.label}';
      } else {
        msg = 'Item salvo, mas falha na alocação: ${aloc.error ?? "erro"}';
      }
    } else if (editing != null && !alocarAgora && editing.temLocal) {
      final cleared = await TecaErpService.clearAlocacao(editing.id);
      if (cleared.success) {
        msg = 'Item atualizado e retirado do armário';
      }
    }

    if (!mounted) return;
    setState(() => _selected = item);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: msg.contains('falha') ? Colors.orange : Colors.green,
      ),
    );
    await _reloadItens();
  }

  Future<void> _showAlocacao(TecaItem item) async {
    String armarioId = item.alocacao?.armario ??
        _filterArmario ??
        ArmariosLocalConfig.catalog.first.id;
    var def0 = ArmariosLocalConfig.byId(armarioId)!;
    int fitaSel = item.alocacao?.fita ?? def0.fitasUteis.first;
    if (!def0.fitasUteis.contains(fitaSel)) {
      fitaSel = def0.fitasUteis.first;
    }
    int sessaoSel = item.alocacao?.sessao ?? 1;
    if (sessaoSel < 1 || sessaoSel > def0.espacosDaFita(fitaSel)) {
      sessaoSel = 1;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final def = ArmariosLocalConfig.byId(armarioId)!;
          final fitas = def.fitasUteis;
          if (!fitas.contains(fitaSel)) fitaSel = fitas.first;
          final maxSessao = def.espacosDaFita(fitaSel);
          if (sessaoSel < 1 || sessaoSel > maxSessao) sessaoSel = 1;
          final espacosDaFita = def.espacos
              .where((e) => e.fita == fitaSel)
              .toList();

          return AlertDialog(
            title: Text('Alocar — ${item.nome}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: armarioId,
                    decoration: const InputDecoration(
                      labelText: 'Armário',
                      border: OutlineInputBorder(),
                    ),
                    items: ArmariosLocalConfig.catalog
                        .map(
                          (a) => DropdownMenuItem(
                            value: a.id,
                            child: Text(
                              '${a.name} (${a.espacos.length} espaços)',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setLocal(() {
                      armarioId = v ?? 'A';
                      final d = ArmariosLocalConfig.byId(armarioId)!;
                      fitaSel = d.fitasUteis.first;
                      sessaoSel = 1;
                    }),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: fitaSel,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Fita',
                      border: OutlineInputBorder(),
                    ),
                    items: fitas
                        .map(
                          (f) => DropdownMenuItem(
                            value: f,
                            child: Text(
                              def.labelDaFita(f),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setLocal(() {
                      fitaSel = v ?? fitas.first;
                      sessaoSel = 1;
                    }),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: sessaoSel,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Espaço',
                      border: const OutlineInputBorder(),
                      helperText: '${espacosDaFita.length} espaço(s) nesta fita',
                    ),
                    items: espacosDaFita
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.sessao,
                            child: Text(
                              e.label.contains('·')
                                  ? e.label.split('·').last.trim()
                                  : e.label,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setLocal(() => sessaoSel = v ?? 1),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Salvar alocação'),
              ),
            ],
          );
        },
      ),
    );

    if (ok != true) return;

    final result = await TecaErpService.setAlocacao(
      id: item.id,
      armario: armarioId,
      fita: fitaSel,
      sessao: sessaoSel,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.success
              ? 'Alocado em ${result.data?.alocacao?.label}'
              : (result.error ?? 'Erro ao alocar'),
        ),
        backgroundColor: result.success ? Colors.green : Colors.red,
      ),
    );
    if (result.success) {
      setState(() => _selected = result.data);
      await _reloadItens();
    }
  }

  Future<void> _clearAlocacao(TecaItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirar alocação'),
        content: Text('Remover "${item.nome}" do armário?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Retirar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final r = await TecaErpService.clearAlocacao(item.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(r.success ? 'Alocação removida' : (r.error ?? 'Erro')),
        backgroundColor: r.success ? Colors.green : Colors.red,
      ),
    );
    if (r.success) await _reloadItens();
  }

  Future<void> _deleteItem(TecaItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir item'),
        content: Text('Excluir permanentemente "${item.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final r = await TecaErpService.deleteItem(item.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(r.success ? 'Item excluído' : (r.error ?? 'Erro')),
        backgroundColor: r.success ? Colors.green : Colors.red,
      ),
    );
    if (r.success) {
      if (_selected?.id == item.id) _selected = null;
      await _reloadItens();
    }
  }

  int _totalNoArmario(String letra) {
    for (final r in _resumo) {
      if (r.letra == letra) return r.totalItens;
    }
    return _items.where((i) => i.alocacao?.armario == letra).length;
  }

  @override
  Widget build(BuildContext context) {
    final onlineEsp = _esps.where((e) => e.online).length;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _bootstrap,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Locação de itens — Teca',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  tooltip: 'Atualizar',
                  onPressed: _loading ? null : _bootstrap,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            Text(
              _apiOk
                  ? 'API online · $onlineEsp ESP(s) na LAN'
                  : 'API offline — confira TECA_ERP_BASE_URL',
              style: TextStyle(
                color: _apiOk ? Colors.green[700] : Colors.red[700],
              ),
            ),
            Text(
              TecaErpConfig.baseUrl,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            if (_lastMsg.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(_lastMsg, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
            ],
            const SizedBox(height: 12),
            _buildArmarioChips(),
            const SizedBox(height: 12),
            _buildFilters(),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Nenhum item. Toque em + para cadastrar.'),
              )
            else
              ..._filtered.map(_buildItemCard),
            if (_selected != null) ...[
              const SizedBox(height: 12),
              _buildDetail(_selected!),
            ],
            // Espaço para o botão "Novo item" não cobrir o último card.
            const SizedBox(height: 88),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'armarios-novo-item',
        onPressed: () => _showCreateOrEdit(),
        icon: const Icon(Icons.add),
        label: const Text('Novo item'),
      ),
    );
  }

  Widget _buildArmarioChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ArmariosLocalConfig.catalog.map((a) {
        final espOnline = _esps.any((e) => e.id == a.id && e.online);
        final selected = _filterArmario == a.id;
        final total = _totalNoArmario(a.id);
        return FilterChip(
          selected: selected,
          label: Text('${a.id} ($total)${espOnline ? ' · LAN' : ''}'),
          onSelected: (v) async {
            setState(() => _filterArmario = v ? a.id : null);
            setState(() => _loading = true);
            await _reloadItens();
            if (mounted) setState(() => _loading = false);
          },
        );
      }).toList(),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Buscar nome ou código',
              isDense: true,
              prefixIcon: const Icon(Icons.search, size: 20),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () async {
                  setState(() => _loading = true);
                  await _reloadItens();
                  if (mounted) setState(() => _loading = false);
                },
              ),
            ),
            onSubmitted: (_) async {
              setState(() => _loading = true);
              await _reloadItens();
              if (mounted) setState(() => _loading = false);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _filterStatus ?? '',
            decoration: const InputDecoration(
              labelText: 'Status',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            items: _statusOptions
                .map(
                  (e) => DropdownMenuItem(value: e.$1, child: Text(e.$2)),
                )
                .toList(),
            onChanged: (v) async {
              setState(() {
                _filterStatus = (v == null || v.isEmpty) ? null : v;
                _loading = true;
              });
              await _reloadItens();
              if (mounted) setState(() => _loading = false);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(TecaItem item) {
    final selected = _selected?.id == item.id;
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: selected
          ? theme.colorScheme.primaryContainer.withAlpha(60)
          : null,
      child: InkWell(
        onTap: () => setState(() => _selected = item),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    child: Text(
                      item.alocacao?.armario ?? '—',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.nome,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (item.codigo != null && item.codigo!.isNotEmpty)
                          Text(
                            item.codigo!,
                            style: theme.textTheme.bodySmall,
                          ),
                        Text(
                          item.statusLabel,
                          style: theme.textTheme.bodySmall,
                        ),
                        Text(
                          item.alocacao?.label ?? 'Sem local',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Localizar LED',
                      icon: const Icon(Icons.my_location),
                      onPressed: item.temLocal && item.alocacao!.temSlot
                          ? () => _locate(item)
                          : null,
                    ),
                    IconButton(
                      tooltip: 'Alocar',
                      icon: const Icon(Icons.place_outlined),
                      onPressed: () => _showAlocacao(item),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (v) {
                        switch (v) {
                          case 'edit':
                            _showCreateOrEdit(editing: item);
                          case 'clear':
                            _clearAlocacao(item);
                          case 'delete':
                            _deleteItem(item);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Editar'),
                        ),
                        if (item.temLocal)
                          const PopupMenuItem(
                            value: 'clear',
                            child: Text('Retirar do armário'),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Excluir'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetail(TecaItem item) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.nome,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (item.codigo != null) Text('Código: ${item.codigo}'),
            if (item.categoria != null) Text('Categoria: ${item.categoria}'),
            Text('Status: ${item.statusLabel}'),
            Text(item.alocacao?.label ?? 'Sem alocação'),
            if (item.descricao != null && item.descricao!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(item.descricao!),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: item.temLocal && item.alocacao!.temSlot
                      ? () => _locate(item)
                      : null,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Localizar LED'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showAlocacao(item),
                  icon: const Icon(Icons.place_outlined),
                  label: const Text('Alocar / realocar'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showCreateOrEdit(editing: item),
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
