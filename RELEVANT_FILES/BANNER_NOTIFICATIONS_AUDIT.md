# Banner & Notifications Audit

**Objetivo:** Documentar todos os banners/notificações existentes na app e recomendar migração para o `TopBanner` component.

**Status:** 📋 Análise completa - aguardando implementação

---

## 🎯 Tipos de Notificação Identificados

### 1. **Confirmação/Sucesso** (Verde)
Background verde indicando ação bem-sucedida

### 2. **Erro/Falha** (Vermelho)
Background vermelho indicando falha ou erro

### 3. **Neutro/Informativo** (Cinza/Bg2)
Informação geral sem conotação positiva/negativa

### 4. **Ação Pendente** (Azul/Planning)
Indicação de ação em progresso ou planeamento

### 5. **Banner Inline** (Amarelo/Atenção)
Mensagens persistentes no topo da página (não SnackBar)

---

## 📄 Análise por Página

### ✅ **group_details_page.dart** (Group Hub)
**Status:** Já usa `TopBanner` ✓

| Tipo | Contexto | Implementação Atual | Recomendação |
|------|----------|-------------------|--------------|
| Neutro | Mute toggle (muted/unmuted) | `TopBanner.show()` | ✓ Manter como está |

**Notas:**
- Primeira página a usar TopBanner
- Referência de implementação para outras páginas

---

### 🔐 **auth_page.dart** (Auth)
**Localização:** `lib/features/auth/presentation/pages/auth_page.dart`

| Tipo | Contexto | Implementação Atual | Recomendação |
|------|----------|-------------------|--------------|
| Confirmação | Código de verificação enviado (linha 70) | `SnackBar` verde | **Migrar para TopBanner (verde)** |
| Erro | Erro no registo (linha 91-92) | `SnackBar` vermelho | **Migrar para TopBanner (vermelho)** |
| Erro | Erro no Google sign-in (linha 111) | `SnackBar` vermelho | **Migrar para TopBanner (vermelho)** |

**Recomendação:**
- Criar `TopBanner.showSuccess()` com background verde
- Criar `TopBanner.showError()` com background vermelho
- Manter duração de 3 segundos para mensagens de sucesso

---

### 📧 **verify_otp.dart** (OTP Verification)
**Localização:** `lib/features/auth/presentation/pages/verify_otp.dart`

| Tipo | Contexto | Implementação Atual | Recomendação |
|------|----------|-------------------|--------------|
| Inline Banner | Banner informativo persistente (linha 120-131) | Container custom amarelo | **Migrar para TopBanner persistente** ou manter como componente inline |
| Neutro | Novo código enviado (linha 48) | State variable `_bannerMessage` | **Converter para TopBanner.showInfo()** |
| Erro | Falha ao reenviar código (linha 51) | State variable `_bannerMessage` | **Converter para TopBanner.showError()** |
| Neutro | Instrução do código (linha 60) | State variable `_bannerMessage` | **Manter inline** (é instrução inicial) |
| Erro | Erro na verificação (linha 86-89) | State variable `_bannerMessage` | **Converter para TopBanner.showError()** |

**Recomendação:**
- Banner amarelo persistente pode manter-se inline (é parte do layout)
- Mensagens de feedback (sucesso/erro) devem usar TopBanner
- Considerar TopBanner com `duration: null` para mensagens persistentes que requerem ação do user

---

### ✅ **finish_setup.dart** (Finish Setup)
**Localização:** `lib/features/auth/presentation/pages/finish_setup.dart`

| Tipo | Contexto | Implementação Atual | Recomendação |
|------|----------|-------------------|--------------|
| Confirmação | Dados guardados (linha 116) | `SnackBar` floating | **Migrar para TopBanner.showSuccess()** |
| Erro | Erro ao guardar (linha 125) | `SnackBar` floating | **Migrar para TopBanner.showError()** |

**Recomendação:**
- Feedback simples e direto - perfeito para TopBanner
- Usar duração curta (2s) pois é feedback de ação imediata

---

### 👤 **profile_page.dart** (Profile)
**Localização:** `lib/features/profile/presentation/pages/profile_page.dart`

