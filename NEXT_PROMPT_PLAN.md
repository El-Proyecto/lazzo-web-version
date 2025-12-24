# 🚀 Próximo Prompt - Notificações em Falta

**Estado atual:** 8 notificações implementadas | 6 precisam de serviço

---

## ❌ Notificações SEM Serviço (para implementar)

Estas **não têm método** em `notification_service.dart` e precisam:
1. Criar método `sendXxx()` no serviço
2. Adicionar trigger no código ou DB

### 1. Group Invite Accepted
**Mensagem:** `{user} joined **{group}**.`  
**Tipo:** `groupInviteAccepted` (notifications feed)  
**Deeplink:** `lazzo://groups/{groupId}`  
**Trigger:** Quando user aceita convite de grupo  
**Ficheiro trigger:** `lib/features/groups/` (ao aceitar invite)

**Método a criar:**
```dart
Future<String?> sendGroupInviteAccepted({
  required String recipientUserId,      // Host/admin que convidou
  required String acceptedUserName,     // Quem aceitou
  required String groupName,
  required String groupId,
}) async {
  return await _client.rpc('create_notification_secure', params: {
    'p_recipient_user_id': recipientUserId,
    'p_type': 'groupInviteAccepted',
    'p_category': 'notifications',
    'p_priority': 'low',
    'p_deeplink': 'lazzo://groups/$groupId',
    'p_group_id': groupId,
    'p_user_name': acceptedUserName,
    'p_group_name': groupName,
  });
}
```

---

### 2. Group Renamed
**Mensagem:** `**{group}** has a new name.`  
**Tipo:** `groupRenamed` (notifications feed)  
**Deeplink:** `lazzo://groups/{groupId}`  
**Trigger:** Quando admin renomeia grupo  
**Ficheiro trigger:** `lib/features/groups/` (ao editar nome)

**Método a criar:**
```dart
Future<String?> sendGroupRenamed({
  required String recipientUserId,
  required String oldGroupName,
  required String newGroupName,
  required String groupId,
}) async {
  return await _client.rpc('create_notification_secure', params: {
    'p_recipient_user_id': recipientUserId,
    'p_type': 'groupRenamed',
    'p_category': 'notifications',
    'p_priority': 'low',
    'p_deeplink': 'lazzo://groups/$groupId',
    'p_group_id': groupId,
    'p_group_name': newGroupName,
  });
}
```

---

### 3. Event Details Updated
**Mensagem:** `**{event}** was updated. Check the new details.`  
**Tipo:** `eventDetailsUpdated` (notifications feed)  
**Deeplink:** `lazzo://events/{eventId}`  
**Trigger:** Quando host edita detalhes do evento  
**Ficheiro trigger:** `lib/features/event/` (ao editar evento)

**Método a criar:**
```dart
Future<String?> sendEventDetailsUpdated({
  required String recipientUserId,
  required String eventName,
  required String eventId,
  String? eventEmoji,
}) async {
  return await _client.rpc('create_notification_secure', params: {
    'p_recipient_user_id': recipientUserId,
    'p_type': 'eventDetailsUpdated',
    'p_category': 'notifications',
    'p_priority': 'medium',
    'p_deeplink': 'lazzo://events/$eventId',
    'p_event_id': eventId,
    'p_event_name': eventName,
    'p_event_emoji': eventEmoji,
  });
}
```

---

### 4. Event Canceled
**Mensagem:** `**{event}** was canceled.`  
**Tipo:** `eventCanceled` (notifications feed)  
**Deeplink:** `lazzo://groups/{groupId}` (vai para grupo, não evento)  
**Trigger:** Quando host cancela evento  
**Ficheiro trigger:** `lib/features/event/` (ação de cancelar)

**Método a criar:**
```dart
Future<String?> sendEventCanceled({
  required String recipientUserId,
  required String eventName,
  required String eventId,
  required String groupId,
  String? eventEmoji,
}) async {
  return await _client.rpc('create_notification_secure', params: {
    'p_recipient_user_id': recipientUserId,
    'p_type': 'eventCanceled',
    'p_category': 'notifications',
    'p_priority': 'high',
    'p_deeplink': 'lazzo://groups/$groupId',
    'p_event_id': eventId,
    'p_group_id': groupId,
    'p_event_name': eventName,
    'p_event_emoji': eventEmoji,
  });
}
```

---

### 5. Event Confirmed
**Mensagem:** `**{event}** is confirmed to happen.`  
**Tipo:** `eventConfirmed` (notifications feed)  
**Deeplink:** `lazzo://events/{eventId}`  
**Trigger:** Quando host confirma evento (botão específico?)  
**Ficheiro trigger:** `lib/features/event/` (ação de confirmar)

