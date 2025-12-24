-- ============================================================
-- SCHEDULED NOTIFICATIONS - SQL IMPLEMENTATION
-- ============================================================
-- Para P2 Developer implementar no Supabase
-- Estas notificações requerem pg_cron ou triggers temporais
-- ============================================================

-- ============================================================
-- 1. EVENT ENDS SOON (15 min antes de acabar)
-- ============================================================

-- Função para notificar eventos que acabam em breve
CREATE OR REPLACE FUNCTION notify_events_ending_soon()
RETURNS void AS $$
DECLARE
  event_record RECORD;
  participant_record RECORD;
  mins_remaining INT;
BEGIN
  -- Buscar eventos que acabam em 15 minutos
  FOR event_record IN
    SELECT id, name, emoji, end_datetime, created_by
    FROM events
    WHERE status = 'living'
      AND end_datetime BETWEEN NOW() AND NOW() + INTERVAL '16 minutes'
      AND end_datetime > NOW() + INTERVAL '14 minutes'
  LOOP
    -- Calcular minutos restantes
    mins_remaining := EXTRACT(EPOCH FROM (event_record.end_datetime - NOW())) / 60;
    
    -- Enviar para todos os participantes (incluindo host)
    FOR participant_record IN
      SELECT user_id FROM event_participants WHERE pevent_id = event_record.id
    LOOP
      PERFORM create_notification_secure(
        p_recipient_user_id := participant_record.user_id,
        p_type := 'eventEndsSoon',
        p_category := 'push',
        p_priority := 'high',
        p_deeplink := 'lazzo://events/' || event_record.id,
        p_event_id := event_record.id,
        p_event_name := event_record.name,
        p_event_emoji := event_record.emoji,
        p_mins := mins_remaining::text
      );
    END LOOP;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Agendar job para executar a cada 5 minutos
-- NOTA: Requer extensão pg_cron
-- SELECT cron.schedule(
--   'notify-events-ending-soon',
--   '*/5 * * * *',
--   'SELECT notify_events_ending_soon();'
-- );


-- ============================================================
-- 2. UPLOADS OPEN (quando evento acaba)
-- ============================================================

-- Trigger automático quando evento muda para 'recap'
CREATE OR REPLACE FUNCTION notify_uploads_open()
RETURNS TRIGGER AS $$
DECLARE
  participant_record RECORD;
  hours_remaining INT;
BEGIN
  -- Só dispara se status mudou para 'recap'
  IF NEW.status = 'recap' AND OLD.status != 'recap' THEN
    -- Upload window: 48h após fim do evento
    hours_remaining := 48;
    
    -- Enviar para todos os participantes
    FOR participant_record IN
      SELECT user_id FROM event_participants WHERE pevent_id = NEW.id
    LOOP
      PERFORM create_notification_secure(
        p_recipient_user_id := participant_record.user_id,
        p_type := 'uploadsOpen',
        p_category := 'push',
        p_priority := 'medium',
        p_deeplink := 'lazzo://events/' || NEW.id || '/upload',
        p_event_id := NEW.id,
        p_event_name := NEW.name,
        p_event_emoji := NEW.emoji,
        p_hours := hours_remaining::text
      );
    END LOOP;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Criar trigger
DROP TRIGGER IF EXISTS trigger_uploads_open ON events;
CREATE TRIGGER trigger_uploads_open
  AFTER UPDATE OF status ON events
  FOR EACH ROW
  EXECUTE FUNCTION notify_uploads_open();


-- ============================================================
-- 3. UPLOADS CLOSING (1h antes de fechar)
-- ============================================================

-- Função para notificar que upload window está a fechar
CREATE OR REPLACE FUNCTION notify_uploads_closing()
RETURNS void AS $$
DECLARE
  event_record RECORD;
  participant_record RECORD;
  upload_deadline TIMESTAMP;
  hours_remaining INT;
BEGIN
  -- Buscar eventos em recap onde upload window fecha em ~1h
  FOR event_record IN
    SELECT id, name, emoji, end_datetime
    FROM events
    WHERE status = 'recap'
  LOOP
    -- Upload deadline: 48h após end_datetime
    upload_deadline := event_record.end_datetime + INTERVAL '48 hours';
    
    -- Verificar se falta entre 55 min e 65 min para fechar
    IF upload_deadline BETWEEN NOW() + INTERVAL '55 minutes' AND NOW() + INTERVAL '65 minutes' THEN
      hours_remaining := 1;
      
      -- Enviar para todos os participantes
      FOR participant_record IN
        SELECT user_id FROM event_participants WHERE pevent_id = event_record.id
      LOOP
        PERFORM create_notification_secure(
          p_recipient_user_id := participant_record.user_id,
          p_type := 'uploadsClosing',
          p_category := 'push',
          p_priority := 'high',
          p_deeplink := 'lazzo://events/' || event_record.id || '/upload',
          p_event_id := event_record.id,
          p_event_name := event_record.name,
          p_event_emoji := event_record.emoji,
          p_hours := hours_remaining::text
        );
      END LOOP;
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Agendar job para executar a cada hora
-- SELECT cron.schedule(
--   'notify-uploads-closing',
--   '0 * * * *',
--   'SELECT notify_uploads_closing();'
-- );


-- ============================================================
-- 4. RSVP UPDATED (trigger automático)
-- ============================================================

