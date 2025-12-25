enum AppEnv { env, prod }

class AppEnvironment {
  static const String _raw =
      String.fromEnvironment('APP_ENV', defaultValue: 'dev');
  static final AppEnv env = _raw == 'prod' ? AppEnv.prod : AppEnv.env;
  static String get docId => env == AppEnv.prod ? 'prod' : 'dev';
}
