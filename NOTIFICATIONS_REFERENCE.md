# Lazzo Notifications Reference

**Última atualização:** 14 de janeiro de 2026  
**Versão:** 1.0

Este documento descreve todas as notificações implementadas na app Lazzo, incluindo o formato, onde aparecem, e os dados necessários.

---

## 📊 Tabela Geral de Notificações

| # | Tipo de Notificação | Categoria | Inbox | Push | Prioridade |
|---|---------------------|-----------|-------|------|------------|
| 1 | Group Invite Received | actions | ✓ | ✓ | medium |
| 2 | Payment Added (You Owe) | notifications | ✓ | ✓ | high |
| 3 | Payment Added (Owes You) | notifications | ✓ | ✓ | high |
| 4 | Payment Request | actions | ✓ | ✓ | high |
| 5 | Event Starts Soon | push | - | ✓ | high |
| 6 | Event Live | push | - | ✓ | high |
| 7 | Chat Mention | push | - | ✓ | medium |
| 8 | Chat Message | push | - | ✓ | medium |
| 9 | Security: New Login | push | - | ✓ | high |
| 10 | Uploads Closing Soon | push | - | ✓ | medium |
| 11 | Memory Ready | notifications | ✓ | ✓ | medium |
| 12 | Event Ends Soon | push | - | ✓ | medium |
| 13 | Event Created | notifications | ✓ | ✓ | medium |
| 14 | Event Date Set | notifications | ✓ | ✓ | medium |
| 15 | Event Extended | notifications | ✓ | ✓ | low |
| 16 | Uploads Open | notifications | ✓ | ✓ | medium |
| 17 | RSVP Updated | notifications | ✓ | ✓ | low |
| 18 | Event Confirmed | notifications | ✓ | ✓ | medium |
| 19 | Event Canceled | notifications | ✓ | ✓ | high |

---

## 📱 Detalhes de Cada Notificação

### 1. Group Invite Received
**Type:** `groupInviteReceived`  
**Category:** `notifications`  
**Priority:** `medium`

**Push Notification:**
- **Título:** "{group_name}"
- **Corpo:** "{user_name} invited you to join"

**Inbox:**
- Aparece no tab "Notifications"
- **Texto:** "**{user_name}** invited you to join **{group_name}**"
- **Icon:** Avatar de {user_name}
- Action: Abrir grupo / aceitar invite

**Dados Necessários:**
- `user_name`: Nome de quem convidou
- `group_name`: Nome do grupo
- `group_id`: ID do grupo
- `deeplink`: `lazzo://groups/{group_id}`

---

### 2. Payment Added (You Owe)
**Type:** `paymentsAddedYouOwe`  
**Category:** `notifications`  
**Priority:** `high`

**Push Notification:**
- **Título:** "{event_emoji} {event_name}"
- **Corpo:** "{user_name} added the expense "{expense_name}""

**Inbox:**
- Aparece no tab "Payments"
- **Texto:** "**{user_name}** added the expense "**{expense_name}**". You owe **<span style="color:red">{amount}</span>**"
- **Icon:** {event_emoji}
- Action: Ver detalhes da expense

**Dados Necessários:**
- `user_name`: Nome de quem criou a expense
- `expense_name`: Nome da expense
- `amount`: Valor que você deve (ex: "€25.00")
- `event_emoji`: Emoji do evento
- `event_name`: Nome do evento
- `event_id`: ID do evento
- `expense_id`: ID da expense
- `deeplink`: `lazzo://events/{event_id}/expenses/{expense_id}`

**Trigger:** INSERT em `payments` onde current_user deve pagar

---

### 3. Payment Added (Owes You)
**Type:** `paymentsAddedOwesYou`  
**Category:** `notifications`  
**Priority:** `high`

**Push Notification:**
- **Título:** "{event_emoji} {event_name}"
- **Corpo:** "{user_name} added the expense "{expense_name}""

