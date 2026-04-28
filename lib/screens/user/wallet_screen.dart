import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:amptrail_mini/constants/colors.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'AmpWallet',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInDown(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Balance',
                      style: GoogleFonts.outfit(
                        color: AppColors.background.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹ 1,250.00',
                      style: GoogleFonts.outfit(
                        color: AppColors.background,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        _buildQuickAction(Icons.add_rounded, 'Add Money'),
                        const SizedBox(width: 16),
                        _buildQuickAction(Icons.history_rounded, 'History'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            FadeInUp(
              child: Text(
                'Recent Transactions',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              separatorBuilder: (context, index) => const Divider(color: AppColors.surfaceLight),
              itemBuilder: (context, index) {
                final isCredit = index % 3 == 0;
                return FadeInLeft(
                  delay: Duration(milliseconds: 100 * index),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCredit ? Icons.add_circle_outline_rounded : Icons.ev_station_rounded,
                        color: isCredit ? AppColors.success : AppColors.primary,
                      ),
                    ),
                    title: Text(
                      isCredit ? 'Wallet Top-up' : 'VoltPark Central Charging',
                      style: GoogleFonts.outfit(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '24 Oct 2023, 11:30 AM',
                      style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 12),
                    ),
                    trailing: Text(
                      isCredit ? '+₹ 500' : '-₹ 120',
                      style: GoogleFonts.outfit(
                        color: isCredit ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.background, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: AppColors.background,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
