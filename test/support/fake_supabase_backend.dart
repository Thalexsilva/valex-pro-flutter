import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:valex_app/config/supabase_config.dart';

/// In-memory PostgREST/Auth/Storage/Functions double used by the end-to-end
/// route tests. It understands the subset of the REST protocol that the app
/// repositories use: equality/in/ilike filters, ordering, limits, single and
/// maybe-single reads, inserts, upserts, patches, deletes and RPC calls.
class FakeSupabaseBackend {
  FakeSupabaseBackend({
    this.userId = 'trainer-1',
    this.email = 'treinador@example.com',
    Map<String, dynamic>? userMetadata,
  }) : userMetadata = userMetadata ?? {'name': 'Profa. Teste'};

  String userId;
  String email;
  Map<String, dynamic> userMetadata;

  final Map<String, List<Map<String, dynamic>>> tables = {};
  final List<http.Request> requests = [];

  /// Every REST/RPC/function request fails with 503 while true.
  bool failAll = false;

  /// Requests to these tables (or `rpc/<name>`, `functions/<name>`) fail.
  final Set<String> failing = {};

  /// Optional RPC implementations keyed by function name.
  final Map<String, Object? Function(Map<String, dynamic> params)> rpcs = {};

  /// Optional edge function implementations keyed by function name.
  final Map<String, Object? Function(Map<String, dynamic> body)> functions = {};

  int _ids = 0;

  List<Map<String, dynamic>> table(String name) =>
      tables.putIfAbsent(name, () => []);

  void seed(String name, List<Map<String, dynamic>> rows) {
    table(name).addAll(rows.map((row) => Map<String, dynamic>.from(row)));
  }

  Iterable<http.Request> writesTo(String name) => requests.where(
    (request) =>
        request.url.path.endsWith('/rest/v1/$name') && request.method != 'GET',
  );

  Map<String, dynamic> get _user => {
    'id': userId,
    'aud': 'authenticated',
    'role': 'authenticated',
    'email': email,
    'email_confirmed_at': '2026-01-01T00:00:00Z',
    'app_metadata': <String, dynamic>{},
    'user_metadata': userMetadata,
    'created_at': '2026-01-01T00:00:00Z',
  };

  Map<String, dynamic> get _session => {
    'access_token': 'token-$userId',
    'refresh_token': 'refresh-$userId',
    'expires_in': 3600,
    'token_type': 'bearer',
    'user': _user,
  };

