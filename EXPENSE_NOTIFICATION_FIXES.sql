-- =====================================================
-- EXPENSE NOTIFICATION FIXES
-- =====================================================
-- Este ficheiro contém as alterações necessárias para:
-- 1. Corrigir {expense_name} a aparecer literalmente nas notificações
-- 2. Adicionar suporte para "quem pagou" ser diferente de "quem criou"
-- 
-- NOTA: A estrutura atual assume que created_by = quem pagou
-- Para suportar pagador diferente do criador, precisamos adicionar
-- um novo campo 'paid_by' à tabela event_expenses
-- =====================================================

-- =====================================================
-- PARTE 1: Corrigir edge function para usar 'note' em vez de 'expense_name'
-- =====================================================
-- FICHEIRO: supabase/functions/send-push-notification-apns/index.ts
-- LINHA: 117
-- 
-- ANTES:
--   const { user_name, group_name, event_name, event_emoji, amount, expense_name, person_name, mins, hours, date, time, place, message, note } = data;
--
-- DEPOIS:
--   const { user_name, group_name, event_name, event_emoji, amount, mins, hours, date, time, place, message, note } = data;
--
-- LINHA: 126-129 e 131-133
--
-- ANTES:
--   paymentsAddedYouOwe: {
--     title: `${emoji} ${event_name}`,
--     body: `${user_name} added the expense "${expense_name}"`,
--   },
--   paymentsAddedOwesYou: {
--     title: `${emoji} ${event_name}`,
--     body: `${user_name} added the expense "${expense_name}"`,
--   },
--   paymentsRequest: {
--     title: `${emoji} ${event_name}`,
--     body: `${user_name} requested ${amount} for ${expense_name}`,
--   },
--
-- DEPOIS:
--   paymentsAddedYouOwe: {
--     title: `${emoji} ${event_name}`,
--     body: `${user_name} added the expense "${note}"`,
--   },
--   paymentsAddedOwesYou: {
--     title: `${emoji} ${event_name}`,
--     body: `${user_name} added the expense "${note}"`,
--   },
--   paymentsRequest: {
--     title: `${emoji} ${event_name}`,
--     body: `${user_name} requested ${amount} for ${note}`,
--   },

-- =====================================================
-- PARTE 2 (OPCIONAL): Adicionar campo 'paid_by' para suportar pagador ≠ criador
-- =====================================================
-- ATENÇÃO: Isto é uma mudança estrutural significativa!
-- Só aplique se realmente precisar que o criador da despesa seja diferente de quem pagou
-- 
-- Cenário atual: 
--   - created_by = quem criou E pagou a despesa
--   - expense_splits = quem deve pagar
--
-- Cenário com paid_by:
--   - created_by = quem criou a despesa (pode ser o host do evento, admin, etc.)
--   - paid_by = quem efetivamente pagou a despesa (pode ser diferente)
--   - expense_splits = quem deve pagar

-- 2.1: Adicionar coluna 'paid_by' à tabela event_expenses
ALTER TABLE public.event_expenses 
ADD COLUMN paid_by uuid REFERENCES public.users(id);

-- 2.2: Popular paid_by com os valores de created_by (migração de dados existentes)
UPDATE public.event_expenses 
SET paid_by = created_by 
WHERE paid_by IS NULL;

-- 2.3: Tornar paid_by obrigatório após migração
ALTER TABLE public.event_expenses 
ALTER COLUMN paid_by SET NOT NULL;

-- 2.4: Adicionar índice para performance
CREATE INDEX idx_event_expenses_paid_by ON public.event_expenses(paid_by);

-- 2.5: Atualizar view user_payment_debts_view para usar paid_by
DROP VIEW IF EXISTS public.user_payment_debts_view;

