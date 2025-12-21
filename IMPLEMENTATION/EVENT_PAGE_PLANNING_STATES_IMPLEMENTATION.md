# Event Page Planning States Implementation

## Overview
Implementar três estados diferentes na página de evento baseados na definição de data e local, melhorando o fluxo de planeamento colaborativo e tornando mais claro quando o evento pode ser confirmado.

**Contexto:** Atualmente a página de evento assume que data e local estão sempre definidos. Esta implementação adiciona lógica condicional para três casos: ambos definidos, apenas um definido, ou nenhum definido. Isto afeta RSVP, sugestões, confirmação de evento e widgets de ajuda ao planeamento.

---

## Part 1: Supabase Changes (P2 Developer)

### 1.1 Database Schema
**Status:** ✅ Schema já existe - nenhuma alteração necessária

As tabelas `events`, `location_suggestions`, `event_date_options` já suportam estes campos nullable:
- `events.location_id` (uuid nullable)
- `events.start_datetime` (timestamp nullable)
- `events.end_datetime` (timestamp nullable)

**Ação:** Nenhuma - schema atual já suporta os três estados.

---

### 1.2 RLS Policies Verification
**Status:** ⚠️ **VERIFICAR PRIMEIRO** - Executar queries abaixo antes de criar novas policies

**Step 1: Verificar Policies Existentes**

Execute estas queries para verificar se as policies necessárias já existem:

```sql
-- ============================================================================
-- VERIFICATION QUERIES - Execute estas queries para verificar policies
-- ============================================================================

-- 1. Listar TODAS as policies para event_date_options
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename = 'event_date_options'
ORDER BY policyname;

-- 2. Listar TODAS as policies para location_suggestions
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename = 'location_suggestions'
ORDER BY policyname;

-- 3. Listar TODAS as policies para event_date_votes
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename = 'event_date_votes'
ORDER BY policyname;

-- 4. Listar TODAS as policies para location_suggestion_votes
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename = 'location_suggestion_votes'
ORDER BY policyname;

-- 5. Verificar se RLS está ativado nestas tabelas
SELECT 
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN (
    'event_date_options',
    'location_suggestions', 
    'event_date_votes',
    'location_suggestion_votes'
  )
ORDER BY tablename;
```

---

**Step 2: Análise dos Resultados**

Após executar as queries acima, verificar se existem policies para:

**event_date_options:**
- [X] **SELECT** - Participantes podem ver sugestões de data
- [X] **INSERT** - Participantes podem adicionar sugestões de data
- [X] **DELETE** (opcional) - Criador pode deletar sua sugestão

**location_suggestions:**
- [X] **SELECT** - Participantes podem ver sugestões de local
- [X] **INSERT** - Participantes podem adicionar sugestões de local
- [X] **DELETE** (opcional) - Criador pode deletar sua sugestão

**event_date_votes:**
- [X] **SELECT** - Participantes podem ver votos
- [X] **INSERT** - Participantes podem votar em sugestões
- [X] **DELETE** - Participantes podem remover seu voto (toggle)

**location_suggestion_votes:**
- [X] **SELECT** - Participantes podem ver votos
- [X] **INSERT** - Participantes podem votar em sugestões
- [X] **DELETE** - Participantes podem remover seu voto (toggle)

---

**Step 3: Criar Policies em Falta (Se Necessário)**

⚠️ **APENAS executar as queries abaixo para policies que NÃO existem** (verificado no Step 1)

