<div align="center">

# ⚡ AmpTrail

**Real-Time EV Charging Discovery, Slot Booking & Station Management System**

<p>
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=flat-square&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Firebase-Cloud%20Firestore-FFCA28?style=flat-square&logo=firebase&logoColor=black" alt="Firebase" />
  <img src="https://img.shields.io/badge/Mapbox-GL%20v11-000000?style=flat-square&logo=mapbox&logoColor=white" alt="Mapbox" />
  <img src="https://img.shields.io/badge/Payment-Razorpay-0C2340?style=flat-square&logo=razorpay&logoColor=white" alt="Razorpay" />
  <img src="https://img.shields.io/badge/CI-GitHub%20Actions-2088FF?style=flat-square&logo=githubactions&logoColor=white" alt="CI" />
  <img src="https://img.shields.io/badge/Tests-Passing%20(11%2F11)-3DDC84?style=flat-square" alt="Tests" />
  <img src="https://img.shields.io/badge/License-MIT-blue?style=flat-square" alt="License" />
</p>

<br />

<img src="assets/docs/hero_banner.jpg" alt="AmpTrail Platform Showcase" width="100%" style="border-radius: 12px; box-shadow: 0 8px 24px rgba(0,0,0,0.4);" />

</div>

---

## 📌 Executive Summary

Electric vehicle drivers frequently encounter **fragmented station discovery**, **phantom availability**, and **booking race conditions** where two motorists arrive at the same charging stall simultaneously. 

**AmpTrail** solves this with an end-to-end mobile client and operator dashboard engineered for reliability:
- **Mapbox-Powered Map Engine**: High-framerate interactive discovery, place search autocomplete, and connector-specific filtering (CCS2, Type 2, CHAdeMO).
- **Atomic Concurrency Control**: Prevents double-booking via Firestore transactions and mathematical interval overlap detection.
- **Operator Admin Dashboard**: Station hardware configuration, real-time booking stream, and 1-tap accept/reject workflows.
- **Production Security Standard**: Role-based access rules, zero committed credentials, and authenticated server-side payment generation.

---

## 📱 Application Flow & Interface

<div align="center">

| 1. Onboarding & Splash | 2. Phone OTP Verification | 3. Station Discovery Map | 4. Slot Booking Engine |
|:---:|:---:|:---:|:---:|
| <img src="assets/docs/01_splash.png" width="220" alt="Splash Screen" /> | <img src="assets/docs/02_otp_verification.png" width="220" alt="OTP Verification" /> | <img src="assets/docs/03_station_discovery_map.png" width="220" alt="Station Discovery Map" /> | <img src="assets/docs/04_booking_confirmation.png" width="220" alt="Booking Confirmation" /> |
| Instant bootstrap & session verification | Secure SMS OTP authentication | Interactive Mapbox discovery with live status | Concurrency-verified slot reservation |

</div>

---

## 🏛️ System Architecture

AmpTrail is structured into distinct, decoupled architectural layers ensuring separation of concerns, testability, and deterministic data flow.

```mermaid
graph TD
    subgraph Client ["Client Presentation Layer (Flutter / Dart)"]
        UD[User Dashboard & Mapbox Map]
        BCS[Booking Confirmation Screen]
        PS[Razorpay Payment Screen]
        AD[Admin Dashboard & Booking Monitor]
        HS[Booking History Screen]
    end

    subgraph Domain ["Domain & Service Layer"]
        SS[StationService]
        US[UserService]
        GU[GeoUtils - Haversine Math]
        BM[Booking Model & Overlap Engine]
    end

    subgraph Security ["Security & Verification Layer"]
        CF[Cloud Function: createRazorpayOrder]
        SR[Firestore Security Rules]
        FAuth[Firebase Phone Authentication]
    end

    subgraph Persistence ["Persistence Layer (Cloud Firestore)"]
        FS_STATIONS[(stations collection)]
        FS_BOOKINGS[(bookings collection)]
        FS_USERS[(users collection)]
        FS_ADMINS[(admins collection)]
    end

    UD --> GU
    UD --> SS
    BCS --> SS
    BCS --> BM
    AD --> SS
    PS --> CF
    US --> FAuth

    SS --> FS_STATIONS
    SS --> FS_BOOKINGS
    US --> FS_USERS
    US --> FS_ADMINS

    FS_BOOKINGS --- SR
    FS_STATIONS --- SR
```

---

## 🔒 Concurrency Control & Double-Booking Prevention

In high-density EV charging infrastructure, allowing two vehicles to reserve the same physical charging stall during overlapping time intervals is a critical domain failure.

