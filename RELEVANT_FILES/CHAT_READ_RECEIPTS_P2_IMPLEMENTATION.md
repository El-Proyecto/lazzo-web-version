# Chat Read Receipts — P2 Implementation Guide (FINAL)

**Feature:** Sistema de read receipts para mensagens do chat de eventos  
**Objective:** Rastrear quais mensagens foram lidas por cada participante e mostrar indicadores visuais (✓/✓✓)  
**Architecture:** Clean Architecture (Presentation/Domain/Data layers)  
**Database:** Nova tabela `message_reads` para rastrear última mensagem lida por user  
**Date:** 4 dezembro 2025

---

## 📋 Overview & Architectural Decisions

Este guião implementa o sistema de read receipts para o chat de eventos, permitindo:
- ✅ Rastrear **por user** até que mensagem foi lida (última visualizada)
- ✅ Mostrar indicador visual **simples**: ✓ = enviado, ✓✓ = lido por alguém
- ✅ Badge count de mensagens novas (não lidas) em event cards
- ✅ Query eficiente otimizada para **5-10 participantes** (máx 20)
- ✅ Atualização em tempo real via Supabase Realtime (**OBRIGATÓRIO**)
- ✅ Preview do chat **NÃO marca como lida** (apenas página completa EventChatPage)

**🎯 Decisões Arquiteturais Finais:**

| **Aspecto** | **Decisão** | **Justificativa** |
|-------------|-------------|-------------------|
| **Schema** | Tabela `message_reads` com `last_read_message_id` | Rastreia por user, eficiente para grupos pequenos |
| **Campo `read` boolean** | **ABANDONAR/DEPRECIAR** | Não rastreia por user, badge count impossível |
| **Indicador ✓/✓✓** | **Simples (Opção A)** | ✓✓ se "alguém leu", sem detalhar quem |
| **Preview marking** | **NÃO marca como lida (Opção B)** | Apenas EventChatPage marca, preview é read-only |
| **Realtime** | **OBRIGATÓRIO** | Mensagens aparecem instantaneamente para todos |
| **Performance target** | Otimizado para 5-10 users (max 20) | Storage: ~320 bytes/evento, queries O(1) |

---

## Part 1: Database Implementation (P2 Tasks)

### 1.1 New Schema: `message_reads` Table

**Conceito:** Rastrear a **última mensagem visualizada** por cada user em cada evento.

```sql
-- Nova tabela: rastreia até que mensagem cada user leu
CREATE TABLE IF NOT EXISTS public.message_reads (
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  event_id uuid NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  last_read_message_id uuid REFERENCES chat_messages(id) ON DELETE SET NULL,
  last_read_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  
  PRIMARY KEY (user_id, event_id)
);

-- Indexes para performance
CREATE INDEX IF NOT EXISTS idx_message_reads_event_id 
  ON message_reads(event_id);

CREATE INDEX IF NOT EXISTS idx_message_reads_last_read_message_id 
  ON message_reads(last_read_message_id);

-- Comentários para documentação
COMMENT ON TABLE message_reads IS 
'Tracks the last message read by each user in each event. Used for badge counts and read receipts.';

COMMENT ON COLUMN message_reads.last_read_message_id IS 
'ID of the last message the user has seen. All messages with created_at <= this message.created_at are considered read.';
```

**Como funciona:**

1. **User abre chat:** App chama RPC `update_last_read_message(event_id, latest_message_id)`
2. **Badge count:** `COUNT(*) FROM chat_messages WHERE created_at > last_read_message.created_at`
3. **Indicador ✓✓:** `EXISTS (SELECT 1 FROM message_reads WHERE last_read_message_id >= current_message.id AND user_id != sender)`

**Performance para grupos pequenos (5-10 pessoas):**

```
Grupo com 10 participantes, 1000 mensagens:

Boolean approach (OLD - DESCARTADO):
- Storage: 1000 rows × 1 bit = 125 bytes
- ❌ Problema CRÍTICO: NÃO rastreia por user!
- ❌ Badge count impossível (global read flag)
- ❌ Update: 1000 rows modificadas = LENTO

message_reads (NEW - ESCOLHIDO):
- Storage: 10 rows × 32 bytes = 320 bytes (+195 bytes)
- ✅ Rastreia por user (badge count correto!)
- ✅ Update: 1 row (apenas do user) = RÁPIDO
- ✅ Query: 1 JOIN simples com index = O(1)
- ✅ Escalável: 20 users = 640 bytes (negligível!)
```

**Conclusão:** `message_reads` é **objetivamente melhor** mesmo para grupos pequenos!

