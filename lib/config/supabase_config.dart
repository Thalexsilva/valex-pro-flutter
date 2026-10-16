import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const passwordRecoveryRedirect = 'https://valexapp.vercel.app/';
  static bool openedFromAuthCallback = false;

  static bool isRecoveryCallback(Uri uri) {
    try {
      final parameters = {
        ...uri.queryParameters,
        ...Uri.splitQueryString(uri.fragment),
      };
      return parameters['type'] == 'recovery' ||
          parameters.containsKey('error') ||
          parameters.containsKey('error_code');
    } on FormatException {
      return false;
    }
  }

  /// Backend hospedado usado quando nenhum `--dart-define` é informado.
  /// A chave publicável é feita para o cliente; o acesso é protegido por RLS.
  static const String _defaultUrl = 'https://xnyqgrzztkifkxuulnai.supabase.co';
  static const String _defaultPublishableKey =
      'sb_publishable_1oycxtJsc1zC9Lt4jTxDjg_TBbZlKZ4';

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: _defaultUrl,
  );

  static const String _legacyAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: _defaultPublishableKey,
  );

  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: _legacyAnonKey,
  );

  /// Lets end-to-end tests run the real repositories against an in-memory
  /// backend without compiling the beta credentials into the test binary.
  @visibleForTesting
  static bool? debugIsConfiguredOverride;

  static bool get isConfigured {
    final override = debugIsConfiguredOverride;
    if (override != null) return override;
    final uri = Uri.tryParse(url);
    // HTTPS sempre; HTTP apenas para o Supabase local (`supabase start`).
    final isLocalHost =
        uri != null && (uri.host == 'localhost' || uri.host == '127.0.0.1');
    return uri != null &&
        (uri.scheme == 'https' || (uri.scheme == 'http' && isLocalHost)) &&
        uri.host.isNotEmpty &&
        !url.contains('xyzcompany.supabase.co') &&
        publishableKey.trim().isNotEmpty &&
        !publishableKey.contains('dummy_anon_key');
  }

  static bool get isInitialized {
    try {
      client;
      return true;
    } catch (_) {
      return false;
    }
  }

  static bool get hasAuthenticatedUser {
    try {
      return client.auth.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    // The SDK consumes the callback before runApp and clears its URL tokens.
    openedFromAuthCallback = isRecoveryCallback(Uri.base);
    if (!isConfigured) return;
    try {
      await Supabase.initialize(
        url: url,
        publishableKey: publishableKey,
        // Require a fresh login when the app is opened or the page is reloaded.
        authOptions: const FlutterAuthClientOptions(
          localStorage: EmptyLocalStorage(),
          // Recovery links may be opened in a different browser or from Android.
          // This client-only flow does not require the requesting device's PKCE verifier.
          authFlowType: AuthFlowType.implicit,
        ),
        debug: false,
      );
    } catch (_) {
      // The login screen remains available to explain initialization failures.
    }
  }
}
