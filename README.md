# Avatar SKW — Monorepo

> **Avatar Home Appliances & Kitchenware** — Full-stack e-commerce platform with a Flutter mobile app and a NestJS REST API backend.

---

## Repository Structure

```
avatar/
├── avatar-skw-backend/   # NestJS REST API (Node.js + TypeScript + PostgreSQL)
└── avatar-skw-app/       # Flutter mobile app (iOS & Android)
```

---

## Quick Start

### Prerequisites

| Tool | Version |
|------|---------|
| Node.js | 18+ |
| npm | 9+ |
| PostgreSQL | 14+ |
| Flutter SDK | 3.9.2+ |
| Dart SDK | 3.9.2+ |

---

### 1. Backend Setup

```bash
cd avatar-skw-backend

# Install dependencies
npm install

# Configure environment
cp .env.example .env
# Edit .env — set DATABASE_URL, JWT_SECRET, etc.

# Run database migrations
npm run migration:run

# Start development server (http://localhost:3000)
npm run start:dev
```

📖 See [`avatar-skw-backend/README.md`](./avatar-skw-backend/README.md) for full details.

---

### 2. Flutter App Setup

```bash
cd avatar-skw-app

# Install dependencies
flutter pub get

# Run on Android (physical device — replace with your machine's LAN IP)
flutter run --dart-define=API_BASE_URL=http://192.168.x.x:3000

# Run on Android Emulator (uses 10.0.2.2 automatically — no --dart-define needed)
flutter run

# Run on iOS Simulator
flutter run
```

📖 See [`avatar-skw-app/README.md`](./avatar-skw-app/README.md) for full details.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile App | Flutter 3.9.2+, Riverpod, go_router, Dio |
| Backend API | NestJS 10, TypeORM, PostgreSQL |
| Auth | JWT (access + refresh token) |
| File Storage | Local (`uploads/`) — S3-ready |
| WhatsApp | Cloud API + Deep Link fallback |

---

## Features

- 🔐 Multi-role authentication (Consumer, Dealer, Admin, SuperAdmin)
- 🛍️ Product catalog with categories, brands & banners
- 🛒 Shopping cart via order drafts
- 📦 Order & quotation management
- 💬 WhatsApp order notifications
- 📊 Admin dashboard & reports
- 💰 Excel-based pricing import/export (SuperAdmin)
- 🏗️ Dealer onboarding & approval workflow

---

## License

Private — Avatar / SKW Bitslab
