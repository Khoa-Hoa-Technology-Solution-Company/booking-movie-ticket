class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue:
        'https://fmwyrnigzclskqcjxsos.supabase.co', // Thay thế bằng URL của bạn nếu không dùng --dart-define
  );
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZtd3lybmlnemNsc2txY2p4c29zIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE2MTI2NjgsImV4cCI6MjA5NzE4ODY2OH0.D_xTZcdSHnGd-VapSYJvsrn1nohPjqSOongZxqNrsnQ',
  );
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '990502611471-4vsjobbtp4m7ks3rjeih4ml363j797lv.apps.googleusercontent.com',
  );
}
