
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:amptrail_mini/constants/colors.dart';
import 'dart:async';

class LiveChargingScreen extends StatefulWidget {
  final String stationName;
  const LiveChargingScreen({super.key, required this.stationName});

  @override
  State<LiveChargingScreen> createState() => _LiveChargingScreenState();
}

class _LiveChargingScreenState extends State<LiveChargingScreen> {
  double _chargePercentage = 42.0;
  double _addedRange = 124.0;
  double _energyDelivered = 15.4;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          if (_chargePercentage < 100) {
            _chargePercentage += 0.1;
            _addedRange += 0.5;
            _energyDelivered += 0.05;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
                  ),
                  Text(
                    'Charging Session',
                    style: GoogleFonts.outfit(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 48), // Spacer
                ],
              ),
            ),
            
            const Spacer(),
            
            // Charging Animation Layer
            FadeIn(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Glow
                  Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.15),
                          blurRadius: 100,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                  ),
                  
                  // Progress Circle
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CircularProgressIndicator(
                      value: _chargePercentage / 100,
                      strokeWidth: 12,
                      backgroundColor: AppColors.surfaceLight,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  
                  // Percentage Text
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_chargePercentage.toStringAsFixed(0)}%',
                        style: GoogleFonts.outfit(
                          color: AppColors.textPrimary,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Charging...',
                        style: GoogleFonts.outfit(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 60),
            
            // Session Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                   _buildStat('Range Added', '${_addedRange.toStringAsFixed(0)} km', Icons.alt_route_rounded),
                   _buildStat('Energy', '${_energyDelivered.toStringAsFixed(1)} kWh', Icons.bolt_rounded),
                   _buildStat('Time Left', '45 min', Icons.timer_outlined),
                ],
              ),
            ),
            
            const Spacer(),
            
            // Station Info Card
            FadeInUp(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.surfaceLight),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.ev_station, color: AppColors.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.stationName,
                            style: GoogleFonts.outfit(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'AC Type 2 • 22 kW',
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
            ),
            
            // Stop Button
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 40),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error.withOpacity(0.1),
                    foregroundColor: AppColors.error,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.error, width: 1.5),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Stop Session',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(
            color: AppColors.textHint,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
