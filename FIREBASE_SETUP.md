# FreightFlow v3.0 — Firebase & Maps Setup Guide

## Overview of New Features
| Feature | Package | Status |
|---|---|---|
| Firestore Database | `cloud_firestore` | Code ready — needs google-services.json |
| Live GPS Tracking | `geolocator` | Works out-of-box on device |
| Google Maps | `google_maps_flutter` | Needs Maps API key |
| Shimmer loading | `shimmer` | Active — no config needed |
| Animated UI | Flutter built-ins | Active — no config needed |

---

## Step 1 — Firebase Project Setup

1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Click **Add project** → name it `FreightFlow`
3. Enable **Cloud Firestore** (Start in test mode for development)
4. Go to **Project Settings → Your apps → Add Android app**
   - Package name: `com.example.freight_flow`
   - Download `google-services.json`
   - Place it at: `android/app/google-services.json`

5. In `android/build.gradle` add inside `dependencies {}`:
   ```
   classpath 'com.google.gms:google-services:4.4.2'
   ```

6. In `android/app/build.gradle` add at the bottom:
   ```
   apply plugin: 'com.google.gms.google-services'
   ```

7. Run `flutterfire configure` (install with `dart pub global activate flutterfire_cli`)

8. In `lib/main.dart`, uncomment the Firebase init block:
   ```dart
   await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,
   );
   ```

9. In `lib/app.dart`, call `enableCloud()` on each provider after login:
   ```dart
   context.read<MasterDataProvider>().enableCloud();
   context.read<BiltyProvider>().enableCloud();
   context.read<ChallanProvider>().enableCloud();
   context.read<TripManagementProvider>().enableCloud();
   ```

---

## Step 2 — Seed Firestore with Demo Data

Run this Firestore seeder once after Firebase is connected.
The `AppDataStore.seed()` already runs in-memory — to push to Firestore,
call `FirestoreService.instance` methods with the same seed objects
(or use the Firebase Console to import the JSON from `AppDataStore`).

Alternatively: the app falls back to in-memory data if Firestore is
not connected, so it remains fully functional for demo without Firebase.

---

## Step 3 — Google Maps API Key

1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Enable **Maps SDK for Android**
3. Create an API key (restrict to your Android app's SHA-1)
4. In `android/app/src/main/AndroidManifest.xml` add inside `<application>`:
   ```xml
   <meta-data
     android:name="com.google.android.geo.API_KEY"
     android:value="YOUR_API_KEY_HERE"/>
   ```

Without the key, `LiveMapWidget` shows a blank grey tile but does NOT crash.
The trip detail screen still shows all other data correctly.

---

## Step 4 — Android Permissions (already added)

`AndroidManifest.xml` already includes:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

---

## Step 5 — Run

```bash
flutter pub get
flutter run
```

Demo credentials: `admin@freightflow.in` / `admin123`

---

## Architecture Notes

### Dual-mode Providers
All providers support both **in-memory** (default) and **Firestore streaming** modes.
- Default: `AppDataStore.instance` (in-memory singleton, resets on restart)
- Cloud:   Call `.enableCloud()` on the provider to switch to Firestore real-time streams

The service layer swap is transparent to the UI — no screen code changes needed.

### GPS on State Transitions
When a trip state changes (e.g. dispatched → inTransit), `LocationService` automatically
captures the device's GPS position and stores it in the `TripStateEvent.location` field.
This is visible in the State History timeline on `TripDetailScreen`.

### Live Map
`LiveMapWidget` displays:
- Dashed polyline from origin city → destination city
- Blue pin at origin, green pin at destination  
- Orange truck marker at `trip.currentLocation` (captured at last state transition)
- "Location pending" badge if GPS not yet captured

The map appears in `TripDetailScreen` for all trips not in `godown` state.
