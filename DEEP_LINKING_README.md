Deep Links / Universal Links / App Links

Purpose
- Explain required native configuration so web invite links `https://<invites-domain>/i/<token>` open the app when installed, else open the landing page.

What to add on the domain
1) iOS (apple-app-site-association)
- Add file at: `https://<invites-domain>/.well-known/apple-app-site-association`
- Example content (no extension, serve as application/json):

```
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAMID.com.yourcompany.yourapp",
        "paths": ["/i/*", "/invite/*"]
      }
    ]
  }
}
```

Notes: replace `TEAMID.com.yourcompany.yourapp` with your Apple Team ID + bundle identifier.

2) Android (assetlinks.json)
- Add file at: `https://<invites-domain>/.well-known/assetlinks.json`
- Example content:

```
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.yourcompany.yourapp",
      "sha256_cert_fingerprints": [
        "AA:BB:...:ZZ"
      ]
    }
  }
]
```

Notes: replace `package_name` and provide the SHA-256 fingerprint(s) of your app signing certificate(s).

What to change in the app
1) iOS
- In Xcode, enable Associated Domains capability and add an entry:
  applinks:<invites-domain>

2) Android
- In `android/app/src/main/AndroidManifest.xml`, ensure your `activity` has an intent-filter similar to:

```xml
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="https" android:host="<invites-domain>" android:pathPrefix="/i" />
</intent-filter>
```

3) Flutter code
- We use `app_links` to detect incoming app links. The code in `lib/app.dart` subscribes to `AppLinks` stream and handles initial app link. On receiving `https://<invites-domain>/i/<token>` the app will call `AcceptGroupInviteByToken` and navigate to the group hub.

Testing
- iOS simulator: Universal Links require a real device and a valid AASA on the domain.
- Android: you can test with `adb shell am start -a android.intent.action.VIEW -d "https://<invites-domain>/i/<token>" com.yourcompany.yourapp`

Security
- Serve the `apple-app-site-association` and `assetlinks.json` files over HTTPS without redirects.

If you want, I can generate exact snippets replacing `yourcompany` and `yourapp` with values you provide (bundle id, Android package name, Apple Team ID, and SHA256 fingerprint).