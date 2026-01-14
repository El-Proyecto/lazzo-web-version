# iOS Push Notifications via APNs - Deployment Guide

**Audience:** Backend Developer (P2)  
**Status:** 🚀 **Pronto para Deploy** (APNs credentials configurados)  
**Last Updated:** 13 Jan 2026  

---

## 📊 Estado Atual da Infraestrutura

### ✅ JÁ IMPLEMENTADO (Confirmado no dump `supabase_schema_public.sql`):

#### 1. Base de Dados
- ✅ **Tabela `user_push_tokens`** criada e funcional (linhas 3534-3560)
  - Campos: id, user_id, device_token, platform, environment, device_name, app_version, is_active, last_used_at
  - Foreign key para `users(id)` com CASCADE
  - Constraints: environment IN ('production', 'sandbox'), platform IN ('ios', 'android')

- ✅ **RLS Policies completas** (5 policies):
  - "Service role full access to push tokens" (linha 5351)
  - "Users can insert own push tokens" (linha 5469)
  - "Users can view own push tokens" (linha 5695)
  - "Users can update own push tokens" (linha 5577)
  - "Users can delete own push tokens" (linha 5410)

- ✅ **Indexes otimizados** (2 indexes):
  - `idx_user_push_tokens_user_id` (user_id, is_active) - linha 4404
  - `idx_user_push_tokens_last_used` (last_used_at WHERE is_active=true) - linha 4397

- ✅ **Função `trigger_send_push()`** criada (linha 2603-2623)
  - ⚠️ **PROBLEMA:** Chama Edge Function antiga `/send-push-notification` (Firebase)
  - ✅ **SOLUÇÃO:** Alterar para chamar `/send-push-notification-apns`

#### 2. Edge Functions
- ✅ **`send-push-notification-apns`** implementada (supabase/functions/send-push-notification-apns/index.ts)
  - 405 linhas de código TypeScript
  - JWT auth com APNs, suporte production/sandbox, multi-device, token cleanup
  - Status: **Criada mas NÃO deployed**

- ✅ **`notify-events-ending`** funcional (chama `notify_events_ending_soon()`)
- ✅ **`notify-uploads-closing`** funcional (chama `notify_uploads_closing_soon()`)
- ✅ **`invite-resolve`** funcional

- 🗑️ **`send-push-notification`** obsoleta (comentada, Firebase)

#### 3. Notification System
- ✅ **Tabela `notifications`** com campo `category` (push/notifications/actions)
- ✅ **RPC `create_notification_secure`** funcional (linha 540-619)
- ✅ **Triggers** para eventos (event_created, event_confirmed, uploads_open, expense_added, etc.)

### ❌ FALTA IMPLEMENTAR (apenas 3 ações):

1. **Instalar extensão `pg_net`** - Necessária para `net.http_post()`
2. **Alterar função `trigger_send_push()`** - Mudar URL da Edge Function
3. **Criar trigger `on_notification_insert_send_push`** - Ativar envio automático

---

## 🎯 Plano de Deployment (15 minutos)

### Passo 1: Instalar Extensão pg_net (1 min)

**Obrigatório:** A função `trigger_send_push()` usa `net.http_post()` que requer a extensão `pg_net`.

**Executar no Supabase SQL Editor:**

```sql
-- Instalar extensão pg_net (necessária para http_post)
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Verificar instalação
SELECT extname, extversion 
FROM pg_extension 
WHERE extname = 'pg_net';

-- Deve retornar:
-- extname | extversion
-- pg_net  | 0.x.x
```

**⚠️ IMPORTANTE:** Sem esta extensão, receberá erro `schema "net" does not exist` ao criar notificações.

---

### Passo 2: Atualizar Função para APNs (2 min)

**Problema:** A função `trigger_send_push()` chama `/send-push-notification` (Firebase, obsoleta).

**Solução:** Executar no **Supabase SQL Editor**:

