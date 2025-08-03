# OpenRouter App Architecture Documentation

## Overview

The OpenRouter App is a Flutter-based AI chat application that provides a unified interface for interacting with multiple AI models through the OpenRouter API. The application follows clean architecture principles with a focus on maintainability, scalability, and user experience.

## Architecture Overview

The application follows a **Layered Architecture** pattern with the following key components:

- **Presentation Layer**: Flutter widgets and screens
- **Business Logic Layer**: BLoC pattern for state management
- **Data Layer**: Models and API integration
- **Infrastructure Layer**: Storage and configuration

## Technology Stack

### Core Framework
- **Flutter**: 3.8.1+ (Cross-platform UI framework)
- **Dart**: SDK 3.8.1+

### State Management
- **flutter_bloc**: ^8.1.3 (BLoC pattern implementation)
- **bloc**: ^8.1.4 (Core BLoC library)
- **provider**: ^6.1.1 (Theme and dependency management)

### API & Networking
- **http**: ^1.1.0 (HTTP client for API calls)
- **Server-Sent Events (SSE)**: Real-time streaming responses

### Storage & Persistence
- **flutter_secure_storage**: ^9.0.0 (Secure API key storage)
- **shared_preferences**: ^2.2.2 (Theme preferences)
- **path_provider**: ^2.1.1 (File system access)

### UI & Styling
- **flutter_markdown**: ^0.7.7+1 (Markdown rendering)
- **flutter_highlight**: ^0.7.0 (Syntax highlighting)
- **scrollable_positioned_list**: ^0.3.8 (Efficient list scrolling)

### Utilities
- **equatable**: ^2.0.5 (Value equality for BLoC states)
- **intl**: ^0.19.0 (Internationalization)

## Project Structure

```
lib/
├── bloc/
│   ├── chat_bloc.dart          # Core business logic
│   ├── chat_event.dart         # Event definitions
│   └── chat_state.dart         # State definitions
├── models/
│   ├── chat_message.dart       # Message data model
│   └── ai_model.dart          # AI model configuration
├── screens/
│   ├── chat_screen.dart       # Main chat interface
│   ├── settings_screen.dart   # Settings and configuration
│   └── model_management_screen.dart  # Model selection
├── providers/
│   └── theme_provider.dart    # Theme management
├── themes/
│   └── app_theme.dart         # Theme definitions
└── main.dart                  # Application entry point
```

## Data Models

### ChatMessage
Located in [`lib/models/chat_message.dart`](lib/models/chat_message.dart:1)

**Purpose**: Represents individual chat messages in the conversation

**Properties**:
- `id`: Unique identifier (String)
- `content`: Message text content (String)
- `isUser`: Whether message is from user (bool)
- `timestamp`: Message creation time (DateTime)
- `model`: AI model identifier (String, nullable)

**Serialization**:
- JSON serialization/deserialization support
- Used for chat history persistence

### AIModel
Located in [`lib/models/ai_model.dart`](lib/models/ai_model.dart:1)

**Purpose**: Configuration for AI models available through OpenRouter

**Properties**:
- `id`: Model identifier (String)
- `name`: Display name (String)
- `description`: Model description (String)
- `contextLength`: Maximum context length (int)
- `pricing`: Cost per token (Map<String, dynamic>)
- `isFree`: Whether model is free to use (bool)

**Features**:
- Pre-configured with 20+ free models
- Includes models from Google, Meta, Mistral, and other providers
- Built-in model validation system

## State Management Architecture

### BLoC Pattern Implementation

The application uses the **BLoC (Business Logic Component)** pattern for state management:

#### ChatBloc
Located in [`lib/bloc/chat_bloc.dart`](lib/bloc/chat_bloc.dart:1)

**Responsibilities**:
- Manage chat state and messages
- Handle API communication with OpenRouter
- Process streaming responses
- Manage chat history persistence
- Handle error states and recovery

**Key Methods**:
- `mapEventToState`: Event processing pipeline
- `_handleSendMessage`: Message sending and streaming
- `_loadChatHistory`: Restore previous conversations
- `_saveChatHistory`: Persist current conversation
- `_validateModel`: Check model availability

#### Events (ChatEvent)
Located in [`lib/bloc/chat_event.dart`](lib/bloc/chat_event.dart:1)

**Event Types**:
- `SendMessage`: Send new message to AI
- `LoadChatHistory`: Load previous conversation
- `ClearChat`: Clear current conversation
- `SetModel`: Change active AI model
- `ValidateModel`: Check if model is available

#### States (ChatState)
Located in [`lib/bloc/chat_state.dart`](lib/bloc/chat_state.dart:1)

**State Types**:
- `ChatInitial`: Initial empty state
- `ChatLoading`: Loading/processing state
- `ChatLoaded`: Active conversation state
- `ChatError`: Error state with details

## API Integration

### OpenRouter API Integration

**Base URL**: `https://openrouter.ai/api/v1`

**Endpoints**:
- `POST /chat/completions`: Send messages and receive responses
- `GET /models`: List available models (for validation)

