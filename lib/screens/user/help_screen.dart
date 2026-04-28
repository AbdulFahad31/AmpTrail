import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:amptrail_mini/constants/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final surfaceColor = Theme.of(context).cardColor;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Help & Support', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.support_agent_rounded, size: 60, color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Need Assistance?',
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Our support team is available 24/7 to help you with any issues.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(color: textColor.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 24),
                  ListTile(
                    leading: const Icon(Icons.email_outlined, color: AppColors.primary),
                    title: Text('Email Us', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: textColor)),
                    subtitle: Text('amptrail.devteam@gmail.com', style: GoogleFonts.outfit(color: textColor.withOpacity(0.7))),
                    onTap: () async {
                      final Uri emailUri = Uri(
                        scheme: 'mailto',
                        path: 'amptrail.devteam@gmail.com',
                        queryParameters: {'subject': 'Support Request'},
                      );
                      if (await canLaunchUrl(emailUri)) {
                        await launchUrl(emailUri);
                      }
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.phone_outlined, color: AppColors.primary),
                    title: Text('Call Us', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: textColor)),
                    subtitle: Text('+91 7539934156 / 9600781450', style: GoogleFonts.outfit(color: textColor.withOpacity(0.7))),
                    onTap: () {
                      _showCallDialog(context, textColor, surfaceColor);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCallDialog(BuildContext context, Color textColor, Color surfaceColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Number',
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 24),
            _buildCallOption(context, '+91 7539934156', textColor),
            const SizedBox(height: 16),
            _buildCallOption(context, '+91 9600780150', textColor),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCallOption(BuildContext context, String number, Color textColor) {
    return InkWell(
      onTap: () async {
        final Uri telUri = Uri(scheme: 'tel', path: number.replaceAll(' ', ''));
        if (await canLaunchUrl(telUri)) {
          await launchUrl(telUri);
        }
        if (context.mounted) Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.phone_rounded, color: AppColors.primary),
            const SizedBox(width: 16),
            Text(number, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
