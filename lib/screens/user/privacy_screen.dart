import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Privacy & Security', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSection(
              context,
              'Data Usage',
              'We only use your location to find nearby stations. Your data is encrypted and secure.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              'Third Party Access',
              'We do not share your data with third parties unless required by law.',
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              'Account Security',
              'Your account is protected by industry-standard authentication protocols.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.outfit(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
