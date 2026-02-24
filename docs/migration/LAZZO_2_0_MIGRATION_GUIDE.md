# LAZZO 2.0 — Migration Guide: Groups & Chat Removal + Event Invites

## Overview

Lazzo 2.0 muda de um modelo **group-centric** para um modelo **event-centric**. Os eventos deixam de estar ligados a grupos. Os convites são partilhados externamente (WhatsApp, Instagram, SMS) através de links com token. Quem não tem a app vê uma **landing page web** com os detalhes do evento e pode fazer RSVP. Quem tem a app é **auto-joined** ao evento.

### Mudanças Fundamentais

| Antes (v1)                         | Depois (v2)                                      |
| ---------------------------------- | ------------------------------------------------ |
| Eventos pertencem a um grupo       | Eventos são **standalone**                        |
| Chat por evento (in-app)           | **Sem chat** — coordenação via WhatsApp/etc.      |
| Convites via grupo (in-app)        | Convites via **link partilhável** (qualquer canal) |
| Só users com app veem o evento     | **Web landing page** para não-users               |
| RSVP apenas para users autenticados | **Guest RSVP** via web (sem app necessária)       |
| Grupos são entidade central        | Grupos **removidos por completo**                 |

---

## O que é removido

### Tabelas Eliminadas
| Tabela                   | Razão                                                |
| ------------------------ | ---------------------------------------------------- |
| `groups`                 | Conceito de grupo removido                           |
| `group_members`          | Sem grupos, sem membros de grupo                     |
| `group_invites`          | Substituído por `event_invite_links`                 |
| `group_invite_links`     | Idem                                                 |
| `group_messages`         | Sem grupos, sem mensagens de grupo                   |
| `group_user_settings`    | Sem grupos, sem settings de grupo                    |
| `chat_messages`          | Chat removido                                        |
| `message_reads`          | Chat removido                                        |

### Views/Materialized Views Eliminadas
| View                           | Substituição                                  |
| ------------------------------ | --------------------------------------------- |
| `group_hub_events_view`        | Removida (não há group hub)                   |
| `group_hub_events_cache`       | Removida                                      |
| `group_photos_with_uploader`   | Renomeada → `event_photos_with_uploader`      |
| `home_events_view`             | Recriada sem referências a grupos             |
| `event_participants_summary_view` | Recriada sem `group_id`                    |

### Funções Eliminadas
- Todas as funções `notify_chat_*`, `notify_group_*`
- `accept_group_invite`, `accept_group_invite_by_token`
- `create_group_invite_link`, `get_or_create_group_invite_link`
- `leave_group`, `is_admin`, `is_member`, `is_group_creator`
- `get_group_member_count`
- `add_group_members_to_event`, `add_new_member_to_group_events`
- `auto_refresh_group_cache`, `auto_refresh_group_photos_view`
- `handle_new_group`

### Colunas Removidas
| Tabela          | Coluna        | Razão                       |
| --------------- | ------------- | --------------------------- |
| `events`        | `group_id`    | Eventos são standalone      |
| `notifications` | `group_id`    | Sem grupos                  |
| `notifications` | `group_name`  | Sem grupos                  |
| `user_notification_settings` | `push_enabled_for_chat` | Sem chat |

### Types Removidos
- `group_state` (active/archived)
- `member_role` (admin/member)
- `message_type` (text/event/expense)

---

## O que é criado/alterado

### Novas Tabelas

#### `event_invite_links`
Token-based invite links para eventos, partilháveis via qualquer canal.

```
┌───────────────────────────────────────────────────────────────┐
│ event_invite_links                                             │
├───────────────┬──────────────┬─────────────────────────────────┤
│ id            │ uuid PK      │ gen_random_uuid()               │
│ event_id      │ uuid FK      │ → events(id) ON DELETE CASCADE  │
│ created_by    │ uuid FK      │ → users(id) ON DELETE CASCADE   │
│ token         │ text UNIQUE  │ URL-safe token (24 chars)       │
│ expires_at    │ timestamptz  │ Default: now() + 48h            │
│ revoked_at    │ timestamptz  │ NULL = active                   │
│ share_channel │ text         │ 'whatsapp'/'instagram'/'sms'/…  │
│ open_count    │ integer      │ Track how many times opened     │
│ created_at    │ timestamptz  │ now()                           │
└───────────────┴──────────────┴─────────────────────────────────┘
```

