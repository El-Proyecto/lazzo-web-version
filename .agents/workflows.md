# Workflows

**Repository:** lazzo-web-version.

*Quick reference: feature playbook (fake-first, 6 steps), common playbooks (cards, lists, POST, DI override).*

## End-to-end feature flow (playbook)

**Goal:** new feature visible with fake data, then switch to Supabase by DI override.

1. **Scope UI**: list screens/sections; identify reusable vs feature-specific.
2. **Domain contracts**
   - Create **Entity** with minimal fields UI needs.
   - Define **Repository interface** (methods used by use cases/UI).
   - Add **Use case** (one action per class).
3. **UI**
   - Copy from Figma → create tokenized component(s) in `shared/components/`.
   - Compose screen in `features/<f>/presentation/pages/` (use shared components).
4. **State**
   - Create **providers** (Riverpod) exposing `AsyncValue` states; inject **FakeRepo** by default.
5. **Data**
   - Add **Supabase data source** in `data/data_sources/` (read/write/RPC/storage calls).
   - Add **DTO model** in `data/models/` (parse row ↔ entity).
   - Implement **Repository** in `data/repositories/` (use data source + DTO; return **entities**).
6. **DI Override**
   - In `main.dart`'s `ProviderScope(overrides: [...])`, swap `FakeRepo` → `RepoImpl(SupabaseClient)`.

**Result:** UI flips from fake to real with **no** widget changes.

## Common playbooks

- **Add a new card used in many screens** → implement in `shared/components/cards/`, then compose in pages.
- **Add a feature list (e.g., events)** → Entity + Repo interface + Use case + Provider; UI consumes provider; Data layer later wires Supabase.
- **Replace fake with real** → only DI override in `main.dart`.
- **Add write action (POST)** → Use case calling repository; repository calls data source `.insert()`/RPC; UI reads `AsyncValue` and shows success/error.
