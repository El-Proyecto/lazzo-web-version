# 🚀 GUIA RÁPIDO - EXECUTAR SQL NO SUPABASE

## ⚠️ ANTES DE EXECUTAR

**IMPORTANTE:** Faça backup do seu banco de dados antes de executar qualquer script SQL em produção!

---

## 📋 PASSO A PASSO

### 1️⃣ Acesse o Supabase Dashboard
1. Abra [https://app.supabase.com](https://app.supabase.com)
2. Faça login com suas credenciais
3. Selecione o projeto **Lazzo**

### 2️⃣ Abra o SQL Editor
1. No menu lateral, clique em **"SQL Editor"**
2. Clique em **"New Query"** (botão verde no canto superior direito)

### 3️⃣ Cole o Script SQL
1. Abra o arquivo `EVENT_DETAIL_SCHEMA.sql` na raiz do projeto
2. Selecione **TODO O CONTEÚDO** do arquivo (Ctrl+A)
3. Copie (Ctrl+C)
4. Cole no SQL Editor do Supabase (Ctrl+V)

### 4️⃣ Execute o Script
1. Clique no botão **"RUN"** (canto inferior direito)
2. Aguarde a execução (pode levar 10-30 segundos)
3. Você verá uma mensagem de sucesso no painel de resultados

---

## ✅ VERIFICAÇÃO PÓS-EXECUÇÃO

### Verificar Tabelas Criadas
Execute esta query no SQL Editor:

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN (
    'rsvps', 'suggestions', 'location_suggestions',
    'suggestion_votes', 'location_suggestion_votes',
    'polls', 'poll_options', 'poll_votes', 'chat_messages'
  )
ORDER BY table_name;
```

**Resultado esperado:** 9 tabelas

```
chat_messages
location_suggestion_votes
location_suggestions
poll_options
poll_votes
polls
rsvps
suggestion_votes
suggestions
```

---

### Verificar Enums Criados
Execute esta query:

```sql
SELECT typname 
FROM pg_type 
WHERE typtype = 'e' 
  AND typname IN ('rsvp_status', 'poll_type');
```

**Resultado esperado:** 2 enums

```
poll_type
rsvp_status
```

---

### Verificar RLS Habilitado
Execute esta query:

```sql
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN (
    'rsvps', 'suggestions', 'location_suggestions',
    'suggestion_votes', 'location_suggestion_votes',
    'polls', 'poll_options', 'poll_votes', 'chat_messages'
  )
ORDER BY tablename;
```

**Resultado esperado:** Todas as tabelas com `rowsecurity = true`

---

### Verificar Policies Criadas
Execute esta query:

```sql
SELECT tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename IN (
    'rsvps', 'suggestions', 'location_suggestions',
    'suggestion_votes', 'location_suggestion_votes',
    'polls', 'poll_options', 'poll_votes', 'chat_messages'
  )
ORDER BY tablename, policyname;
```

**Resultado esperado:** 14 policies (2 por tabela em média)

---

### Verificar RPC Functions
Execute esta query:

```sql
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_type = 'FUNCTION' 
  AND routine_name IN (
    'increment_poll_vote_count',
    'decrement_poll_vote_count'
  );
```

**Resultado esperado:** 2 funções

```
decrement_poll_vote_count
increment_poll_vote_count
```

---

## 🧪 TESTE MANUAL (OPCIONAL)

### Testar Inserção com RLS
1. No SQL Editor, execute:

```sql
-- Criar um RSVP de teste (substituir com IDs reais)
INSERT INTO rsvps (event_id, user_id, status)
VALUES (
  'COLOQUE_ID_DE_EVENTO_AQUI',
  auth.uid(), -- seu user ID atual
  'going'
);

-- Verificar se foi criado
SELECT * FROM rsvps WHERE user_id = auth.uid();
```

2. Se funcionar, **delete o teste:**

```sql
DELETE FROM rsvps WHERE user_id = auth.uid() LIMIT 1;
```

---

## ❌ SOLUÇÃO DE PROBLEMAS

### Erro: "relation already exists"
**Causa:** Tabela já foi criada antes.

**Solução:**
- Se for ambiente de desenvolvimento: DROP TABLE e execute novamente
- Se for produção: Verifique se precisa executar novamente

### Erro: "permission denied"
**Causa:** Usuário atual não tem permissões de admin.

**Solução:**
- Certifique-se de estar logado como Owner do projeto
- Ou use a conta de service role (não recomendado)

### Erro: "syntax error at or near..."
**Causa:** Script SQL incompleto ou corrompido.

**Solução:**
- Certifique-se de copiar TODO o arquivo `EVENT_DETAIL_SCHEMA.sql`
- Verifique se não há caracteres especiais na cópia

---

## 📊 PRÓXIMOS PASSOS APÓS EXECUÇÃO

1. ✅ Verificar que todas as queries de verificação passaram
2. 🚀 Executar `flutter run` para testar integração
3. 🧪 Testar criação de RSVP via UI
4. 📝 Verificar dados no Supabase Table Editor

---

## 🆘 PRECISA DE AJUDA?

Se encontrar algum erro:
1. Copie a mensagem de erro completa
2. Verifique qual linha do SQL causou o erro
3. Consulte o arquivo `EVENT_DETAIL_P2_IMPLEMENTATION.md` para contexto
4. Em último caso, role back o banco e tente novamente

---

**Última atualização:** Após P2 implementation  
**Tempo estimado:** 10 minutos  
**Dificuldade:** ⭐ Fácil
