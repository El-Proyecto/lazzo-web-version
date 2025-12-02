# Settings P2 Implementation Guide — Backend & Supabase

**Role:** P2 (Backend Developer)  
**Scope:** Implement Supabase data layer for Settings, Report a Problem, and Share a Suggestion features  
**Exclusions:** Privacy Policy, Terms & Conditions, FAQ, Invite Friend to Group

---

## Overview

This guide provides complete P2 implementation steps for the Settings feature and associated pages (Report a Problem, Share a Suggestion). The Settings feature is already functional with logout/delete account working via Supabase Auth. This P2 phase adds:

1. **User Settings Storage** — Persistent notification preferences and language selection
2. **Problem Reports** — Store and track user-reported issues
3. **Suggestions** — Store and track user feature suggestions

**Current Status:**
- ✅ P1 Complete: UI, Domain entities, Repository interfaces, Providers (fake data)
- ✅ Logout/Delete Account: Working with Supabase Auth
- ⚠️ Pending: Settings persistence, Report/Suggestion storage

---

## Database Schema Changes

### Required Tables

You need to create **3 new tables** in Supabase:

1. `user_settings` — User preferences (notifications, language)
2. `problem_reports` — User-reported problems
3. `user_suggestions` — User feature suggestions

---

### 1. Table: `user_settings`

**Purpose:** Store per-user notification and language preferences.

**SQL to Execute in Supabase:**

```sql
-- Create user_settings table
CREATE TABLE IF NOT EXISTS public.user_settings (
  user_id uuid NOT NULL,
  notifications_enabled boolean NOT NULL DEFAULT true,
  language text NOT NULL DEFAULT 'en' CHECK (language IN ('en', 'pt')),
  early_access_invites integer NOT NULL DEFAULT 3,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  
  CONSTRAINT user_settings_pkey PRIMARY KEY (user_id),
  CONSTRAINT user_settings_user_id_fkey FOREIGN KEY (user_id) 
    REFERENCES public.users(id) ON DELETE CASCADE
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_user_settings_user_id ON public.user_settings(user_id);

-- Trigger to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_user_settings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_user_settings_updated_at
  BEFORE UPDATE ON public.user_settings
  FOR EACH ROW
  EXECUTE FUNCTION update_user_settings_updated_at();

-- Trigger to auto-create settings for new users
CREATE OR REPLACE FUNCTION create_user_settings_for_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_settings (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_create_user_settings
  AFTER INSERT ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION create_user_settings_for_new_user();
```

**RLS Policies:**

```sql
-- Enable RLS
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;

-- Users can read their own settings
CREATE POLICY "Users can read own settings"
  ON public.user_settings
  FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own settings
CREATE POLICY "Users can insert own settings"
  ON public.user_settings
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own settings
CREATE POLICY "Users can update own settings"
  ON public.user_settings
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own settings (handled by CASCADE on user deletion)
CREATE POLICY "Users can delete own settings"
  ON public.user_settings
  FOR DELETE
  USING (auth.uid() = user_id);
```

**Notes:**
- `user_id` is the primary key (one settings row per user)
- Auto-creates default settings when user signs up
- `early_access_invites` tracks remaining invite count (starts at 3)
- Cascade deletes when user account is deleted

---

### 2. Table: `problem_reports`

**Purpose:** Store user-reported bugs and issues during beta.

**SQL to Execute in Supabase:**

```sql
-- Create custom enum for report status
CREATE TYPE public.report_status AS ENUM ('pending', 'in_review', 'resolved');

-- Create problem_reports table
CREATE TABLE IF NOT EXISTS public.problem_reports (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  category text NOT NULL,
  description text NOT NULL CHECK (char_length(description) >= 10 AND char_length(description) <= 500),
  status public.report_status NOT NULL DEFAULT 'pending',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  
  CONSTRAINT problem_reports_pkey PRIMARY KEY (id),
  CONSTRAINT problem_reports_user_id_fkey FOREIGN KEY (user_id) 
    REFERENCES public.users(id) ON DELETE CASCADE,
  CONSTRAINT problem_reports_category_check CHECK (
    category IN (
      'Sign up / Login',
      'Create or join event',
      'Upload photos & memories',
      'Share memories',
      'Payments & expenses',
      'Notifications',
      'Other'
    )
  )
);

-- Create indexes for filtering and sorting
CREATE INDEX IF NOT EXISTS idx_problem_reports_user_id ON public.problem_reports(user_id);
CREATE INDEX IF NOT EXISTS idx_problem_reports_status ON public.problem_reports(status);
CREATE INDEX IF NOT EXISTS idx_problem_reports_created_at ON public.problem_reports(created_at DESC);

-- Trigger to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_problem_reports_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_problem_reports_updated_at
  BEFORE UPDATE ON public.problem_reports
  FOR EACH ROW
  EXECUTE FUNCTION update_problem_reports_updated_at();
```