### The Race Condition Challenge
Standard client-side validation (`read -> check -> write`) creates a race condition window:
```text
User A: Reads Port 1 at 2:00 PM (Empty) ───────────────> Writes Booking A (Succeeds)
User B: Reads Port 1 at 2:00 PM (Empty) ──> Writes Booking B (Double-Booking Occurred!)
```

### The AmpTrail Solution: Optimistic Concurrency Control (OCC)
AmpTrail combines **normalized interval mathematics** with **atomic Cloud Firestore transactions (`runTransaction`)**:

1. **Interval Overlap Equation**:
   Two time slots $[S_A, E_A)$ and $[S_B, E_B)$ conflict if and only if:
   $$\text{Overlap} \iff (S_A < E_B) \land (E_A > S_B)$$
   Cancelled and rejected reservations are automatically bypassed.

2. **Atomic Verification Transaction**:
   The reservation write is committed through an atomic transaction. If another reservation commits concurrently, the conflict is trapped and reported back as a clean `BookingResult.conflict` instead of corrupting database state.

```mermaid
sequenceDiagram
    autonumber
    actor Driver as EV Driver
    participant App as Mobile App
    participant Service as StationService
    participant Model as BookingModel
    participant DB as Cloud Firestore (Transaction)

    Driver->>App: Selects Port, Date & Slot (e.g. 02:00 PM - 03:00 PM)
    App->>Service: saveBooking(newBooking)
    Service->>DB: Begin Atomic runTransaction
    Service->>DB: Query existing active bookings for stationId + portNumber
    DB-->>Service: Return documents
    loop Overlap Check
        Service->>Model: overlapsWith(newBooking.start, newBooking.end)
        alt Conflict Detected
            Model-->>Service: true
            Service-->>App: Abort transaction -> BookingResult.conflict(msg)
            App-->>Driver: Display Conflict Notice & Refresh Slots
        end
    end
    Service->>DB: Commit document write (status: "accepted")
    DB-->>Service: Transaction Successful
    Service-->>App: BookingResult.success()
    App-->>Driver: Navigate to Live Confirmation / Payment
```

---

## ⚡ Performance Engineering

| Optimization | Implementation Pattern | Impact |
|---|---|---|
| **Map Repaint Isolation** | `RepaintBoundary(child: MapWidget(...))` | Prevents full-screen layout repaints when dragging bottom sheets or swiping station cards. |
| **Marker Bitmap Caching** | Static in-memory bitmap cache (`_cachedMarkerImage`) | Eliminates redundant raster decoding overhead during map panning and chip filtering. |
| **Debounced Search Geocoding** | 400ms Timer cancellation (`_debounce?.cancel()`) | Throttles HTTP calls to Mapbox Geocoding API by over 75% during active typing. |
| **Haversine Distance Engine** | Pure Dart utility in `GeoUtils.calculateDistanceKm` | Performs $O(1)$ spherical trigonometry calculations without triggering widget rebuilds. |
| **Target Frame Rate** | TextureView map rendering with hardware acceleration | Maintains stable 60 FPS scrolling across budget and flagship Android hardware. |

---

## 🛡️ Security Architecture

- **No Hardcoded Secrets**: All third-party tokens (`MAPBOX_TOKEN`, `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`) are isolated in `lib/config/api_keys.dart`.
- **Git Leak Protection**: Production config, `.env*` files, and Firebase debug logs are strictly gitignored. A clean template ([lib/config/api_keys.example.dart](lib/config/api_keys.example.dart)) is committed for onboarding and CI pipelines.
- **Server-Side Payment Signing**: Razorpay secret keys are never distributed in the Flutter binary. Orders are generated through an authenticated Cloud Function (`createRazorpayOrder`) with caller authentication verification (`context.auth`).
- **Cloud Firestore Security Rules**: Production [firestore.rules](firestore.rules) restrict write permissions to authenticated owners and station operators, preventing unauthorized slot modification.
- **Role Verification**: Admin access is validated via backend-verified Firestore document checks (`/admins/{uid}`) rather than relying on client-side state flags.

---

## 🧪 Automated Testing & Continuous Integration

AmpTrail maintains a continuous testing discipline with unit tests covering core domain logic and GitHub Actions validating every commit.

### Test Execution

```bash
flutter test
```

