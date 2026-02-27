-- Add 'expired' value to event_state enum
-- Expired = pending events whose start_datetime passed without being confirmed
ALTER TYPE public.event_state ADD VALUE IF NOT EXISTS 'expired';
