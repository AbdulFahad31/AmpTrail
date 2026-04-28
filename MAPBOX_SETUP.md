
# Mapbox Setup Instructions for AmpTrail

To make the map work, you need a Mapbox Account and Access Tokens.

## 1. Get Your Tokens
1. Go to [mapbox.com](https://www.mapbox.com/) and Sign Up/Log In.
2. Go to your **Account Dashboard**.
3. Copy your **Default Public Token** (starts with `pk...`).
4. Click **Create a token** to create a **Secret Scope Token**.
   - Check `Downloads:Read` scope.
   - Create it and Copy it (starts with `sk...`).

## 2. Configure Android
1. Open `android/app/build.gradle`.
2. Find the code, usually at the bottom or top level (NOT inside `android {}` block), and ensure your secret token is configured if using the download token method, OR simpler method:

**Easiest Way for Android (Public Token):**
Open `android/app/src/main/AndroidManifest.xml` and add this inside the `<application>` tag:
```xml
<meta-data
    android:name="com.mapbox.token"
    android:value="PASTE_YOUR_PUBLIC_KEY_HERE" />
```

**For the Secret Token (Required for downloading the SDK):**
Open `android/gradle.properties` (if it doesn't exist, create it in `android/` folder) and add:
```properties
MAPBOX_DOWNLOADS_TOKEN=PASTE_YOUR_SECRET_SK_TOKEN_HERE
```

## 3. Configure iOS
Open `ios/Runner/Info.plist` and add:
```xml
<key>MBXAccessToken</key>
<string>PASTE_YOUR_PUBLIC_KEY_HERE</string>
```

## 4. Restart
After adding these keys, run:
```bash
flutter clean
flutter run
```
