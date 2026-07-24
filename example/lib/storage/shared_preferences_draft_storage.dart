import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_form_fields/smart_form_fields.dart';

/// Persists example drafts across route changes and application restarts.
final class SharedPreferencesDraftStorage implements SmartDraftStorage {
  const SharedPreferencesDraftStorage({
    this.keyPrefix = 'smart_form_fields.draft.',
  });

  final String keyPrefix;

  String _key(String id) => '$keyPrefix$id';

  @override
  Future<String?> read(String id) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_key(id));
  }

  @override
  Future<void> write(String id, String payload) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key(id), payload);
  }

  @override
  Future<void> delete(String id) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_key(id));
  }
}
