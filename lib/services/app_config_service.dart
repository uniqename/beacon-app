import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/org_config.dart';

/// Singleton that holds the active [OrgConfig] and persists the user's
/// country/org selection across app launches.
///
/// Usage:
///   AppConfigService.instance.config   → current OrgConfig
///   AppConfigService.instance.setConfig('us')  → switch to US
class AppConfigService extends ChangeNotifier {
  static final AppConfigService _instance = AppConfigService._internal();
  static AppConfigService get instance => _instance;
  AppConfigService._internal();

  static const _prefKey = 'selected_org_key';

  OrgConfig _config = ghanaConfig; // default until loaded
  bool _loaded = false;

  OrgConfig get config => _config;
  bool get isLoaded => _loaded;
  bool get needsSelection => _loaded && !_hasExplicitSelection;
  bool _hasExplicitSelection = false;

  /// Call once at app startup. Returns true if the user has already made a
  /// selection (no picker needed), false if the picker should be shown.
  Future<bool> load() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(_prefKey);
    if (key != null && allConfigs.containsKey(key)) {
      _config = allConfigs[key]!;
      _hasExplicitSelection = true;
    } else {
      _hasExplicitSelection = false;
      // Default to Ghana for existing installs (preserve existing behaviour)
      _config = ghanaConfig;
    }
    _loaded = true;
    notifyListeners();
    return _hasExplicitSelection;
  }

  /// Persists and activates the chosen org config.
  Future<void> setConfig(String orgKey) async {
    final cfg = allConfigs[orgKey];
    if (cfg == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, orgKey);
    _config = cfg;
    _hasExplicitSelection = true;
    notifyListeners();
  }
}