**Método a criar:**
```dart
Future<String?> sendEventConfirmed({
  required String recipientUserId,
  required String eventName,
  required String eventId,
  String? eventEmoji,
}) async {
  return await _client.rpc('create_notification_secure', params: {
    'p_recipient_user_id': recipientUserId,
    'p_type': 'eventConfirmed',
    'p_category': 'notifications',
    'p_priority': 'medium',
    'p_deeplink': 'lazzo://events/$eventId',
    'p_event_id': eventId,
    'p_event_name': eventName,
    'p_event_emoji': eventEmoji,
  });
}
```

---

### 6. Suggestion Added
**Mensagem:** `{user} suggested **{suggestion}** for **{event}**.`  
**Tipo:** `suggestionAdded` (notifications feed)  
**Deeplink:** `lazzo://events/{eventId}`  
**Trigger:** Quando alguém adiciona sugestão (date/location/poll)  
**Ficheiro trigger:** `lib/features/event/` (ao criar sugestão)

**Método a criar:**
```dart
Future<String?> sendSuggestionAdded({
  required String recipientUserId,      // Host do evento
  required String userName,             // Quem sugeriu
  required String suggestionType,       // 'date', 'location', 'poll'
  required String eventName,
  required String eventId,
  String? eventEmoji,
}) async {
  return await _client.rpc('create_notification_secure', params: {
    'p_recipient_user_id': recipientUserId,
    'p_type': 'suggestionAdded',
    'p_category': 'notifications',
    'p_priority': 'low',
    'p_deeplink': 'lazzo://events/$eventId',
    'p_event_id': eventId,
    'p_event_name': eventName,
    'p_event_emoji': eventEmoji,
    'p_user_name': userName,
    // Nota: suggestionType não está no RPC, usar 'note' field?
  });
}
```

---

## 📝 Checklist de Implementação

Para cada notificação:

1. **Adicionar método ao `notification_service.dart`**
   - [ ] Copiar template acima
   - [ ] Ajustar parâmetros conforme necessário
   - [ ] Verificar que todos campos RPC estão corretos

2. **Encontrar trigger point**
   - [ ] Identificar ficheiro onde ação acontece
   - [ ] Injetar `NotificationService` se necessário
   - [ ] Adicionar código para buscar participantes/membros
   - [ ] Enviar notificação em try-catch

3. **Testar**
   - [ ] Executar ação no app
   - [ ] Verificar registo em Supabase `notifications` table
   - [ ] Verificar que notificação aparece no inbox
   - [ ] Verificar navegação funciona

---

## 🗂️ Ficheiros a Modificar

**Serviço:**
- `lib/services/notification_service.dart` - Adicionar 6 métodos

**Triggers (estimativa):**
- `lib/features/groups/` - Group Invite Accepted, Group Renamed
- `lib/features/event/` - Event Canceled, Event Confirmed, Event Details Updated
- `lib/features/event/data/data_sources/suggestion_remote_data_source.dart` - Suggestion Added

---

## 💡 Notas Importantes

**Padrão de implementação:**
1. Todos os métodos usam `create_notification_secure()` RPC
2. Categoria: `'notifications'` (feed only, não push)
3. Priority: `'low'` ou `'medium'` (não são urgentes)
4. Sempre enviar para **participantes/membros exceto o autor da ação**
5. Wrap em try-catch para não falhar operação principal

**Diferença vs notificações já implementadas:**
- Event Created/Date Set/Location Set → já feitas ✅
- Estas 6 → precisam criar método **e** trigger

---

## 🎯 Objetivo do Próximo Prompt

**Input esperado:**
```
"Implementa agora as 6 notificações em falta: Group Invite Accepted, Group Renamed, Event Details Updated, Event Canceled, Event Confirmed, Suggestion Added. Dá-me o código completo para notification_service.dart e os triggers necessários."
```

**Output esperado:**
1. 6 novos métodos em `notification_service.dart`
2. Triggers nos ficheiros apropriados
3. Código compila sem erros
4. Documento explicativo com queries executadas

---

## 📊 Estado Final Esperado

Após próximo prompt:
- ✅ **14 notificações implementadas** (8 atuais + 6 novas)
- ⏰ **5 scheduled jobs** (para P2 implementar SQL)
- 🚧 **5 dependem features** (Payment, Chat Mention, etc.)

**Total:** 24 notificações completas
