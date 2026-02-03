# 📱 VILO - Vietnamese Chat App

> "Private chat, no trace"

## 🎯 About

VILO is an ultra-lightweight, secure messaging app for Vietnamese users. Built with native technologies for maximum performance.

### Core Philosophy
- **Ultra Light**: < 10MB app size (vs Zalo ~150MB)
- **Ultra Smooth**: 60fps, < 100ms message delivery
- **Simple**: Minimal features, maximum UX

### Key Features (MVP)
- ✅ Phone + OTP authentication
- ✅ 1-on-1 encrypted chat
- ✅ Text, emoji, and image messages
- ✅ End-to-end encryption (E2EE)
- ✅ No server-side message storage

## 🛠 Tech Stack

| Component | Technology |
|-----------|------------|
| iOS | Swift 5.9 + SwiftUI |
| Android | Kotlin + Jetpack Compose |
| Backend | Node.js + Fastify + TypeScript |
| Database | PostgreSQL (Supabase) |
| Cache | Redis (Upstash) |
| Encryption | CryptoKit (iOS) / Tink (Android) |

## 📁 Project Structure

```
vilo/
├── ios/            # Swift iOS App
├── android/        # Kotlin Android App
├── server/         # Node.js Backend
└── docs/           # Documentation
```

## 🎨 Brand Colors

| Color | Hex | Usage |
|-------|-----|-------|
| 🔴 Red | #DA251D | Primary (Vietnamese flag) |
| 🟡 Yellow | #FFCD00 | Secondary (Golden star) |
| ⚫ Dark | #0D0D0D | Background |

## 🚀 Getting Started

### Prerequisites
- Xcode 15+ (for iOS)
- Node.js 20+
- Git

### Setup
```bash
# Clone repository
git clone https://github.com/yourusername/vilo.git
cd vilo

# Setup backend
cd server
npm install
npm run dev

# iOS (open in Xcode)
open ios/Vilo.xcodeproj
```

## 📄 License

Private - All rights reserved

---

*Built with ❤️ for Vietnamese users*