**Inbox:**
- Aparece no tab "Payments"
- **Texto:** "**{user_name}** added the expense "**{expense_name}**". **{person_name}** owes you **<span style="color:green">{amount}</span>**"
- **Icon:** {event_emoji}
- Action: Ver detalhes da expense

**Dados Necessários:**
- `user_name`: Nome de quem criou a expense
- `expense_name`: Nome da expense
- `person_name`: Nome de quem deve a você
- `amount`: Valor a receber (ex: "€20.00")
- `event_emoji`: Emoji do evento
- `event_name`: Nome do evento
- `event_id`: ID do evento
- `expense_id`: ID da expense
- `deeplink`: `lazzo://events/{event_id}/expenses/{expense_id}`

**Trigger:** INSERT em `payments` onde outra pessoa deve ao current_user

---

### 4. Payment Request
**Type:** `paymentsRequest`  
**Category:** `actions`  
**Priority:** `high`

**Push Notification:**
- **Título:** "{event_emoji} {event_name}"
- **Corpo:** "{user_name} requested {amount} for {expense_name}"

**Inbox:**
- Aparece no tab "Payments"
- **Texto:** "**{user_name}** requested **<span style="color:red">{amount}</span>** for **{expense_name}**"
- **Icon:** {event_emoji}
- Action: Marcar como pago

**Dados Necessários:**
- `user_name`: Nome de quem está a pedir
- `expense_name`: Nome da expense
- `amount`: Valor (ex: "€25.00")
- `event_emoji`: Emoji do evento
- `event_name`: Nome do evento
- `event_id`: ID do evento
- `expense_id`: ID da expense
- `deeplink`: `lazzo://events/{event_id}/expenses/{expense_id}`

**Trigger:** User envia payment request

---

### 5. Event Starts Soon
**Type:** `eventStartsSoon`  
**Category:** `push`  
**Priority:** `high`

**Push Notification:**
- **Título:** "{event_emoji} {event_name}"
- **Corpo:** "Starts in {mins} min"

**Inbox:**
- NÃO aparece (categoria `push` = ephemeral)

**Dados Necessários:**
- `event_emoji`: Emoji do evento (ex: "🎉")
- `event_name`: Nome do evento
- `mins`: Minutos restantes (ex: "15")
- `event_id`: ID do evento
- `deeplink`: `lazzo://events/{event_id}`

**Trigger:** Cron job (notify-events-ending Edge Function)

---

### 6. Event Live
**Type:** `eventLive`  
**Category:** `push`  
**Priority:** `high`

**Push Notification:**
- **Título:** "{event_emoji} {event_name}"
- **Corpo:** "It's live now!"

**Inbox:**
- NÃO aparece (categoria `push` = ephemeral)

**Dados Necessários:**
- `event_emoji`: Emoji do evento
- `event_name`: Nome do evento
- `event_id`: ID do evento
- `deeplink`: `lazzo://events/{event_id}/live`

**Trigger:** Cron job quando evento começa

---

### 7. Chat Mention
**Type:** `chatMention`  
**Category:** `push`  
**Priority:** `medium`

**Push Notification:**
- **Título:** "{event_emoji} {event_name}"
- **Corpo:** "{user_name} mentioned you in chat"

**Inbox:**
- NÃO aparece (categoria `push` = ephemeral)

**Dados Necessários:**
- `event_emoji`: Emoji do evento
- `user_name`: Nome de quem mencionou
- `event_name`: Nome do evento
- `event_id`: ID do evento
- `deeplink`: `lazzo://events/{event_id}/chat`

**Trigger:** Quando mensagem contém @mention

---

### 8. Chat Message
**Type:** `chatMessage`  
**Category:** `push`  
**Priority:** `medium`

**Push Notification:**
- **Título:** "{event_emoji} {event_name}"
- **Corpo:** "{user_name}: {message}"

**Inbox:**
- NÃO aparece (categoria `push` = ephemeral)