```sql
-- Atualizar função para chamar Edge Function APNs
CREATE OR REPLACE FUNCTION public.trigger_send_push()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Only trigger for 'push' category notifications
  IF NEW.category = 'push' THEN
    -- Call APNs Edge Function asynchronously via pg_net
    -- IMPORTANT: Replace YOUR_SERVICE_ROLE_KEY with actual service role key from Supabase Dashboard
    PERFORM
      net.http_post(
        url := 'https://pgpryaelqhspwhplttzb.supabase.co/functions/v1/send-push-notification-apns',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer YOUR_SERVICE_ROLE_KEY'
        ),
        body := jsonb_build_object('notificationId', NEW.id)
      );
  END IF;
  
  RETURN NEW;
END;
$$;
```

**Mudanças:**
- ✅ URL: `/send-push-notification` → `/send-push-notification-apns`
- ✅ Auth: `service_role_key` hardcoded (mais simples e confiável)
- ✅ Project URL: Hardcoded para pgpryaelqhspwhplttzb.supabase.co

**⚠️ ANTES DE EXECUTAR:**
1. Vá para **Supabase Dashboard** → Project Settings → API
2. Copie o **service_role** key (secret, não o anon key!)
3. Substitua `YOUR_SERVICE_ROLE_KEY` no SQL acima com a key real

**Exemplo:**
```sql
'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS...'
```

**Verificação:**
```sql
-- Confirmar função atualizada
SELECT proname, prosrc 
FROM pg_proc 
WHERE proname = 'trigger_send_push';
```

---

### Passo 3: Criar Trigger Automático (1 min)

**Ativar envio automático quando notificação com `category='push'` é criada.**

```sql
-- Criar trigger (caso não exista)
DROP TRIGGER IF EXISTS on_notification_insert_send_push ON public.notifications;

CREATE TRIGGER on_notification_insert_send_push
  AFTER INSERT ON public.notifications
  FOR EACH ROW
  EXECUTE FUNCTION trigger_send_push();
```

**Verificação:**
```sql
-- Confirmar trigger existe
SELECT trigger_name, event_object_table, action_timing, event_manipulation, action_statement
FROM information_schema.triggers
WHERE trigger_name = 'on_notification_insert_send_push';

-- Deve retornar:
-- trigger_name: on_notification_insert_send_push
-- event_object_table: notifications
-- action_timing: AFTER
-- event_manipulation: INSERT
-- action_statement: EXECUTE FUNCTION trigger_send_push()
```

---

### Passo 4: Deploy Edge Function APNs (5 min)

**Pré-requisitos:**
- ✅ APNs credentials configurados (secrets: APNS_KEY_ID, APNS_TEAM_ID, APNS_AUTH_KEY, IOS_BUNDLE_ID)
- ✅ Supabase CLI login efetuado

**Comandos:**

```bash
# 1. Navegar para o projeto
cd /Users/monteiro/projects/app/lazzo

# 2. Verificar secrets (deve mostrar 4 secrets)
supabase secrets list --project-ref pgpryaelqhspwhplttzb

# Expected output:
# APNS_KEY_ID
# APNS_TEAM_ID
# APNS_AUTH_KEY
# IOS_BUNDLE_ID

# 3. Deploy da Edge Function
supabase functions deploy send-push-notification-apns --project-ref pgpryaelqhspwhplttzb

# Expected output:
# Deploying function send-push-notification-apns...
# ✓ Deployed successfully

# 4. Verificar deployment
supabase functions list --project-ref pgpryaelqhspwhplttzb

# Expected output (deve incluir):
# send-push-notification-apns   <timestamp>   <version>
```

**Troubleshooting:**

Se deploy falhar com "Missing secrets":
```bash
# Re-set secrets (substituir valores reais)
supabase secrets set APNS_KEY_ID=ABC1234567 --project-ref pgpryaelqhspwhplttzb
supabase secrets set APNS_TEAM_ID=XYZ9876543 --project-ref pgpryaelqhspwhplttzb
supabase secrets set APNS_AUTH_KEY="$(cat AuthKey_ABC1234567.p8)" --project-ref pgpryaelqhspwhplttzb
supabase secrets set IOS_BUNDLE_ID=com.yourcompany.lazzo --project-ref pgpryaelqhspwhplttzb
```

