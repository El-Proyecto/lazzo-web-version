# Fase 5 — Guião de Implementação (Restante)

> **Contexto:** Fase 5 = remover todas as referências a `groupId` / `groupName` / `group_id` / `group_name` do codebase.  
> Já foram limpos: entities, models/DTOs, data sources principais, repos, use cases, providers, e a maioria das pages/widgets.  
> Restam **37 ficheiros** com referências — organizados em **10 passos** abaixo.

---

## Passo 1 — Storage pipeline: renomear `groupId` → `eventId`
> **Tipo:** Rename de parâmetro (não remover — é usado no path de storage)  
> **Impacto:** O storage path atual é `$groupId/$eventId/$userId/$file`. Como groups já não existem, `groupId` passa a ser redundante com `eventId`. Renomear param para clareza.

| # | Ficheiro | Alteração |
|---|----------|-----------|
| 1.1 | `services/storage_service.dart` | Renomear param `groupId` → `eventId` em `uploadMemoryPhoto()` e `deleteMemoryPhoto()`. Atualizar path e docs. |
| 1.2 | `features/event/data/data_sources/event_photo_data_source.dart` | Remover param `groupId` de `uploadPhoto()`. Usar `eventId` no storage path: `$eventId/$userId/$timestamp.ext`. Atualizar docs. |
| 1.3 | `features/event/data/repositories/event_photo_repository_impl.dart` | Remover param `groupId` de `uploadPhoto()`. Remover `groupId: groupId` na chamada ao data source. |
| 1.4 | `features/event/domain/repositories/event_photo_repository.dart` | Remover param `groupId` da interface `uploadPhoto()`. Atualizar docs. |
| 1.5 | `features/event/domain/usecases/upload_event_photo.dart` | Remover param `groupId` de `call()`. Remover validação `groupId.isEmpty`. |
| 1.6 | `features/event/presentation/providers/event_photo_providers.dart` | Remover param `groupId` de `takePhoto()`, `pickPhotoFromGallery()`, `_uploadPhoto()`. |
| 1.7 | `features/event/presentation/pages/event_living_page.dart` | Remover `groupId: event.id` da chamada `takePhoto()`. |
| 1.8 | `features/memory/data/data_sources/memory_photo_data_source.dart` | Renomear param `groupId` → `eventId` em `uploadPhoto()`. Passar `eventId` ao `storageService.uploadMemoryPhoto()`. |
| 1.9 | `features/memory/presentation/providers/manage_memory_providers.dart` | Remover `final groupId = eventId;`. Passar `eventId` diretamente ao data source. |
| 1.10 | `features/memory/presentation/pages/manage_memory_page.dart` | Remover `groupId: event.id` das chamadas `takePhoto()` e `pickPhotoFromGallery()`. |
| 1.11 | `shared/layouts/main_layout.dart` | Remover `groupId: eventDetail.id` da chamada `takePhoto()`. Remover comment sobre "groupId". |
| 1.12 | `shared/utils/image_compression_service.dart` | Renomear param `groupId` → `eventId` em `generateTempFileName()`. |

---

## Passo 2 — Inbox: Action entity + pipeline
> **Tipo:** Remover campo `groupId` da entity, interface, use case, fakes

| # | Ficheiro | Alteração |
|---|----------|-----------|
| 2.1 | `features/inbox/domain/entities/action.dart` | Remover campo `groupId`, param no construtor, e no `copyWith()`. |
| 2.2 | `features/inbox/domain/repositories/action_repository.dart` | Remover param `groupId` de `getActions()`. |
| 2.3 | `features/inbox/domain/usecases/get_user_actions.dart` | Remover param `groupId` de `call()` e da chamada ao repo. |
| 2.4 | `features/inbox/data/fakes/fake_action_repository.dart` | Remover `groupId` de todos os fake data items. Remover filtro por `groupId` em `getActions()`. |

---

## Passo 3 — Inbox: Payment pipeline
> **Tipo:** Remover param `groupId` das interfaces e fakes

| # | Ficheiro | Alteração |
|---|----------|-----------|
| 3.1 | `features/inbox/domain/repositories/payment_repository.dart` | Remover param `groupId` de `getPayments()`. |
| 3.2 | `features/inbox/domain/usecases/get_user_payments.dart` | Remover param `groupId` de `call()` e da chamada ao repo. |
| 3.3 | `features/inbox/data/repositories/payment_repository_impl.dart` | Remover param `groupId` de `getPayments()`. |
| 3.4 | `features/inbox/data/fakes/fake_payment_repository.dart` | Remover `groupId` de todos os fake data items. Remover filtro por `groupId` em `getPayments()`. |

---

## Passo 4 — Notification: remover método morto `createNotification()`
> **Tipo:** Remover código morto (chama RPC `create_notification_if_not_duplicate` que NÃO existe na DB)

| # | Ficheiro | Alteração |
|---|----------|-----------|
| 4.1 | `features/inbox/data/data_sources/notification_remote_data_source.dart` | Apagar método `createNotification()` inteiro (~linhas 125-188). |

---