**RLS Policies:**

```sql
-- Enable RLS
ALTER TABLE public.problem_reports ENABLE ROW LEVEL SECURITY;

-- Users can read their own reports
CREATE POLICY "Users can read own reports"
  ON public.problem_reports
  FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own reports
CREATE POLICY "Users can insert own reports"
  ON public.problem_reports
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users cannot update reports after submission (admin-only operation)
-- Admin updates would need service_role key or separate admin policies

-- Users cannot delete reports (admin-only operation)
-- Reports are kept for tracking purposes
```

**Notes:**
- Category is validated at DB level (matches UI options)
- Description has min 10 chars, max 500 chars
- Users can only insert reports, not update/delete them
- Admin dashboard (future) can update status to track resolution

---

### 3. Table: `user_suggestions`

**Purpose:** Store user feature suggestions and ideas during beta.

**SQL to Execute in Supabase:**

```sql
-- Create custom enum for suggestion status
CREATE TYPE public.suggestion_status AS ENUM ('pending', 'in_review', 'implemented', 'declined');

-- Create user_suggestions table
CREATE TABLE IF NOT EXISTS public.user_suggestions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  description text NOT NULL CHECK (char_length(description) >= 10 AND char_length(description) <= 500),
  status public.suggestion_status NOT NULL DEFAULT 'pending',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  
  CONSTRAINT user_suggestions_pkey PRIMARY KEY (id),
  CONSTRAINT user_suggestions_user_id_fkey FOREIGN KEY (user_id) 
    REFERENCES public.users(id) ON DELETE CASCADE
);

-- Create indexes for filtering and sorting
CREATE INDEX IF NOT EXISTS idx_user_suggestions_user_id ON public.user_suggestions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_suggestions_status ON public.user_suggestions(status);
CREATE INDEX IF NOT EXISTS idx_user_suggestions_created_at ON public.user_suggestions(created_at DESC);

-- Trigger to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_user_suggestions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_user_suggestions_updated_at
  BEFORE UPDATE ON public.user_suggestions
  FOR EACH ROW
  EXECUTE FUNCTION update_user_suggestions_updated_at();
```

**RLS Policies:**

```sql
-- Enable RLS
ALTER TABLE public.user_suggestions ENABLE ROW LEVEL SECURITY;

-- Users can read their own suggestions
CREATE POLICY "Users can read own suggestions"
  ON public.user_suggestions
  FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own suggestions
CREATE POLICY "Users can insert own suggestions"
  ON public.user_suggestions
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users cannot update suggestions after submission (admin-only operation)
-- Admin dashboard (future) can update status to track implementation

-- Users cannot delete suggestions (admin-only operation)
-- Suggestions are kept for product roadmap planning
```

**Notes:**
- No category field (unlike reports)
- Description has min 10 chars, max 500 chars
- Users can only insert suggestions, not update/delete them
- Status includes 'implemented' and 'declined' for future admin tracking

---

## Verification Queries

After creating tables, verify with these queries:

```sql
-- Check tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('user_settings', 'problem_reports', 'user_suggestions');

-- Check RLS is enabled
SELECT tablename, rowsecurity FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('user_settings', 'problem_reports', 'user_suggestions');

-- Check policies exist
SELECT schemaname, tablename, policyname FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('user_settings', 'problem_reports', 'user_suggestions');

-- Test insert (replace with actual user ID)
INSERT INTO user_settings (user_id) VALUES ('your-user-id-here');
```

---

## Code Implementation Tasks

### Task 1: Settings Data Source

**File:** `lib/features/settings/data/data_sources/settings_remote_data_source.dart`