**Dados Necessários:**
- `event_emoji`: Emoji do evento
- `event_name`: Nome do evento
- `user_name`: Nome de quem enviou a mensagem
- `message`: Conteúdo da mensagem (truncado se > 100 chars)
- `event_id`: ID do evento
- `deeplink`: `lazzo://events/{event_id}/chat`

**Trigger:** 
- Quando nova mensagem é enviada no chat
- **Condições:**
  - Mensagem é de outro user (não do próprio)
  - Chat do evento NÃO está muted
  - User tem notificações de chat ativadas

**Nota:** Por default, chat não está muted. User pode mutar via settings.

---

### 9. Security: New Login
**Type:** `securityNewLogin`  
**Category:** `push`  
**Priority:** `high`

**Push Notification:**
- **Título:** "New Login Detected"
- **Corpo:** "Logged in from {place}"

**Inbox:**
- NÃO aparece (categoria `push` = ephemeral)

**Dados Necessários:**
- `device`: Tipo de dispositivo (ex: "iPhone 14")
- `place`: Localização (opcional, ex: "Lisboa, Portugal")
- `deeplink`: `lazzo://profile/security`

**Trigger:** Chamado pela app após auth bem-sucedida

---

### 10. Uploads Closing Soon
**Type:** `uploadsClosing`  
**Category:** `push`  
**Priority:** `medium`

**Push Notification:**
- **Título:** "{event_emoji} {event_name}"
- **Corpo:** "Upload photos ({mins} min left)"

**Inbox:**
- NÃO aparece (categoria `push` = ephemeral)

**Dados Necessários:**
- `event_emoji`: Emoji do evento
- `event_name`: Nome do evento
- `mins`: Minutos restantes (ex: "60")
- `event_id`: ID do evento
- `deeplink`: `lazzo://events/{event_id}/uploads`

**Trigger:** Cron job (notify-uploads-closing Edge Function)

---

### 11. Memory Ready
**Type:** `memoryReady`  
**Category:** `notifications`  
**Priority:** `medium`

**Push Notification:**
- **Título:** "{event_emoji} {event_name}"
- **Corpo:** "Your memory is ready to view!"

**Inbox:**
- Aparece no tab "Notifications"
- **Texto:** "**{event_name}** memory is ready to view!"
- **Icon:** {event_emoji}
- Action: Ver memória

**Dados Necessários:**
- `event_emoji`: Emoji do evento
- `event_name`: Nome do evento
- `event_id`: ID do evento
- `deeplink`: `lazzo://memories/{event_id}`

**Trigger:** Quando estado do evento muda para `ended`

---

### 12. Event Ends Soon
**Type:** `eventEndsSoon`  
**Category:** `push`  
**Priority:** `medium`

**Push Notification:**
- **Título:** "{event_emoji} {event_name}"
- **Corpo:** "The event ends in {mins} minutes"

**Inbox:**
- NÃO aparece (categoria `push` = ephemeral)

**Dados Necessários:**
- `event_emoji`: Emoji do evento
- `event_name`: Nome do evento
- `mins`: Minutos restantes (ex: "10")
- `event_id`: ID do evento
- `deeplink`: `lazzo://events/{event_id}`

**Trigger:** Cron job (notify-events-ending Edge Function)

---

### 13. Event Created
**Type:** `eventCreated`  
**Category:** `notifications`  
**Priority:** `medium`

**Push Notification:**
- **Título:** "{group_name}"
- **Corpo:** "{user_name} created an event in {group_name}"

**Inbox:**
- Aparece no tab "Notifications"
- **Texto:** "**{user_name}** created **{event_name}** in **{group_name}**"
- **Icon:** {event_emoji}
- Action: Ver evento

**Dados Necessários:**
- `user_name`: Nome do criador
- `event_emoji`: Emoji do evento
- `event_name`: Nome do evento
- `group_name`: Nome do grupo
- `event_id`: ID do evento
- `group_id`: ID do grupo
- `deeplink`: `lazzo://events/{event_id}`

**Trigger:** Quando novo evento é criado

---

### 14. Event Date Set
**Type:** `eventDateSet`  
**Category:** `notifications`  
**Priority:** `medium`