| Tipo | Contexto | Implementação Atual | Recomendação |
|------|----------|-------------------|--------------|
| Neutro | Logout (linha 92-93) | `SnackBar` | **Migrar para TopBanner.showInfo()** (ou remover, pois navega away) |

**Recomendação:**
- Considerar se notificação é necessária (user já navega para auth page)
- Se mantiver, usar TopBanner neutro com duração curta (1.5s)

---

### ✏️ **edit_profile_page.dart** (Edit Profile)
**Localização:** `lib/features/profile/presentation/pages/edit_profile_page.dart`

| Tipo | Contexto | Implementação Atual | Recomendação |
|------|----------|-------------------|--------------|
| Erro | Falha ao escolher imagem da galeria (linha 401) | `SnackBar` custom (bg2) | **Migrar para TopBanner.showError()** |
| Erro | Falha ao tirar foto (linha 420) | `SnackBar` custom (bg2) | **Migrar para TopBanner.showError()** |
| Ação Pendente | Uploading photo... (linha 429) | `SnackBar` custom (bg2) | **Migrar para TopBanner.showLoading()** |
| Confirmação | Photo updated successfully (linha 443) | `SnackBar` custom (bg2) | **Migrar para TopBanner.showSuccess()** |
| Erro | Failed to upload photo (linha 446) | `SnackBar` custom (bg2) | **Migrar para TopBanner.showError()** |
| Confirmação | Photo removed successfully (linha 466) | `SnackBar` custom (bg2) | **Migrar para TopBanner.showSuccess()** |
| Erro | Failed to remove photo (linha 469) | `SnackBar` custom (bg2) | **Migrar para TopBanner.showError()** |

**Recomendação:**
- Página com mais notificações - excelente candidata para TopBanner
- Criar `TopBanner.showLoading()` para estados "Uploading..."
- Considerar loading spinner no banner para operações longas
- Usar verde para sucesso, vermelho para erro, azul para loading

---

### 🎉 **event_page.dart** (Event Details)
**Localização:** `lib/features/event/presentation/pages/event_page.dart`

| Tipo | Contexto | Implementação Atual | Recomendação |
|------|----------|-------------------|--------------|
| Confirmação/Neutro | Event confirmed/unmarked (linha 76-87) | `SnackBar` com BrandColors.planning/text2 | **Migrar para TopBanner com cores dinâmicas** |
| Confirmação | Event date set successfully (linha 1008) | `SnackBar` verde | **Migrar para TopBanner.showSuccess()** |
| Erro | Failed to set event date (linha 1018) | `SnackBar` vermelho | **Migrar para TopBanner.showError()** |
| Confirmação | Event location set successfully (linha 1079) | `SnackBar` verde | **Migrar para TopBanner.showSuccess()** |
| Erro | Failed to set event location (linha 1089) | `SnackBar` vermelho | **Migrar para TopBanner.showError()** |

**Recomendação:**
- Método `_showStatusMessage()` deve usar TopBanner
- Manter lógica de cores dinâmicas (verde para confirmado, cinza para unmarked)
- TopBanner deve suportar `backgroundColor` customizável

---

### 💭 **memory_page.dart** (Memory)
**Localização:** `lib/features/memory/presentation/pages/memory_page.dart`

| Tipo | Contexto | Implementação Atual | Recomendação |
|------|----------|-------------------|--------------|
| Neutro | Share URL gerado (linha 242) | `SnackBar` com BrandColors.planning | **Migrar para TopBanner.showInfo()** |
| Erro | Failed to share (linha 252) | `SnackBar` com BrandColors.cantVote | **Migrar para TopBanner.showError()** |

**Recomendação:**
- Feedback de share é importante - usar TopBanner
- Considerar adicionar ícone no banner (share icon, error icon)

---

### 👥 **groups_page.dart** (Groups List)
**Localização:** `lib/features/groups/presentation/pages/groups_page.dart`

| Tipo | Contexto | Implementação Atual | Recomendação |
|------|----------|-------------------|--------------|
| N/A | showDialog para join group (linha 392) | Dialog modal | **Manter como dialog** (requer input) |

**Recomendação:**
- Dialog é adequado (precisa de decisão do user)
- Após join/cancelar, adicionar TopBanner para confirmar ação

