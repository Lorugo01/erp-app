import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../config/environment.dart';
import '../../services/config_service.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _isLoading = false;
  bool _isLoadingConfig = true;
  final String _currentEnvironment = EnvironmentConfig.environment.name;
  final String _apiUrl = ApiConfig.baseUrl;
  final int _timeout = ApiConfig.apiTimeout.inSeconds;

  // Configurações do sistema
  Map<String, dynamic> _systemConfig = {};
  Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    // Inicializar com valores padrão primeiro
    _initializeDefaultConfig();
    // Tentar carregar do backend em background
    _loadSystemConfig();
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeDefaultConfig() {
    _systemConfig = {
      'evaluationModel': 'TRADICIONAL',
      'minGrade': 5.0,
      'minAttendance': 75.0,
      'currentAcademicYear': '2024',
      'enrollmentPeriodStart': '01/12/2024',
      'enrollmentPeriodEnd': '31/01/2025',
      'operatingHoursStart': '07:00',
      'operatingHoursEnd': '18:00',
      'evaluationType': 'NUMERICO',
      'passingGrade': 7.0,
      'evaluationPeriods': '4 Bimestres',
      'maxClassCapacity': 35,
      'weeklyWorkload': 25,
      'maxLoginAttempts': 3,
      'sessionTimeout': 30,
      'requirePasswordChange': false,
      'enableDebugLogs': false,
      'validateSSLCert': true,
      'autoBackupEnabled': true,
      'backupFrequency': 'DIARIO',
      'retentionDays': 30,
    };
    _initializeControllers();
  }

  Future<void> _loadSystemConfig() async {
    try {
      setState(() => _isLoadingConfig = true);
      final config = await ConfigService.getConfig();
      setState(() {
        _systemConfig = config;
        _initializeControllers();
      });
    } catch (e) {
      debugPrint('⚠️ Erro ao carregar configurações do backend: $e');
      // Manter os valores padrão se falhar, sem mostrar erro ao usuário
    } finally {
      setState(() => _isLoadingConfig = false);
    }
  }

  void _initializeControllers() {
    _controllers = {
      'currentAcademicYear': TextEditingController(
        text: _systemConfig['currentAcademicYear']?.toString() ?? '',
      ),
      'enrollmentPeriodStart': TextEditingController(
        text: _systemConfig['enrollmentPeriodStart']?.toString() ?? '',
      ),
      'enrollmentPeriodEnd': TextEditingController(
        text: _systemConfig['enrollmentPeriodEnd']?.toString() ?? '',
      ),
      'operatingHoursStart': TextEditingController(
        text: _systemConfig['operatingHoursStart']?.toString() ?? '',
      ),
      'operatingHoursEnd': TextEditingController(
        text: _systemConfig['operatingHoursEnd']?.toString() ?? '',
      ),
      'passingGrade': TextEditingController(
        text: _systemConfig['passingGrade']?.toString() ?? '',
      ),
      'evaluationPeriods': TextEditingController(
        text: _systemConfig['evaluationPeriods']?.toString() ?? '',
      ),
      'maxClassCapacity': TextEditingController(
        text: _systemConfig['maxClassCapacity']?.toString() ?? '',
      ),
      'weeklyWorkload': TextEditingController(
        text: _systemConfig['weeklyWorkload']?.toString() ?? '',
      ),
      'maxLoginAttempts': TextEditingController(
        text: _systemConfig['maxLoginAttempts']?.toString() ?? '',
      ),
      'sessionTimeout': TextEditingController(
        text: _systemConfig['sessionTimeout']?.toString() ?? '',
      ),
      'retentionDays': TextEditingController(
        text: _systemConfig['retentionDays']?.toString() ?? '',
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingConfig) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações do Sistema'),
        backgroundColor: const Color(0xFF2953A5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Salvar Configurações',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seção: Configurações Gerais
            _buildSection(
              title: 'Configurações Gerais',
              icon: Icons.settings,
              children: [
                _buildEditableField(
                  title: 'Ano Letivo Atual',
                  controller: _controllers['currentAcademicYear']!,
                  icon: Icons.calendar_today,
                ),
                _buildEditableField(
                  title: 'Período de Matrículas',
                  controller: _controllers['enrollmentPeriodStart']!,
                  icon: Icons.date_range,
                  subtitle: 'Início',
                ),
                _buildEditableField(
                  title: 'Período de Matrículas',
                  controller: _controllers['enrollmentPeriodEnd']!,
                  icon: Icons.date_range,
                  subtitle: 'Fim',
                ),
                _buildEditableField(
                  title: 'Horário de Funcionamento',
                  controller: _controllers['operatingHoursStart']!,
                  icon: Icons.access_time,
                  subtitle: 'Início',
                ),
                _buildEditableField(
                  title: 'Horário de Funcionamento',
                  controller: _controllers['operatingHoursEnd']!,
                  icon: Icons.access_time,
                  subtitle: 'Fim',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Seção: Sistema de Notas
            _buildSection(
              title: 'Sistema de Notas',
              icon: Icons.star,
              children: [
                _buildDropdownField(
                  title: 'Tipo de Avaliação',
                  value: _systemConfig['evaluationType'] ?? 'NUMERICO',
                  items: [
                    DropdownMenuItem(
                      value: 'NUMERICO',
                      child: Text('Numérico (0-10)'),
                    ),
                    DropdownMenuItem(
                      value: 'CONCEITUAL',
                      child: Text('Conceitual (A-F)'),
                    ),
                    DropdownMenuItem(
                      value: 'PERCENTUAL',
                      child: Text('Percentual (0-100)'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _systemConfig['evaluationType'] = value;
                    });
                  },
                ),
                _buildEditableField(
                  title: 'Média para Aprovação',
                  controller: _controllers['passingGrade']!,
                  icon: Icons.grade,
                ),
                _buildEditableField(
                  title: 'Períodos de Avaliação',
                  controller: _controllers['evaluationPeriods']!,
                  icon: Icons.assessment,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Seção: Configurações de Turmas
            _buildSection(
              title: 'Configurações de Turmas',
              icon: Icons.class_,
              children: [
                _buildEditableField(
                  title: 'Capacidade Máxima',
                  controller: _controllers['maxClassCapacity']!,
                  icon: Icons.people,
                  suffix: ' alunos',
                ),
                _buildEditableField(
                  title: 'Carga Horária Semanal',
                  controller: _controllers['weeklyWorkload']!,
                  icon: Icons.schedule,
                  suffix: ' horas',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Seção: Configurações de Usuários
            _buildSection(
              title: 'Configurações de Usuários',
              icon: Icons.people,
              children: [
                _buildEditableField(
                  title: 'Tentativas de Login',
                  controller: _controllers['maxLoginAttempts']!,
                  icon: Icons.lock,
                ),
                _buildEditableField(
                  title: 'Timeout da Sessão',
                  controller: _controllers['sessionTimeout']!,
                  icon: Icons.timer,
                  suffix: ' minutos',
                ),
                _buildSwitchTile(
                  title: 'Exigir Mudança de Senha',
                  subtitle: 'Forçar usuários a alterarem senhas periodicamente',
                  value: _systemConfig['requirePasswordChange'] ?? false,
                  onChanged: (value) {
                    setState(() {
                      _systemConfig['requirePasswordChange'] = value;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Seção: Configurações de Segurança
            _buildSection(
              title: 'Segurança',
              icon: Icons.security,
              children: [
                _buildSwitchTile(
                  title: 'Logs de Debug',
                  subtitle: 'Ativar logs detalhados para desenvolvimento',
                  value: _systemConfig['enableDebugLogs'] ?? false,
                  onChanged: (value) {
                    setState(() {
                      _systemConfig['enableDebugLogs'] = value;
                    });
                  },
                ),
                _buildSwitchTile(
                  title: 'Validação de Certificados SSL',
                  subtitle: 'Verificar certificados SSL em conexões HTTPS',
                  value: _systemConfig['validateSSLCert'] ?? true,
                  onChanged: (value) {
                    setState(() {
                      _systemConfig['validateSSLCert'] = value;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Seção: Backup e Restauração
            _buildSection(
              title: 'Backup e Restauração',
              icon: Icons.backup,
              children: [
                _buildSwitchTile(
                  title: 'Backup Automático',
                  subtitle: 'Ativar backup automático do sistema',
                  value: _systemConfig['autoBackupEnabled'] ?? true,
                  onChanged: (value) {
                    setState(() {
                      _systemConfig['autoBackupEnabled'] = value;
                    });
                  },
                ),
                _buildDropdownField(
                  title: 'Frequência de Backup',
                  value: _systemConfig['backupFrequency'] ?? 'DIARIO',
                  items: [
                    DropdownMenuItem(value: 'DIARIO', child: Text('Diário')),
                    DropdownMenuItem(value: 'SEMANAL', child: Text('Semanal')),
                    DropdownMenuItem(value: 'MENSAL', child: Text('Mensal')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _systemConfig['backupFrequency'] = value;
                    });
                  },
                ),
                _buildEditableField(
                  title: 'Dias de Retenção',
                  controller: _controllers['retentionDays']!,
                  icon: Icons.history,
                  suffix: ' dias',
                ),
                _buildActionTile(
                  title: 'Restaurar Padrões',
                  subtitle: 'Voltar às configurações padrão do sistema',
                  icon: Icons.restore,
                  onTap: _resetToDefaults,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Seção: Informações do Sistema
            _buildSection(
              title: 'Informações do Sistema',
              icon: Icons.info,
              children: [
                _buildInfoCard(
                  title: 'Versão do App',
                  value: '1.0.0',
                  icon: Icons.app_settings_alt,
                ),
                _buildInfoCard(
                  title: 'Ambiente Atual',
                  value: _currentEnvironment.toUpperCase(),
                  icon: Icons.computer,
                ),
                _buildInfoCard(
                  title: 'URL da API',
                  value: _apiUrl,
                  icon: Icons.link,
                ),
                _buildInfoCard(
                  title: 'Timeout (segundos)',
                  value: _timeout.toString(),
                  icon: Icons.timer,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Botão de Salvar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveSettings,
                icon:
                    _isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.save),
                label: Text(
                  _isLoading ? 'Salvando...' : 'Salvar Configurações',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2953A5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF2953A5),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required String title,
    required TextEditingController controller,
    required IconData icon,
    String? subtitle,
    String? suffix,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF2953A5), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
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
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixText: suffix,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              hintText: 'Digite o valor...',
            ),
            onChanged: (value) {
              // Atualizar o valor no sistema de configurações
              if (value.isNotEmpty) {
                setState(() {
                  if (title.contains('Ano Letivo')) {
                    _systemConfig['currentAcademicYear'] = value;
                  } else if (title.contains('Período de Matrículas') &&
                      subtitle == 'Início') {
                    _systemConfig['enrollmentPeriodStart'] = value;
                  } else if (title.contains('Período de Matrículas') &&
                      subtitle == 'Fim') {
                    _systemConfig['enrollmentPeriodEnd'] = value;
                  } else if (title.contains('Horário de Funcionamento') &&
                      subtitle == 'Início') {
                    _systemConfig['operatingHoursStart'] = value;
                  } else if (title.contains('Horário de Funcionamento') &&
                      subtitle == 'Fim') {
                    _systemConfig['operatingHoursEnd'] = value;
                  } else if (title.contains('Média para Aprovação')) {
                    _systemConfig['passingGrade'] =
                        double.tryParse(value) ?? value;
                  } else if (title.contains('Períodos de Avaliação')) {
                    _systemConfig['evaluationPeriods'] = value;
                  } else if (title.contains('Capacidade Máxima')) {
                    _systemConfig['maxClassCapacity'] =
                        int.tryParse(value) ?? value;
                  } else if (title.contains('Carga Horária Semanal')) {
                    _systemConfig['weeklyWorkload'] =
                        int.tryParse(value) ?? value;
                  } else if (title.contains('Tentativas de Login')) {
                    _systemConfig['maxLoginAttempts'] =
                        int.tryParse(value) ?? value;
                  } else if (title.contains('Timeout da Sessão')) {
                    _systemConfig['sessionTimeout'] =
                        int.tryParse(value) ?? value;
                  } else if (title.contains('Dias de Retenção')) {
                    _systemConfig['retentionDays'] =
                        int.tryParse(value) ?? value;
                  }
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String title,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            items: items,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2953A5), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF2953A5),
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF2953A5)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  // Métodos de ação
  Future<void> _saveSettings() async {
    try {
      setState(() => _isLoading = true);

      // Preparar dados para salvar
      final configData = Map<String, dynamic>.from(_systemConfig);

      // Adicionar campos editáveis
      _controllers.forEach((key, controller) {
        if (controller.text.isNotEmpty) {
          final value = controller.text;
          // Converter para tipo apropriado
          if (key.contains('Grade') ||
              key.contains('Capacity') ||
              key.contains('Workload') ||
              key.contains('Attempts') ||
              key.contains('Timeout') ||
              key.contains('Retention')) {
            configData[key] =
                double.tryParse(value) ?? int.tryParse(value) ?? value;
          } else {
            configData[key] = value;
          }
        }
      });

      // Salvar no backend
      await ConfigService.updateConfig(configData);

      // Recarregar configurações
      await _loadSystemConfig();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configurações salvas com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar configurações: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetToDefaults() async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Restaurar Padrões'),
              content: const Text(
                'Tem certeza que deseja restaurar todas as configurações para os valores padrão?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Confirmar'),
                ),
              ],
            ),
      );

      if (confirmed == true) {
        setState(() => _isLoading = true);

        // Resetar no backend
        await ConfigService.resetConfig();

        // Recarregar configurações
        await _loadSystemConfig();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Configurações restauradas para padrão!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao restaurar configurações: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