-- Notificar host quando alguém muda RSVP
CREATE OR REPLACE FUNCTION notify_rsvp_updated()
RETURNS TRIGGER AS $$
DECLARE
  event_record RECORD;
  user_record RECORD;
  host_user_id UUID;
BEGIN
  -- Só dispara se RSVP mudou
  IF NEW.rsvp != OLD.rsvp THEN
    -- Buscar info do evento e host
    SELECT e.id, e.name, e.emoji, e.created_by
    INTO event_record
    FROM events e
    WHERE e.id = NEW.pevent_id;
    
    host_user_id := event_record.created_by;
    
    -- Não notificar se o host mudou próprio RSVP
    IF NEW.user_id != host_user_id THEN
      -- Buscar nome do user que mudou RSVP
      SELECT name INTO user_record
      FROM users
      WHERE id = NEW.user_id;
      
      -- Enviar notificação para o host
      PERFORM create_notification_secure(
        p_recipient_user_id := host_user_id,
        p_type := 'rsvpUpdated',
        p_category := 'notifications',
        p_priority := 'low',
        p_deeplink := 'lazzo://events/' || event_record.id,
        p_event_id := event_record.id,
        p_event_name := event_record.name,
        p_event_emoji := event_record.emoji,
        p_user_name := user_record.name
        -- Nota: rsvpStatus seria NEW.rsvp mas não está no RPC atual
      );
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Criar trigger
DROP TRIGGER IF EXISTS trigger_rsvp_updated ON event_participants;
CREATE TRIGGER trigger_rsvp_updated
  AFTER UPDATE OF rsvp ON event_participants
  FOR EACH ROW
  EXECUTE FUNCTION notify_rsvp_updated();


-- ============================================================
-- 5. MEMORY READY (trigger quando processing completa)
-- ============================================================

-- NOTA: Depende de como memory processing funciona
-- Assumindo que existe coluna 'processing_status' em 'memories'

CREATE OR REPLACE FUNCTION notify_memory_ready()
RETURNS TRIGGER AS $$
DECLARE
  event_record RECORD;
  participant_record RECORD;
BEGIN
  -- Só dispara se processing ficou 'ready'
  IF NEW.processing_status = 'ready' AND OLD.processing_status != 'ready' THEN
    -- Buscar evento associado à memory
    SELECT e.id, e.name, e.emoji
    INTO event_record
    FROM events e
    WHERE e.id = NEW.event_id;  -- Assumindo foreign key
    
    -- Enviar para todos os participantes do evento
    FOR participant_record IN
      SELECT user_id FROM event_participants WHERE pevent_id = event_record.id
    LOOP
      PERFORM create_notification_secure(
        p_recipient_user_id := participant_record.user_id,
        p_type := 'memoryReady',
        p_category := 'push',
        p_priority := 'medium',
        p_deeplink := 'lazzo://events/' || event_record.id || '/memory',
        p_event_id := event_record.id,
        p_event_name := event_record.name,
        p_event_emoji := event_record.emoji
      );
    END LOOP;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Criar trigger (ajustar tabela/coluna conforme schema real)
-- DROP TRIGGER IF EXISTS trigger_memory_ready ON memories;
-- CREATE TRIGGER trigger_memory_ready
--   AFTER UPDATE OF processing_status ON memories
--   FOR EACH ROW
--   EXECUTE FUNCTION notify_memory_ready();


-- ============================================================
-- VERIFICAÇÃO E TESTES
-- ============================================================

-- Verificar se pg_cron está disponível
-- SELECT * FROM pg_extension WHERE extname = 'pg_cron';

-- Listar jobs agendados
-- SELECT * FROM cron.job;

-- Testar função manualmente
-- SELECT notify_events_ending_soon();
-- SELECT notify_uploads_closing();

-- Verificar triggers criados
SELECT 
  trigger_name, 
  event_object_table, 
  action_timing, 
  event_manipulation
FROM information_schema.triggers
WHERE trigger_name IN (
  'trigger_uploads_open',
  'trigger_rsvp_updated',
  'trigger_memory_ready'
);

-- Verificar notificações criadas recentemente
SELECT 
  id,
  recipient_user_id,
  type,
  category,
  created_at,
  event_name
FROM notifications
WHERE type IN (
  'eventEndsSoon',
  'uploadsOpen',
  'uploadsClosing',
  'rsvpUpdated',
  'memoryReady'
)
ORDER BY created_at DESC
LIMIT 20;


-- ============================================================
-- NOTAS IMPORTANTES
-- ============================================================

-- 1. pg_cron requer superuser ou rds_superuser role
-- 2. Triggers devem ter SECURITY DEFINER para bypassar RLS
-- 3. Dedup automático (5 min) já está no create_notification_secure()
-- 4. Ajustar intervalos conforme necessário (15 min, 1h, etc.)
-- 5. Monitorizar performance - jobs podem ficar lentos com muitos eventos
-- 6. Considerar rate limiting se app crescer muito

-- ============================================================
-- ROLLBACK (se necessário)
-- ============================================================

-- DROP FUNCTION IF EXISTS notify_events_ending_soon();
-- DROP FUNCTION IF EXISTS notify_uploads_open() CASCADE;
-- DROP FUNCTION IF EXISTS notify_uploads_closing();
-- DROP FUNCTION IF EXISTS notify_rsvp_updated() CASCADE;
-- DROP FUNCTION IF EXISTS notify_memory_ready() CASCADE;

-- SELECT cron.unschedule('notify-events-ending-soon');
-- SELECT cron.unschedule('notify-uploads-closing');
