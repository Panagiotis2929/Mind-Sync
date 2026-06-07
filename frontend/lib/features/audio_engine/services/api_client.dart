import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/neural_blueprint.dart';
import '../models/synthesis_parameters.dart';
import '../../../core/constants/dimensions.dart';

/// ApiException carries a typed API error from the backend.
class ApiException implements Exception {
  final String code;
  final String message;
  final int statusCode;

  const ApiException({
    required this.code,
    required this.message,
    required this.statusCode,
  });

  @override
  String toString() => 'ApiException[$statusCode] $code: $message';
}

/// MindSyncApiClient is the sole HTTP communication layer.
/// It is a pure service: no state, no side effects beyond HTTP calls.
class MindSyncApiClient {
  final http.Client _client;
  final String _baseUrl;

  MindSyncApiClient({http.Client? client})
      : _client = client ?? http.Client(),
        _baseUrl = '${MindSyncStrings.apiBaseUrl}/api/${MindSyncStrings.apiVersion}';

  // ── Blueprint endpoints ────────────────────────────────────────────────

  /// computeBlueprint sends synthesis parameters to the DSP engine
  /// and returns the computed mathematical audio specification.
  Future<NeuralBlueprint> computeBlueprint(SynthesisParameters params) async {
    final response = await _post('/blueprint/compute', params.toApiJson());
    final data = _unwrap(response);
    return NeuralBlueprint.fromJson(data as Map<String, dynamic>);
  }

  /// getFactoryPresets returns the hardcoded factory preset configurations.
  Future<List<Map<String, dynamic>>> getFactoryPresets() async {
    final response = await _get('/blueprint/presets');
    final data = _unwrap(response);
    return (data as List).cast<Map<String, dynamic>>();
  }

  // ── Signature endpoints ────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAllSignatures() async {
    final response = await _get('/signatures/');
    final data = _unwrap(response);
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createSignature(Map<String, dynamic> body) async {
    final response = await _post('/signatures/', body);
    return _unwrap(response) as Map<String, dynamic>;
  }

  Future<void> deleteSignature(String id) async {
    final uri = Uri.parse('$_baseUrl/signatures/$id/');
    final resp = await _client.delete(uri, headers: _headers());
    if (resp.statusCode != 204) {
      _throwApiError(resp);
    }
  }

  Future<void> toggleFavorite(String id) async {
    final uri = Uri.parse('$_baseUrl/signatures/$id/favorite');
    final resp = await _client.post(uri, headers: _headers());
    _throwIfError(resp);
  }

  // ── Session endpoints ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> startSession(Map<String, dynamic> body) async {
    final response = await _post('/sessions/', body);
    return _unwrap(response) as Map<String, dynamic>;
  }

  Future<void> finalizeSession(String id, double durationSec) async {
    final uri = Uri.parse('$_baseUrl/sessions/$id/finalize');
    final resp = await _client.patch(
      uri,
      headers: _headers(),
      body: jsonEncode({'duration_sec': durationSec}),
    );
    _throwIfError(resp);
  }

  Future<List<Map<String, dynamic>>> getRecentSessions({int limit = 20}) async {
    final response = await _get('/sessions/?limit=$limit');
    final data = _unwrap(response);
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getStats() async {
    final response = await _get('/sessions/stats');
    return _unwrap(response) as Map<String, dynamic>;
  }

  // ── Health check ───────────────────────────────────────────────────────

  Future<bool> checkHealth() async {
    try {
      final uri = Uri.parse('${MindSyncStrings.apiBaseUrl}/health');
      final resp = await _client.get(uri).timeout(const Duration(seconds: 3));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Private HTTP helpers ───────────────────────────────────────────────

  Map<String, String> _headers() => {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept':       'application/json',
  };

  Future<http.Response> _get(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    return _client.get(uri, headers: _headers());
  }

  Future<http.Response> _post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_baseUrl$path');
    return _client.post(uri, headers: _headers(), body: jsonEncode(body));
  }

  /// _unwrap extracts the `data` field from a standard API envelope,
  /// throwing a typed ApiException for any non-2xx response.
  dynamic _unwrap(http.Response response) {
    _throwIfError(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['data'];
  }

  void _throwIfError(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    _throwApiError(response);
  }

  Never _throwApiError(http.Response response) {
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final error = json['error'] as Map<String, dynamic>?;
      throw ApiException(
        code:       error?['code'] as String? ?? 'UNKNOWN',
        message:    error?['message'] as String? ?? response.body,
        statusCode: response.statusCode,
      );
    } on FormatException {
      throw ApiException(
        code:       'PARSE_ERROR',
        message:    'Failed to parse server response',
        statusCode: response.statusCode,
      );
    }
  }
}