**Changes Required:**

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsRemoteDataSource {
  final SupabaseClient _client;

  SettingsRemoteDataSource(this._client);

  /// Get current user settings from user_settings table
  Future<Map<String, dynamic>> getSettings() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Get settings from user_settings table
    final response = await _client
        .from('user_settings')
        .select('notifications_enabled, language, early_access_invites')
        .eq('user_id', userId)
        .single();

    return response;
  }

  /// Update notification preferences
  Future<void> updateNotifications(bool enabled) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    await _client
        .from('user_settings')
        .update({'notifications_enabled': enabled})
        .eq('user_id', userId);
  }

  /// Update language preference
  Future<void> updateLanguage(String language) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    await _client
        .from('user_settings')
        .update({'language': language})
        .eq('user_id', userId);
  }

  /// Share early access invite (decrement counter)
  Future<void> shareInvite() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Get current invite count
    final response = await _client
        .from('user_settings')
        .select('early_access_invites')
        .eq('user_id', userId)
        .single();

    final currentInvites = response['early_access_invites'] as int;
    
    if (currentInvites <= 0) {
      throw Exception('No invites remaining');
    }

    // Decrement invite count
    await _client
        .from('user_settings')
        .update({'early_access_invites': currentInvites - 1})
        .eq('user_id', userId);
  }

  /// Log out current user
  Future<void> logOut() async {
    await _client.auth.signOut();
  }

  /// Delete current user account (cascades to user_settings)
  Future<void> deleteAccount() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Delete user from users table (cascades to all related data)
    await _client.from('users').delete().eq('id', userId);

    // Sign out after deletion
    await _client.auth.signOut();
  }
}
```

**Key Changes:**
- Replace TODO comments with actual Supabase queries
- `getSettings()` reads from `user_settings` table
- `updateNotifications()` and `updateLanguage()` update `user_settings`
- `shareInvite()` decrements `early_access_invites` counter
- Keep `logOut()` and `deleteAccount()` as-is (already working)

---

### Task 2: Settings Model (DTO)

**File:** `lib/features/settings/data/models/settings_model.dart`

**Changes Required:**

```dart
import '../../domain/entities/settings_entity.dart';

class SettingsModel {
  final bool notificationsEnabled;
  final String language;
  final int earlyAccessInvites;

  const SettingsModel({
    required this.notificationsEnabled,
    required this.language,
    required this.earlyAccessInvites,
  });

  /// Create from Supabase JSON response
  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      language: json['language'] as String? ?? 'en',
      earlyAccessInvites: json['early_access_invites'] as int? ?? 3,
    );
  }

  /// Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'notifications_enabled': notificationsEnabled,
      'language': language,
      'early_access_invites': earlyAccessInvites,
    };
  }

  /// Convert to domain entity
  SettingsEntity toEntity() {
    return SettingsEntity(
      notificationsEnabled: notificationsEnabled,
      language: language,
      earlyAccessInvites: earlyAccessInvites,
    );
  }

  /// Create from domain entity
  factory SettingsModel.fromEntity(SettingsEntity entity) {
    return SettingsModel(
      notificationsEnabled: entity.notificationsEnabled,
      language: entity.language,
      earlyAccessInvites: entity.earlyAccessInvites,
    );
  }
}
```

**Key Points:**
- Maps Supabase snake_case to Dart camelCase
- Provides defaults for null values
- Converts between DTO and Entity

---

### Task 3: Settings Repository Implementation

**File:** `lib/features/settings/data/repositories/settings_repository_impl.dart`

**Update Required:**

The file already exists and is mostly correct. Update the `getSettings()` method to parse using `SettingsModel`:

```dart
@override
Future<SettingsEntity> getSettings() async {
  try {
    final json = await _dataSource.getSettings();
    final model = SettingsModel.fromJson(json);
    return model.toEntity();
  } catch (e) {
    throw Exception('Failed to load settings: $e');
  }
}
```

**All other methods remain unchanged** (they already work correctly).

---

### Task 4: Report Problem Data Source

**File:** `lib/features/settings/data/data_sources/report_remote_data_source.dart` *(create new file)*

**Full Implementation:**

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source for problem reports
class ReportRemoteDataSource {
  final SupabaseClient _client;

  ReportRemoteDataSource(this._client);

  /// Submit a problem report to Supabase
  Future<void> submitReport({
    required String category,
    required String description,
    required String userId,
  }) async {
    await _client.from('problem_reports').insert({
      'user_id': userId,
      'category': category,
      'description': description,
      'status': 'pending',
    });
  }

  /// Get user's submitted reports (optional - for future "My Reports" page)
  Future<List<Map<String, dynamic>>> getUserReports() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final response = await _client
        .from('problem_reports')
        .select('id, category, description, status, created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);

    return List<Map<String, dynamic>>.from(response);
  }
}
```

