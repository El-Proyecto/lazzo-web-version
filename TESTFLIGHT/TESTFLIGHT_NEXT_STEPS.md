# 🚀 Próximos Passos para TestFlight — Ação Imediata

**Status:** ✅ Patches aplicados (dependências + privacy + location permission)

---

## ✅ Completado Agora (28 Dez 2025)

1. ✅ Movidas dependências de teste (`mocktail`, `faker`, `integration_test`) para `dev_dependencies`
2. ✅ Removida permissão redundante `NSLocationAlwaysAndWhenInUseUsageDescription` 
3. ✅ Criado `PrivacyInfo.xcprivacy` com Required Reason APIs
4. ✅ Criado template `GoogleService-Info.plist.TEMPLATE`
5. ✅ Build iOS Release testado — compila sem erros

---

## 🔴 BLOQUEADORES — Resolver Antes de TestFlight

### 1. Firebase GoogleService-Info.plist (CRÍTICO ⚠️)

**Ficheiro atual:** `ios/Runner/GoogleService-Info.plist.TEMPLATE` (placeholder)

**Ação:**
```bash
# 1. Download do Firebase Console
# https://console.firebase.google.com → Projeto Lazzo → iOS app → Download

# 2. Substituir template
cp ~/Downloads/GoogleService-Info.plist ios/Runner/GoogleService-Info.plist

# 3. Adicionar ao Xcode (IMPORTANTE)
open ios/Runner.xcworkspace
# → Right-click "Runner" (pasta azul)
# → Add Files to "Runner"
# → Selecionar GoogleService-Info.plist
# → ☑️ "Copy items if needed"
# → ☑️ Add to target: Runner
```

**Teste:**
```bash
flutter run --release
# Verificar logs: "Configured FirebaseApp" (sem crash)
```

---

### 2. Privacy Manifest no Xcode (IMPORTANTE 📋)

**Ficheiro criado:** `ios/Runner/PrivacyInfo.xcprivacy`

**Ação:**
```bash
# Adicionar ao Xcode target
open ios/Runner.xcworkspace
# → Right-click "Runner" (pasta azul)
# → Add Files to "Runner"
# → Selecionar PrivacyInfo.xcprivacy
# → ☑️ "Copy items if needed"
# → ☑️ Add to target: Runner
```

---

### 3. Apple Developer Program ($99/ano)

**Link:** https://developer.apple.com/programs/enroll/

**Após join:**
1. Criar App ID com Bundle ID `com.gmonteiro.lazzo`
2. Ativar capabilities:
   - ☑️ Push Notifications
   - ☑️ Associated Domains (se quiser Universal Links futuro)

---

### 4. Xcode Capabilities (Requer Apple Developer Account)

**Abrir:** `ios/Runner.xcworkspace`

**Adicionar:**
1. **Push Notifications**
   - Target Runner → Signing & Capabilities → "+ Capability"
   - Adicionar "Push Notifications"
   
2. **Background Modes**
   - Adicionar "Background Modes"
   - ☑️ Remote notifications

3. **Signing**
   - Team: [SEU TEAM após join]
   - Automatically manage signing: ☑️

---

### 5. Firebase APNs Configuration

**No Firebase Console:**
1. Project Settings → Cloud Messaging → iOS app
2. Upload APNs Authentication Key:
   - Download .p8 key em developer.apple.com (Certificates → Keys → "+")
   - Copiar Key ID e Team ID
   - Upload no Firebase

---

### 6. App Store Connect

**Criar App:**
1. https://appstoreconnect.apple.com → My Apps → "+"
2. Configurar:
   - Name: Lazzo
   - Bundle ID: com.gmonteiro.lazzo
   - Primary Language: Portuguese (Portugal)
3. App Information:
   - **Privacy Policy URL:** [DEFINIR - pode ser Notion público]
   - Category: Social Networking

---

## 📦 Build & Upload

```bash
# 1. Build IPA
flutter build ipa --release --obfuscate --split-debug-info=build/debug-info

# 2. Validar (opcional)
flutter build ipa --release --no-codesign
# → Verificar warnings no console

# 3. Upload via Xcode Organizer
open ios/Runner.xcworkspace
# → Product → Archive
# → Window → Organizer → Archives
# → Upload to App Store Connect

# Ou via Transporter (mais simples)
open -a Transporter build/ios/ipa/*.ipa
```

---

## ✅ Checklist Final

### Pré-Upload
- [ ] GoogleService-Info.plist adicionado ao Xcode target
- [ ] PrivacyInfo.xcprivacy adicionado ao Xcode target
- [ ] Firebase init testado em device: `flutter run --release`
- [ ] Privacy Policy URL definido (pode ser temporário)

### Apple Developer Account
- [ ] Join Apple Developer Program ($99)
- [ ] App ID criado com Bundle ID `com.gmonteiro.lazzo`
- [ ] Push Notifications capability ativado no App ID
- [ ] APNs key (.p8) criado e uploaded no Firebase

### Xcode
- [ ] Signing configurado (Team + Certificate)
- [ ] Push Notifications capability adicionado
- [ ] Background Modes → Remote notifications ativado
- [ ] Commit `Runner.entitlements` gerado

### App Store Connect
- [ ] App criado
- [ ] Privacy Policy URL configurado
- [ ] Pricing: Free

### Build
- [ ] `flutter build ipa --release` executado sem erros
- [ ] Upload concluído (via Organizer ou Transporter)
- [ ] Build processada (5-30min)

### TestFlight
- [ ] Testers internos adicionados
- [ ] Build distribuída
- [ ] Push notifications testado em device real
- [ ] Todas as flows críticas validadas

---

## 🆘 Troubleshooting Comum

### Firebase init crash
**Erro:** App fecha ao lançar  
**Causa:** GoogleService-Info.plist não adicionado ao target  
**Fix:** Verificar no Xcode → Runner → Build Phases → Copy Bundle Resources

### Push token não regista
**Erro:** `getToken()` retorna null  
**Causa:** Capability não configurado ou APNs key não uploaded  
**Fix:** Verificar Runner.entitlements tem `aps-environment`

### Code signing failed
**Erro:** No valid signing identity found  
**Causa:** Team não configurado ou Certificate expirado  
**Fix:** Xcode → Signing & Capabilities → Download Manual Profiles

### Upload rejected: Missing compliance
**Erro:** Export compliance not set  
**Causa:** App usa encriptação (HTTPS)  
**Fix:** App Store Connect → App Information → Export Compliance → "No" (HTTPS exempt)

---

## 📞 Support

- **Relatório Completo:** Ver `TESTFLIGHT_READINESS_REPORT.md`
- **Firebase Issues:** https://console.firebase.google.com → Support
- **Apple Issues:** https://developer.apple.com/support/

---

**Tempo Estimado até TestFlight:** 1-2 dias (após Apple Developer Account)
