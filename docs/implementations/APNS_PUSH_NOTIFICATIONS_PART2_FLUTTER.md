# iOS Push Notifications via APNs - Part 2: Flutter Implementation

**Audience:** Agent / P1 Developer  
**Status:** 🔴 Not Started  
**Last Updated:** 13 Jan 2026  
**Depends On:** Part 1 (Backend Setup) must be completed first

---

## Overview

Implement iOS push notification handling in Flutter app using APNs device tokens. This guide covers token registration, notification handling, deep link navigation, and UI updates.

### Prerequisites
✅ Part 1 completed (database, APNs config, Edge Functions)  
✅ App has iOS entitlements configured  
✅ Provisioning profile includes Push Notifications capability  
✅ Deep linking already implemented (see `DEEP_LINKING_README.md`)

---

## Architecture Overview

```
┌────────────────────────────────────────────────────────────────┐
│                   FLUTTER PUSH FLOW                             │
├────────────────────────────────────────────────────────────────┤
│  1. App launches → request notification permissions            │
│  2. iOS provides APNs device token (64 hex chars)              │
│  3. Flutter sends token to Supabase (user_push_tokens table)   │
│  4. Token refresh listener updates DB automatically            │
│  5. App receives push in 3 states:                             │
│     - Foreground: Show in-app banner                           │
│     - Background: iOS shows notification banner                │
│     - Terminated: iOS shows banner, launch on tap              │
│  6. User taps notification → extract deeplink                  │
│  7. Navigate using AppRouter (existing implementation)         │
│  8. Update badge count from unread notifications               │
└────────────────────────────────────────────────────────────────┘
```

---

## Part 1: Add Dependencies

### 1.1 Update `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.0.0 # Already present
  flutter_riverpod: ^2.5.0 # Already present
  
  # Add for iOS push notifications
  flutter_local_notifications: ^17.0.0
  permission_handler: ^11.0.0
```

**Run:**
```bash
flutter pub get
```

---

### 1.2 iOS Configuration

**File:** `ios/Runner/Info.plist`

Add notification permission descriptions:

```xml
<key>NSUserNotificationUsageDescription</key>
<string>We need notification permission to alert you about events, messages, and group invites.</string>
```

**File:** `ios/Runner/Runner.entitlements`

Ensure Push Notifications capability is enabled:

```xml
<key>aps-environment</key>
<string>development</string> <!-- Change to 'production' for TestFlight/App Store -->
```

**Xcode Configuration:**
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner target → Signing & Capabilities
3. Enable "Push Notifications" capability
4. Enable "Background Modes" → Check "Remote notifications"

---

## Part 2: Create Push Service

### 2.1 Push Notification Service

**File:** `lib/services/push_notification_service.dart`

```dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service to handle iOS APNs push notifications
/// Manages token registration, notification handling, and deep linking
class PushNotificationService {
  final SupabaseClient _supabase;
  final FlutterLocalNotificationsPlugin _localNotifications;
  
  String? _currentToken;
  bool _isInitialized = false;

  PushNotificationService(this._supabase)
      : _localNotifications = FlutterLocalNotificationsPlugin();

  /// Initialize push notifications (call from main.dart after Supabase init)
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Only iOS supported for now
    if (!Platform.isIOS) {
      debugPrint('[PushService] Not iOS, skipping initialization');
      return;
    }

