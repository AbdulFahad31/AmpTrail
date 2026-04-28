import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:amptrail_mini/constants/colors.dart';
import 'package:amptrail_mini/screens/auth/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:amptrail_mini/screens/user/user_dashboard.dart';
import 'package:amptrail_mini/screens/admin/admin_dashboard.dart';
import 'package:amptrail_mini/services/station_service.dart';
import 'package:amptrail_mini/services/user_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginState();
  }

  void _checkLoginState() async {
    // Minimum duration to show splash animation
    final minDelay = Future.delayed(const Duration(seconds: 2));

    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      // Preload critical data into memory cache during splash screen
      try {
        await Future.wait([
          StationService().getStations(),
          UserService().getUserProfile(),
          minDelay,
        ]);
      } catch (e) {
        debugPrint("Preload error: $e");
      }
      
      if (!mounted) return;

      // Check if admin (Mock Implementation based on existing code)
      if (user.phoneNumber == '+911234567890') {
         Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, anim, secAnim) => const AdminDashboard(),
            transitionsBuilder: (context, anim, secAnim, child) => FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, anim, secAnim) => const UserDashboard(),
            transitionsBuilder: (context, anim, secAnim, child) => FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    } else {
      await minDelay;
      
      if (!mounted) return;
      
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, anim, secAnim) => const LoginScreen(),
          transitionsBuilder: (context, anim, secAnim, child) => FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeInDown(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.1),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: const Icon(
                  Icons.electric_bolt_rounded,
                  size: 60,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeInUp(
              child: Text(
                'AmpTrail',
                style: GoogleFonts.outfit(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 10),
            FadeInUp(
              delay: const Duration(milliseconds: 500),
              child: Text(
                'Charge Smarter.',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  letterSpacing: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