**Indexes:**
- `idx_event_invite_links_token` — UNIQUE, partial (WHERE revoked_at IS NULL)
- `idx_event_invite_links_event_valid` — Por evento + expiração

#### `event_guest_rsvps`
RSVP de convidados que **não têm a app** (via web landing page).

```
┌───────────────────────────────────────────────────────────────┐
│ event_guest_rsvps                                              │
├──────────────┬──────────────┬──────────────────────────────────┤
│ id           │ uuid PK      │ gen_random_uuid()                │
│ event_id     │ uuid FK      │ → events(id) ON DELETE CASCADE   │
│ invite_token │ text         │ Token usado para aceder           │
│ guest_name   │ text         │ Nome do convidado                 │
│ guest_phone  │ text         │ Contacto opcional                 │
│ rsvp         │ text         │ 'going' / 'not_going' / 'maybe'  │
│ plus_one     │ integer      │ Acompanhantes (default 0)         │
│ created_at   │ timestamptz  │ now()                             │
│ updated_at   │ timestamptz  │ Auto-updated via trigger          │
└──────────────┴──────────────┴──────────────────────────────────┘
```

#### `invite_analytics`
Tracking do funil de conversão dos convites.

```
┌───────────────────────────────────────────────────────────────┐
│ invite_analytics                                               │
├──────────────┬──────────────┬──────────────────────────────────┤
│ id           │ uuid PK      │ gen_random_uuid()                │
│ event_id     │ uuid FK      │ → events(id) ON DELETE CASCADE   │
│ invite_token │ text         │ Token associado                   │
│ action       │ text         │ Ver ações abaixo                  │
│ user_id      │ uuid FK?     │ NULL para visitantes anónimos     │
│ metadata     │ jsonb        │ User agent, referrer, etc.        │
│ created_at   │ timestamptz  │ now()                             │
└──────────────┴──────────────┴──────────────────────────────────┘
```

**Ações trackadas:**
- `link_created` — Host criou um link
- `link_opened_web` — Alguém abriu o link no browser
- `link_opened_app` — Alguém abriu o link na app
- `rsvp_web` — Guest fez RSVP via web
- `rsvp_app` — User fez RSVP na app
- `auto_join_app` — User foi auto-joined via deep link

### Alterações a Tabelas Existentes

#### `events`
- **Removido:** `group_id`
- **Adicionado:** `description` (text) — Descrição para a landing page web
- **Adicionado:** `max_participants` (integer) — Controlo de capacidade opcional

#### `group_photos` → `event_photos`
- Tabela renomeada (era `group_photos`, agora `event_photos`)
- Constraints renomeadas para consistência
- Materialized view renomeada para `event_photos_with_uploader`

#### `notifications`
- **Removidas colunas:** `group_id`, `group_name`
- **Removidos registos** de tipos: `groupInviteReceived`, `groupInviteAccepted`, `groupMemberAdded`, `chatMessage`, `chatMention`

### Novas RPCs (Funções)

| Função | Descrição | Auth |
| ------ | --------- | ---- |
| `get_or_create_event_invite_link(event_id, expires_in_hours, share_channel)` | Cria ou reutiliza um link de convite válido | Authenticated (participante/organizer) |
| `accept_event_invite_by_token(token)` | Auto-join de user autenticado ao evento via token | Authenticated |
| `upsert_event_guest_rsvp_by_token(token, name, rsvp, plus_one, phone)` | RSVP de guest via web (sem conta) | Service role (server-side) |
| `get_event_by_invite_token(token)` | Dados do evento para a web landing page | Service role (server-side) |
| `revoke_event_invite_link(token)` | Revogar um link de convite | Authenticated (organizer only) |

### Funções Recriadas (sem referências a grupos)

| Função | Alteração |
| ------ | --------- |
| `handle_new_event()` | Já não adiciona membros do grupo; só adiciona o criador como participante |
| `is_member_of_event(eid)` | Sem alteração de lógica |
| `get_recent_memories_with_covers(user_id, start_date)` | Parâmetro mudou de `group_ids[]` para `user_id`; query por participação direta |
| `get_user_memories_with_covers(user_id)` | Idem |

---

## Novo Fluxo de Invite