```sql
-- ============================================================================
-- CREATE POLICIES - Apenas se verificação mostrar que não existem
-- ============================================================================

-- ATENÇÃO: NÃO executar se policy com mesmo nome já existir!
-- Ajustar lógica da policy conforme padrões do projeto

-- ============================================================================
-- event_date_options policies
-- ============================================================================

-- Permitir participantes verem sugestões de data
CREATE POLICY "event_participants_can_view_date_suggestions"
ON event_date_options
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM event_participants ep
    WHERE ep.pevent_id = event_date_options.event_id
    AND ep.user_id = auth.uid()
  )
);

-- Permitir participantes adicionarem sugestões de data
CREATE POLICY "event_participants_can_add_date_suggestions"
ON event_date_options
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM event_participants ep
    WHERE ep.pevent_id = event_date_options.event_id
    AND ep.user_id = auth.uid()
  )
);

-- (Opcional) Permitir criador deletar sua própria sugestão
CREATE POLICY "users_can_delete_own_date_suggestions"
ON event_date_options
FOR DELETE
TO authenticated
USING (created_by = auth.uid());

-- ============================================================================
-- location_suggestions policies
-- ============================================================================

-- Permitir participantes verem sugestões de local
CREATE POLICY "event_participants_can_view_location_suggestions"
ON location_suggestions
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM event_participants ep
    WHERE ep.pevent_id = location_suggestions.event_id
    AND ep.user_id = auth.uid()
  )
);

-- Permitir participantes adicionarem sugestões de local
CREATE POLICY "event_participants_can_add_location_suggestions"
ON location_suggestions
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM event_participants ep
    WHERE ep.pevent_id = location_suggestions.event_id
    AND ep.user_id = auth.uid()
  )
);

-- (Opcional) Permitir criador deletar sua própria sugestão
CREATE POLICY "users_can_delete_own_location_suggestions"
ON location_suggestions
FOR DELETE
TO authenticated
USING (user_id = auth.uid());

-- ============================================================================
-- event_date_votes policies
-- ============================================================================

-- Permitir participantes verem votos
CREATE POLICY "event_participants_can_view_date_votes"
ON event_date_votes
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM event_participants ep
    WHERE ep.pevent_id = event_date_votes.event_id
    AND ep.user_id = auth.uid()
  )
);

-- Permitir participantes votarem
CREATE POLICY "event_participants_can_vote_on_date_suggestions"
ON event_date_votes
FOR INSERT
TO authenticated
WITH CHECK (
  user_id = auth.uid() AND
  EXISTS (
    SELECT 1 FROM event_participants ep
    WHERE ep.pevent_id = event_date_votes.event_id
    AND ep.user_id = auth.uid()
  )
);

-- Permitir participantes removerem seu próprio voto (toggle)
CREATE POLICY "users_can_remove_own_date_votes"
ON event_date_votes
FOR DELETE
TO authenticated
USING (user_id = auth.uid());

-- ============================================================================
-- location_suggestion_votes policies
-- ============================================================================

-- Permitir participantes verem votos
CREATE POLICY "event_participants_can_view_location_votes"
ON location_suggestion_votes
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM event_participants ep
    INNER JOIN location_suggestions ls ON ls.event_id = ep.pevent_id
    WHERE ls.id = location_suggestion_votes.suggestion_id
    AND ep.user_id = auth.uid()
  )
);

-- Permitir participantes votarem
CREATE POLICY "event_participants_can_vote_on_location_suggestions"
ON location_suggestion_votes
FOR INSERT
TO authenticated
WITH CHECK (
  user_id = auth.uid() AND
  EXISTS (
    SELECT 1 FROM event_participants ep
    INNER JOIN location_suggestions ls ON ls.event_id = ep.pevent_id
    WHERE ls.id = location_suggestion_votes.suggestion_id
    AND ep.user_id = auth.uid()
  )
);

-- Permitir participantes removerem seu próprio voto (toggle)
CREATE POLICY "users_can_remove_own_location_votes"
ON location_suggestion_votes
FOR DELETE
TO authenticated
USING (user_id = auth.uid());
```

---

**Step 4: Testar Policies (Após Criar as em Falta)**

Execute estes testes para verificar se as policies funcionam:

```sql
-- ============================================================================
-- TESTING - Execute como participante (não-host) do evento
-- ============================================================================

-- 1. Tentar adicionar sugestão de data (deve funcionar)
INSERT INTO event_date_options (event_id, starts_at, ends_at, created_by)
VALUES (
  '<event_id_onde_sou_participante>',
  '2025-12-20 14:00:00+00',
  '2025-12-20 16:00:00+00',
  auth.uid()
);

-- 2. Tentar ver sugestões de data (deve funcionar)
SELECT * FROM event_date_options 
WHERE event_id = '<event_id_onde_sou_participante>';

-- 3. Tentar adicionar sugestão de local (deve funcionar)
INSERT INTO location_suggestions (event_id, user_id, location_name, address)
VALUES (
  '<event_id_onde_sou_participante>',
  auth.uid(),
  'Test Location',
  'Test Address'
);

-- 4. Tentar ver sugestões de local (deve funcionar)
SELECT * FROM location_suggestions 
WHERE event_id = '<event_id_onde_sou_participante>';

-- 5. Tentar votar em sugestão de data (deve funcionar)
INSERT INTO event_date_votes (option_id, user_id, event_id)
VALUES (
  '<date_option_id>',
  auth.uid(),
  '<event_id>'
);

-- 6. Tentar votar em sugestão de local (deve funcionar)
INSERT INTO location_suggestion_votes (suggestion_id, user_id)
VALUES (
  '<location_suggestion_id>',
  auth.uid()
);
```

---

**Testing Checklist (Manual - App):**
- [X] Participante (não-host) pode adicionar sugestão de data quando `start_datetime IS NULL`
- [X] Participante (não-host) pode adicionar sugestão de local quando `location_id IS NULL`
- [X] Participante pode ver sugestões adicionadas por outros
- [X] Participante pode votar em sugestões existentes
- [X] Participante pode remover seu próprio voto (toggle)
- [X] Participante NÃO pode deletar sugestões de outros (deve falhar)
- [X] Participante NÃO pode votar em eventos onde não é participante (deve falhar)

---

### 1.3 Optional: Helper Function (Low Priority)
Função opcional para facilitar verificação do estado do evento:

```sql
-- Function to check event planning status
CREATE OR REPLACE FUNCTION get_event_planning_status(p_event_id uuid)
RETURNS TABLE (
  has_location boolean,
  has_date boolean,
  status text
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    (location_id IS NOT NULL) as has_location,
    (start_datetime IS NOT NULL) as has_date,
    CASE
      WHEN location_id IS NOT NULL AND start_datetime IS NOT NULL THEN 'both_defined'
      WHEN location_id IS NOT NULL OR start_datetime IS NOT NULL THEN 'partial_defined'
      ELSE 'none_defined'
    END as status
  FROM events
  WHERE id = p_event_id;
END;
$$;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION get_event_planning_status TO authenticated;
```

