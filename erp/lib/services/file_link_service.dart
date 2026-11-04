import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../config/api_config.dart';

/// Abre anexos da API. Anexos de atividades, entregas e chat exigem um link
/// assinado e temporário, pedido em POST /storage/sign antes de abrir.
class FileLinkService {
  static Future<void> open(BuildContext context, String? fileUrl) async {
    final path = fileUrl?.trim() ?? '';
    var opened = false;
    if (path.isNotEmpty) {
      try {
        final signed = await _sign(path);
        final uri = Uri.parse('${ApiConfig.baseUrl}$signed');
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint('Falha ao abrir anexo: $e');
      }
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o arquivo'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static Future<String> _sign(String fileUrl) async {
    final token = ApiConfig.sessionToken;
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/storage/sign'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'fileUrl': fileUrl}),
    );
    if (response.statusCode != 200) {
      throw Exception('Erro ao gerar link do arquivo (${response.statusCode})');
    }
    return (jsonDecode(response.body) as Map<String, dynamic>)['url'] as String;
  }
}
