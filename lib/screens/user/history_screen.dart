import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:amptrail_mini/constants/colors.dart';
import 'package:amptrail_mini/models/booking_model.dart';
import 'package:amptrail_mini/services/station_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:shimmer/shimmer.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Timer? _countdownTimer;
  final StationService _stationService = StationService();

  @override
  void initState() {
    super.initState();
    // Refresh UI every minute to update "time left" countdowns
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _deleteBooking(String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Record?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to remove this booking from your history? This action cannot be undone.',
          style: GoogleFonts.outfit(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.outfit(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Delete', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _stationService.deleteBooking(bookingId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Text('Booking removed from history', style: GoogleFonts.outfit(color: Colors.white)),
              ],
            ),
            backgroundColor: AppColors.surfaceLight,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Cancel Booking?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to cancel this booking?',
          style: GoogleFonts.outfit(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No', style: GoogleFonts.outfit(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Yes, Cancel', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _stationService.cancelBooking(bookingId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: AppColors.error, size: 20),
                const SizedBox(width: 12),
                Text('Booking cancelled', style: GoogleFonts.outfit(color: Colors.white)),
              ],
            ),
            backgroundColor: AppColors.surfaceLight,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.completed:
        return AppColors.success;
      case BookingStatus.accepted:
        return AppColors.primary;
      case BookingStatus.pending:
        return AppColors.warning;
      case BookingStatus.rejected:
        return AppColors.error;
      case BookingStatus.cancelled:
        return AppColors.textSecondary;
    }
  }

  String _getStatusText(BookingStatus status, DateTime bookingDate, String timeSlot) {
    if (status == BookingStatus.accepted) {
      try {
        final timeParts = timeSlot.split(' - ');
        if (timeParts.length >= 2) {
          final endTimeStr = timeParts.last.trim();
          final format = DateFormat("hh:mm a");
          final endTime = format.parse(endTimeStr);
          final scheduledEnd = DateTime(
            bookingDate.year,
            bookingDate.month,
            bookingDate.day,
            endTime.hour,
            endTime.minute,
          );
          final now = DateTime.now();

          if (scheduledEnd.isBefore(now)) {
            return 'Completed';
          }
        }
      } catch (e) {
        // Fallback or ignore error
      }

      final scheduledTime = _getScheduledDateTime(bookingDate, timeSlot);
      if (scheduledTime != null && scheduledTime.isAfter(DateTime.now())) {
        return 'Upcoming';
      }
    }
    switch (status) {
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.accepted:
        return 'Confirmed';
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.rejected:
        return 'Rejected';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  DateTime? _getScheduledDateTime(DateTime bookingDate, String timeSlot) {
    try {
      final timeStr = timeSlot.split(' - ').first.trim();
      final format = DateFormat("hh:mm a");
      final time = format.parse(timeStr);
      return DateTime(
        bookingDate.year,
        bookingDate.month,
        bookingDate.day,
        time.hour,
        time.minute,
      );
    } catch (e) {
      return null;
    }
  }

  String _getTimeToStart(Booking booking) {
    final scheduledTime = _getScheduledDateTime(booking.bookingDate, booking.timeSlot);
    if (scheduledTime == null) return "";
    
    final now = DateTime.now();
    if (scheduledTime.isAfter(now)) {
      final diff = scheduledTime.difference(now);
      
      if (diff.inDays > 0) {
        return "${diff.inDays} ${diff.inDays == 1 ? 'day' : 'days'} left";
      } else if (diff.inHours > 0) {
        final mins = diff.inMinutes % 60;
        if (mins > 0) {
          return "${diff.inHours}h ${mins}m left";
        }
        return "${diff.inHours} ${diff.inHours == 1 ? 'hour' : 'hours'} left";
      } else if (diff.inMinutes > 0) {
        return "${diff.inMinutes} mins left";
      } else {
        return "Starting soon";
      }
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final identifier = user?.phoneNumber ?? user?.email;
    final uid = user?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInDown(
              child: Text(
                'Booking History',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontSize: 22,
                ),
              ),
            ),
            if (identifier != null)
              FadeInDown(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  'Linked to this current user',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
          ],
        ),
        toolbarHeight: 80,
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: identifier == null && uid == null
          ? _buildLoginPrompt()
          : StreamBuilder<List<Booking>>(
              stream: _stationService.getBookingsStream(identifier ?? 'unknown', userId: uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      return Shimmer.fromColors(
                        baseColor: AppColors.surfaceLight,
                        highlightColor: AppColors.surface,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                      );
                    },
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading bookings',
                      style: GoogleFonts.outfit(color: AppColors.error),
                    ),
                  );
                }

                final bookings = snapshot.data ?? [];

                if (bookings.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    return FadeInUp(
                      delay: Duration(milliseconds: index * 100),
                      child: _buildBookingCard(booking),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Text(
        'Please login to see history',
        style: GoogleFonts.outfit(color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: FadeIn(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_outlined,
              size: 80,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No bookings yet',
              style: GoogleFonts.outfit(
                fontSize: 20,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your booking history will appear here',
              style: GoogleFonts.outfit(color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    var statusColor = _getStatusColor(booking.status);
    final statusText = _getStatusText(booking.status, booking.bookingDate, booking.timeSlot);
    if (statusText == 'Completed') {
      statusColor = AppColors.success;
    }
    final dateFormat = DateFormat('dd MMM yyyy');
    final isUpcoming = statusText == 'Upcoming';
    final timeLeft = _getTimeToStart(booking);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isUpcoming ? AppColors.primary.withOpacity(0.4) : statusColor.withOpacity(0.1),
          width: isUpcoming ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isUpcoming ? AppColors.primary : Colors.black).withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          children: [
            // Top Status Bar for Upcoming
            if (isUpcoming && timeLeft.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.15),
                      AppColors.primary.withOpacity(0.05),
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer_outlined, color: AppColors.primary, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      timeLeft.toUpperCase(),
                      style: GoogleFonts.outfit(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.ev_station, color: AppColors.primary, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    booking.stationName,
                                    style: GoogleFonts.outfit(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'ID: ${booking.id}',
                                    style: GoogleFonts.outfit(
                                      color: AppColors.textHint,
                                      fontSize: 11,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isUpcoming ? AppColors.primary : statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isUpcoming ? AppColors.primary : statusColor),
                        ),
                        child: Text(
                          statusText.toUpperCase(),
                          style: GoogleFonts.outfit(
                            color: isUpcoming ? Colors.black : statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isUpcoming || booking.status == BookingStatus.pending)
                        IconButton(
                          onPressed: () => _cancelBooking(booking.id),
                          icon: const Icon(Icons.cancel_outlined, color: AppColors.error, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Cancel booking',
                        )
                      else
                        IconButton(
                          onPressed: () => _deleteBooking(booking.id),
                          icon: const Icon(Icons.delete_outline, color: AppColors.textHint, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Delete history record',
                        ),

                    ],
                  ),
                  const SizedBox(height: 16),

                  // Details Grid
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.background.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.surfaceLight.withOpacity(0.5)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildDetailRow(Icons.calendar_today_rounded, dateFormat.format(booking.bookingDate))),
                            Expanded(child: _buildDetailRow(Icons.schedule_rounded, booking.timeSlot)),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: AppColors.surfaceLight.withOpacity(0.5), height: 1),
                        ),
                        Row(
                          children: [
                            Expanded(child: _buildDetailRow(Icons.timelapse_rounded, '${booking.hours} Hours')),
                            Expanded(child: _buildDetailRow(Icons.account_balance_wallet_rounded, '₹${booking.totalPrice.toStringAsFixed(0)}')),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Rejection reason (if rejected)
                  if (booking.status == BookingStatus.rejected && booking.rejectionReason != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error.withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.error, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Rejection Reason:',
                                  style: GoogleFonts.outfit(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  booking.rejectionReason!,
                                  style: GoogleFonts.outfit(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 16),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: GoogleFonts.outfit(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
