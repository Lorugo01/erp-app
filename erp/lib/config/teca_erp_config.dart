import '../config/environment.dart';

/// Endpoints da API de locação Teca (`/erp`).
class TecaErpConfig {
  TecaErpConfig._();

  static String get baseUrl => EnvironmentConfig.tecaErpBaseUrl;

  static int get requestTimeout => EnvironmentConfig.tecaErpRequestTimeout;

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static String itensUrl([String? query]) {
    final base = EnvironmentConfig.getTecaErpUrl('/itens');
    if (query == null || query.isEmpty) return base;
    return '$base?$query';
  }

  static String itemUrl(int id) => EnvironmentConfig.getTecaErpUrl('/itens/$id');

  static String alocacaoUrl(int id) =>
      EnvironmentConfig.getTecaErpUrl('/itens/$id/alocacao');

  static String armariosUrl() => EnvironmentConfig.getTecaErpUrl('/armarios');

  static String armarioUrl(String letra) =>
      EnvironmentConfig.getTecaErpUrl('/armarios/$letra');

  static String localizarUrl(String nome) {
    final q = Uri.encodeQueryComponent(nome);
    return EnvironmentConfig.getTecaErpUrl('/localizar?nome=$q');
  }
}