```
                    ┌──────────────┐
                    │  Host cria   │
                    │   evento     │
                    └──────┬───────┘
                           │
                    ┌──────▼───────┐
                    │ Gera link de │
                    │   convite    │
                    │ /e/<TOKEN>   │
                    └──────┬───────┘
                           │
              ┌────────────┼────────────┐
              │                         │
     ┌────────▼────────┐      ┌────────▼────────┐
     │ Partilha via    │      │ Partilha via    │
     │ WhatsApp/Insta  │      │ SMS/Copy link   │
     └────────┬────────┘      └────────┬────────┘
              │                         │
              └────────────┬────────────┘
                           │
                    ┌──────▼───────┐
                    │ Convidado    │
                    │ abre link   │
                    └──────┬───────┘
                           │
              ┌────────────┼────────────┐
              │                         │
     ┌────────▼────────┐      ┌────────▼────────┐
     │   TEM A APP     │      │  NÃO TEM APP    │
     │                 │      │                 │
     │ Universal Link  │      │ Web landing     │
     │ → auto-join     │      │ page com info   │
     │ → Event Page    │      │ do evento       │
     │   (in-app)      │      │ → RSVP como     │
     │                 │      │   guest         │
     └─────────────────┘      └─────────────────┘
```

---

## RLS (Row Level Security)

### `event_invite_links`
- **SELECT:** Participantes e organizador do evento
- **INSERT:** Participantes e organizador (com `created_by = auth.uid()`)

### `event_guest_rsvps`
- **ALL (service role):** Para o web server (Next.js) poder inserir/ler
- **SELECT:** Participantes e organizador do evento podem ver RSVPs de guests

### `invite_analytics`
- **SELECT:** Apenas o organizador do evento
- **INSERT:** Qualquer um (inserções feitas pelas RPCs)

---

## Impacto no Flutter (App) — Alterações Realizadas

> Convenção: todos os locais editados ficaram marcados com `// LAZZO 2.0:` no código.

### Artefacto Criado
- **`EventDisplayEntity`** (`lib/features/event/domain/entities/event_display_entity.dart`) — substitui `GroupEventEntity` em todo o app. Enum `EventDisplayStatus { pending, confirmed, living, recap }`.

### Ficheiros Editados (39 total, por camada)

#### Core / Orchestração (6 ficheiros)
| Ficheiro | Alterações |
|----------|-----------|
| `main.dart` | Removidos imports e DI overrides de grupos (providers, fakes, use cases) |
| `app.dart` | Removido deep link handler de group invites, `_pendingGroupInviteToken`, `_handleGroupInviteLink()` |
| `app_router.dart` | Removidas constantes de rotas de grupo (`groups`, `groupHub`, `groupCreated`, etc.) e handlers |
| `main_layout.dart` | Tab Groups removida; nav remapeada para 3 tabs (Home/Inbox/Profile), create button no centro |
| `main_layout_providers.dart` | Comentário atualizado para 3 tabs |
| `components.dart` | Removidos exports de `group_card.dart` e `group_badge.dart` |

#### Notifications (6 ficheiros)
| Ficheiro | Alterações |
|----------|-----------|
| `notification_entity.dart` | Removidos enum values: `groupInviteReceived`, `groupInviteAccepted`, `groupInviteDeclined`, `newGroupMember`, `chatMessageReceived` |
| `notification_model.dart` | Removidos cases de geração de notificações de grupo |
| `notification_card.dart` | Removidos botões accept/decline de group invite, photo builder, emoji cases de grupo |
| `notifications_section.dart` | Removidos `onAcceptInvite` / `onDeclineInvite` callbacks |
| `inbox_page.dart` | Removidos handlers de group invite, navegação para grupos, `_showSnackBar` |
| `notification_service.dart` | Removidos `sendGroupInvite`, `sendGroupMemberJoined`; `sendEventCreated` simplificado (sem `groupName`/`groupId`) |

#### Profile / Other Profile (10 ficheiros)
| Ficheiro | Alterações |
|----------|-----------|
| `other_profile_providers.dart` | Removidos 4 providers de group invite + 5 imports |
| `other_profile_repository.dart` | Removidos 4 métodos de group invite + import de `invite_group_entity` |
| `other_profile_entity.dart` | `List<GroupEventEntity>` → `List<EventDisplayEntity>` |
| `other_profile_page.dart` | Removido botão invite, `_handleInvitePressed`, `_handleGroupSelected`; atualizado `_onEventTap` |
| `upcoming_together_section.dart` | `GroupEventEntity` → `EventDisplayEntity` |
| `other_profile_model.dart` | Import e tipo de param atualizados |
| `fake_other_profile_repository.dart` | Rewrite completo: `EventDisplayEntity`, removidos 4 métodos de grupo |
| `other_profile_repository_impl.dart` | `EventDisplayEntity`, removidos `_parseEventStatus` → `EventDisplayStatus`, removidos métodos de grupo |
| `other_profile_data_source.dart` | Removidos `getInvitableGroups`, `inviteToGroup`, `acceptGroupInvite`, `declineGroupInvite` |
| Use cases (4 stubs) | `accept_group_invite.dart`, `decline_group_invite.dart`, `get_invitable_groups.dart`, `invite_to_group.dart` — substituídos por stubs de compilação |

