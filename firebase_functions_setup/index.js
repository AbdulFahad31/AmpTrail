const functions = require("firebase-functions");
const admin = require("firebase-admin");
const Razorpay = require("razorpay");
const crypto = require("crypto");

admin.initializeApp();

// IMPORTANT: Do NOT hardcode secrets in a real production app.
// Instead use Firebase Secrets: 
// 1. firebase functions:secrets:set RAZORPAY_KEY_ID
// 2. firebase functions:secrets:set RAZORPAY_KEY_SECRET
// 3. And use process.env.RAZORPAY_KEY_ID and process.env.RAZORPAY_KEY_SECRET

const RAZORPAY_KEY_ID = process.env.RAZORPAY_KEY_ID || (functions.config().razorpay ? functions.config().razorpay.key_id : "");
const RAZORPAY_KEY_SECRET = process.env.RAZORPAY_KEY_SECRET || (functions.config().razorpay ? functions.config().razorpay.key_secret : "");

const razorpay = new Razorpay({
    key_id: RAZORPAY_KEY_ID,
    key_secret: RAZORPAY_KEY_SECRET,
});

/**
 * createRazorpayOrder
 * Callable function from Flutter app to generate a valid Razorpay Order ID.
 */
exports.createRazorpayOrder = functions.https.onCall(async (data, context) => {
    try {
        // Enforce user authentication
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated to create a payment order.');
        }

        // 2. Safely get the amount (in paise, so rs 100 = 10000)
        const amount = data.amount;

        if (!amount || amount <= 0) {
            throw new functions.https.HttpsError('invalid-argument', 'Amount must be greater than 0');
        }

        // 3. Create the order from Razorpay
        const options = {
            amount: amount, // Amount in the smallest currency sub-unit
            currency: "INR",
            receipt: `receipt_${Date.now()}`
        };

        const order = await razorpay.orders.create(options);

        // 4. Return order id and details to flutter app
        return {
            id: order.id,
            amount: order.amount,
            currency: order.currency
        };
    } catch (error) {
        console.error("Error creating Razorpay Order:", error);
        throw new functions.https.HttpsError("internal", error.message || "Failed to create order");
    }
});

/**
 * verifyPayment
 * Callable function from Flutter app after successful payment to verify signature
 */
exports.verifyPayment = functions.https.onCall(async (data, context) => {
    try {
        const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = data;

        // Secret must match the generated signature
        const secret = RAZORPAY_KEY_SECRET;

        const hmac = crypto.createHmac("sha256", secret);
        hmac.update(razorpay_order_id + "|" + razorpay_payment_id);
        const generated_signature = hmac.digest("hex");

        if (generated_signature === razorpay_signature) {
            // Payment Verified
            // Here you could update your Firebase Database / Firestore:
            // eg: admin.firestore().collection('bookings').doc('SOME_ID').update({ status: 'Paid' });

            return { success: true, message: "Payment verified successfully" };
        } else {
            throw new functions.https.HttpsError("invalid-argument", "Payment signature verification failed");
        }
    } catch (error) {
        console.error("Error verifying payment:", error);
        throw new functions.https.HttpsError("internal", error.message || "Failed to verify payment");
    }
});
