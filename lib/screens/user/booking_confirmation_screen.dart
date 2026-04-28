import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:amptrail_mini/constants/colors.dart';
import 'package:amptrail_mini/models/station_model.dart';
import 'package:amptrail_mini/models/booking_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:amptrail_mini/screens/user/payment_screen.dart';
import 'package:amptrail_mini/services/station_service.dart';
import 'dart:async';

class BookingConfirmationScreen extends StatefulWidget {
  final Station station;
  
  const BookingConfirmationScreen({super.key, required this.station});

  @override
  State<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  final StationService _stationService = StationService();
  final user = FirebaseAuth.instance.currentUser;
  
  DateTime selectedDate = DateTime.now();
  TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 10, minute: 0);
  int selectedHours = 1;
  int selectedPort = 1;
  String _status = 'selection'; // selection, requesting, waiting, accepted, rejected

  List<Booking> bookedSlots = [];
  StreamSubscription<List<Booking>>? _slotsSubscription;

  @override
  void dispose() {
    _slotsSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _setInitialTimes();
  }

  void _setInitialTimes() {
    final now = DateTime.now();
    int startHour = now.hour + 1;
    
    if (startHour >= 24) {
      // It's very late, default to tomorrow morning 9 AM
      selectedDate = now.add(const Duration(days: 1));
      startTime = const TimeOfDay(hour: 9, minute: 0);
      endTime = const TimeOfDay(hour: 10, minute: 0);
    } else {
      // Default to today, next available hour
      selectedDate = now;
      startTime = TimeOfDay(hour: startHour, minute: 0);
      endTime = TimeOfDay(hour: (startHour + 1) % 24, minute: 0);
      
      // If it's late in the night (e.g. after 10 PM), default to tomorrow 9 AM anyway
      if (now.hour >= 22) {
        selectedDate = now.add(const Duration(days: 1));
        startTime = const TimeOfDay(hour: 9, minute: 0);
        endTime = const TimeOfDay(hour: 10, minute: 0);
      }
    }
    
    _loadBookedSlots();
    _calculateHours();
  }

  void _calculateHours() {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    
    int diff = endMinutes - startMinutes;
    // If end time is before start time, assume it's for the next day
    if (diff <= 0) diff += 24 * 60; 
    
    setState(() {
      selectedHours = (diff / 60).ceil();
      if (selectedHours == 0) selectedHours = 1;
    });
  }

  double get pricePerHr => widget.station.pricePerHr;
  double get totalPrice => pricePerHr * selectedHours;

  bool _isTimeInPast() {
    final now = DateTime.now();
    final bookingStart = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      startTime.hour,
      startTime.minute,
    );
    
    return bookingStart.isBefore(now);
  }

  void _loadBookedSlots() {
    _slotsSubscription?.cancel();
    _slotsSubscription = _stationService.bookedSlotsStream(widget.station.id, selectedDate).listen(
      (slots) {
        if (mounted) {
          setState(() {
            bookedSlots = slots;
          });
        }
      },
      onError: (e) {
        debugPrint("Error listening to booked slots: $e");
      }
    );
  }

  int _parseTimeStr(String timeStr) {
    timeStr = timeStr.trim().toUpperCase().replaceAll('\u202F', ' ').replaceAll('.', '');
    bool isPM = timeStr.contains('PM');
    bool isAM = timeStr.contains('AM');
    
    timeStr = timeStr.replaceAll('PM', '').replaceAll('AM', '').trim();
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      int h = int.tryParse(parts[0]) ?? 0;
      int m = int.tryParse(parts[1]) ?? 0;
      
      if (isPM && h < 12) h += 12;
      if (isAM && h == 12) h = 0;
      return h * 60 + m;
    }
    return 0; 
  }

  bool _isOverlapping() {
    if (bookedSlots.isEmpty) return false;

    final startMinutes = startTime.hour * 60 + startTime.minute;
    int effEndMinutes = endTime.hour * 60 + endTime.minute;
    if (effEndMinutes <= startMinutes) effEndMinutes += 24 * 60; // Next day

    for (Booking booking in bookedSlots) {
      if (booking.portNumber != selectedPort) continue;

      try {
        final parts = booking.timeSlot.split('-');
        if (parts.length == 2) {
          final bStart = _parseTimeStr(parts[0]);
          var bEnd = _parseTimeStr(parts[1]);
          if (bEnd <= bStart) bEnd += 24 * 60;

          if (startMinutes < bEnd && effEndMinutes > bStart) {
            return true;
          }
        }
      } catch (e) {
        debugPrint("Skipping slot parsing error: \$e");
      }
    }
    return false;
  }

  void _onConfirmPressed() {
    if (_isTimeInPast()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cannot book a time slot in the past. Please select a future time."),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_isOverlapping()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("This time slot is already booked. Please select a different time."),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    if (endMinutes <= startMinutes && selectedDate.day == DateTime.now().day) {
       // This handles the "next day" logic but if it's today it might be confusing
       // For now, let's just ensure duration is positive and not crossing midnight if not intended
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          amount: totalPrice,
          stationName: widget.station.name,
          onPaymentSuccess: () {
            Navigator.pop(context); // Close payment screen
            _startBookingProcess();
          },
        ),
      ),
    );
  }

  Future<void> _startBookingProcess() async {
    setState(() => _status = 'requesting');

    final String timeRange = "${startTime.format(context)} - ${endTime.format(context)}";

    // Use the most unique identifier available
    final String userPhoneIdentifier = user?.phoneNumber ?? user?.email ?? '+910000000000';

    // Create booking
    final booking = Booking(
      id: "BT${DateTime.now().millisecondsSinceEpoch}",
      userId: user?.uid ?? 'U001',
      userName: user?.displayName ?? 'User',
      userPhone: userPhoneIdentifier,
      stationId: widget.station.id,
      stationName: widget.station.name,
      bookingDate: selectedDate,
      timeSlot: timeRange,
      pricePerHr: pricePerHr,
      hours: selectedHours,
      totalPrice: totalPrice,
      status: BookingStatus.accepted, // Instant acceptance
      portNumber: selectedPort,
    );

    debugPrint("DEBUG: Saving booking for $userPhoneIdentifier");

    // Save to Firestore
    final success = await _stationService.saveBooking(booking);

    if (success && mounted) {
      setState(() => _status = 'accepted');
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking failed. Please try again.')),
        );
        setState(() => _status = 'selection');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_status != 'selection') {
      return _buildStatusScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        ),
        title: FadeInDown(
          child: Text(
            'Confirm Booking',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Station Card
            FadeInUp(
              delay: const Duration(milliseconds: 100),
              child: _buildStationCard(),
            ),
            const SizedBox(height: 24),

            // Date Selection
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: _buildDateSelection(),
            ),
            const SizedBox(height: 24),

            // Port Selection
            if (widget.station.totalPorts > 1)
              FadeInUp(
                delay: const Duration(milliseconds: 250),
                child: _buildPortSelection(),
              ),
            if (widget.station.totalPorts > 1)
              const SizedBox(height: 24),

            // Charging Type Selection
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: _buildChargingTypeSelection(),
            ),
            const SizedBox(height: 24),

            // Time Selection
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: _buildTimeRangeSelection(),
            ),
            
            if (_isTimeInPast())
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: FadeIn(
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'This time slot has already passed',
                        style: GoogleFonts.outfit(
                          color: AppColors.error,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_isOverlapping())
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: FadeIn(
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This slot overlaps with an existing booking.',
                          style: GoogleFonts.outfit(
                            color: AppColors.error,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Price Summary
            FadeInUp(
              delay: const Duration(milliseconds: 500),
              child: _buildPriceSummary(),
            ),
            const SizedBox(height: 32),

            // Confirm Button
            FadeInUp(
              delay: const Duration(milliseconds: 600),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onConfirmPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    'Confirm & Pay ₹${totalPrice.toStringAsFixed(0)}',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.background,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.ev_station, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.station.name,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: AppColors.textSecondary, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.station.address,
                        style: GoogleFonts.outfit(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Date',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 30)),
              builder: (context, child) {
                return Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: AppColors.primary,
                      surface: AppColors.surface,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() => selectedDate = picked);
              _loadBookedSlots();
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Text(
                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  style: GoogleFonts.outfit(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChargingTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Charging Type',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTypeCard(
                widget.station.chargerType, 
                Icons.electrical_services, 
                'Station Standard Outlet', 
                '₹${widget.station.pricePerHr.toStringAsFixed(0)}'
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeCard(String id, IconData icon, String label, String price) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.background),
              const SizedBox(width: 8),
              Text(
                id,
                style: GoogleFonts.outfit(
                  color: AppColors.background,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$price/kWh',
            style: GoogleFonts.outfit(
              color: AppColors.background,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Port',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(widget.station.totalPorts, (index) {
              final portNumber = index + 1;
              final isSelected = selectedPort == portNumber;
              return GestureDetector(
                onTap: () => setState(() => selectedPort = portNumber),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.surfaceLight,
                    ),
                  ),
                  child: Text(
                    'Port $portNumber',
                    style: GoogleFonts.outfit(
                      color: isSelected ? AppColors.background : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeRangeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Time Range',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTimePicker('Start Time', startTime, (time) {
                setState(() => startTime = time);
                _calculateHours();
              }),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTimePicker('End Time', endTime, (time) {
                setState(() => endTime = time);
                _calculateHours();
              }),
            ),
          ],
        ),
        if (selectedHours > 0)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Total Duration: $selectedHours ${selectedHours == 1 ? 'hour' : 'hours'}',
              style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay time, Function(TimeOfDay) onPicked) {
    return GestureDetector(
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: time,
          builder: (context, child) {
            return Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: AppColors.primary,
                  surface: AppColors.surface,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              time.format(context),
              style: GoogleFonts.outfit(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.2), AppColors.secondary.withOpacity(0.2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Price per hour:',
                style: GoogleFonts.outfit(color: AppColors.textSecondary),
              ),
              Text(
                '₹${pricePerHr.toStringAsFixed(0)}',
                style: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Duration:',
                style: GoogleFonts.outfit(color: AppColors.textSecondary),
              ),
              Text(
                '$selectedHours ${selectedHours == 1 ? 'hour' : 'hours'}',
                style: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.surfaceLight),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount:',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '₹${totalPrice.toStringAsFixed(0)}',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              _buildStatusIcon(),
              const SizedBox(height: 48),
              _buildStatusText(),
              const SizedBox(height: 12),
              _buildSubText(),
              const Spacer(),
              if (_status == 'accepted') ...[
                FadeInUp(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate to dashboard and pop all screens back to home
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        'Back to Home',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.background,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (_status) {
      case 'requesting':
        return FadeIn(
          child: const SizedBox(
            height: 100,
            width: 100,
            child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 8),
          ),
        );
      case 'waiting':
        return Pulse(
          infinite: true,
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_active_rounded, size: 80, color: AppColors.accent),
          ),
        );
      case 'accepted':
        return ElasticIn(
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, size: 80, color: AppColors.success),
          ),
        );
      default:
        return Container();
    }
  }

  Widget _buildStatusText() {
    String text = '';
    switch (_status) {
      case 'requesting': text = 'Finalizing Booking...'; break;
      case 'accepted': text = 'Booking Confirmed!'; break;
    }
    return Text(
      text,
      textAlign: TextAlign.center,
      style: GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildSubText() {
    String text = '';
    switch (_status) {
      case 'requesting': text = 'Just a moment, we are securing your slot.'; break;
      case 'accepted': text = 'Your slot has been reserved. You can view it in your booking history.'; break;
    }
    return Text(
      text,
      textAlign: TextAlign.center,
      style: GoogleFonts.outfit(
        fontSize: 16,
        color: AppColors.textSecondary,
      ),
    );
  }
}