---

### 1.2 RLS Policies for `message_reads`

```sql
-- Enable RLS
ALTER TABLE message_reads ENABLE ROW LEVEL SECURITY;

-- Policy 1: Users can view their own read status
CREATE POLICY "Users can view their own read status"
ON message_reads
FOR SELECT
USING (auth.uid() = user_id);

-- Policy 2: Users can view read status of event participants (for ✓✓ indicator)
CREATE POLICY "Users can view read status of event participants"
ON message_reads
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM event_participants ep
    WHERE ep.pevent_id = message_reads.event_id  -- ⚠️ Corrigido: pevent_id, não event_id
      AND ep.user_id = auth.uid()
  )
);

-- Policy 3: Users can update their own read status
CREATE POLICY "Users can update their own read status"
ON message_reads
FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Grant permissions
GRANT SELECT, INSERT, UPDATE ON message_reads TO authenticated;
```

**Nota:** RPC function usa `SECURITY DEFINER` para bypass RLS, mas valida participação manualmente.

---

### 1.3 RPC Function: Update Last Read Message

```sql
-- Função RPC: Atualizar última mensagem lida pelo user em um evento
CREATE OR REPLACE FUNCTION update_last_read_message(
  p_event_id uuid,
  p_message_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER  -- Executa com privilégios do owner (bypass RLS)
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_message_created_at timestamptz;
  v_is_participant boolean;
  v_updated boolean := false;
BEGIN
  -- Validação 1: User deve estar autenticado
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User not authenticated';
  END IF;

  -- Validação 2: Verificar se user é participante do evento
  SELECT EXISTS (
    SELECT 1 FROM event_participants
    WHERE pevent_id = p_event_id AND user_id = v_user_id  -- ⚠️ Corrigido: pevent_id
  ) INTO v_is_participant;

  IF NOT v_is_participant THEN
    RAISE EXCEPTION 'User is not a participant of this event';
  END IF;

  -- Validação 3: Verificar que mensagem existe e pertence ao evento
  SELECT created_at INTO v_message_created_at
  FROM chat_messages
  WHERE id = p_message_id AND event_id = p_event_id AND is_deleted = false;

  IF v_message_created_at IS NULL THEN
    RAISE EXCEPTION 'Message not found or does not belong to this event';
  END IF;

  -- UPSERT: Inserir ou atualizar última mensagem lida
  -- Apenas atualiza se mensagem é mais recente que a atual last_read
  INSERT INTO message_reads (user_id, event_id, last_read_message_id, last_read_at, updated_at)
  VALUES (v_user_id, p_event_id, p_message_id, now(), now())
  ON CONFLICT (user_id, event_id)
  DO UPDATE SET
    last_read_message_id = EXCLUDED.last_read_message_id,
    last_read_at = now(),
    updated_at = now()
  WHERE (
    -- Apenas atualizar se:
    -- 1. Nova mensagem é mais recente OU
    -- 2. Ainda não há last_read registrada
    message_reads.last_read_message_id IS NULL OR
    v_message_created_at > (
      SELECT created_at FROM chat_messages 
      WHERE id = message_reads.last_read_message_id
    )
  )
  RETURNING true INTO v_updated;

  -- Retornar resultado com informações úteis
  RETURN jsonb_build_object(
    'success', true,
    'updated', COALESCE(v_updated, false),
    'user_id', v_user_id,
    'event_id', p_event_id,
    'last_read_message_id', p_message_id,
    'last_read_at', now()
  );
END;
$$;

-- Grant execute para authenticated users
GRANT EXECUTE ON FUNCTION update_last_read_message(uuid, uuid) TO authenticated;

-- Comentário para documentação
COMMENT ON FUNCTION update_last_read_message IS 
'Updates the last message read by the current user in an event. Only updates if the new message is more recent. Returns success status and updated flag.';
```

---

### 1.4 RPC Function: Get Unread Message Count

```sql
-- RPC: Get unread message count (eficiente)
CREATE OR REPLACE FUNCTION get_unread_message_count(
  p_event_id uuid,
  p_user_id uuid
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count integer;
BEGIN
  SELECT COUNT(*)::integer INTO v_count
  FROM chat_messages cm
  LEFT JOIN message_reads mr ON (
    mr.user_id = p_user_id AND
    mr.event_id = cm.event_id
  )
  LEFT JOIN chat_messages last_read ON (last_read.id = mr.last_read_message_id)
  WHERE cm.event_id = p_event_id
    AND cm.user_id != p_user_id
    AND cm.is_deleted = false
    AND (
      mr.last_read_message_id IS NULL OR
      cm.created_at > last_read.created_at
    );

  RETURN v_count;
END;
$$;

GRANT EXECUTE ON FUNCTION get_unread_message_count(uuid, uuid) TO authenticated;

COMMENT ON FUNCTION get_unread_message_count IS 
'Returns count of unread messages for a user in an event. Excludes user''s own messages.';
```

