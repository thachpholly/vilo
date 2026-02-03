# CLAUDE.md - VILO Project Guide

## Project Overview

VILO is an ultra-lightweight, secure messaging app for Vietnamese users. Built with native technologies for maximum performance.

**Philosophy**: Ultra Light (< 10MB) | Ultra Smooth (60fps) | Simple

## Tech Stack

- **iOS**: Swift 5.9 + SwiftUI + CryptoKit (E2EE)
- **Android**: Kotlin + Jetpack Compose (future)
- **Backend**: Node.js 20 + Fastify + TypeScript
- **Database**: PostgreSQL (Supabase)
- **Cache**: Redis (Upstash)
- **Auth**: Phone + OTP (Twilio)

## Project Structure

```
vilo/
├── ios/Vilo/              # Swift iOS App
│   ├── App/               # ViloApp.swift, AppColors.swift
│   ├── Views/             # SwiftUI views (Login, ChatList, Chat)
│   ├── ViewModels/        # Auth & Chat view models
│   ├── Services/          # API, WebSocket, Crypto services
│   ├── Models/            # User, Message, Chat models
│   └── Utils/             # Storage (Keychain)
│
├── server/                # Node.js Backend
│   ├── src/
│   │   ├── index.ts       # Fastify entry point
│   │   ├── routes/        # auth.ts, users.ts
│   │   ├── ws/            # WebSocket handler
│   │   ├── services/      # otp, jwt, redis, push
│   │   ├── db/            # Drizzle ORM schema & queries
│   │   └── middleware/    # auth middleware
│   ├── drizzle/           # SQL migrations
│   └── package.json
│
├── android/               # Kotlin Android App (future)
└── docs/                  # Documentation
```

## Common Commands

### Backend Development
```bash
cd server
npm install          # Install dependencies
npm run dev          # Start dev server (hot reload)
npm run build        # Build for production
npm run start        # Start production server
npm run lint         # Run ESLint
```

### Database
```bash
# Run migration SQL in Supabase Dashboard > SQL Editor
# File: server/drizzle/0000_initial.sql
```

### iOS Development
```bash
# Open in Xcode
open ios/Vilo.xcodeproj

# Build: ⌘+B
# Run: ⌘+R
# Clean: ⌘+Shift+K
```

## API Endpoints

### Auth
- `POST /api/auth/send-otp` - Send OTP to phone
- `POST /api/auth/verify-otp` - Verify OTP & login
- `POST /api/auth/refresh` - Refresh JWT token

### Users
- `GET /api/users/me` - Get current user
- `PATCH /api/users/me` - Update profile
- `POST /api/users/keys` - Upload E2EE public keys
- `GET /api/users/keys/:phone` - Get user's public key
- `GET /api/users/find/:phone` - Find user by phone

### WebSocket
- `ws://localhost:3000/ws` - Real-time messaging
- Message types: `auth`, `message`, `typing`, `read`, `delivered`, `ping`

## Environment Variables

Required in `server/.env`:
```
DATABASE_URL=postgres://...
UPSTASH_REDIS_REST_URL=https://...
UPSTASH_REDIS_REST_TOKEN=...
JWT_SECRET=...
TWILIO_ACCOUNT_SID=AC...
TWILIO_AUTH_TOKEN=...
TWILIO_VERIFY_SERVICE_SID=VA...
```

## Brand Colors (Vietnamese Flag Theme)

| Color | Hex | Usage |
|-------|-----|-------|
| 🔴 Primary | #DA251D | Buttons, sent bubbles, accents |
| 🟡 Secondary | #FFCD00 | Online indicator, badges |
| ⚫ Background | #0D0D0D | App background |
| Surface | #1A1A1A | Cards, inputs |
| Border | #2A2A2A | Dividers |

## Architecture Notes

### E2EE Implementation
- Uses X3DH key agreement (Signal protocol)
- CryptoKit on iOS, Tink on Android
- Keys: Identity Key (long-term), Signed PreKey, One-time PreKeys
- Messages encrypted with AES-256-GCM

### Message Flow
1. Sender encrypts message with recipient's public key
2. Sends encrypted blob via WebSocket
3. Server queues if recipient offline (24h TTL in Redis)
4. Recipient decrypts with private key
5. Server deletes after delivery (zero-knowledge)

### Local Storage
- iOS: UserDefaults (non-sensitive) + Keychain (tokens, keys)
- Messages stored locally on device only
- Server never stores message content

## Current Status

### ✅ Completed
- Project structure & Git repo
- Backend: Fastify server, routes, WebSocket, services
- iOS: SwiftUI views, view models, services
- Database schema (Drizzle + SQL migration)
- E2EE crypto service

### 🚧 TODO
- [ ] Create Xcode project file
- [ ] Setup Supabase database
- [ ] Setup Upstash Redis
- [ ] Setup Twilio for OTP
- [ ] Add push notifications (APNs)
- [ ] Image upload (Cloudflare R2)
- [ ] Android app

## Development Tips

- Dev mode: OTP is logged to console (no Twilio needed)
- iOS Simulator uses `localhost:3000`
- Physical device needs Mac's local IP address
- SwiftUI previews work without backend connection
