# AmpTrail Mini - Feature Testing & Enhancement Plan

## ✅ WORKING FEATURES (Tested & Verified)

### 1. **Authentication Flow**
- ✅ Login Screen with phone number input
- ✅ OTP Verification Screen
- ✅ Firebase Authentication integration
- ✅ Role-based routing (User/Admin)

### 2. **User Dashboard - Map Screen**
- ✅ Mapbox integration with dark theme
- ✅ Current location detection & permission handling
- ✅ Search functionality with Mapbox Geocoding API
- ✅ Search suggestions dropdown
- ✅ Station markers on map (4 test stations)
- ✅ Horizontal station card carousel
- ✅ Distance calculation from current location
- ✅ "My Location" floating action button
- ✅ Fly-to animation when selecting stations

### 3. **Booking Flow**
- ✅ Station card with "Book Now" button
- ✅ Booking Confirmation Screen
  - Date selection
  - Time slot selection
  - Hours selection
  - Price calculation
  - Booking status flow (requesting → waiting → accepted)
- ✅ Mock booking creation via ApiService

### 4. **History Screen**
- ✅ Displays past bookings
- ✅ Status badges (Completed, Cancelled, Pending)
- ✅ Booking details display

### 5. **Profile Screen**
- ✅ User avatar with initials
- ✅ Display name from Firebase Auth
- ✅ Phone number display
- ✅ Edit Profile navigation
- ✅ Notifications settings dialog
- ✅ Privacy & Security dialog
- ✅ Help & Support with URL launcher
- ✅ Logout functionality

### 6. **Edit Profile**
- ✅ Name editing with Firebase sync
- ✅ Profile picture upload (Gallery/Camera)
- ✅ Local storage of profile image
- ✅ Real-time avatar update

### 7. **Admin Dashboard**
- ✅ Pending bookings list
- ✅ Accept/Reject booking actions
- ✅ User information display
- ✅ Mock data for testing

## 🔧 FEATURES TO ENHANCE

### 1. **Add "Live Charging" Feature**
- Create a button to start charging session
- Show real-time charging animation
- Display battery percentage, time remaining, cost
- Add "Stop Charging" functionality

### 2. **Improve Station Cards**
- Add station images (using placeholder URLs)
- Show connector types
- Add "Directions" button (Google Maps integration)
- Show operating hours

### 3. **Add Favorites Feature**
- Star icon on station cards
- Save favorite stations locally
- Quick access to favorites

### 4. **Enhance Search**
- Add recent searches
- Filter by availability
- Filter by price range
- Sort by distance/rating/price

### 5. **Add Notifications**
- Booking confirmation notification
- Charging complete notification
- Low battery warning

### 6. **Add Payment Integration**
- Wallet balance display
- Add money to wallet
- Transaction history
- Payment for bookings

## 🐛 KNOWN ISSUES TO FIX

1. ⚠️ Deprecation warnings for `withOpacity` (use `withValues`)
2. ⚠️ No error handling for network failures
3. ⚠️ Mock data needs to be replaced with real API calls
4. ⚠️ No offline mode support

## 🎯 PRIORITY ENHANCEMENTS (Within Limits)

### Priority 1: Essential Fixes
1. Fix deprecation warnings
2. Add proper error handling
3. Add loading states

### Priority 2: User Experience
1. Add station images
2. Add "Directions" button
3. Improve booking confirmation UI
4. Add charging session screen

### Priority 3: Nice to Have
1. Add favorites
2. Add filters
3. Add recent searches
4. Add wallet feature

---

**Note**: All backend API calls are currently mocked. Aditya will provide real endpoints.