**Push Notification:**
- **Título:** "{event_emoji} {event_name}"
- **Corpo:** "Event date is set to {date} at {time}"

**Inbox:**
- Aparece no tab "Notifications"
- **Texto:** "**{event_name}** is set for **{date}** at **{time}**"
- **Icon:** {event_emoji}
- Action: Ver evento

**Dados Necessários:**
- `event_emoji`: Emoji do evento
- `event_name`: Nome do evento
- `date`: Data formatada (ex: "15 Jan")
- `time`: Hora formatada (ex: "20:00")
- `event_id`: ID do evento
- `deeplink`: `lazzo://events/{event_id}`

**Trigger:** Quando `start_datetime` é definido pela primeira vez

---

### 15. Event Extended
**Type:** `eventExtended`  
**Category:** `notifications`  
**Priority:** `low`

**Push Notification:**
- **Título:** "{event_emoji} {event_name}"
- **Corpo:** "Event extended by {hours}h"

**Inbox:**
- Aparece no tab "Notifications"
- **Texto:** "**{event_name}** extended by **{hours}h**"
- **Icon:** {event_emoji}
- Action: Ver evento

**Dados Necessários:**
- `event_emoji`: Emoji do evento
- `event_name`: Nome do evento
- `hours`: Horas estendidas (ex: "2")
- `event_id`: ID do evento
- `deeplink`: `lazzo://events/{event_id}`

**Trigger:** Quando `end_datetime` é alterado (aumentado)

---

### 16. Uploads Open
**Type:** `uploadsOpen`  
**Category:** `notifications`  
**Priority:** `medium`

**Push Notification:**
- **Título:** "{event_emoji} {event_name}"
- **Corpo:** "Uploads are open ({hours}h left)"

**Inbox:**
- Aparece no tab "Notifications"
- **Texto:** "Upload photos for **{event_name}** (**{hours}h** left)"
- **Icon:** {event_emoji}
- Action: Upload de fotos

**Dados Necessários:**
- `event_emoji`: Emoji do evento
- `event_name`: Nome do evento
- `hours`: Horas disponíveis (ex: "48")
- `event_id`: ID do evento
- `deeplink`: `lazzo://events/{event_id}/uploads`

**Trigger:** Quando evento muda para estado `recap`

---

### 17. RSVP Updated
**Type:** `rsvpUpdated`  
**Category:** `notifications`  
**Priority:** `low`

**Push Notification:**
- **Título:** "{event_emoji} {event_name}"
- **Corpo:** "{user_name} is {note} to the event"

**Inbox:**
- Aparece no tab "Notifications"
- **Texto:** "**{user_name}** is **{note}** to **{event_name}**"
- **Icon:** {event_emoji}
- Action: Ver participantes

**Dados Necessários:**
- `event_emoji`: Emoji do evento
- `user_name`: Nome do participante
- `note`: Estado do RSVP (ex: "going", "not going", "maybe")
- `event_name`: Nome do evento
- `event_id`: ID do evento
- `deeplink`: `lazzo://events/{event_id}/participants`

**Trigger:** Quando participante atualiza RSVP

---

### 18. Event Confirmed
**Type:** `eventConfirmed`  
**Category:** `notifications`  
**Priority:** `medium`

**Push Notification:**
- **Título:** "{event_emoji} {event_name}"
- **Corpo:** "Event confirmed for {date} at {time}"

**Inbox:**
- Aparece no tab "Notifications"
- **Texto:** "**{event_name}** confirmed for **{date}** at **{time}**"
- **Icon:** {event_emoji}
- Action: Ver evento

**Dados Necessários:**
- `event_emoji`: Emoji do evento
- `event_name`: Nome do evento
- `date`: Data formatada
- `time`: Hora formatada
- `event_id`: ID do evento
- `deeplink`: `lazzo://events/{event_id}`

**Trigger:** Quando estado do evento muda para `confirmed`

---

