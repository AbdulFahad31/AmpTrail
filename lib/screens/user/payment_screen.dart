import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:amptrail_mini/constants/colors.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentScreen extends StatefulWidget {
  final double amount;
  final String stationName;
  final Function onPaymentSuccess;

  const PaymentScreen({
    super.key,
    required this.amount,
    required this.stationName,
    required this.onPaymentSuccess,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late Razorpay _razorpay;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment Successful!"), backgroundColor: Colors.green),
      );
      setState(() => _isProcessing = false);
      widget.onPaymentSuccess();
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Payment Failed: ${response.message ?? 'Cancelled'}"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("External Wallet Selected: ${response.walletName}")),
      );
    }
  }

  void _handlePayment() async {
    setState(() => _isProcessing = true);

    try {
      // 1. Generate Order ID using Razorpay API directly in Flutter
      // NOTE: This places the Secret in the app. For production, move this back to Firebase.
      // But for Test Mode, this avoids any GCP billing/deployment issues instantly.
      final keyId = 'rzp_test_SMPI0nhvKUesx3';
      final keySecret = 'iYoPdfRRVgSbiBPF9rKa0gHC';

      final basicAuth = 'Basic ${base64Encode(utf8.encode('$keyId:$keySecret'))}';

      final response = await http.post(
        Uri.parse('https://api.razorpay.com/v1/orders'),
        headers: <String, String>{
          'authorization': basicAuth,
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'amount': (widget.amount * 100).toInt(),
          'currency': 'INR',
          'receipt': 'receipt_${DateTime.now().millisecondsSinceEpoch}',
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to create order: ${response.body}');
      }

      final data = jsonDecode(response.body);
      final String orderId = data['id'];

      // 2. Open Razorpay Check out
      var options = {
        'key': keyId,
        'amount': (widget.amount * 100).toInt(),
        'name': 'AmpTrail',
        'order_id': orderId,
        'description': 'Booking for ${widget.stationName}',
        'timeout': 120, // in seconds
        'theme': {
          'color': '#00C853' // AppColors.primary equivalent in hex
        }
      };

      _razorpay.open(options);
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error initiating payment: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Payment',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Summary Card
            FadeInDown(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
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
                  children: [
                    Text(
                      'Total Amount',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${widget.amount.toStringAsFixed(2)}',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.stationName,
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            Text(
              'Payment Gateway',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Razorpay Unified Gateway Method
            FadeInRight(
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.security_rounded, color: AppColors.primary),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Razorpay (Secure)",
                            style: GoogleFonts.outfit(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            "UPI, Credit/Debit Cards, NetBanking",
                            style: GoogleFonts.outfit(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_circle, color: AppColors.primary),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 48),

            // Pay Button
            FadeInUp(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _handlePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                        )
                      : Text(
                          'Confirm & Pay',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
