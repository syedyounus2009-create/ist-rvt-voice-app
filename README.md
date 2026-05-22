# 🌍 IST-RVT — Real-Time Voice Translator

> **Speak Any Language, Anywhere** — Production-grade real-time voice translation platform with voice preservation, WebRTC calls, and offline support.

[![Python](https://img.shields.io/badge/Backend-FastAPI-009688?style=flat-square&logo=fastapi)](backend/)
[![Flutter](https://img.shields.io/badge/Mobile-Flutter-02569B?style=flat-square&logo=flutter)](mobile_app/)
[![License](https://img.shields.io/badge/License-Proprietary-red?style=flat-square)]()

---

## ⚡ Features

| Feature | Description |
|---------|-------------|
| 🎙️ **Real-Time Voice Translation** | <300ms latency — VAD → STT → Translation → TTS pipeline |
| 🗣️ **Voice Preservation** | XTTS-v2 cloning or pitch-shifted Edge TTS to match your voice |
| 📵 **Offline Mode** | On-device translation via Google MLKit (no internet needed) |
| 📞 **Voice & Video Calls** | WebRTC-based P2P calls with live translated captions |
| 💬 **Translated Chat** | Send text/voice messages — auto-translated in real-time |
| 🌐 **15+ Languages** | English, Arabic, Chinese, Urdu, French, Spanish, German, Hindi, and more |
| 🔐 **JWT Auth** | Secure registration, login, and session management |
| 📊 **Admin Dashboard** | Live monitoring of rooms, users, and system health |

---

## 🏗️ Architecture

```
IST-RVT/
├── backend/              # FastAPI Python backend
│   ├── main.py           # App entry point
│   ├── config.py         # Environment-based settings
│   ├── database.py       # SQLAlchemy async (SQLite/PostgreSQL)
│   ├── models/           # User, Message, CallSession ORM models
│   ├── routers/          # REST API: auth, translate, calls, contacts
│   ├── services/         # AI pipeline: STT, Translation, TTS, VoicePipeline
│   ├── websocket/        # Real-time audio & signaling WebSocket handlers
│   ├── Dockerfile        # Production container image
│   └── requirements.txt  # Python dependencies
├── mobile_app/           # Flutter mobile application
│   ├── lib/
│   │   ├── main.dart             # App entry
│   │   ├── app.dart              # GoRouter navigation + theme
│   │   ├── core/                 # Theme, colors, constants, utils
│   │   ├── data/                 # Models, services (audio, WebSocket)
│   │   ├── providers/            # State management (auth, translation, call)
│   │   └── presentation/        # Screens + widgets
│   └── pubspec.yaml
├── admin/                # Admin dashboard (HTML/CSS/JS)
│   └── index.html
├── docker-compose.yml    # Local dev stack
└── README.md
```

---

## 🚀 Quick Start

### Prerequisites
- **Python 3.11+** (backend)
- **Flutter 3.16+** (mobile app)
- **ffmpeg** (audio processing)

### 1. Backend Setup

```bash
cd backend

# Create virtual environment
python -m venv venv
# Windows
venv\Scripts\activate
# Linux/macOS
source venv/bin/activate

# Install dependencies
pip install --extra-index-url https://download.pytorch.org/whl/cpu -r requirements.txt

# Configure environment
copy .env.example .env   # Windows
# cp .env.example .env   # Linux/macOS

# Run server
python main.py
```

Backend starts at `http://localhost:8000` — API docs at `http://localhost:8000/docs`

### 2. Flutter Mobile App

```bash
cd mobile_app

# Get dependencies
flutter pub get

# Run on connected device / emulator
flutter run
```

> **Note:** Update `AppConstants.useCloud` in `lib/core/constants/app_constants.dart` to switch between local and cloud backend.

### 3. Admin Dashboard

Open `admin/index.html` in a browser while the backend is running. It auto-connects to `localhost:8000`.

---

## 🐳 Docker Deployment

### Local (Docker Compose)
```bash
docker-compose up --build
```

### Cloud (Railway / Render)
1. Push the `backend/` directory to a Git repo
2. Connect to Railway/Render
3. Set environment variables from `.env.example`
4. Deploy — the `Dockerfile` handles everything

---

## 🔌 API Reference

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/auth/register` | Create account |
| POST | `/api/v1/auth/login` | Login → JWT token |
| GET | `/api/v1/auth/me` | Current user profile |
| POST | `/api/v1/translate/text` | Translate text (+ optional TTS) |
| POST | `/api/v1/translate/voice` | Upload audio → transcribe → translate |
| POST | `/api/v1/translate/voice-profile` | Upload voice sample for cloning |
| GET | `/api/v1/translate/languages` | List supported languages |
| POST | `/api/v1/calls/initiate` | Start a call → get room ID |
| GET | `/api/v1/calls/history` | Call history |
| GET | `/api/v1/contacts/search?query=` | Search users |
| WS | `/ws/audio/{room_id}` | Real-time audio translation |
| WS | `/ws/signal/{room_id}` | WebRTC signaling |

---

## ⚙️ Configuration

All settings via environment variables (see `backend/.env.example`):

| Variable | Default | Description |
|----------|---------|-------------|
| `WHISPER_MODEL` | `small` | STT model: tiny, base, small, medium, large-v3 |
| `DEVICE` | `cpu` | Processing device: cpu or cuda |
| `TTS_ENGINE` | `edge` | TTS: edge (free), gtts, or xtts (GPU) |
| `VOICE_CLONE_ENABLED` | `false` | Enable XTTS-v2 voice cloning |
| `DATABASE_URL` | `sqlite+aiosqlite:///./ist_rvt.db` | Database connection |
| `SECRET_KEY` | — | JWT signing key (CHANGE IN PRODUCTION) |

---

## 📱 Mobile App Screens

- **Splash** — Animated logo with auto-navigation
- **Onboarding** — 4-page intro with language selection
- **Login / Register** — JWT-based auth with gradient UI
- **Home** — Bottom nav: Translator, Contacts, History, Settings
- **Translator** — Real-time voice translation with waveform visualizer
- **Voice/Video Call** — WebRTC calls with live translated captions
- **Chat** — Text/voice messaging with auto-translation
- **Contacts** — User search and contact management
- **History** — Call logs with duration and latency stats
- **Settings** — Language preferences, voice profile, theme

---

## 🧠 AI Pipeline

```
Audio In (100ms chunks)
    ↓
Silero VAD (voice activity detection)
    ↓
faster-whisper STT (int8 quantized, CPU-optimized)
    ↓
argostranslate (offline) / Google Translate (fallback)
    ↓
Edge TTS (300+ voices) / XTTS-v2 (voice cloning)
    ↓
Audio Out (translated speech)
```

**Target Latency:** ~300ms on CPU, ~150ms on GPU

---

## 📄 License

Proprietary — IST-RVT © 2026. All rights reserved.
