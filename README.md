# OpenRouter App

A Flutter-based AI chat application that provides unified access to 20+ AI models through the OpenRouter API. Chat with different AI models, compare their responses, and manage your conversations all in one place.

![App Screenshot](docs/screenshot.png)

## Features

- **🤖 Multiple AI Models**: Access 20+ AI models from Google, Meta, Mistral, Anthropic, and more
- **💬 Real-time Chat**: Stream responses in real-time with Server-Sent Events
- **🎨 Modern UI**: Beautiful Material 3 design with light and dark themes
- **🔒 Secure Storage**: API keys and chat history stored securely
- **📱 Cross-platform**: Works on iOS, Android, Web, and Desktop
- **⚡ Fast Performance**: Optimized for smooth scrolling and quick responses
- **🔄 Model Comparison**: Easily switch between models to compare responses

## Quick Start

### 1. Get Your API Key
1. Visit [openrouter.ai](https://openrouter.ai)
2. Create an account or sign in
3. Go to Settings → API Keys
4. Generate a new API key

### 2. Install the App
- **Mobile**: Download from App Store or Google Play
- **Web**: Visit [app.openrouter.ai](https://app.openrouter.ai)
- **Desktop**: Download from [releases](https://github.com/your-org/openrouter-app/releases)

### 3. Start Chatting
1. Open the app
2. Enter your API key in settings
3. Select a model
4. Start chatting!

## Available Models

| Model | Provider | Best For | Free |
|-------|----------|----------|------|
| Gemini Flash 1.5 | Google | Quick answers | ✅ |
| Llama 3.1 8B | Meta | General chat | ✅ |
| Mistral 7B | Mistral | Balanced performance | ✅ |
| Claude 3.5 Sonnet | Anthropic | Complex reasoning | ❌ |
| Gemini Pro 1.5 | Google | Advanced tasks | ❌ |

[View all models →](docs/MODELS.md)

## Installation

### Prerequisites
- Flutter 3.8.1+
- Dart 3.8.1+
- Git

### Development Setup
```bash
# Clone the repository
git clone https://github.com/your-org/openrouter-app.git
cd openrouter-app

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Platform-Specific Setup

#### iOS
```bash
cd ios && pod install
```

#### Android
```bash
# No additional setup required
```

#### Web
```bash
flutter run -d chrome
```

## Usage

### Basic Usage
1. **Enter API Key**: Go to settings and add your OpenRouter API key
2. **Select Model**: Tap the model name to browse available models
3. **Start Chatting**: Type your message and press send
4. **Switch Models**: Change models anytime to compare responses

### Advanced Features
- **Model Comparison**: Ask the same question to different models
- **Conversation History**: All chats are automatically saved
- **Theme Switching**: Toggle between light and dark themes
- **Keyboard Shortcuts**: Use Ctrl+Enter to send messages (desktop)

## Documentation

- **[User Guide](USER_GUIDE.md)**: Complete guide for end users
- **[Development Guide](DEVELOPMENT_GUIDE.md)**: Setup and development instructions
- **[Architecture](ARCHITECTURE.md)**: Technical architecture overview
- **[API Integration](API_INTEGRATION.md)**: API documentation and integration details
- **[Data Flow](DATA_FLOW.md)**: Complete data flow documentation

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Quick Contribution Steps
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run integration tests
flutter drive --target=test_driver/app.dart
```

## Building for Production

### Mobile
```bash
# iOS
flutter build ios --release

# Android
flutter build apk --release
flutter build appbundle --release
```

### Web
```bash
flutter build web --release
```

### Desktop
```bash
# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

## Performance

The app is optimized for:
- **Fast startup**: < 2 seconds on modern devices
- **Smooth scrolling**: 60 FPS with large message lists
- **Low memory usage**: Efficient memory management
- **Battery optimization**: Minimal background usage

## Security

- **API Key Security**: Stored using platform-specific secure storage
- **HTTPS Only**: All API calls use encrypted connections
- **No Data Tracking**: Conversations stay on your device
- **Input Validation**: All user input is sanitized

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| "Invalid API Key" | Check your OpenRouter API key is correct |
| "Model Not Found" | Try a different model from the list |
| "Rate Limit Exceeded" | Wait a few minutes or upgrade your plan |
| "Network Error" | Check your internet connection |

[View full troubleshooting guide →](USER_GUIDE.md#troubleshooting)

## Support

- **Documentation**: Check our [docs](docs/)
- **Issues**: [GitHub Issues](https://github.com/your-org/openrouter-app/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-org/openrouter-app/discussions)
- **Discord**: [Join our Discord](https://discord.gg/openrouter-app)

## Roadmap

- [ ] Voice input/output support
- [ ] File upload capabilities
- [ ] Conversation sharing
- [ ] Custom model fine-tuning
- [ ] Plugin system
- [ ] Team collaboration features

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- **OpenRouter** for providing the unified AI API
- **Flutter Team** for the amazing framework
- **Contributors** who helped make this app better

---

**Made with ❤️ by the OpenRouter App team**

[⬆ Back to top](#openrouter-app)
