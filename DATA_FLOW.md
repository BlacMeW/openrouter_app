# Data Flow Documentation

## Overview

This document details the complete data flow within the OpenRouter App, from user input to AI response and back. It covers the entire lifecycle of data as it moves through the application's architecture.

## High-Level Data Flow

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   User Input    │────▶│  UI Layer        │────▶│  BLoC Layer     │
│   (ChatScreen)  │     │  (Widgets)       │     │  (ChatBloc)     │
└─────────────────┘     └──────────────────┘     └─────────────────┘
                                                           │
                                                           ▼
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   AI Response   │◀────│  API Layer       │◀────│  Data Layer     │
│   (ChatScreen)  │     │  (HTTP Client)   │     │  (OpenRouter)   │
└─────────────────┘     └──────────────────┘     └─────────────────┘
```

## Detailed Data Flow

### 1. User Input Flow

#### 1.1 Text Input
**Location**: [`lib/screens/chat_screen.dart`](lib/screens/chat_screen.dart:1)

**Flow**:
1. User types in `TextField` widget
2. Text is captured in `_messageController`
3. Send button triggers `_handleSendMessage()`
4. Message is validated (non-empty check)
5. Event is dispatched to ChatBloc

```dart
// In ChatScreen
final message = _messageController.text.trim();
if (message.isNotEmpty) {
  context.read<ChatBloc>().add(SendMessage(message));
  _messageController.clear();
}
```

#### 1.2 Model Selection
**Location**: [`lib/screens/model_management_screen.dart`](lib/screens/model_management_screen.dart:1)

**Flow**:
1. User opens model selection screen
2. Available models are displayed from `AIModel.predefinedModels`
3. User selects a model
4. Selection is validated via API
5. Model is set in ChatBloc

```dart
// In ModelManagementScreen
context.read<ChatBloc>().add(SetModel(model.id));
```

### 2. BLoC Processing Flow

#### 2.1 Event Reception
**Location**: [`lib/bloc/chat_bloc.dart`](lib/bloc/chat_bloc.dart:1)

**Flow**:
1. ChatEvent arrives via `mapEventToState`
2. Event is processed in corresponding handler
3. State transitions are managed
4. Side effects are triggered

#### 2.2 Message Processing
**Location**: [`lib/bloc/chat_bloc.dart`](lib/bloc/chat_bloc.dart:1)

**Detailed Flow**:
```
SendMessage Event
    ↓
Add user message to state
    ↓
Save updated chat history
    ↓
Build API request payload
    ↓
Send HTTP POST request
    ↓
Process streaming response
    ↓
Update state with AI response
    ↓
Save final chat history
```

### 3. API Communication Flow

#### 3.1 Request Building
**Location**: [`lib/bloc/chat_bloc.dart`](lib/bloc/chat_bloc.dart:1)

**Components**:
- **URL**: `https://openrouter.ai/api/v1/chat/completions`
- **Method**: POST
- **Headers**: Authorization, Content-Type, Referrer
- **Body**: JSON payload with model and messages

#### 3.2 Streaming Response
**Location**: [`lib/bloc/chat_bloc.dart`](lib/bloc/chat_bloc.dart:1)

**Flow**:
1. Open HTTP connection with streaming enabled
2. Listen to Server-Sent Events
3. Parse each event chunk
4. Accumulate response text
5. Update UI in real-time

```dart
// Streaming response handling
final response = await client.send(request);
final stream = response.stream
    .transform(utf8.decoder)
    .transform(const LineSplitter());

await for (final line in stream) {
  if (line.startsWith('data: ')) {
    final data = line.substring(6);
    if (data != '[DONE]') {
      final jsonResponse = jsonDecode(data);
      // Process response chunk
    }
  }
}
```

### 4. State Management Flow

#### 4.1 State Transitions
**Location**: [`lib/bloc/chat_state.dart`](lib/bloc/chat_state.dart:1)

