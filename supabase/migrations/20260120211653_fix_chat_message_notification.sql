-- Fix: notify_chat_message() to include message content and fix event_participants join
-- Issue: chatMessage notifications showing "undefined" for message content
-- Also fixes typo: ep.pevent_id -> ep.event_id

CREATE OR REPLACE FUNCTION public.notify_chat_message() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
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
    note,
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
    NEW.content,                                   -- ✅ mensagem do chat
    'lazzo://events/' || NEW.event_id || '/chat'  -- deeplink para o chat
  FROM event_participants ep
  CROSS JOIN users sender
  WHERE sender.id = NEW.user_id                   -- dados do sender
    AND ep.event_id = NEW.event_id                -- ✅ corrigido de pevent_id para event_id
    AND ep.user_id != NEW.user_id                 -- não notificar o sender
    -- TODO: Adicionar lógica para verificar se user está ativo no chat
    -- Exemplo: AND NOT is_user_active_in_chat(ep.user_id, NEW.event_id)
  ON CONFLICT (dedup_key, dedup_bucket) DO NOTHING;
  
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.notify_chat_message() IS 'Trigger que cria notificações push (ephemeral) quando alguém envia mensagem no chat.
Categoria "push" = não aparece no inbox, apenas como push notification.
TODO: Filtrar users que estão ativos no chat para não enviar notificação.';
