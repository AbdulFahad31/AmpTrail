import 'package:amptrail_mini/models/booking_model.dart';
import 'package:amptrail_mini/models/station_model.dart';

/// API Service for AmpTrail
/// This is the FRONTEND structure - Aditya will provide the actual backend URLs
/// For now, we use mock data

class ApiService {
  // TODO: Aditya will provide this URL after deploying backend
  static const String baseUrl = 'https://your-backend-url.com/api';
  
  // -------------------------------
  // AUTHENTICATION APIs
  // -------------------------------
  
  /// Send OTP to phone number
  /// Aditya's Backend: POST /auth/send-otp
  Future<bool> sendOtp(String phoneNumber) async {
    try {
      // TODO: Replace with actual API call when Aditya provides backend
      // final response = await http.post(
      //   Uri.parse('$baseUrl/auth/send-otp'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: json.encode({'phoneNumber': phoneNumber}),
      // );
      // return response.statusCode == 200;
      
      // Mock success for now
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      print('Error sending OTP: $e');
      return false;
    }
  }

  /// Verify OTP and login
  /// Aditya's Backend: POST /auth/verify-otp
  /// Returns user role: 'user' or 'admin'
  Future<Map<String, dynamic>?> verifyOtp(String phoneNumber, String otp) async {
    try {
      // TODO: Replace with actual API call when Aditya provides backend
      // final response = await http.post(
      //   Uri.parse('$baseUrl/auth/verify-otp'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: json.encode({'phoneNumber': phoneNumber, 'otp': otp}),
      // );
      // 
      // if (response.statusCode == 200) {
      //   return json.decode(response.body);
      // }
      
      // Mock response for now
      await Future.delayed(const Duration(seconds: 1));
      
      // Check if admin (example: +911234567890)
      if (phoneNumber == '+911234567890') {
        return {
          'role': 'admin',
          'userId': 'ADMIN001',
          'name': 'Admin User',
          'phoneNumber': phoneNumber,
          'token': 'mock_admin_token',
        };
      } else {
        return {
          'role': 'user',
          'userId': 'U001',
          'name': 'John Doe',
          'phoneNumber': phoneNumber,
          'token': 'mock_user_token',
        };
      }
    } catch (e) {
      print('Error verifying OTP: $e');
      return null;
    }
  }

  // -------------------------------
  // STATION APIs (For Map)
  // -------------------------------
  
  /// Get all charging stations
  /// Aditya's Backend: GET /stations
  Future<List<Station>> getAllStations() async {
    try {
      // TODO: Replace with actual API call
      // final response = await http.get(Uri.parse('$baseUrl/stations'));
      // if (response.statusCode == 200) {
      //   List data = json.decode(response.body);
      //   return data.map((json) => Station.fromJson(json)).toList();
      // }
      
      // Return mock data for now
      await Future.delayed(const Duration(milliseconds: 500));
      return dummyStations;
    } catch (e) {
      print('Error fetching stations: $e');
      return [];
    }
  }

  // -------------------------------
  // BOOKING APIs (User Side)
  // -------------------------------
  
  /// Create a new booking request
  /// Aditya's Backend: POST /bookings/create
  /// This sends notification to station owner (Aditya handles FCM)
  Future<Booking?> createBooking(Booking booking) async {
    try {
      // TODO: Replace with actual API call
      // final response = await http.post(
      //   Uri.parse('$baseUrl/bookings/create'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: json.encode(booking.toJson()),
      // );
      // 
      // if (response.statusCode == 201) {
      //   return Booking.fromJson(json.decode(response.body));
      // }
      
      // Mock success for now
      await Future.delayed(const Duration(seconds: 1));
      return booking;
    } catch (e) {
      print('Error creating booking: $e');
      return null;
    }
  }

  /// Get user's booking history
  /// Aditya's Backend: GET /bookings/user/:userId
  Future<List<Booking>> getUserBookings(String userId) async {
    try {
      // TODO: Replace with actual API call
      // final response = await http.get(Uri.parse('$baseUrl/bookings/user/$userId'));
      // if (response.statusCode == 200) {
      //   List data = json.decode(response.body);
      //   return data.map((json) => Booking.fromJson(json)).toList();
      // }
      
      // Return mock data for now
      await Future.delayed(const Duration(milliseconds: 500));
      return dummyUserBookings;
    } catch (e) {
      print('Error fetching user bookings: $e');
      return [];
    }
  }

  // -------------------------------
  // ADMIN APIs (Station Owner Side)
  // -------------------------------
  
  /// Get all pending booking requests for admin
  /// Aditya's Backend: GET /bookings/pending
  Future<List<Booking>> getPendingBookings() async {
    try {
      // TODO: Replace with actual API call
      // final response = await http.get(Uri.parse('$baseUrl/bookings/pending'));
      // if (response.statusCode == 200) {
      //   List data = json.decode(response.body);
      //   return data.map((json) => Booking.fromJson(json)).toList();
      // }
      
      // Return mock data for now
      await Future.delayed(const Duration(milliseconds: 500));
      return dummyPendingBookings;
    } catch (e) {
      print('Error fetching pending bookings: $e');
      return [];
    }
  }

  /// Accept a booking request
  /// Aditya's Backend: PUT /bookings/:id/accept
  /// This sends notification to user (Aditya handles FCM)
  Future<bool> acceptBooking(String bookingId) async {
    try {
      // TODO: Replace with actual API call
      // final response = await http.put(
      //   Uri.parse('$baseUrl/bookings/$bookingId/accept'),
      //   headers: {'Content-Type': 'application/json'},
      // );
      // return response.statusCode == 200;
      
      // Mock success for now
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      print('Error accepting booking: $e');
      return false;
    }
  }

  /// Reject a booking request
  /// Aditya's Backend: PUT /bookings/:id/reject
  /// This sends notification to user (Aditya handles FCM)
  Future<bool> rejectBooking(String bookingId, String reason) async {
    try {
      // TODO: Replace with actual API call
      // final response = await http.put(
      //   Uri.parse('$baseUrl/bookings/$bookingId/reject'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: json.encode({'reason': reason}),
      // );
      // return response.statusCode == 200;
      
      // Mock success for now
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      print('Error rejecting booking: $e');
      return false;
    }
  }
}