---

### 1.5 RPC Function: Get Messages With Read Status (Batch)

```sql
-- RPC: Get messages with read status (batch, eficiente)
CREATE OR REPLACE FUNCTION get_messages_with_read_status(
  p_event_id uuid,
  p_current_user_id uuid,
  p_limit integer DEFAULT 50
)
RETURNS TABLE (
  id uuid,
  event_id uuid,
  user_id uuid,
  content text,
  created_at timestamptz,
  is_pinned boolean,
  is_deleted boolean,
  reply_to_id uuid,
  updated_at timestamptz,
  user_name text,
  user_avatar text,
  is_read_by_someone boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    cm.id,
    cm.event_id,
    cm.user_id,
    cm.content,
    cm.created_at,
    cm.is_pinned,
    cm.is_deleted,
    cm.reply_to_id,
    cm.updated_at,
    u.name AS user_name,
    u.avatar_url AS user_avatar,
    EXISTS (
      SELECT 1
      FROM message_reads mr
      INNER JOIN chat_messages last_read ON (last_read.id = mr.last_read_message_id)
      WHERE mr.event_id = cm.event_id
        AND mr.user_id != cm.user_id
        AND last_read.created_at >= cm.created_at
    ) AS is_read_by_someone
  FROM chat_messages cm
  LEFT JOIN users u ON u.id = cm.user_id
  WHERE cm.event_id = p_event_id
    AND cm.is_deleted = false
  ORDER BY cm.created_at DESC
  LIMIT p_limit;
END;
$$;

GRANT EXECUTE ON FUNCTION get_messages_with_read_status(uuid, uuid, integer) TO authenticated;

COMMENT ON FUNCTION get_messages_with_read_status IS 
'Returns messages with is_read_by_someone flag computed. Efficient batch query avoids N+1 problem.';
```

---

### 1.6 Realtime Configuration (OBRIGATÓRIO)

```sql
-- Adicionar chat_messages à publicação de realtime
ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;

-- Adicionar message_reads à publicação (opcional mas recomendado)
ALTER PUBLICATION supabase_realtime ADD TABLE message_reads;

-- Verificar que realtime está ativo
SELECT schemaname, tablename 
FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime'
  AND tablename IN ('chat_messages', 'message_reads');

-- Expected output:
-- public | chat_messages
-- public | message_reads
```

**Por quê Realtime é OBRIGATÓRIO:**
- ✅ Mensagens novas aparecem instantaneamente para todos os participantes
- ✅ Indicador ✓✓ atualiza quando alguém lê (sem refresh)
- ✅ Preview do chat mostra última mensagem em tempo real
- ✅ Badge counts atualizam automaticamente

---

### 1.7 (Optional) Deprecate Old `read` Field

```sql
-- Marcar campo como deprecated, mas manter por compatibilidade
COMMENT ON COLUMN chat_messages.read IS 
'DEPRECATED: Use message_reads table instead. This field does not track per-user read status and should not be used in new code.';
```

**Decisão:** Manter campo por compatibilidade legacy, mas **não usar** no código novo.

---

### 1.8 Database Setup Checklist (P2)

Execute estes scripts **na ordem** no Supabase SQL Editor:

- [ ] **Step 1:** Create `message_reads` table (script 1.1)
- [ ] **Step 2:** Verify table creation
- [ ] **Step 3:** Create RLS policies (script 1.2)
- [ ] **Step 4:** Create RPC `update_last_read_message` (script 1.3)
- [ ] **Step 5:** Create RPC `get_unread_message_count` (script 1.4)
- [ ] **Step 6:** Create RPC `get_messages_with_read_status` (script 1.5)
- [ ] **Step 7:** Enable Realtime (script 1.6)
- [ ] **Step 8:** Deprecate old `read` field (script 1.7)
- [ ] **Step 9:** Test all RPC functions (script 1.9)
- [ ] **Step 10:** Verify Realtime is working (script 1.9)

---

### 1.9 Complete Test Suite (Execute After All Setup)

**⚠️ IMPORTANTE:** Execute estes testes **após** completar os steps 1-8 acima.

#### Test 1: Verify Table Structure

