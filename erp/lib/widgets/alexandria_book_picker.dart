import 'dart:async';

import 'package:flutter/material.dart';

import '../services/alexandria_service.dart';
import '../utils/user_friendly_error.dart';

/// Diálogo de busca no catálogo do Alexandria. Retorna o livro escolhido.
Future<AlexandriaBook?> showAlexandriaBookPicker(BuildContext context) {
  return showDialog<AlexandriaBook>(
    context: context,
    builder: (_) => const _AlexandriaBookPickerDialog(),
  );
}

class _AlexandriaBookPickerDialog extends StatefulWidget {
  const _AlexandriaBookPickerDialog();

  @override
  State<_AlexandriaBookPickerDialog> createState() =>
      _AlexandriaBookPickerDialogState();
}

class _AlexandriaBookPickerDialogState
    extends State<_AlexandriaBookPickerDialog> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<AlexandriaBook> _results = [];
  bool _loading = false;
  String? _error;
  int _searchGeneration = 0;

  // Acervo da escola, buscado uma vez ao abrir o diálogo
  late final Future<int?> _acervoId = AlexandriaService.schoolAcervoId()
      .catchError((Object _) => null);

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(value));
  }

  Future<void> _search(String query) async {
    final generation = ++_searchGeneration;
    if (query.trim().length < 2) {
      setState(() {
        _results = [];
        _error = null;
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await AlexandriaService.searchBooks(
        query,
        acervoId: await _acervoId,
      );
      if (!mounted || generation != _searchGeneration) return;
      setState(() => _results = results);
    } catch (e) {
      if (!mounted || generation != _searchGeneration) return;
      setState(() => _error = userErrorMessage(e));
    } finally {
      if (mounted && generation == _searchGeneration) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Livro do Alexandria'),
      content: SizedBox(
        width: 420,
        height: 420,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Buscar por título ou autor',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _onQueryChanged,
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildResults()),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }

  Widget _buildResults() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }
    if (_results.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.trim().length < 2
              ? 'Digite ao menos 2 letras.'
              : 'Nenhum livro encontrado.',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }
    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final book = _results[index];
        return ListTile(
          leading: AlexandriaBookCover(url: book.coverUrl),
          title: Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: book.author.isEmpty ? null : Text(book.author),
          onTap: () => Navigator.of(context).pop(book),
        );
      },
    );
  }
}

/// Capa pequena de livro do Alexandria (decodificada no tamanho exibido).
class AlexandriaBookCover extends StatelessWidget {
  final String? url;
  final double width;
  final double height;

  const AlexandriaBookCover({
    super.key,
    required this.url,
    this.width = 40,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: const Icon(Icons.menu_book, color: Colors.grey),
    );
    final src = url ?? '';
    if (src.isEmpty) return placeholder;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        src,
        width: width,
        height: height,
        fit: BoxFit.cover,
        cacheWidth: (width * dpr).round(),
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }
}