### Authentication
- API keys stored securely using `flutter_secure_storage`
- Keys never exposed in UI or logs
- Configurable via Settings screen

### Request/Response Flow

1. **User Input** → ChatScreen
2. **Event Dispatch** → ChatBloc (SendMessage event)
3. **API Call** → OpenRouter API with streaming
4. **Stream Processing** → Real-time response handling
5. **State Update** → ChatLoaded with new messages
6. **UI Update** → ChatScreen re-renders with new content

### Error Handling

**HTTP Status Codes**:
- `401`: Invalid API key
- `403`: Insufficient credits
- `404`: Model not found
- `429`: Rate limit exceeded
- `500`: Server errors

**Recovery Strategies**:
- Automatic retry with exponential backoff
- User-friendly error messages
- Model validation before sending

## User Interface Architecture

### Screen Navigation

**Main Screens**:
1. **ChatScreen** (`lib/screens/chat_screen.dart:1`)
   - Primary chat interface
   - Message display with markdown support
   - Input field with send functionality
   - Model indicator and settings access

2. **SettingsScreen** (`lib/screens/settings_screen.dart:1`)
   - API key configuration
   - Theme selection (light/dark/system)
   - Chat history management

3. **ModelManagementScreen** (`lib/screens/model_management_screen.dart:1`)
   - Model selection from 20+ options
   - Model descriptions and capabilities
   - Real-time model validation

### Theme System

**ThemeProvider** (`lib/providers/theme_provider.dart:1`)
- Manages theme state using Provider pattern
- Supports light, dark, and system themes
- Persists theme preference using SharedPreferences

**AppTheme** (`lib/themes/app_theme.dart:1`)
- Comprehensive Material 3 theme definitions
- Light and dark theme variants
- Consistent color scheme and typography
- Responsive design considerations

## Data Flow Architecture

### Complete Data Flow

```
User Action
    ↓
Widget (Presentation Layer)
    ↓
ChatEvent (BLoC Layer)
    ↓
ChatBloc (Business Logic)
    ↓
HTTP Client (Data Layer)
    ↓
OpenRouter API
    ↓
Stream Response
    ↓
ChatState (BLoC Layer)
    ↓
Widget Rebuild (Presentation Layer)
    ↓
Updated UI
```

### Storage Flow

```
Chat Messages
    ↓
JSON Serialization
    ↓
flutter_secure_storage
    ↓
Encrypted Local Storage
    ↓
JSON Deserialization
    ↓
Restored Chat State
```

## Security Architecture

### API Key Management
- **Storage**: flutter_secure_storage with platform-specific secure storage
- **Access**: Only accessed by ChatBloc for API calls
- **UI**: Never displayed in plain text
- **Configuration**: User-configurable via Settings screen

### Data Privacy
- **Local Storage**: All chat history stored locally
- **No Cloud Sync**: No data sent to external servers except OpenRouter API
- **Encryption**: Platform-level encryption for stored data

## Performance Considerations

### Optimizations
- **List Rendering**: scrollable_positioned_list for efficient message list
- **Image Caching**: Built-in Flutter image caching
- **State Updates**: Minimal widget rebuilds with BLoC
- **Memory Management**: Proper disposal of streams and controllers

### Streaming Architecture
- **Real-time Updates**: SSE for immediate response display
- **Progressive Rendering**: Messages appear as they're generated
- **Cancellation Support**: Ability to cancel ongoing requests

## Testing Strategy

### Unit Testing
- BLoC logic testing with bloc_test
- Model serialization testing
- API response parsing testing

### Integration Testing
- End-to-end chat flow testing
- API integration testing
- Storage persistence testing

### Widget Testing
- UI component testing
- Theme switching testing
- Navigation flow testing

## Deployment Considerations

### Platform Support
- **iOS**: Full support with secure storage
- **Android**: Full support with secure storage
- **Web**: Full support with web storage
- **Desktop**: macOS, Windows, Linux support

### Build Configuration
- **Release Mode**: Optimized for production
- **Obfuscation**: Code obfuscation enabled
- **Shrinking**: Tree shaking for minimal bundle size

## Future Enhancements

### Planned Features
- **Multi-language Support**: Internationalization with intl package
- **Voice Input**: Speech-to-text integration
- **Image Support**: Multi-modal chat capabilities
- **Chat Export**: Conversation export functionality
- **Model Comparison**: Side-by-side model testing

### Architecture Improvements
- **Repository Pattern**: Separate data layer abstraction
- **Dependency Injection**: Service locator pattern
- **Offline Support**: Local model caching
- **Analytics**: Usage tracking and insights

## Development Guidelines

### Code Style
- **Dart Style Guide**: Follows official Dart style guide
- **Linting**: flutter_lints for consistent code style
- **Formatting**: dart format for consistent formatting

### Git Workflow
- **Branching**: Feature branch workflow
- **Commits**: Conventional commits format
- **Reviews**: Pull request reviews required

### Documentation
- **Code Comments**: Comprehensive inline documentation
- **API Documentation**: OpenAPI specification for API layer
- **User Documentation**: In-app help and tooltips