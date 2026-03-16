# Smart Billing & Sales Management App

This project upgrades the existing billing app into a universal offline-first Smart Billing & Sales Management App for small businesses.

Supported business types:
- Tea Shop
- Restaurant
- Salon / Barber Shop
- Juice Shop
- Bakery
- Street Vendor

## What is implemented

1. Business Type Setup
- First-time setup includes business type selection.
- App auto-loads default items/services based on selected business type.
- Users can add/edit custom items in inventory.

2. Modern Dashboard (Material UI)
- Today total sales
- Total orders
- Top selling item
- Quick Add Bill action
- Payment split and smart insights

3. Fast Billing
- Tap products to add to bill
- Quantity and discounts
- Auto total calculation
- Quick billing flow with large tappable controls

4. Payment Options
- Cash
- UPI QR code
- UPI ID used for QR: `shanmuga007@oksbi`

5. Bill History
- Local SQLite storage for all bills
- Daily/date-range filtering
- Search by invoice, customer, and items

6. Salon Customer Records
- Enabled for Salon business type
- Store customer name, service, and visit history
- Auto-save salon service visits from completed bills

7. Sales Analytics
- Daily sales chart (last 7 days)
- Most sold items
- Revenue and order metrics

8. Smart Insights (Hackathon Feature)
- Example insights:
	- Most sold item today
	- Peak sales hour
	- Average order value

9. Export Features
- CSV export (orders, products, expenses, customers)
- PDF export for sales report

10. Offline First
- Fully local data using SQLite
- No internet required for billing flow

11. UI Improvements
- Material Design 3
- Dark mode support
- Cleaner cards, chips, and action flows

12. Performance
- Fast local reads/writes
- Builder-based lists/grids for smooth scrolling
- Light state updates through provider

## Updated project structure (key files)

```text
lib/
	models/
		business_profile_model.dart
		business_type.dart                # new
		salon_visit_model.dart            # new
	screens/
		billing_screen.dart
		bill_summary_screen.dart
		dashboard_screen.dart
		data_export_screen.dart
		business_profile_screen.dart
		sales_analytics_screen.dart       # new
		salon_customers_screen.dart       # new
	services/
		app_state.dart
		database_service.dart
	utils/
		business_templates.dart           # new
```

## Run locally

```bash
flutter pub get
flutter run
```

## Generate branded icon and native splash

Brand asset used:

```text
assets/branding/app_icon.png
```

After changing this image, regenerate resources:

```bash
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Build Android release APK

From project root:

```bash
flutter clean
flutter pub get
flutter build apk --release
```

## Android release signing (production)

1. Generate keystore:

```bash
keytool -genkey -v -keystore android/app/release-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias release
```

2. Create file `android/key.properties`:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=release
storeFile=release-keystore.jks
```

3. Ensure `android/app/build.gradle.kts` reads `key.properties` and applies a `release` signingConfig.

4. Build signed APK:

```bash
flutter build apk --release
```

5. Optional signed AAB for Play Store:

```bash
flutter build appbundle --release
```

Generated APK path:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Optional split per ABI (smaller APKs):

```bash
flutter build apk --release --split-per-abi
```

## Notes for hackathon demo

- First launch: choose business type and continue.
- Show fast billing flow: add items and complete payment in a few taps.
- Open dashboard and analytics to demonstrate insights.
- Export CSV and PDF reports from Export Data screen.
