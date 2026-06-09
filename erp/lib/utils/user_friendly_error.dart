import 'dart:convert';
import 'dart:io';

/// Converte erros técnicos em mensagens claras para o usuário.
class UserFriendlyError {
  static const _knownMessages = <String, String>{
    'Senha inválida': 'Senha incorreta. Verifique e tente novamente.',
    'Usuário não encontrado': 'E-mail não cadastrado ou incorreto.',
    'Token de acesso não fornecido': 'Sessão expirada. Faça login novamente.',
    'Token inválido': 'Sessão inválida. Faça login novamente.',
    'Usuário não encontrado.': 'E-mail não cadastrado ou incorreto.',
    'Erro no login': 'Não foi possível entrar. Verifique e-mail e senha.',
    'Erro no registro': 'Não foi possível criar a conta. Tente novamente.',
    'Erro interno do servidor': 'Ocorreu um erro no servidor. Tente novamente em instantes.',
    'Acesso negado: requer permissão de administrador ou desenvolvedor':
        'Você não tem permissão para esta ação.',
    'Acesso negado: requer permissão de desenvolvedor':
        'Você não tem permissão para esta ação.',
    'Acesso negado: escola diferente da sua':
        'Você não tem acesso a estes dados.',
    'Usuário não tem escola associada': 'Conta sem escola vinculada. Contate o administrador.',
    'Já existe uma nota desse tipo para este aluno, disciplina e período.':
        'Este aluno já possui uma nota deste tipo neste período.',
    'Disciplina não encontrada': 'Matéria não encontrada.',
    'Turma não encontrada': 'Turma não encontrada.',
    'Professor não encontrado': 'Professor não encontrado.',
    'Estudante não encontrado': 'Aluno não encontrado.',
    'Arquivo não enviado. Use o campo "file".': 'Selecione um arquivo para enviar.',
    'Arquivo não encontrado': 'Arquivo não encontrado.',
  };

  /// Extrai mensagem amigável de qualquer erro capturado.
  static String message(
    dynamic error, {
    String fallback = 'Não foi possível completar a operação. Tente novamente.',
  }) {
    if (error == null) return fallback;

    var raw = _extractRawMessage(error);
    raw = _unwrapNestedMessages(raw);

    if (raw.isEmpty) return fallback;

    final mapped = _knownMessages[raw] ?? _knownMessages[raw.trim()];
    if (mapped != null) return mapped;

    if (_isNetworkError(raw, error)) {
      return 'Não foi possível conectar ao servidor. Verifique sua internet e tente novamente.';
    }

    if (_isTimeout(raw, error)) {
      return 'A conexão demorou muito. Tente novamente.';
    }

    if (_looksTechnical(raw)) {
      return fallback;
    }

    if (RegExp(r':\s*\d{3}$').hasMatch(raw)) {
      return fallback;
    }

    return raw;
  }

  /// Extrai mensagem de erro de resposta HTTP JSON da API.
  static String fromHttpBody(String body, {String fallback = 'Operação não concluída.'}) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final apiError = decoded['error'] ?? decoded['message'];
        if (apiError != null) {
          return message(apiError, fallback: fallback);
        }
      }
    } catch (_) {}
    return fallback;
  }

  static String _extractRawMessage(dynamic error) {
    if (error is String) return error.trim();

    if (error is Exception || error is Error) {
      return error.toString().trim();
    }

    return error.toString().trim();
  }

  static String _unwrapNestedMessages(String raw) {
    var message = raw;

    const prefixes = [
      'Exception: ',
      'Erro de conexão: ',
      'Erro HTTP: ',
      'FormatException: ',
      'ClientException: ',
      'HandshakeException: ',
      'SocketException: ',
      'TimeoutException: ',
    ];

    var changed = true;
    while (changed) {
      changed = false;
      for (final prefix in prefixes) {
        if (message.startsWith(prefix)) {
          message = message.substring(prefix.length).trim();
          changed = true;
        }
      }
    }

    return message;
  }

  static bool _isNetworkError(String raw, dynamic error) {
    if (error is SocketException) return true;
    final lower = raw.toLowerCase();
    return lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('network is unreachable') ||
        lower.contains('connection refused') ||
        lower.contains('connection reset') ||
        lower.contains('clientexception');
  }

  static bool _isTimeout(String raw, dynamic error) {
    final type = error.runtimeType.toString().toLowerCase();
    if (type.contains('timeout')) return true;
    return raw.toLowerCase().contains('timeout');
  }

  static bool _looksTechnical(String raw) {
    final lower = raw.toLowerCase();
    return lower.contains('exception') ||
        lower.contains('stacktrace') ||
        lower.contains('dart:') ||
        lower.contains('package:') ||
        lower.contains('type \'') ||
        lower.contains('null check operator') ||
        raw.length > 160;
  }
}

/// Atalho para uso em catch blocks e SnackBars.
String userErrorMessage(dynamic error, {String? fallback}) {
  return UserFriendlyError.message(
    error,
    fallback: fallback ?? 'Não foi possível completar a operação. Tente novamente.',
  );
}