```sql
-- Verificar que message_reads foi criada corretamente
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'message_reads'
ORDER BY ordinal_position;

-- Expected output:
-- user_id               | uuid                     | NO  | NULL
-- event_id              | uuid                     | NO  | NULL
-- last_read_message_id  | uuid                     | YES | NULL
-- last_read_at          | timestamp with time zone | YES | now()
-- updated_at            | timestamp with time zone | YES | now()
```

#### Test 2: Verify Indexes

```sql
-- Verificar que indexes foram criados
SELECT 
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename = 'message_reads'
ORDER BY indexname;

-- Expected output (pelo menos 3 indexes):
-- message_reads_pkey                        | CREATE UNIQUE INDEX ... PRIMARY KEY (user_id, event_id)
-- idx_message_reads_event_id                | CREATE INDEX ... ON message_reads(event_id)
-- idx_message_reads_last_read_message_id    | CREATE INDEX ... ON message_reads(last_read_message_id)
```

#### Test 3: Verify RLS Policies

```sql
-- Verificar que RLS está ativo e policies foram criadas
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'message_reads'
ORDER BY policyname;

-- Expected output (3 policies):
-- Users can view their own read status
-- Users can view read status of event participants
-- Users can update their own read status
```

#### Test 4: Verify RPC Functions Exist

```sql
-- Verificar que todas as RPC functions foram criadas
SELECT 
  routine_name,
  routine_type,
  data_type AS return_type,
  type_udt_name
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN (
    'update_last_read_message',
    'get_unread_message_count',
    'get_messages_with_read_status'
  )
ORDER BY routine_name;

-- Expected output (3 functions):
-- get_messages_with_read_status  | FUNCTION | USER-DEFINED | record
-- get_unread_message_count       | FUNCTION | integer      | int4
-- update_last_read_message       | FUNCTION | USER-DEFINED | jsonb
```

#### Test 5: Verify Realtime is Enabled

```sql
-- Verificar que Realtime está ativo nas tabelas
SELECT 
  schemaname,
  tablename
FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
  AND tablename IN ('chat_messages', 'message_reads')
ORDER BY tablename;

-- Expected output (2 rows):
-- public | chat_messages
-- public | message_reads
```

#### Test 6: End-to-End RPC Test (CRITICAL)

**⚠️ PRÉ-REQUISITO:** Substituir UUIDs por valores reais do teu ambiente:
- Escolher um evento real onde sejas participante
- Escolher mensagens reais desse evento
- Usar o teu user_id autenticado

