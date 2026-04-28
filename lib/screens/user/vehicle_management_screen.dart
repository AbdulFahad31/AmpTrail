
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:amptrail_mini/constants/colors.dart';
import 'package:amptrail_mini/models/vehicle_model.dart';

class VehicleManagementScreen extends StatefulWidget {
  const VehicleManagementScreen({super.key});

  @override
  State<VehicleManagementScreen> createState() => _VehicleManagementScreenState();
}

class _VehicleManagementScreenState extends State<VehicleManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'My Vehicles',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: myVehicles.length,
                itemBuilder: (context, index) {
                  final vehicle = myVehicles[index];
                  return FadeInLeft(
                    delay: Duration(milliseconds: 100 * index),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.surfaceLight),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.directions_car_filled_rounded, color: AppColors.primary, size: 32),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${vehicle.brand} ${vehicle.model}',
                                      style: GoogleFonts.outfit(
                                        color: AppColors.textPrimary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      vehicle.licensePlate,
                                      style: GoogleFonts.outfit(
                                        color: AppColors.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(color: AppColors.surfaceLight),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildInfoChip(Icons.flash_on_rounded, vehicle.connectorType.name.toUpperCase()),
                              _buildInfoChip(Icons.battery_charging_full_rounded, '${vehicle.batteryCapacity} kWh'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  'Add New Vehicle',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