#### Home (2 ficheiros)
| Ficheiro | Alterações |
|----------|-----------|
| `home.dart` | Removido `groups_provider` import, `NoGroupsYetCard`, simplificada lógica empty state, renomeados métodos de conversão |
| `no_upcoming_events_card.dart` | Rewrite completo: `StatefulWidget` → `StatelessWidget`, removida classe `GroupChipData`, group chips, scroll controller |

#### Event / Create Event (4 ficheiros)
| Ficheiro | Alterações |
|----------|-----------|
| `event_providers.dart` | Removido `isUserGroupAdminProvider`, `canManageEventProvider` simplificado |
| `event_page.dart` | Navegação `AppRouter.groupHub` → no-op com comentário |
| `create_event_page.dart` | `_createNewGroup` → stub, `onCreateGroup` → no-op, imports comentados |
| `event_repository_impl.dart` | Removidos `groupName`/`groupId` de `sendEventCreated`, query de groups comentada |

#### Shared Components (2 ficheiros)
| Ficheiro | Alterações |
|----------|-----------|
| `event_full_card.dart` | `GroupEventEntity` → `EventDisplayEntity` |
| `fake_notification_repository.dart` | Removidos fakes de `groupInviteReceived` e `groupInviteAccepted` |

#### Dead Code (Compilação — 4 ficheiros)
| Ficheiro | Alterações |
|----------|-----------|
| `group_details_page.dart` | `AppRouter.groups` → string literal |
| `group_hub_page.dart` | Adicionado `EventDisplayEntity` import + conversão inline, removido `displayEvent` unused |
| `create_group_page.dart` | `AppRouter.groupCreated` → string literal, import comentado |
| `groups_page.dart` | `AppRouter.groupHub` → string literal, import comentado |

### Navegação (Antes → Depois)
| Antes (4 tabs) | Depois (3 tabs) |
|----------------|-----------------|
| 0: Home | 0: Home |
| 1: Groups | _(removido)_ |
| 2: Inbox | 1: Inbox |
| 3: Profile | 2: Profile |
| _(sem botão central)_ | Create button no centro (nav index 1) |

### Dead Code Pendente (para remover futuramente)
Estes ficheiros/pastas são dead code — não são importados por nenhum ficheiro ativo mas foram mantidos para compilação:
- `lib/features/groups/` — pasta inteira
- `lib/features/group_hub/` — pasta inteira
- `lib/features/group_details/` — pasta inteira
- `lib/features/create_group/` — pasta inteira  
- `lib/features/edit_group/` — pasta inteira
- `lib/features/group_invites/` — pasta inteira
- `lib/shared/components/cards/group_card.dart`
- `lib/shared/components/common/group_badge.dart`
- `lib/shared/components/chips/group_chip.dart`
- `lib/shared/components/cards/no_groups_yet_card.dart`
- `lib/shared/components/common/invite_to_group_bottom_sheet.dart`

### TODOs Pós-Migration SQL
- `other_profile_data_source.dart` — queries de `group_members` precisam usar `event_participants` quando migration SQL executar
- `create_event/data/repositories/event_repository_impl.dart` — query de `group_members` para notificações precisa ser atualizada

### Features a Criar (Futuro)
- `lib/features/event_invites/` — Novo módulo:
  - `domain/`: `EventInviteLink` entity, `EventInviteRepository` interface, `AcceptEventInvite` use case
  - `data/`: Supabase data source (RPCs), DTOs, repository impl, fake repo
  - `presentation/`: Share bottom sheet, invite button, deep link handler

### Deep Links (Futuro)
```dart
// Novo parsing em lib/app.dart
if (pathSegments.length >= 2 && pathSegments[0] == 'e') {
  final token = pathSegments[1];
  // Se logged in: acceptEventInviteByToken(token) → navegar para EventPage
  // Se logged out: guardar em PendingInviteService → aceitar pós-login
}
```

---

## Impacto no Web (Next.js — a criar)