**Nota:** Esta função é **opcional** - a lógica pode ser feita no cliente (mais eficiente). Incluído apenas para referência.

---

## Part 2: Codebase Changes (Agent/P1)

### 2.1 Domain Layer

#### 2.1.1 Update Entity: `EventDetail`
**File:** `lib/features/event/domain/entities/event_detail.dart`

**Changes:**
```dart
// Add computed properties to EventDetail class

/// Check if event has both location and date defined
bool get isFullyDefined => location != null && startDateTime != null;

/// Check if event has location defined
bool get hasDefinedLocation => location != null;

/// Check if event has date defined  
bool get hasDefinedDate => startDateTime != null;

/// Planning status for UI logic
EventPlanningStatus get planningStatus {
  if (isFullyDefined) return EventPlanningStatus.bothDefined;
  if (hasDefinedLocation || hasDefinedDate) return EventPlanningStatus.partialDefined;
  return EventPlanningStatus.noneDefined;
}
```

**New Enum:**
```dart
/// Event planning status based on location and date definition
enum EventPlanningStatus {
  /// Both location and date are defined
  bothDefined,
  
  /// Only one of location or date is defined
  partialDefined,
  
  /// Neither location nor date is defined
  noneDefined,
}
```

**Why:** Encapsular lógica de verificação na entidade, seguindo DDD principles. UI apenas lê computed properties.

---

### 2.2 Shared Components Layer

#### 2.2.1 Create New Widget: `HelpPlanEventWidget`
**File:** `lib/shared/components/widgets/help_plan_event_widget.dart`

**Purpose:** Widget similar ao RSVP mas para eventos sem data/local definidos.

**Specs:**
- Similar layout ao `RSVPWidget` (mesmo padding, border radius, background)
- Título: "Help plan this event"
- Botão CTA abaixo do título
- Texto do botão dinâmico baseado no que falta:
  - "Add date and place suggestion" (nenhum definido)
  - "Add date suggestion" (só local definido)
  - "Add place suggestion" (só data definida)
- Stateless widget com callback `onPressed`

**Implementation:**
```dart
import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// Widget to encourage participants to help plan event
/// when location or date (or both) are not defined
class HelpPlanEventWidget extends StatelessWidget {
  final bool hasLocation;
  final bool hasDate;
  final VoidCallback onAddSuggestion;

  const HelpPlanEventWidget({
    super.key,
    required this.hasLocation,
    required this.hasDate,
    required this.onAddSuggestion,
  });

  String get _buttonText {
    if (!hasLocation && !hasDate) {
      return 'Add date and place suggestion';
    } else if (!hasLocation) {
      return 'Add place suggestion';
    } else {
      return 'Add date suggestion';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: Pads.cardContent,
      decoration: BoxDecoration(
        color: BrandColors.bg2,
        borderRadius: Radii.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          Text(
            'Help plan this event',
            style: AppText.titleMediumEmph.copyWith(
              color: BrandColors.text1,
            ),
          ),
          const SizedBox(height: Gaps.sm),
          
          // CTA Button
          ElevatedButton(
            onPressed: onAddSuggestion,
            style: ElevatedButton.styleFrom(
              backgroundColor: BrandColors.planning,
              foregroundColor: BrandColors.bg1,
              padding: const EdgeInsets.symmetric(
                horizontal: Insets.md,
                vertical: Insets.sm,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: Radii.button,
              ),
            ),
            child: Text(
              _buttonText,
              style: AppText.labelLarge.copyWith(
                color: BrandColors.bg1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

**Export:** Add to `lib/shared/components/components.dart`:
```dart
export 'widgets/help_plan_event_widget.dart';
```

---

#### 2.2.2 Create New Dialog: `MissingFieldsConfirmationDialog`
**File:** `lib/shared/components/dialogs/missing_fields_confirmation_dialog.dart`

**Purpose:** Dialog específico para avisar hosts que falta definir data/local antes de confirmar evento.

**Specs:**
- Usar base do `ConfirmationDialog` existente
- Título: "Cannot Confirm Event"
- Mensagem dinâmica baseada no que falta
- Apenas um botão: "Ok" (não é destructive)
- Ícone de aviso (opcional)

**Implementation:**
```dart
import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// Dialog to inform host that event cannot be confirmed
/// until all required fields (date and location) are defined
class MissingFieldsConfirmationDialog extends StatelessWidget {
  final bool hasLocation;
  final bool hasDate;

  const MissingFieldsConfirmationDialog({
    super.key,
    required this.hasLocation,
    required this.hasDate,
  });

