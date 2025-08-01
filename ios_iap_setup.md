# iOS Configuration for In-App Purchases

## Required Steps:

### 1. App Store Connect Setup
- Log into App Store Connect
- Go to your app → Features → In-App Purchases
- Create a new Non-Consumable product with ID: `unlockall`
- Set the display name, description, and price
- Add localized metadata
- Submit for review

### 2. iOS Info.plist (Already OK)
Your Info.plist looks good and doesn't need additional IAP configuration.

### 3. iOS Capabilities
Make sure In-App Purchase capability is enabled in Xcode:
- Open ios/Runner.xcworkspace in Xcode
- Select Runner project → Signing & Capabilities
- Add "In-App Purchase" capability if not present

### 4. Testing
- Use sandbox testing with test users from App Store Connect
- Test on real device (simulator doesn't support IAP)

## Product IDs to configure in App Store Connect:
- `unlockall` (Non-Consumable) - Unlock all levels permanently
