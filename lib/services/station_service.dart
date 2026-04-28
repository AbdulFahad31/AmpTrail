import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:amptrail_mini/models/station_model.dart';
import 'package:amptrail_mini/models/booking_model.dart';
import 'package:flutter/foundation.dart';

class StationService {
  // Singleton pattern to enable global caching
  static final StationService _instance = StationService._internal();
  factory StationService() => _instance;
  StationService._internal();

  // Connect to your specific database 'stations31'
  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'stations31',
  );
  final String _collectionPath = 'stations';

  // In-memory cache
  List<Station>? _cachedStations;
  DateTime? _lastFetchTime;
  final Duration _cacheDuration = const Duration(minutes: 5);

  // Fetch all stations from Firestore
  Future<List<Station>> getStations({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh && _cachedStations != null && _lastFetchTime != null) {
        if (DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
          debugPrint("DEBUG: Returning cached stations.");
          return _cachedStations!;
        }
      }

      debugPrint("DEBUG: Fetching stations from Firestore...");
      QuerySnapshot querySnapshot = await _firestore.collection(_collectionPath).get(
        const GetOptions(source: Source.serverAndCache),
      );
      
      List<Station> stations = [];
      for (var doc in querySnapshot.docs) {
        try {
          stations.add(Station.fromFirestore(doc));
        } catch (e) {
          debugPrint("ERROR parsing station doc ${doc.id}: $e");
        }
      }
      
      _cachedStations = stations;
      _lastFetchTime = DateTime.now();
      
      debugPrint("DEBUG: Successfully fetched ${stations.length} stations.");
      return stations;
    } catch (e) {
      debugPrint("ERROR: Error fetching stations: $e");
      // Return cached stations if available in case of error
      if (_cachedStations != null) return _cachedStations!;
      // Return empty list or handle error as needed
      return [];
    }
  }

  // Save a new booking to Firestore
  Future<bool> saveBooking(Booking booking) async {
    try {
      debugPrint("DEBUG: Saving booking ${booking.id} to Firestore...");
      await _firestore.collection('bookings').doc(booking.id).set(booking.toJson());
      debugPrint("DEBUG: Booking saved successfully.");
      return true;
    } catch (e) {
      debugPrint("ERROR: Error saving booking: $e");
      return false;
    }
  }

  // Get current user's bookings from Firestore with pagination capability
  Future<List<Booking>> getMyBookings(String identifier, {String? userId, DocumentSnapshot? startAfter, int limit = 20}) async {
    try {
      debugPrint("DEBUG: StationService - Fetching bookings for identifier: $identifier");
      
      Query query = _firestore.collection('bookings').where('userPhone', isEqualTo: identifier);
      
      // Order by descending date first so startAfter logic works correctly
      query = query.orderBy('bookingDate', descending: true).limit(limit);
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      
      // Try by phone/email identifier
      QuerySnapshot querySnapshot = await query.get(const GetOptions(source: Source.serverAndCache));
      
      // If empty and we have a userId, try by userId
      if (querySnapshot.docs.isEmpty && userId != null) {
        debugPrint("DEBUG: No bookings found for $identifier, trying userId: $userId");
        Query userQuery = _firestore.collection('bookings').where('userId', isEqualTo: userId);
        userQuery = userQuery.orderBy('bookingDate', descending: true).limit(limit);
        if (startAfter != null) {
          userQuery = userQuery.startAfterDocument(startAfter);
        }
        querySnapshot = await userQuery.get(const GetOptions(source: Source.serverAndCache));
      }
      
      List<Booking> bookings = [];
      for (var doc in querySnapshot.docs) {
        try {
          bookings.add(Booking.fromFirestore(doc));
        } catch (e) {
          debugPrint("ERROR parsing booking doc ${doc.id}: $e");
        }
      }

      // Sort locally: newest first
      bookings.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
      
      debugPrint("DEBUG: StationService - Found ${bookings.length} fetched bookings.");
      return bookings;
    } catch (e) {
      debugPrint("ERROR: StationService - Error fetching history: $e");
      return [];
    }
  }

  // Stream of bookings for real-time updates (Capped for performance)
  Stream<List<Booking>> getBookingsStream(String identifier, {String? userId, int limit = 20}) {
    debugPrint("DEBUG: StationService - Opening stream for $identifier (UID: $userId)");
    
    // We'll prioritize the field we find data in. For simplicity in a stream, 
    // we can merge two streams if needed, but it's likely one will work.
    // Let's use the phone identifier for now as it's the primary field.
    return _firestore
        .collection('bookings')
        .where('userPhone', isEqualTo: identifier)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          debugPrint("DEBUG: StationService - Stream received ${snapshot.docs.length} docs for phone.");
          final bookings = <Booking>[];
          for (var doc in snapshot.docs) {
            try {
              bookings.add(Booking.fromFirestore(doc));
            } catch (e) {
              debugPrint("ERROR parsing booking doc in stream ${doc.id}: $e");
            }
          }
          bookings.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
          return bookings;
        });
  }

  // Delete a booking by ID
  Future<bool> deleteBooking(String bookingId) async {
    try {
      debugPrint("DEBUG: Deleting booking $bookingId...");
      await _firestore.collection('bookings').doc(bookingId).delete();
      return true;
    } catch (e) {
      debugPrint("ERROR: Error deleting booking: $e");
      return false;
    }
  }

  // Cancel a booking by ID
  Future<bool> cancelBooking(String bookingId) async {
    try {
      debugPrint("DEBUG: Cancelling booking $bookingId...");
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': BookingStatus.cancelled.toString().split('.').last,
      });
      return true;
    } catch (e) {
      debugPrint("ERROR: Error cancelling booking: $e");
      return false;
    }
  }

  // Stream of stations for real-time updates
  Stream<List<Station>> stationsStream() {
    return _firestore.collection(_collectionPath).snapshots().map((snapshot) {
      final stations = <Station>[];
      for (var doc in snapshot.docs) {
        try {
          stations.add(Station.fromFirestore(doc));
        } catch (e) {
          debugPrint("ERROR parsing station doc in stream ${doc.id}: $e");
        }
      }
      return stations;
    });
  }

  // Get booked time slots for a specific station and date
  Future<List<Booking>> getBookedSlotsForStation(String stationId, DateTime date) async {
    try {
      final querySnapshot = await _firestore
          .collection('bookings')
          .where('stationId', isEqualTo: stationId)
          .get();

      List<Booking> bookedSlots = [];
      for (var doc in querySnapshot.docs) {
        try {
          final booking = Booking.fromFirestore(doc);
          if (booking.status != BookingStatus.cancelled &&
              booking.status != BookingStatus.rejected) {
            if (booking.bookingDate.year == date.year &&
                booking.bookingDate.month == date.month &&
                booking.bookingDate.day == date.day) {
              bookedSlots.add(booking);
            }
          }
        } catch (e) {
          debugPrint("ERROR parsing booking for slots: $e");
        }
      }
      return bookedSlots;
    } catch (e) {
      debugPrint("ERROR getting booked slots: $e");
      return [];
    }
  }

  // Real-time Stream for booked time slots
  Stream<List<Booking>> bookedSlotsStream(String stationId, DateTime date) {
    return _firestore
        .collection('bookings')
        .where('stationId', isEqualTo: stationId)
        .snapshots()
        .map((snapshot) {
      List<Booking> bookedSlots = [];
      for (var doc in snapshot.docs) {
        try {
          final booking = Booking.fromFirestore(doc);
          if (booking.status != BookingStatus.cancelled &&
              booking.status != BookingStatus.rejected) {
            if (booking.bookingDate.year == date.year &&
                booking.bookingDate.month == date.month &&
                booking.bookingDate.day == date.day) {
              bookedSlots.add(booking);
            }
          }
        } catch (e) {
          debugPrint("ERROR parsing booking for slots stream: $e");
        }
      }
      return bookedSlots;
    });
  }
}
