import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:amptrail_mini/utils/theme_provider.dart';
import 'package:amptrail_mini/constants/colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    // Determine colors based on theme
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final surfaceColor = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.outfit(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Notifications Section
            _buildSectionHeader('Notifications', textColor),
            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(
                      'Push Notifications',
                      style: GoogleFonts.outfit(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Get updates on your booking status',
                      style: GoogleFonts.outfit(
                        color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    value: _notificationsEnabled,
                    activeThumbColor: AppColors.primary,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                    },
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: GoogleFonts.outfit(
            color: color.withOpacity(0.7),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
