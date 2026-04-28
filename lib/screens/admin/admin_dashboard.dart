import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:amptrail_mini/constants/colors.dart';
import 'package:amptrail_mini/models/booking_model.dart';
import 'package:amptrail_mini/services/api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:amptrail_mini/screens/auth/login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final ApiService _apiService = ApiService();
  List<Booking> _pendingBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingBookings();
  }

  Future<void> _loadPendingBookings() async {
    setState(() => _isLoading = true);
    final bookings = await _apiService.getPendingBookings();
    setState(() {
      _pendingBookings = bookings;
      _isLoading = false;
    });
  }

  Future<void> _acceptBooking(String bookingId) async {
    final success = await _apiService.acceptBooking(bookingId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking accepted! User will be notified.'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadPendingBookings(); // Refresh list
    }
  }

  Future<void> _rejectBooking(String bookingId) async {
    final TextEditingController reasonController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Reject Booking',
          style: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: reasonController,
          style: const TextStyle(color: AppColors.textPrimary),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter reason for rejection...',
            hintStyle: GoogleFonts.outfit(color: AppColors.textHint),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: GoogleFonts.outfit(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await _apiService.rejectBooking(bookingId, reasonController.text);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Booking rejected. User will be notified.'),
                    backgroundColor: AppColors.error,
                  ),
                );
                _loadPendingBookings();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text('Reject', style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: FadeInDown(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.admin_panel_settings, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Text(
                'Admin Panel',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadPendingBookings,
            icon: const Icon(Icons.refresh, color: AppColors.primary),
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: AppColors.error),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _pendingBookings.isEmpty
              ? Center(
                  child: FadeIn(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 80, color: AppColors.success.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text(
                          'No pending requests',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'New booking requests will appear here',
                          style: GoogleFonts.outfit(color: AppColors.textHint),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPendingBookings,
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _pendingBookings.length,
                    itemBuilder: (context, index) {
                      final booking = _pendingBookings[index];
                      return FadeInUp(
                        delay: Duration(milliseconds: index * 100),
                        child: _buildBookingCard(booking),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.userName,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      booking.userPhone,
                      style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.warning),
                ),
                child: Text(
                  'PENDING',
                  style: GoogleFonts.outfit(
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Station Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.ev_station, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    booking.stationName,
                    style: GoogleFonts.outfit(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Booking Details
          Row(
            children: [
              Expanded(
                child: _buildInfoRow(Icons.calendar_today, 
                  '${booking.bookingDate.day}/${booking.bookingDate.month}/${booking.bookingDate.year}'),
              ),
              Expanded(
                child: _buildInfoRow(Icons.access_time, booking.timeSlot),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInfoRow(Icons.schedule, '${booking.hours} hrs'),
              ),
              Expanded(
                child: _buildInfoRow(Icons.currency_rupee, '₹${booking.totalPrice.toStringAsFixed(0)}'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _rejectBooking(booking.id),
                  icon: const Icon(Icons.close, size: 20),
                  label: Text('Reject', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _acceptBooking(booking.id),
                  icon: const Icon(Icons.check, size: 20),
                  label: Text('Accept', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 16),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