### Rotas
| Rota | Descrição |
| ---- | --------- |
| `/e/[token]` | Landing page do evento (SSR) |
| `/api/og/event?token=...` | OG image dinâmica para preview no WhatsApp |

### Dados
- O web server usa **Service Role** (server-side only) para chamar `get_event_by_invite_token(token)`
- Nunca expôr a service key ao browser
- RSVP via `upsert_event_guest_rsvp_by_token()` (chamada server-side)

### OG Preview (WhatsApp Card)
```
┌─────────────────────────────────────┐
│  🎉 Aniversário do João            │
│  📍 Bar do Bairro · 20h            │
│  ────────────────────────           │
│  RSVP agora                        │
│  lazzo.app/e/abc123...              │
└─────────────────────────────────────┘
```

---

## Verificação Pós-Migration

Executar manualmente após a migration:

```sql
-- 1. Confirmar que não existem tabelas de grupo
SELECT tablename FROM pg_tables 
WHERE schemaname = 'public' AND tablename LIKE 'group%';
-- Esperado: 0 rows

-- 2. Confirmar que não existem tabelas de chat
SELECT tablename FROM pg_tables 
WHERE schemaname = 'public' AND (tablename LIKE 'chat%' OR tablename = 'message_reads');
-- Esperado: 0 rows

-- 3. Confirmar novas tabelas
SELECT tablename FROM pg_tables 
WHERE schemaname = 'public' AND tablename IN ('event_invite_links', 'event_guest_rsvps', 'invite_analytics');
-- Esperado: 3 rows

-- 4. Confirmar que events não tem group_id
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'events' AND column_name = 'group_id';
-- Esperado: 0 rows

-- 5. Confirmar rename de photos
SELECT tablename FROM pg_tables 
WHERE schemaname = 'public' AND tablename = 'event_photos';
-- Esperado: 1 row

-- 6. Testar flow de invite
-- (substituir por um event_id real)
-- SELECT * FROM get_or_create_event_invite_link('<event_id>');
-- SELECT * FROM get_event_by_invite_token('<token>');

-- 7. Confirmar storage policies foram atualizadas
SELECT policyname, tablename FROM pg_policies 
WHERE schemaname = 'storage' AND policyname LIKE '%group%';
-- Esperado: 0 rows (nenhuma policy com "group" no nome)

-- 8. Confirmar novas storage policies existem
SELECT policyname FROM pg_policies 
WHERE schemaname = 'storage' AND policyname LIKE 'legacy-%' OR policyname LIKE 'event_%';
-- Esperado: 5+ rows

-- 9. Confirmar event_photos RLS policies
SELECT policyname FROM pg_policies 
WHERE tablename = 'event_photos';
-- Esperado: 5 rows (view, upload, delete own, update own, creator manage)

-- 10. Confirmar nenhuma policy referencia group_members
SELECT policyname, tablename, schemaname 
FROM pg_policies 
WHERE qual LIKE '%group_members%' OR with_check LIKE '%group_members%';
-- Esperado: 0 rows
```

---

## Supabase Storage — O que muda

### Análise de Impacto

A migration remove `group_members`, mas **17 storage policies** no bucket `storage.objects` faziam JOIN com `group_members` para controlo de acesso. Sem esta atualização, **o acesso a fotos ficaria completamente partido**.

### Buckets e o seu estado

| Bucket | Antes | Depois | Ação |
| ------ | ----- | ------ | ---- |
| `group-photos` | 6 policies (2 usam `group_members`) | Modo legacy — read-only para autenticados, delete own | Policies substituídas; sem novos uploads |
| `memory_groups` | 7 policies (5 usam `group_members`) | Policies baseadas em `event_participants` | Policies recriadas com JOIN a `event_participants` |
| `event-photos` | 2 policies (já usam `event_participants`) ✅ | **Sem alterações** — continua a funcionar | Bucket principal para novos uploads |
| `thumbs` | 4 policies (já usam `event_participants`) ✅ | **Sem alterações** | OK |
| `users-profile-pic` | 1 policy usa `group_members` para avatar visibility | Policy baseada em `event_participants` | `group_members_can_view_avatars` → `event_participants_can_view_avatars` |

### Estratégia de Storage para Lazzo 2.0

1. **Novos uploads** → bucket `event-photos` (path: `eventId/userId/file.jpg`)
2. **Ficheiros legados em `group-photos`** → acessíveis em read para autenticados; utilizadores podem apagar os seus próprios
3. **Ficheiros legados em `memory_groups`** → acesso controlado por `event_participants`
4. **Avatares** → visibilidade baseada em co-participação em eventos (em vez de co-membership em grupos)

