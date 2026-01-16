# ✅ CORREÇÃO APLICADA: Notificações de Expenses

## 📋 Problema Identificado

1. **Push notifications e inbox mostravam literalmente `{expense_name}`** em vez do nome da despesa
2. **Campos inexistentes** sendo usados: `expense_name` e `person_name` não existem na tabela `notifications`
3. **Campo correto disponível:** `note` (que já está a ser preenchido pelo Flutter com o nome da despesa)

## 🔧 Alterações Aplicadas

### 1. Edge Function TypeScript (`supabase/functions/send-push-notification-apns/index.ts`)
- ✅ Removido `expense_name` e `person_name` da desestruturação (linha 117)
- ✅ Alterado `paymentsAddedYouOwe` para usar `${note}` em vez de `${expense_name}`
- ✅ Alterado `paymentsAddedOwesYou` para usar `${note}` em vez de `${expense_name}`
- ✅ Alterado `paymentsRequest` para usar `${note}` em vez de `${expense_name}`

### 2. Flutter - NotificationModel (`lib/features/inbox/data/models/notification_model.dart`)
- ✅ Removido campos `expenseName` e `personName` da classe
- ✅ Removido mapeamento de `json['expense_name']` e `json['person_name']`
- ✅ Atualizado templates de mensagem:
  - `paymentsRequest`: usa `{note}` ✅
  - `paymentsAddedYouOwe`: usa `{note}` ✅
  - `paymentsAddedOwesYou`: usa `{note}` + texto genérico "Someone owes you" ✅

### 3. Flutter - NotificationEntity (`lib/features/inbox/domain/entities/notification_entity.dart`)
- ✅ Removido propriedades `expenseName` e `personName`
- ✅ Removido do construtor
- ✅ Removido do método `copyWith`
- ✅ Removido substituições de `{expense_name}` e `{person_name}` no `formattedMessage`

## 🗄️ Estrutura do Supabase (Análise)

### Tabela `notifications`
✅ **Campos disponíveis:**
- `id`, `recipient_user_id`, `type`, `category`, `priority`
- `event_id`, `expense_id` ✅ (para link)
- `user_name`, `event_name`, `amount`
- `note` ✅ (usado para nome da despesa)
- **NÃO tem:** `expense_name`, `person_name`

### Tabela `event_expenses`
✅ **Estrutura atual:**
- `id`, `event_id`, `title`, `total_amount`, `created_at`
- `created_by` (quem criou a despesa)
- **NÃO tem:** campo separado para "quem pagou"

❓ **Limitação identificada:**
A estrutura atual **não suporta criador ≠ pagador**. A view `user_payment_debts_view` assume que `created_by` = "quem pagou".

## 📄 Ficheiro Criado para Referência

**`EXPENSE_NOTIFICATION_FIXES.sql`**
- Documentação completa das mudanças
- **PARTE 1:** Correções aplicadas (TypeScript + Flutter)
- **PARTE 2 (OPCIONAL):** Como adicionar campo `paid_by` se for necessário suportar pagador ≠ criador
- Instruções SQL para migração caso seja necessário
- Queries de teste

## ✅ Resultado Esperado

Agora quando uma expense é criada:
1. ✅ Flutter preenche `p_note` com o `description` (nome da despesa)
2. ✅ Supabase guarda em `notifications.note`
3. ✅ Edge function usa `${note}` para gerar push notification
4. ✅ Flutter inbox usa `{note}` no template
5. ✅ **Resultado:** Nome correto da despesa aparece em vez de `{expense_name}`

## 🧪 Como Testar

1. Criar uma expense no app (ex: "Jantar de equipa")
2. Verificar notificação push mostra: "João added the expense 'Jantar de equipa'"
3. Verificar inbox mostra: "João added the expense 'Jantar de equipa'. You owe 25€"
4. Query de verificação:
```sql
SELECT 
  type, 
  note AS expense_name, 
  user_name, 
  amount, 
  expense_id
FROM notifications
WHERE type = 'paymentsAddedYouOwe'
ORDER BY created_at DESC
LIMIT 5;
```

## ⚠️ Nota sobre "Person Name"

O campo `person_name` foi removido porque:
- ❌ Não existe na tabela `notifications`
- ❌ Não é necessário para o caso "you owe"
- ✅ Para o caso "someone owes you", usamos texto genérico: "Someone owes you {amount}"

**Alternativa futura (se necessário):**
- Se quiser mostrar quem deve especificamente, seria necessário:
  1. Fazer JOIN com `expense_splits` via `expense_id`
  2. Buscar os nomes dos devedores
  3. Mas isto já está disponível na UI de detalhes da expense

## 📊 Status Final

| Item | Estado | Nota |
|------|--------|------|
| Push notifications | ✅ Corrigido | Usa `note` |
| Inbox | ✅ Corrigido | Usa `note` |
| Flutter compila | ✅ OK | Sem erros |
| Edge function | ✅ OK | Usa `note` |
| expense_id linkado | ✅ OK | Já estava correto |
| Criador ≠ Pagador | ⚠️ Não suportado | Ver PARTE 2 se necessário |