    try {
      debugPrint('[PushService] Initializing...');

      // 1) Request permissions
      final granted = await _requestPermissions();
      if (!granted) {
        debugPrint('[PushService] Permissions denied');
        return;
      }

      // 2) Configure local notifications (for foreground handling)
      await _configureLocalNotifications();

      // 3) Get APNs token
      final token = await _getAPNsToken();
      if (token == null) {
        debugPrint('[PushService] Failed to get APNs token');
        return;
      }

      // 4) Register token in Supabase
      await _registerToken(token);

      // 5) Listen for token refresh (iOS can change tokens)
      _listenForTokenRefresh();

      _isInitialized = true;
      debugPrint('[PushService] Initialization complete');
    } catch (e) {
      debugPrint('[PushService] Initialization error: $e');
    }
  }

  /// Request notification permissions from user
  Future<bool> _requestPermissions() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Configure local notifications for foreground display
  Future<void> _configureLocalNotifications() async {
    const initSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: null,
    );

    const initSettings = InitializationSettings(
      iOS: initSettingsIOS,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );
  }

  /// Get APNs device token from iOS
  Future<String?> _getAPNsToken() async {
    // Note: This requires platform channels or a package that exposes APNs token
    // Option 1: Use firebase_messaging (just for token, don't use FCM)
    // Option 2: Create custom platform channel
    // Option 3: Wait for flutter_local_notifications to support it
    
    // TODO: Implement APNs token retrieval
    // For now, using firebase_messaging as it's the easiest way to get iOS token
    // See implementation below
    
    return null; // Placeholder
  }

  /// Register device token in Supabase
  Future<void> _registerToken(String token) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('[PushService] No authenticated user');
        return;
      }

      // Determine environment based on build mode
      final environment = kDebugMode ? 'sandbox' : 'production';

      // Get device info (optional but helpful)
      final deviceName = 'iOS Device'; // TODO: Get from device_info_plus
      final appVersion = '1.0.0'; // TODO: Get from package_info_plus

      // Insert or update token in Supabase
      await _supabase.from('user_push_tokens').upsert({
        'user_id': userId,
        'device_token': token,
        'platform': 'ios',
        'environment': environment,
        'device_name': deviceName,
        'app_version': appVersion,
        'is_active': true,
        'last_used_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'device_token,platform');

      _currentToken = token;
      debugPrint('[PushService] Token registered: ${token.substring(0, 16)}...');
    } catch (e) {
      debugPrint('[PushService] Token registration error: $e');
    }
  }

  /// Listen for token refresh events
  void _listenForTokenRefresh() {
    // APNs tokens can change when:
    // - App is reinstalled
    // - Device is restored
    // - User changes Apple ID
    
    // TODO: Implement token refresh listener
    // This requires a package that exposes token changes
  }

  /// Handle notification tap (deep link navigation)
  void _handleNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    debugPrint('[PushService] Notification tapped: $payload');

    // Payload should be deeplink (e.g., 'lazzo://events/event-id')
    // Navigate using existing deep link handler
    // This should integrate with your AppRouter
    
    // TODO: Integrate with existing deep link handler from DEEP_LINKING_README.md
  }

  /// Handle foreground notification (show in-app banner)
  Future<void> handleForegroundNotification(Map<String, dynamic> message) async {
    debugPrint('[PushService] Foreground notification: $message');

    // Extract notification data
    final title = message['aps']?['alert']?['title'] ?? 'Notification';
    final body = message['aps']?['alert']?['body'] ?? '';
    final deeplink = message['deeplink'] ?? '';

    // Show local notification (appears as banner even in foreground)
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: deeplink,
    );
  }

  /// Update badge count based on unread notifications
  Future<void> updateBadgeCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Count unread push notifications
      final response = await _supabase
          .from('notifications')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('recipient_user_id', userId)
          .eq('is_read', false)
          .eq('category', 'push');

      final count = response.count ?? 0;

      // Update iOS badge (requires platform channel)
      // TODO: Implement badge count update
      debugPrint('[PushService] Badge count: $count');
    } catch (e) {
      debugPrint('[PushService] Badge count error: $e');
    }
  }

  /// Unregister token on logout
  Future<void> unregisterToken() async {
    if (_currentToken == null) return;

    try {
      await _supabase
          .from('user_push_tokens')
          .update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()})
          .eq('device_token', _currentToken!)
          .eq('platform', 'ios');

      debugPrint('[PushService] Token unregistered');
      _currentToken = null;
    } catch (e) {
      debugPrint('[PushService] Token unregister error: $e');
    }
  }
}
```

---

### 2.2 Alternative: Using firebase_messaging for APNs Token Only

**Why:** `firebase_messaging` is the easiest way to get APNs token in Flutter, even without using FCM.

**File:** `lib/services/push_notification_service_fcm.dart`

```dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Push service using firebase_messaging ONLY for APNs token retrieval
/// We DO NOT use FCM for message delivery - APNs handles that directly
class PushNotificationService {
  final SupabaseClient _supabase;
  final FirebaseMessaging _firebaseMessaging;

