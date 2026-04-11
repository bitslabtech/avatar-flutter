# Avatar SKW — NestJS Backend

> Secure, production-ready REST API for **Avatar Home Appliances & Kitchenware** e-commerce platform.
> Built with NestJS, PostgreSQL (TypeORM), JWT authentication, and WhatsApp Cloud API integration.

---

## Features

- 🔐 **Auth & RBAC** — JWT (access + refresh tokens), roles: Consumer, Dealer, Admin, SuperAdmin
- 🛍️ **Product Catalog** — Products, categories, brands, banners with full CRUD
- 🛒 **Order Management** — Cart-as-draft, order confirmation, status workflow, WhatsApp notifications
- 📋 **Quotation System** — Similar to orders; separate quotation flow
- 💰 **Pricing (Excel)** — SuperAdmin import/export pricing via Excel (ExcelJS)
- 🚚 **Courier Fees** — Rule-based courier fee calculation engine
- 📊 **Reports & Dashboard** — Order stats, revenue charts, dealer analytics
- 👥 **Dealer Onboarding** — Registration → Approval workflow
- 🌐 **Landing Page Config** — Dynamic banners, industries, footer — managed by SuperAdmin
- 💬 **WhatsApp Integration** — Cloud API + Deep Link fallback
- 🏗️ **Settings API** — Whitelist-secured key-value store for business configuration
- 📤 **File Uploads** — Multer-based local storage, S3-ready

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | NestJS 10 (Node.js + TypeScript) |
| Database | PostgreSQL 14+ with TypeORM |
| Auth | Passport.js + JWT (bcrypt passwords) |
| Validation | class-validator + class-transformer |
| File Upload | Multer |
| Excel | ExcelJS |
| Security | Helmet, Throttler (rate limiting) |
| API Docs | Swagger / OpenAPI |

---

## Critical Design Decisions

### 1. Monetary Values (Paise)
All monetary values are stored as **integers in paise** (1 ₹ = 100 paise) to avoid floating-point errors. Conversion to ₹ happens in service/DTO layers.

### 2. Settings Security
The settings endpoint exposes only whitelisted public/business keys via HTTP. Secrets live in environment variables only.

### 3. Safe DTOs
Public-facing DTOs (`OrderPublicDto`, `QuotationPublicDto`) never expose internal discount fields or sensitive pricing.

### 4. Transaction-Safe Order Numbers
Order/quotation numbers use per-day incremental counters with `UNIQUE` constraints under a database transaction.

---

## Setup

### Prerequisites

- Node.js 18+
- npm 9+
- PostgreSQL 14+

### Installation

```bash
# 1. Install dependencies
npm install

# 2. Configure environment
cp .env.example .env
# Edit .env — see Environment Variables section below
```

### Environment Variables

Copy `.env.example` to `.env` and fill in your values:

```bash
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/avatar_db
TYPEORM_SYNC=false           # true for local dev only; use migrations in production

# JWT
JWT_SECRET=<random-32+-char-string>
JWT_EXPIRES_IN=15m
JWT_REFRESH_SECRET=<random-32+-char-string>
JWT_REFRESH_EXPIRES_IN=7d

# Application
PORT=3000
NODE_ENV=development
FRONTEND_MOBILE_APP_URL=http://localhost:3000   # CORS origin for mobile app

# WhatsApp Cloud API (optional)
WHATSAPP_CLOUD_API_TOKEN=
WHATSAPP_PHONE_NUMBER_ID=

# S3 File Storage (optional — falls back to local uploads/)
S3_ACCESS_KEY=
S3_SECRET_KEY=
S3_BUCKET_NAME=
S3_REGION=

# Rate Limiting
THROTTLE_TTL=60000
THROTTLE_LIMIT=10
```

---

## Database

```bash
# Create database
createdb avatar_db   # or via psql / pgAdmin

# Run all pending migrations
npm run migration:run

# Revert last migration
npm run migration:revert

# Generate a new migration (after entity changes)
npm run migration:generate -- src/database/migrations/MigrationName
```

> **Note**: For local dev you can set `TYPEORM_SYNC=true` to auto-create/update tables. **Never use `TYPEORM_SYNC=true` in production.**

---

## Running the Application

```bash
# Development (auto-reload)
npm run start:dev

# Production build
npm run build
npm run start:prod
```

---

## API Overview

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/register` | Register (Consumer/Dealer) |
| POST | `/auth/login` | Login → `accessToken` + `refreshToken` |
| POST | `/auth/refresh` | Refresh access token |
| GET | `/auth/me` | Current user |
| POST | `/auth/forgot-password` | Initiate password reset |
| POST | `/auth/reset-password` | Complete password reset |

### Products
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/products` | List products (public) |
| GET | `/products/:id` | Product details (public) |
| GET | `/products/meta/brands` | Brands list |
| GET | `/products/meta/categories` | Categories list |
| GET | `/products/banners` | Active banners |

### Orders
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/orders/draft` | Create/update cart (order draft) |
| POST | `/orders/confirm` | Confirm order |
| GET | `/orders` | User's orders |
| GET | `/orders/:id` | Order details |
| PATCH | `/orders/:id/status` | Update status (Admin) |

### Admin
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/admin/orders/dashboard` | Dashboard statistics |
| GET/POST/PATCH/DELETE | `/admin/banners` | Banner management |
| GET/POST/PATCH/DELETE | `/admin/categories` | Category management |
| GET | `/admin/reports/*` | Sales & order reports |

### Pricing (SuperAdmin only)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/prices/export-xlsx` | Export pricing to Excel |
| POST | `/prices/import-xlsx` | Import pricing from Excel |

---

## Project Structure

```
src/
├── common/              # Guards, decorators, filters, interceptors
├── config/              # App configuration modules
├── database/
│   ├── migrations/      # TypeORM migration files
│   └── seed.ts          # Database seeder
└── modules/
    ├── auth/            # JWT authentication
    ├── users/           # User management & dealer admin
    ├── catalog/         # Products, categories, brands, banners
    ├── orders/          # Order management & cart
    ├── quotations/      # Quotation flow
    ├── pricing/         # Excel import/export
    ├── courier/         # Courier fee rules
    ├── settings/        # Business settings store
    ├── whatsapp/        # WhatsApp Cloud API integration
    ├── reports/         # Reporting & analytics
    ├── landing/         # Landing page dynamic config
    └── admin/           # Admin dashboard & tools
```

---

## License

ISC — Private / Avatar SKW
