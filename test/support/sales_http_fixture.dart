import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:valex_app/models/sales_model.dart';

Future<SupabaseClient> createSalesTestClient({
  bool failConversion = false,
}) async {
  final rows = <Map<String, dynamic>>[
    LeadItem(
      id: 'lead-test',
      name: 'Lead Teste',
      createdAt: '2026-09-01',
      updatedAt: '2026-09-01',
    ).toJson(),
  ];
  final client = SupabaseClient(
    'https://example.supabase.co',
    'test-key',
    authOptions: const AuthClientOptions(autoRefreshToken: false),
    httpClient: MockClient((request) async {
      dynamic body;
      if (request.url.path.startsWith('/auth/')) {
        body = {
          'access_token': 'test-token',
          'refresh_token': 'test-refresh',
          'token_type': 'bearer',
          'expires_in': 3600,
          'user': {
            'id': 'trainer-test',
            'aud': 'authenticated',
            'app_metadata': {},
            'user_metadata': {},
            'created_at': '2026-09-01T00:00:00Z',
          },
        };
      } else if (request.url.path.endsWith('/rpc/convert_lead_to_student')) {
        if (failConversion) {
          return http.Response(
            '{"message":"conversion failed"}',
            400,
            request: request,
          );
        }
        final params = jsonDecode(request.body) as Map<String, dynamic>;
        for (final row in rows) {
          if (row['id'] == params['p_lead_id']) row['status'] = 'won';
        }
        body = params['p_student'];
      } else if (request.method == 'POST') {
        final row = jsonDecode(request.body) as Map<String, dynamic>;
        rows.removeWhere((existing) => existing['id'] == row['id']);
        rows.add(row);
        body = row;
      } else if (request.method == 'DELETE') {
        final id = request.url.queryParameters['id']?.replaceFirst('eq.', '');
        rows.removeWhere((row) => row['id'] == id);
        body = [];
      } else {
        body = rows;
      }
      return http.Response(
        jsonEncode(body),
        200,
        request: request,
        headers: {'content-type': 'application/json'},
      );
    }),
  );
  await client.auth.signInWithPassword(
    email: 'trainer@example.com',
    password: 'test-password',
  );
  return client;
}