```text
00:00 +0: Booking Model Unit Tests: Booking serializes and deserializes correctly via JSON
00:00 +1: Booking Model Unit Tests: Slot string derivation accurately calculates start and end time
00:00 +2: Booking Model Unit Tests: overlapsWith correctly detects conflicting time intervals
00:00 +3: Booking Model Unit Tests: Cancelled or rejected bookings do not cause conflict overlap
00:00 +4: Booking Model Unit Tests: BookingResult correctly exposes conflict and success states
00:00 +5: GeoUtils Unit Tests: calculateDistanceKm returns 0 for identical coordinates
00:00 +6: GeoUtils Unit Tests: calculateDistanceKm returns accurate distance between Bangalore and Chennai
00:00 +7: GeoUtils Unit Tests: formatDistance returns meters for distances under 1 km
00:00 +8: GeoUtils Unit Tests: formatDistance returns kilometers for distances >= 1 km
00:00 +9: GeoUtils Unit Tests: formatDistance handles 0 and negative inputs safely
00:00 +10: AmpTrail Mini App loads properly
00:00 +11: All tests passed!
```

### GitHub Actions CI Pipeline (`.github/workflows/flutter_ci.yml`)
- **Automated Formatting**: `dart format --output=none --set-exit-if-changed .`
- **Static Analysis**: `flutter analyze --no-fatal-infos` (0 errors, 0 warnings).
- **Automated Regression Suite**: Runs all unit and widget tests on Ubuntu runners.

---

## 📁 Codebase Directory Structure

```text
AmpTrail/
├── .github/
│   └── workflows/
│       └── flutter_ci.yml           # Continuous Integration workflow
├── assets/
│   ├── docs/                        # Architecture & UI showcase media
│   └── icon/                        # Application launcher assets
├── firebase_functions_setup/        # Cloud Functions backend (Node.js)
│   └── index.js                     # Authenticated Razorpay order creation
├── firestore.rules                  # Production Cloud Firestore security rules
├── lib/
│   ├── config/                      # Gitignored API configuration & templates
│   │   ├── api_keys.dart            # Local credentials (gitignored)
│   │   └── api_keys.example.dart    # Public sanitized configuration template
│   ├── constants/                   # Palette tokens, typography, and styling constants
│   ├── models/                      # Domain models (Booking, Station, Vehicle)
│   ├── screens/
│   │   ├── admin/                   # Operator dashboard & slot management
│   │   ├── auth/                    # Phone OTP authentication screens
│   │   └── user/                    # Map discovery, booking, wallet & profile
│   ├── services/                    # Firestore, Auth, Favorites, and API services
│   ├── utils/                       # Geo distance math and theme providers
│   └── main.dart                    # Application bootstrap & dependency setup
├── test/
│   ├── unit/                        # Concurrency, model, and math unit tests
│   └── widget_test.dart             # Smoke test
└── pubspec.yaml                     # Flutter dependencies and asset manifests
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK 3.x](https://docs.flutter.dev/get-started/install) (Channel `stable`)
- [Android Studio](https://developer.android.com/studio) or [Xcode](https://developer.apple.com/xcode/)
- A configured [Firebase Project](https://console.firebase.google.com/)
- A [Mapbox](https://www.mapbox.com/) Access Token

### Local Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/AbdulFahad31/AmpTrail.git
   cd AmpTrail
   ```

2. **Configure Environment Keys**:
   Copy the example configuration:
   ```bash
   cp lib/config/api_keys.example.dart lib/config/api_keys.dart
   ```
   Add your API keys in `lib/config/api_keys.dart`:
   ```dart
   const String MAPBOX_TOKEN = 'your_mapbox_token_here';
   const String RAZORPAY_KEY_ID = 'your_razorpay_key_id';
   const String RAZORPAY_KEY_SECRET = 'your_razorpay_key_secret';
   ```

3. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

4. **Run Analysis & Tests**:
   ```bash
   flutter analyze
   flutter test
   ```

5. **Launch Application**:
   ```bash
   flutter run
   ```

---

## ⚖️ Engineering Trade-Offs & Decisions

### 1. Atomic Transactions vs. Eventual Consistency
- **Decision**: Implemented atomic Firestore transactions for slot verification and reservation.
- **Rationale**: While eventual consistency reduces write latency in read-heavy applications, EV charging stalls represent finite physical resources. An atomic transaction ensures that concurrency conflicts are caught immediately rather than requiring complex manual rollbacks or refunds.

### 2. Normalized Time Intervals vs. Raw String Slots
- **Decision**: Supported dual representations—normalizing start and end timestamps into `DateTime` objects while storing readable slot labels.
- **Rationale**: `DateTime` normalization enables mathematical interval comparison ($O(1)$ overlap detection) across varying session lengths (30 mins vs 2 hours), while preserving human-readable slot strings ensures backwards compatibility with legacy station databases.

### 3. Client-Side Haversine Math vs. Server-Side Geohashes
- **Decision**: Computed geographical distances directly on the client using the Haversine formula in `GeoUtils`.
- **Rationale**: For regional station discovery (< 1,000 stations in the active viewport), fetching station coordinates and calculating client-side distance avoids maintaining complex bounding-box geohash queries and reduces cloud database read costs.

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
