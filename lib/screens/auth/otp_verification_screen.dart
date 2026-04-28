import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:amptrail_mini/constants/colors.dart';
import 'package:amptrail_mini/screens/user/user_dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'dart:async';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int _secondsRemaining = 90;
  Timer? _timer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  void _startTimer() {
    setState(() => _secondsRemaining = 90);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) return;
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // 1. Authenticate with Firebase
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otp,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      debugPrint("DEBUG: Auth Successful: ${userCredential.user?.uid}");
      
      // 2. Fire and forget Firestore save - do NOT await it
      // This prevents Permission Denied errors from hanging the UI
      FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'stations31')
          .collection('users')
          .doc(userCredential.user?.phoneNumber)
          .set({
        'phone': userCredential.user?.phoneNumber,
        'lastLogin': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).catchError((e) {
        debugPrint("DEBUG: Background Firestore Error (ignored): $e");
      });

      if (!mounted) return;
      
      // Haptic feedback for successful verification
      HapticFeedback.mediumImpact();
      
      setState(() => _isLoading = false);

      // 3. Forced Navigation with Smooth Transition
      debugPrint("DEBUG: Navigating to Dashboard...");
      
      // Close keyboard before navigating for a smoother look
      FocusScope.of(context).unfocus();
      
      // Give a tiny moment for keyboard and state to settle
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const UserDashboard(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
          (route) => false,
        );
      });

    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Invalid OTP'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint("DEBUG: Unexpected Error: $e");
        // Even for unexpected errors, if we have a user, let them in
        if (FirebaseAuth.instance.currentUser != null) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const UserDashboard()),
            (route) => false,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              FadeInDown(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verify Phone',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Code sent to ${widget.phoneNumber}',
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
                child: PinCodeTextField(
                  appContext: context,
                  length: 6,
                  controller: _otpController,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.number,
                  autoFocus: true,
                  textStyle: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(16),
                    fieldHeight: 60,
                    fieldWidth: 46,
                    activeFillColor: AppColors.surface,
                    inactiveFillColor: AppColors.surface,
                    selectedFillColor: AppColors.surface,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.surfaceLight,
                    selectedColor: AppColors.primary,
                    borderWidth: 2,
                  ),
                  enableActiveFill: true,
                  onCompleted: (value) => _verifyOtp(),
                  onChanged: (value) {},
                ),
              ),

              const SizedBox(height: 32),
              
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: Center(
                  child: _secondsRemaining > 0
                      ? Text(
                          'Resend code in ${_secondsRemaining ~/ 60}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}',
                          style: GoogleFonts.outfit(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        )
                      : TextButton(
                          onPressed: () {
                            _startTimer();
                          },
                          child: Text(
                            'Resend Code',
                            style: GoogleFonts.outfit(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 32),

              FadeInUp(
                delay: const Duration(milliseconds: 300),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
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
                          'Verify',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.background,
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