  String get _message {
    if (!hasLocation && !hasDate) {
      return 'You need to define both date and location before confirming this event.';
    } else if (!hasLocation) {
      return 'You need to define a location before confirming this event.';
    } else {
      return 'You need to define a date before confirming this event.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: BrandColors.bg2,
      shape: RoundedRectangleBorder(
        borderRadius: Radii.dialog,
      ),
      child: Padding(
        padding: Pads.dialogContent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              'Cannot Confirm Event',
              style: AppText.titleMediumEmph.copyWith(
                color: BrandColors.text1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Gaps.sm),
            
            // Message
            Text(
              _message,
              style: AppText.bodyMedium.copyWith(
                color: BrandColors.text2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Gaps.md),
            
            // Ok Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BrandColors.planning,
                  foregroundColor: BrandColors.bg1,
                  padding: const EdgeInsets.symmetric(
                    vertical: Insets.sm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: Radii.button,
                  ),
                ),
                child: Text(
                  'Ok',
                  style: AppText.labelLarge.copyWith(
                    color: BrandColors.bg1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Export:** Add to `lib/shared/components/components.dart`:
```dart
export 'dialogs/missing_fields_confirmation_dialog.dart';
```

---

### 2.3 Presentation Layer (Feature-specific)

#### 2.3.1 Update `EventPage` Widget Logic
**File:** `lib/features/event/presentation/pages/event_page.dart`

**Changes Required:**

**A) Update `_showStatusChangeDialog` method:**
```dart
/// Show dialog to change event status
/// Now checks if event has required fields before allowing confirmation
void _showStatusChangeDialog(
  BuildContext context,
  WidgetRef ref,
  String eventId,
  EventDetail event, // Changed: now receives full event
  EventStatus currentStatus,
) {
  final isConfirmed = currentStatus == EventStatus.confirmed;

  // If trying to confirm but missing required fields, show warning dialog
  if (!isConfirmed && !event.isFullyDefined) {
    showDialog(
      context: context,
      builder: (context) => MissingFieldsConfirmationDialog(
        hasLocation: event.hasDefinedLocation,
        hasDate: event.hasDefinedDate,
      ),
    );
    return;
  }

  // Original confirmation dialog
  showDialog(
    context: context,
    builder: (context) => ConfirmationDialog(
      title: isConfirmed ? 'Unmark Event' : 'Confirm Event',
      message: isConfirmed
          ? 'Are you sure you want to unmark this event as confirmed?'
          : 'Are you sure you want to confirm this event?',
      confirmText: isConfirmed ? 'Unmark' : 'Confirm',
      cancelText: 'Cancel',
      isDestructive: isConfirmed,
      onConfirm: () async {
        final newStatus =
            isConfirmed ? EventStatus.pending : EventStatus.confirmed;

        await ref
            .read(eventStatusNotifierProvider(eventId).notifier)
            .updateStatus(eventId, newStatus);

        if (context.mounted) {
          _showStatusMessage(context, newStatus);
        }
      },
    ),
  );
}
```

**B) Update `_buildEventStatusSection` call:**
```dart
// Find the call to _showStatusChangeDialog and update to pass event
// Before:
_showStatusChangeDialog(context, ref, eventId, event.status);

// After:
_showStatusChangeDialog(context, ref, eventId, event, event.status);
```

**C) Add new method `_buildHelpPlanSection` (add near line 1000, in section builders area):**
```dart
/// Build help plan section when event has undefined fields
/// Shows instead of RSVP widget when location or date not defined
Widget _buildHelpPlanSection(EventDetail event) {
  return Column(
    children: [
      const SizedBox(height: Gaps.md),
      HelpPlanEventWidget(
        hasLocation: event.hasDefinedLocation,
        hasDate: event.hasDefinedDate,
        onAddSuggestion: () {
          // Determine initial tab based on what's missing
          // Note: User can always switch tabs in the bottom sheet
          final initialType = event.hasDefinedLocation && !event.hasDefinedDate
              ? SuggestionType.dateTime  // Missing date only
              : SuggestionType.location;  // Missing location (or both)

          // Use existing bottom sheet function
          showAddSuggestionBottomSheet(
            context,
            eventId: event.id,
            eventStartDate: event.startDateTime ?? DateTime.now(),
            eventStartTime: event.startDateTime != null
                ? TimeOfDay.fromDateTime(event.startDateTime!)
                : const TimeOfDay(hour: 12, minute: 0),
            eventEndDate: event.endDateTime ?? DateTime.now().add(const Duration(hours: 2)),
            eventEndTime: event.endDateTime != null
                ? TimeOfDay.fromDateTime(event.endDateTime!)
                : const TimeOfDay(hour: 14, minute: 0),
            type: initialType,
            currentEventLocationName: event.location?.displayName,
            currentEventAddress: event.location?.formattedAddress,
          );
        },
      ),
    ],
  );
}
```

**Note:** Uses existing `showAddSuggestionBottomSheet()` function (already in codebase).

**D) Update `_buildRsvpSection` to be conditional:**
```dart
/// Build RSVP section - only shown when event is fully defined
/// When not fully defined, shows HelpPlanSection instead
Widget _buildRsvpSection(EventDetail event, String? currentUserId) {
  // If event doesn't have both location and date, show help plan widget
  if (!event.isFullyDefined) {
    return _buildHelpPlanSection(event);
  }

  // Original RSVP widget code (keep existing implementation)
  return Consumer(
    builder: (context, ref, child) {
      // ... existing RSVP code ...
    },
  );
}
```

**E) Update suggestion widgets visibility logic:**

**Current Implementation (around line 400-480):**
```dart
// Date/Time Suggestions Widget
Consumer(
  builder: (context, ref, child) {
    final dataAsync = ref.watch(dateTimeSuggestionsDataProvider(eventId));
    
    if (!dataAsync.hasValue) {
      return const SizedBox.shrink();
    }
    
    final data = dataAsync.value!;
    final processedData = _processDateTimeSuggestions(...);
    
    // Current check: only show if there are alternatives
    if (!processedData.hasAlternatives) {
      return const SizedBox.shrink();
    }
    
    return DateTimeSuggestionsWidget(...);
  },
)
```

**Update to (preserve alternatives check for defined events):**
```dart
// Date/Time Suggestions Widget
Consumer(
  builder: (context, ref, child) {
    final dataAsync = ref.watch(dateTimeSuggestionsDataProvider(eventId));
    
    if (!dataAsync.hasValue) {
      return const SizedBox.shrink();
    }
    
    final data = dataAsync.value!;
    
    // Show widget if:
    // 1. Event has NO date defined (planning mode) - show all suggestions
    // 2. Event HAS date defined - only show if there are alternatives
    final suggestions = data['suggestions'] as List<Suggestion>;
    final shouldShow = !event.hasDefinedDate || 
                      (suggestions.isNotEmpty && 
                       _processDateTimeSuggestions(...).hasAlternatives);
    
    if (!shouldShow) {
      return const SizedBox.shrink();
    }
    
    return DateTimeSuggestionsWidget(...);
  },
)
```

**Similar logic for Location Suggestions Widget (around line 480-550):**
```dart
// Location Suggestions Widget  
Consumer(
  builder: (context, ref, child) {
    final dataAsync = ref.watch(locationSuggestionsDataProvider(eventId));
    
    if (!dataAsync.hasValue) {
      return const SizedBox.shrink();
    }
    
    final data = dataAsync.value!;
    final locationSuggestions = data['locationSuggestions'] as List<LocationSuggestion>;
    
    // Current: only shows if suggestions exist
    if (locationSuggestions.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final processedData = _processLocationSuggestions(...);
    
    // Update to: show if no location OR if there are alternatives
    final shouldShow = !event.hasDefinedLocation || processedData.hasAlternatives;
    
    if (!shouldShow) {
      return const SizedBox.shrink();
    }
    
    return LocationSuggestionsWidget(...);
  },
)
```

**Performance Note:** No additional queries - reuses existing combined providers.

**F) Add HelpPlanWidget visibility helper (add near line 1050, after _buildHelpPlanSection):**