---

### Passo 5: Testar End-to-End (7 min)

#### 4.1 Verificar Token de Teste

```sql
-- Verificar se há tokens registrados
SELECT 
  id, 
  user_id, 
  LEFT(device_token, 20) || '...' as device_token_preview,
  platform, 
  environment, 
  is_active,
  last_used_at,
  created_at
FROM user_push_tokens
WHERE is_active = true
ORDER BY created_at DESC
LIMIT 5;
```

**Se não houver tokens:** Abrir app no dispositivo TestFlight e aguardar registro automático (Flutter faz isso no launch).

---

#### 4.2 Criar Notificação de Teste

```sql
-- Inserir notificação push de teste
INSERT INTO notifications (
  recipient_user_id, 
  type, 
  category,  -- 'push' vai ativar o trigger
  priority,
  deeplink,
  event_name,
  event_emoji,
  user_name
) VALUES (
  (SELECT id FROM users WHERE email = 'seu-email-testflight@example.com'), -- User com device token
  'eventStartsSoon',
  'push',  -- Importante: isto ativa o trigger
  'high',
  'lazzo://events/test-push',
  'Teste APNs',
  '🧪',
  'Sistema'
) RETURNING id, recipient_user_id, type, category, created_at;
```

**Expected behavior:**
1. ✅ Notificação inserida na tabela `notifications`
2. ✅ Trigger `on_notification_insert_send_push` dispara automaticamente
3. ✅ Função `trigger_send_push()` chama Edge Function via `net.http_post`
4. ✅ Edge Function `send-push-notification-apns` processa
5. ✅ Push enviado para APNs (production ou sandbox)
6. ✅ Dispositivo recebe notificação em 2-5 segundos

---

#### 4.3 Verificar Logs da Edge Function

```bash
# Ver logs em tempo real
supabase functions logs send-push-notification-apns --project-ref pgpryaelqhspwhplttzb --follow

# Procurar por:
# ✅ "Processing notification: <uuid>"
# ✅ "Sending to APNs: production/sandbox"
# ✅ "APNs Response: 200"
# ✅ "Push notifications processed - sent: 1, failed: 0"

# Erros comuns:
# ❌ "Missing APNs credentials" → secrets não configurados
# ❌ "InvalidProviderToken" → Auth key ou Team ID errado
# ❌ "BadDeviceToken" → Token de device inválido (app reinstalado?)
# ❌ "Unregistered" → App desinstalado do dispositivo
```

---

#### 4.4 Verificar no Dispositivo

