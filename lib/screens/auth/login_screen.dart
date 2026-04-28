import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:amptrail_mini/constants/colors.dart';
import 'package:amptrail_mini/screens/auth/otp_verification_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _completePhoneNumber = '';
  bool _isLoading = false;

  void _handleLogin() async {
    HapticFeedback.lightImpact();
    if (_completePhoneNumber.isEmpty || _completePhoneNumber.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid phone number")),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _completePhoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          setState(() => _isLoading = false);
          await FirebaseAuth.instance.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message ?? 'Verification failed'),
              backgroundColor: AppColors.error,
            ),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() => _isLoading = false);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(
                phoneNumber: _completePhoneNumber,
                verificationId: verificationId,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (mounted) setState(() => _isLoading = false);
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("An error occurred. Please try again.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              FadeInDown(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withOpacity(0.1),
                      ),
                      child: const Icon(
                        Icons.ev_station_rounded,
                        size: 48,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Welcome Back',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your phone number to continue',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              FadeInUp(
                child: IntlPhoneField(
                  decoration: InputDecoration(
                    hintText: 'Phone Number',
                    hintStyle: const TextStyle(color: AppColors.textHint),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    counterText: "",
                  ),
                  initialCountryCode: 'IN',
                  style: const TextStyle(color: AppColors.textPrimary),
                  dropdownTextStyle: const TextStyle(color: AppColors.textPrimary),
                  dropdownIcon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                  onChanged: (phone) {
                    _completePhoneNumber = phone.completeNumber;
                  },
                ),
              ),
              const SizedBox(height: 24),
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: AppColors.background, strokeWidth: 2),
                        )
                      : Text(
                          'Get OTP',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.background,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 80),
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Text(
                    'By continuing, you agree to our Terms & Conditions',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