---

### Task 5: Report Model (DTO)

**File:** `lib/features/settings/data/models/report_model.dart` *(create new file)*

**Full Implementation:**

```dart
import '../../domain/entities/report_entity.dart';

class ReportModel {
  final String? id;
  final String category;
  final String description;
  final String userId;
  final DateTime createdAt;
  final String status;

  const ReportModel({
    this.id,
    required this.category,
    required this.description,
    required this.userId,
    required this.createdAt,
    required this.status,
  });

  /// Create from Supabase JSON response
  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] as String?,
      category: json['category'] as String,
      description: json['description'] as String,
      userId: json['user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      status: json['status'] as String? ?? 'pending',
    );
  }

  /// Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'category': category,
      'description': description,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'status': status,
    };
  }

  /// Convert to domain entity
  ReportEntity toEntity() {
    return ReportEntity(
      id: id,
      category: category,
      description: description,
      userId: userId,
      createdAt: createdAt,
      status: status,
    );
  }

  /// Create from domain entity
  factory ReportModel.fromEntity(ReportEntity entity) {
    return ReportModel(
      id: entity.id,
      category: entity.category,
      description: entity.description,
      userId: entity.userId,
      createdAt: entity.createdAt,
      status: entity.status,
    );
  }
}
```

---

### Task 6: Report Repository Implementation

**File:** `lib/features/settings/data/repositories/report_repository_impl.dart` *(create new file)*

**Full Implementation:**

```dart
import '../../domain/entities/report_entity.dart';
import '../../domain/repositories/report_repository.dart';
import '../data_sources/report_remote_data_source.dart';
import '../models/report_model.dart';

/// Implementation of ReportRepository using Supabase
class ReportRepositoryImpl implements ReportRepository {
  final ReportRemoteDataSource _dataSource;

  ReportRepositoryImpl(this._dataSource);

  @override
  Future<void> submitReport(ReportEntity report) async {
    try {
      await _dataSource.submitReport(
        category: report.category,
        description: report.description,
        userId: report.userId,
      );
    } catch (e) {
      throw Exception('Failed to submit report: $e');
    }
  }

  /// Optional: Get user's submitted reports
  Future<List<ReportEntity>> getUserReports() async {
    try {
      final jsonList = await _dataSource.getUserReports();
      return jsonList.map((json) => ReportModel.fromJson(json).toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to load reports: $e');
    }
  }
}
```

---

### Task 7: Suggestion Data Source

**File:** `lib/features/settings/data/data_sources/suggestion_remote_data_source.dart` *(create new file)*

**Full Implementation:**

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source for user suggestions
class SuggestionRemoteDataSource {
  final SupabaseClient _client;

  SuggestionRemoteDataSource(this._client);

  /// Submit a suggestion to Supabase
  Future<void> submitSuggestion({
    required String description,
    required String userId,
  }) async {
    await _client.from('user_suggestions').insert({
      'user_id': userId,
      'description': description,
      'status': 'pending',
    });
  }

  /// Get user's submitted suggestions (optional - for future "My Suggestions" page)
  Future<List<Map<String, dynamic>>> getUserSuggestions() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final response = await _client
        .from('user_suggestions')
        .select('id, description, status, created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);

    return List<Map<String, dynamic>>.from(response);
  }
}
```

---

### Task 8: Suggestion Model (DTO)

**File:** `lib/features/settings/data/models/suggestion_model.dart` *(create new file)*

**Full Implementation:**

```dart
import '../../domain/entities/suggestion_entity.dart';

class SuggestionModel {
  final String? id;
  final String description;
  final String userId;
  final DateTime createdAt;
  final String status;

  const SuggestionModel({
    this.id,
    required this.description,
    required this.userId,
    required this.createdAt,
    required this.status,
  });

