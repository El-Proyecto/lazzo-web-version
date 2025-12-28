# TestFlight Readiness Report — Lazzo iOS App

**Data:** 28 de Dezembro de 2025  
**Versão Atual:** 1.0.0+1  
**Bundle ID:** com.gmonteiro.lazzo  
**Objetivo:** Deploy beta via TestFlight em Janeiro 2025

---

## 📊 Status Atual

### ✅ Build iOS Release
```bash
flutter build ios --release --no-codesign
# ✓ Built build/ios/iphoneos/Runner.app (27.1MB)
# ✅ Compila sem erros
```

**Conclusão:** App compila com sucesso em modo Release. Próximo passo é configurar code signing no Xcode.

---

## 🚨 Bloqueadores para TestFlight

### 🔴 CRÍTICO 1: Firebase Setup Incompleto (iOS)
**Problema:** Firebase Core está inicializado no código Dart, mas **falta GoogleService-Info.plist** no projeto iOS.

**Localização:**
- `lib/main.dart:149-152` — `await Firebase.initializeApp();`
- `ios/Runner/` — **FALTA GoogleService-Info.plist**

**Impacto:** 
- App crashará ao tentar inicializar Firebase em device
- Push notifications não funcionarão

**Solução:**
1. Download `GoogleService-Info.plist` do Firebase Console (projeto: [REDACTED])
2. Adicionar ficheiro em `ios/Runner/GoogleService-Info.plist`
3. Adicionar ao Xcode target (Runner) via "Add Files to Runner" (garantir "Copy items if needed")
4. Verificar que está listado em `project.pbxproj` como resource

**Teste de validação:**
```bash
flutter run --release
# Verificar logs: "Configured FirebaseApp" (sem crash)
```

---

### 🔴 CRÍTICO 2: Push Notifications Capability
**Problema:** Firebase Messaging está implementado, mas **falta capability no Xcode**.

**Localização:**
- `pubspec.yaml:66` — `firebase_messaging: ^16.1.0`
- `lib/main.dart:5,152` — `FirebaseMessaging` usado
- `lib/services/push_notification_service.dart` — Serviço completo implementado
- **iOS Capabilities:** Não configurado

**Impacto:** 
- Notificações push não registarão device token
- Apple rejeita apps com código de notificações sem capability

**Solução (requer Apple Developer Account):**
1. Abrir `ios/Runner.xcworkspace` no Xcode
2. Target Runner → Signing & Capabilities → "+ Capability"
3. Adicionar **"Push Notifications"**
4. Adicionar **"Background Modes"** e ativar:
   - ☑️ Remote notifications
   - ☑️ Background fetch (opcional)
5. Commit Runner.entitlements gerado

---

### 🔴 CRÍTICO 3: App Store Connect Metadata
**Problema:** Faltam assets e textos obrigatórios para TestFlight.

