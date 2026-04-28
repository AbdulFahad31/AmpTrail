# 🔋 AmpTrail - EV Charging Station Booking App

A modern Flutter application for booking EV charging slots at nearby stations. Users can find stations on a map, book charging slots, and receive real-time notifications when station owners accept or reject their requests.

## 📱 Features

### User Features
- 🗺️ **Interactive Map** - View nearby charging stations on Mapbox
- 📍 **Station Details** - See pricing, availability, and ratings
- 📅 **Slot Booking** - Select date, time slot, and duration
- 🔔 **Notifications** - Get notified when booking is accepted/rejected
- 📜 **Booking History** - View all past and upcoming bookings
- 👤 **Profile Management** - Manage account settings

### Admin Features
- 📨 **Booking Requests** - View all pending booking requests
- ✅ **Accept/Reject** - Approve or decline bookings with reasons
- 🔔 **Notification System** - Notify users of booking status

### Authentication
- 📱 **OTP Login** - Secure phone number authentication via Firebase
- 🔐 **Role-based Access** - Automatic routing to user or admin dashboard

---

## 🎨 UI/UX Highlights

- ✨ **Modern Dark Theme** with vibrant electric green accents
- 🎭 **Smooth Animations** using `animate_do` package
- 💅 **Google Fonts** (Outfit) for premium typography
- 🎨 **Glassmorphism** effects on search bars and cards
- 📱 **Responsive Design** for all screen sizes

---

## 🏗️ Project Structure

```
lib/
├── constants/
│   └── colors.dart              # App color palette
├── models/
│   ├── station_model.dart       # Station data model
│   └── booking_model.dart       # Booking data model
├── screens/
│   ├── splash_screen.dart       # 3-second splash screen
│   ├── auth/
│   │   ├── login_screen.dart    # Phone number login
│   │   └── otp_verification_screen.dart
│   ├── user/
│   │   ├── user_dashboard.dart  # Map view with stations
│   │   ├── booking_confirmation_screen.dart
│   │   ├── history_screen.dart
│   │   └── profile_screen.dart
│   └── admin/
│       └── admin_dashboard.dart # Booking requests panel
├── services/
│   └── api_service.dart         # API integration layer
└── main.dart
```

---

## 🛠️ Tech Stack

### Frontend (Abdul's Work - ✅ COMPLETED)
- **Framework**: Flutter 3.x
- **State Management**: setState (simple, suitable for this scope)
- **Maps**: Mapbox Maps Flutter SDK
- **Authentication**: Firebase Auth (OTP)
- **UI Animations**: animate_do
- **Fonts**: Google Fonts (Outfit)
- **HTTP Client**: http package

### Backend (Aditya's Work - 🚧 IN PROGRESS)
- **Runtime**: Node.js + Express
- **Database**: MongoDB Atlas
- **Authentication**: Firebase Admin SDK
- **Notifications**: Firebase Cloud Messaging (FCM)
- **Hosting**: Render / Railway / Vercel

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>= 3.7.2)
- Android Studio / VS Code
- Firebase project with Auth enabled
- Mapbox API token

### Installation

1. **Clone the repository**
```bash
git clone <your-repo-url>
cd AmpTrailMini
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Configure Firebase**
- Add `google-services.json` to `android/app/`
- Add `GoogleService-Info.plist` to `ios/Runner/` (for iOS)

4. **Configure Mapbox**
- Get your Mapbox token from https://mapbox.com
- Add to `android/app/src/main/AndroidManifest.xml`:
  ```xml
  <meta-data
      android:name="MAPBOX_ACCESS_TOKEN"
      android:value="YOUR_MAPBOX_TOKEN" />
  ```

5. **Run the app**
```bash
flutter run
```

---

## 🔐 Login Credentials (Demo)

### User Login
- Phone: Any number except `+911234567890`
- OTP: Any 6-digit code (Firebase will send real OTP in production)

### Admin Login
- Phone: `+911234567890`
- OTP: Firebase OTP

The role is determined by the phone number in the backend.

---

## 📡 API Integration

The app uses a service layer (`lib/services/api_service.dart`) with mock implementations. Once Aditya deploys the backend:

1. Update the base URL in `api_service.dart`:
```dart
static const String baseUrl = 'https://your-backend-url.com/api';
```

2. Uncomment the HTTP requests in each function
3. Remove mock data returns

For detailed API documentation, see [BACKEND_GUIDE.md](BACKEND_GUIDE.md).

---

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  google_fonts: ^6.3.2
  animate_do: ^4.2.0
  firebase_core: ^4.3.0
  firebase_auth: ^6.1.3
  mapbox_maps_flutter: ^2.17.0
  http: ^1.6.0
  intl: ^0.19.0
  permission_handler: ^12.0.1
  intl_phone_field: ^3.2.0
```

---

## 🎯 App Flow

```
Splash Screen (3s)
    ↓
Login Screen (Phone Number)
    ↓
OTP Verification
    ↓
Role Check (DB)
    ↓
┌──────────────────┬──────────────────┐
│   User Dashboard │  Admin Dashboard │
│   - Map View     │  - Requests List │
│   - Book Slot    │  - Accept/Reject │
│   - History      │                  │
│   - Profile      │                  │
└──────────────────┴──────────────────┘
```

### Booking Flow (User → Admin → User)
1. **User** selects station on map
2. **User** chooses date, time slot, hours
3. **User** confirms booking
4. **Notification sent to Admin** (station owner)
5. **Admin** sees request in dashboard
6 **Admin** accepts or rejects with reason
7. **Notification sent back to User**
8. **User** sees updated status in history

---

## 🎨 Color Palette

```dart
Background: #0F172A (Dark Slate)
Surface: #1E293B (Lighter Slate)
Primary: #00E676 (Electric Green)
Secondary: #2979FF (Electric Blue)
Accent: #FFC400 (Amber)
Error: #EF4444 (Red)
Success: #22C55E (Green)
Warning: #FFC400 (Amber)
```

---

## 📸 Screenshots

_TODO: Add screenshots after running the app_

---

## 🔮 Future Enhancements

- 🌐 Real-time availability tracking
- 💳 Payment gateway integration
- ⭐ User reviews and ratings
- 📊 Analytics dashboard for admins
- 🚗 EV finder (location sharing)
- 🔋 Battery % based recommendations

---

## 👥 Team

### Frontend & System (Abdul)
- Flutter app development
- UI/UX design
- Mapbox integration
- Device testing

### Backend & Cloud (Aditya)
- Node.js API development
- MongoDB database
- Firebase FCM notifications
- Deployment

---

## 📄 License

This project is for educational/hackathon purposes.

---

## 🤝 Contributing

This is a collaborative project between Abdul and Aditya. For contributions:
1. Frontend changes → Contact Abdul
2. Backend changes → Contact Aditya

---

## 📞 Support

For any issues or questions:
- Abdul (Frontend): [Your Contact]
- Aditya (Backend): [Aditya's Contact]

---

**Made with ⚡ by Abdul & Aditya**
