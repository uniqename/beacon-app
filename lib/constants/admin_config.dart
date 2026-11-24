/// Admin settings for the app.
///
/// Nothing secret is stored in this file. Secrets are passed at build time with
/// --dart-define, so they never go into git and are not bundled unless you pass them.
///
/// Example (local testing only, never for store builds):
///   flutter run --dart-define=SUPABASE_SERVICE_ROLE_KEY=... --dart-define=ADMIN_ALLOWED_EMAILS=a@b.com
///
/// Store builds without these values: admin sign-up by secret code is disabled,
/// and the service-role admin calls (such as deleting an auth user) return an error.
class AdminConfig {
  AdminConfig._();

  /// Public project URL. Safe to ship.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://mloatbnakkjbmsrvzybk.supabase.co',
  );

  /// Service-role key. Empty unless passed with --dart-define. Do not ship in store builds.
  static const String supabaseServiceRoleKey = String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY');

  /// Maximum number of admin accounts that can be created.
  static const int maxAdminAccounts = int.fromEnvironment('MAX_ADMIN_ACCOUNTS', defaultValue: 5);

  static const String _secretCode = String.fromEnvironment('ADMIN_SECRET_CODE');
  static const String _allowedEmails = String.fromEnvironment('ADMIN_ALLOWED_EMAILS');

  /// True only when a secret code is configured and the input matches it.
  static bool validateSecretCode(String code) {
    return _secretCode.isNotEmpty && code == _secretCode;
  }

  /// True only when the email is in the configured allow-list.
  static bool isAllowedAdminEmail(String email) {
    final target = email.trim().toLowerCase();
    return _allowedList().contains(target);
  }

  /// Same allow-list as [isAllowedAdminEmail]. Kept separate for existing callers.
  static bool isPreApprovedEmail(String email) => isAllowedAdminEmail(email);

  static List<String> _allowedList() {
    if (_allowedEmails.isEmpty) return const [];
    return _allowedEmails.split(',').map((e) => e.trim().toLowerCase()).where((e) => e.isNotEmpty).toList();
  }
}
