# OpenRouter API Integration Guide

## Overview

This document provides comprehensive details about the OpenRouter API integration within the Flutter application, including authentication, endpoints, request/response formats, and error handling.

## API Configuration

### Base Configuration
- **Base URL**: `https://openrouter.ai/api/v1`
- **API Version**: v1
- **Authentication**: Bearer token in Authorization header
- **Content-Type**: application/json

### Authentication Setup
API keys are managed through the Settings screen and stored securely using `flutter_secure_storage`. The key is never exposed in the UI and is only accessed by the ChatBloc for making API calls.

## API Endpoints

### Chat Completions
**Endpoint**: `POST /chat/completions`
**Purpose**: Send messages to AI models and receive responses

#### Request Format
```json
{
  "model": "google/gemini-flash-1.5",
  "messages": [
    {
      "role": "user",
      "content": "Hello, how are you?"
    }
  ],
  "stream": true,
  "max_tokens": 4000
}
```

#### Request Headers
```http
Authorization: Bearer YOUR_API_KEY
Content-Type: application/json
HTTP-Referer: https://your-app-domain.com
X-Title: OpenRouter App
```

#### Response Format (Streaming)
The API returns Server-Sent Events (SSE) for streaming responses:

```
data: {"choices":[{"delta":{"content":"Hello"}}]}
data: {"choices":[{"delta":{"content":" there"}}]}
data: [DONE]
```

### Model Validation
**Endpoint**: `GET /models`
**Purpose**: Validate model availability and retrieve model information

#### Response Format
```json
{
  "data": [
    {
      "id": "google/gemini-flash-1.5",
      "name": "Google Gemini Flash 1.5",
      "context_length": 1000000,
      "pricing": {
        "prompt": "0.00000015",
        "completion": "0.0000006"
      }
    }
  ]
}
```

## Implementation Details

### ChatBloc Integration

The API integration is handled within [`lib/bloc/chat_bloc.dart`](lib/bloc/chat_bloc.dart:1) with the following key components:

#### HTTP Client Setup
```dart
final client = http.Client();
final request = http.Request('POST', Uri.parse('$baseUrl/chat/completions'))
  ..headers.addAll({
    'Authorization': 'Bearer $apiKey',
    'Content-Type': 'application/json',
    'HTTP-Referer': 'https://openrouter.ai',
    'X-Title': 'OpenRouter App',
  });
```

#### Streaming Response Handling
The application uses Server-Sent Events for real-time response streaming:

1. **Stream Initialization**: Opens HTTP connection with streaming enabled
2. **Event Processing**: Parses SSE events as they arrive
3. **Message Assembly**: Builds complete response from stream chunks
4. **State Updates**: Updates ChatState with new messages
5. **Error Handling**: Manages connection failures and API errors

#### Request Building
```dart
final body = {
  'model': currentModel,
  'messages': messages.map((msg) => {
    'role': msg.isUser ? 'user' : 'assistant',
    'content': msg.content,
  }).toList(),
  'stream': true,
  'max_tokens': 4000,
};
```

## Error Handling

### HTTP Status Codes

| Status | Description | Handling Strategy |
|--------|-------------|-------------------|
| 200 | Success | Process response normally |
| 401 | Unauthorized | Show "Invalid API Key" message |
| 403 | Forbidden | Show "Insufficient Credits" message |
| 404 | Not Found | Show "Model Not Found" message |
| 429 | Rate Limited | Show "Rate Limit Exceeded" message |
| 500 | Server Error | Show "Server Error" with retry option |

### Error Response Format
```json
{
  "error": {
    "message": "Invalid API key",
    "type": "authentication_error"
  }
}
```

### Retry Logic
The application implements exponential backoff for failed requests:
- Initial retry: 1 second
- Maximum retries: 3
- Backoff multiplier: 2x

## Model Configuration

### Available Models
The application supports 20+ free models from various providers:

#### Google Models
- `google/gemini-flash-1.5` - Fast, efficient model
- `google/gemini-pro-1.5` - More capable, slower

