-- ==============================================================================
-- LAZZO NOTIFICATIONS FIX
-- ==============================================================================
-- Data: 14 de janeiro de 2026
-- Objetivo: 
-- 1. Adicionar campos expense_name e person_name à tabela notifications
-- 2. Atualizar trigger notify_expense_added para preencher esses campos
-- 3. Criar trigger para notificações de chatMessage (não-mention)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. ADICIONAR CAMPOS À TABELA NOTIFICATIONS
-- ------------------------------------------------------------------------------

-- Adicionar campo expense_name (nome da despesa)
ALTER TABLE public.notifications 
ADD COLUMN IF NOT EXISTS expense_name TEXT;

-- Adicionar campo person_name (nome da pessoa que deve pagar)
ALTER TABLE public.notifications 
ADD COLUMN IF NOT EXISTS person_name TEXT;

COMMENT ON COLUMN public.notifications.expense_name IS 'Nome da despesa associada (usado em notificações de pagamento)';
COMMENT ON COLUMN public.notifications.person_name IS 'Nome da pessoa associada (usado em notificações de dívida/crédito)';

-- ------------------------------------------------------------------------------
-- 2. ATUALIZAR TRIGGER notify_expense_added
-- ------------------------------------------------------------------------------
-- Este trigger agora vai incluir:
-- - expense_name: nome da despesa (ee.title)
-- - amount formatado como "25.00€" (sem o símbolo € no início)

CREATE OR REPLACE FUNCTION public.notify_expense_added() 
RETURNS TRIGGER 
LANGUAGE plpgsql 
SECURITY DEFINER
AS $$
BEGIN
  -- Criar notificação "You Owe" para cada participante que deve dinheiro
  INSERT INTO notifications (
    recipient_user_id, 
    type, 
    category, 
    priority, 
    deeplink,
    event_id, 
    event_emoji, 
    user_name, 
    event_name, 
    amount,
    expense_id,
    expense_name
  )
  SELECT
    es.user_id,                                    -- quem deve
    'paymentsAddedYouOwe',                        -- tipo
    'notifications',                               -- categoria (aparece no inbox)
    'high',                                        -- prioridade
    'lazzo://events/' || e.id || '/expenses',     -- deeplink
    e.id,                                          -- event_id
    e.emoji,                                       -- emoji do evento
    u.name,                                        -- nome de quem criou
    e.name,                                        -- nome do evento
    es.amount::TEXT || '€',                       -- FORMATO: "25.00€" (símbolo no final)
    NEW.id,                                        -- expense_id
    NEW.title                                      -- NOVO: expense_name
  FROM expense_splits es
  JOIN event_expenses ee ON ee.id = es.expense_id
  JOIN events e ON e.id = ee.event_id
  JOIN users u ON u.id = ee.created_by
  WHERE es.expense_id = NEW.id
    AND es.user_id != ee.created_by               -- não notificar quem criou
    AND es.has_paid = FALSE                        -- só quem ainda não pagou
  ON CONFLICT (dedup_key, dedup_bucket) DO NOTHING;

  -- Criar notificação "Owes You" para o criador da despesa
  -- (informando quem lhe deve dinheiro)
  INSERT INTO notifications (
    recipient_user_id, 
    type, 
    category, 
    priority, 
    deeplink,
    event_id, 
    event_emoji, 
    user_name, 
    event_name, 
    amount,
    expense_id,
    expense_name,
    person_name
  )
  SELECT
    ee.created_by,                                 -- quem criou a despesa (recebe notif)
    'paymentsAddedOwesYou',                       -- tipo
    'notifications',                               -- categoria
    'high',                                        -- prioridade
    'lazzo://events/' || e.id || '/expenses',     -- deeplink
    e.id,                                          -- event_id
    e.emoji,                                       -- emoji do evento
    u_creator.name,                                -- nome do criador (ele próprio)
    e.name,                                        -- nome do evento
    es.amount::TEXT || '€',                       -- FORMATO: "25.00€" (símbolo no final)
    NEW.id,                                        -- expense_id
    NEW.title,                                     -- NOVO: expense_name
    u_debtor.name                                  -- NOVO: person_name (quem deve)
  FROM expense_splits es
  JOIN event_expenses ee ON ee.id = es.expense_id
  JOIN events e ON e.id = ee.event_id
  JOIN users u_creator ON u_creator.id = ee.created_by
  JOIN users u_debtor ON u_debtor.id = es.user_id
  WHERE es.expense_id = NEW.id
    AND es.user_id != ee.created_by               -- só notificar sobre outras pessoas
    AND es.has_paid = FALSE
  ON CONFLICT (dedup_key, dedup_bucket) DO NOTHING;
  
  RETURN NEW;
