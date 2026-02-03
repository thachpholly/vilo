# 📱 VILO - Vietnamese Chat App

## 🎯 Project Overview

**App Name**: **VILO** (Viet + Local)
**Tagline**: "Private chat, no trace"

## 🎯 CORE PHILOSOPHY: ULTRA LIGHT, ULTRA SMOOTH, SIMPLE

| Principle | Target | Comparison |
|-----------|--------|------------|
| **Ultra Light** | < 15MB app size | Zalo ~150MB, Telegram ~100MB |
| **Ultra Smooth** | 60fps, < 100ms response | No lag, no jank |
| **Simple** | Minimal features, maximum UX | 1 tap = 1 action |

**Goals**:
- ✅ Free forever (no paid features)
- ✅ Highly secure
- ✅ No server-side data storage (zero-knowledge)
- ✅ **ULTRA LIGHT** (< 15MB)
- ✅ **ULTRA SMOOTH** (60fps)
- ✅ **SIMPLE** (minimal UI)

**Developer**: 100% AI-assisted (Claude Code)

---

## ✅ TECH STACK: NATIVE + NODE.JS

#### 📱 iOS - SWIFT (Native)
```
Swift 5.9 + SwiftUI
├── SwiftUI - Native Apple UI framework
├── Combine - Reactive programming
├── CryptoKit - Native encryption (super fast)
├── CoreData / SwiftData - Local storage
├── URLSession + WebSocket - Native networking
└── Push Notifications - APNs native
```

**Swift native advantages:**
- App size: ~5-8MB (vs React Native ~30MB)
- Performance: 60fps guaranteed
- Memory: ~30MB RAM (vs RN ~100MB)
- Battery: Best optimized
- Apple review: Easier approval

#### 🤖 Android - KOTLIN (Native)
```
Kotlin + Jetpack Compose
├── Jetpack Compose - Modern UI toolkit
├── Coroutines + Flow - Async programming
├── Tink (Google) - Encryption library
├── Room - Local database
├── OkHttp + WebSocket - Networking
└── Firebase Cloud Messaging - Push
```

**Kotlin native advantages:**
- App size: ~5-10MB
- Performance: Native speed
- Smooth animations: 60fps
- Battery efficient

#### 🔥 Backend - NODE.JS
```
Node.js 20 + TypeScript
├── Fastify - Web framework (2x faster than Express)
├── ws - Native WebSocket (lightweight)
├── Drizzle ORM - Type-safe, minimal
├── PostgreSQL - User data (Supabase free)
├── Redis - Message queue (Upstash free)
└── Twilio - OTP SMS
```

#### 🔐 Encryption
```
iOS: CryptoKit (native Apple)
Android: Tink (Google's crypto library)
├── ECDH key exchange
├── AES-256-GCM encryption
└── Ed25519 signatures
```

#### ☁️ Infrastructure - FREE TIER
```
├── Railway / Render (Node.js hosting) - FREE tier
├── Supabase (PostgreSQL) - 500MB FREE
├── Upstash Redis - 10k commands/day FREE
├── Cloudflare R2 (images) - 10GB FREE
├── APNs (iOS push) - FREE
└── FCM (Android push) - FREE
```

---

## 📋 MVP SCOPE - MINIMAL FEATURES ONLY

### ❌ NOT included in MVP (to keep app light):
- ❌ Group chat
- ❌ Voice/Video call
- ❌ File sharing (pdf, doc)
- ❌ Location sharing
- ❌ Stories/Feed
- ❌ Stickers
- ❌ Reactions

### ✅ ONLY essential features:

#### 1. Auth (super simple)
- [x] Phone number + OTP login
- [ ] Profile: Name + Avatar (optional)
- [x] No email, no password required

#### 2. 1-on-1 Chat (core feature)
- [x] Text messages
- [x] Emoji (native keyboard)
- [ ] Image (1 image at a time, auto-compressed)
- [x] Sent/Delivered/Read status
- [x] Typing indicator

#### 3. UI (minimal)
- [x] 3 screens: Login → Chat List → Chat
- [x] Dark mode default (saves battery)
- [x] No complex animations
- [x] No long onboarding

#### 4. Performance targets
- [ ] App size: < 15MB
- [ ] First load: < 2s
- [ ] Message send: < 100ms
- [ ] Memory: < 100MB RAM