### 19. Event Canceled
**Type:** `eventCanceled`  
**Category:** `notifications`  
**Priority:** `high`

**Push Notification:**
- **Título:** "{emoji} Event Canceled"
- **Corpo:** "{event_name} has been canceled"

**Inbox:**
- Aparece no tab "Notifications"
- Action: Ver razão

**Dados Necessários:**
- `event_emoji`: Emoji do evento
- `event_name`: Nome do evento
- `group_name`: Nome do grupo
- `event_id`: ID do evento
- `deeplink`: `lazzo://events/{event_id}`

**Trigger:** Quando evento é eliminado (trigger BEFORE DELETE)

---

## 🔔 Categorias de Notificações

### 1. `push` (Ephemeral)
Notificações temporárias que **não aparecem na Inbox**. Servem apenas para alertar o utilizador em tempo real.

**Características:**
- Aparecem como push notification
- Não ficam guardadas na Inbox
- Auto-limpeza após 7 dias (cleanup_expired_notifications)
- Exemplos: eventStartsSoon, eventLive, chatMention, eventEndsSoon

**Uso:** Alertas time-sensitive que perdem relevância rapidamente.

### 2. `notifications` (Persistent)
Notificações que **aparecem na Inbox** e podem enviar push.

**Características:**
- Aparecem no tab "Notifications" da Inbox
- Podem enviar push notification
- Permanecem até serem lidas/arquivadas
- Exemplos: eventCreated, memoryReady, paymentsAddedYouOwe

**Uso:** Informações importantes que o utilizador deve poder rever.

### 3. `actions` (Actionable)
Notificações que requerem ação do utilizador.

**Características:**
- Aparecem no tab "Actions" da Inbox
- Sempre têm um CTA claro
- Exemplos: groupInviteReceived, paymentsRequest

**Uso:** Quando utilizador precisa fazer algo (aceitar, pagar, confirmar).

---

## 📋 Campos Comuns

Todos os registos na tabela `notifications` têm:

```typescript
{
  id: uuid,                      // ID único
  recipient_user_id: uuid,       // Quem recebe
  type: string,                  // Tipo (ver tabela acima)
  category: enum,                // push | notifications | actions
  priority: enum,                // low | medium | high
  is_read: boolean,              // Se foi lida (default: false)
  created_at: timestamp,         // Quando foi criada
  
  // Campos opcionais (dependem do tipo)
  deeplink: string,              // Deep link para navegação
  group_id: uuid,                // ID do grupo relacionado
  event_id: uuid,                // ID do evento relacionado
  expense_id: uuid,              // ID da expense relacionada
  
  // Dados dinâmicos para mensagens
  event_emoji: string,           // 🎉
  user_name: string,             // "João Silva"
  group_name: string,            // "Friends"
  event_name: string,            // "Birthday Party"
  amount: string,                // "€25.00"
  hours: string,                 // "2"
  mins: string,                  // "15"
  date: string,                  // "15 Jan"
  time: string,                  // "20:00"
  place: string,                 // "Parque das Nações"
  device: string,                // "iPhone 14"
  note: string,                  // "going" | "not going" | "maybe"
  
  // Deduplicação (evita spam)
  dedup_bucket: timestamp,       // Janela de 5min
  dedup_key: string              // user_id:type:group_id:event_id
}
```

---

## 🔧 Triggers Automáticos

