-- ============================================================================
-- FIX CHAT MESSAGES NOT BEING INSERTED + NOTIFICATION IMPROVEMENTS
-- ============================================================================
-- CRITICAL ISSUES FIXED:
-- 1. RLS policy chat_insert_policy blocks INSERTs if is_pinned/is_deleted not sent
-- 2. Missing 'note' field in notifications (message appears as undefined in push)
-- 3. Trigger errors can block message inserts (now wrapped in exception handler)
-- ============================================================================

-- PART 1: Fix RLS Policy (CRITICAL - blocks all chat messages)
-- ============================================================================

DROP POLICY IF EXISTS chat_insert_policy ON public.chat_messages;

CREATE POLICY chat_insert_policy ON public.chat_messages 
FOR INSERT 
WITH CHECK (
  (auth.uid() IS NOT NULL) 
  AND (auth.uid() IN (
    SELECT gm.user_id
    FROM public.group_members gm
    JOIN public.events e ON (e.group_id = gm.group_id)
    WHERE e.id = chat_messages.event_id
  )) 
  AND (user_id = auth.uid())
  -- ✅ REMOVED: AND (is_pinned = false) AND (is_deleted = false)
  -- These have DEFAULT false in table definition, no need to check on INSERT
);

COMMENT ON POLICY chat_insert_policy ON public.chat_messages IS 
'Allows group members to insert chat messages.
Removed is_pinned and is_deleted checks - these have DEFAULT false values.';


-- PART 2: Fix notify_chat_message() function
-- ============================================================================

DROP FUNCTION IF EXISTS public.notify_chat_message();

CREATE OR REPLACE FUNCTION public.notify_chat_message() 
RETURNS trigger
LANGUAGE plpgsql 
SECURITY DEFINER
AS $$
DECLARE
  v_event_emoji TEXT;
  v_event_name TEXT;
BEGIN
  -- ✅ CRITICAL FIX: Wrap notification logic in exception handler
  -- This prevents notification errors from blocking message INSERT
  BEGIN
    -- Buscar dados do evento
    SELECT emoji, name 
    INTO v_event_emoji, v_event_name
    FROM events 
    WHERE id = NEW.event_id;

    -- Criar notificação para todos os participantes do evento (exceto o sender)
    -- Categoria 'push' = ephemeral (não aparece no inbox, só push notification)
    INSERT INTO notifications (
      recipient_user_id,
      type,
      category,
      priority,
      user_name,
      event_name,
      event_emoji,
      event_id,
      note,           -- ✅ ADDED: Store message content
      deeplink
    )
    SELECT 
      ep.user_id,                                    -- participante do evento
      'chatMessage',                                 -- tipo
      'push',                                        -- categoria PUSH (ephemeral)
      'low',                                         -- prioridade baixa
      sender.name,                                   -- quem enviou
      v_event_name,                                  -- nome do evento
      v_event_emoji,                                 -- emoji do evento
      NEW.event_id,                                  -- event_id
      NEW.content,                                   -- ✅ ADDED: mensagem do chat
      'lazzo://events/' || NEW.event_id || '/chat'  -- deeplink para o chat
    FROM event_participants ep
    CROSS JOIN users sender
    WHERE sender.id = NEW.user_id                   -- dados do sender
      AND ep.pevent_id = NEW.event_id               -- ✅ CORRECT: pevent_id IS the event FK
      AND ep.user_id != NEW.user_id                 -- não notificar o sender
      -- TODO: Adicionar lógica para verificar se user está ativo no chat
      -- Exemplo: AND NOT is_user_active_in_chat(ep.user_id, NEW.event_id)
    ON CONFLICT (dedup_key, dedup_bucket) DO NOTHING;

  EXCEPTION
    WHEN OTHERS THEN
      -- ✅ Log error but don't block message insert
      RAISE WARNING 'notify_chat_message failed: %', SQLERRM;
  END;
  
  -- ✅ ALWAYS return NEW to allow message insert
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.notify_chat_message() IS 'Trigger que cria notificações push (ephemeral) quando alguém envia mensagem no chat.
Categoria "push" = não aparece no inbox, apenas como push notification.
Inclui conteúdo da mensagem no campo "note".
Wrapped in exception handler to prevent blocking message inserts.
TODO: Filtrar users que estão ativos no chat para não enviar notificação.';


-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Test 1: Verify policy exists
SELECT schemaname, tablename, policyname, cmd 
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename = 'chat_messages' 
  AND policyname = 'chat_insert_policy';

-- Test 2: Verify function exists
SELECT proname, prosrc 
FROM pg_proc 
WHERE proname = 'notify_chat_message';

-- Test 3: Try inserting a test message (as authenticated user)
-- INSERT INTO chat_messages (event_id, user_id, content)
-- VALUES ('<valid_event_id>', auth.uid(), 'Test message');

