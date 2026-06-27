import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String _hostKey = 'api_host';
  static const String _portKey = 'api_port';
  static const String _defaultHost = '127.0.0.1';
  static const int _defaultPort = 8420;

  String _host = _defaultHost;
  int _port = _defaultPort;
  bool _authenticated = false;

  ApiClient();

  String get baseUrl => 'http://$_host:$_port/api';
  String get wsUrl => 'ws://$_host:$_port/api/runtime-stream';
  String get host => _host;
  int get port => _port;
  bool get isAuthenticated => _authenticated;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _host = prefs.getString(_hostKey) ?? _defaultHost;
    _port = prefs.getInt(_portKey) ?? _defaultPort;
  }

  Future<void> saveSettings(String host, int port) async {
    _host = host;
    _port = port;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_hostKey, host);
    await prefs.setInt(_portKey, port);
  }

  Map<String, String> _headers() {
    return {'Content-Type': 'application/json', 'X-OBC-Auth': '1'};
  }

  Future<Map<String, dynamic>> get(String path, {int? timeout}) async {
    final uri = Uri.parse('$baseUrl$path');
    final client = http.Client();
    try {
      final res = await client.get(uri, headers: _headers()).timeout(Duration(seconds: timeout ?? 10));
      if (res.statusCode == 401) _authenticated = false;
      if (res.statusCode >= 400) throw ApiException(res.statusCode, res.body);
      return jsonDecode(res.body);
    } finally {
      client.close();
    }
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body, int? timeout}) async {
    final uri = Uri.parse('$baseUrl$path');
    final client = http.Client();
    try {
      final res = await client.post(uri, headers: _headers(), body: body != null ? jsonEncode(body) : null)
          .timeout(Duration(seconds: timeout ?? 10));
      if (res.statusCode == 401) _authenticated = false;
      if (res.statusCode >= 400) throw ApiException(res.statusCode, res.body);
      return jsonDecode(res.body);
    } finally {
      client.close();
    }
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final client = http.Client();
    try {
      final res = await client.delete(uri, headers: _headers()).timeout(const Duration(seconds: 10));
      if (res.statusCode == 401) _authenticated = false;
      if (res.statusCode >= 400) throw ApiException(res.statusCode, res.body);
      return res.body.isNotEmpty ? jsonDecode(res.body) : {};
    } finally {
      client.close();
    }
  }

  Future<bool> checkHealth({String? overrideHost, int? overridePort}) async {
    try {
      final h = overrideHost ?? _host;
      final p = overridePort ?? _port;
      final uri = Uri.parse('http://$h:$p/api/health');
      final client = http.Client();
      try {
        final res = await client.get(uri, headers: {'X-OBC-Auth': '1'}).timeout(const Duration(seconds: 5));
        return res.statusCode == 200;
      } finally {
        client.close();
      }
    } catch (_) {
      return false;
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;
  ApiException(this.statusCode, this.body);
  @override
  String toString() => 'ApiException($statusCode): $body';
}
