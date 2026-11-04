import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../config/api_config.dart';
import '../config/environment.dart';

/// Livro do catálogo do Alexandria.
class AlexandriaBook {
  final String id;
  final String title;
  final String author;
  final String coverUrl;

  const AlexandriaBook({
    required this.id,
    required this.title,
    required this.author,
    required this.coverUrl,
  });

  factory AlexandriaBook.fromJson(Map<String, dynamic> json) {
    return AlexandriaBook(
      id: '${json['id'] ?? ''}',
      title: '${json['book_title'] ?? ''}',
      author: '${json['author_name'] ?? ''}',
      coverUrl: '${json['book_cover_img'] ?? ''}',
    );
  }
}

/// Integração com o app Alexandria: busca no catálogo e abertura do livro
/// no app instalado no tablet (`alexandria://livro/<id>`).
class AlexandriaService {
  static Future<List<AlexandriaBook>> searchBooks(
    String query, {
    int? acervoId,
  }) async {
    final text = query.trim();
    if (text.length < 2) return [];
    final uri = Uri.parse(EnvironmentConfig.alexandriaApiUrl).replace(
      queryParameters: {
        'method_name': 'search_text',
        'search_text': text,
        // Mesmo filtro que o Alexandria usa a partir da conta do tablet
        if (acervoId != null) 'acervo_id': '$acervoId',
      },
    );
    final response = await http
        .get(uri)
        .timeout(Duration(seconds: EnvironmentConfig.apiRequestTimeout));
    if (response.statusCode != 200) {
      throw Exception('Erro ao buscar livros (${response.statusCode})');
    }
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final rows = data is Map ? data['EBOOK_APP'] : null;
    if (rows is! List) return [];
    return rows
        .whereType<Map>()
        .map((row) => AlexandriaBook.fromJson(Map<String, dynamic>.from(row)))
        .where((book) => book.id.isNotEmpty && book.title.isNotEmpty)
        .toList();
  }

  /// Acervo configurado para a escola do usuário (null = catálogo inteiro).
  static Future<int?> schoolAcervoId() async {
    final schoolId = _schoolIdProvider?.call();
    if (schoolId == null || schoolId.isEmpty) return null;
    final token = ApiConfig.sessionToken;
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/schools/$schoolId/integration'),
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200) return null;
    return int.tryParse(
      '${jsonDecode(response.body)['alexandriaAcervoId'] ?? ''}',
    );
  }

  /// Escola da sessão atual, definida pelo AuthProvider.
  static String? Function()? _schoolIdProvider;
  static set schoolIdProvider(String? Function() provider) =>
      _schoolIdProvider = provider;

  static Uri bookLink(String bookId) => Uri.parse('alexandria://livro/$bookId');

  /// Abre o livro no Alexandria. Retorna false se o app não estiver instalado.
  static Future<bool> openBook(String bookId) async {
    try {
      return await launchUrl(
        bookLink(bookId),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }
}
