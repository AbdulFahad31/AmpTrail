# Razorpay Backend Integration Setup

Since you want to implement it the proper way (Production Approach) where the **Key ID** goes to the app and the **Key Secret** stays securely in the backend, I have set up a Firebase Functions folder for you.

## 1. Add your Razorpay API Keys

First, go to the files I created and replace the keys:
1. In `firebase_functions_setup/index.js`, find and replace:
   - `rzp_test_YOUR_KEY_ID_HERE` with your actual Test **Key ID**.
   - `YOUR_KEY_SECRET_HERE` with your actual Test **Key Secret**.
2. In `lib/screens/user/payment_screen.dart`, find and replace:
   - `rzp_test_YOUR_KEY_ID_HERE` with your actual Test **Key ID**.

## 2. Deploy the Firebase Functions

To deploy these functions securely to your Firebase backend:
1. Open your terminal in the root of your AmpTrail project (`c:/Users/abdul/AmpTrailMini/`).
2. If you haven't initialized firebase functions yet:
   ```bash
   firebase init functions
   ```
   * Choose JavaScript.
   * Do NOT overwrite `package.json` or `index.js` (you will manually copy them in step 3).
3. Copy the contents of the `firebase_functions_setup` folder that I generated into the newly created `functions` directory.
   - Run `npm install` inside the `functions` directory:
     ```bash
     cd functions
     npm install razorpay
     ```
4. Deploy the functions:
   ```bash
   firebase deploy --only functions
   ```

## 3. Test The Flow
Once deployed, the `createRazorpayOrder` function will automatically be available to your Flutter App.
When you press **Confirm & Pay**, it will call the function, retrieve a secure `order_id` generated with the Key Secret, and trigger the Razorpay popup using the Key ID!

> Note: Razorpay Test Mode allows you to complete dummy transactions via NetBanking, UPI, and Cards without actually spending real money.