---

## 🎨 UI STYLE GUIDE

### Design Philosophy
```
MINIMAL + FUNCTIONAL + FAST
- No unnecessary decoration
- Every element has a purpose
- Prioritize readability
```

### Color Palette (Dark Theme - Default) 🇻🇳
```
Background:     #0D0D0D (pure dark)
Surface:        #1A1A1A (cards, inputs)
Border:         #2A2A2A (subtle lines)
Text Primary:   #FFFFFF
Text Secondary: #888888

🔴 Primary:     #DA251D (Vietnamese flag red)
🟡 Secondary:   #FFCD00 (Golden star yellow)

Sent Bubble:    #DA251D (red)
Received Bubble:#1A1A1A
Online:         #FFCD00 (yellow)
Accent Button:  #DA251D
Error:          #FF4757
```

### Color Usage:
```
🔴 Red (#DA251D):
   - Send message button
   - Sent message bubble
   - Links, highlights
   - App icon background

🟡 Yellow (#FFCD00):
   - Online indicator
   - Unread badge
   - Star/favorite
   - Small accents (icons)
```

### Typography (Native System Fonts)
```
iOS:     SF Pro Display / SF Pro Text
Android: Roboto / Google Sans

Sizes:
- Header:    24px bold
- Title:     18px semibold
- Body:      16px regular
- Caption:   14px regular
- Small:     12px regular
```

### Spacing System
```
4px  - micro (icon padding)
8px  - small (between elements)
16px - medium (section padding)
24px - large (screen margins)
32px - xl (between sections)
```

### App Icon Concept 🇻🇳
```
┌─────────┐
│         │
│    V    │  ← Letter V (Vilo) in YELLOW
│   💬    │  ← Chat bubble
│         │
└─────────┘

Background: #DA251D (flag red)
Letter V:   #FFCD00 (star yellow)
Style: Flat, minimal, bold
```

---

## 🔐 SECURITY ARCHITECTURE (NO SERVER STORE)

### E2EE + Local-first Model