#### Meta Models
- `meta-llama/llama-3.1-8b-instruct` - Open source model
- `meta-llama/llama-3.1-70b-instruct` - Larger variant

#### Mistral Models
- `mistralai/mistral-7b-instruct` - Efficient 7B model
- `mistralai/mixtral-8x7b-instruct` - Mixture of experts

#### Anthropic Models
- `anthropic/claude-3-haiku` - Fast, cost-effective
- `anthropic/claude-3.5-sonnet` - Advanced reasoning

### Model Validation
Before sending requests, the application validates model availability:

```dart
Future<bool> validateModel(String modelId) async {
  final response = await http.get(
    Uri.parse('$baseUrl/models'),
    headers: {'Authorization': 'Bearer $apiKey'},
  );

  if (response.statusCode == 200) {
    final models = jsonDecode(response.body)['data'];
    return models.any((model) => model['id'] == modelId);
  }
  return false;
}
```

## Rate Limiting

### OpenRouter Limits
- **Free Tier**: 20 requests per minute
- **Paid Tier**: Higher limits based on subscription
- **Burst Limits**: Temporary spikes allowed

### Client-Side Throttling
The application implements client-side rate limiting:
- Request queuing for rapid user input
- Debounced input handling
- Visual feedback during rate limiting

## Security Considerations

### API Key Security
- **Storage**: Encrypted using platform-specific secure storage
- **Transmission**: Always sent over HTTPS
- **Validation**: Never logged or exposed in error messages
- **Rotation**: Support for key rotation without app restart

### Request Security
- **HTTPS Only**: All API calls use HTTPS
- **Header Validation**: Custom headers for tracking
- **Referrer Policy**: Proper referrer headers set

## Performance Optimization

### Connection Management
- **HTTP/2**: Uses HTTP/2 for multiplexing
- **Connection Pooling**: Reuses connections when possible
- **Timeout Handling**: Configurable timeouts for requests

### Caching Strategy
- **Model List**: Cached for 5 minutes
- **Response Streaming**: No caching for real-time responses
- **Error Responses**: Cached briefly to prevent spam

### Monitoring
- **Request Metrics**: Track API latency and success rates
- **Error Tracking**: Log and categorize API errors
- **Usage Analytics**: Monitor model usage patterns

## Testing

### Unit Tests
- **Request Building**: Verify correct request format
- **Response Parsing**: Test SSE parsing logic
- **Error Handling**: Verify error scenarios

### Integration Tests
- **End-to-End Flow**: Test complete chat flow
- **Model Validation**: Test model availability checks
- **Error Recovery**: Test retry mechanisms

### Mock API
For development and testing:
```dart
class MockOpenRouterApi implements OpenRouterApi {
  @override
  Future<Stream<String>> sendMessage(String message) async {
    // Return mock response stream
  }
}
```

## Troubleshooting

### Common Issues

#### "Invalid API Key"
- Verify key is correctly entered in Settings
- Check for extra spaces or characters
- Ensure key has proper permissions

#### "Model Not Found"
- Verify model ID is correct
- Check if model is still available
- Try refreshing model list

#### "Rate Limit Exceeded"
- Wait for rate limit reset
- Consider upgrading OpenRouter plan
- Implement client-side throttling

#### "Network Error"
- Check internet connection
- Verify firewall settings
- Try different network

### Debug Mode
Enable debug logging by setting:
```dart
const bool kDebugMode = true;
```

This will log:
- All API requests and responses
- SSE events for debugging
- Error details and stack traces

## Future Enhancements

### Planned Features
- **Batch Requests**: Support for batch API calls
- **WebSocket Support**: Real-time bidirectional communication
- **Custom Models**: Support for fine-tuned models
- **Usage Analytics**: Detailed usage reporting

### API Versioning
- **Version Detection**: Automatic API version detection
- **Backward Compatibility**: Handle API changes gracefully
- **Feature Flags**: Enable/disable features based on API version