  /// Create from Supabase JSON response
  factory SuggestionModel.fromJson(Map<String, dynamic> json) {
    return SuggestionModel(
      id: json['id'] as String?,
      description: json['description'] as String,
      userId: json['user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      status: json['status'] as String? ?? 'pending',
    );
  }

  /// Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'description': description,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'status': status,
    };
  }

  /// Convert to domain entity
  SuggestionEntity toEntity() {
    return SuggestionEntity(
      id: id,
      description: description,
      userId: userId,
      createdAt: createdAt,
      status: status,
    );
  }

  /// Create from domain entity
  factory SuggestionModel.fromEntity(SuggestionEntity entity) {
    return SuggestionModel(
      id: entity.id,
      description: entity.description,
      userId: entity.userId,
      createdAt: entity.createdAt,
      status: entity.status,
    );
  }
}
```

---

### Task 9: Suggestion Repository Implementation

**File:** `lib/features/settings/data/repositories/suggestion_repository_impl.dart` *(create new file)*

**Full Implementation:**

```dart
import '../../domain/entities/suggestion_entity.dart';
import '../../domain/repositories/suggestion_repository.dart';
import '../data_sources/suggestion_remote_data_source.dart';
import '../models/suggestion_model.dart';

/// Implementation of SuggestionRepository using Supabase
class SuggestionRepositoryImpl implements SuggestionRepository {
  final SuggestionRemoteDataSource _dataSource;

  SuggestionRepositoryImpl(this._dataSource);

  @override
  Future<void> submitSuggestion(SuggestionEntity suggestion) async {
    try {
      await _dataSource.submitSuggestion(
        description: suggestion.description,
        userId: suggestion.userId,
      );
    } catch (e) {
      throw Exception('Failed to submit suggestion: $e');
    }
  }