**Flow**:
```
ChatInitial
    ↓ (LoadChatHistory)
ChatLoading
    ↓ (History loaded)
ChatLoaded(messages: [...])
    ↓ (SendMessage)
ChatLoading
    ↓ (Response received)
ChatLoaded(messages: [...])
    ↓ (Error)
ChatError(message: "...", previousMessages: [...])
```

#### 4.2 State Persistence
**Location**: [`lib/bloc/chat_bloc.dart`](lib/bloc/chat_bloc.dart:1)

**Flow**:
1. State changes trigger `_saveChatHistory()`
2. Messages are serialized to JSON
3. JSON is encrypted and stored
4. Storage key: `chat_history`

### 5. Storage Flow

#### 5.1 Secure Storage
**Location**: [`lib/bloc/chat_bloc.dart`](lib/bloc/chat_bloc.dart:1)

**Data Types**:
- **API Key**: Stored under key `openrouter_api_key`
- **Chat History**: Stored under key `chat_history`
- **Theme Preference**: Stored under key `theme_mode`

#### 5.2 Serialization Flow
```dart
// Message serialization
final jsonMessages = messages.map((msg) => msg.toJson()).toList();
final jsonString = jsonEncode(jsonMessages);
await _storage.write(key: 'chat_history', value: jsonString);

// Message deserialization
final jsonString = await _storage.read(key: 'chat_history');
final jsonMessages = jsonDecode(jsonString) as List;
final messages = jsonMessages.map((json) => ChatMessage.fromJson(json)).toList();
```

### 6. Theme Data Flow

#### 6.1 Theme Selection
**Location**: [`lib/providers/theme_provider.dart`](lib/providers/theme_provider.dart:1)

**Flow**:
1. User changes theme in SettingsScreen
2. ThemeProvider updates theme mode
3. Preference is saved to SharedPreferences
4. App rebuilds with new theme

#### 6.2 Theme Application
**Location**: [`lib/themes/app_theme.dart`](lib/themes/app_theme.dart:1)

**Flow**:
```
ThemeProvider
    ↓
MaterialApp theme property
    ↓
InheritedTheme
    ↓
All widgets in the tree
```

### 7. Navigation Flow

#### 7.1 Screen Navigation
**Location**: [`lib/main.dart`](lib/main.dart:1)

**Flow**:
```
MainApp (MaterialApp)
    ↓
ChatScreen (initial route)
    ↓ (Settings button)
SettingsScreen
    ↓ (Model selection)
ModelManagementScreen
    ↓ (Back)
SettingsScreen
    ↓ (Back)
ChatScreen
```

#### 7.2 Navigation Stack
- **ChatScreen**: Always at bottom of stack
- **SettingsScreen**: Pushed on top
- **ModelManagementScreen**: Pushed on top of SettingsScreen

### 8. Error Handling Flow

#### 8.1 API Errors
**Location**: [`lib/bloc/chat_bloc.dart`](lib/bloc/chat_bloc.dart:1)

**Flow**:
```
API Error Occurs
    ↓
Catch exception
    ↓
Map to user-friendly message
    ↓
Update state to ChatError
    ↓
Display error in ChatScreen
    ↓
Allow retry or model change
```

#### 8.2 Validation Errors
**Location**: [`lib/bloc/chat_bloc.dart`](lib/bloc/chat_bloc.dart:1)

**Types**:
- **Empty Message**: Prevent sending empty messages
- **Invalid API Key**: Show configuration prompt
- **Invalid Model**: Show model selection prompt
- **Network Issues**: Show connectivity error

### 9. Real-time Updates Flow

#### 9.1 Message Streaming
**Location**: [`lib/bloc/chat_bloc.dart`](lib/bloc/chat_bloc.dart:1)

**Flow**:
```
User sends message
    ↓
Show "typing..." indicator
    ↓
Start streaming response
    ↓
Update message content in real-time
    ↓
Remove "typing..." indicator
    ↓
Message complete
```