  String? _currentToken;

  PushNotificationService(this._supabase)
      : _firebaseMessaging = FirebaseMessaging.instance;

  /// Initialize push notifications
  Future<void> initialize() async {
    if (!Platform.isIOS) return;

    try {
      // 1) Request permissions
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        debugPrint('[PushService] Permissions denied');
        return;
      }

      // 2) Get APNs token via Firebase Messaging
      // This is the actual APNs device token, not FCM token
      final token = await _firebaseMessaging.getAPNSToken();
      
      if (token == null) {
        debugPrint('[PushService] APNs token not available yet, waiting...');
        // Sometimes token isn't immediately available, listen for it
        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          debugPrint('[PushService] APNs token received: ${newToken.substring(0, 16)}...');
          _registerToken(newToken);
        });
        return;
      }

      // 3) Register token
      await _registerToken(token);

      // 4) Listen for token changes
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        debugPrint('[PushService] APNs token refreshed');
        _registerToken(newToken);
      });

      // 5) Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[PushService] Foreground message: ${message.notification?.title}');
        _handleForegroundMessage(message);
      });

      // 6) Handle notification tap (background/terminated)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[PushService] Notification tapped (background)');
        _handleNotificationTap(message);
      });

      // 7) Handle notification tap (terminated)
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('[PushService] Notification tapped (terminated)');
        _handleNotificationTap(initialMessage);
      }

      debugPrint('[PushService] Initialization complete');
    } catch (e) {
      debugPrint('[PushService] Initialization error: $e');
    }
  }

  /// Register APNs token in Supabase
  Future<void> _registerToken(String token) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final environment = kDebugMode ? 'sandbox' : 'production';

      await _supabase.from('user_push_tokens').upsert({
        'user_id': userId,
        'device_token': token,
        'platform': 'ios',
        'environment': environment,
        'is_active': true,
        'last_used_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'device_token,platform');

      _currentToken = token;
      debugPrint('[PushService] Token registered successfully');
    } catch (e) {
      debugPrint('[PushService] Token registration error: $e');
    }
  }

  /// Handle foreground message (show in-app notification)
  void _handleForegroundMessage(RemoteMessage message) {
    final title = message.notification?.title ?? 'Notification';
    final body = message.notification?.body ?? '';
    
    // Show in-app notification UI (use your existing design)
    // Or ignore and let user see in inbox
  }

  /// Handle notification tap (deep link navigation)
  void _handleNotificationTap(RemoteMessage message) {
    final deeplink = message.data['deeplink'] as String?;
    if (deeplink == null || deeplink.isEmpty) return;

    debugPrint('[PushService] Navigating to: $deeplink');
    
    // Integrate with existing deep link handler
    // See DEEP_LINKING_README.md for navigation logic
    // Example: AppRouter.navigateToDeepLink(deeplink);
  }

  /// Unregister token on logout
  Future<void> unregisterToken() async {
    if (_currentToken == null) return;

    try {
      await _supabase
          .from('user_push_tokens')
          .update({'is_active': false})
          .eq('device_token', _currentToken!)
          .eq('platform', 'ios');

      _currentToken = null;
      debugPrint('[PushService] Token unregistered');
    } catch (e) {
      debugPrint('[PushService] Unregister error: $e');
    }
  }
}
```

**Add to pubspec.yaml:**
```yaml
dependencies:
  firebase_messaging: ^14.7.0
```

**iOS Configuration:**
```bash
cd ios && pod install
```

---

## Part 3: Integrate with App Lifecycle

### 3.1 Initialize in `main.dart`

**File:** `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/push_notification_service.dart'; // Or push_notification_service_fcm.dart

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase (already exists)
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );

  // Initialize Push Notifications
  final pushService = PushNotificationService(Supabase.instance.client);
  await pushService.initialize();

  runApp(
    ProviderScope(
      overrides: [
        // Add push service provider
        pushNotificationServiceProvider.overrideWithValue(pushService),
        // ... existing overrides
      ],
      child: const LazzoApp(),
    ),
  );
}

