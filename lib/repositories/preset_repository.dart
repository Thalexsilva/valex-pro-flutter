import 'package:valex_app/config/supabase_config.dart';
import 'package:valex_app/models/workout_model.dart';

class PresetRepository {
  /// Lista todos os presets customizados do treinador no Supabase
  Future<List<WorkoutSheet>> fetchPresets() async {
    try {
      final client = SupabaseConfig.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await client
          .from('custom_presets')
          .select()
          .eq('trainer_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((row) {
        final data = Map<String, dynamic>.from(row['sheet_data'] as Map);
        data['studentName'] = row['preset_title'];
        return WorkoutSheet.fromJson(data);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Exclui um preset do treinador no Supabase.
  Future<bool> deletePreset(String presetTitle) async {
    try {
      final client = SupabaseConfig.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return false;
      await client
          .from('custom_presets')
          .delete()
          .eq('trainer_id', userId)
          .eq('preset_title', presetTitle);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Salva um novo preset no Supabase
  Future<bool> savePreset(WorkoutSheet sheet, String presetTitle) async {
    try {
      final client = SupabaseConfig.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return false;

      final payload = {
        'trainer_id': userId,
        'preset_title': presetTitle,
        'sheet_data': sheet.toJson(),
      };

      await client.from('custom_presets').insert(payload);
      return true;
    } catch (_) {
      return false;
    }
  }
}