```dart
/// Determine if HelpPlanWidget should be visible
/// Returns true if widget should be shown, false if should shrink
/// 
/// Logic:
/// - Always hidden if event is fully defined (has both date and location)
/// - If missing both: hide only when BOTH suggestion types have been added
/// - If missing one: hide only when that specific suggestion type has been added
/// 
/// Note: Uses data from combined providers (already loaded)
bool _shouldShowHelpPlanWidget(
  EventDetail event, {
  required bool hasDateSuggestions,
  required bool hasLocationSuggestions,
}) {
  // Always hide if event is fully defined
  if (event.isFullyDefined) return false;

  // If missing both fields
  if (!event.hasDefinedDate && !event.hasDefinedLocation) {
    // Only hide when BOTH suggestion types exist
    // This keeps the widget visible until both are addressed
    return !(hasDateSuggestions && hasLocationSuggestions);
  }

  // If missing only date
  if (!event.hasDefinedDate) {
    // Hide when date suggestion exists
    return !hasDateSuggestions;
  }

  // If missing only location
  if (!event.hasDefinedLocation) {
    // Hide when location suggestion exists
    return !hasLocationSuggestions;
  }

  return false;
}
```

**Usage in build method (around line 350-400):**
```dart
// Determine HelpPlan visibility using data from combined providers
final dateDataAsync = ref.watch(dateTimeSuggestionsDataProvider(eventId));
final locationDataAsync = ref.watch(locationSuggestionsDataProvider(eventId));

final hasDateSuggestions = dateDataAsync.hasValue &&
    (dateDataAsync.value!['suggestions'] as List).isNotEmpty;
final hasLocationSuggestions = locationDataAsync.hasValue &&
    (locationDataAsync.value!['locationSuggestions'] as List).isNotEmpty;

final shouldShowHelpPlan = _shouldShowHelpPlanWidget(
  event,
  hasDateSuggestions: hasDateSuggestions,
  hasLocationSuggestions: hasLocationSuggestions,
);

// Then in widget tree:
if (shouldShowHelpPlan) _buildHelpPlanSection(event),
```

**Performance Note:** Reuses data from existing combined providers - no additional queries.

---

#### 2.3.2 Bottom Sheet - No Changes Required
**File:** `lib/features/event/presentation/widgets/add_suggestion_bottom_sheet.dart`

**Status:** ✅ **Existing implementation is already correct**

**Current Behavior (Keep as-is):**
- Bottom sheet has **Tab Controller** with 2 tabs: Date/Time and Location
- Initial tab is set by `suggestionType` parameter:
  - `SuggestionType.dateTime` → opens on Date/Time tab
  - `SuggestionType.location` → opens on Location tab
- Users can **freely switch between tabs** to add suggestions of either type
- This flexibility is intentional and desired behavior

**How HelpPlanWidget will use it:**
```dart
// When missing only date:
showAddSuggestionBottomSheet(
  context,
  eventId: event.id,
  suggestionType: SuggestionType.dateTime, // Opens on Date/Time tab
  // ... other params
);

// When missing only location:
showAddSuggestionBottomSheet(
  context,
  eventId: event.id,
  suggestionType: SuggestionType.location, // Opens on Location tab
  // ... other params
);

// When missing both - default to date/time:
showAddSuggestionBottomSheet(
  context,
  eventId: event.id,
  suggestionType: SuggestionType.dateTime, // Opens on Date/Time tab
  // User can switch to Location tab if desired
  // ... other params
);
```