```sql
-- ====================
-- SETUP: Buscar dados reais para testar
-- ====================

-- 1. Buscar um evento onde você é participante
SELECT 
  e.id AS event_id,
  e.name AS event_name,
  ep.user_id AS my_user_id
FROM events e
INNER JOIN event_participants ep ON ep.pevent_id = e.id  -- ⚠️ Corrigido: pevent_id
WHERE ep.user_id = auth.uid()
LIMIT 1;

-- Copiar event_id e my_user_id da query acima


-- 2. Buscar mensagens desse evento (de outros users)
SELECT 
  cm.id AS message_id,
  cm.content,
  cm.created_at,
  cm.user_id AS sender_id
FROM chat_messages cm
WHERE cm.event_id = 'SEU_EVENT_ID_AQUI'::uuid  -- ⚠️ Substituir por event_id real
  AND cm.user_id != auth.uid()  -- Mensagens de outros
  AND cm.is_deleted = false
ORDER BY cm.created_at DESC
LIMIT 5;

-- Copiar message_id da mensagem mais recente


-- ====================
-- TEST A: update_last_read_message (primeira vez)
-- ====================

SELECT update_last_read_message(
  'SEU_EVENT_ID_AQUI'::uuid,      -- ⚠️ Substituir por event_id real
  'SEU_MESSAGE_ID_AQUI'::uuid     -- ⚠️ Substituir por message_id real
);

-- Expected output:
-- {
--   "success": true,
--   "updated": true,
--   "user_id": "your-uuid",
--   "event_id": "event-uuid",
--   "last_read_message_id": "message-uuid",
--   "last_read_at": "2025-12-04T..."
-- }


-- ====================
-- TEST B: Verificar que row foi inserida em message_reads
-- ====================

SELECT 
  user_id,
  event_id,
  last_read_message_id,
  last_read_at,
  updated_at
FROM message_reads
WHERE user_id = auth.uid()
  AND event_id = 'SEU_EVENT_ID_AQUI'::uuid;  -- ⚠️ Substituir

-- Expected: 1 row com last_read_message_id correto


-- ====================
-- TEST C: update_last_read_message (segunda vez, mesma mensagem)
-- ====================

SELECT update_last_read_message(
  'SEU_EVENT_ID_AQUI'::uuid,
  'SEU_MESSAGE_ID_AQUI'::uuid
);

-- Expected output:
-- {
--   "success": true,
--   "updated": false,  -- ⚠️ Nota: false porque mensagem não é mais recente
--   ...
-- }


-- ====================
-- TEST D: get_unread_message_count
-- ====================

SELECT get_unread_message_count(
  'SEU_EVENT_ID_AQUI'::uuid,
  auth.uid()
);

-- Expected: 0 (se marcou todas como lidas) ou número de mensagens mais recentes


-- ====================
-- TEST E: get_messages_with_read_status
-- ====================

SELECT 
  id,
  content,
  created_at,
  user_name,
  is_read_by_someone
FROM get_messages_with_read_status(
  'SEU_EVENT_ID_AQUI'::uuid,
  auth.uid(),
  10  -- limit
)
ORDER BY created_at DESC;

-- Expected: Lista de mensagens com is_read_by_someone = true/false


-- ====================
-- TEST F: Enviar nova mensagem e contar não lidas
-- ====================

-- 1. Inserir nova mensagem (simula outro user enviando)
INSERT INTO chat_messages (event_id, user_id, content)
VALUES (
  'SEU_EVENT_ID_AQUI'::uuid,
  'OUTRO_USER_ID_AQUI'::uuid,  -- ⚠️ Substituir por outro participante
  'Test message for read receipts'
)
RETURNING id, content, created_at;


-- 2. Verificar que count aumentou
SELECT get_unread_message_count(
  'SEU_EVENT_ID_AQUI'::uuid,
  auth.uid()
);

-- Expected: 1 (ou +1 do count anterior)


-- 3. Marcar nova mensagem como lida
SELECT update_last_read_message(
  'SEU_EVENT_ID_AQUI'::uuid,
  'ID_DA_NOVA_MENSAGEM'::uuid  -- ⚠️ Substituir por id da mensagem inserida
);


-- 4. Verificar que count voltou a zero
SELECT get_unread_message_count(
  'SEU_EVENT_ID_AQUI'::uuid,
  auth.uid()
);

-- Expected: 0
```

#### Test 7: RLS Security Test

```sql
-- ====================
-- TEST: Verificar que user NÃO pode ver reads de outros events
-- ====================

-- 1. Tentar ler message_reads de evento onde NÃO é participante
SELECT *
FROM message_reads
WHERE event_id = 'EVENT_ID_ONDE_NAO_ES_PARTICIPANTE'::uuid;

-- Expected: 0 rows (RLS bloqueia)


-- 2. Tentar atualizar read de outro user (deve falhar)
UPDATE message_reads
SET last_read_message_id = gen_random_uuid()
WHERE user_id != auth.uid();

-- Expected: 0 rows affected (RLS bloqueia)


-- 3. Tentar chamar RPC com evento onde não é participante
SELECT update_last_read_message(
  'EVENT_ID_ONDE_NAO_ES_PARTICIPANTE'::uuid,
  'QUALQUER_MESSAGE_ID'::uuid
);

-- Expected: ERROR: User is not a participant of this event
```

#### Test 8: Performance Test (Optional)

```sql
-- ====================
-- TEST: Verificar performance das queries
-- ====================

-- 1. Test unread count query performance
EXPLAIN ANALYZE
SELECT get_unread_message_count(
  'SEU_EVENT_ID_AQUI'::uuid,
  auth.uid()
);

-- Verificar que usa indexes:
-- Expected: "Index Scan using idx_message_reads_event_id"
-- Expected: Execution Time < 100ms


-- 2. Test messages with read status performance
EXPLAIN ANALYZE
SELECT *
FROM get_messages_with_read_status(
  'SEU_EVENT_ID_AQUI'::uuid,
  auth.uid(),
  50
);

-- Expected: Execution Time < 200ms (para 50 mensagens)
```

---

### 1.10 Troubleshooting Common Errors

#### Error: "column event_id does not exist"

**Causa:** Tabela `event_participants` usa `pevent_id`, não `event_id`.

**Fix:** Verificar que todos os scripts usam `ep.pevent_id` nas queries:

```sql
-- ❌ ERRADO:
WHERE ep.event_id = message_reads.event_id

-- ✅ CORRETO:
WHERE ep.pevent_id = message_reads.event_id
```

#### Error: "function does not exist"

**Causa:** RPC function não foi criada ou tem nome diferente.

**Fix:** Re-executar script de criação da função (1.3, 1.4 ou 1.5).