CREATE VIEW public.user_payment_debts_view WITH (security_invoker='on') AS
 SELECT ((es.expense_id || '_'::text) || es.user_id) AS payment_id,
    ee.id AS expense_id,
    ee.title AS expense_title,
    es.amount AS debt_amount,
    es.has_paid,
    ee.created_at,
    ee.paid_by AS paid_by_user_id,  -- ✅ MUDANÇA: usar paid_by em vez de created_by
    payer.name AS paid_by_user_name,
    payer.avatar_url AS paid_by_avatar_url,
    es.user_id AS debtor_user_id,
    debtor.name AS debtor_user_name,
    debtor.avatar_url AS debtor_avatar_url,
    e.id AS event_id,
    e.name AS event_name,
    e.emoji AS event_emoji,
    g.id AS group_id,
    g.name AS group_name
   FROM (((((public.expense_splits es
     JOIN public.event_expenses ee ON ((es.expense_id = ee.id)))
     JOIN public.events e ON ((ee.event_id = e.id)))
     JOIN public.groups g ON ((e.group_id = g.id)))
     JOIN public.users payer ON ((ee.paid_by = payer.id)))  -- ✅ MUDANÇA: usar paid_by
     JOIN public.users debtor ON ((es.user_id = debtor.id)))
  WHERE (es.has_paid = false);

-- 2.6: Atualizar Flutter para usar paid_by
-- FICHEIRO: lib/features/expense/data/data_sources/event_expense_remote_data_source.dart
-- MUDANÇA: adicionar campo 'paid_by' ao insert
--
-- ANTES:
--   .insert({
--     'event_id': eventId,
--     'title': description,
--     'total_amount': amount,
--     'created_by': paidBy,
--   })
--
-- DEPOIS:
--   .insert({
--     'event_id': eventId,
--     'title': description,
--     'total_amount': amount,
--     'created_by': auth.currentUser?.id,  // quem está a criar
--     'paid_by': paidBy,                    // quem pagou
--   })

-- =====================================================
-- PARTE 3: Verificar trigger de notificações
-- =====================================================
-- O trigger notify_expense_added precisa ser verificado para garantir
-- que usa os campos corretos da tabela event_expenses

-- Verificar se o trigger existe:
-- SELECT * FROM pg_trigger WHERE tgname = 'expense_added_trigger';

-- Se existir, pode precisar ser ajustado para:
-- 1. Usar 'note' na notificação (já está correto se seguiu o NotificationService)
-- 2. Usar 'paid_by' em vez de 'created_by' se implementar PARTE 2

-- =====================================================
-- RESUMO DA DECISÃO
-- =====================================================
-- OPÇÃO A (Simples - Recomendado se created_by = paid_by):
--   - Aplicar apenas PARTE 1 (corrigir TypeScript)
--   - Manter estrutura atual onde created_by é quem pagou
--   - Mais simples, menos mudanças
--
-- OPÇÃO B (Completo - Se precisar separar criador de pagador):
--   - Aplicar PARTE 1 + PARTE 2
--   - Adicionar campo paid_by
--   - Atualizar todas as queries/views/triggers
--   - Atualizar Flutter
--   - Mais flexível, mas requer mais testes

-- =====================================================
-- TESTE APÓS APLICAR
-- =====================================================
-- 1. Criar uma expense via Flutter
-- 2. Verificar se a notificação foi criada com 'note' preenchido
-- 3. Verificar se o push notification mostra o nome correto da despesa
-- 4. Verificar se a inbox mostra o nome correto da despesa
-- 5. Se aplicou PARTE 2, verificar se paid_by está correto

-- Query para verificar notificações de expenses:
-- SELECT id, type, note, expense_id, user_name, event_name, amount
-- FROM notifications
-- WHERE type = 'paymentsAddedYouOwe'
-- ORDER BY created_at DESC
-- LIMIT 5;

-- Query para verificar event_expenses:
-- SELECT id, title, created_by, paid_by, total_amount
-- FROM event_expenses
-- ORDER BY created_at DESC
-- LIMIT 5;