  http.Response _json(Object? body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  http.Response _failure() =>
      _json({'message': 'service unavailable', 'code': '503'}, 503);

  Future<http.Response> handle(http.Request request) async {
    final response = _route(request);
    return http.Response.bytes(
      response.bodyBytes,
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }

  http.Response _route(http.Request request) {
    requests.add(request);
    final path = request.url.path;
    if (path.startsWith('/auth/v1/')) return _auth(request);
    if (path.startsWith('/storage/v1/')) return _storage(request);
    if (path.startsWith('/functions/v1/')) {
      final name = path.substring('/functions/v1/'.length);
      if (failAll || failing.contains('functions/$name')) return _failure();
      final handler = functions[name];
      if (handler == null) return _json({'error': 'not found'}, 404);
      final body = request.body.isEmpty
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(jsonDecode(request.body) as Map);
      return _json(handler(body));
    }
    if (path.startsWith('/rest/v1/rpc/')) {
      final name = path.substring('/rest/v1/rpc/'.length);
      if (failAll || failing.contains('rpc/$name')) return _failure();
      final handler = rpcs[name];
      if (handler == null) {
        return _json({'message': 'function not found'}, 404);
      }
      // RPC sem parâmetros envia o corpo `null`.
      final decoded = request.body.isEmpty ? null : jsonDecode(request.body);
      final params = decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};
      return _json(handler(params));
    }
    if (path.startsWith('/rest/v1/')) return _rest(request);
    return _json({'message': 'unknown route $path'}, 404);
  }

  http.Response _auth(http.Request request) {
    final path = request.url.path;
    if (path.endsWith('/logout')) return http.Response('', 204);
    if (path.endsWith('/token')) return _json(_session);
    if (path.endsWith('/user')) {
      if (request.method == 'PUT' && request.body.isNotEmpty) {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final data = body['data'];
        if (data is Map) userMetadata = {...userMetadata, ...data};
      }
      return _json(_user);
    }
    if (path.endsWith('/recover')) return _json({});
    return _json(_session);
  }

  http.Response _storage(http.Request request) {
    if (failAll || failing.contains('storage')) return _failure();
    final path = request.url.path;
    if (path.contains('/object/sign/')) {
      final key = path.split('/object/sign/').last;
      return _json({'signedURL': '/object/sign/$key?token=test'});
    }
    if (request.method == 'DELETE') return _json([]);
    return _json({'Key': path.split('/object/').last, 'Id': 'obj-${_ids++}'});
  }

  http.Response _rest(http.Request request) {
    final name = request.url.path.substring('/rest/v1/'.length);
    if (failAll || failing.contains(name)) return _failure();
    final rows = table(name);
    final params = request.url.queryParametersAll;
    final matches = rows.where((row) => _matches(row, params)).toList();

    switch (request.method) {
      case 'GET':
      case 'HEAD':
        var result = [...matches];
        _order(result, request.url.queryParameters['order']);
        final offset = int.tryParse(
          request.url.queryParameters['offset'] ?? '',
        );
        if (offset != null) result = result.skip(offset).toList();
        final limit = int.tryParse(request.url.queryParameters['limit'] ?? '');
        if (limit != null) result = result.take(limit).toList();
        return _respond(request, result);
      case 'POST':
        final decoded = jsonDecode(request.body);
        final incoming = decoded is List
            ? decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList()
            : [Map<String, dynamic>.from(decoded as Map)];
        final merge = (request.headers['Prefer'] ?? '').contains(
          'merge-duplicates',
        );
        final conflict = (request.url.queryParameters['on_conflict'] ?? 'id')
            .split(',')
            .map((e) => e.trim())
            .toList();
        final written = <Map<String, dynamic>>[];
        for (final row in incoming) {
          row.putIfAbsent('id', () => 'gen-${name.hashCode}-${_ids++}');
          row.putIfAbsent(
            'created_at',
            () => DateTime.now().toUtc().toIso8601String(),
          );
          final existing = rows.indexWhere(
            (current) =>
                conflict.every((column) => current[column] == row[column]),
          );
          if (existing >= 0 && merge) {
            rows[existing] = {...rows[existing], ...row};
            written.add(rows[existing]);
          } else if (existing >= 0 && conflict.contains('id')) {
            return _json({
              'message': 'duplicate key value violates unique constraint',
              'code': '23505',
            }, 409);
          } else {
            rows.add(row);
            written.add(row);
          }
        }
        return _respond(request, written, status: 201);
      case 'PATCH':
        final patch = Map<String, dynamic>.from(jsonDecode(request.body));
        for (final row in matches) {
          row.addAll(patch);
        }
        return _respond(request, matches);
      case 'DELETE':
        rows.removeWhere(matches.contains);
        return _respond(request, matches);
    }
    return _json({'message': 'method not allowed'}, 405);
  }

  http.Response _respond(
    http.Request request,
    List<Map<String, dynamic>> rows, {
    int status = 200,
  }) {
    final wantsObject = (request.headers['Accept'] ?? '').contains(
      'vnd.pgrst.object',
    );
    final prefer = request.headers['Prefer'] ?? '';
    if (request.method != 'GET' &&
        !prefer.contains('return=representation') &&
        !wantsObject) {
      return http.Response('', status == 201 ? 201 : 204);
    }
    if (wantsObject) {
      if (rows.length != 1) {
        return _json({
          'code': 'PGRST116',
          'message': 'JSON object requested, multiple (or no) rows returned',
          'details': 'Results contain ${rows.length} rows',
        }, 406);
      }
      return _json(rows.single, status);
    }
    return _json(rows, status);
  }

  static const _reserved = {
    'select',
    'order',
    'limit',
    'offset',
    'on_conflict',
    'columns',
  };

  bool _matches(Map<String, dynamic> row, Map<String, List<String>> params) {
    for (final entry in params.entries) {
      if (_reserved.contains(entry.key)) continue;
      for (final raw in entry.value) {
        if (!_filter(row[entry.key], raw)) return false;
      }
    }
    return true;
  }

  bool _filter(Object? value, String raw) {
    final dot = raw.indexOf('.');
    if (dot < 0) return true;
    final op = raw.substring(0, dot);
    final operand = raw.substring(dot + 1);
    final text = value?.toString();
    switch (op) {
      case 'eq':
        return text == operand;
      case 'neq':
        return text != operand;
      case 'is':
        return operand == 'null' ? value == null : text == operand;
      case 'in':
        final inner = operand.replaceAll(RegExp(r'^\(|\)$'), '');
        final values = inner
            .split(',')
            .map((e) => e.trim().replaceAll('"', ''))
            .toSet();
        return values.contains(text);
      case 'ilike':
      case 'like':
        final pattern = RegExp(
          '^${RegExp.escape(operand).replaceAll('%', '.*').replaceAll(r'\*', '.*')}\$',
          caseSensitive: op == 'like',
        );
        return text != null && pattern.hasMatch(text);
      case 'gte':
        return text != null && text.compareTo(operand) >= 0;
      case 'lte':
        return text != null && text.compareTo(operand) <= 0;
      case 'gt':
        return text != null && text.compareTo(operand) > 0;
      case 'lt':
        return text != null && text.compareTo(operand) < 0;
    }
    return true;
  }

  void _order(List<Map<String, dynamic>> rows, String? order) {
    if (order == null || order.isEmpty) return;
    final parts = order.split(',').first.split('.');
    final column = parts.first;
    final descending = parts.contains('desc');
    rows.sort((a, b) {
      final left = a[column]?.toString() ?? '';
      final right = b[column]?.toString() ?? '';
      return descending ? right.compareTo(left) : left.compareTo(right);
    });
  }

  /// Initializes the global Supabase client against this backend and signs in.
  Future<void> start({bool signIn = true}) async {
    SupabaseConfig.debugIsConfiguredOverride = true;
    await Supabase.initialize(
      url: 'https://fake.supabase.co',
      publishableKey: 'test-key',
      debug: false,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.implicit,
        autoRefreshToken: false,
        localStorage: EmptyLocalStorage(),
        detectSessionInUri: false,
      ),
      httpClient: MockClient(handle),
    );
    if (signIn) {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: 'test-password',
      );
    }
  }

  Future<void> stop() async {
    SupabaseConfig.debugIsConfiguredOverride = null;
    try {
      await Supabase.instance.dispose();
    } catch (_) {}
  }
}
