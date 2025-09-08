# VayuDrishti - ISRO Satellite Air Quality Monitor

**Tagline:** *Swasth Jeevan ki Shrishti!*

A modern Flutter mobile application that provides satellite-driven Air Quality Monitoring with an intuitive UI/UX. The app leverages ISRO satellite data and various air quality APIs to deliver real-time, hyperlocal air quality insights.

## 🌟 Features

### ✅ Splash Screen

- Beautiful gradient background with satellite theme
- App logo with satellite icon
- Animated progress bar with "Initializing satellite connection..." text
- Smooth transitions to authentication screens

### ✅ Authentication System

- **Login Screen:** Email/password authentication with "Forgot Password" functionality
- **Signup Screen:** User registration with name, email, and password
- Firebase Authentication integration
- Consistent purple/indigo gradient theme
- Form validation and error handling

### ✅ Home Dashboard

- **Welcome Section:** Personalized greeting with user's name
- **Real-time AQI Display:** Current Air Quality Index with color-coded indicators
- **Pollutants Grid:** Detailed breakdown of PM2.5, PM10, CO, NO2, O3, SO2 levels
- **Quick Forecast:** 24-hour AQI forecast preview
- **Health Recommendations:** Personalized suggestions based on current AQI levels

### ✅ Navigation & Screens

- **Bottom Navigation Bar:** Home, Map, Forecast, Profile tabs
- **Map Screen:** Placeholder for interactive AQI heatmap (coming soon)
- **Forecast Screen:** Detailed hourly/daily AQI predictions with charts
- **Profile Screen:** User management and app settings

### ✅ Modern UI Components

- Clean, card-based layout design
- Gradient backgrounds and smooth animations
- Color-coded AQI indicators (Green=Good, Red=Hazardous)
- Custom widgets for reusability
- Dark theme optimized for air quality monitoring

## 🛠️ Tech Stack

- **Frontend:** Flutter & Dart
- **State Management:** Provider
- **Authentication:** Firebase Authentication
- **Database:** Firebase Firestore
- **Charts:** FL Chart package
- **Location:** Geolocator package
- **HTTP Requests:** Dio/HTTP packages
- **Maps:** Google Maps (planned integration)

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (latest version)
- Android Studio / VS Code
- Firebase project setup (optional for development)

### Installation

1. **Clone the repository:**

```bash
git clone <repository-url>
cd vayu_drishti
```

2. **Install dependencies:**

```bash
flutter pub get
```

3. **Configure Firebase (Optional):**
   - Create a Firebase project
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Update Firebase configuration in `firebase_options.dart`

4. **Add API Keys:**
   - Get OpenWeatherMap API key for air quality data
   - Update `AppConstants.openWeatherMapApiKey` in `lib/core/constants/app_constants.dart`

5. **Run the app:**

```bash
flutter run
```

## 🌍 Air Quality Data Sources

- **Primary:** OpenWeatherMap Air Pollution API
- **Backup:** Mock data with realistic AQI values
- **Future:** Integration with CPCB and ISRO satellite data

## 📊 Air Quality Index Categories

| AQI Range | Category | Color | Health Implications |
|-----------|----------|--------|-------------------|
| 0-50 | Good | Green | Ideal for outdoor activities |
| 51-100 | Fair | Yellow | Acceptable for most people |
| 101-150 | Moderate | Orange | Sensitive groups should limit exposure |
| 151-200 | Poor | Red | Everyone should avoid outdoor activities |
| 201-300 | Very Poor | Purple | Health warnings of emergency conditions |
| 301+ | Hazardous | Maroon | Emergency conditions for all |

## 📱 App Structure

```txt
lib/
├── core/
│   ├── constants/      # App constants and configurations
│   ├── models/         # Data models
│   ├── providers/      # State management
│   ├── services/       # API and external service calls
│   └── theme/          # App theming and styles
├── screens/
│   ├── auth/           # Authentication screens
│   ├── home/           # Main app screens
│   └── splash_screen.dart
├── widgets/            # Reusable UI components
└── main.dart          # App entry point
```

---

**VayuDrishti** - Powered by ISRO Technology 🛰️

*Making air quality monitoring accessible to everyone, everywhere.*