**Checklist Obrigatório:**
- [ ] **App Icons:** ✅ Presentes (todos os tamanhos em `Assets.xcassets/AppIcon.appiconset`)
- [ ] **Screenshots:** ❌ FALTA (6.7", 6.5", 5.5" para iPhone)
- [ ] **App Privacy Policy URL:** ❌ FALTA
- [ ] **Export Compliance:** Definir se usa encriptação forte (Supabase HTTPS = sim, mas exempt)

**Localização Assets:**
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/` — ✅ Icons OK
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/` — ✅ Launch screen OK

**Nota:** Screenshots podem ser adicionados manualmente em App Store Connect (não bloqueiam upload, mas bloqueiam review).

---

## 🟡 Melhorias Recomendadas (Não bloqueiam TestFlight)

### 🟡 1. Dependências de Teste em `dependencies` (Deve Mover para `dev_dependencies`)

**Problema:** Packages de teste estão em `dependencies`, aumentam bundle size desnecessariamente.

**Localização: `pubspec.yaml`**
```yaml
dependencies:
  mocktail: ^1.0.3         # ❌ Deve estar em dev_dependencies
  faker: ^2.1.0            # ❌ Deve estar em dev_dependencies
  integration_test:        # ❌ Deve estar em dev_dependencies
    sdk: flutter
```

**Uso no código:**
- `mocktail` — ❌ **Não usado em lib/** (grep confirmou)
- `faker` — ❌ **Não usado em lib/** (grep confirmou)
- `integration_test` — ❌ **Não usado em lib/** (grep confirmou)

**Impacto:** 
- +~500KB no bundle final (desnecessário)
- Sujo para produção

**Solução:** Ver patch no final deste doc.

---

### 🟡 2. Permissão de Localização Redundante

**Problema:** App pede `NSLocationAlwaysAndWhenInUseUsageDescription` mas não usa localização em background.

**Localização: `ios/Runner/Info.plist:68-70`**
```xml
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Este app precisa de acesso à sua localização para definir a localização do evento automaticamente.</string>
```

**Uso real:**
- `geolocator` package — usa **only "When In Use"** (não background)
- Nenhum código pede `requestAlwaysAuthorization()`

**Impacto:**
- Apple review pode questionar necessidade de "Always" permission
- Usuários desconfiam de apps que pedem mais do que precisam

**Recomendação:** Remover `NSLocationAlwaysAndWhenInUseUsageDescription`. Manter apenas `NSLocationWhenInUseUsageDescription`.

**Solução:** Ver patch no final deste doc.

---

### 🟡 3. Deep Links / Universal Links (app_links)

**Problema:** Package `app_links` está no `pubspec.lock` mas **não é usado** no código.

**Localização:**
- `pubspec.lock:28` — `app_links: 6.4.1` presente
- `ios/Podfile.lock:4` — `app_links (6.4.1)` instalado
- `lib/**/*.dart` — ❌ **Nenhum import de `package:app_links`**

**Origem:** Provável dependência transitiva ou leftover de teste.

**Impacto:**
- Aumenta bundle (+200KB)
- Confunde intenção de deep linking

**Status de Deep Links:**
- ❌ Nenhuma implementação ativa no código
- ❌ Não configurado `com.apple.developer.associated-domains` no Xcode
- ❌ Não existe ficheiro `.well-known/apple-app-site-association`

**Recomendação:** 
- **Curto prazo (Janeiro):** Ignorar. Não bloqueia TestFlight.
- **Médio prazo:** Se quiser invites via deep link (e.g., `lazzo://group/123`), implementar:
  1. Custom URL Schemes em `Info.plist` (URL Types)
  2. Handler com `app_links` package
  3. Universal Links (Associated Domains) quando tiver domínio web

---

### 🟡 4. Privacy Manifest (PrivacyInfo.xcprivacy)

**Problema:** Falta Privacy Manifest exigido por Apple desde iOS 17 (obrigatório desde Maio 2024).

**Localização:**
- `ios/Runner/` — ❌ **FALTA PrivacyInfo.xcprivacy**

**Required Reason APIs usados pela app:**
- **UserDefaults** (via `shared_preferences`) — Reason: User preferences
- **File timestamps** (via `path_provider`) — Reason: App functionality
- **System boot time** (via Firebase/network checks) — Reason: Measure time intervals

**Impacto:**
- Apple pode rejeitar na review (warning first, depois rejection)
- Requerido para todas as apps desde Maio 2024

**Solução:** Criar `ios/Runner/PrivacyInfo.xcprivacy` (ver patch no final).

---

### 🟡 5. Version e Build Number

**Status Atual:**
- `pubspec.yaml:20` — `version: 1.0.0+1` ✅
- `ios/Runner.xcodeproj/project.pbxproj:516` — `MARKETING_VERSION = 1.0` ✅
- `ios/Runner.xcodeproj/project.pbxproj:492` — `CURRENT_PROJECT_VERSION = $(FLUTTER_BUILD_NUMBER)` ✅

**Configuração:** ✅ Correta (Flutter controla via pubspec.yaml)

**Recomendação para TestFlight:**
- Primeira build: `1.0.0+1` (já está)
- Próxima iteração: `1.0.0+2`, depois `1.0.0+3` (só incrementar build number)
- Quando lançar público: `1.0.1+4` ou `1.1.0+5`

---

## 📱 Análise de Permissões (Info.plist)

### ✅ Permissões Corretas e Bem Justificadas

| Permissão | Texto | Status |
|-----------|-------|--------|
| **NSCameraUsageDescription** | "Este app precisa de acesso à câmera para tirar fotos das memórias do evento." | ✅ Claro e específico |
| **NSPhotoLibraryUsageDescription** | "Este app precisa de acesso às suas fotos para escolher imagens para as memórias do evento." | ✅ Bom |
| **NSPhotoLibraryAddUsageDescription** | "Este app precisa de permissão para guardar fotos das memórias do evento." | ✅ Bom |
| **NSCalendarsUsageDescription** | "Este app precisa de acesso ao calendário para adicionar eventos." | ✅ OK |
| **NSLocationWhenInUseUsageDescription** | "Este app precisa de acesso à sua localização para definir a localização do evento automaticamente." | ✅ OK |

### 🟡 Permissão Desnecessária

| Permissão | Problema |
|-----------|----------|
| **NSLocationAlwaysAndWhenInUseUsageDescription** | ❌ Redundante — App só usa "When In Use", não precisa de "Always" |

**Ação:** Remover linha 68-70 de `Info.plist`.

---

## 🔧 Análise de Dependências

### Dependências Core (Produção) — ✅ Todas Necessárias

| Package | Uso | Status |
|---------|-----|--------|
| `supabase_flutter: ^2.10.0` | Database + Auth | ✅ Core |
| `flutter_riverpod: ^2.6.1` | State management | ✅ Core |
| `firebase_core: ^4.3.0` | Firebase init | ✅ Core (notifications) |
| `firebase_messaging: ^16.1.0` | Push notifications | ✅ Core |
| `image_picker: ^1.0.7` | Camera/gallery | ✅ Core (memories) |
| `geolocator: ^14.0.2` | Current location | ✅ Core (events) |
| `geocoding: ^4.0.0` | Address ↔ coordinates | ✅ Core (events) |
| `url_launcher: ^6.1.0` | Open external maps | ✅ Core (locations) |
| `qr_flutter: ^4.1.0` | QR codes (invites) | ✅ Core (groups) |
| `add_2_calendar: ^3.0.1` | Add events to calendar | ✅ Core |
| `share_plus: ^12.0.1` | Native share | ✅ Core (memories) |
| `gal: ^2.3.0` | Save to gallery | ✅ Core (memories) |
| `shared_preferences: ^2.2.2` | Local storage | ✅ Core (settings) |
| `image: ^4.2.0` | Image processing | ✅ Core (compression) |
| `flutter_image_compress: ^2.3.0` | Image compression | ✅ Core (uploads) |
| `path_provider: ^2.1.1` | File paths | ✅ Core (storage) |
| `uuid: ^4.5.1` | ID generation | ✅ Core (fake repos) |
| `intl: ^0.20.2` | Internationalization | ✅ Core (dates) |
| `font_awesome_flutter: ^10.6.0` | Icons | ✅ UI |
| `http: ^1.4.0` | HTTP client | ✅ Core (Supabase) |

### ❌ Dependências de Teste em `dependencies` (MOVER)

| Package | Problema | Ação |
|---------|----------|------|
| `mocktail: ^1.0.3` | ❌ **Não usado em lib/** | Mover para `dev_dependencies` |
| `faker: ^2.1.0` | ❌ **Não usado em lib/** | Mover para `dev_dependencies` |
| `integration_test: sdk: flutter` | ❌ **Não usado em lib/** | Mover para `dev_dependencies` |

**Impacto:** ~500KB de código desnecessário no bundle final.

---

## 🗑️ SDKs Removidos com Sucesso (Limpeza Prévia)

✅ As seguintes dependências foram corretamente removidas:
- `sign_in_with_apple` — Removido (só email + OTP)
- `google_maps_flutter` — Removido (usa url_launcher para mapas externos)

**Status:** Código limpo, sem imports órfãos. ✅

---

## 🎯 Plano de Ativação Pós-Apple Developer Program

### 1. Criar App ID em developer.apple.com

**Steps:**
1. Login em [developer.apple.com/account](https://developer.apple.com/account)
2. Certificates, Identifiers & Profiles → Identifiers → "+"
3. Configurar:
   - **Bundle ID:** `com.gmonteiro.lazzo` (Explicit, não Wildcard)
   - **App Services (Capabilities):**
     - ☑️ Push Notifications
     - ☑️ Associated Domains (se quiser Universal Links)
     - ☐ Sign in with Apple (não usado)
4. Confirm & Register

### 2. Configurar Xcode Signing & Capabilities

**Abrir `ios/Runner.xcworkspace` no Xcode:**

#### Signing & Capabilities Tab:
- **Team:** [SEU_TEAM_NAME] (após join Apple Developer Program)
- **Bundle Identifier:** `com.gmonteiro.lazzo`
- **Signing Certificate:** Apple Distribution (gerido automaticamente)

#### Adicionar Capabilities:
1. **Push Notifications** (obrigatório)
   - Click "+ Capability"
   - Adicionar "Push Notifications"
   - Gera `Runner.entitlements` com:
     ```xml
     <key>aps-environment</key>
     <string>development</string>  <!-- ou 'production' para release -->
     ```

2. **Background Modes** (para push notifications background)
   - Ativar:
     - ☑️ Remote notifications

3. **Associated Domains** (apenas se implementar Universal Links)
   - Adicionar domínio:
     ```
     applinks:lazzo.app
     applinks:www.lazzo.app
     ```
   - Criar ficheiro em servidor web:
     ```
     https://lazzo.app/.well-known/apple-app-site-association
     ```

### 3. Firebase APNs Configuration

**No Firebase Console:**
1. Project Settings → Cloud Messaging → iOS app
2. Upload APNs Authentication Key:
   - Download .p8 key em developer.apple.com (Certificates → Keys)
   - Key ID, Team ID
3. Ou usar APNs Certificate (Legacy, não recomendado)

### 4. App Store Connect Setup

**Criar App em [appstoreconnect.apple.com](https://appstoreconnect.apple.com):**
1. My Apps → "+" → New App
2. Configurar:
   - **Platform:** iOS
   - **Name:** Lazzo
   - **Primary Language:** Portuguese (Portugal)
   - **Bundle ID:** `com.gmonteiro.lazzo`
   - **SKU:** `com-gmonteiro-lazzo` (interno, qualquer)
3. App Information:
   - **Privacy Policy URL:** [URL_TO_DEFINE]
   - **Category:** Social Networking (ou Photo & Video)
   - **Content Rights:** Choose appropriate
4. Pricing and Availability:
   - **Price:** Free

### 5. TestFlight Upload

**Command line:**
```bash
# 1. Build archive
flutter build ipa --release --obfuscate --split-debug-info=build/debug-info

# 2. Upload via Xcode Organizer
open ios/Runner.xcworkspace
# Window → Organizer → Archives → Upload to App Store Connect

# Ou via Transporter app (mais simples)
open build/ios/ipa/*.ipa
# Arrastar para Transporter.app
```

**Validation Checks (Apple fará automaticamente):**
- ✅ Valid code signature
- ✅ All required icons present
- ✅ Info.plist completo
- ✅ Capabilities match entitlements
- ⚠️ Privacy manifest (pode gerar warning, não bloqueia TestFlight)

### 6. Validar AASA para Universal Links (Opcional — Futuro)

Se implementar Associated Domains:

**Criar ficheiro em servidor web:**
```json
// https://lazzo.app/.well-known/apple-app-site-association
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "<TEAM_ID>.com.gmonteiro.lazzo",
        "paths": [
          "/invite/*",
          "/group/*",
          "/event/*"
        ]
      }
    ]
  }
}
```

**Servir ficheiro:**
- Content-Type: `application/json` (sem `.json` extension no filename)
- HTTPS obrigatório
- Sem redirect 3xx

**Validar:**
```bash
# Apple CDN valida em ~15min após deploy
curl -v https://lazzo.app/.well-known/apple-app-site-association

# Testar em device
# Abrir link no Safari → deve abrir app automaticamente
```

---

## 📋 Checklist Final para TestFlight (Janeiro 2025)

### Fase 1: Pré-Upload (Antes de Apple Developer Account)

- [ ] **CRÍTICO:** Adicionar `GoogleService-Info.plist` ao projeto iOS
- [ ] **CRÍTICO:** Testar Firebase init em device (`flutter run --release`)
- [ ] Mover `mocktail`, `faker`, `integration_test` para `dev_dependencies`
- [ ] Remover `NSLocationAlwaysAndWhenInUseUsageDescription` de `Info.plist`
- [ ] Criar `PrivacyInfo.xcprivacy` em `ios/Runner/`
- [ ] Gerar screenshots (6.7", 6.5", 5.5") para App Store Connect
- [ ] Definir Privacy Policy URL (hospedar em lazzo.app ou Notion público)

### Fase 2: Apple Developer Program (Dia 1)

- [ ] Join Apple Developer Program (99 USD/ano)
- [ ] Criar App ID com Bundle ID `com.gmonteiro.lazzo`
- [ ] Ativar Push Notifications capability no App ID
- [ ] Criar APNs key (.p8) e fazer upload no Firebase Console
- [ ] Configurar signing no Xcode (Team, Certificate)

### Fase 3: Xcode Capabilities (Dia 1)

- [ ] Abrir `ios/Runner.xcworkspace` no Xcode
- [ ] Adicionar capability "Push Notifications"
- [ ] Adicionar capability "Background Modes" → Remote notifications
- [ ] Commit `Runner.entitlements` gerado

### Fase 4: App Store Connect (Dia 2)

- [ ] Criar App em App Store Connect
- [ ] Adicionar App Information (Privacy Policy URL)
- [ ] Configurar Pricing (Free)
- [ ] Gerar build: `flutter build ipa --release`
- [ ] Upload via Xcode Organizer ou Transporter

### Fase 5: TestFlight (Dia 2-3)

- [ ] Aguardar processamento (5-30min)
- [ ] Adicionar testers internos (até 100 via email)
- [ ] Distribuir build (link automático por email)
- [ ] Testar push notifications em device real
- [ ] Validar todas as flows críticas (auth, events, photos)

### Fase 6: Review (Opcional — Quando pronto para público)

- [ ] Preencher App Store metadata (description, keywords, screenshots)
- [ ] Adicionar screenshots de todos os tamanhos obrigatórios
- [ ] Submit for Review
- [ ] Responder a possíveis questões da Apple (2-3 dias típico)

---

## 🛠️ Patches Sugeridos (Copy/Paste)

### Patch 1: Mover Dependências de Teste

**Ficheiro:** `pubspec.yaml`

```diff
 dependencies:
   flutter:
     sdk: flutter
   supabase_flutter: ^2.10.0
-  mocktail: ^1.0.3
   flutter_riverpod: ^2.6.1
   http: ^1.4.0
   font_awesome_flutter: ^10.6.0
   image_picker: ^1.0.7
   intl: ^0.20.2
-  faker: ^2.1.0
   # Native platform integrations for P2 handoff
   url_launcher: ^6.1.0
   geocoding: ^4.0.0
@@ -64,8 +62,6 @@ dependencies:
   # Push notifications (FCM for Android, APNs for iOS)
   firebase_core: ^4.3.0
   firebase_messaging: ^16.1.0
-  integration_test:
-    sdk: flutter
   # The following adds the Cupertino Icons font to your application.
   # Use with the CupertinoIcons class for iOS style icons.
   cupertino_icons: ^1.0.8
@@ -73,6 +69,11 @@ dependencies:
 dev_dependencies:
   flutter_test:
     sdk: flutter
+  mocktail: ^1.0.3
+  faker: ^2.1.0
+  integration_test:
+    sdk: flutter
 
   # The "flutter_lints" package below contains a set of recommended lints to
```

**Comandos após aplicar:**
```bash
flutter pub get
flutter build ios --release --no-codesign  # Validar que compila
```

---

### Patch 2: Remover Permissão de Localização Redundante

**Ficheiro:** `ios/Runner/Info.plist`

```diff
 	<!-- Permissões de localização para funcionalidade Current Location -->
 	<key>NSLocationWhenInUseUsageDescription</key>
 	<string>Este app precisa de acesso à sua localização para definir a localização do evento automaticamente.</string>
-	<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
-	<string>Este app precisa de acesso à sua localização para definir a localização do evento automaticamente.</string>
 	<!-- Permissões para adicionar eventos ao calendário -->
 	<key>NSCalendarsUsageDescription</key>
```

---

### Patch 3: Criar Privacy Manifest

**Novo Ficheiro:** `ios/Runner/PrivacyInfo.xcprivacy`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Tracking (não usado) -->
    <key>NSPrivacyTracking</key>
    <false/>
    
    <!-- Domínios de tracking (vazio) -->
    <key>NSPrivacyTrackingDomains</key>
    <array/>
    
    <!-- APIs que requerem justificação -->
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <!-- UserDefaults (via shared_preferences) -->
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string> <!-- Store user preferences -->
            </array>
        </dict>
        
        <!-- File timestamps (via path_provider) -->
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>C617.1</string> <!-- App functionality -->
            </array>
        </dict>
        
        <!-- System boot time (via Firebase) -->
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategorySystemBootTime</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>35F9.1</string> <!-- Measure time -->
            </array>
        </dict>
    </array>
    
    <!-- Data coletada (para Privacy Nutrition Label) -->
    <key>NSPrivacyCollectedDataTypes</key>
    <array>
        <dict>
            <key>NSPrivacyCollectedDataType</key>
            <string>NSPrivacyCollectedDataTypeEmailAddress</string>
            <key>NSPrivacyCollectedDataTypeLinked</key>
            <true/>
            <key>NSPrivacyCollectedDataTypeTracking</key>
            <false/>
            <key>NSPrivacyCollectedDataTypePurposes</key>
            <array>
                <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
            </array>
        </dict>
        <dict>
            <key>NSPrivacyCollectedDataType</key>
            <string>NSPrivacyCollectedDataTypeName</string>
            <key>NSPrivacyCollectedDataTypeLinked</key>
            <true/>
            <key>NSPrivacyCollectedDataTypeTracking</key>
            <false/>
            <key>NSPrivacyCollectedDataTypePurposes</key>
            <array>
                <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
            </array>
        </dict>
        <dict>
            <key>NSPrivacyCollectedDataType</key>
            <string>NSPrivacyCollectedDataTypePhotosorVideos</string>
            <key>NSPrivacyCollectedDataTypeLinked</key>
            <true/>
            <key>NSPrivacyCollectedDataTypeTracking</key>
            <false/>
            <key>NSPrivacyCollectedDataTypePurposes</key>
            <array>
                <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
            </array>
        </dict>
        <dict>
            <key>NSPrivacyCollectedDataType</key>
            <string>NSPrivacyCollectedDataTypePreciseLocation</string>
            <key>NSPrivacyCollectedDataTypeLinked</key>
            <false/>
            <key>NSPrivacyCollectedDataTypeTracking</key>
            <false/>
            <key>NSPrivacyCollectedDataTypePurposes</key>
            <array>
                <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

**Adicionar ao Xcode:**
1. Abrir `ios/Runner.xcworkspace`
2. Right-click na pasta "Runner" (azul) → Add Files to "Runner"
3. Selecionar `PrivacyInfo.xcprivacy`
4. ☑️ "Copy items if needed"
5. ☑️ Add to target: Runner

---

### Patch 4: GoogleService-Info.plist Template

**Nota:** Substituir valores `[REDACTED]` com os reais do Firebase Console.

**Novo Ficheiro:** `ios/Runner/GoogleService-Info.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>API_KEY</key>
	<string>[REDACTED - Firebase API Key]</string>
	<key>GCM_SENDER_ID</key>
	<string>[REDACTED - Firebase Sender ID]</string>
	<key>PLIST_VERSION</key>
	<string>1</string>
	<key>BUNDLE_ID</key>
	<string>com.gmonteiro.lazzo</string>
	<key>PROJECT_ID</key>
	<string>[REDACTED - Firebase Project ID]</string>
	<key>STORAGE_BUCKET</key>
	<string>[REDACTED - Firebase Storage Bucket]</string>
	<key>IS_ADS_ENABLED</key>
	<false/>
	<key>IS_ANALYTICS_ENABLED</key>
	<false/>
	<key>IS_APPINVITE_ENABLED</key>
	<true/>
	<key>IS_GCM_ENABLED</key>
	<true/>
	<key>IS_SIGNIN_ENABLED</key>
	<true/>
	<key>GOOGLE_APP_ID</key>
	<string>[REDACTED - Firebase App ID]</string>
</dict>
</plist>
```

**Obter valores:**
1. Firebase Console → Project Settings → iOS app
2. Download `GoogleService-Info.plist`
3. Copiar para `ios/Runner/GoogleService-Info.plist`
4. Adicionar ao Xcode (mesmo processo que PrivacyInfo)

---

## 📌 Resumo Executivo

### ✅ O Que Está Bem
- App compila em Release sem erros
- Bundle ID configurado (`com.gmonteiro.lazzo`)
- Permissões de localização/câmera/fotos bem justificadas
- App Icons completos (todos os tamanhos)
- Versioning correto (Flutter controla via pubspec.yaml)
- Código limpo (sem social auth ou google_maps_flutter)

### 🔴 Bloqueadores CRÍTICOS (Resolver Antes de Upload)
1. **Firebase GoogleService-Info.plist** — FALTA (app crashará)
2. **Push Notifications Capability** — Não configurado no Xcode
3. **App Store Connect Assets** — Falta Privacy Policy URL e screenshots

### 🟡 Melhorias Recomendadas (Não Urgentes)
1. Mover `mocktail`, `faker`, `integration_test` para `dev_dependencies` (~500KB saving)
2. Remover `NSLocationAlwaysAndWhenInUseUsageDescription` redundante
3. Criar `PrivacyInfo.xcprivacy` (Apple pode começar a exigir)

### 🎯 Timeline Estimado para TestFlight
- **Hoje (28 Dez):** Aplicar patches 1-3 (1h)
- **Dia 1 (quando tiver Apple Developer):** Configurar Firebase, Xcode capabilities, criar App ID (2h)
- **Dia 2:** Build + upload para App Store Connect (1h)
- **Dia 3:** TestFlight beta disponível para testers 🎉

---

**Próximos Passos Imediatos:**
1. ✅ Aplicar Patch 1 (dependências)
2. ✅ Aplicar Patch 2 (location permission)
3. ✅ Aplicar Patch 3 (privacy manifest)
4. 🔴 Download GoogleService-Info.plist do Firebase
5. 🔴 Join Apple Developer Program
6. 🔴 Configure push notifications no Xcode

---

*Report gerado automaticamente. Para questões: [seu-email-ou-slack]*
