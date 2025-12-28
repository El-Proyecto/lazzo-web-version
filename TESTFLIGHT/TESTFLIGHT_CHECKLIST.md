# ✅ TestFlight Checklist — Lazzo iOS

**Imprimir ou abrir em split screen durante deployment**

---

## 📋 FASE 1: Preparação (HOJE) ✅

- [x] Mover dependencies de teste para `dev_dependencies`
- [x] Remover permissão `NSLocationAlwaysAndWhenInUseUsageDescription`
- [x] Criar `PrivacyInfo.xcprivacy`
- [x] Criar template `GoogleService-Info.plist.TEMPLATE`
- [x] Testar build: `flutter build ios --release --no-codesign` ✅

---

## 📋 FASE 2: Firebase Setup (DIA 1)

- [ ] Aceder Firebase Console: https://console.firebase.google.com
- [ ] Selecionar projeto Lazzo
- [ ] Project Settings → iOS app → Download `GoogleService-Info.plist`
- [ ] Copiar ficheiro: `cp ~/Downloads/GoogleService-Info.plist ios/Runner/`
- [ ] Abrir Xcode: `open ios/Runner.xcworkspace`
- [ ] Adicionar ao target:
  - [ ] Right-click "Runner" → Add Files to "Runner"
  - [ ] Selecionar `GoogleService-Info.plist`
  - [ ] ☑️ "Copy items if needed"
  - [ ] ☑️ Add to target: Runner
- [ ] Testar: `flutter run --release` (verificar logs Firebase)

---

## 📋 FASE 3: Privacy Manifest no Xcode (DIA 1)

- [ ] Xcode já aberto (passo anterior)
- [ ] Adicionar ao target:
  - [ ] Right-click "Runner" → Add Files to "Runner"
  - [ ] Selecionar `PrivacyInfo.xcprivacy`
  - [ ] ☑️ "Copy items if needed"
  - [ ] ☑️ Add to target: Runner
- [ ] Verificar aparece em Runner → Build Phases → Copy Bundle Resources

---

## 📋 FASE 4: Apple Developer Program (DIA 1)

- [ ] Aceder: https://developer.apple.com/programs/enroll/
- [ ] Pagar $99 USD/ano
- [ ] Aguardar aprovação (15min - 48h, média: 2h)
- [ ] Verificar acesso em: https://developer.apple.com/account

---

## 📋 FASE 5: Criar App ID (DIA 1)

- [ ] Aceder: https://developer.apple.com/account
- [ ] Certificates, Identifiers & Profiles
- [ ] Identifiers → "+" (canto superior direito)
- [ ] Selecionar "App IDs" → Continue
- [ ] Configurar:
  - [ ] Type: App
  - [ ] Description: Lazzo iOS App
  - [ ] Bundle ID: Explicit → `com.gmonteiro.lazzo`
  - [ ] Capabilities:
    - [ ] ☑️ Push Notifications
    - [ ] ☑️ Associated Domains (opcional — futuro)
- [ ] Continue → Register

---

## 📋 FASE 6: APNs Key (DIA 1)

- [ ] developer.apple.com → Certificates, Identifiers & Profiles
- [ ] Keys → "+"
- [ ] Key Name: "Lazzo APNs Key"
- [ ] ☑️ Apple Push Notifications service (APNs)
- [ ] Continue → Register → Download (.p8 file)
- [ ] ⚠️ GUARDAR ficheiro .p8 em local seguro (só download 1x)
- [ ] Copiar Key ID (ex: `AB12CD34EF`)
- [ ] Copiar Team ID (Account → Membership)
- [ ] Firebase Console → Project Settings → Cloud Messaging → iOS
- [ ] Upload APNs Authentication Key:
  - [ ] Upload .p8 file
  - [ ] Key ID: [colar]
  - [ ] Team ID: [colar]

---

## 📋 FASE 7: Xcode Capabilities (DIA 1)

- [ ] Xcode: `open ios/Runner.xcworkspace`
- [ ] Selecionar target "Runner" (barra esquerda)
- [ ] Tab "Signing & Capabilities"

### Signing
- [ ] Team: [Selecionar SEU TEAM]
- [ ] ☑️ Automatically manage signing
- [ ] Verificar: Certificate aparece (Apple Distribution)

### Capabilities
- [ ] Click "+ Capability"
- [ ] Adicionar "Push Notifications"
- [ ] Click "+ Capability" novamente
- [ ] Adicionar "Background Modes"
  - [ ] ☑️ Remote notifications

### Validação
- [ ] Verificar ficheiro criado: `Runner/Runner.entitlements`
- [ ] Commit ficheiro: `git add ios/Runner/Runner.entitlements`

---

## 📋 FASE 8: App Store Connect (DIA 2)

- [ ] Aceder: https://appstoreconnect.apple.com
- [ ] My Apps → "+" → New App
- [ ] Configurar:
  - [ ] Platform: iOS
  - [ ] Name: Lazzo
  - [ ] Primary Language: Portuguese (Portugal)
  - [ ] Bundle ID: `com.gmonteiro.lazzo`
  - [ ] SKU: `com-gmonteiro-lazzo`
  - [ ] User Access: Full Access
