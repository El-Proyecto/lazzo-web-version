# Notificações - Status de Implementação (Resumo)

**Última atualização:** 23 Dez 2024

---

## ✅ Implementadas (8)

| Notificação | Trigger | Ficheiro |
|-------------|---------|----------|
| **Group Invite** | Ao convidar user para grupo | `other_profile_repository_impl.dart:221` |
| **Expense Added (You Owe)** | Ao criar despesa | `event_expense_remote_data_source.dart:73` |
| **Event Extended** | Ao estender duração | `event_remote_data_source.dart:415` |
| **Event Created** ✨ | Após criar evento | `event_repository_impl.dart:147` |
| **Event Date Set** ✨ | Status → planning | `event_remote_data_source.dart:275` |
| **Event Location Set** ✨ | Após definir localização | `event_remote_data_source.dart:213` |
| **Event Starts Soon** | Scheduled job (automático) | - |
| **Event Live** | Scheduled job (automático) | - |

✨ = **Implementadas neste prompt**

---

## ⏰ Precisam Scheduled Jobs (5)

Estas notificações **NÃO podem ser implementadas no Flutter** - precisam de jobs agendados no Supabase/PostgreSQL.

| Notificação | Quando disparar | SQL necessário |
|-------------|----------------|----------------|
| **Event Ends Soon** | 15 min antes de acabar | `pg_cron` job |
| **Uploads Open** | Quando evento acaba | Trigger após `status='recap'` |
| **Uploads Closing** | 1h antes de fechar upload | `pg_cron` job |
| **Memory Ready** | Processamento completo | Trigger após processing |
| **RSVP Updated** | Alguém muda RSVP | Trigger em `event_participants` |

**SQL Exemplo (Event Ends Soon):**
```sql
-- Função para enviar notificação
CREATE OR REPLACE FUNCTION notify_event_ending_soon()
RETURNS void AS $$
DECLARE
  event_record RECORD;
  participant_record RECORD;
BEGIN
  -- Buscar eventos que acabam em 15 min
  FOR event_record IN
    SELECT id, name, emoji, end_datetime
    FROM events
    WHERE status = 'living'
      AND end_datetime BETWEEN NOW() AND NOW() + INTERVAL '15 minutes'
  LOOP
    -- Enviar para todos os participantes
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
        p_mins := '15'
      );
    END LOOP;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Job agendado (executa a cada 5 minutos)
SELECT cron.schedule(
  'notify-events-ending-soon',
  '*/5 * * * *',
  'SELECT notify_event_ending_soon();'
);
```

---

## 🚧 Precisam Features (5)

Estas dependem de funcionalidades que ainda não existem:

| Notificação | Feature necessária | Prioridade |
|-------------|-------------------|------------|
| **Payment Request** | Sistema de pedidos de pagamento | Baixa |
| **Payment Received** | Confirmação de pagamento recebido | Baixa |
| **Chat Mention** | Parser de @mentions no chat | Média |
| **New Login** | Monitorização de sessões auth | Baixa |
| **Memory Shared** | Sistema de partilha de memórias | Média |

---

## ❌ Faltam Serviços (6)

Estas NÃO têm método em `notification_service.dart`:

| Notificação | Método necessário | Trigger point |
|-------------|-------------------|---------------|
| Group Invite Accepted | `sendGroupInviteAccepted()` | Ao aceitar convite |
| Group Renamed | `sendGroupRenamed()` | Ao renomear grupo |
| Event Details Updated | `sendEventDetailsUpdated()` | Ao editar evento |
| Event Canceled | `sendEventCanceled()` | Ao cancelar evento |
| Event Confirmed | `sendEventConfirmed()` | Ao confirmar evento |
| Suggestion Added | `sendSuggestionAdded()` | Ao adicionar sugestão |

**⚠️ Estas serão tratadas no próximo prompt**

---

## Sumário Geral

| Status | Count | Ação |
|--------|-------|------|
| ✅ Implementadas | 8 | Testáveis agora |
| ⏰ Scheduled Jobs | 5 | Requerem SQL/Supabase |
| 🚧 Dependem Features | 5 | Implementar features primeiro |
| ❌ Faltam Serviços | 6 | **Próximo prompt** |

**Total:** 24 notificações mapeadas

---

## Próximos Passos

1. **Testar as 3 novas notificações** (Event Created, Date Set, Location Set)
2. **Próximo prompt:** Criar os 6 serviços em falta
3. **Depois:** Configurar scheduled jobs no Supabase
4. **Por fim:** Implementar features dependentes
