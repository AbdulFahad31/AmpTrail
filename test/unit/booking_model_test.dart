import 'package:flutter_test/flutter_test.dart';
import 'package:amptrail_mini/models/booking_model.dart';
import 'package:amptrail_mini/services/station_service.dart';

void main() {
  group('Booking Model Unit Tests', () {
    final baseDate = DateTime(2026, 10, 25);

    test('Booking serializes and deserializes correctly via JSON', () {
      final start = DateTime(2026, 10, 25, 10, 0);
      final end = DateTime(2026, 10, 25, 12, 0);

      final original = Booking(
        id: 'BT123456',
        userId: 'USER_ABC',
        userName: 'Alex River',
        userPhone: '+919876543210',
        stationId: 'STATION_001',
        stationName: 'VoltPark Central',
        bookingDate: baseDate,
        timeSlot: '10:00 AM - 12:00 PM',
        startDateTime: start,
        endDateTime: end,
        pricePerHr: 80.0,
        hours: 2,
        totalPrice: 160.0,
        status: BookingStatus.accepted,
        portNumber: 2,
      );

      final json = original.toJson();
      expect(json['id'], equals('BT123456'));
      expect(json['pricePerHr'], equals(80.0));
      expect(json['totalPrice'], equals(160.0));
      expect(json['portNumber'], equals(2));
      expect(json['status'], equals('accepted'));

      final restored = Booking.fromJson(json);
      expect(restored.id, equals(original.id));
      expect(restored.userId, equals(original.userId));
      expect(restored.pricePerHr, equals(original.pricePerHr));
      expect(restored.totalPrice, equals(original.totalPrice));
      expect(restored.status, equals(BookingStatus.accepted));
      expect(restored.portNumber, equals(2));
      expect(restored.startDateTime, equals(start));
      expect(restored.endDateTime, equals(end));
    });

    test('Slot string derivation accurately calculates start and end time', () {
      final booking = Booking(
        id: 'BT999',
        userId: 'U1',
        userName: 'Test User',
        userPhone: '+919999999999',
        stationId: 'ST1',
        stationName: 'AmpStation',
        bookingDate: baseDate,
        timeSlot: '09:30 AM - 11:30 AM',
        pricePerHr: 60.0,
        hours: 2,
        totalPrice: 120.0,
        status: BookingStatus.accepted,
        portNumber: 1,
      );

      expect(booking.calculatedStart.hour, equals(9));
      expect(booking.calculatedStart.minute, equals(30));
      expect(booking.calculatedEnd.hour, equals(11));
      expect(booking.calculatedEnd.minute, equals(30));
    });

    test('overlapsWith correctly detects conflicting time intervals', () {
      final booking = Booking(
        id: 'B_EXISTING',
        userId: 'U1',
        userName: 'User 1',
        userPhone: '+911111111111',
        stationId: 'ST1',
        stationName: 'Station 1',
        bookingDate: baseDate,
        timeSlot: '10:00 AM - 12:00 PM',
        startDateTime: DateTime(2026, 10, 25, 10, 0),
        endDateTime: DateTime(2026, 10, 25, 12, 0),
        pricePerHr: 50.0,
        hours: 2,
        totalPrice: 100.0,
        status: BookingStatus.accepted,
        portNumber: 1,
      );

      // Exact overlap (10:00 - 12:00)
      expect(
        booking.overlapsWith(
          DateTime(2026, 10, 25, 10, 0),
          DateTime(2026, 10, 25, 12, 0),
        ),
        isTrue,
      );

      // Partial overlap inside (10:30 - 11:30)
      expect(
        booking.overlapsWith(
          DateTime(2026, 10, 25, 10, 30),
          DateTime(2026, 10, 25, 11, 30),
        ),
        isTrue,
      );

      // Partial overlap start (09:00 - 10:30)
      expect(
        booking.overlapsWith(
          DateTime(2026, 10, 25, 9, 0),
          DateTime(2026, 10, 25, 10, 30),
        ),
        isTrue,
      );

      // Partial overlap end (11:30 - 13:00)
      expect(
        booking.overlapsWith(
          DateTime(2026, 10, 25, 11, 30),
          DateTime(2026, 10, 25, 13, 0),
        ),
        isTrue,
      );

      // Completely adjacent preceding (08:00 - 10:00) -> NO overlap
      expect(
        booking.overlapsWith(
          DateTime(2026, 10, 25, 8, 0),
          DateTime(2026, 10, 25, 10, 0),
        ),
        isFalse,
      );

      // Completely adjacent succeeding (12:00 - 14:00) -> NO overlap
      expect(
        booking.overlapsWith(
          DateTime(2026, 10, 25, 12, 0),
          DateTime(2026, 10, 25, 14, 0),
        ),
        isFalse,
      );
    });

    test('Cancelled or rejected bookings do not cause conflict overlap', () {
      final cancelledBooking = Booking(
        id: 'B_CANCELLED',
        userId: 'U1',
        userName: 'User 1',
        userPhone: '+911111111111',
        stationId: 'ST1',
        stationName: 'Station 1',
        bookingDate: baseDate,
        timeSlot: '10:00 AM - 12:00 PM',
        startDateTime: DateTime(2026, 10, 25, 10, 0),
        endDateTime: DateTime(2026, 10, 25, 12, 0),
        pricePerHr: 50.0,
        hours: 2,
        totalPrice: 100.0,
        status: BookingStatus.cancelled,
        portNumber: 1,
      );

      expect(
        cancelledBooking.overlapsWith(
          DateTime(2026, 10, 25, 10, 0),
          DateTime(2026, 10, 25, 12, 0),
        ),
        isFalse,
      );
    });

    test('BookingResult correctly exposes conflict and success states', () {
      const successResult = BookingResult.success();
      expect(successResult.isSuccess, isTrue);
      expect(successResult.isConflict, isFalse);
      expect(successResult.errorMessage, isNull);

      const conflictResult = BookingResult.conflict('Slot already booked');
      expect(conflictResult.isSuccess, isFalse);
      expect(conflictResult.isConflict, isTrue);
      expect(conflictResult.errorMessage, equals('Slot already booked'));
    });
  });
}