- [ ] Create

### App Information
- [ ] App Store Connect → My Apps → Lazzo → App Information
- [ ] Privacy Policy URL: [DEFINIR URL]
  - Opções: Notion público, Google Doc, ou hospedar em lazzo.app
- [ ] Category: Social Networking (ou Photo & Video)
- [ ] Save

### Pricing and Availability
- [ ] My Apps → Lazzo → Pricing and Availability
- [ ] Price: Free
- [ ] Availability: All countries (ou escolher specific)
- [ ] Save

---

## 📋 FASE 9: Build & Upload (DIA 2)

### Build IPA
```bash
cd /Users/monteiro/projects/lazzo
flutter clean
flutter pub get
flutter build ipa --release
```

- [ ] Comando executado sem erros
- [ ] Ficheiro gerado: `build/ios/ipa/app.ipa` (verificar existe)

### Upload via Xcode Organizer
- [ ] Xcode: `open ios/Runner.xcworkspace`
- [ ] Product → Archive (⌘B para build antes se necessário)
- [ ] Aguardar conclusão (2-5min)
- [ ] Window → Organizer (ou ⌘⌥⇧O)
- [ ] Tab "Archives"
- [ ] Selecionar build mais recente
- [ ] "Distribute App"
- [ ] "App Store Connect" → Next
- [ ] "Upload" → Next
- [ ] Manter defaults → Next
- [ ] Automatically manage signing → Next
- [ ] Upload
- [ ] Aguardar (1-3min)

### OU Upload via Transporter (Alternativa mais simples)
- [ ] Abrir Transporter app (instalar da Mac App Store se necessário)
- [ ] Arrastar `build/ios/ipa/app.ipa` para Transporter
- [ ] Login com Apple ID
- [ ] Deliver

---

## 📋 FASE 10: TestFlight (DIA 2-3)

- [ ] App Store Connect → My Apps → Lazzo → TestFlight
- [ ] Aguardar processamento (5-30min, média: 15min)
- [ ] Verificar status: "Ready to Submit" ou "Ready to Test"

### Compliance (Se Apple perguntar)
- [ ] "Provide Export Compliance Information"
- [ ] "Your app uses encryption" → Yes (HTTPS)
- [ ] "Does your app qualify for exemption?" → Yes
- [ ] Selecionar: Uses encryption for standard HTTPS communication
- [ ] Submit

### Adicionar Testers Internos
- [ ] TestFlight → Internal Testing → Default (Internal Testers)
- [ ] "+" → Add tester
- [ ] Email: [seu-email@exemplo.com]
- [ ] Add
- [ ] Selecionar build → Enable for Testing

### Distribuir Build
- [ ] Tester receberá email automático
- [ ] Instalar TestFlight app em iPhone
- [ ] Abrir link do email
- [ ] Install

---

## 📋 FASE 11: Validação (DIA 3)

### Testes Críticos em Device Real
- [ ] **Auth Flow:**
  - [ ] Signup com email + OTP
  - [ ] Login com email + OTP
  - [ ] Logout
- [ ] **Push Notifications:**
  - [ ] Aceitar permission prompt
  - [ ] Enviar test notification (Firebase Console)
  - [ ] Verificar recebe notificação
- [ ] **Camera & Photos:**
  - [ ] Tirar foto
  - [ ] Escolher da galeria
  - [ ] Salvar na galeria
- [ ] **Location:**
  - [ ] Aceitar permission "When In Use"
  - [ ] Criar evento com localização atual
  - [ ] Abrir mapa externo
- [ ] **Calendar:**
  - [ ] Aceitar permission
  - [ ] Adicionar evento ao calendário
- [ ] **Core Flows:**
  - [ ] Criar grupo
  - [ ] Criar evento
  - [ ] Upload fotos de memória
  - [ ] Chat no evento
  - [ ] RSVP

---

## 🎉 FASE 12: Concluído!

- [ ] Todas as validações passaram ✅
- [ ] App funciona em device real ✅
- [ ] Push notifications funcionam ✅
- [ ] TestFlight build distribuído ✅

### Próximos Passos (Futuro)
- [ ] Adicionar mais testers externos (até 10,000)
- [ ] Iterar baseado em feedback
- [ ] Preparar screenshots para App Store (quando pronto para público)
- [ ] Submit for Review (quando app estável)

---

## 🆘 Troubleshooting Rápido

| Erro | Solução Rápida |
|------|----------------|
| Firebase init crash | Verificar GoogleService-Info.plist no Copy Bundle Resources |
| Push token null | Verificar Runner.entitlements tem `aps-environment` |
| Code signing failed | Xcode → Preferences → Accounts → Download Manual Profiles |
| Upload rejected | App Store Connect → Export Compliance → Yes (HTTPS exempt) |
| Build não aparece | Aguardar 30min, refresh página |

---

**Duração Total Estimada:** 1-2 dias  
**Custo:** $99 USD (Apple Developer Program)  
**Complexidade:** 🟢 Média (follow checklist passo a passo)

---

**Último Update:** 28 Dezembro 2025  
**Versão App:** 1.0.0+1  
**Status:** ✅ Fase 1 completa, pronto para Fase 2