#### 9.2 Scroll Management
**Location**: [`lib/screens/chat_screen.dart`](lib/screens/chat_screen.dart:1)

**Flow**:
1. New message added to list
2. ScrollablePositionedList scrolls to bottom
3. Smooth animation for new messages
4. Maintain scroll position during updates

### 10. Data Validation Flow

#### 10.1 Input Validation
**Location**: [`lib/screens/chat_screen.dart`](lib/screens/chat_screen.dart:1)

**Checks**:
- Message length (max 4000 characters)
- Profanity filtering (optional)
- Rate limiting (client-side)

#### 10.2 Model Validation
**Location**: [`lib/bloc/chat_bloc.dart`](lib/bloc/chat_bloc.dart:1)

**Flow**:
```
Select model
    ↓
Validate against API
    ↓
Check availability
    ↓
Update valid model list
    ↓
Notify user of invalid models
```

## Data Flow Diagrams

### Sequence Diagram: Send Message

```
User -> ChatScreen: Type message + send
ChatScreen -> ChatBloc: SendMessage(message)
ChatBloc -> Storage: Save user message
ChatBloc -> OpenRouterAPI: POST /chat/completions
OpenRouterAPI -> ChatBloc: Streaming response
ChatBloc -> ChatBloc: Process response chunks
ChatBloc -> Storage: Save AI response
ChatBloc -> ChatScreen: Update UI
ChatScreen -> User: Display response
```

### State Diagram: Chat States

```
[*] --> ChatInitial
ChatInitial --> ChatLoading : LoadChatHistory
ChatLoading --> ChatLoaded : HistoryLoaded
ChatLoaded --> ChatLoading : SendMessage
ChatLoading --> ChatLoaded : ResponseReceived
ChatLoading --> ChatError : APIError
ChatError --> ChatLoading : Retry
ChatLoaded --> [*] : ClearChat
```

## Performance Considerations

### 1. Memory Management
- **Message List**: Efficient list rendering with ScrollablePositionedList
- **Image Caching**: Automatic image caching for avatars
- **Stream Disposal**: Proper disposal of SSE streams

### 2. Network Optimization
- **Connection Reuse**: HTTP/2 connection multiplexing
- **Request Batching**: Future support for batch requests
- **Caching**: Model list cached for 5 minutes

### 3. UI Responsiveness
- **Debounced Input**: 300ms debounce for rapid typing
- **Progressive Rendering**: Messages appear as received
- **Smooth Scrolling**: 60fps scrolling animations

## Security Flow

### 1. API Key Flow
```
User enters API key
    ↓
Encrypted storage (flutter_secure_storage)
    ↓
Retrieved only by ChatBloc
    ↓
Used in Authorization header
    ↓
Never logged or exposed
```

### 2. Data Encryption
- **At Rest**: Platform-specific encryption for stored data
- **In Transit**: HTTPS for all API communications
- **In Memory**: Secure disposal of sensitive data

## Monitoring and Analytics

### 1. Usage Tracking
- **Message Count**: Per model usage
- **Response Time**: API latency tracking
- **Error Rate**: Failed request percentage

### 2. Performance Metrics
- **Memory Usage**: Monitor for memory leaks
- **Network Usage**: Track data consumption
- **Battery Usage**: Optimize for mobile devices

## Future Enhancements

### 1. Offline Support
- **Message Queue**: Store messages when offline
- **Sync Engine**: Upload when connection restored
- **Local Cache**: Cache model responses

### 2. Real-time Collaboration
- **WebSocket Support**: Bidirectional communication
- **Shared Sessions**: Multiple users in same chat
- **Presence Indicators**: Show who's typing

### 3. Advanced Features
- **File Upload**: Support for documents and images
- **Voice Messages**: Audio input/output
- **Custom Commands**: Bot commands and shortcuts