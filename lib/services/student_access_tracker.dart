import 'package:flutter/foundation.dart';

import '../config/supabase_config.dart';

/// Called only after a signed-in account has been resolved to an active student.
/// The server obtains the IP and approximate network location from the request.
class StudentAccessTracker {
  Future<void> recordLogin() async {
    if (!SupabaseConfig.hasAuthenticatedUser) return;
    await SupabaseConfig.client.functions.invoke(
      'student_login_event',
      body: {
        'platform': kIsWeb ? 'Web' : defaultTargetPlatform.name,
        'time_zone': DateTime.now().timeZoneName,
      },
    );
  }
}
