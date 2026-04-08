// Credentials are injected at build time via --dart-define.
// For local development, set these in your IDE run configuration or .env file.
// See .env.example for the required variable names.
// Do NOT hardcode real values here.
class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
}