---

### ➕ **create_group_page.dart** (Create Group)
**Localização:** `lib/features/groups/presentation/pages/create_group_page.dart`

| Tipo | Contexto | Implementação Atual | Recomendação |
|------|----------|-------------------|--------------|
| Erro | Erro na criação do grupo (linha 94) | `SnackBar` | **Migrar para TopBanner.showError()** |
| Erro | Erro genérico (linha 243) | `SnackBar` | **Migrar para TopBanner.showError()** |

**Recomendação:**
- Erros críticos - usar TopBanner.showError()
- Considerar duração mais longa (4-5s) para dar tempo ao user ler

---

### 🎊 **group_created_page.dart** (Group Created Success)
**Localização:** `lib/features/groups/presentation/pages/group_created_page.dart`

| Tipo | Contexto | Implementação Atual | Recomendação |
|------|----------|-------------------|--------------|
| Confirmação | Link copied to clipboard (linha 141) | `SnackBar` com colorScheme.primary | **Migrar para TopBanner.showSuccess()** |
| Neutro | Unable to share / Link copied (linha 159) | `SnackBar` | **Migrar para TopBanner.showInfo()** |

**Recomendação:**
- Página de sucesso - usar TopBanner verde
- Feedback de clipboard é rápido - duração 1.5-2s

---

### 📅 **create_event_page.dart** (Create Event)
**Localização:** `lib/features/create_event/presentation/pages/create_event_page.dart`

| Tipo | Contexto | Implementação Atual | Recomendação |
|------|----------|-------------------|--------------|
| Confirmação | Group created (linha 778) | `SnackBar` com BrandColors.planning | **Migrar para TopBanner.showSuccess()** |

**Recomendação:**
- Feedback de criação de grupo inline - usar TopBanner verde
- Duração média (2-3s)

---

### ✏️ **edit_event_page.dart** (Edit Event)
**Localização:** `lib/features/create_event/presentation/pages/edit_event_page.dart`

| Tipo | Contexto | Implementação Atual | Recomendação |
|------|----------|-------------------|--------------|
| Erro | Erro ao editar evento (linha 410) | `SnackBar` vermelho | **Migrar para TopBanner.showError()** |

**Recomendação:**
- Erro crítico - TopBanner.showError() com duração longa (4-5s)
- Considerar adicionar ícone de erro

---

## 🎨 TopBanner API Proposta

### Métodos Estáticos

```dart
## 🎨 TopBanner API Implementada ✅

### Métodos Estáticos Disponíveis

```dart
// Neutro (sem ícone, fundo cinza bg2)
TopBanner.show(context, message: 'Message');

// Sucesso (verde planning #169C3E, ícone check_circle) - 2.2s
TopBanner.showSuccess(context, message: 'Action completed!');

// Erro (vermelho cantVote #FF3B30, ícone error) - 3.0s
TopBanner.showError(context, message: 'Failed to perform action');

// Warning (amarelo #FFB800, ícone warning) - 3.0s
TopBanner.showWarning(context, message: 'Warning message');

// Informativo (cinza bg2 #1F1F1F, ícone info) - 2.2s
TopBanner.showInfo(context, message: 'Information message');
```

### Características Implementadas

✅ **Apenas 1 banner visível** - novos banners substituem o atual automaticamente  
✅ **Durações por tipo:**
  - Success/Info: 2.2s
  - Warning: 3.0s
  - Error: 3.0s
  - Neutro: customizável (padrão: sem auto-dismiss)

✅ **Ícones e cores por tipo:**
  - Success: `Icons.check_circle` (verde `BrandColors.planning` #169C3E)
  - Error: `Icons.error` (vermelho `BrandColors.cantVote` #FF3B30)
  - Warning: `Icons.warning` (amarelo `BrandColors.warning` #FFB800)
  - Info: `Icons.info` (cinza `BrandColors.bg2` #1F1F1F - mesmo que neutro)
  - Neutro: sem ícone (cinza `BrandColors.bg2` #1F1F1F)

✅ **Posicionamento:** Topo, centrado, abaixo safe area + AppBar + 8px offset  
✅ **Alinhamento:** Texto alinhado à esquerda  
✅ **Drag-to-dismiss:** Arrastar para cima >50px para fechar  
✅ **Animação:** Slide-down suave (300ms)

### Exemplos de Uso

```dart
// Sucesso após ação
TopBanner.showSuccess(context, message: 'Profile updated successfully');

