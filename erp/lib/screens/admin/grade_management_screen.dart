import 'package:flutter/material.dart';
import '../../services/grade_period_service.dart';
import '../../services/grade_type_service.dart';

class GradeManagementScreen extends StatefulWidget {
  const GradeManagementScreen({super.key});

  @override
  State<GradeManagementScreen> createState() => _GradeManagementScreenState();
}

class _GradeManagementScreenState extends State<GradeManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Períodos
  List<Map<String, dynamic>> _periods = [];
  bool _loadingPeriods = false;
  String? _errorPeriods;

  // Tipos de nota
  List<Map<String, dynamic>> _gradeTypes = [];
  bool _loadingGradeTypes = false;
  String? _errorGradeTypes;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchPeriods();
    _fetchGradeTypes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchPeriods() async {
    if (mounted) {
      setState(() {
        _loadingPeriods = true;
        _errorPeriods = null;
      });
    }
    try {
      final periods = await GradePeriodService.getAllGradePeriods();
      if (mounted) {
        setState(() {
          _periods = periods;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorPeriods = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingPeriods = false;
        });
      }
    }
  }

  Future<void> _fetchGradeTypes() async {
    if (mounted) {
      setState(() {
        _loadingGradeTypes = true;
        _errorGradeTypes = null;
      });
    }
    try {
      final types = await GradeTypeService.getAllGradeTypes();
      if (mounted) {
        setState(() {
          _gradeTypes = types;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorGradeTypes = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingGradeTypes = false;
        });
      }
    }
  }

  Future<void> _deletePeriod(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar Exclusão'),
            content: const Text(
              'Tem certeza que deseja excluir este período? Esta ação não pode ser desfeita.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Excluir'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await GradePeriodService.deleteGradePeriod(id);
        await _fetchPeriods();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Período excluído com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir período: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteGradeType(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar Exclusão'),
            content: const Text(
              'Tem certeza que deseja excluir este tipo de nota? Esta ação não pode ser desfeita.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Excluir'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await GradeTypeService.deleteGradeType(id);
        await _fetchGradeTypes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tipo de nota excluído com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir tipo de nota: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showAddPeriodDialog() async {
    final result = await showDialog(
      context: context,
      builder: (context) => const AddPeriodDialog(),
    );
    if (result == true) {
      _fetchPeriods();
    }
  }

  void _showEditPeriodDialog(Map<String, dynamic> period) async {
    final result = await showDialog(
      context: context,
      builder: (context) => EditPeriodDialog(period: period),
    );
    if (result == true) {
      _fetchPeriods();
    }
  }

  void _showAddGradeTypeDialog() async {
    final result = await showDialog(
      context: context,
      builder: (context) => const AddGradeTypeDialog(),
    );
    if (result == true) {
      _fetchGradeTypes();
    }
  }

  void _showEditGradeTypeDialog(Map<String, dynamic> gradeType) async {
    final result = await showDialog(
      context: context,
      builder: (context) => EditGradeTypeDialog(gradeType: gradeType),
    );
    if (result == true) {
      _fetchGradeTypes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Sistema de Notas'),
        backgroundColor: const Color(0xFF2953A5),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Períodos', icon: Icon(Icons.schedule)),
            Tab(text: 'Tipos de Nota', icon: Icon(Icons.assignment)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildPeriodsTab(), _buildGradeTypesTab()],
      ),
    );
  }

  Widget _buildPeriodsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Períodos de Avaliação',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _showAddPeriodDialog,
                icon: const Icon(Icons.add),
                label: const Text('Novo Período'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child:
                _loadingPeriods
                    ? const Center(child: CircularProgressIndicator())
                    : _errorPeriods != null
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            _errorPeriods!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _fetchPeriods,
                            child: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    )
                    : _periods.isEmpty
                    ? const Center(child: Text('Nenhum período cadastrado'))
                    : ListView.builder(
                      itemCount: _periods.length,
                      itemBuilder: (context, index) {
                        final period = _periods[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF2953A5),
                              child: Text(
                                '${period['order'] ?? ''}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              period['name'] ?? 'Período',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text('Ordem: ${period['order']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed:
                                      () => _showEditPeriodDialog(period),
                                  icon: const Icon(Icons.edit),
                                  color: Colors.blue,
                                ),
                                IconButton(
                                  onPressed: () => _deletePeriod(period['id']),
                                  icon: const Icon(Icons.delete),
                                  color: Colors.red,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeTypesTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tipos de Nota',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _showAddGradeTypeDialog,
                icon: const Icon(Icons.add),
                label: const Text('Novo Tipo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child:
                _loadingGradeTypes
                    ? const Center(child: CircularProgressIndicator())
                    : _errorGradeTypes != null
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            _errorGradeTypes!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _fetchGradeTypes,
                            child: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    )
                    : _gradeTypes.isEmpty
                    ? const Center(
                      child: Text('Nenhum tipo de nota cadastrado'),
                    )
                    : ListView.builder(
                      itemCount: _gradeTypes.length,
                      itemBuilder: (context, index) {
                        final gradeType = _gradeTypes[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  gradeType['isConcept'] == true
                                      ? Colors.orange
                                      : const Color(0xFF2953A5),
                              child: Icon(
                                gradeType['isConcept'] == true
                                    ? Icons.abc
                                    : Icons.numbers,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              gradeType['name'] ?? 'Tipo',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (gradeType['description'] != null)
                                  Text(gradeType['description']),
                                Text(
                                  gradeType['isConcept'] == true
                                      ? 'Conceito (A, B, C, D...)'
                                      : 'Nota numérica (0-10)',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed:
                                      () => _showEditGradeTypeDialog(gradeType),
                                  icon: const Icon(Icons.edit),
                                  color: Colors.blue,
                                ),
                                IconButton(
                                  onPressed:
                                      () => _deleteGradeType(gradeType['id']),
                                  icon: const Icon(Icons.delete),
                                  color: Colors.red,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

// Dialog para adicionar período
class AddPeriodDialog extends StatefulWidget {
  const AddPeriodDialog({super.key});

  @override
  State<AddPeriodDialog> createState() => _AddPeriodDialogState();
}

class _AddPeriodDialogState extends State<AddPeriodDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _orderController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      await GradePeriodService.createGradePeriod(
        name: _nameController.text,
        order: int.parse(_orderController.text),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo Período'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome do Período'),
              validator:
                  (v) => v == null || v.isEmpty ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _orderController,
              decoration: const InputDecoration(labelText: 'Ordem'),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Informe a ordem';
                if (int.tryParse(v) == null) return 'Deve ser um número';
                return null;
              },
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child:
              _loading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Salvar'),
        ),
      ],
    );
  }
}

// Dialog para editar período
class EditPeriodDialog extends StatefulWidget {
  final Map<String, dynamic> period;

  const EditPeriodDialog({super.key, required this.period});

  @override
  State<EditPeriodDialog> createState() => _EditPeriodDialogState();
}

class _EditPeriodDialogState extends State<EditPeriodDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _orderController;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.period['name']);
    _orderController = TextEditingController(text: '${widget.period['order']}');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      await GradePeriodService.updateGradePeriod(
        id: widget.period['id'],
        name: _nameController.text,
        order: int.parse(_orderController.text),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Período'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome do Período'),
              validator:
                  (v) => v == null || v.isEmpty ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _orderController,
              decoration: const InputDecoration(labelText: 'Ordem'),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Informe a ordem';
                if (int.tryParse(v) == null) return 'Deve ser um número';
                return null;
              },
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child:
              _loading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Salvar'),
        ),
      ],
    );
  }
}

