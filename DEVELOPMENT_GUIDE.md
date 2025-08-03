# Development Guide

## Overview

This guide is for developers who want to contribute to or understand the OpenRouter App codebase. It covers setup, architecture, coding standards, and deployment processes.

## Prerequisites

### Required Software
- **Flutter**: 3.8.1 or higher
- **Dart**: 3.8.1 or higher
- **Git**: For version control
- **IDE**: VS Code, Android Studio, or IntelliJ IDEA

### Recommended Extensions
- **Flutter**: Official Flutter extension
- **Dart**: Official Dart extension
- **GitLens**: Git superpowers
- **Error Lens**: Inline error highlighting

## Project Setup

### 1. Clone the Repository
```bash
git clone https://github.com/your-org/openrouter-app.git
cd openrouter-app
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Environment Configuration
Create a `.env` file in the root directory:
```env
OPENROUTER_API_KEY=your_development_api_key_here
```

### 4. Run the App
```bash
# Development
flutter run

# Web
flutter run -d chrome

# iOS Simulator
flutter run -d iphone

# Android Emulator
flutter run -d android
```

## Project Structure

```
openrouter-app/
├── lib/
│   ├── bloc/                    # Business Logic Components
│   │   ├── chat_bloc.dart      # Main chat logic
│   │   ├── chat_event.dart     # Event definitions
│   │   └── chat_state.dart     # State definitions
│   ├── models/                 # Data models
│   │   ├── chat_message.dart   # Message model
│   │   └── ai_model.dart      # AI model configuration
│   ├── screens/               # UI screens
│   │   ├── chat_screen.dart   # Main chat interface
│   │   ├── settings_screen.dart  # Settings
│   │   └── model_management_screen.dart  # Model selection
│   ├── providers/             # State providers
│   │   └── theme_provider.dart  # Theme management
│   ├── themes/               # Theme definitions
│   │   └── app_theme.dart    # Material 3 themes
│   └── main.dart            # App entry point
├── test/                    # Test files
├── docs/                    # Documentation
└── pubspec.yaml            # Dependencies
```

## Architecture Overview

The app follows **Clean Architecture** with these layers:

1. **Presentation Layer**: Flutter widgets and screens
2. **Business Logic Layer**: BLoC pattern for state management
3. **Data Layer**: Models and API integration
4. **Infrastructure Layer**: Storage and configuration

## Key Components

### BLoC Architecture

#### ChatBloc ([`lib/bloc/chat_bloc.dart`](lib/bloc/chat_bloc.dart:1))
- **Purpose**: Central business logic for chat functionality
- **Responsibilities**:
  - API communication with OpenRouter
  - Message state management
  - Error handling and recovery
  - Chat history persistence

#### Events ([`lib/bloc/chat_event.dart`](lib/bloc/chat_event.dart:1))
- `SendMessage`: Send new message to AI
- `LoadChatHistory`: Restore previous conversation
- `ClearChat`: Start fresh conversation
- `SetModel`: Change active AI model
- `ValidateModel`: Check model availability

#### States ([`lib/bloc/chat_state.dart`](lib/bloc/chat_state.dart:1))
- `ChatInitial`: Empty state
- `ChatLoading`: Processing state
- `ChatLoaded`: Active conversation
- `ChatError`: Error with recovery options

### Data Models

#### ChatMessage ([`lib/models/chat_message.dart`](lib/models/chat_message.dart:1))
```dart
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? model;
}
```

#### AIModel ([`lib/models/ai_model.dart`](lib/models/ai_model.dart:1))
```dart
class AIModel {
  final String id;
  final String name;
  final String description;
  final int contextLength;
  final Map<String, dynamic> pricing;
  final bool isFree;
}
```

## Development Workflow

### 1. Feature Development
```bash
# Create feature branch
git checkout -b feature/your-feature-name

# Make changes
# Test thoroughly
# Commit with conventional commits
git commit -m "feat: add new feature description"

# Push and create PR
git push origin feature/your-feature-name
```

### 2. Testing Strategy

#### Unit Tests
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/chat_bloc_test.dart

# Run with coverage
flutter test --coverage
```

#### Widget Tests
```bash
# Run widget tests
flutter test test/widget_test.dart
```

#### Integration Tests
```bash
# Run integration tests
flutter drive --target=test_driver/app.dart
```

### 3. Code Quality

#### Linting
```bash
# Check code style
flutter analyze

# Auto-fix issues
dart fix --apply
```

#### Formatting
```bash
# Format all files
dart format .

# Check formatting
dart format --output=none --set-exit-if-changed .
```

## API Integration

### OpenRouter API
- **Base URL**: `https://openrouter.ai/api/v1`
- **Authentication**: Bearer token
- **Streaming**: Server-Sent Events (SSE)

### Key API Methods

#### Send Message
```dart
Future<void> sendMessage(String message, String model) async {
  final response = await http.post(
    Uri.parse('$baseUrl/chat/completions'),
    headers: {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'model': model,
      'messages': [{'role': 'user', 'content': message}],
      'stream': true,
    }),
  );
}
```

