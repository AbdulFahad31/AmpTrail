🔋 AmpTrail - EV Charging Station Booking App

A modern Flutter application for booking EV charging slots at nearby stations. Users can find stations on a map, book charging slots, and receive real-time notifications when station owners accept or reject their requests.

📱 Features
User Features
🗺️ Interactive Map - View nearby charging stations on Mapbox
📍 Station Details - See pricing, availability, and ratings
📅 Slot Booking - Select date, time slot, and duration
🔔 Notifications - Get notified when booking is accepted/rejected
📜 Booking History - View all past and upcoming bookings
👤 Profile Management - Manage account settings
Admin Features
📨 Booking Requests - View all pending booking requests
✅ Accept/Reject - Approve or decline bookings with reasons
🔔 Notification System - Notify users of booking status
🔐 Authentication
📱 OTP Login - Secure phone number authentication via Firebase
🔐 Role-based Access - Automatic routing to user or admin dashboard
🛠️ Tech Stack
Frontend
Framework: Flutter 3.x
State Management: setState
Maps: Mapbox Maps Flutter SDK
Authentication: Firebase Auth (OTP)
UI Animations: animate_do
Fonts: Google Fonts (Outfit)
HTTP Client: http package
Backend 
Authentication: Firebase Auth (OTP)
Database: Cloud Firestore
Backend Logic: Firebase Functions
Notifications: Firebase Cloud Messaging (FCM)
Hosting: Firebase Hosting
The app uses a service layer (lib/services/api_service.dart) with mock implementations.


👥 Developer
Abdul – Flutter app development, UI/UX, Mapbox integration, testing
📞 Support

For any issues or questions:

Abdul: 7539934156
📄 License

This project is for educational/hackathon purposes.