```
┌──────────────────────────────────────────────────────────────┐
│                        ARCHITECTURE                          │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│   Device A                    Server                Device B │
│  ┌────────┐               ┌──────────┐            ┌────────┐│
│  │ Keys   │               │ Relay    │            │ Keys   ││
│  │ Local  │──encrypted───▶│ Queue    │──────────▶│ Local  ││
│  │ SQLite │   messages    │ (temp)   │  encrypted │ SQLite ││
│  └────────┘               │ <24h TTL │  messages  └────────┘│
│                           └──────────┘                       │
│                                                              │
│  Server DOES NOT store:    Server ONLY stores:              │
│  - Message content         - User ID + Phone (hashed)       │
│  - Media files             - Public keys                     │
│  - Chat history            - Encrypted message queue (temp)  │
│  - Private keys            - Delivery receipts              │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### Message Flow
1. User A types message → Encrypt with session key
2. Send encrypted blob to server
3. Server queues message (max 24h TTL)
4. User B comes online → Receives encrypted blob
5. Decrypt on device B
6. Server deletes message from queue
7. Both devices store locally (encrypted SQLite)

### Key Management
- **Identity Key**: Long-term, backup with recovery phrase
- **Prekeys**: One-time keys for X3DH
- **Session Keys**: Ratchet per message

---

## 🚀 DEVELOPMENT PHASES (NATIVE iOS FIRST)

### Strategy: iOS first → Android later
Since you have Mac + iPhone:
- Test directly on device
- Launch App Store early
- Android after iOS is stable

---

### Phase 1: Setup & Backend ✅ COMPLETE
| Day | Task | Status |
|-----|------|--------|
| 1-2 | Create Xcode project, SwiftUI setup | ✅ Code ready |
| 3-4 | Node.js + Fastify + PostgreSQL | ✅ Done |
| 5-7 | WebSocket server + Redis | ✅ Done |

### Phase 2: iOS Auth (1 week)
| Day | Task | Status |
|-----|------|--------|
| 1-3 | LoginView + OTP flow | ✅ Code ready |
| 4-5 | User profile screen | 🚧 TODO |
| 6-7 | JWT + Keychain storage | ✅ Code ready |

### Phase 3: iOS Messaging (2-3 weeks)
| Day | Task | Status |
|-----|------|--------|
| 1-4 | WebSocket client Swift | ✅ Code ready |
| 5-8 | ChatListView | ✅ Code ready |
| 9-12 | ChatView + send/receive | ✅ Code ready |
| 13-16 | CryptoKit E2EE | ✅ Code ready |
| 17-21 | Message status + image | 🚧 TODO |

### Phase 4: iOS Launch (1-2 weeks)
| Day | Task | Status |
|-----|------|--------|
| 1-4 | Bug fixes, UI polish | ⏳ Pending |
| 5-7 | TestFlight beta | ⏳ Pending |
| 8-14 | App Store submission | ⏳ Pending |

**Total iOS: ~6-7 weeks**

---

### Phase 5: Android (after iOS launch) - 4-5 weeks
| Week | Task | Status |
|------|------|--------|
| 1 | Kotlin + Compose setup | ⏳ Pending |
| 2 | Auth flow (copy logic from iOS) | ⏳ Pending |
| 3-4 | Messaging (copy logic) | ⏳ Pending |
| 5 | Play Store submission | ⏳ Pending |

**Total both platforms: ~11-12 weeks**

---

### Future (after both platforms):
- Voice message - 1 week/platform
- Group chat - 2 weeks/platform
- Voice call (WebRTC) - 4 weeks/platform

---

## 💰 COST ESTIMATE

### Development Phase (free or very low)
| Service | Free Tier | When scaling |
|---------|-----------|--------------|
| Railway | 500 hours/month | ~$5-20/month |
| Supabase | 500MB database | $25/month |
| Upstash Redis | 10k commands/day | $10/month |
| Firebase (push) | 10k/day | Free |
| Twilio (OTP) | $15 credit trial | ~$0.05/SMS |
| **Total MVP** | **~$0-15/month** | |

### Production (1000 users)
- Server: ~$20-50/month
- OTP: ~$50/month (if many new signups)
- CDN: Free (Cloudflare)
- **Total: ~$70-100/month**

---

## 💻 YOUR SETUP

| Device | Value | Benefit |
|--------|-------|---------|
| **Computer** | Mac (macOS) | ✅ Can build both iOS + Android |
| **Test device** | iPhone | ✅ Test native iOS directly |

---

## ✅ DECISION SUMMARY

| Decision | Value |
|----------|-------|
| App name | **VILO** |
| Philosophy | **Ultra light < 10MB, Ultra smooth 60fps, Simple** |
| Development | **100% AI-assisted** |
| iOS | **Swift + SwiftUI** (native) |
| Android | **Kotlin + Jetpack Compose** (native) |
| Backend | **Node.js + Fastify** |
| Database | **PostgreSQL** (Supabase free) |
| Encryption | **CryptoKit (iOS) / Tink (Android)** |
| UI Colors | **Red #DA251D + Yellow #FFCD00** (Vietnamese flag) |
| MVP Timeline | **iOS: ~6-7 weeks, Android: +4-5 weeks** |
| MVP Features | 1-on-1 Chat + Text + Emoji + Image ONLY |
| Hosting cost | **~$0/month** (free tier) |

### App size comparison:
| App | Size | Vilo Target |
|-----|------|-------------|
| Zalo | ~150MB | ❌ |
| Messenger | ~200MB | ❌ |
| Telegram | ~100MB | ❌ |
| Signal | ~50MB | ❌ |
| React Native app | ~30-50MB | ❌ |
| **VILO (Native)** | **< 10MB** | ✅ |

---

## 🚀 CURRENT STATUS

### ✅ Completed
- [x] Project structure & Git repo
- [x] Backend: Fastify server, routes, WebSocket, services
- [x] iOS: SwiftUI views, view models, services
- [x] Database schema (Drizzle + SQL migration)
- [x] E2EE crypto service
- [x] Pushed to GitHub

### 🚧 In Progress
- [ ] Create Xcode project file (manual step)
- [ ] Setup Supabase database
- [ ] Setup Upstash Redis
- [ ] Setup Twilio for OTP

### ⏳ Next
- [ ] Test end-to-end flow
- [ ] Add push notifications (APNs)
- [ ] Image upload (Cloudflare R2)
- [ ] Profile screen
- [ ] Android app

---

*Plan created: 2024*
*Last updated: Phase 1 Complete*
*Method: 100% AI-powered development*
