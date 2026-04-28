# AmpTrail - Backend Integration Guide for Aditya

## Overview
This document outlines all the **backend APIs** that need to be implemented by **Aditya** to connect with the Flutter frontend.

Abdul has completed all **frontend/UI/system** work. The app now has:
- ✅ Complete UI for all screens
- ✅ Navigation flow
- ✅ Models with JSON serialization
- ✅ API service layer (with mock implementations)
- ✅ Firebase Auth integration (OTP)
- ✅ Mapbox integration

---

## 🎯 Your Task (Aditya)

You need to build a **Node.js + Express backend** with **MongoDB** and deploy it.

### Tech Stack (Your Side):
- **Backend**: Node.js + Express
- **Database**: MongoDB Atlas
- **Authentication**: Firebase Admin SDK (for OTP verification)
- **Notifications**: Firebase Cloud Messaging (FCM)
- **Hosting**: Render / Railway / Vercel

---

## 📡 API Endpoints to Implement

### Base URL
```
https://your-backend-url.com/api
```

Update `lib/services/api_service.dart` line 8 with your deployed URL.

---

## 1. Authentication APIs

### 1.1 Send OTP
**Endpoint**: `POST /auth/send-otp`

**Request Body**:
```json
{
  "phoneNumber": "+919876543210"
}
```

**Response** (200 OK):
```json
{
  "success": true,
  "message": "OTP sent successfully"
}
```

**What to do**:
- Use Firebase Admin SDK to send OTP via Firebase Auth
- Return success/error

---

### 1.2 Verify OTP
**Endpoint**: `POST /auth/verify-otp`

**Request Body**:
```json
{
  "phoneNumber": "+919876543210",
  "otp": "123456"
}
```

**Response** (200 OK):
```json
{
  "role": "user",  // or "admin"
  "userId": "U001",
  "name": "John Doe",
  "phoneNumber": "+919876543210",
  "token": "jwt_token_here"
}
```

**What to do**:
- Verify OTP with Firebase Admin SDK
- Check if user exists in MongoDB:
  - If exists, return user data
  - If new, create user in DB
- Check if phone number is admin (store admin phone numbers in DB)
- Generate JWT token for future requests
- Return role ('user' or 'admin')

**MongoDB Schema**:
```javascript
{
  _id: ObjectId,
  userId: String, // unique
  name: String,
  phoneNumber: String, // unique, indexed
  role: String, // 'user' or 'admin'
  createdAt: Date
}
```

---

## 2. Station APIs

### 2.1 Get All Stations
**Endpoint**: `GET /stations`

**Headers**:
```
Authorization: Bearer <jwt_token>
```

**Response** (200 OK):
```json
[
  {
    "id": "1",
    "name": "VoltPark Central",
    "address": "12 Main St, Downtown",
    "latitude": 12.9716,
    "longitude": 77.5946,
    "pricePerHr": 50.0,
    "isAvailable": true,
    "rating": 4.5
  },
  ...
]
```

**What to do**:
- Return all charging stations from MongoDB
- Include availability status

**MongoDB Schema**:
```javascript
{
  _id: ObjectId,
  id: String, // unique station ID
  name: String,
  address: String,
  latitude: Number,
  longitude: Number,
  pricePerHr: Number,
  isAvailable: Boolean,
  rating: Number,
  ownerId: String, // admin user ID who owns this station
  createdAt: Date
}
```

---

## 3. Booking APIs (User Side)

### 3.1 Create Booking
**Endpoint**: `POST /bookings/create`

**Headers**:
```
Authorization: Bearer <jwt_token>
```

**Request Body**:
```json
{
  "id": "B1234567890",
  "userId": "U001",
  "userName": "John Doe",
  "userPhone": "+919876543210",
  "stationId": "1",
  "stationName": "VoltPark Central",
  "bookingDate": "2026-01-17T00:00:00.000Z",
  "timeSlot": "02:00 PM - 04:00 PM",
  "pricePerHr": 50.0,
  "hours": 2,
  "totalPrice": 100.0,
  "status": "pending"
}
```

**Response** (201 Created):
```json
{
  "id": "B1234567890",
  "userId": "U001",
  "stationId": "1",
  "status": "pending",
  "createdAt": "2026-01-16T05:55:00.000Z"
}
```