## Passo 5 — Create Event: remover `getEventsForGroup` (código morto)
> **Tipo:** Remover método e provider sem consumers

| # | Ficheiro | Alteração |
|---|----------|-----------|
| 5.1 | `features/create_event/domain/repositories/event_repository.dart` | Remover `getEventsForGroup(String groupId)` da interface. |
| 5.2 | `features/create_event/data/repositories/event_repository_impl.dart` | Remover implementação de `getEventsForGroup()`. |
| 5.3 | `features/create_event/data/fakes/fake_event_repository.dart` | Remover `getEventsForGroup()` e referências a `groupId`/`groupName` nos fake events e history. |
| 5.4 | `features/create_event/presentation/providers/event_providers.dart` | Remover `eventsForGroupProvider`. |

---

## Passo 6 — Event fakes: remover `groupId`/`groupName`
> **Tipo:** Limpar fake data que ainda referencia campos removidos das entities

| # | Ficheiro | Alteração |
|---|----------|-----------|
| 6.1 | `features/event/data/fakes/fake_event_repository.dart` | Remover todas as refs a `groupId`/`groupName` (~12 ocorrências). |
| 6.2 | `features/home/data/fakes/fake_home_event_repository.dart` | Remover `groupId`/`groupName` dos fake HomeEvent (~8 ocorrências). |
| 6.3 | `features/home/data/fakes/fake_todo_repository.dart` | Remover `groupName` dos fake TodoEntity (~4 ocorrências). |

---

## Passo 7 — EventDraft + EventGroupSelector: limpar sistema de seleção de grupo
> **Tipo:** Remover campo `selectedGroup` do draft e eliminar/esvaziar widget de seleção de grupo

| # | Ficheiro | Alteração |
|---|----------|-----------|
| 7.1 | `shared/models/event_draft.dart` | Remover campo `selectedGroup`, import de `GroupInfo`, e todas as refs em `toJson`/`fromJson`/`copyWith`/`isNotEmpty`/`isGroupValid`. |
| 7.2 | `features/create_event/presentation/widgets/event_group_selector.dart` | Widget inteiro vai ser eliminado (ou esvaziado). |
| 7.3 | `features/create_event/presentation/widgets/group_selection_dialog.dart` | Ficheiro morto — importa `EventGroupSelector`. Eliminar. |
| 7.4 | `features/create_event/presentation/pages/create_event_page.dart` | Remover import de `event_group_selector.dart`. Remover widget `EventGroupSelector()`. |
| 7.5 | `features/create_event/presentation/pages/edit_event_page.dart` | Remover import de `event_group_selector.dart`. Remover widget `EventGroupSelector()`. Remover `_groupError`, `selectedGroup: null`. |
| 7.6 | `features/create_event/presentation/widgets/confirm_event_dialog.dart` | Remover import de `event_group_selector.dart`. |

---

## Passo 8 — UI: todo_card
> **Tipo:** Substituir referência a `groupName` por `eventName`

| # | Ficheiro | Alteração |
|---|----------|-----------|
| 8.1 | `shared/components/cards/todo_card.dart` | Trocar `todo.groupName` por `todo.eventName` (ou campo equivalente). Trocar ícone `Icons.people` por `Icons.event`. |

---

## Passo 9 — Eliminar ficheiros mortos
> **Tipo:** Delete — ficheiros sem imports no codebase

| # | Ficheiro | Motivo |
|---|----------|--------|
| 9.1 | `services/notification_service_old.dart` | 0 imports — dead file |
| 9.2 | `shared/components/chips/group_chip.dart` | 0 imports ativos (só 1 comment) — dead file |
| 9.3 | `features/profile/presentation/widgets/invite_to_group_bottom_sheet.dart` | 0 imports — dead file |
| 9.4 | `features/create_event/presentation/widgets/event_group_selector.dart` | Após passo 7 — 0 imports |
| 9.5 | `features/create_event/presentation/widgets/group_selection_dialog.dart` | Após passo 7 — 0 imports |

---

## Passo 10 — Verificação final
> **Tipo:** Validação de que tudo foi limpo

```bash
# Deve retornar 0 resultados (exceto group_invites que é funcionalidade ativa):
grep -rn "groupId\|groupName\|group_id\|group_name" lib/ --include="*.dart" | grep -v "group_invite"

# Compilação sem erros:
cd /Users/monteiro/projects/app/lazzo-web-version && flutter analyze

# Build:
flutter build apk --debug 2>&1 | tail -5
```

---

## Resumo de Impacto

| Passo | Ficheiros | Tipo |
|-------|-----------|------|
| 1 | 12 ficheiros | Rename param (storage) |
| 2 | 4 ficheiros | Remover campo entity |
| 3 | 4 ficheiros | Remover param interface |
| 4 | 1 ficheiro | Remover método morto |
| 5 | 4 ficheiros | Remover método morto |
| 6 | 3 ficheiros | Limpar fakes |
| 7 | 6 ficheiros | Remover draft field + widgets |
| 8 | 1 ficheiro | UI fix |
| 9 | 5 ficheiros | Delete |
| 10 | — | Verificação |
| **Total** | **~40 ficheiros** | |
