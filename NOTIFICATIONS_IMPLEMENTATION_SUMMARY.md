# Correções de Notificações - Resumo de Implementação

**Data:** 14 de janeiro de 2026  
**Status:** ✅ Código Flutter atualizado | ⏳ SQL pronto para executar no Supabase

---

## 📋 Problemas Identificados e Resolvidos

### 1. ❌ `{expense_name}` aparecendo literalmente
**Causa:** Campos `expense_name` e `person_name` não existem na tabela `notifications` do Supabase.

**Solução SQL:** Adicionar campos e atualizar trigger (ver [NOTIFICATIONS_FIX.sql](NOTIFICATIONS_FIX.sql))

### 2. ❌ Símbolo € no lugar errado
**Era:** `"€25.00"` (símbolo no início)  
**Agora:** `"25.00€"` (símbolo no final) ✅

**Arquivos Flutter atualizados:**
- [notification_entity.dart#L221-225](lib/features/inbox/domain/entities/notification_entity.dart#L221-L225) - Lógica de formatação
- [event_expense_remote_data_source.dart#L78](lib/features/expense/data/data_sources/event_expense_remote_data_source.dart#L78) - Criação de notificação

### 3. ✅ Cores verde/vermelho
**Já implementado corretamente:**
- [notification_card.dart#L330-340](lib/features/inbox/presentation/widgets/notification_card.dart#L330-L340)
- Detecta € e aplica cor baseado no tipo de notificação
- Vermelho (#FF4444) para débitos
- Verde (#4CAF50) para créditos

### 4. ⏳ Trigger para `chatMessage` (não-mention)
**Novo:** Trigger criado no arquivo SQL para notificar mensagens normais de chat (categoria `push`/ephemeral)

---

## 🔧 Passos para Implementação no Supabase

### Passo 1: Executar SQL
Abra o [SQL Editor do Supabase](https://supabase.com/dashboard/project/_/sql) e execute o arquivo:

```bash
📁 NOTIFICATIONS_FIX.sql
```

Este script vai:
1. ✅ Adicionar campos `expense_name` e `person_name` à tabela `notifications`
2. ✅ Atualizar trigger `notify_expense_added` para preencher esses campos
3. ✅ Criar trigger `notify_chat_message` para mensagens de chat
4. ✅ Alterar formato do amount para `"25.00€"` (símbolo no final)

### Passo 2: Verificar Triggers Ativos
Execute no SQL Editor:

```sql
SELECT 
  trigger_name, 
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE trigger_schema = 'public'
  AND trigger_name IN (
    'expense_added_notification', 
    'chat_message_notification', 
    'chat_mention_notification'
  );
```

**Resultado esperado:**
- ✅ `expense_added_notification` em `expense_splits`
- ✅ `chat_message_notification` em `chat_messages`
- ✅ `chat_mention_notification` em `chat_messages` (já existente)

### Passo 3: Testar Notificação de Expense
1. Criar uma despesa nova no app
2. Verificar que a notificação aparece como:
   - `"João added the expense "Jantar". You owe 25.00€"` (nome real da despesa, € no final)
   - Valor em **vermelho** se você deve
   - Valor em **verde** se alguém te deve

### Passo 4: Testar Notificação de Chat
1. Enviar mensagem no chat de um evento
2. Verificar que push notification é enviada
3. **Importante:** Não deve aparecer no inbox (categoria `push` = ephemeral)

---

## 📊 Estrutura Atualizada da Tabela `notifications`

### Campos Novos:
```sql
expense_name TEXT    -- Nome da despesa (ex: "Jantar no restaurante")
person_name TEXT     -- Nome da pessoa que deve (ex: "Maria Silva")
```

### Formato do Amount:
```sql
-- ANTES
amount: "€25.00"

-- AGORA
amount: "25.00€"
```

---

## 🧪 Exemplos de Notificações

### Exemplo 1: Payment Added (You Owe)
**Dados na tabela `notifications`:**
```json
{
  "type": "paymentsAddedYouOwe",
  "user_name": "João Silva",
  "expense_name": "Jantar no restaurante",
  "amount": "25.00€",
  "event_emoji": "🍽️",
  "event_name": "Dinner Party"
}
```

**Texto renderizado no inbox:**
> **João Silva** added the expense "**Jantar no restaurante**". You owe **<span style="color: red">25.00€</span>**

### Exemplo 2: Payment Added (Owes You)
**Dados na tabela `notifications`:**
```json
{
  "type": "paymentsAddedOwesYou",
  "user_name": "João Silva",
  "expense_name": "Jantar no restaurante",
  "person_name": "Maria Silva",
  "amount": "25.00€",
  "event_emoji": "🍽️",
  "event_name": "Dinner Party"
}
```

**Texto renderizado no inbox:**
> **João Silva** added the expense "**Jantar no restaurante**". **Maria Silva** owes you **<span style="color: green">25.00€</span>**

### Exemplo 3: Chat Message (Push Only)
**Dados na tabela `notifications`:**
```json
{
  "type": "chatMessage",
  "category": "push",
  "user_name": "Pedro Costa",
  "event_emoji": "🎉",
  "event_name": "Birthday Party"
}
```

**Push notification:**
> 🎉 Birthday Party  
> Pedro Costa sent a message

**Inbox:** ❌ Não aparece (categoria `push`)

---

## ✅ Checklist de Validação

### Flutter (Já Completo)
- [x] Amount formatado com € no final (`notification_entity.dart`)
- [x] Notificação de expense usa formato correto (`event_expense_remote_data_source.dart`)
- [x] Cores verde/vermelho aplicadas corretamente (`notification_card.dart`)
- [x] Placeholders `{expense_name}` e `{person_name}` implementados
- [x] `flutter analyze` sem erros (apenas 2 warnings pré-existentes)

### Supabase (Pendente)
- [ ] Executar `NOTIFICATIONS_FIX.sql`
- [ ] Verificar campos `expense_name` e `person_name` criados
- [ ] Testar trigger `notify_expense_added` (criar despesa)
- [ ] Testar trigger `notify_chat_message` (enviar mensagem)
- [ ] Validar formato do amount em notificações novas

---

## 🚨 Notas Importantes

### Migração de Dados Existentes
Notificações antigas não terão `expense_name` e `person_name` preenchidos.  
Para corrigir (opcional):

```sql
UPDATE notifications n
SET expense_name = ee.title
FROM event_expenses ee
WHERE n.expense_id = ee.id 
  AND n.expense_name IS NULL
  AND n.type IN ('paymentsAddedYouOwe', 'paymentsAddedOwesYou', 'paymentsRequest');
```

### Chat Message vs Chat Mention
- **chatMention:** Trigger já existe (quando mensagem contém @username)
- **chatMessage:** Novo trigger para todas as mensagens (categoria `push`)
- **TODO:** Filtrar users ativos no chat para não enviar notificação desnecessária

### Formato Regional
O símbolo € está no final (padrão português/europeu).  
Se precisar adaptar para outros países:
- Criar lógica de detecção de locale
- Formato US: `"$25.00"` (símbolo no início)
- Formato PT/EU: `"25.00€"` (símbolo no final) ✅

---

**Próximos Passos:**
1. ✅ Código Flutter está pronto
2. ⏳ Executar SQL no Supabase
3. 🧪 Testar criação de despesas e mensagens de chat
4. 📱 Validar push notifications e inbox rendering