// Erro com duração customizada
TopBanner.showError(
  context, 
  message: 'Failed to upload photo',
  duration: Duration(seconds: 5),
);

// Info sem auto-dismiss
TopBanner.showInfo(
  context,
  message: 'Tap to continue',
  duration: null, // Permanece até drag-to-dismiss
);

// Neutro (comportamento legacy)
TopBanner.show(context, message: 'Group notifications muted');
```
```

### Parâmetros Adicionais

- `icon: IconData?` - ícone opcional à esquerda
- `backgroundColor: Color?` - cor de fundo custom
- `textColor: Color?` - cor do texto custom
- `duration: Duration?` - null = manual dismiss apenas
- `dismissible: bool` - permitir drag-to-dismiss (default: true)
- `showCloseButton: bool` - mostrar X para fechar (default: false)

---

## 📊 Resumo de Migração

### Por Tipo de Notificação

| Tipo | Quantidade | Páginas Afetadas |
|------|-----------|-----------------|
| **Confirmação/Sucesso** | 12 | auth, finish_setup, edit_profile, event, group_created, create_event |
| **Erro** | 13 | auth, verify_otp, finish_setup, edit_profile, event, memory, create_group, edit_event |
| **Neutro/Info** | 8 | group_details ✓, auth, verify_otp, profile, memory, group_created |
| **Loading** | 1 | edit_profile |
| **Inline Persistente** | 1 | verify_otp (considerar manter) |

**Total:** ~35 notificações SnackBar para migrar

---

## 🚀 Plano de Implementação Sugerido

### Fase 1: Expandir TopBanner Component
1. Adicionar métodos estáticos (showSuccess, showError, showInfo, showLoading)
2. Adicionar suporte a ícones
3. Adicionar cores customizáveis
4. Adicionar loading spinner para showLoading
5. Testar todas as variantes

### Fase 2: Migração por Feature (ordem sugerida)
1. ✅ **group_hub** - Já migrado
2. **edit_profile** - 7 notificações (alto impacto)
3. **event** - 5 notificações (alto impacto)
4. **auth/verify_otp/finish_setup** - 8 notificações (flow crítico)
5. **groups (create/created)** - 4 notificações
6. **memory** - 2 notificações
7. **create_event/edit_event** - 2 notificações
8. **profile** - 1 notificação

### Fase 3: Testes & Refinamento
1. Testar todas as notificações em diferentes contextos
2. Ajustar durações conforme feedback
3. Garantir acessibilidade (screen readers)
4. Documentar guidelines de uso

---

## ⚠️ Considerações Importantes

### **Não Migrar (manter como está):**
- **Dialogs modais** - requerem decisão do user (ex: confirmações de delete, join group)
- **Banners inline persistentes** - parte do layout da página (ex: instruções em verify_otp)
- **Validação de forms** - erros inline nos campos

### **Casos Especiais:**
- **Logout** (profile_page) - considerar se notificação é necessária
- **verify_otp banner** - avaliar se deve ser TopBanner persistente ou manter inline

### **Acessibilidade:**
- TopBanner deve anunciar mensagens para screen readers
- Cores devem ter contraste adequado (WCAG AA)
- Loading states devem ser anunciados

### **Performance:**
- Usar `const` constructors onde possível
- Limitar número de overlays simultâneos (1 por vez)
- Dismiss automático para evitar memory leaks

---

## 📝 Notas Finais

Este audit identifica **~35 SnackBars** que devem ser migrados para **TopBanner**, proporcionando:

✅ **Consistência visual** em toda a app  
✅ **Melhor UX** (não tapa conteúdo importante como SnackBar)  
✅ **Drag-to-dismiss** intuitivo  
✅ **Animações suaves** e profissionais  
✅ **Código mais limpo** (API simplificada)  

**Próximos passos:** Expandir TopBanner component e começar migração por feature conforme plano acima.
