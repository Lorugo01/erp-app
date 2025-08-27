import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/tecaai_service.dart';

class ArmariosScreen extends StatefulWidget {
  const ArmariosScreen({super.key});

  @override
  State<ArmariosScreen> createState() => _ArmariosScreenState();
}

class _ArmariosScreenState extends State<ArmariosScreen> {
  bool _isLoading = false;
  bool _isConnected = false;
  TecaAIResponse? _lastResponse;
  List<TecaAICommandHistory> _history = [];
  TecaAIStats? _stats;
  List<TecaAIItem> _items = [];
  List<TecaAIItem> _filteredItems = [];
  TecaAIItem? _selectedItem;
  String? _selectedArmario;

  // Controllers para adicionar/editar itens
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _itemPositionController = TextEditingController();
  final TextEditingController _itemEspIpController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _itemFileiraController = TextEditingController();
  final TextEditingController _itemSegmentoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _loadHistory();
    _loadStats();
    _loadItems();
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _itemPositionController.dispose();
    _itemEspIpController.dispose();
    _searchController.dispose();
    _itemFileiraController.dispose();
    _itemSegmentoController.dispose();
    super.dispose();
  }

  Future<void> _checkConnection() async {
    final connected = await TecaAIService.checkConnection();
    if (mounted) {
      setState(() {
        _isConnected = connected;
      });
    }
  }

  Future<void> _loadHistory() async {
    final history = await TecaAIService.getCommandHistory(limit: 20);
    if (mounted) {
      setState(() {
        _history = history;
      });
    }
  }

  Future<void> _loadStats() async {
    final stats = await TecaAIService.getStats();
    if (mounted) {
      setState(() {
        _stats = stats;
      });
    }
  }

  Future<void> _loadItems() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    try {
      final items = await TecaAIService.getAllItems();
      if (mounted) {
        setState(() {
          _items = items;
          _filteredItems = items;
        });
      }
    } catch (e) {
      // Ignorar erro silenciosamente
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterItemsByArmario(String? armario) {
    _selectedArmario = armario;
    _applyFilters();
  }

  void _filterItemsBySearch(String searchTerm) {
    _applyFilters();
  }

  void _applyFilters() {
    List<TecaAIItem> filtered = _items;

    // Filtro por armário
    if (_selectedArmario != null) {
      filtered =
          filtered
              .where((item) => item.espIpOriginal == _selectedArmario)
              .toList();
    }

    // Filtro por busca
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filtered =
          filtered.where((item) {
            return item.nome.toLowerCase().contains(searchTerm) ||
                item.posicao.toLowerCase().contains(searchTerm) ||
                item.espIp.toLowerCase().contains(searchTerm);
          }).toList();
    }

    if (mounted) {
      setState(() {
        _filteredItems = filtered;
      });
    }
  }

  List<String> get _availableArmarios {
    final armarios = _items.map((item) => item.espIpOriginal).toSet().toList();
    armarios.sort();
    return armarios;
  }

  Future<void> _locateItem() async {
    if (_selectedItem == null) {
      _showSnackBar('Selecione um item');
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user!;
      final response = await TecaAIService.locateItem(
        item: _selectedItem!.nome,
        user: user,
      );

      if (mounted) {
        setState(() {
          _lastResponse = response;
          _isLoading = false;
        });
      }

      if (response.success) {
        _showSnackBar('Item localizado!');
        _loadHistory();
      } else {
        _showSnackBar('Erro: ${response.error}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      _showSnackBar('Erro: $e');
    }
  }

  Future<void> _executePredefinedCommand(String commandKey) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user!;
      final response = await TecaAIService.executePredefinedCommand(
        commandKey: commandKey,
        user: user,
      );

      if (mounted) {
        setState(() {
          _lastResponse = response;
          _isLoading = false;
        });
      }

      if (response.success) {
        _showSnackBar('Comando executado!');
        _loadHistory();
      } else {
        _showSnackBar('Erro: ${response.error}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      _showSnackBar('Erro: $e');
    }
  }

  Future<void> _addItem() async {
    // Limpar os controllers antes de usar
    _itemNameController.clear();
    _itemFileiraController.clear();
    _itemSegmentoController.clear();
    _itemEspIpController.clear();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder:
          (context) => _AddEditItemDialog(
            title: 'Adicionar Item',
            itemNameController: _itemNameController,
            itemFileiraController: _itemFileiraController,
            itemSegmentoController: _itemSegmentoController,
            itemEspIpController: _itemEspIpController,
            availableArmarios: _availableArmarios,
          ),
    );

    if (result != null) {
      if (mounted) {
        setState(() => _isLoading = true);
      }
      try {
        final response = await TecaAIService.addItem(
          nome: result['nome']!,
          posicao: result['posicao']!,
          espIp: result['esp_ip']!,
          user: context.read<AuthProvider>().user!,
        );

        if (mounted) {
          setState(() {
            _lastResponse = response;
            _isLoading = false;
          });
        }

        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response.response ?? 'Item adicionado com sucesso!',
              ),
              backgroundColor: Colors.green,
            ),
          );
          _loadItems(); // Recarregar lista
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error ?? 'Erro ao adicionar item'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _editItem(TecaAIItem item) async {
    _itemNameController.text = item.nome;
    _itemEspIpController.text = item.espIpOriginal;

    // Extrair fileira e segmento da posição
    final posicao = item.posicaoOriginal;
    if (posicao.startsWith('f') && posicao.contains('s')) {
      final partes = posicao.replaceAll('f', '').split('s');
      if (partes.length == 2) {
        _itemFileiraController.text = partes[0];
        _itemSegmentoController.text = partes[1];
      } else {
        _itemFileiraController.text = '';
        _itemSegmentoController.text = '';
      }
    } else {
      _itemFileiraController.text = '';
      _itemSegmentoController.text = '';
    }

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder:
          (context) => _AddEditItemDialog(
            title: 'Editar Item',
            itemNameController: _itemNameController,
            itemFileiraController: _itemFileiraController,
            itemSegmentoController: _itemSegmentoController,
            itemEspIpController: _itemEspIpController,
            availableArmarios: _availableArmarios,
          ),
    );

    if (result != null && item.id != null) {
      if (mounted) {
        setState(() => _isLoading = true);
      }
      try {
        final response = await TecaAIService.editItem(
          itemId: item.id!,
          nome: result['nome']!,
          posicao: result['posicao']!,
          espIp: result['esp_ip']!,
          user: context.read<AuthProvider>().user!,
        );

        if (mounted) {
          setState(() {
            _lastResponse = response;
            _isLoading = false;
          });
        }

        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.response ?? 'Item editado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadItems(); // Recarregar lista
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error ?? 'Erro ao editar item'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteItem(TecaAIItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar Exclusão'),
            content: Text(
              'Tem certeza que deseja remover o item "${item.nome}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Remover'),
              ),
            ],
          ),
    );

    if (confirm == true && item.id != null) {
      if (mounted) {
        setState(() => _isLoading = true);
      }
      try {
        final response = await TecaAIService.deleteItem(
          itemId: item.id!,
          user: context.read<AuthProvider>().user!,
        );

        if (mounted) {
          setState(() {
            _lastResponse = response;
            _isLoading = false;
          });
        }

        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.response ?? 'Item removido com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadItems(); // Recarregar lista
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error ?? 'Erro ao remover item'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título da seção
          LayoutBuilder(
            builder: (context, constraints) {
              if (isMobile && constraints.maxWidth < 400) {
                // Layout muito compacto para telas muito pequenas
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.computer,
                          size: 28,
                          color: Color(0xFF2953A5),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Gestão de Equipamentos',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2953A5),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (constraints.maxWidth < 350) ...[
                      SizedBox(height: 4),
                      Text(
                        'TecaAI',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2953A5),
                        ),
                      ),
                    ],
                  ],
                );
              } else if (isMobile) {
                // Layout mobile padrão
                return Row(
                  children: [
                    Icon(Icons.computer, size: 28, color: Color(0xFF2953A5)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Gestão de Equipamentos - TecaAI',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2953A5),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              } else {
                // Layout desktop
                return Row(
                  children: [
                    Icon(Icons.computer, size: 32, color: Color(0xFF2953A5)),
                    SizedBox(width: 12),
                    Text(
                      'Gestão de Equipamentos - TecaAI',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2953A5),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
          SizedBox(height: isMobile ? 16 : 24),

          // Status de conexão
          Card(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              child: Row(
                children: [
                  Icon(
                    _isConnected ? Icons.check_circle : Icons.error,
                    color: _isConnected ? Colors.green : Colors.red,
                    size: isMobile ? 20 : 24,
                  ),
                  SizedBox(width: isMobile ? 6 : 8),
                  Expanded(
                    child: Text(
                      _isConnected ? 'TecaAI Conectado' : 'TecaAI Desconectado',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isConnected ? Icons.wifi : Icons.wifi_off,
                      size: isMobile ? 20 : 24,
                    ),
                    onPressed: _checkConnection,
                    tooltip: _isConnected ? 'Conectado' : 'Desconectado',
                    padding: EdgeInsets.all(isMobile ? 4 : 8),
                    constraints: BoxConstraints(
                      minWidth: isMobile ? 32 : 48,
                      minHeight: isMobile ? 32 : 48,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: isMobile ? 12 : 16),

          // Estatísticas
          if (_stats != null) ...[
            Card(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estatísticas',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: isMobile ? 6 : 8),
                    Text(
                      'Total de comandos: ${_stats!.totalCommands}',
                      style: TextStyle(fontSize: isMobile ? 13 : 14),
                    ),
                    Text(
                      'Taxa de sucesso: ${_stats!.successRate.toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: isMobile ? 13 : 14),
                    ),
                    SizedBox(height: isMobile ? 6 : 8),
                    Text(
                      'Comandos por tipo:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 13 : 14,
                      ),
                    ),
                    ..._stats!.commandsByType.entries.map(
                      (entry) => Text(
                        '  ${entry.key}: ${entry.value}',
                        style: TextStyle(fontSize: isMobile ? 12 : 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: isMobile ? 12 : 16),
          ],

          // Seção: Localizar Item
          Card(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (isMobile && constraints.maxWidth < 400) {
                        // Layout compacto para telas muito pequenas
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Localizar Item',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  onPressed: _isLoading ? null : _addItem,
                                  icon: Icon(Icons.add, size: 20),
                                  tooltip: 'Adicionar Item',
                                  padding: EdgeInsets.all(8),
                                  constraints: BoxConstraints(
                                    minWidth: 36,
                                    minHeight: 36,
                                  ),
                                ),
                                IconButton(
                                  onPressed:
                                      _isLoading ? null : () => _loadItems(),
                                  icon: Icon(Icons.refresh, size: 20),
                                  tooltip: 'Recarregar Itens',
                                  padding: EdgeInsets.all(8),
                                  constraints: BoxConstraints(
                                    minWidth: 36,
                                    minHeight: 36,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      } else {
                        // Layout padrão
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Localizar Item',
                              style: TextStyle(
                                fontSize: isMobile ? 16 : 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: _isLoading ? null : _addItem,
                                  icon: Icon(
                                    Icons.add,
                                    size: isMobile ? 20 : 24,
                                  ),
                                  tooltip: 'Adicionar Item',
                                  padding: EdgeInsets.all(isMobile ? 4 : 8),
                                  constraints: BoxConstraints(
                                    minWidth: isMobile ? 36 : 48,
                                    minHeight: isMobile ? 36 : 48,
                                  ),
                                ),
                                IconButton(
                                  onPressed:
                                      _isLoading ? null : () => _loadItems(),
                                  icon: Icon(
                                    Icons.refresh,
                                    size: isMobile ? 20 : 24,
                                  ),
                                  tooltip: 'Recarregar Itens',
                                  padding: EdgeInsets.all(isMobile ? 4 : 8),
                                  constraints: BoxConstraints(
                                    minWidth: isMobile ? 36 : 48,
                                    minHeight: isMobile ? 36 : 48,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  SizedBox(height: isMobile ? 12 : 16),

                  // Filtro por armário
                  DropdownButtonFormField<String>(
                    value: _selectedArmario,
                    decoration: InputDecoration(
                      labelText: 'Filtrar por Armário',
                      border: const OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8 : 12,
                        vertical: isMobile ? 8 : 12,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Todos os Armários'),
                      ),
                      ..._availableArmarios.map((armario) {
                        // Traduzir o IP para letra para exibição
                        String displayText = armario;
                        if (armario == '192.168.100.184') {
                          displayText = 'A';
                        } else if (armario == '192.168.100.185') {
                          displayText = 'B';
                        } else if (armario == '192.168.100.186') {
                          displayText = 'C';
                        }

                        return DropdownMenuItem(
                          value: armario,
                          child: Text('Armário $displayText'),
                        );
                      }),
                    ],
                    onChanged: _filterItemsByArmario,
                  ),
                  SizedBox(height: isMobile ? 12 : 16),

                  // Campo de busca
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Buscar Item',
                      hintText:
                          isMobile
                              ? 'Nome, posição ou armário...'
                              : 'Digite o nome, posição ou armário...',
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search, size: isMobile ? 20 : 24),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8 : 12,
                        vertical: isMobile ? 8 : 12,
                      ),
                      suffixIcon:
                          _searchController.text.isNotEmpty
                              ? IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  _filterItemsBySearch('');
                                },
                                icon: Icon(
                                  Icons.clear,
                                  size: isMobile ? 18 : 24,
                                ),
                                padding: EdgeInsets.all(isMobile ? 4 : 8),
                                constraints: BoxConstraints(
                                  minWidth: isMobile ? 32 : 48,
                                  minHeight: isMobile ? 32 : 48,
                                ),
                              )
                              : null,
                    ),
                    onChanged: _filterItemsBySearch,
                  ),
                  SizedBox(height: isMobile ? 12 : 16),

                  // Lista de itens
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_filteredItems.isEmpty)
                    Center(
                      child: Text(
                        'Nenhum item encontrado',
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    )
                  else
                    Container(
                      height: isMobile ? 150 : 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          return Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: isMobile ? 6 : 8,
                              vertical: isMobile ? 3 : 4,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey.shade700,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(50),
                                onTap: () {
                                  if (mounted) {
                                    setState(() {
                                      _selectedItem = item;
                                    });
                                  }
                                },
                                child: ListTile(
                                  title: Text(
                                    item.nome,
                                    style: TextStyle(
                                      fontSize: isMobile ? 13 : 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    '${item.posicao} - Armário ${item.espIp}',
                                    style: TextStyle(
                                      fontSize: isMobile ? 11 : 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        onPressed: () => _editItem(item),
                                        icon: Icon(
                                          Icons.edit,
                                          size: isMobile ? 18 : 20,
                                        ),
                                        tooltip: 'Editar',
                                        padding: EdgeInsets.all(
                                          isMobile ? 4 : 8,
                                        ),
                                        constraints: BoxConstraints(
                                          minWidth: isMobile ? 28 : 40,
                                          minHeight: isMobile ? 28 : 40,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => _deleteItem(item),
                                        icon: Icon(
                                          Icons.delete,
                                          size: isMobile ? 18 : 20,
                                          color: Colors.red,
                                        ),
                                        tooltip: 'Remover',
                                        padding: EdgeInsets.all(
                                          isMobile ? 4 : 8,
                                        ),
                                        constraints: BoxConstraints(
                                          minWidth: isMobile ? 28 : 40,
                                          minHeight: isMobile ? 28 : 40,
                                        ),
                                      ),
                                    ],
                                  ),
                                  selected: _selectedItem?.id == item.id,
                                  selectedTileColor: Colors.transparent,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  SizedBox(height: isMobile ? 12 : 16),

                  // Item Selecionado
                  if (_selectedItem != null) ...[
                    Container(
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: isMobile ? 18 : 24,
                              ),
                              SizedBox(width: isMobile ? 6 : 8),
                              Text(
                                'Item Selecionado:',
                                style: TextStyle(
                                  fontSize: isMobile ? 14 : 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isMobile ? 8 : 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Nome: ${_selectedItem!.nome}',
                                      style: TextStyle(
                                        fontSize: isMobile ? 12 : 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: isMobile ? 2 : 4),
                                    Text(
                                      'Posição: ${_selectedItem!.posicao}',
                                      style: TextStyle(
                                        fontSize: isMobile ? 12 : 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: isMobile ? 2 : 4),
                                    Text(
                                      'Armário: ${_selectedItem!.espIp}',
                                      style: TextStyle(
                                        fontSize: isMobile ? 12 : 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => _editItem(_selectedItem!),
                                icon: Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                  size: isMobile ? 18 : 24,
                                ),
                                tooltip: 'Editar Item Selecionado',
                                padding: EdgeInsets.all(isMobile ? 4 : 8),
                                constraints: BoxConstraints(
                                  minWidth: isMobile ? 32 : 48,
                                  minHeight: isMobile ? 32 : 48,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                  ],

                  // Botão de localizar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          _selectedItem == null || _isLoading
                              ? null
                              : _locateItem,
                      icon: Icon(Icons.search, size: isMobile ? 18 : 24),
                      label: Text(
                        isMobile
                            ? 'Localizar Item'
                            : 'Localizar Item Selecionado',
                        style: TextStyle(fontSize: isMobile ? 13 : 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 16 : 24,
                          vertical: isMobile ? 12 : 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: isMobile ? 12 : 16),

          // Comandos Pré-definidos
          Card(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Comandos Pré-definidos',
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: isMobile ? 12 : 16),
                  Wrap(
                    spacing: isMobile ? 6 : 8,
                    runSpacing: isMobile ? 6 : 8,
                    children: [
                      ElevatedButton(
                        onPressed:
                            _isLoading
                                ? null
                                : () => _executePredefinedCommand('ligar_luz'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 12 : 16,
                            vertical: isMobile ? 8 : 12,
                          ),
                        ),
                        child: Text(
                          'Ligar Luz',
                          style: TextStyle(fontSize: isMobile ? 12 : 14),
                        ),
                      ),
                      ElevatedButton(
                        onPressed:
                            _isLoading
                                ? null
                                : () =>
                                    _executePredefinedCommand('desligar_luz'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 12 : 16,
                            vertical: isMobile ? 8 : 12,
                          ),
                        ),
                        child: Text(
                          'Desligar Luz',
                          style: TextStyle(fontSize: isMobile ? 12 : 14),
                        ),
                      ),
                      ElevatedButton(
                        onPressed:
                            _isLoading
                                ? null
                                : () =>
                                    _executePredefinedCommand('modo_festa_on'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 12 : 16,
                            vertical: isMobile ? 8 : 12,
                          ),
                        ),
                        child: Text(
                          'Modo Festa ON',
                          style: TextStyle(fontSize: isMobile ? 12 : 14),
                        ),
                      ),
                      ElevatedButton(
                        onPressed:
                            _isLoading
                                ? null
                                : () =>
                                    _executePredefinedCommand('modo_festa_off'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 12 : 16,
                            vertical: isMobile ? 8 : 12,
                          ),
                        ),
                        child: Text(
                          'Modo Festa OFF',
                          style: TextStyle(fontSize: isMobile ? 12 : 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: isMobile ? 12 : 16),

          // Última Resposta
          if (_lastResponse != null) ...[
            Card(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Última Resposta',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: isMobile ? 6 : 8),
                    Container(
                      padding: EdgeInsets.all(isMobile ? 8 : 12),
                      decoration: BoxDecoration(
                        color:
                            _lastResponse!.success
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              _lastResponse!.success
                                  ? Colors.green
                                  : Colors.red,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _lastResponse!.success ? 'Sucesso' : 'Erro',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 13 : 14,
                              color:
                                  _lastResponse!.success
                                      ? Colors.green
                                      : Colors.red,
                            ),
                          ),
                          SizedBox(height: isMobile ? 6 : 8),
                          if (_lastResponse!.response != null)
                            Text(
                              'Resposta: ${_lastResponse!.response}',
                              style: TextStyle(fontSize: isMobile ? 12 : 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (_lastResponse!.error != null)
                            Text(
                              'Erro: ${_lastResponse!.error}',
                              style: TextStyle(fontSize: isMobile ? 12 : 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          SizedBox(height: isMobile ? 6 : 8),
                          Text(
                            'Timestamp: ${_lastResponse!.timestamp}',
                            style: TextStyle(
                              fontSize: isMobile ? 10 : 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: isMobile ? 12 : 16),
          ],

          // Histórico
          Card(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Histórico Recente',
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: isMobile ? 12 : 16),
                  if (_history.isEmpty)
                    Text(
                      'Nenhum comando registrado',
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  if (_history.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        final item = _history[index];
                        return ListTile(
                          title: Text(
                            item.parameter,
                            style: TextStyle(fontSize: isMobile ? 13 : 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${item.commandType} - ${item.userRole}',
                            style: TextStyle(fontSize: isMobile ? 11 : 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Icon(
                            item.success ? Icons.check_circle : Icons.error,
                            color: item.success ? Colors.green : Colors.red,
                            size: isMobile ? 18 : 24,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddEditItemDialog extends StatefulWidget {
  final String title;
  final TextEditingController itemNameController;
  final TextEditingController? itemFileiraController;
  final TextEditingController? itemSegmentoController;
  final TextEditingController itemEspIpController;
  final List<String> availableArmarios;

  const _AddEditItemDialog({
    required this.title,
    required this.itemNameController,
    this.itemFileiraController,
    this.itemSegmentoController,
    required this.itemEspIpController,
    required this.availableArmarios,
  });

  @override
  State<_AddEditItemDialog> createState() => _AddEditItemDialogState();
}

class _AddEditItemDialogState extends State<_AddEditItemDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedArmario;

  @override
  void initState() {
    super.initState();
    // Preencher o armário selecionado se já tiver um valor
    if (widget.itemEspIpController.text.isNotEmpty) {
      final espIp = widget.itemEspIpController.text;
      // Verificar se o valor existe na lista de armários disponíveis
      if (widget.availableArmarios.contains(espIp)) {
        _selectedArmario = espIp;
      } else {
        _selectedArmario = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return AlertDialog(
      title: Text(widget.title, style: TextStyle(fontSize: isMobile ? 18 : 20)),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: widget.itemNameController,
              decoration: InputDecoration(
                labelText: 'Nome do Item',
                border: const OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8 : 12,
                  vertical: isMobile ? 8 : 12,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nome é obrigatório';
                }
                return null;
              },
            ),
            SizedBox(height: isMobile ? 12 : 16),

            // Campos de fileira e segmento
            LayoutBuilder(
              builder: (context, constraints) {
                if (isMobile && constraints.maxWidth < 300) {
                  // Layout vertical para telas muito pequenas
                  return Column(
                    children: [
                      TextFormField(
                        controller:
                            widget.itemFileiraController ??
                            TextEditingController(),
                        decoration: InputDecoration(
                          labelText: 'Fileira (f)',
                          border: const OutlineInputBorder(),
                          helperText: 'Ex: 1, 2, 3...',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 8 : 12,
                            vertical: isMobile ? 8 : 12,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Fileira é obrigatória';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Digite um número';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: isMobile ? 8 : 12),
                      TextFormField(
                        controller:
                            widget.itemSegmentoController ??
                            TextEditingController(),
                        decoration: InputDecoration(
                          labelText: 'Segmento (s)',
                          border: const OutlineInputBorder(),
                          helperText: 'Ex: 1, 2, 3...',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 8 : 12,
                            vertical: isMobile ? 8 : 12,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Segmento é obrigatório';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Digite um número';
                          }
                          return null;
                        },
                      ),
                    ],
                  );
                } else {
                  // Layout horizontal padrão
                  return Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller:
                              widget.itemFileiraController ??
                              TextEditingController(),
                          decoration: InputDecoration(
                            labelText: 'Fileira (f)',
                            border: const OutlineInputBorder(),
                            helperText: 'Ex: 1, 2, 3...',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 8 : 12,
                              vertical: isMobile ? 8 : 12,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Fileira é obrigatória';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Digite um número';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(width: isMobile ? 12 : 16),
                      Expanded(
                        child: TextFormField(
                          controller:
                              widget.itemSegmentoController ??
                              TextEditingController(),
                          decoration: InputDecoration(
                            labelText: 'Segmento (s)',
                            border: const OutlineInputBorder(),
                            helperText: 'Ex: 1, 2, 3...',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 8 : 12,
                              vertical: isMobile ? 8 : 12,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Segmento é obrigatório';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Digite um número';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
            SizedBox(height: isMobile ? 12 : 16),

            DropdownButtonFormField<String>(
              value: _selectedArmario,
              decoration: InputDecoration(
                labelText: 'Armário',
                border: const OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8 : 12,
                  vertical: isMobile ? 8 : 12,
                ),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Selecione um armário'),
                ),
                ...widget.availableArmarios.map((armario) {
                  // Traduzir o IP para letra para exibição
                  String displayText = armario;
                  if (armario == '192.168.100.184') {
                    displayText = 'A';
                  } else if (armario == '192.168.100.185') {
                    displayText = 'B';
                  } else if (armario == '192.168.100.186') {
                    displayText = 'C';
                  }

                  return DropdownMenuItem(
                    value: armario,
                    child: Text('Armário $displayText'),
                  );
                }),
              ],
              onChanged: (value) {
                if (mounted) {
                  setState(() {
                    _selectedArmario = value;
                    if (value != null) {
                      widget.itemEspIpController.text = value;
                    }
                  });
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Armário é obrigatório';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 8 : 12,
            ),
          ),
          child: Text(
            'Cancelar',
            style: TextStyle(fontSize: isMobile ? 13 : 14),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final fileira = widget.itemFileiraController?.text ?? '';
              final segmento = widget.itemSegmentoController?.text ?? '';
              final posicao = 'f${fileira}s$segmento';

              Navigator.of(context).pop({
                'nome': widget.itemNameController.text,
                'posicao': posicao,
                'esp_ip': widget.itemEspIpController.text,
              });
            }
          },
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 8 : 12,
            ),
          ),
          child: Text(
            widget.title.contains('Adicionar') ? 'Adicionar' : 'Salvar',
            style: TextStyle(fontSize: isMobile ? 13 : 14),
          ),
        ),
      ],
    );
  }
}
