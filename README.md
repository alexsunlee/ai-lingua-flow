# AI LinguaFlow

<p align="center">
  <strong>🎯 AI-Powered Chinese-English Learning App</strong>
</p>

<p align="center">
  An intelligent language learning tool powered by Google Gemini AI, supporting video learning, shadowing practice, vocabulary memorization, and more.
</p>

---

## ✨ Features

### 📝 Text Study
- Text import and reading
- AI-assisted content comprehension
- New word annotation and learning

### 📺 Video Study
- Import and learn from YouTube videos
- Smart content extraction for learning
- Synchronized video playback with learning content

### 🖼️ Image Study
- Image-based content recognition learning
- AI analysis of text within images

### 🗣️ Shadowing Practice
- AI-powered pronunciation assessment
- Real-time Speech-to-Text (STT)
- Text-to-Speech demonstration (TTS)
- High-quality Gemini AI-driven TTS

### 📚 Vocabulary Management
- Smart vocabulary collection and organization
- Spaced repetition review system
- Dictation practice mode
- Built-in dictionary service

### 📊 Assessment
- Comprehensive skill evaluation
- Learning progress tracking
- Personalized learning recommendations

### 🔄 Review Hub
- Unified review center
- Smart review reminders
- Learning statistics dashboard

---

## 🛠️ Tech Stack

### Core Technologies
| Category | Technology |
|----------|------------|
| **Framework** | Flutter 3.x |
| **Language** | Dart (SDK ^3.10.7) |
| **State Management** | Riverpod 2.x |
| **Dependency Injection** | GetIt + Injectable |
| **Navigation** | GoRouter |
| **AI Service** | Google Gemini API (via Dio) |

### Storage & Data
| Category | Technology |
|----------|------------|
| **Local Database** | SQLite (sqflite) |
| **Secure Storage** | Flutter Secure Storage |
| **File Paths** | path_provider |

### Media & Audio/Video
| Category | Technology |
|----------|------------|
| **Video Playback** | video_player + chewie |
| **YouTube** | youtube_explode_dart |
| **Audio Playback** | just_audio |
| **Recording** | record |
| **Speech Recognition** | speech_to_text |
| **Text-to-Speech** | flutter_tts |

### UI Components
| Category | Technology |
|----------|------------|
| **Charts** | fl_chart |
| **Loading Effects** | shimmer |
| **Image Caching** | cached_network_image |

---

## 📁 Project Structure

```
lib/
├── main.dart              # App entry point
├── app.dart               # Root App widget
├── injection.dart         # Dependency injection config
│
├── core/                  # Core modules
│   ├── constants/         # Constants definitions
│   ├── database/          # Database configuration
│   ├── error/             # Error handling
│   ├── network/           # Network layer (Gemini Client)
│   ├── router/            # Router configuration
│   ├── storage/           # Storage services
│   ├── theme/             # Theme configuration
│   ├── utils/             # Utility classes
│   └── widgets/           # Common widgets
│
├── features/              # Feature modules
│   ├── assessment/        # Skill assessment
│   ├── home/              # Home page
│   ├── image_study/       # Image-based learning
│   ├── onboarding/        # Onboarding flow
│   ├── review/            # Review hub
│   ├── settings/          # Settings
│   ├── shadowing/         # Shadowing practice
│   ├── text_study/        # Text-based learning
│   ├── video_study/       # Video-based learning
│   └── vocabulary/        # Vocabulary management
│
└── services/              # Business services
    ├── audio_service.dart
    ├── data_export_service.dart
    ├── dictionary_service.dart
    ├── gemini_tts_service.dart
    └── tts_service.dart
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK ^3.10.7
- Dart SDK ^3.10.7
- Android Studio / VS Code
- Xcode (for macOS development)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd ai-lingua-flow
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code** (Riverpod/Injectable/JSON serialization)
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Configure Gemini API

On first launch, enter your Google Gemini API key in the Settings page. The API key will be securely stored locally on your device.

Get your API key: [Google AI Studio](https://aistudio.google.com/apikey)

---

## 📱 Supported Platforms

- ✅ Android
- ✅ iOS
- ✅ macOS
- ✅ Windows
- ✅ Linux
- ✅ Web

---

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run tests with coverage report
flutter test --coverage
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🤝 Contributing

Issues and Pull Requests are welcome!

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request
