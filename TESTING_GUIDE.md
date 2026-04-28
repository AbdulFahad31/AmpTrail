# 🎯 Quick Testing Guide - AmpTrail Mini 1.1.0

## 🔑 New Features to Test

### 📍 Location & Map
1. **Current Location**: Tap the bullseye button (bottom right). It now shows a spinner while fetching. It will timeout if GPS is poor.
2. **Map Styles**: Tap the sun/moon icon (top right). Switches between Dark and Light Street maps.
3. **Refresh**: Tap the sync icon below the style switcher to "update" stations.

### 💖 Favorites & Filters
1. **Favorite a Station**: Tap the heart icon on any station card. It turns red and saves!
2. **Filter by Favorites**: Tap the "Favorites" chip below the search bar. Only your red-heart stations will show.
3. **Filter by Available**: Tap the "Available" chip to hide "Busy" stations.
4. **Empty State**: Favorite nothing, then filter by favorites to see the "No stations found" message.

### 💰 Wallet & Info
1. **Wallet**: Check the search bar - you'll see a ₹1,250 balance pill.
2. **Card Details**: Look at the station cards. You'll see "CCS2", "22 kW", and "12 min" tags now.

### 🌍 Social Impact
1. Go to **Profile**.
2. See the new "Impact Statistics" card at the top showing your CO2 savings.

## 🧪 Basic Checklist
- [ ] Login (User/Admin)
- [ ] Location fetch (Success SnackBar)
- [ ] Search & Suggestions
- [ ] Map Style Toggle
- [ ] Filter Chips logic
- [ ] Favorite toggle persistence
- [ ] Booking confirmation flow
- [ ] Live charging animation
- [ ] Profile photo change
- [ ] Admin Accept/Reject

---
**Happy Testing! 🎉**
