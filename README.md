# SmartShutter - AI-Powered Photo Capture Application

A Flutter-based mobile application that uses AI to guide users in taking perfect passport photos and aesthetic self-portraits.

## Features

### 1. Passport/ID Photo Mode (Free)
- Country-specific photo guidelines (India, UK, etc.)
- Real-time compliance checking with biometric analysis
- Face detection and alignment guides
- Automated photo processing and export

### 2. Smart Solo Mode (Premium)   *(only in ui not backend connecteed)
- AI-generated pose suggestions based on preferences 
- Real-time pose guidance and framing feedback
- Automatic capture when pose is optimal
- Best shot selection and quality ranking

### 3. Gallery Management
- Filter photos by mode (Passport vs Smart Solo)
- Full-screen preview with download/share options
- Organized capture history with metadata

## Project Structure

```
ai-camera-frontend/
├── lib/
│   ├── core/
│   │   ├── providers/      # Global state management
│   │   ├── services/       # API integration
│   │   └── theme.dart      # App-wide styling
│   ├── screens/
│   │   ├── passport/       # Passport photo mode
│   │   ├── smart_solo/     # Smart Solo mode (premium)
│   │   └── tabs/           # Main navigation tabs
│   └── main.dart           # App entry point
├── assets/                 # Images and resources
└── pubspec.yaml           # Dependencies
```

## Tech Stack

- **Framework:** Flutter 3.x
- **State Management:** Provider
- **Camera:** camera package
- **Image Processing:** MediaPipe for face detection
- **Backend API:** Flask/FastAPI with biometric analysis

## Getting Started

### Prerequisites
- Flutter SDK (3.0 or higher)
- Dart 3.0+
- Android Studio / Xcode
- Camera permissions

### Installation

1. Clone the repository:
```bash
git clone https://gitlab.com/thenextgenailabs-group/smartshutter-app.git
cd smartshutter-app/ai-camera-frontend
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Configuration

Update the API base URL in `lib/core/services/api_service.dart`:
```dart
final String baseUrl = 'YOUR_BACKEND_URL';
```

## Code Documentation

All Dart files include comprehensive header comments explaining:
- **Purpose**: What the file does
- **Functionality**: Key features and responsibilities
- **Integration**: How it connects with other components
- **Usage**: When and why it's used in the app flow

## Development

### Branch Strategy
- `main` - Production-ready code
- `development` - Integration branch
- `feature/SS-XXXX_Description` - Feature branches

### Committing Code
```bash
git checkout -b feature/SS-XXXX_YourFeature
# Make changes
git add .
git commit -m "#XXXX: Your commit message"
git push origin feature/SS-XXXX_YourFeature
```

### Running Tests
```bash
flutter test
flutter analyze
```

## Architecture Highlights

- **Modular Design**: Separate screens for each mode and workflow
- **State Management**: Centralized app state with Provider pattern
- **Reusable Components**: Glassmorphic UI components in theme
- **API Integration**: Clean service layer for backend communication
- **Cross-Platform**: Works on Android, iOS, and Web

## Contributing

1. Create a feature branch from `development`
2. Make your changes with clear, descriptive commits
3. Ensure code passes `flutter analyze` with no errors
4. Test on both Android and iOS platforms
5. Create a merge request to `development` branch

## License

This project is part of the SmartShutter application suite developed by TheNextGenAI Labs.

## Support

For issues or questions, please create an issue in the GitLab repository or contact the development team.