// Dialog para adicionar tipo de nota
class AddGradeTypeDialog extends StatefulWidget {
  const AddGradeTypeDialog({super.key});

  @override
  State<AddGradeTypeDialog> createState() => _AddGradeTypeDialogState();
}

class _AddGradeTypeDialogState extends State<AddGradeTypeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isConcept = false;
  bool _isRecovery = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      await GradeTypeService.createGradeType(
        name: _nameController.text,
        description:
            _descriptionController.text.isNotEmpty
                ? _descriptionController.text
                : null,
        isConcept: _isConcept,
        isRecovery: _isRecovery,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo Tipo de Nota'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome do Tipo'),
              validator:
                  (v) => v == null || v.isEmpty ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('É conceito (A, B, C, D)?'),
              subtitle: const Text('Se desmarcado, será nota numérica (0-10)'),
              value: _isConcept,
              onChanged: (value) {
                if (mounted) {
                  setState(() {
                    _isConcept = value ?? false;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('É nota de recuperação?'),
              subtitle: const Text(
                'Se marcado, esta nota poderá substituir a menor nota regular',
              ),
              value: _isRecovery,
              onChanged: (value) {
                if (mounted) {
                  setState(() {
                    _isRecovery = value ?? false;
                  });
                }
              },
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child:
              _loading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Salvar'),
        ),
      ],
    );
  }
}

// Dialog para editar tipo de nota
class EditGradeTypeDialog extends StatefulWidget {
  final Map<String, dynamic> gradeType;

  const EditGradeTypeDialog({super.key, required this.gradeType});

  @override
  State<EditGradeTypeDialog> createState() => _EditGradeTypeDialogState();
}

class _EditGradeTypeDialogState extends State<EditGradeTypeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late bool _isConcept;
  late bool _isRecovery;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.gradeType['name']);
    _descriptionController = TextEditingController(
      text: widget.gradeType['description'] ?? '',
    );
    _isConcept = widget.gradeType['isConcept'] ?? false;
    _isRecovery = widget.gradeType['isRecovery'] ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      await GradeTypeService.updateGradeType(
        id: widget.gradeType['id'],
        name: _nameController.text,
        description:
            _descriptionController.text.isNotEmpty
                ? _descriptionController.text
                : null,
        isConcept: _isConcept,
        isRecovery: _isRecovery,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Tipo de Nota'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome do Tipo'),
              validator:
                  (v) => v == null || v.isEmpty ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('É conceito (A, B, C, D)?'),
              subtitle: const Text('Se desmarcado, será nota numérica (0-10)'),
              value: _isConcept,
              onChanged: (value) {
                if (mounted) {
                  setState(() {
                    _isConcept = value ?? false;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('É nota de recuperação?'),
              subtitle: const Text(
                'Se marcado, esta nota poderá substituir a menor nota regular',
              ),
              value: _isRecovery,
              onChanged: (value) {
                if (mounted) {
                  setState(() {
                    _isRecovery = value ?? false;
                  });
                }
              },
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child:
              _loading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Salvar'),
        ),
      ],
    );
  }
}
