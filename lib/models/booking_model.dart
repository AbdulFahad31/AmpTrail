
import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus {
  pending,
  accepted,
  rejected,
  completed,
  cancelled,
}

class Booking {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final String stationId;
  final String stationName;
  final DateTime bookingDate;
  final String timeSlot; // e.g., "10:00 AM - 11:00 AM"
  final double pricePerHr;
  final int hours;
  final double totalPrice;
  final BookingStatus status;
  final String? rejectionReason;
  final int portNumber;

  Booking({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.stationId,
    required this.stationName,
    required this.bookingDate,
    required this.timeSlot,
    required this.pricePerHr,
    required this.hours,
    required this.totalPrice,
    required this.status,
    this.rejectionReason,
    this.portNumber = 1,
  });

  // Convert to JSON for API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'stationId': stationId,
      'stationName': stationName,
      'bookingDate': bookingDate.toIso8601String(),
      'timeSlot': timeSlot,
      'pricePerHr': pricePerHr,
      'hours': hours,
      'totalPrice': totalPrice,
      'status': status.toString().split('.').last,
      'rejectionReason': rejectionReason,
      'portNumber': portNumber,
    };
  }

  // Create from JSON (for backend response)
  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      userId: json['userId'],
      userName: json['userName'],
      userPhone: json['userPhone'],
      stationId: json['stationId'],
      stationName: json['stationName'],
      bookingDate: DateTime.parse(json['bookingDate']),
      timeSlot: json['timeSlot'],
      pricePerHr: json['pricePerHr'].toDouble(),
      hours: json['hours'],
      totalPrice: json['totalPrice'].toDouble(),
      status: BookingStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      rejectionReason: json['rejectionReason'],
      portNumber: json['portNumber'] ?? 1,
    );
  }

  // Create from Firestore Document
  factory Booking.fromFirestore(DocumentSnapshot doc) {
    try {
      Map<String, dynamic> data = (doc.data() as Map<String, dynamic>?) ?? {};

      DateTime parseDate(dynamic value) {
        if (value == null) return DateTime.now();
        if (value is Timestamp) return value.toDate();
        if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
        if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
        return DateTime.now();
      }

      double parseDouble(dynamic value, double defaultValue) {
        if (value == null) return defaultValue;
        if (value is double) return value;
        if (value is int) return value.toDouble();
        if (value is String) return double.tryParse(value) ?? defaultValue;
        return defaultValue;
      }

      int parseInt(dynamic value, int defaultValue) {
        if (value == null) return defaultValue;
        if (value is int) return value;
        if (value is double) return value.toInt();
        if (value is String) return int.tryParse(value) ?? defaultValue;
        return defaultValue;
      }

      return Booking(
        id: doc.id,
        userId: data['userId']?.toString() ?? '',
        userName: data['userName']?.toString() ?? '',
        userPhone: data['userPhone']?.toString() ?? '',
        stationId: data['stationId']?.toString() ?? '',
        stationName: data['stationName']?.toString() ?? 'Unknown Station',
        bookingDate: parseDate(data['bookingDate']),
        timeSlot: data['timeSlot']?.toString() ?? '',
        pricePerHr: parseDouble(data['pricePerHr'], 0.0),
        hours: parseInt(data['hours'], 0),
        totalPrice: parseDouble(data['totalPrice'], 0.0),
        status: BookingStatus.values.firstWhere(
          (e) => e.toString().split('.').last == (data['status']?.toString() ?? 'pending'),
          orElse: () => BookingStatus.pending,
        ),
        rejectionReason: data['rejectionReason']?.toString(),
        portNumber: parseInt(data['portNumber'], 1),
      );
    } catch (e) {
      print("Error parsing Booking ${doc.id}: $e");
      rethrow;
    }
  }
}

// Mock Data for testing (Abdul's side)
List<Booking> dummyUserBookings = [
  Booking(
    id: 'B001',
    userId: 'U001',
    userName: 'John Doe',
    userPhone: '+919876543210',
    stationId: '1',
    stationName: 'VoltPark Central',
    bookingDate: DateTime.now().subtract(const Duration(days: 2)),
    timeSlot: '10:00 AM - 12:00 PM',
    pricePerHr: 50.0,
    hours: 2,
    totalPrice: 100.0,
    status: BookingStatus.completed,
  ),
  Booking(
    id: 'B002',
    userId: 'U001',
    userName: 'John Doe',
    userPhone: '+919876543210',
    stationId: '2',
    stationName: 'EcoCharge Hub',
    bookingDate: DateTime.now().add(const Duration(days: 1)),
    timeSlot: '02:00 PM - 04:00 PM',
    pricePerHr: 45.0,
    hours: 2,
    totalPrice: 90.0,
    status: BookingStatus.pending,
  ),
  Booking(
    id: 'B003',
    userId: 'U001',
    userName: 'John Doe',
    userPhone: '+919876543210',
    stationId: '3',
    stationName: 'AmpZone Fast Charging',
    bookingDate: DateTime.now().subtract(const Duration(days: 5)),
    timeSlot: '09:00 AM - 11:00 AM',
    pricePerHr: 60.0,
    hours: 2,
    totalPrice: 120.0,
    status: BookingStatus.rejected,
    rejectionReason: 'Station under maintenance',
  ),
];

// Mock pending requests for Admin
List<Booking> dummyPendingBookings = [
  Booking(
    id: 'B002',
    userId: 'U001',
    userName: 'John Doe',
    userPhone: '+919876543210',
    stationId: '2',
    stationName: 'EcoCharge Hub',
    bookingDate: DateTime.now().add(const Duration(days: 1)),
    timeSlot: '02:00 PM - 04:00 PM',
    pricePerHr: 45.0,
    hours: 2,
    totalPrice: 90.0,
    status: BookingStatus.pending,
  ),
  Booking(
    id: 'B004',
    userId: 'U002',
    userName: 'Jane Smith',
    userPhone: '+919123456789',
    stationId: '1',
    stationName: 'VoltPark Central',
    bookingDate: DateTime.now().add(const Duration(hours: 5)),
    timeSlot: '06:00 PM - 08:00 PM',
    pricePerHr: 50.0,
    hours: 2,
    totalPrice: 100.0,
    status: BookingStatus.pending,
  ),
];