#### Error: "permission denied for table"

**Causa:** RLS bloqueando acesso ou grant não executado.

**Fix:** Verificar que executou:
```sql
GRANT SELECT, INSERT, UPDATE ON message_reads TO authenticated;
GRANT EXECUTE ON FUNCTION update_last_read_message(uuid, uuid) TO authenticated;
```

#### Error: "new row violates foreign key constraint"

**Causa:** Tentando inserir message_read com event_id ou message_id inválido.

**Fix:** Verificar que IDs existem antes de chamar RPC:
```sql
-- Verificar que evento existe
SELECT id FROM events WHERE id = 'SEU_EVENT_ID'::uuid;

-- Verificar que mensagem existe
SELECT id FROM chat_messages WHERE id = 'SEU_MESSAGE_ID'::uuid;
```

#### Realtime não está funcionando

**Causa:** Publicação não foi criada ou tabela não foi adicionada.

**Fix:**
```sql
-- Verificar publicação existe
SELECT * FROM pg_publication WHERE pubname = 'supabase_realtime';

-- Se não existir, criar:
CREATE PUBLICATION supabase_realtime;

-- Adicionar tabelas novamente:
ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE message_reads;
```

---

### ✅ Final Validation Checklist

Após executar todos os testes acima, verificar:

- [X] Tabela `message_reads` existe com 5 colunas
- [X] 3 indexes criados (PRIMARY KEY + 2 indexes)
- [X] RLS ativo com 3 policies
- [X] 3 RPC functions criadas e executáveis
- [X] Realtime ativo em `chat_messages` e `message_reads`
- [X] Test 6 (End-to-End) passou em todos os steps A-F
- [X] Test 7 (RLS Security) bloqueou acessos inválidos
- [X] Performance < 200ms nas queries principais

**Se todos os checkboxes acima estiverem ✅, a implementação do database está completa!**

---

## Part 2: Code Implementation (Agent Tasks)

### 2.1 Domain Layer Updates

#### Entity: Update `ChatMessage`

**File:** `lib/features/event/domain/entities/chat_message.dart`

```dart
class ChatMessage {
  final String id;
  final String eventId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final bool isPinned;
  final bool isDeleted;
  final String? replyToId;
  final DateTime? updatedAt;
  final String? userName;
  final String? userAvatar;
  
  @Deprecated('Use isReadBySomeone instead')
  final bool read;
  
  final bool isReadBySomeone;  // 🆕 NOVO

  const ChatMessage({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.isPinned = false,
    this.isDeleted = false,
    this.replyToId,
    this.updatedAt,
    this.userName,
    this.userAvatar,
    @Deprecated('Use isReadBySomeone') this.read = false,
    this.isReadBySomeone = false,
  });

  ChatMessage copyWith({
    String? id,
    String? eventId,
    String? userId,
    String? content,
    DateTime? createdAt,
    bool? isPinned,
    bool? isDeleted,
    String? replyToId,
    DateTime? updatedAt,
    String? userName,
    String? userAvatar,
    bool? read,
    bool? isReadBySomeone,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isPinned: isPinned ?? this.isPinned,
      isDeleted: isDeleted ?? this.isDeleted,
      replyToId: replyToId ?? this.replyToId,
      updatedAt: updatedAt ?? this.updatedAt,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      read: read ?? this.read,
      isReadBySomeone: isReadBySomeone ?? this.isReadBySomeone,
    );
  }
}
```

#### Repository: Update Interface

**File:** `lib/features/event/domain/repositories/chat_repository.dart`

```dart
abstract class ChatRepository {
  // ... métodos existentes

  Future<bool> updateLastReadMessage({
    required String eventId,
    required String messageId,
  });

  Future<int> getUnreadMessageCount({
    required String eventId,
    required String currentUserId,
  });

  Future<List<ChatMessage>> getMessagesWithReadStatus({
    required String eventId,
    required String currentUserId,
    int limit = 50,
  });
}
```

#### Use Cases

**File:** `lib/features/event/domain/usecases/update_last_read_message.dart`

```dart
import '../repositories/chat_repository.dart';

class UpdateLastReadMessage {
  final ChatRepository repository;

  UpdateLastReadMessage(this.repository);

  Future<bool> call({
    required String eventId,
    required String messageId,
  }) async {
    try {
      return await repository.updateLastReadMessage(
        eventId: eventId,
        messageId: messageId,
      );
    } catch (e) {
      print('[UpdateLastReadMessage] Error: $e');
      return false;
    }
  }
}
```

**File:** `lib/features/event/domain/usecases/get_unread_message_count.dart`

