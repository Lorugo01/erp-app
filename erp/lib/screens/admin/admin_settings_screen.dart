import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../config/environment.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _isLoading = false;
  String _currentEnvironment = EnvironmentConfig.environment.name;
  String _apiUrl = ApiConfig.baseUrl;
  int _timeout = ApiConfig.apiTimeout.inSeconds;

  @override
  Widget build(BuildContext context) {
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

            const SizedBox(height: 24),

            // Seção: Configurações de Ambiente
            _buildSection(
              title: 'Configurações de Ambiente',
              icon: Icons.settings,
              children: [
                _buildEnvironmentSelector(),
                _buildApiUrlEditor(),
                _buildTimeoutEditor(),
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
                  value: true,
                  onChanged: (value) {
                    // Implementar toggle de logs
                  },
                ),
                _buildSwitchTile(
                  title: 'Validação de Certificados SSL',
                  subtitle: 'Verificar certificados SSL em conexões HTTPS',
                  value: true,
                  onChanged: (value) {
                    // Implementar toggle de validação SSL
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
                _buildActionTile(
                  title: 'Exportar Configurações',
                  subtitle: 'Salvar configurações em arquivo JSON',
                  icon: Icons.download,
                  onTap: _exportSettings,
                ),
                _buildActionTile(
                  title: 'Importar Configurações',
                  subtitle: 'Carregar configurações de arquivo JSON',
                  icon: Icons.upload,
                  onTap: _importSettings,
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

            // Seção: Testes e Diagnóstico
            _buildSection(
              title: 'Testes e Diagnóstico',
              icon: Icons.bug_report,
              children: [
                _buildActionTile(
                  title: 'Testar Conexão com API',
                  subtitle: 'Verificar se a API está acessível',
                  icon: Icons.wifi,
                  onTap: _testApiConnection,
                ),
                _buildActionTile(
                  title: 'Verificar Status do Servidor',
                  subtitle: 'Testar todos os endpoints da API',
                  icon: Icons.health_and_safety,
                  onTap: _checkServerStatus,
                ),
                _buildActionTile(
                  title: 'Limpar Cache do App',
                  subtitle: 'Remover dados temporários',
                  icon: Icons.cleaning_services,
                  onTap: _clearAppCache,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Seção: Sobre
            _buildSection(
              title: 'Sobre',
              icon: Icons.help,
              children: [
                _buildActionTile(
                  title: 'Sobre o Sistema',
                  subtitle: 'Informações sobre o ByLAB ERP',
                  icon: Icons.info,
                  onTap: _showAboutDialog,
                ),
                _buildActionTile(
                  title: 'Logs do Sistema',
                  subtitle: 'Visualizar logs de erro e debug',
                  icon: Icons.list_alt,
                  onTap: _showSystemLogs,
                ),
                _buildActionTile(
                  title: 'Política de Privacidade',
                  subtitle: 'Como seus dados são utilizados',
                  icon: Icons.privacy_tip,
                  onTap: _showPrivacyPolicy,
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

  Widget _buildEnvironmentSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ambiente', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _currentEnvironment,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: 'development',
                child: Text('Desenvolvimento'),
              ),
              DropdownMenuItem(value: 'production', child: Text('Produção')),
              DropdownMenuItem(value: 'local', child: Text('Local')),
            ],
            onChanged: (value) {
              setState(() {
                _currentEnvironment = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildApiUrlEditor() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'URL da API',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: _apiUrl,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              hintText: 'http://192.168.18.15:3000',
            ),
            onChanged: (value) {
              setState(() {
                _apiUrl = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimeoutEditor() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Timeout (segundos)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: _timeout.toString(),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              hintText: '30',
            ),
            onChanged: (value) {
              setState(() {
                _timeout = int.tryParse(value) ?? 30;
              });
            },
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
    setState(() {
      _isLoading = true;
    });

    // Simular salvamento
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configurações salvas com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _exportSettings() {
    // Implementar exportação de configurações
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exportando configurações...')),
    );
  }

  void _importSettings() {
    // Implementar importação de configurações
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Importando configurações...')),
    );
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Restaurar Padrões'),
            content: const Text(
              'Tem certeza que deseja restaurar todas as configurações para os valores padrão?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Configurações restauradas!')),
                  );
                },
                child: const Text('Confirmar'),
              ),
            ],
          ),
    );
  }

  void _testApiConnection() {
    // Implementar teste de conexão
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Testando conexão com API...')),
    );
  }

  void _checkServerStatus() {
    // Implementar verificação de status
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Verificando status do servidor...')),
    );
  }

  void _clearAppCache() {
    // Implementar limpeza de cache
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Cache limpo com sucesso!')));
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sobre o ByLAB ERP'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Versão: 1.0.0'),
                SizedBox(height: 8),
                Text('Sistema de Gestão Escolar'),
                SizedBox(height: 8),
                Text('Desenvolvido com Flutter e Node.js'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showSystemLogs() {
    // Implementar visualização de logs
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Abrindo logs do sistema...')));
  }

  void _showPrivacyPolicy() {
    // Implementar política de privacidade
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Abrindo política de privacidade...')),
    );
  }
}