**Why no changes needed:**
- Current bottom sheet already handles all cases elegantly
- Tab switching allows users to add either suggestion type regardless of initial state
- Prevents need for complex "both" type or restricting user actions
- Keeps implementation simple and flexible

---

### 2.4 Integration & DI

#### 2.4.1 No Changes Required
**Reason:** All existing providers and repositories already support nullable `location` and `startDateTime`. No new data sources or repositories needed.

**Verification:**
- [ ] `eventDetailProvider` returns `EventDetail` with nullable fields ✅
- [ ] `eventSuggestionsProvider` handles empty lists ✅
- [ ] `eventLocationSuggestionsProvider` handles empty lists ✅

---

### 2.5 Optimistic UI Patterns (Leverage Existing)

**Current Implementation Already Uses Optimistic UI:**

The event page **already implements optimistic UI** in several places. **Reuse these patterns** for consistency:

#### Pattern 1: Invalidate-First for Instant Feedback
**Used in:** `_setEventDate()`, `_setEventLocation()`

```dart
// OPTIMISTIC UI: Invalidate providers FIRST for instant UI update
// Providers will refetch and show loading state immediately
ref.invalidate(eventDetailProvider(eventId));
ref.invalidate(eventSuggestionsProvider(eventId));
ref.invalidate(eventRsvpsProvider(eventId));
// ... then perform async operation
```

**Apply to:** Status change confirmation, adding suggestions

#### Pattern 2: Combined Providers for Reduced Nesting
**Used in:** `dateTimeSuggestionsDataProvider`, `locationSuggestionsDataProvider`, `chatPreviewDataProvider`

```dart
// Single provider combines multiple data sources
final dataAsync = ref.watch(combinedDataProvider(eventId));

// Access with .value even during refresh
if (dataAsync.hasValue) {
  final data = dataAsync.value!; // Works even during refresh
  // ...
}
```

**Benefits:**
- Reduces widget nesting from 4 levels to 1
- Previous data visible during refresh
- Better perceived performance

**Apply to:** HelpPlanWidget can leverage existing providers

#### Pattern 3: whenOrNull for Skeleton States
**Used in:** Participants list, polls

```dart
participantsAsync.whenOrNull(
  data: (participants) {
    // Show actual widget
    return ActualWidget(...);
  },
) ?? const SizedBox.shrink(); // Show nothing during loading
```

