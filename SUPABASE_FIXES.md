# 🔧 Alterações Necessárias no Supabase

## 1. Adicionar coluna `updated_at` à tabela `events`

### Problema
Ao tentar editar a hora do evento, o sistema tenta atualizar a coluna `updated_at` na tabela `events`, mas essa coluna não existe. Isto causa o erro:
```
PostgrestException(message: code:42703, details:The result contains 0 rows
hint:null, message:JSON object requested, multiple (or no) rows returned
```

### Solução SQL

Execute este SQL no Supabase SQL Editor:

```sql
-- 1. Adicionar coluna updated_at (se não existir)
ALTER TABLE events 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 2. Atualizar registos existentes para terem updated_at = created_at
UPDATE events 
SET updated_at = created_at 
WHERE updated_at IS NULL;

-- 3. Tornar a coluna NOT NULL
ALTER TABLE events 
ALTER COLUMN updated_at SET NOT NULL;

-- 4. Criar função para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 5. Criar trigger na tabela events
DROP TRIGGER IF EXISTS update_events_updated_at ON events;

CREATE TRIGGER update_events_updated_at
    BEFORE UPDATE ON events
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

### Verificação
```sql
-- Verificar se a coluna foi criada
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'events'
  AND column_name = 'updated_at';

-- Testar o trigger
UPDATE events 
SET name = name 
WHERE id = (SELECT id FROM events LIMIT 1)
RETURNING id, name, updated_at;
```

---

## 2. Corrigir RLS Policies para `event_participants` (RSVP)

### Problema
Os votos RSVP não estão a ser persistidos no Supabase. Isto pode ser causado por políticas RLS que bloqueiam o UPSERT.

### Verificar políticas existentes
```sql
-- Ver políticas atuais
SELECT schemaname, tablename, policyname, permissive, cmd, qual, with_check
FROM pg_policies
WHERE tablename = 'event_participants';
```

### Criar políticas necessárias
```sql
-- Permitir SELECT (ver RSVPs)
DROP POLICY IF EXISTS "Users can view event_participants" ON event_participants;

CREATE POLICY "Users can view event_participants"
ON event_participants FOR SELECT
TO authenticated
USING (
  -- Ver RSVPs de eventos em grupos onde é membro
  pevent_id IN (
    SELECT e.id 
    FROM events e
    JOIN group_members gm ON e.group_id = gm.group_id
    WHERE gm.user_id = auth.uid()
  )
);

-- Permitir INSERT (criar RSVP)
DROP POLICY IF EXISTS "Users can insert own RSVP" ON event_participants;

CREATE POLICY "Users can insert own RSVP"
ON event_participants FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- Permitir UPDATE (alterar RSVP)
DROP POLICY IF EXISTS "Users can update own RSVP" ON event_participants;

CREATE POLICY "Users can update own RSVP"
ON event_participants FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());
```

### Adicionar Primary Key para UPSERT funcionar
```sql
-- Verificar se primary key existe
SELECT constraint_name, constraint_type
FROM information_schema.table_constraints
WHERE table_name = 'event_participants'
  AND constraint_type = 'PRIMARY KEY';

-- Se não existir, criar
ALTER TABLE event_participants 
DROP CONSTRAINT IF EXISTS event_participants_pkey CASCADE;

ALTER TABLE event_participants 
ADD CONSTRAINT event_participants_pkey 
PRIMARY KEY (pevent_id, user_id);
```

---

## 3. Verificar RLS Policies para `users.avatar_url`

### Problema
Os avatares podem não aparecer se a política RLS bloquear a leitura da coluna `avatar_url`.

### Verificar políticas existentes
```sql
-- Ver políticas atuais
SELECT schemaname, tablename, policyname, permissive, cmd, qual, with_check
FROM pg_policies
WHERE tablename = 'users';
```

### Criar política para ler avatares
```sql
-- Permitir SELECT de avatares
DROP POLICY IF EXISTS "Users can read user profiles" ON users;

CREATE POLICY "Users can read user profiles"
ON users FOR SELECT
TO authenticated
USING (true);  -- Todos os utilizadores autenticados podem ver perfis
```

---

## 4. Adicionar Indexes para Performance

```sql
-- Index para consultas de RSVP por evento
CREATE INDEX IF NOT EXISTS idx_event_participants_event 
ON event_participants(pevent_id);

-- Index para consultas de RSVP por utilizador
CREATE INDEX IF NOT EXISTS idx_event_participants_user 
ON event_participants(user_id);

-- Index composto para consultas por evento e status
CREATE INDEX IF NOT EXISTS idx_event_participants_event_rsvp 
ON event_participants(pevent_id, rsvp);

-- Index para avatar_url lookups
CREATE INDEX IF NOT EXISTS idx_users_avatar 
ON users(avatar_url) 
WHERE avatar_url IS NOT NULL;
```

---

## 5. Testar as Correções

### Testar `updated_at`
```sql
-- Editar um evento e verificar se updated_at é atualizado
UPDATE events 
SET start_datetime = start_datetime + INTERVAL '1 hour'
WHERE id = '<event_id>'
RETURNING id, name, updated_at;
```

### Testar RSVP
```sql
-- Ver RSVPs antes
SELECT user_id, rsvp FROM event_participants WHERE pevent_id = '<event_id>';

-- Fazer UPSERT (como a app faz)
INSERT INTO event_participants (pevent_id, user_id, rsvp, confirmed_at)
VALUES ('<event_id>', '<user_id>', 'no', NOW())
ON CONFLICT (pevent_id, user_id)
DO UPDATE SET rsvp = EXCLUDED.rsvp, confirmed_at = EXCLUDED.confirmed_at
RETURNING *;

-- Ver RSVPs depois
SELECT user_id, rsvp FROM event_participants WHERE pevent_id = '<event_id>';
```

### Testar Avatar
```sql
-- Ver avatares dos utilizadores
SELECT id, name, avatar_url FROM users LIMIT 10;

-- Verificar se pode ler (como utilizador autenticado)
SELECT id, name, avatar_url FROM users WHERE id = '<user_id>';
```

---

## 6. Checklist de Validação

Após executar o SQL acima:

- [ ] Coluna `updated_at` existe em `events`
- [ ] Trigger `update_events_updated_at` está ativo
- [ ] Editar hora do evento não dá erro
- [ ] Primary key `(pevent_id, user_id)` existe em `event_participants`
- [ ] RLS permite INSERT/UPDATE próprio RSVP
- [ ] RLS permite SELECT de RSVPs de eventos do grupo
- [ ] RLS permite SELECT de `users.avatar_url`
- [ ] Indexes criados para performance
- [ ] UPSERT de RSVP funciona
- [ ] Avatares aparecem no chat

---

## 7. Ordem de Execução

Execute nesta ordem:

1. **events.updated_at** (SQL #1)
2. **event_participants Primary Key** (SQL #2 - parte 3)
3. **event_participants RLS** (SQL #2 - parte 2)
4. **users RLS** (SQL #3)
5. **Indexes** (SQL #4)
6. **Testar** (SQL #5)

---

## 📌 Notas Importantes

- A função `update_updated_at_column()` é reutilizável para outras tabelas
- O trigger só atualiza `updated_at` em **UPDATE**, não em **INSERT**
- Primary key `(pevent_id, user_id)` permite UPSERT funcionar corretamente
- RLS políticas permitem que utilizadores vejam RSVPs de eventos nos seus grupos
- Todos os utilizadores autenticados podem ver perfis (incluindo avatares)
- Avatares são armazenados como paths no DB mas convertidos para URLs públicos no código
