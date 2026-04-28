import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:amptrail_mini/constants/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:amptrail_mini/screens/auth/login_screen.dart';
import 'package:amptrail_mini/screens/user/edit_profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:amptrail_mini/screens/user/settings_screen.dart';
import 'package:amptrail_mini/screens/user/help_screen.dart';
import 'package:amptrail_mini/screens/user/privacy_screen.dart';
import 'package:amptrail_mini/services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  File? _profileImage;
  final UserService _userService = UserService();
  String _displayName = 'User';

  @override
  void initState() {
    super.initState();
    _loadLocalImage();
    _loadFirestoreData();
  }

  Future<void> _loadFirestoreData({bool forceRefresh = false}) async {
    final profile = await _userService.getUserProfile(forceRefresh: forceRefresh);
    if (profile != null && profile['name'] != null) {
      if (mounted) {
        setState(() {
          _displayName = profile['name'];
        });
      }
    } else {
      setState(() {
        _displayName = user?.displayName ?? 'User';
      });
    }
  }

  Future<void> _loadLocalImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profile_image_${user.uid}');
    if (imagePath != null && File(imagePath).existsSync()) {
      setState(() {
        _profileImage = File(imagePath);
      });
    }
  }

  Future<void> _refreshUser() async {
    await user?.reload();
    await _loadLocalImage();
    await _loadFirestoreData(forceRefresh: true);
    setState(() {
      user = FirebaseAuth.instance.currentUser;
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // Unused dialog items removed for clarity

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.electric_bolt, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Text(
              'About AmpTrail',
              style: GoogleFonts.outfit(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AmpTrail is a smart EV charging station booking app that helps you find, book, and manage charging slots effortlessly.',
              style: GoogleFonts.outfit(color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 20),
            _buildInfoRow('Version', '1.0.0'),
            const SizedBox(height: 12),
            _buildInfoRow('Developed by', 'AmpTrail Team'),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.copyright, color: AppColors.primary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '2025 AmpTrail. All rights reserved.',
                      style: GoogleFonts.outfit(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(color: AppColors.textHint, fontSize: 14),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Terms & Conditions',
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Acceptance of Terms',
                style: GoogleFonts.outfit(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'By using AmpTrail, you agree to these terms and conditions.',
                style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 16),
              Text(
                '2. Service Usage',
                style: GoogleFonts.outfit(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'AmpTrail provides a platform to book EV charging slots. Actual charging services are provided by station owners.',
                style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 16),
              Text(
                '3. User Responsibilities',
                style: GoogleFonts.outfit(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Users must provide accurate information and arrive on time for confirmed bookings.',
                style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 16),
              Text(
                '© 2025 AmpTrail. All rights reserved.',
                style: GoogleFonts.outfit(color: AppColors.textHint, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Unused notification settings removal

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: FadeInDown(
          child: Text(
            'Profile',
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
          children: [
            const SizedBox(height: 20),
            
            // Profile Picture & Name
            FadeInDown(
              delay: const Duration(milliseconds: 200),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: AppColors.surface,
                      backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                      child: _profileImage == null 
                        ? Text(
                            _displayName.isNotEmpty ? _displayName[0].toUpperCase() : 'U',
                            style: GoogleFonts.outfit(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _displayName,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.phoneNumber ?? 'Not logged in',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Statistics section removed
            
            const SizedBox(height: 12),
            
            const SizedBox(height: 32),

            // Account Settings Section
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: _buildSection(
                'Account Settings',
                [
                  _buildMenuItem(Icons.person_outline, 'Edit Profile', () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                    );
                    _refreshUser();
                  }),
                  _buildMenuItem(Icons.settings_outlined, 'Settings', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  }),
                  _buildMenuItem(Icons.security_outlined, 'Privacy & Security', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PrivacyScreen()),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // App Settings Section
            FadeInUp(
              delay: const Duration(milliseconds: 600),
              child: _buildSection(
                'App Settings',
                [
                  _buildMenuItem(Icons.help_outline, 'Help & Support', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HelpScreen()),
                    );
                  }),
                  _buildMenuItem(Icons.info_outline, 'About', _showAboutDialog),
                  _buildMenuItem(Icons.policy_outlined, 'Terms & Conditions', _showTermsDialog),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Logout Button
            FadeInUp(
              delay: const Duration(milliseconds: 800),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: Text(
                    'Logout',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Version & Copyright
            Column(
              children: [
                Text(
                  'Version 1.0.0',
                  style: GoogleFonts.outfit(
                    color: AppColors.textHint,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '© 2025 AmpTrail Team',
                  style: GoogleFonts.outfit(
                    color: AppColors.textHint,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceLight),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  // Unused stat item removal
}
