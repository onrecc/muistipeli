# Android Configuration for In-App Purchases

## Required Steps:

### 1. Google Play Console Setup

- Log into Google Play Console
- Go to your app → Monetize → Products → In-app products  
- Create a new product with ID: `unlockall`
- Set it as "Non-consumable" 
- Set the display name, description, and price
- Activate the product

### 2. Android Permissions (Already configured)

Your app already has the correct permissions in the manifest through the in_app_purchase plugin.

### 3. Google Play Billing

The in_app_purchase plugin automatically handles Google Play Billing setup.

### 4. Testing

- Upload a signed APK to Google Play Console (Internal Testing track)
- Add test users in Google Play Console → Settings → License Testing  
- Test with real Google accounts on real devices
- Use test cards provided by Google Play Console

### 5. App Signing

Make sure your app is properly signed:
- You already have signing configured in `android/app/build.gradle.kts`
- Your `key.properties` file should contain your signing keys

## Product IDs to configure in Google Play Console

- `unlockall` (Non-Consumable) - Unlock all levels permanently

## Important Notes

- In-app products must be published along with your app
- Test purchases are automatically refunded in testing
- Production purchases are real transactions