// Provider for PushNotificationService
final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  throw UnimplementedError('PushNotificationService must be overridden in main()');
});
```

---

### 3.2 Handle Auth State Changes

**Update auth listener to register/unregister token:**

```dart
// In your auth provider or main.dart
Supabase.instance.client.auth.onAuthStateChange.listen((data) {
  final event = data.event;
  final session = data.session;

  if (event == AuthChangeEvent.signedIn && session != null) {
    // User logged in → register token
    final pushService = ref.read(pushNotificationServiceProvider);
    pushService.initialize();
  } else if (event == AuthChangeEvent.signedOut) {
    // User logged out → unregister token
    final pushService = ref.read(pushNotificationServiceProvider);
    pushService.unregisterToken();
  }
});
```

---

## Part 4: Deep Link Integration

### 4.1 Connect to Existing Deep Link Handler

**File:** `lib/app.dart` (or wherever your deep link handler lives)

```dart
import 'package:app_links/app_links.dart';

class LazzoApp extends ConsumerStatefulWidget {
  // ... existing code

  @override
  void initState() {
    super.initState();
    _handleDeepLinks();
  }

  void _handleDeepLinks() {
    final appLinks = AppLinks();

    // Handle initial deep link (app opened from notification)
    appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _navigateToDeepLink(uri);
      }
    });

    // Handle deep links while app is running
    appLinks.uriLinkStream.listen((uri) {
      _navigateToDeepLink(uri);
    });
  }

  void _navigateToDeepLink(Uri uri) {
    // Parse lazzo://events/event-id or lazzo://groups/group-id
    debugPrint('[DeepLink] Navigating to: $uri');

    if (uri.scheme != 'lazzo') return;

    final path = uri.path;
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();

    if (segments.isEmpty) return;

    // Route based on path
    switch (segments[0]) {
      case 'events':
        if (segments.length > 1) {
          final eventId = segments[1];
          Navigator.pushNamed(context, '/event-detail', arguments: eventId);
        }
        break;
      case 'groups':
        if (segments.length > 1) {
          final groupId = segments[1];
          Navigator.pushNamed(context, '/group-hub', arguments: groupId);
        }
        break;
      case 'settings':
        Navigator.pushNamed(context, '/settings');
        break;
      default:
        debugPrint('[DeepLink] Unknown path: $path');
    }
  }
}
```

**Deeplink patterns from `notification_service.dart`:**
- `lazzo://groups/{groupId}` → Group Hub
- `lazzo://events/{eventId}` → Event Detail
- `lazzo://events/{eventId}/expenses` → Event Expenses
- `lazzo://events/{eventId}/chat` → Event Chat
- `lazzo://events/{eventId}/upload` → Photo Upload
- `lazzo://events/{eventId}/memory` → Memory Viewer
- `lazzo://events/{eventId}/planning` → Event Planning
- `lazzo://settings/security` → Security Settings

---

## Part 5: UI Updates

### 5.1 Badge Count Management

**Update badge when notifications change:**

```dart
// In your notifications provider
final notificationsProvider = StreamProvider<List<NotificationEntity>>((ref) {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return Stream.value([]);

  return Supabase.instance.client
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('recipient_user_id', userId)
      .order('created_at', ascending: false)
      .map((data) => data.map((json) => NotificationEntity.fromJson(json)).toList());
});

// Listen to changes and update badge
class NotificationsBadgeListener extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(notificationsProvider, (previous, next) {
      final unreadCount = next.value?.where((n) => !n.isRead && n.category == 'push').length ?? 0;
      final pushService = ref.read(pushNotificationServiceProvider);
      pushService.updateBadgeCount();
    });

    return const SizedBox.shrink();
  }
}
```

---

### 5.2 In-App Notification Banner (Optional)

**Show custom banner for foreground notifications:**

