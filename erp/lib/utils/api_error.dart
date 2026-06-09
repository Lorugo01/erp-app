import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'user_friendly_error.dart';

/// Lança exceção com mensagem vinda do corpo JSON da API.
Never throwApiResponseError(
  http.Response response, {
  String fallback = 'Não foi possível completar a operação.',
}) {
  final message = UserFriendlyError.fromHttpBody(response.body, fallback: fallback);
  throw Exception(message);
}

/// Repassa exceções da API; converte erros de rede em mensagens amigáveis.
Never rethrowServiceError(
  dynamic error, {
  String fallback = 'Não foi possível completar a operação. Tente novamente.',
}) {
  if (error is Exception) {
    final msg = UserFriendlyError.message(error, fallback: fallback);
    if (msg != error.toString().replaceFirst('Exception: ', '')) {
      throw Exception(msg);
    }
    throw error;
  }

  debugPrint('❌ Erro de serviço: $error');
  throw Exception(UserFriendlyError.message(error, fallback: fallback));
}

/// Tenta ler campo `error` de um corpo JSON.
String? parseApiErrorField(String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map) {
      final value = decoded['error'] ?? decoded['message'];
      if (value != null) return value.toString();
    }
  } catch (_) {}
  return null;
}