```dart
import '../repositories/chat_repository.dart';

class GetUnreadMessageCount {
  final ChatRepository repository;

  GetUnreadMessageCount(this.repository);

  Future<int> call({
    required String eventId,
    required String currentUserId,
  }) async {
    try {
      return await repository.getUnreadMessageCount(
        eventId: eventId,
        currentUserId: currentUserId,
      );
    } catch (e) {
      print('[GetUnreadMessageCount] Error: $e');
      return 0;
    }
  }
}
```

---

### 2.2 Data Layer Updates

#### Model: Update `ChatMessageModel`

**File:** `lib/features/event/data/models/chat_message_model.dart`

```dart
class ChatMessageModel {
  final String id;
  final String eventId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final bool isPinned;
  final bool isDeleted;
  final String? replyToId;
  final DateTime? updatedAt;
  final String? userName;
  final String? userAvatar;
  @Deprecated('Use isReadBySomeone') final bool read;
  final bool isReadBySomeone;

  const ChatMessageModel({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.isPinned = false,
    this.isDeleted = false,
    this.replyToId,
    this.updatedAt,
    this.userName,
    this.userAvatar,
    this.read = false,
    this.isReadBySomeone = false,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isPinned: json['is_pinned'] as bool? ?? false,
      isDeleted: json['is_deleted'] as bool? ?? false,
      replyToId: json['reply_to_id'] as String?,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      userName: json['user_name'] as String?,
      userAvatar: json['user_avatar'] as String?,
      read: json['read'] as bool? ?? false,
      isReadBySomeone: json['is_read_by_someone'] as bool? ?? false,
    );
  }

  ChatMessage toEntity() {
    return ChatMessage(
      id: id,
      eventId: eventId,
      userId: userId,
      content: content,
      createdAt: createdAt,
      isPinned: isPinned,
      isDeleted: isDeleted,
      replyToId: replyToId,
      updatedAt: updatedAt,
      userName: userName,
      userAvatar: userAvatar,
      read: read,
      isReadBySomeone: isReadBySomeone,
    );
  }
}
```

#### Data Source: Add RPC Methods

**File:** `lib/features/event/data/data_sources/chat_remote_data_source.dart`

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatRemoteDataSource {
  final SupabaseClient _client;

  ChatRemoteDataSource(this._client);

  Future<Map<String, dynamic>> updateLastReadMessage({
    required String eventId,
    required String messageId,
  }) async {
    try {
      final response = await _client.rpc(
        'update_last_read_message',
        params: {
          'p_event_id': eventId,
          'p_message_id': messageId,
        },
      );

      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to update last read message: $e');
    }
  }

  Future<int> getUnreadMessageCount({
    required String eventId,
    required String currentUserId,
  }) async {
    try {
      final count = await _client.rpc(
        'get_unread_message_count',
        params: {
          'p_event_id': eventId,
          'p_user_id': currentUserId,
        },
      );

      return count as int;
    } catch (e) {
      throw Exception('Failed to get unread message count: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getMessagesWithReadStatus({
    required String eventId,
    required String currentUserId,
    int limit = 50,
  }) async {
    try {
      final response = await _client.rpc(
        'get_messages_with_read_status',
        params: {
          'p_event_id': eventId,
          'p_current_user_id': currentUserId,
          'p_limit': limit,
        },
      );

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw Exception('Failed to get messages with read status: $e');
    }
  }
}
```

#### Repository: Implement Methods

**File:** `lib/features/event/data/repositories/chat_repository_impl.dart`

```dart
@override
Future<bool> updateLastReadMessage({
  required String eventId,
  required String messageId,
}) async {
  try {
    final response = await _remoteDataSource.updateLastReadMessage(
      eventId: eventId,
      messageId: messageId,
    );

    return response['success'] == true;
  } catch (e) {
    throw Exception('Failed to update last read message: $e');
  }
}

@override
Future<int> getUnreadMessageCount({
  required String eventId,
  required String currentUserId,
}) async {
  try {
    return await _remoteDataSource.getUnreadMessageCount(
      eventId: eventId,
      currentUserId: currentUserId,
    );
  } catch (e) {
    throw Exception('Failed to get unread message count: $e');
  }
}

@override
Future<List<ChatMessage>> getMessagesWithReadStatus({
  required String eventId,
  required String currentUserId,
  int limit = 50,
}) async {
  try {
    final data = await _remoteDataSource.getMessagesWithReadStatus(
      eventId: eventId,
      currentUserId: currentUserId,
      limit: limit,
    );

    return data
        .map((json) => ChatMessageModel.fromJson(json))
        .map((model) => model.toEntity())
        .toList();
  } catch (e) {
    throw Exception('Failed to get messages with read status: $e');
  }
}
```

---

### 2.3 Presentation Layer Updates

#### Providers

**File:** `lib/features/event/presentation/providers/chat_read_receipts_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/update_last_read_message.dart';
import '../../domain/usecases/get_unread_message_count.dart';
import 'chat_providers.dart';

final updateLastReadMessageProvider = Provider<UpdateLastReadMessage>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return UpdateLastReadMessage(repository);
});