```dart
import 'package:flutter/material.dart';

/// Custom in-app notification banner (appears at top of screen)
class NotificationBanner extends StatelessWidget {
  final String title;
  final String body;
  final VoidCallback onTap;

  const NotificationBanner({
    required this.title,
    required this.body,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: BrandColors.cardBg,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.notifications, color: BrandColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.labelMediumEmph),
                    Text(body, style: AppText.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show banner at top of screen
  static void show(BuildContext context, String title, String body, VoidCallback onTap) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 0,
        right: 0,
        child: NotificationBanner(title: title, body: body, onTap: onTap),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto-remove after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      overlayEntry.remove();
    });
  }
}
```

**Usage in PushNotificationService:**
```dart
void _handleForegroundMessage(RemoteMessage message) {
  final title = message.notification?.title ?? 'Notification';
  final body = message.notification?.body ?? '';
  final deeplink = message.data['deeplink'] as String?;

  NotificationBanner.show(
    navigatorKey.currentContext!,
    title,
    body,
    () {
      if (deeplink != null) {
        _handleNotificationTap(message);
      }
    },
  );
}
```

---

## Part 6: Testing Checklist

### 6.1 Permissions ✅
- [ ] App requests notification permission on first launch
- [ ] Permission dialog shows custom description from Info.plist
- [ ] User can grant/deny permission
- [ ] App handles denied permission gracefully

### 6.2 Token Registration ✅
- [ ] App gets APNs token after permission granted
- [ ] Token is sent to Supabase (`user_push_tokens` table)
- [ ] Token has correct `environment` ('sandbox' for debug, 'production' for TestFlight)
- [ ] Multiple devices register separate tokens for same user
- [ ] Token refreshes automatically if it changes

### 6.3 Push Reception ✅
- [ ] **Foreground:** Notification banner appears while app is open
- [ ] **Background:** iOS shows notification in Notification Center
- [ ] **Terminated:** iOS shows notification, app launches on tap
- [ ] Notification contains correct title, body, and emoji
- [ ] Sound plays when notification arrives (if not in silent mode)

### 6.4 Deep Link Navigation ✅
- [ ] Tapping notification navigates to correct screen
- [ ] `lazzo://events/{id}` opens Event Detail
- [ ] `lazzo://groups/{id}` opens Group Hub
- [ ] `lazzo://events/{id}/chat` opens Event Chat
- [ ] Navigation works from terminated state
- [ ] Navigation works from background state

### 6.5 Badge Count ✅
- [ ] Badge shows unread push notification count
- [ ] Badge updates when new notification arrives
- [ ] Badge decreases when notification marked as read
- [ ] Badge clears when all notifications read

### 6.6 Logout ✅
- [ ] Token marked inactive on logout
- [ ] No push notifications received after logout
- [ ] Token re-registers on login

---

## Part 7: End-to-End Test Scenarios

### Scenario 1: Group Invite
1. User A invites User B to group
2. `NotificationService.sendGroupInvite()` creates notification
3. Push sent to User B's devices
4. User B taps → navigates to Group Hub
5. User B accepts invite → notification marked read

### Scenario 2: Event Starts Soon
1. Scheduled job runs 15 min before event
2. Notification created for all participants
3. Push sent to all active tokens
4. Users tap → navigate to Event Detail
5. Badge count shows +1 until marked read

### Scenario 3: Multiple Devices
1. User logs in on iPhone and iPad
2. Both tokens registered in `user_push_tokens`
3. Group invite notification created
4. Push sent to both devices simultaneously
5. User taps on iPhone → both notifications marked read

### Scenario 4: Token Refresh
1. User reinstalls app
2. APNs provides new token
3. Old token marked inactive automatically
4. New token registered
5. Push notifications continue working

### Scenario 5: Foreground Notification
1. User is browsing app
2. Notification arrives
3. In-app banner appears at top
4. User taps banner → navigates to deeplink
5. Banner auto-dismisses after 4 seconds if not tapped

---

## Part 8: Troubleshooting

