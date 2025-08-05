import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/tecaai_service.dart';

class TecaAIDemoScreen extends StatefulWidget {
  const TecaAIDemoScreen({super.key});

  @override
  State<TecaAIDemoScreen> createState() => _TecaAIDemoScreenState();
}

class _TecaAIDemoScreenState extends State<TecaAIDemoScreen> {
  bool _isLoading = false;
  bool _isConnected = false;
  TecaAIResponse? _lastResponse;
  List<TecaAICommandHistory> _history = [];
  TecaAIStats? _stats;
  List<TecaAIItem> _items = [];
  List<TecaAIItem> _filteredItems = [];
  TecaAIItem? _selectedItem;
  String? _selectedArmario;

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
    super.dispose();
  }

  Future<void> _checkConnection() async {
    final connected = await TecaAIService.checkConnection();
    setState(() {
      _isConnected = connected;
    });
  }

  Future<void> _loadHistory() async {
    final history = await TecaAIService.getCommandHistory(limit: 20);
    setState(() {
      _history = history;
    });
  }

  Future<void> _loadStats() async {
    final stats = await TecaAIService.getStats();
    setState(() {
      _stats = stats;
    });
  }

  Future<void> _loadItems() async {
    final items = await TecaAIService.getAllItems();
    setState(() {
      _items = items;
      _filteredItems = items;
    });
  }

  void _filterItemsByArmario(String? armario) {
    setState(() {
      _selectedArmario = armario;
      _selectedItem = null; // Reset selected item when filtering
      
      if (armario == null || armario.isEmpty) {
        _filteredItems = _items;
      } else {
        _filteredItems = _items.where((item) => item.espIp == armario).toList();
      }
    });
  }

  List<String> get _availableArmarios {
    final armarios = _items.map((item) => item.espIp).toSet().toList();
    armarios.sort();
    return armarios;
  }

  Future<void> _locateItem() async {
    if (_selectedItem == null) {
      _showSnackBar('Selecione um item');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user!;
      final response = await TecaAIService.locateItem(
        item: _selectedItem!.nome,
        user: user,
      );

      setState(() {
        _lastResponse = response;
        _isLoading = false;
      });

      if (response.success) {
        _showSnackBar('Item localizado!');
        _loadHistory();
      } else {
        _showSnackBar('Erro: ${response.error}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Erro: $e');
    }
  }

  Future<void> _executePredefinedCommand(String commandKey) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user!;
      final response = await TecaAIService.executePredefinedCommand(
        commandKey: commandKey,
        user: user,
      );

      setState(() {
        _lastResponse = response;
        _isLoading = false;
      });

      if (response.success) {
        _showSnackBar('Comando executado!');
        _loadHistory();
      } else {
        _showSnackBar('Erro: ${response.error}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Erro: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TecaAI - Demonstração'),
        backgroundColor: const Color(0xFF2953A5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isConnected ? Icons.wifi : Icons.wifi_off),
            onPressed: _checkConnection,
            tooltip: _isConnected ? 'Conectado' : 'Desconectado',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status de conexão
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      _isConnected ? Icons.check_circle : Icons.error,
                      color: _isConnected ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isConnected ? 'TecaAI Conectado' : 'TecaAI Desconectado',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Estatísticas
            if (_stats != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estatísticas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Total de comandos: ${_stats!.totalCommands}'),
                      Text(
                        'Taxa de sucesso: ${_stats!.successRate.toStringAsFixed(1)}%',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Comandos por tipo:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ..._stats!.commandsByType.entries.map(
                        (entry) => Text('  ${entry.key}: ${entry.value}'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Localizar Item
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Localizar Item',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedArmario,
                      decoration: const InputDecoration(
                        labelText: 'Filtrar por Armário',
                        border: OutlineInputBorder(),
                        hintText: 'Escolha um armário para filtrar',
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Todos os Armários'),
                        ),
                        ..._availableArmarios.map((armario) {
                          return DropdownMenuItem<String>(
                            value: armario,
                            child: Text('Armário $armario'),
                          );
                        }),
                      ],
                      onChanged: (String? value) {
                        _filterItemsByArmario(value);
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<TecaAIItem>(
                      value: _selectedItem,
                      decoration: const InputDecoration(
                        labelText: 'Selecione um Item',
                        border: OutlineInputBorder(),
                        hintText: 'Escolha um item para localizar',
                      ),
                      items:
                          _filteredItems.map((item) {
                            return DropdownMenuItem<TecaAIItem>(
                              value: item,
                              child: Text(
                                '${item.nome} (${item.posicao} - Armário ${item.espIp})',
                              ),
                            );
                          }).toList(),
                      onChanged: (TecaAIItem? value) {
                        setState(() {
                          _selectedItem = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _locateItem,
                        child:
                            _isLoading
                                ? const CircularProgressIndicator()
                                : const Text('Localizar Item'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Comandos Pré-definidos
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Comandos Pré-definidos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed:
                              _isLoading
                                  ? null
                                  : () =>
                                      _executePredefinedCommand('ligar_luz'),
                          child: const Text('Ligar Luz'),
                        ),
                        ElevatedButton(
                          onPressed:
                              _isLoading
                                  ? null
                                  : () =>
                                      _executePredefinedCommand('desligar_luz'),
                          child: const Text('Desligar Luz'),
                        ),
                        ElevatedButton(
                          onPressed:
                              _isLoading
                                  ? null
                                  : () => _executePredefinedCommand(
                                    'modo_festa_on',
                                  ),
                          child: const Text('Modo Festa ON'),
                        ),
                        ElevatedButton(
                          onPressed:
                              _isLoading
                                  ? null
                                  : () => _executePredefinedCommand(
                                    'modo_festa_off',
                                  ),
                          child: const Text('Modo Festa OFF'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Última Resposta
            if (_lastResponse != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Última Resposta',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
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
                                color:
                                    _lastResponse!.success
                                        ? Colors.green
                                        : Colors.red,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_lastResponse!.response != null)
                              Text('Resposta: ${_lastResponse!.response}'),
                            if (_lastResponse!.error != null)
                              Text('Erro: ${_lastResponse!.error}'),
                            const SizedBox(height: 8),
                            Text(
                              'Timestamp: ${_lastResponse!.timestamp}',
                              style: const TextStyle(
                                fontSize: 12,
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
              const SizedBox(height: 16),
            ],

            // Histórico
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Histórico Recente',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_history.isEmpty)
                      const Text('Nenhum comando registrado'),
                    if (_history.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _history.length,
                        itemBuilder: (context, index) {
                          final item = _history[index];
                          return ListTile(
                            title: Text(item.parameter),
                            subtitle: Text(
                              '${item.commandType} - ${item.userRole}',
                            ),
                            trailing: Icon(
                              item.success ? Icons.check_circle : Icons.error,
                              color: item.success ? Colors.green : Colors.red,
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
      ),
    );
  }
}