### ⚠️ Consideração Importante: Paths Existentes

Os ficheiros já armazenados em `group-photos` e `memory_groups` têm paths como:
```
group-photos/groupId/eventId/userId/uuid.jpg
memory_groups/groupId/eventId/userId/uuid.jpg
```

Após a migration, o `groupId` no path torna-se **opaco** (já não é usado para controlo de acesso). A tabela `event_photos.storage_path` ainda contém estes paths, e eles continuam a funcionar porque Supabase Storage resolve ficheiros pelo path completo — não valida os segmentos do path individualmente.

**Não é necessário migrar ficheiros** — apenas as policies RLS que controlam quem os pode aceder.

### Padrão Novo para Código Flutter

```dart
// ANTES (v1): upload usava groupId no path
final path = '$groupId/$eventId/$userId/${uuid.v4()}.jpg';
await supabase.storage.from('group-photos').upload(path, file);

// DEPOIS (v2): upload usa só eventId/userId
final path = '$eventId/$userId/${uuid.v4()}.jpg';
await supabase.storage.from('event-photos').upload(path, file);
```

---

## Outras Policies Públicas Atualizadas (Phase 16)

Além do storage, várias RLS policies em tabelas públicas referenciavam `group_members`:

| Tabela | Policy Removida | Policy Nova |
| ------ | --------------- | ----------- |
| `events` | "Users can view events from their groups" | "Event participants can view events" |
| `events` | "Group members can update event cover" | "Event participants can update event cover" |
| `events` | "group members can select group events" | (coberto pela policy acima) |
| `events` | "events_delete_policy" (usava `group_members`) | "Event creator or admin can delete events" |
| `location_suggestions` | "Group members can create/view location suggestions" | "Event participants can create/view location suggestions" |
| `location_suggestions` | "Event creators can delete..." (usava groups JOIN) | "Event creators can delete location suggestions" |
| `locations` | "Users can view locations for accessible events" (grupos) | "Users can view locations for their events" |
| `users` | "users_can_view_avatars_of_group_members" | "users_can_view_avatars_of_event_participants" |
| `event_participants` | "Users can view event_participants" (via `group_members`) | "Users can view event_participants" (via self-join) |

---

## Riscos & Mitigações

| Risco | Mitigação |
| ----- | --------- |
| Perda de dados de grupos/chat | **BACKUP antes de correr a migration** |
| FKs em cascata apagam dados inesperados | Migration usa DROP CASCADE controlado; verificar dependências |
| Views recriadas com schema diferente | Testar queries após migration |
| App crashar com colunas/tabelas removidas | Deploy app update **antes** ou **ao mesmo tempo** que a migration |
| Edge functions a referenciar grupos | Auditar e atualizar edge functions separadamente |
| **Storage policies broken** | **Phase 13-14 recria todas as policies afetadas** |
| **Fotos legacy inacessíveis** | Paths existentes continuam válidos; policies legacy mantêm acesso |
| **Avatar visibility broken** | Policy substituída por `event_participants`-based |

---

## Ordem de Deployment Recomendada

1. **Backup** completo da base de dados
2. **Deploy app update** que remove referências a grupos/chat (ou feature flags)
3. **Correr migration SQL** na Supabase (inclui storage policies)
4. **Verificar** com queries de pós-migration (incluindo storage checks)
5. **Testar acesso a fotos** — upload, view, delete em `event-photos`
6. **Testar avatares** — visibilidade entre co-participants
7. **Deploy web** (Next.js skeleton com `/e/[token]`)
8. **Testar** flow completo: criar evento → gerar link → partilhar → abrir na app + web

---

## Ficheiros Relacionados

| Ficheiro | Descrição |
| -------- | --------- |
| [MIGRATIONS/LAZZO_2_0_REMOVE_GROUPS_CHAT_ADD_EVENT_INVITES.sql](MIGRATIONS/LAZZO_2_0_REMOVE_GROUPS_CHAT_ADD_EVENT_INVITES.sql) | SQL migration completa (inclui storage) |
| `LAZZO_2_0_STEP_BY_STEP_PLAN_APP_WEB_SPLIT.md` | Plano week-by-week com split App vs Web |
| [supabase_structure.sql](supabase_structure.sql) | Schema atual (pré-migration) |
| `supabase_schema_public_and_storage.sql` | Schema completo com storage (pré-migration) |