### Issue: Token not received
**Symptoms:** `getAPNSToken()` returns null  
**Solutions:**
- Ensure "Push Notifications" capability enabled in Xcode
- Check provisioning profile includes Push entitlement
- Verify `aps-environment` in entitlements file
- Wait a few seconds after permission grant (token is async)

### Issue: Push not received
**Symptoms:** Notification created in DB but no push on device  
**Solutions:**
- Check Edge Function logs for errors
- Verify APNs credentials (Key ID, Team ID, Auth Key)
- Ensure token has correct `environment` (sandbox vs production)
- Check iOS device has internet connection
- Verify user_push_tokens.is_active = true

### Issue: Deep link doesn't work
**Symptoms:** Notification received but tap does nothing  
**Solutions:**
- Verify deeplink included in notification payload
- Check AppRouter handles the deeplink pattern
- Ensure app_links package is configured correctly
- Test deeplink manually: `xcrun simctl openurl booted "lazzo://events/test-id"`

### Issue: Duplicate notifications
**Symptoms:** Same notification appears multiple times  
**Solutions:**
- Check dedup_bucket in notifications table
- Verify dedup_key is correct
- Ensure Edge Function only sends once per token

---

## Part 9: Performance Optimization

### 9.1 Token Registration Debouncing

```dart
// Prevent excessive token updates
Timer? _tokenUpdateTimer;

void _registerToken(String token) {
  _tokenUpdateTimer?.cancel();
  _tokenUpdateTimer = Timer(const Duration(seconds: 2), () async {
    await _doRegisterToken(token);
  });
}
```

### 9.2 Batch Badge Updates

```dart
// Update badge max once per second
Timer? _badgeUpdateTimer;

void updateBadgeCount() {
  _badgeUpdateTimer?.cancel();
  _badgeUpdateTimer = Timer(const Duration(seconds: 1), () async {
    await _doUpdateBadgeCount();
  });
}
```

### 9.3 Cache Token Locally

```dart
import 'package:shared_preferences/shared_preferences.dart';

// Avoid re-registering same token
Future<void> _registerToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  final lastToken = prefs.getString('last_apns_token');
  
  if (lastToken == token) {
    debugPrint('[PushService] Token unchanged, skipping registration');
    return;
  }
  
  await _doRegisterToken(token);
  await prefs.setString('last_apns_token', token);
}
```

---

## Part 10: Migration from Firebase (if needed)

If app previously used Firebase for push:

### 10.1 Remove Firebase Dependencies

```bash
# Remove from pubspec.yaml
# - firebase_core
# - firebase_messaging

flutter pub get
cd ios && pod install
```

### 10.2 Remove Firebase Configuration

```bash
rm ios/Runner/GoogleService-Info.plist
rm ios/firebase_app_id_file.json
```

### 10.3 Keep APNs Token Retrieval

**Option 1:** Keep firebase_messaging ONLY for token (recommended)  
**Option 2:** Implement custom platform channel for APNs token

---

## Summary

After completing Part 2:
- ✅ Flutter app can receive push notifications via APNs
- ✅ Device tokens registered in Supabase
- ✅ Deep link navigation working
- ✅ Badge count managed automatically
- ✅ Foreground/background/terminated states handled
- ✅ Multi-device support working
- ✅ Token cleanup on logout

**Total Implementation Time (Agent):** ~2-3 hours

**Testing Time:** ~1 hour

**Next Steps:**
1. Test all notification types from `notification_service.dart`
2. Verify deep links for all screens
3. Test on real TestFlight device (not simulator)
4. Monitor Edge Function logs for errors
5. Collect user feedback on notification delivery

---

## Reference Links

- **APNs Documentation:** https://developer.apple.com/documentation/usernotifications
- **firebase_messaging Package:** https://pub.dev/packages/firebase_messaging
- **flutter_local_notifications:** https://pub.dev/packages/flutter_local_notifications
- **app_links Package:** https://pub.dev/packages/app_links
- **Deep Linking Setup:** `DEEP_LINKING_README.md` in project root
- **Notification Service:** `lib/services/notification_service.dart`
- **Supabase Edge Functions:** https://supabase.com/docs/guides/functions