**Apply to:** HelpPlanWidget visibility (don't show during initial load)

#### Pattern 4: Pure Functions for Data Processing
**Used in:** `_processChatMessages()`, `_processDateTimeSuggestions()`, `_processLocationSuggestions()`

```dart
// Extract processing logic to pure function
final processedData = _processDateTimeSuggestions(
  suggestions: rawSuggestions,
  allVotes: rawVotes,
  userVoteIds: userVotes,
  event: event,
  goingCount: goingCount,
  currentUserId: currentUserId,
);

// Improves testability and performance (can memoize)
```

**Apply to:** Create `_processHelpPlanVisibility()` helper

#### Recommendations for New Changes:

**DO:**
- ✅ Use `ref.invalidate()` before async operations (status change, set date/location)
- ✅ Use `whenOrNull` for conditional rendering (HelpPlanWidget)
- ✅ Extract complex logic to pure functions (`_shouldShowHelpPlanWidget`)
- ✅ Use `hasValue` check before accessing `.value` (prevents null errors during refresh)

**DON'T:**
- ❌ Add new providers if existing ones can be reused
- ❌ Create complex nested Consumer widgets (use combined providers)
- ❌ Block UI during async operations (invalidate first, then perform operation)
- ❌ Mix business logic with widget code (extract to pure functions)

---

### 2.6 Architecture Analysis & Refactoring Suggestions

#### Current Page Structure (1549 lines)

**✅ Well-Organized Sections:**
```dart
// Lines 1-150: Imports, class definition, lifecycle methods
// Lines 150-250: Helper methods (_addToCalendar, _onScroll)
// Lines 250-400: Dialog methods (_showStatusChangeDialog, _showStatusMessage)
// Lines 400-700: Build method with Consumer widgets (optimized with combined providers)
// Lines 700-1000: Action methods (_setEventDate, _setEventLocation)
// Lines 1000-1549: Section builder methods & data processing functions
```

**✅ Current Optimizations Already Applied:**
- Combined providers (`dateTimeSuggestionsDataProvider`, `locationSuggestionsDataProvider`, `chatPreviewDataProvider`)
- Pure functions for data processing (`_processChatMessages`, `_processDateTimeSuggestions`, `_processLocationSuggestions`)
- Optimistic UI patterns (invalidate-first)
- Skeleton states with `whenOrNull`

**Performance Characteristics:**
- **Widget rebuilds:** Minimal - Riverpod providers cached, Consumer scoped
- **Network calls:** Optimized - Combined providers batch requests
- **Data processing:** Pure functions enable memoization (if needed later)
- **Scroll performance:** Good - individual Consumer widgets only rebuild their section

#### Impact Assessment of New Changes

**Additions for Planning States:**
1. `_buildHelpPlanSection()` → ~30 lines
2. Update `_buildRsvpSection()` conditional → +5 lines
3. Update `_showStatusChangeDialog()` validation → +15 lines
4. `_shouldShowHelpPlanWidget()` helper → ~30 lines
5. Update suggestion visibility logic → +10 lines

**Total:** ~90 new lines → **1639 lines** (still manageable)

#### Refactoring Decision: **NOT NEEDED for this PR**

**Reasons to keep current structure:**
1. **Page is well-organized** with clear sections and comments
2. **Performance is already optimized** (combined providers, pure functions, optimistic UI)
3. **Adding 90 lines is acceptable** - still under 2000 line threshold
4. **Premature refactoring** could break existing optimizations
5. **Current architecture follows Clean principles** (section builders, extracted helpers)

**When to refactor (future triggers):**
- Page exceeds **2000 lines**
- Adding **new major features** (e.g., polls voting, expenses split UI)
- Performance issues detected (profile first!)
- Multiple developers working on same file causing conflicts

#### Suggested Organization for New Code

**Add in existing section builder area (~line 1000-1100):**
```dart
// ═══════════════════════════════════════════════════════════════════════════
// PLANNING STATE HELPERS (NEW)
// Methods to handle conditional UI based on event planning status
// ═══════════════════════════════════════════════════════════════════════════

/// Build help plan section when event has undefined fields
Widget _buildHelpPlanSection(EventDetail event) { ... }

/// Determine if HelpPlanWidget should be visible
bool _shouldShowHelpPlanWidget(...) { ... }
```

**Benefits:**
- Maintains existing organization pattern
- Keeps related code together
- Easy to find and modify
- No structural changes to existing optimizations

**Recommendation:** **Proceed with current structure. No refactoring needed.**

---

## Acceptance Criteria

### Functional Requirements
- [ ] **Case 1 - Both Defined**: Current behavior preserved (RSVP visible, can confirm event)
- [ ] **Case 2 - Partial Defined**: 
  - [ ] HelpPlanWidget shows with correct button text
  - [ ] Clicking button opens appropriate bottom sheet (date OR location)
  - [ ] After adding suggestion, suggestion widget appears
  - [ ] HelpPlanWidget shrinks only when missing field suggestion is added
  - [ ] Hosts cannot confirm event, see MissingFieldsConfirmationDialog
  - [ ] Dialog shows correct missing field(s)
- [ ] **Case 3 - None Defined**:
  - [ ] HelpPlanWidget shows "Add date and place suggestion"
  - [ ] After adding one suggestion, button text updates to remaining field
  - [ ] HelpPlanWidget shrinks only when both suggestion widgets visible
  - [ ] Hosts cannot confirm event, see dialog mentioning both fields

### Technical Requirements  
- [ ] All new shared components use design tokens (no hardcoded colors/spacing)
- [ ] Shared components are stateless
- [ ] No Supabase calls in presentation layer
- [ ] Entity has computed properties for planning status
- [ ] RLS policies allow participants to add suggestions
- [ ] `flutter analyze` passes with no errors
- [ ] No `print()` statements in final code

### UI/UX Requirements
- [ ] HelpPlanWidget matches RSVP visual style (padding, radius, background)
- [ ] Dialog is clear and actionable
- [ ] Transitions between states are smooth (no layout jumps)
- [ ] Loading states handled gracefully
- [ ] Bottom sheet opens to correct form based on missing fields

### Testing Checklist
**Manual Testing:**
- [ ] Create event with both fields → RSVP appears, can confirm
- [ ] Create event with only date → HelpPlan appears, button says "Add place suggestion"
- [ ] Create event with only location → HelpPlan appears, button says "Add date suggestion"
- [ ] Create event with neither → HelpPlan appears, button says "Add date and place suggestion"
- [ ] Add date suggestion when missing → date widget appears, HelpPlan updates
- [ ] Add location suggestion when missing → location widget appears, HelpPlan updates
- [ ] Try to confirm incomplete event as host → see appropriate dialog
- [ ] Dialog "Ok" button dismisses dialog properly
- [ ] Participants can add suggestions (verify RLS)

**Edge Cases:**
- [ ] Event changes from partial → fully defined (through edit page)
- [ ] Suggestion deleted (does HelpPlan reappear if needed?)
- [ ] Multiple participants add suggestions simultaneously
- [ ] Offline → online transition

---

## Implementation Order

### Phase 1: Foundation (P2 Supabase + Domain) ✅ COMPLETE
**Duration:** ~30 min (Actual: 25 min)
1. [X] Verify/update RLS policies (P2) ✅
2. [X] Add computed properties to `EventDetail` entity (Agent) ✅
3. [X] Add `EventPlanningStatus` enum (Agent) ✅
4. [X] Test entity properties with various event states (Agent) ✅

**Completed Files:**
- `lib/features/event/domain/entities/event_detail.dart` - Added computed properties and enum
- `test/features/event/domain/entities/event_detail_test.dart` - Created comprehensive tests (7 passing tests)

**Test Results:**
```
✅ All 7 tests passed
✅ flutter analyze: No issues found
✅ Computed properties working correctly for all planning states
```

### Phase 2: Shared UI Components
**Duration:** ~1 hour
5. [ ] Create `HelpPlanEventWidget` in `lib/shared/components/widgets/` (Agent)
6. [ ] Create `MissingFieldsConfirmationDialog` in `lib/shared/components/dialogs/` (Agent)
7. [ ] Export both components in `components.dart` (Agent)
8. [ ] Visual test both components in isolation (Agent)

### Phase 3: Event Page Integration  
**Duration:** ~1.5 hours
9. [ ] Add `_buildHelpPlanSection()` method (~line 1000 in section builders) (Agent)
10. [ ] Add `_shouldShowHelpPlanWidget()` helper (~line 1050) (Agent)
11. [ ] Update `_showStatusChangeDialog()` with validation logic (Agent)
12. [ ] Update `_buildRsvpSection()` to be conditional (call HelpPlan when not fully defined) (Agent)
13. [ ] Update date/time suggestions visibility logic (~line 400-480) (Agent)
14. [ ] Update location suggestions visibility logic (~line 480-550) (Agent)
15. [ ] Add HelpPlanWidget visibility check in build method (~line 350) (Agent)
16. [ ] Update all method calls to pass correct parameters (Agent)
17. [ ] Add imports for new components at top of file (Agent)

### Phase 4: Testing & Refinement
**Duration:** ~1 hour
18. [ ] Run `flutter analyze` and fix any issues (Agent)
19. [ ] Manual test all 3 cases end-to-end (Agent)
20. [ ] Test as host and as participant (Agent)
21. [ ] Test bottom sheet opens on correct tab for each case (Agent)
22. [ ] Test RLS policies in dev environment (P2 + Agent)
23. [ ] Verify optimistic UI patterns work correctly (Agent)
24. [ ] Fix any edge cases discovered (Agent)

### Phase 5: Documentation & Cleanup
**Duration:** ~30 min
25. [ ] Remove any debug `print()` statements (Agent)
26. [ ] Run `./scripts/clean_prints.sh` (Agent)
27. [ ] Update any relevant comments (Agent)
28. [ ] Create PR with clear description (Agent)

**Total Estimated Time:** ~4.5 hours (reduced from 5h due to no bottom sheet changes needed)

---

## Migration Notes

### Breaking Changes
**None** - This is additive functionality. Existing events with both fields defined continue to work as before.

### Rollback Plan
If critical issues arise:
1. Revert `EventPage` changes (keep old RSVP logic)
2. Keep shared components (no harm if unused)
3. Domain entity changes are safe (just unused properties)

### Performance Considerations
- **No additional queries** - uses existing event data
- **Computed properties** are simple null checks (O(1))
- **Conditional rendering** may reduce widget count in some cases (better performance)

---

## Post-Implementation Improvements (Future)

### High Priority
- [ ] Add analytics tracking for planning vs confirmed events
- [ ] Add notification when missing field gets first suggestion
- [ ] Improve bottom sheet UX for "both" type (step-by-step?)

### Medium Priority
- [ ] Extract event page sections into separate view widgets (refactor)
- [ ] Add tooltip explaining why confirm button is disabled
- [ ] Add "quick confirm" flow if only 1 suggestion for each field

### Low Priority  
- [ ] Add RPC function for atomic "suggest and vote" operation
- [ ] Consider materialized view for event planning status
- [ ] A/B test different CTA button copy

---

## Questions & Decisions Log

**Q: Should HelpPlanWidget shrink immediately when ANY suggestion is added?**  
**A:** No. Only shrink when the MISSING field gets a suggestion. This keeps the widget visible as a reminder.

**Q: Can participants (non-hosts) add suggestions?**  
**A:** Yes. RLS policies must allow INSERT for participants. This encourages collaborative planning.

**Q: Should we allow confirming event with suggestions but no final date/location?**  
**A:** No. Event must have both fields explicitly set. Suggestions are proposals, not final decisions.

**Q: What if host tries to confirm before ANY suggestions exist?**  
**A:** Same dialog appears. Dialog doesn't mention suggestions, only that date/location need to be defined.

**Q: Should we add loading state to HelpPlanWidget button?**  
**A:** Not in MVP. Bottom sheet opening is instant. Can add if users report issues.

---

## References

**Related Files:**
- Entity: `lib/features/event/domain/entities/event_detail.dart`
- Page: `lib/features/event/presentation/pages/event_page.dart` (1549 lines)
- Bottom Sheet: `lib/features/event/presentation/widgets/add_suggestion_bottom_sheet.dart`
- Existing RSVP Widget: `lib/shared/components/widgets/rsvp_widget.dart`
- Existing Dialog: `lib/shared/components/dialogs/confirmation_dialog.dart`

**Database Tables:**
- `events` (location_id, start_datetime nullable)
- `location_suggestions` (for location suggestions)
- `event_date_options` (for date suggestions)
- `location_suggestion_votes` (for voting)
- `event_date_votes` (for voting)

**Architecture Docs:**
- `agents.md` - Section 17 (Implementation files)
- `README.md` - Feature development flow
- `supabase_structure.sql` - Database schema reference

---

## Sign-off

**P1 (UI/Planning):** _[Agent completing this implementation]_  
**P2 (Backend):** _[To verify RLS policies]_  
**QA:** _[To test all acceptance criteria]_

**Implementation Start Date:** _[TBD]_  
**Target Completion Date:** _[TBD]_  
**Status:** 📋 Ready for Implementation
