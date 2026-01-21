-- ========================================================================
-- CREATE VIEW: user_payment_debts_view
-- ========================================================================
-- PURPOSE: Provides a denormalized view of payment debts for the Inbox Payments feature
--
-- This view joins event_expenses and expense_splits to show who owes whom,
-- including all necessary context (event name, emoji, payer name, amounts)
-- ========================================================================

CREATE OR REPLACE VIEW public.user_payment_debts_view AS
SELECT 
  -- IDs
  (es.expense_id || '_' || es.user_id) AS payment_id,  -- Unique payment ID
  es.expense_id,
  es.user_id AS debtor_user_id,            -- Who owes money
  ee.paid_by AS paid_by_user_id,           -- Who paid (creditor)
  ee.event_id,
  
  -- Amounts
  es.amount AS debt_amount,                -- How much the debtor owes
  es.has_paid,                             -- Payment status
  
  -- Expense details
  ee.title AS expense_title,
  ee.total_amount AS expense_total_amount,
  ee.created_at,
  ee.created_by AS expense_created_by,
  
  -- Debtor details (user who owes)
  debtor.name AS debtor_user_name,
  debtor.avatar_url AS debtor_avatar_url,
  
  -- Creditor details (user who paid)
  creditor.name AS paid_by_user_name,
  creditor.avatar_url AS paid_by_avatar_url,
  
  -- Event details
  e.name AS event_name,
  e.emoji AS event_emoji,
  e.group_id,
  
  -- Group details
  g.name AS group_name

FROM public.expense_splits es
INNER JOIN public.event_expenses ee ON ee.id = es.expense_id
INNER JOIN public.events e ON e.id = ee.event_id
INNER JOIN public.users debtor ON debtor.id = es.user_id
INNER JOIN public.users creditor ON creditor.id = ee.paid_by
LEFT JOIN public.groups g ON g.id = e.group_id

-- Only show unpaid debts
WHERE es.has_paid = FALSE

-- Order by most recent first
ORDER BY ee.created_at DESC;

-- ========================================================================
-- GRANT ACCESS
-- ========================================================================
GRANT SELECT ON public.user_payment_debts_view TO authenticated;

COMMENT ON VIEW public.user_payment_debts_view IS 'Denormalized view of unpaid payment debts for Inbox Payments feature. Shows who owes whom with full context (event, amounts, names). Filtering by user is done in application queries.';