  /// Optional: Get user's submitted suggestions
  Future<List<SuggestionEntity>> getUserSuggestions() async {
    try {
      final jsonList = await _dataSource.getUserSuggestions();
      return jsonList.map((json) => SuggestionModel.fromJson(json).toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to load suggestions: $e');
    }
  }
}
```

---

### Task 10: Dependency Injection (DI) Override

**File:** `lib/main.dart`

**Changes Required:**

Update the `ProviderScope` overrides to replace fake repositories with real implementations:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
// ... other imports

// Import Settings data layer
import 'features/settings/data/data_sources/settings_remote_data_source.dart';
import 'features/settings/data/repositories/settings_repository_impl.dart';
import 'features/settings/presentation/providers/settings_providers.dart';

// Import Report data layer
import 'features/settings/data/data_sources/report_remote_data_source.dart';
import 'features/settings/data/repositories/report_repository_impl.dart';
import 'features/settings/presentation/providers/report_providers.dart';

// Import Suggestion data layer
import 'features/settings/data/data_sources/suggestion_remote_data_source.dart';
import 'features/settings/data/repositories/suggestion_repository_impl.dart';
import 'features/settings/presentation/providers/suggestion_providers.dart';

void main() async {
  // ... existing initialization

  runApp(
    ProviderScope(
      overrides: [
        // ... existing overrides
        
        // Settings repository override
        settingsRepositoryProvider.overrideWith((ref) {
          return SettingsRepositoryImpl(
            SettingsRemoteDataSource(Supabase.instance.client),
          );
        }),
        
        // Report repository override
        reportRepositoryProvider.overrideWith((ref) {
          return ReportRepositoryImpl(
            ReportRemoteDataSource(Supabase.instance.client),
          );
        }),
        
        // Suggestion repository override
        suggestionRepositoryProvider.overrideWith((ref) {
          return SuggestionRepositoryImpl(
            SuggestionRemoteDataSource(Supabase.instance.client),
          );
        }),
      ],
      child: const MyApp(),
    ),
  );
}
```

**Note:** The Settings repository override may already exist (for logout/delete). If so, just verify it's using the correct implementation.

---

## Testing Checklist

After implementing all changes:

### 1. Settings Persistence
- [ ] Open Settings page (should load from `user_settings` table)
- [ ] Toggle notifications → reload app → verify state persists
- [ ] Change language → reload app → verify language persists
- [ ] Click "Share Invite" → verify invite count decrements

### 2. Report a Problem
- [ ] Navigate to Report a Problem
- [ ] Select category and enter description
- [ ] Submit report → verify success banner
- [ ] Check Supabase table: `SELECT * FROM problem_reports ORDER BY created_at DESC LIMIT 1;`
- [ ] Verify report appears with correct category, description, status='pending'

### 3. Share a Suggestion
- [ ] Navigate to Share a Suggestion
- [ ] Enter description (no category)
- [ ] Submit suggestion → verify success banner
- [ ] Check Supabase table: `SELECT * FROM user_suggestions ORDER BY created_at DESC LIMIT 1;`
- [ ] Verify suggestion appears with correct description, status='pending'

### 4. Account Operations
- [ ] Test logout → verify redirects to login
- [ ] Test delete account → verify:
  - User row deleted from `users` table
  - `user_settings` deleted (CASCADE)
  - All `problem_reports` deleted (CASCADE)
  - All `user_suggestions` deleted (CASCADE)
  - Redirects to login

### 5. Error Handling
- [ ] Try submitting report with empty description → verify validation
- [ ] Try submitting suggestion with empty description → verify validation
- [ ] Test offline mode → verify appropriate error messages
- [ ] Test with unauthenticated user → verify error handling

---

## Performance Considerations

### Indexes (already in SQL above)
- `user_settings.user_id` — Fast user lookup
- `problem_reports.user_id` — Fast user report queries
- `problem_reports.status` — Admin filtering by status
- `problem_reports.created_at DESC` — Recent reports first
- `user_suggestions.user_id` — Fast user suggestion queries
- `user_suggestions.status` — Admin filtering by status
- `user_suggestions.created_at DESC` — Recent suggestions first

### Query Optimization
- All queries use `LIMIT` to prevent full table scans
- Foreign keys have `ON DELETE CASCADE` for efficient cleanup
- Minimal column selection (never `SELECT *`)
- Single-row lookups use `.single()` instead of `.limit(1)`

### Caching Strategy
- Settings cached in Riverpod provider (refresh on app start)
- Reports/suggestions not cached (infrequent writes)
- Consider offline-first with local SQLite for settings if needed

---

## Security & RLS Verification

### Test RLS Policies
```sql
-- Set session to test user
SET ROLE authenticated;
SET request.jwt.claims.sub = 'test-user-id-here';

-- Test SELECT (should only see own settings)
SELECT * FROM user_settings;

-- Test INSERT (should only insert for self)
INSERT INTO user_settings (user_id, notifications_enabled) 
VALUES ('test-user-id-here', true);

-- Test UPDATE (should only update own settings)
UPDATE user_settings SET language = 'pt' WHERE user_id = 'test-user-id-here';

-- Reset role
RESET ROLE;
```

### Common RLS Issues
- **"new row violates row-level security"** → Check INSERT policy `WITH CHECK` clause
- **"no rows returned"** → Verify user is authenticated and `auth.uid()` matches
- **"permission denied"** → Check table RLS is enabled and policies exist

---

## Admin Dashboard (Future Consideration)

For production, consider building an admin dashboard to:
- View all `problem_reports` (aggregate by category, status)
- Update report status (`pending` → `in_review` → `resolved`)
- View all `user_suggestions` (prioritize by count/status)
- Mark suggestions as `implemented` or `declined`
- Analytics: reports per week, most common categories, suggestion trends

**Implementation Note:** Use Supabase service_role key for admin queries (bypasses RLS).

---

## Rollback Plan

If issues arise, rollback in reverse order:

1. Remove DI overrides in `main.dart` (reverts to fake repos)
2. Drop tables (preserves data if you want to inspect):
   ```sql
   DROP TABLE IF EXISTS public.user_suggestions CASCADE;
   DROP TABLE IF EXISTS public.problem_reports CASCADE;
   DROP TABLE IF EXISTS public.user_settings CASCADE;
   DROP TYPE IF EXISTS public.suggestion_status;
   DROP TYPE IF EXISTS public.report_status;
   ```

---

## Summary

**Database Changes (Execute in Supabase):**
1. Create `user_settings` table + RLS policies + triggers
2. Create `problem_reports` table + enum + RLS policies + triggers
3. Create `user_suggestions` table + enum + RLS policies + triggers

**Code Changes (Implement in Codebase):**
1. Update `settings_remote_data_source.dart` (replace TODOs)
2. Update `settings_model.dart` (already done, verify)
3. Update `settings_repository_impl.dart` (minor change to `getSettings()`)
4. Create `report_remote_data_source.dart`
5. Create `report_model.dart`
6. Create `report_repository_impl.dart`
7. Create `suggestion_remote_data_source.dart`
8. Create `suggestion_model.dart`
9. Create `suggestion_repository_impl.dart`
10. Update `main.dart` (add/update DI overrides)

**Result:** Complete P2 implementation for Settings, Report a Problem, and Share a Suggestion with full Supabase integration, RLS security, and production-ready error handling.

---

**Questions or Issues?** Refer to:
- `agents.md` — Architecture guidelines
- `README.md` — Feature development flow
- `SUPABASE_DATABASE_STRUCTURE.md` — Database patterns and examples
- Supabase Docs: https://supabase.com/docs