| Trigger | Função | Quando Dispara |
|---------|--------|----------------|
| `notify_event_created` | Criar notificação "Event Created" | INSERT em `events` |
| `notify_event_confirmed` | Criar notificação "Event Confirmed" | UPDATE `events.status` → `confirmed` |
| `notify_event_date_set` | Criar notificação "Date Set" | UPDATE `events.start_datetime` (NULL → valor) |
| `notify_event_location_set` | Criar notificação "Location Set" | UPDATE `events.location_id` (NULL → valor) |
| `notify_event_extended` | Criar notificação "Event Extended" | UPDATE `events.end_datetime` (aumentar) |
| `notify_event_details_updated` | Criar notificação "Details Updated" | UPDATE `events.name` ou `events.emoji` |
| `notify_participants_before_delete` | Criar notificação "Event Canceled" | DELETE em `events` |
| `notify_uploads_open` | Criar notificação "Uploads Open" | UPDATE `events.status` → `recap` |
| `notify_expense_added` | Criar notificação "Payment Added" | INSERT em `event_expenses` |
| `notify_group_invite_received` | Criar notificação "Group Invite" | INSERT em `group_invites` |
| `notify_chat_mention` | Criar notificação "Chat Mention" | INSERT em `chat_messages` (se contém @) |
| `on_notification_insert_send_push` | Enviar push APNs | INSERT em `notifications` (category=`push`) |

---

## 🕐 Cron Jobs (Edge Functions)

| Edge Function | Frequência | Notificação Criada |
|---------------|------------|-------------------|
| `notify-events-ending` | A cada 5min | `eventStartsSoon`, `eventLive`, `eventEndsSoon` |
| `notify-uploads-closing` | A cada hora | `uploadsClosing` |
| Cleanup (futuro) | Diário | Remove notificações `push` > 7 dias |

---

## 🎨 Sugestões de Melhorias

### Notificações em Falta

1. **Group Member Added**
   - Tipo: `groupMemberAdded`
   - Push: "{user_name} joined {group_name}"
   - Categoria: `notifications`

2. **Payment Received**
   - Tipo: `paymentsReceived`
   - Push: "{user_name} paid you {amount}"
   - Categoria: `notifications`

3. **Poll Vote Added**
   - Tipo: `pollVoteAdded`
   - Push: "{user_name} voted on {event_name}"
   - Categoria: `notifications`

4. **Date Suggestion Added**
   - Tipo: `dateSuggestionAdded`
   - Push: "{user_name} suggested dates for {event_name}"
   - Categoria: `notifications`

5. **Location Suggestion Added**
   - Tipo: `locationSuggestionAdded`
   - Push: "{user_name} suggested {place} for {event_name}"
   - Categoria: `notifications`

6. **Group Invite Accepted**
   - Tipo: `groupInviteAccepted`
   - Push: "{user_name} accepted your invite to {group_name}"
   - Categoria: `notifications`

7. **Event RSVP Reminder**
   - Tipo: `eventRsvpReminder`
   - Push: "Please respond to {event_name} ({date})"
   - Categoria: `push`

8. **Photo Upload Complete**
   - Tipo: `photoUploadComplete`
   - Push: "Your {count} photos were uploaded to {event_name}"
   - Categoria: `notifications`

### Melhorias de Formato

1. **Localização (i18n)**
   - Atualmente: Inglês hardcoded
   - Sugestão: Usar ARB files + backend locale detection

2. **Rich Notifications (iOS)**
   - Adicionar imagens (event cover, user avatar)
   - Adicionar actions (Accept/Decline, Mark Paid, etc.)

3. **Notification Grouping**
   - Agrupar múltiplas notificações do mesmo evento
   - Ex: "3 updates in Birthday Party"

4. **Sound Customization**
   - Som diferente por prioridade (high = loud, low = subtle)
   - Custom sounds por tipo (payment = cash register sound)

---

## 📊 Estatísticas (Futuro)

Campos a adicionar para analytics:

```sql
ALTER TABLE notifications ADD COLUMN delivered_at timestamp;
ALTER TABLE notifications ADD COLUMN opened_at timestamp;
ALTER TABLE notifications ADD COLUMN action_taken boolean DEFAULT false;
```

Métricas úteis:
- Taxa de entrega (delivered / sent)
- Taxa de abertura (opened / delivered)
- Taxa de ação (action_taken / opened)
- Tempo médio até abertura
- Tipos mais ignorados (nunca abertos)

---

**Documento criado:** 14 de janeiro de 2026  
**Autor:** Copilot (baseado em análise do código)  
**Versão Edge Function APNs:** 2 (deployed)  
**Status:** ✅ Completo e testado