**What to do**:
1. Save booking to MongoDB with status="pending"
2. **Send FCM notification to station owner** (get owner's FCM token from users collection)
3. Notification should contain:
   - User name & phone
   - Station name
   - Time slot
   - Total price
   - Booking ID

**MongoDB Schema**:
```javascript
{
  _id: ObjectId,
  id: String, // unique booking ID
  userId: String,
  userName: String,
  userPhone: String,
  stationId: String,
  stationName: String,
  bookingDate: Date,
  timeSlot: String,
  pricePerHr: Number,
  hours: Number,
  totalPrice: Number,
  status: String, // 'pending', 'accepted', 'rejected', 'completed', 'cancelled'
  rejectionReason: String, // optional
  createdAt: Date,
  updatedAt: Date
}
```

---

### 3.2 Get User Bookings
**Endpoint**: `GET /bookings/user/:userId`

**Headers**:
```
Authorization: Bearer <jwt_token>
```

**Response** (200 OK):
```json
[
  {
    "id": "B001",
    "userId": "U001",
    "userName": "John Doe",
    "userPhone": "+919876543210",
    "stationId": "1",
    "stationName": "VoltPark Central",
    "bookingDate": "2026-01-15T00:00:00.000Z",
    "timeSlot": "10:00 AM - 12:00 PM",
    "pricePerHr": 50.0,
    "hours": 2,
    "totalPrice": 100.0,
    "status": "completed"
  },
  ...
]
```

**What to do**:
- Return all bookings for the given user ID
- Sort by createdAt descending (newest first)

---

## 4. Admin APIs (Station Owner Side)

### 4.1 Get Pending Bookings
**Endpoint**: `GET /bookings/pending`

**Headers**:
```
Authorization: Bearer <jwt_token>
```

**Response** (200 OK):
```json
[
  {
    "id": "B002",
    "userId": "U001",
    "userName": "John Doe",
    "userPhone": "+919876543210",
    "stationId": "2",
    "stationName": "EcoCharge Hub",
    "bookingDate": "2026-01-17T00:00:00.000Z",
    "timeSlot": "02:00 PM - 04:00 PM",
    "pricePerHr": 45.0,
    "hours": 2,
    "totalPrice": 90.0,
    "status": "pending"
  },
  ...
]
```

**What to do**:
- Return all bookings where status = "pending"
- Filter by stations owned by the logged-in admin
- Sort by createdAt ascending (oldest first)

---

### 4.2 Accept Booking
**Endpoint**: `PUT /bookings/:bookingId/accept`

**Headers**:
```
Authorization: Bearer <jwt_token>
```

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Booking accepted"
}
```

**What to do**:
1. Update booking status to "accepted"
2. **Send FCM notification to user** with confirmation details
3. Notification should say: "Your booking at [Station Name] has been accepted!"

---

### 4.3 Reject Booking
**Endpoint**: `PUT /bookings/:bookingId/reject`

**Headers**:
```
Authorization: Bearer <jwt_token>
```

**Request Body**:
```json
{
  "reason": "Station under maintenance"
}
```

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Booking rejected"
}
```

**What to do**:
1. Update booking status to "rejected"
2. Save rejection reason
3. **Send FCM notification to user** with rejection reason
4. Notification should say: "Your booking was rejected. Reason: [reason]"

---

## 🔥 Firebase Cloud Messaging (FCM) Setup

You need to implement notification logic:

1. **Store FCM tokens** in users collection:
```javascript
{
  userId: "U001",
  phoneNumber: "+919876543210",
  fcmToken: "user_device_token_here", // Updated when user logs in
  ...
}
```

2. **Send notifications** when:
   - User creates booking → Notify station owner
   - Admin accepts/rejects → Notify user

3. **Use Firebase Admin SDK**:
```javascript
const admin = require('firebase-admin');

admin.messaging().send({
  token: userFcmToken,
  notification: {
    title: 'Booking Confirmed!',
    body: 'Your booking at VoltPark Central has been accepted.'
  },
  data: {
    bookingId: 'B001',
    type: 'booking_accepted'
  }
});
```

---

## 📦 MongoDB Collections Summary

### users
- userId (String, unique)
- name (String)
- phoneNumber (String, unique, indexed)
- role (String: 'user' or 'admin')
- fcmToken (String)
- createdAt (Date)

### stations
- id (String, unique)
- name (String)
- address (String)
- latitude (Number)
- longitude (Number)
- pricePerHr (Number)
- isAvailable (Boolean)
- rating (Number)
- ownerId (String) // admin userId
- createdAt (Date)

### bookings
- id (String, unique)
- userId (String)
- userName (String)
- userPhone (String)
- stationId (String)
- stationName (String)
- bookingDate (Date)
- timeSlot (String)
- pricePerHr (Number)
- hours (Number)
- totalPrice (Number)
- status (String: 'pending', 'accepted', 'rejected', 'completed', 'cancelled')
- rejectionReason (String, optional)
- createdAt (Date)
- updatedAt (Date)

---

## 🚀 Deployment Checklist

1. ✅ Create MongoDB Atlas cluster
2. ✅ Set up Firebase Admin SDK
3. ✅ Implement all API endpoints
4. ✅ Add JWT authentication middleware
5. ✅ Test APIs with Postman
6. ✅ Deploy to Render/Railway
7. ✅ Share base URL with Abdul
8. ✅ Test FCM notifications

---

## 📞 Contact

Once you deploy the backend:
1. Share the **base URL** with Abdul
2. Abdul will update `lib/services/api_service.dart` line 8
3. Test the complete flow together!

**Good luck, Aditya! 🚀**
