# FleetMetric

A comprehensive fleet management mobile application built with Flutter that helps track fuel consumption, vehicle maintenance, and mileage for personal and business use.

![Flutter](https://img.shields.io/badge/Flutter-3.4.3+-blue.svg)
![Dart](https://img.shields.io/badge/Dart-3.4.3+-blue.svg)
![Platform](https://img.shields.io/badge/Platform-Android-green.svg)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)

## Features

### 🚗 Vehicle Management
- Add and manage multiple vehicles
- Track vehicle details (make, model, registration)
- Automatic mileage tracking from fuel slips and service records
- View current and starting odometer readings

### ⛽ Fuel Tracking
- Capture fuel slips with camera or gallery
- OCR (Optical Character Recognition) to auto-fill receipt data
- Track fuel consumption and costs
- Calculate fuel efficiency (L/100km)
- Monitor spending patterns and forecasts

### 🔧 Maintenance Tracking
- Log service records and invoices
- Customizable maintenance intervals (km and/or days)
- Automated maintenance status indicators
- Maintenance reminders with notifications
- Track service history and costs
- AI-powered invoice data extraction (optional)

### 📊 Analytics & Dashboard
- Real-time fuel efficiency charts
- Monthly spending forecasts
- Cost per kilometer calculations
- Historical efficiency trends
- Vehicle-specific analytics

### 🔔 Smart Notifications
- Maintenance due reminders
- Configurable notification schedules
- Timezone-aware scheduling

## Screenshots

*Add screenshots of your app here*

## Tech Stack

- **Framework**: Flutter 3.4.3+
- **Language**: Dart
- **Backend**: Supabase (PostgreSQL, Authentication, Storage)
- **State Management**: Flutter BLoC
- **OCR**: Google ML Kit Text Recognition
- **AI**: Google Generative AI (Gemini) for invoice extraction
- **Notifications**: flutter_local_notifications
- **Charts**: FL Chart

## Prerequisites

- Flutter SDK (3.4.3 or higher)
- Android Studio / VS Code
- A Supabase project (free tier works)
- Android device or emulator for testing

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/fleetmetric.git
cd fleetmetric
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Supabase Setup

1. Create a new project at [supabase.com](https://supabase.com)
2. Run the SQL migrations in order:
   - `supabase/migrations/20240930_create_maintenance_tables.sql`
   - `supabase/migrations/20241005_add_current_odometer_to_vehicles.sql`
3. Get your project URL and anon/public key from Supabase settings
4. Update the credentials in `lib/main.dart`:

```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);
```

### 4. Storage Setup

In your Supabase project, create two storage buckets:
- `fuel-slips` (for fuel slip images)
- `service-invoices` (for service invoice images)

Enable RLS policies as defined in the migration files.

### 5. Run the App

```bash
flutter run
```

For Android:
```bash
flutter run -d android
```

## Building for Release

### Android APK

```bash
flutter build apk --release
```

The APK will be generated at `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (for Play Store)

```bash
flutter build appbundle --release
```

The AAB will be generated at `build/app/outputs/bundle/release/app-release.aab`

## Project Structure

```
lib/
├── models/                 # Data models
│   ├── fuel_models.dart
│   └── maintenance_models.dart
├── pages/                  # UI screens
│   ├── loginPage.dart
│   ├── register_page.dart
│   ├── vehicles_page.dart
│   ├── addfuel_slip.dart
│   ├── add_service_page.dart
│   ├── maintenance_dashboard.dart
│   └── ...
├── services/               # Business logic & API calls
│   ├── auth_service.dart
│   ├── fuel_repository.dart
│   ├── maintenance_repository.dart
│   ├── notification_service.dart
│   └── ocr_service.dart
├── repositories/           # Data access layer
│   └── maintenance_repository.dart
├── bloc/                   # State management
│   └── maintenance_bloc.dart
└── main.dart              # App entry point
```

## Configuration

### Google ML Kit OCR
- Works out of the box with default configuration
- Supports multiple languages (optimized for English)

### AI Invoice Extraction (Optional)
- Requires Google Generative AI API key
- Configure in `lib/pages/add_service_page.dart`:
```dart
const geminiApiKey = 'YOUR_GEMINI_API_KEY';
```

### Notifications
- Android permissions are automatically handled
- iOS requires user permission (handled in app)
- Timezone set to Africa/Johannesburg (configurable)

## Usage

### Adding a Vehicle
1. Navigate to Garage/Vehicles
2. Tap "Add Vehicle"
3. Enter vehicle details
4. Set starting odometer
5. Save

### Recording Fuel
1. Tap "+" on fuel section
2. Capture or select fuel slip photo
3. Review OCR-extracted data
4. Enter odometer reading
5. Save

### Tracking Maintenance
1. Navigate to vehicle's maintenance dashboard
2. Tap "+" to add service record
3. Enter service details
4. Add service items if needed
5. Save
6. Tap maintenance cards to customize intervals

## Database Schema

### Vehicles
- `id` (UUID)
- `user_id` (UUID)
- `make` (TEXT)
- `model` (TEXT)
- `registration_number` (TEXT)
- `starting_odometer` (INTEGER)
- `current_odometer` (INTEGER)

### Fuel Slips
- `id` (UUID)
- `user_id` (UUID)
- `vehicle_id` (UUID)
- `merchant_name` (TEXT)
- `transaction_date` (DATE)
- `total_amount` (DECIMAL)
- `price_per_unit` (DECIMAL)
- `volume_units` (DECIMAL)
- `odometer_reading` (INTEGER)
- `image_path` (TEXT)
- `distance_driven` (DECIMAL)
- `consumption_l_100km` (DECIMAL)

### Vehicle Services
- `id` (UUID)
- `user_id` (UUID)
- `vehicle_id` (UUID)
- `workshop_name` (TEXT)
- `invoice_date` (DATE)
- `total_amount` (DECIMAL)
- `odometer_reading` (INTEGER)
- `invoice_path` (TEXT)
- `notes` (TEXT)

### Maintenance Schedules
- `id` (UUID)
- `user_id` (UUID)
- `vehicle_id` (UUID)
- `component_name` (TEXT)
- `component_key` (TEXT)
- `interval_km` (INTEGER)
- `interval_days` (INTEGER)
- `last_service_km` (INTEGER)
- `last_service_date` (DATE)
- `next_due_km` (INTEGER)
- `next_due_date` (DATE)

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Development Guidelines

- Follow Flutter/Dart style guidelines
- Write meaningful commit messages
- Add comments for complex logic
- Test on multiple Android versions if possible
- Ensure proper error handling

## Known Issues

- Notifications may not work reliably on some Android versions
- OCR accuracy depends on receipt quality and lighting
- No offline mode - requires internet connection
- iOS version not yet available

## Roadmap

- [ ] iOS support
- [ ] Offline mode with sync
- [ ] Multi-user/team accounts
- [ ] Export reports (PDF, CSV)
- [ ] Web dashboard
- [ ] Expense categories
- [ ] Tax reporting features
- [ ] Integration with fleet management systems

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter team for the amazing framework
- Supabase for the backend-as-a-service platform
- Google ML Kit for OCR capabilities
- Google Generative AI for invoice extraction
- The open-source community

## Contact

For support, questions, or suggestions:
- Open an issue on GitHub
- Email: nmathibela2801@gmail.com

---

**Built with ❤️ using Flutter**
