<div align="center">

<img src="https://img.shields.io/badge/⚡-AmpTrail-02569B?style=for-the-badge&labelColor=0a0a0a&color=00C9A7" height="40"/>

# AmpTrail

### EV Charging — Discover. Book. Charge.

<p>
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Firebase-Backend-FFCA28?style=flat-square&logo=firebase&logoColor=black" />
  <img src="https://img.shields.io/badge/Dart-Language-0175C2?style=flat-square&logo=dart&logoColor=white" />
  <img src="https://img.shields.io/badge/Mapbox-Maps-000000?style=flat-square&logo=mapbox&logoColor=white" />
  <img src="https://img.shields.io/badge/Platform-Android-3DDC84?style=flat-square&logo=android&logoColor=white" />
  <img src="https://img.shields.io/badge/Status-Active%20Development-brightgreen?style=flat-square" />
</p>

</div>

---

## What is AmpTrail?

AmpTrail is a mobile application that removes the friction from EV charging. Find nearby stations on an interactive map, check slot availability in real time, and reserve your session — all before you leave home.

Built with **Flutter** and **Firebase**, AmpTrail offers a fast, secure, and intuitive experience for EV owners and a powerful admin dashboard for station operators.

---

## Features

### For EV Users

| Feature | Description |
|---|---|
| 📍 Station Discovery | Find nearby charging stations on an interactive Mapbox-powered map |
| ⚡ Live Availability | See which slots are open right now, updated in real time |
| 📅 Slot Booking | Reserve a charging slot and pick your preferred duration |
| 📜 Booking History | View all past and upcoming reservations in one place |
| 🔔 Notifications | Instant push alerts for booking confirmations and status updates |
| ⭐ Station Info | Browse ratings, pricing, and charger specs before arriving |
| 👤 Profile Management | Manage your account and preferences |

### For Station Admins

| Feature | Description |
|---|---|
| 📨 Booking Requests | Review and act on incoming reservation requests |
| ✅ Approve / ❌ Reject | Accept or decline bookings with one tap and instantly notify users |
| 📊 Station Monitor | Track booking activity and slot usage across stations |
| 🔐 Role-Based Access | Secure admin controls — only authorized users can manage stations |

---

## Tech Stack

| Layer | Technology |
|---|---|
| **Mobile App** | Flutter (Dart) |
| **Authentication** | Firebase Phone Auth (OTP) |
| **Database** | Cloud Firestore |
| **Backend Logic** | Firebase Cloud Functions |
| **Push Notifications** | Firebase Cloud Messaging (FCM) |
| **Hosting** | Firebase Hosting |
| **Maps & Location** | Mapbox SDK |
| **UI Typography** | Google Fonts |
| **API Communication** | HTTP Package |

---

## Architecture

AmpTrail follows a **modular, service-layer architecture** for clean code organization, maintainability, and scalability.

```
lib/
│
├── core/           # App-wide constants, themes, error handling
├── models/         # Data models (Station, Booking, User, etc.)
├── services/       # Firebase, Mapbox, and API integrations
├── providers/      # State management
├── screens/        # Full-page UI screens
├── widgets/        # Reusable UI components
├── utils/          # Helper functions and formatters
└── main.dart       # App entry point
```

---

## Getting Started

### Prerequisites

- [Flutter 3.x](https://docs.flutter.dev/get-started/install) installed
- A Firebase project configured with the required services
- A Mapbox access token

### Installation

```bash
# Clone the repository
git clone https://github.com/AbdulFahad31/AmpTrail.git

# Navigate into the project
cd AmpTrail

# Install dependencies
flutter pub get

# Run the app
flutter run
```

> **Note:** Add your `google-services.json` (Android) and Mapbox token to the appropriate config files before running.

---

## Project Status

```
✅ Firebase Integration
✅ Phone Authentication (OTP)
✅ Cloud Firestore Database
✅ Real-Time Slot Booking
✅ Push Notifications
✅ Admin Panel
🚧 Payment Gateway          ← In Progress
```

---

## Roadmap

- [ ] **Online Payments** — In-app payment for booking sessions
- [ ] **QR Check-In** — Scan to authenticate at the charger
- [ ] **Live Charger Monitoring** — Real-time hardware status feeds
- [ ] **Session Analytics** — Charging history, energy used, cost breakdown
- [ ] **Favourite Stations** — Save and quick-access preferred locations
- [ ] **Dark Mode** — System-aware theme switching
- [ ] **Multi-language Support** — Localization for broader reach

---


## License

This project was developed for educational, research, and hackathon purposes.

---

<div align="center">

If AmpTrail sparked something useful for you, drop a ⭐ — it helps!

</div>