## Error Handling

### Error Types
- **NetworkError**: Connection issues
- **AuthenticationError**: Invalid API key
- **RateLimitError**: Too many requests
- **ModelError**: Model unavailable
- **ValidationError**: Invalid input

### Error Recovery
```dart
try {
  await sendMessage(message, model);
} on NetworkError {
  // Retry with exponential backoff
} on AuthenticationError {
  // Prompt for API key
} on RateLimitError {
  // Show rate limit message
}
```

## Security Best Practices

### API Key Management
- **Storage**: Use `flutter_secure_storage`
- **Never commit**: Add to `.gitignore`
- **Environment variables**: Use for development

### Data Protection
- **Encryption**: All stored data encrypted
- **HTTPS only**: All API calls use HTTPS
- **Input validation**: Sanitize all user input

## Performance Optimization

### 1. List Performance
- **scrollable_positioned_list**: Efficient for large lists
- **Item extent**: Fixed height items for better performance
- **Lazy loading**: Load messages as needed

### 2. Memory Management
- **Dispose streams**: Always close SSE streams
- **Image caching**: Use Flutter's built-in caching
- **State cleanup**: Proper disposal in dispose()

### 3. Network Optimization
- **Connection pooling**: Reuse HTTP connections
- **Request debouncing**: Prevent rapid requests
- **Caching**: Cache model lists for 5 minutes

## Debugging

### 1. Flutter DevTools
```bash
# Start DevTools
flutter pub global run devtools

# Connect to app
flutter run --debug
```

### 2. Logging
```dart
// Debug logging
debugPrint('Debug message');

// Error logging
log('Error message', error: error, stackTrace: stackTrace);
```

### 3. Breakpoints
- **VS Code**: Click left gutter
- **Android Studio**: Click left gutter
- **Conditional breakpoints**: Right-click breakpoint

## Deployment

### 1. Mobile Deployment

#### iOS
```bash
# Build for App Store
flutter build ios --release

# Upload to App Store
open ios/Runner.xcworkspace
```

#### Android
```bash
# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release
```

### 2. Web Deployment
```bash
# Build for web
flutter build web --release

# Deploy to hosting
firebase deploy
```

### 3. Desktop Deployment
```bash
# Build for desktop
flutter build windows
flutter build macos
flutter build linux
```

## Environment Configuration

### Development
```bash
# Development environment
flutter run --debug

# With hot reload
flutter run --hot
```

### Staging
```bash
# Staging environment
flutter run --flavor staging
```

### Production
```bash
# Production build
flutter build --release
```

## Contributing Guidelines

### 1. Code Style
- **Dart style guide**: Follow official Dart conventions
- **Flutter lint**: Use flutter_lints package
- **Consistent formatting**: Use dart format

### 2. Commit Messages
Follow conventional commits:
```
feat: add new feature
fix: resolve bug
docs: update documentation
style: formatting changes
refactor: code restructuring
test: add tests
chore: maintenance tasks
```

### 3. Pull Request Process
1. **Create feature branch**
2. **Write tests** for new features
3. **Update documentation**
4. **Ensure CI passes**
5. **Request review** from team members

## Monitoring and Analytics

### 1. Performance Monitoring
- **Flutter Performance**: Built-in performance overlay
- **Memory usage**: Monitor for leaks
- **Network monitoring**: Track API latency

### 2. Crash Reporting
```dart
// Add crash reporting
FirebaseCrashlytics.instance.recordError(error, stackTrace);
```

### 3. Usage Analytics
```dart
// Track user interactions
FirebaseAnalytics.instance.logEvent(
  name: 'chat_message_sent',
  parameters: {'model': modelId},
);
```

## Troubleshooting

### Common Issues

#### Build Issues
```bash
# Clean build
flutter clean
flutter pub get

# Update dependencies
flutter pub upgrade
```

#### iOS Issues
```bash
# Update pods
cd ios && pod install && cd ..

# Clean iOS build
cd ios && xcodebuild clean && cd ..
```

#### Android Issues
```bash
# Clean Android build
cd android && ./gradlew clean && cd ..
```

### Getting Help
- **Flutter docs**: [flutter.dev/docs](https://flutter.dev/docs)
- **Stack Overflow**: Tag with `flutter`
- **GitHub Issues**: Create detailed issue reports

## Resources

### Documentation
- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Documentation](https://dart.dev/guides)
- [BLoC Library](https://bloclibrary.dev)

### Tools
- [Flutter DevTools](https://docs.flutter.dev/tools/devtools)
- [Dart DevTools](https://dart.dev/tools/dart-devtools)
- [Firebase Console](https://console.firebase.google.com)

### Community
- [Flutter Community](https://flutter.dev/community)
- [Reddit r/FlutterDev](https://reddit.com/r/FlutterDev)
- [Discord Flutter Community](https://discord.gg/flutter)