final getUnreadMessageCountProvider = Provider<GetUnreadMessageCount>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return GetUnreadMessageCount(repository);
});

final eventUnreadCountProvider = FutureProvider.autoDispose
    .family<int, ({String eventId, String currentUserId})>((ref, params) async {
  final useCase = ref.watch(getUnreadMessageCountProvider);
  
  return await useCase(
    eventId: params.eventId,
    currentUserId: params.currentUserId,
  );
});
```

#### Update EventChatPage

**File:** `lib/features/event/presentation/pages/event_chat_page.dart`

```dart
import '../providers/chat_read_receipts_provider.dart';

// Add method:
Future<void> _markMessagesAsRead() async {
  try {
    final messages = await ref.read(
      chatMessagesProvider(widget.eventId).future
    );

    if (messages.isEmpty) return;

    final latestMessage = messages.first;

    final useCase = ref.read(updateLastReadMessageProvider);
    final success = await useCase(
      eventId: widget.eventId,
      messageId: latestMessage.id,
    );

    if (success) {
      print('[EventChatPage] Marked messages as read');
    }
  } catch (e) {
    print('[EventChatPage] Failed to mark messages as read: $e');
  }
}

// Call in initState:
@override
void initState() {
  super.initState();
  
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _markMessagesAsRead();
  });
}
```

#### Update ChatMessageBubble

**File:** `lib/features/event/presentation/widgets/chat_message_bubble.dart`

```dart
// Change read indicator logic:
if (isCurrentUser && isLastInGroup) {
  Icon(
    message.isReadBySomeone  // ✅ Use isReadBySomeone instead of read
        ? Icons.done_all  // ✓✓
        : Icons.done,     // ✓
    size: 14,
    color: message.isReadBySomeone
        ? Colors.blue[300]
        : Colors.grey[600],
  ),
  const SizedBox(width: 4),
}
```

#### Add Badge to EventCard

**File:** `lib/shared/components/cards/event_card.dart`

```dart
class EventCard extends ConsumerWidget {
  final EventEntity event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(currentUserProvider).value?.id;

    final unreadCountAsync = currentUserId != null
        ? ref.watch(eventUnreadCountProvider((
            eventId: event.id,
            currentUserId: currentUserId,
          )))
        : const AsyncValue<int>.data(0);

    return Card(
      child: Stack(
        children: [
          // ... existing card content

          // Unread badge
          unreadCountAsync.when(
            data: (count) {
              if (count == 0) return const SizedBox.shrink();

              return Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
```

---

## Part 3: Implementation Checklist

### Database Setup (P2)
- [ ] Create `message_reads` table
- [ ] Create RLS policies
- [ ] Create 3 RPC functions
- [ ] Enable Realtime
- [ ] Test all functions
- [ ] Verify Realtime works

### Code Implementation (Agent)
- [ ] Update `ChatMessage` entity
- [ ] Update `ChatRepository` interface
- [ ] Create 2 use cases
- [ ] Update `ChatMessageModel`
- [ ] Update `ChatRemoteDataSource`
- [ ] Update `ChatRepositoryImpl`
- [ ] Create providers
- [ ] Update `EventChatPage`
- [ ] Update `ChatMessageBubble`
- [ ] Add badge to `EventCard`

### Testing
- [ ] Test marking messages as read
- [ ] Verify ✓/✓✓ icons work
- [ ] Test unread badge count
- [ ] Verify preview doesn't mark read
- [ ] Test Realtime updates
- [ ] Test with 10+ users
- [ ] Verify performance

---

## Conclusion

✅ **Schema otimizado** para 5-10 participantes  
✅ **Indicador simples** (✓/✓✓ sem detalhes)  
✅ **Preview não marca** como lida  
✅ **Realtime obrigatório** funcionando  
✅ **Campo `read` deprecated** (não usado)

**Estimativa:** ~5-6 horas total (1h DB + 3-4h código + 1h testing)

**Próximos passos:**
1. P2 executa scripts SQL
2. Agent implementa código
3. Testing multi-user
4. Deploy