END;
$$;

-- Recriar o trigger (caso já exista)
DROP TRIGGER IF EXISTS expense_added_notification ON public.expense_splits;
CREATE TRIGGER expense_added_notification
  AFTER INSERT ON public.expense_splits
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_expense_added();

COMMENT ON FUNCTION public.notify_expense_added IS 
'Trigger que cria notificações quando uma despesa é adicionada. 
Envia "You Owe" para devedores e "Owes You" para o criador.
Formato do amount: "25.00€" (símbolo no final).';

-- ------------------------------------------------------------------------------
-- 3. CRIAR TRIGGER PARA NOTIFICAÇÕES DE CHAT (chatMessage)
-- ------------------------------------------------------------------------------
-- Este trigger cria notificações para mensagens de chat normais (não-mention)
-- IMPORTANTE: Só notifica se o utilizador NÃO estiver ativo no chat

CREATE OR REPLACE FUNCTION public.notify_chat_message() 
RETURNS TRIGGER 
LANGUAGE plpgsql 
SECURITY DEFINER
AS $$
DECLARE
  v_event_emoji TEXT;
  v_event_name TEXT;
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
    'lazzo://events/' || NEW.event_id || '/chat'  -- deeplink para o chat
  FROM event_participants ep
  CROSS JOIN users sender
  WHERE sender.id = NEW.user_id                   -- dados do sender
    AND ep.pevent_id = NEW.event_id               -- participantes do evento
    AND ep.user_id != NEW.user_id                 -- não notificar o sender
    -- TODO: Adicionar lógica para verificar se user está ativo no chat
    -- Exemplo: AND NOT is_user_active_in_chat(ep.user_id, NEW.event_id)
  ON CONFLICT (dedup_key, dedup_bucket) DO NOTHING;
  
  RETURN NEW;
END;
$$;

-- Criar o trigger (só se não existir)
DROP TRIGGER IF EXISTS chat_message_notification ON public.chat_messages;
CREATE TRIGGER chat_message_notification
  AFTER INSERT ON public.chat_messages
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_chat_message();

COMMENT ON FUNCTION public.notify_chat_message IS 
'Trigger que cria notificações push (ephemeral) quando alguém envia mensagem no chat.
Categoria "push" = não aparece no inbox, apenas como push notification.
TODO: Filtrar users que estão ativos no chat para não enviar notificação.';

-- ------------------------------------------------------------------------------
-- 4. VERIFICAÇÃO E TESTES
-- ------------------------------------------------------------------------------

-- Verificar se os campos foram adicionados
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'notifications'
  AND column_name IN ('expense_name', 'person_name');

-- Verificar triggers ativos
SELECT 
  trigger_name, 
  event_manipulation, 
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE trigger_schema = 'public'
  AND trigger_name IN ('expense_added_notification', 'chat_message_notification', 'chat_mention_notification');

-- ==============================================================================
-- NOTAS IMPORTANTES
-- ==============================================================================
--
-- 1. FORMATO DO AMOUNT:
--    - ANTES: "€25.00" (símbolo no início)
--    - AGORA: "25.00€" (símbolo no final)
--    - O Flutter vai detectar "€" e aplicar cor verde/vermelha
--
-- 2. EXPENSE_NAME e PERSON_NAME:
--    - Agora são preenchidos automaticamente pelo trigger
--    - No Flutter, {expense_name} e {person_name} serão substituídos pelos valores reais
--
-- 3. NOTIFICAÇÕES DE CHAT:
--    - chatMention: Já existe (quando alguém usa @username)
--    - chatMessage: NOVO trigger para mensagens normais (categoria 'push')
--    - chatMessage é ephemeral (não aparece no inbox)
--
-- 4. MIGRAÇÃO DE DADOS EXISTENTES:
--    - Notificações antigas não terão expense_name/person_name preenchidos
--    - Considere executar um UPDATE se necessário:
--      UPDATE notifications n
--      SET expense_name = ee.title
--      FROM event_expenses ee
--      WHERE n.expense_id = ee.id AND n.expense_name IS NULL;
--
-- ==============================================================================
