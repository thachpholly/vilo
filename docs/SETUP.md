# 🚀 VILO Setup Guide

This guide will help you set up the VILO development environment.

## Prerequisites

- **macOS** (for iOS development)
- **Xcode 15+** (download from App Store)
- **Node.js 20+** ([download](https://nodejs.org/))
- **Git** (pre-installed on macOS)

## 1. Backend Setup

### 1.1 Install Dependencies

```bash
cd server
npm install
```

### 1.2 Setup Supabase (Free PostgreSQL Database)

1. Go to [supabase.com](https://supabase.com) and create a free account
2. Click **"New Project"**
3. Enter:
   - Project name: `vilo`
   - Database password: (save this!)
   - Region: Choose nearest to Vietnam
4. Wait for project to be created (~2 minutes)
5. Go to **Settings > Database** and copy the connection string

### 1.3 Setup Upstash Redis (Free)

1. Go to [upstash.com](https://upstash.com) and create a free account
2. Click **"Create Database"**
3. Select:
   - Name: `vilo-redis`
   - Region: Singapore or nearest
   - Type: Regional
4. Copy the **REST URL** and **REST Token**

### 1.4 Setup Twilio (for OTP)

1. Go to [twilio.com](https://www.twilio.com/) and create a free account
2. Get your **Account SID** and **Auth Token** from the console
3. Go to **Verify > Services** and create a new service
4. Copy the **Service SID**

### 1.5 Configure Environment

```bash
# Copy example config
cp .env.example .env

# Edit with your values
nano .env
```

Fill in:
```
DATABASE_URL=postgres://postgres:YOUR_PASSWORD@db.YOUR_PROJECT.supabase.co:5432/postgres
UPSTASH_REDIS_REST_URL=https://YOUR_PROJECT.upstash.io
UPSTASH_REDIS_REST_TOKEN=YOUR_TOKEN
JWT_SECRET=generate-a-random-32-char-string
TWILIO_ACCOUNT_SID=ACxxxxxxxxxx
TWILIO_AUTH_TOKEN=your_auth_token
TWILIO_VERIFY_SERVICE_SID=VAxxxxxxxxxx
```

### 1.6 Setup Database

1. Go to Supabase Dashboard > SQL Editor
2. Copy contents of `drizzle/0000_initial.sql`
3. Run the SQL

### 1.7 Start Server

```bash
npm run dev
```

Server should start at `http://localhost:3000`

Test it:
```bash
curl http://localhost:3000/health
# Should return: {"status":"ok","timestamp":"..."}
```

## 2. iOS Setup

### 2.1 Create Xcode Project

1. Open Xcode
2. File > New > Project
3. Select **iOS > App**
4. Configure:
   - Product Name: `Vilo`
   - Team: Your Apple ID
   - Organization Identifier: `app.vilo`
   - Interface: **SwiftUI**
   - Language: **Swift**
5. Save to `~/Projects/vilo/ios/`

### 2.2 Add Source Files

The Swift source files are already in `ios/Vilo/`. You need to add them to Xcode:

1. In Xcode, right-click on the `Vilo` folder
2. Select **Add Files to "Vilo"...**
3. Navigate to `ios/Vilo/` and select all folders:
   - `App/`
   - `Views/`
   - `ViewModels/`
   - `Services/`
   - `Models/`
   - `Utils/`
4. Make sure **"Copy items if needed"** is UNCHECKED
5. Make sure **"Create groups"** is selected
6. Click **Add**

### 2.3 Configure Project

1. Select the project in navigator
2. Select the `Vilo` target
3. Under **Signing & Capabilities**:
   - Team: Your Apple ID
   - Bundle Identifier: `app.vilo.ios`

### 2.4 Run on Simulator

1. Select a simulator (iPhone 15 Pro recommended)
2. Press ⌘+R to build and run

### 2.5 Run on Physical Device

1. Connect your iPhone via USB
2. On iPhone: Settings > Privacy & Security > Developer Mode > Enable
3. Trust your computer when prompted
4. Select your device in Xcode
5. Press ⌘+R

## 3. Development Workflow

### Backend Changes
```bash
cd server
npm run dev  # Auto-reloads on file changes
```

### iOS Changes
- Xcode SwiftUI previews update automatically
- Press ⌘+R to run on simulator/device

### Testing API
```bash
# Send OTP
curl -X POST http://localhost:3000/api/auth/send-otp \
  -H "Content-Type: application/json" \
  -d '{"phone":"+84123456789"}'

# Check console for OTP in dev mode
# Look for: [DEV] OTP for +84123456789: 123456
```

## 4. Troubleshooting

### Server won't start
- Check Node.js version: `node --version` (need 20+)
- Check for missing env vars
- Check Supabase/Redis connectivity

### iOS build fails
- Clean build: ⌘+Shift+K
- Delete Derived Data: Xcode > Settings > Locations > Derived Data > Delete
- Update Xcode if needed

### WebSocket not connecting
- Make sure server is running
- Check iOS is using correct URL (localhost for simulator)
- For physical device, use your Mac's local IP

## 5. Next Steps

After basic setup works:

1. **Configure Push Notifications** (APNs)
2. **Add App Icons and Launch Screen**
3. **Setup TestFlight** for beta testing
4. **Configure Production Environment**

---

Need help? Check the [README.md](../README.md) or create an issue.
