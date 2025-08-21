import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback? onLoginTap;
  final bool? isDeveloperRegistration;
  const RegisterScreen({
    super.key,
    this.onLoginTap,
    this.isDeveloperRegistration,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _email = '';
  String _password = '';
  Role _selectedRole = Role.student;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoading = authProvider.isLoading;
    final error = authProvider.error;

    return Scaffold(
      body: Row(
        children: [
          // Lado esquerdo azul com logo
          Expanded(
            flex: 2,
            child: Container(
              color: const Color(0xFF2953A5),
              child: Center(
                child: Text(
                  'ByLAB',
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ),
            ),
          ),
          // Lado direito com formulário
          Expanded(
            flex: 3,
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),
                        const Text(
                          'Cadastro',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        // Tipo de usuário
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: DropdownButtonFormField<Role>(
                            value: _selectedRole,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              icon: Icon(Icons.person),
                              labelText: 'Tipo de usuário',
                            ),
                            items: [
                              DropdownMenuItem(
                                value: Role.student,
                                child: Text(
                                  'Aluno',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DropdownMenuItem(
                                value: Role.teacher,
                                child: Text(
                                  'Professor',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DropdownMenuItem(
                                value: Role.admin,
                                child: Text(
                                  'Admin',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              // Opção DEVELOPER apenas para usuários autorizados
                              if (widget.isDeveloperRegistration ?? false)
                                DropdownMenuItem(
                                  value: Role.developer,
                                  child: Text(
                                    'Desenvolvedor',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                            onChanged: (role) {
                              setState(() {
                                _selectedRole = role!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Nome
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: TextFormField(
                            initialValue: '',
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              icon: Icon(Icons.person_outline),
                              labelText: 'Nome',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Informe o nome';
                              }
                              return null;
                            },
                            onSaved: (value) => _name = value!.trim(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Email
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: TextFormField(
                            initialValue: '',
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              icon: Icon(Icons.email),
                              labelText: 'Email',
                              hintText: 'example@gmail.com',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Informe o email';
                              }
                              if (!value.contains('@')) {
                                return 'Email inválido';
                              }
                              return null;
                            },
                            onSaved: (value) => _email = value!.trim(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Senha
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: Stack(
                            alignment: Alignment.centerRight,
                            children: [
                              TextFormField(
                                initialValue: '',
                                obscureText: _obscurePassword,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  icon: Icon(Icons.vpn_key),
                                  labelText: 'Senha',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Informe a senha';
                                  }
                                  if (value.length < 6) {
                                    return 'A senha deve ter pelo menos 6 caracteres';
                                  }
                                  return null;
                                },
                                onSaved: (value) => _password = value!,
                              ),
                              IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        if (error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              error,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        const SizedBox(height: 8),
                        // Botão Registrar
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2953A5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            onPressed:
                                isLoading
                                    ? null
                                    : () async {
                                      if (_formKey.currentState!.validate()) {
                                        _formKey.currentState!.save();
                                        await authProvider.register(
                                          email: _email,
                                          password: _password,
                                          name: _name,
                                          role: _selectedRole,
                                        );
                                        if (authProvider.isAuthenticated) {}
                                      }
                                    },
                            child:
                                isLoading
                                    ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                    : const Text(
                                      'Registrar',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Link para login
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Já tem conta?'),
                            TextButton(
                              onPressed: widget.onLoginTap,
                              child: const Text('Faça login'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
