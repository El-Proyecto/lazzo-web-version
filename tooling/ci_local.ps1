# tool/ci_local.ps1
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# 0) Checks rápidos
flutter --version
java -version

# 1) Dependências
flutter clean
flutter pub get

# 2) Lint
flutter analyze --no-fatal-infos --no-fatal-warnings

# 3) Format (não altera ficheiros; falha se necessário)
dart format --set-exit-if-changed .

# 4) Tests + cobertura
flutter test --coverage

# 5) Build APK debug (DEV)
if (-not $env:SUPABASE_URL_DEV) { throw "Missing env var SUPABASE_URL_DEV" }
if (-not $env:SUPABASE_ANON_KEY_DEV) { throw "Missing env var SUPABASE_ANON_KEY_DEV" }

# cria o ficheiro de env de dev
New-Item -Force -ItemType Directory -Path "env" | Out-Null
'{"APP_ENV":"dev"}' | Out-File -NoNewline -Encoding utf8 "env/dev.json"

flutter build apk --debug `
  --dart-define-from-file=env/dev.json `
  --dart-define=SUPABASE_URL=$env:SUPABASE_URL_DEV `
  --dart-define=SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY_DEV

Write-Host ""
Write-Host "✅ Done."
Write-Host "Coverage:   coverage/lcov.info"
Write-Host "APK (dev):  build/app/outputs/flutter-apk/app-debug.apk"