**Checklist:**
- [ ] Notificação aparece no Notification Center do iOS
- [ ] Banner mostra título e corpo corretos
- [ ] Badge count incrementa
- [ ] Som de notificação toca
- [ ] Tap na notificação abre app
- [ ] Deep link navega para screen correto (lazzo://events/test-push)
- [ ] Notificação aparece no inbox do app (tab Notificações)

**Se não receber push:**

1. **Verificar device token:**
   ```sql
   SELECT device_token, environment, is_active, last_used_at
   FROM user_push_tokens
   WHERE user_id = (SELECT id FROM users WHERE email = 'seu-email@example.com');
   ```

2. **Verificar app build:**
   - TestFlight → `environment` deve ser `'production'`
   - Xcode debug → `environment` deve ser `'sandbox'`

3. **Verificar notificações permitidas:**
   - iOS Settings → Lazzo → Notifications → Allow Notifications = ON

4. **Verificar logs APNs:**
   ```bash
   supabase functions logs send-push-notification-apns | grep "ERROR\|APNs Response"
   ```

---

#### 4.5 Limpar Teste

```sql
-- Remover notificação de teste
DELETE FROM notifications
WHERE event_name = 'Teste APNs'
AND type = 'eventStartsSoon';
```

---

## 🧹 Cleanup Opcional (Remover Firebase)

### Remover Edge Function Obsoleta

```bash
# Opcional: Remover função Firebase comentada
rm -rf /Users/monteiro/projects/app/lazzo/supabase/functions/send-push-notification

# Undeploy da Supabase (se estava deployed)
# NOTA: Só fazer isto SE tiver certeza que nenhuma outra parte do código a chama
# supabase functions delete send-push-notification --project-ref pgpryaelqhspwhplttzb
```

**⚠️ AVISO:** Se houver qualquer dúvida, **deixe a função antiga como está**. Não causa problemas estar presente (só ocupa espaço).

---

## 📊 Monitorização & Maintenance

### 1. Query: Notificações Push Recentes

```sql
SELECT 
  n.id,
  n.type,
  n.priority,
  n.recipient_user_id,
  u.email,
  n.created_at,
  n.deeplink,
  n.event_name
FROM notifications n
JOIN users u ON n.recipient_user_id = u.id
WHERE n.category = 'push'
ORDER BY n.created_at DESC
LIMIT 20;
```

### 2. Query: Tokens Ativos por Platform

```sql
SELECT 
  platform,
  environment,
  COUNT(*) as total_tokens,
  COUNT(*) FILTER (WHERE is_active) as active_tokens,
  COUNT(*) FILTER (WHERE is_active AND last_used_at > now() - interval '7 days') as used_last_7_days
FROM user_push_tokens
GROUP BY platform, environment;
```

### 3. Query: Tokens Inativos (Cleanup)

```sql
-- Ver tokens marcados como inativos (app desinstalado, token inválido)
SELECT 
  upt.id,
  upt.device_token,
  upt.environment,
  upt.last_used_at,
  upt.updated_at,
  u.email
FROM user_push_tokens upt
JOIN users u ON upt.user_id = u.id
WHERE upt.is_active = false
ORDER BY upt.updated_at DESC
LIMIT 50;

-- Cleanup automático (opcional - rodar manualmente ou via pg_cron)
DELETE FROM user_push_tokens
WHERE is_active = false
AND updated_at < now() - interval '90 days';
```

### 4. Edge Function Logs (Common Patterns)

```bash
# Ver sucessos
supabase functions logs send-push-notification-apns | grep "sent: [1-9]"

# Ver erros
supabase functions logs send-push-notification-apns | grep "ERROR\|failed: [1-9]"

# Ver token invalidations
supabase functions logs send-push-notification-apns | grep "Marking token inactive"

# Ver por notification ID específico
supabase functions logs send-push-notification-apns | grep "<notification-uuid>"
```

---

## 🚨 Troubleshooting

### Problema: ERROR: unrecognized configuration parameter "app.supabase_url"

**Sintoma:** Ao criar notificação, erro `42704: unrecognized configuration parameter`.

**Causa:** Função está usando `current_setting()` para parâmetros que não existem.

**Solução:** Use valores diretos (hardcoded) na função:
```sql
CREATE OR REPLACE FUNCTION public.trigger_send_push()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NEW.category = 'push' THEN
    PERFORM
      net.http_post(
        url := 'https://pgpryaelqhspwhplttzb.supabase.co/functions/v1/send-push-notification-apns',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer YOUR_SERVICE_ROLE_KEY'  -- Substituir com key real
        ),
        body := jsonb_build_object('notificationId', NEW.id)
      );
  END IF;
  RETURN NEW;
END;
$$;
```

**Obter service_role key:**
1. Supabase Dashboard → Project Settings → API
2. Copiar **service_role** (secret) key
3. Substituir `YOUR_SERVICE_ROLE_KEY` com o valor real

---

### Problema: ERROR: schema "net" does not exist

**Sintoma:** Ao criar notificação, erro `3F000: schema "net" does not exist`.

**Causa:** Extensão `pg_net` não está instalada.

**Solução:**
```sql
CREATE EXTENSION IF NOT EXISTS pg_net;
```

**Verificar instalação:**
```sql
SELECT extname, extversion FROM pg_extension WHERE extname = 'pg_net';
```

Se não aparecer, contactar suporte Supabase (extensão deve estar disponível por default).

---

### Problema: Trigger não dispara

**Sintoma:** Notificação criada mas Edge Function não é chamada.

**Diagnóstico:**
```sql
-- Verificar trigger existe e está ENABLED
SELECT 
  trigger_name, 
  event_object_table, 
  action_statement,
  status
FROM information_schema.triggers
WHERE trigger_name = 'on_notification_insert_send_push';
```

**Solução:** Re-criar trigger (ver Passo 3).

---

### Problema: "Missing APNs credentials"

**Sintoma:** Edge Function logs mostram erro de credentials.

**Diagnóstico:**
```bash
supabase secrets list --project-ref pgpryaelqhspwhplttzb
```

**Solução:** Re-configurar secrets (ver Passo 4 - Troubleshooting).

---

### Problema: APNs retorna 403 InvalidProviderToken

**Sintoma:** Push não é entregue, logs mostram status 403.

**Causas possíveis:**
- Auth Key (.p8) errado ou corrompido
- Team ID errado
- Key ID errado
- JWT malformado

**Solução:**
1. Re-download `.p8` file da Apple Developer Portal
2. Re-set secrets com valores corretos
3. Redeploy Edge Function

---

### Problema: APNs retorna 410 Unregistered

**Sintoma:** Push não entregue, token marcado como inativo.

**Causa:** App foi desinstalado do dispositivo.

**Solução:** Normal behavior. Token será marcado `is_active=false` automaticamente. User precisa reinstalar app e obter novo token.

---

### Problema: Device não recebe push (sem erro nos logs)

**Checklist:**
1. ✅ Token registrado? (query `user_push_tokens`)
2. ✅ Environment correto? (production para TestFlight, sandbox para debug)
3. ✅ Notificações permitidas no iOS? (Settings → Lazzo)
4. ✅ Bundle ID correto nos secrets?
5. ✅ Device online e conectado?
6. ✅ Notification aparece no inbox do app? (se sim, problema está só no push, não no sistema de notificações)

---

## ✅ Acceptance Criteria

Deployment está completo quando:

- [x] Função `trigger_send_push()` atualizada para chamar `/send-push-notification-apns`
- [x] Trigger `on_notification_insert_send_push` criado e ativo
- [x] Edge Function `send-push-notification-apns` deployed
- [x] Secrets APNs configurados (4 secrets visíveis com `supabase secrets list`)
- [x] Teste end-to-end passou:
  - Notificação criada → Trigger dispara → Edge Function processa → APNs 200 OK → Device recebe
- [x] Deep link funciona ao tap na notificação
- [x] Token `last_used_at` atualizado após envio bem-sucedido
- [x] Logs não mostram erros críticos

---

## 📚 Resources

- **APNs Documentation:** https://developer.apple.com/documentation/usernotifications
- **APNs HTTP/2 API:** https://developer.apple.com/documentation/usernotifications/sending-notification-requests-to-apns
- **Supabase Edge Functions:** https://supabase.com/docs/guides/functions
- **pg_net Extension:** https://supabase.com/docs/guides/database/extensions/pg_net

---

## 🎉 Next Steps

Após deployment bem-sucedido:

1. ✅ Monitorizar logs durante 24-48h
2. ✅ Verificar taxa de entrega (quantos pushes enviados vs quantos recebidos)
3. ✅ Ajustar prioridades de notificações se necessário
4. ✅ Implementar analytics (opcional): tracking de taps, dismissals, conversions
5. → **Proceed to Part 2:** Flutter Implementation (APNS_PUSH_NOTIFICATIONS_PART2_FLUTTER.md)

---

**Deployment concluído! Sistema de push notifications APNs está agora operacional.** 🚀
