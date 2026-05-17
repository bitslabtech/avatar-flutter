# Avatar SKW — Flutter Mobile App

> Premium home appliances & kitchenware store mobile app for **iOS & Android**.
> Built with Flutter, Riverpod state management, and go_router navigation.

---

## Features

- 🎨 Premium dark UI with Apple-like design
- 🛍️ Product catalog with categories, brands & banners
- 🛒 Shopping cart (via order drafts)
- 📦 Order management & order history
- 📋 Quotations flow
- 👤 User authentication & profile
- 🎭 Animated splash screen (Lottie)
- 🖼️ Banner slider for promotions
- 📊 Reports & analytics screens (Admin/Dealer)
- 🏗️ Admin panel for order, banner & category management

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.9.2+ / Dart 3.9.2+ |
| State Management | flutter_riverpod |
| Navigation | go_router |
| HTTP Client | Dio |
| Local Storage | shared_preferences + flutter_secure_storage |
| Image Loading | cached_network_image |
| Charts | fl_chart |
| Animations | lottie |

---

## Setup

### Prerequisites

- Flutter SDK 3.9.2+
- Dart SDK 3.9.2+
- Android Studio / VS Code with Flutter extension
- Backend API running (see [`avatar-skw-backend/README.md`](../avatar-skw-backend/README.md))

### Installation

```bash
# 1. Install dependencies
flutter pub get
```

### Configuring API Base URL

The app resolves the backend URL in this priority order:

1. **`--dart-define=API_BASE_URL=...`** — Recommended for all environments
2. Automatic fallback based on platform (Android emulator → `10.0.2.2:3000`, iOS/Web → `localhost:3000`)

**Physical Android device:**
```bash
flutter run --dart-define=API_BASE_URL=http://192.168.x.x:3000
```
> Replace `192.168.x.x` with your computer's LAN IP (find with `ipconfig` on Windows / `ifconfig` on Mac).

**Android Emulator (no flag needed):**
```bash
flutter run
```

**VS Code launch.json (recommended for team use):**
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Avatar App (Physical Device)",
      "request": "launch",
      "type": "dart",
      "args": ["--dart-define=API_BASE_URL=http://192.168.x.x:3000"]
    }
  ]
}
```

---

## Running the App

```bash
# Development
flutter run

# With specific device
flutter devices
flutter run -d <device-id>

# Release mode
flutter run --release
```

---

## Project Structure

```
lib/
├── main.dart                     # App entry point
├── core/
│   ├── api/
│   │   ├── api_client.dart       # Dio HTTP client with interceptors
│   │   └── api_endpoints.dart    # Centralized endpoint constants
│   ├── constants/
│   │   └── app_constants.dart    # App-wide constants
│   ├── routing/
│   │   └── app_router.dart       # go_router navigation config
│   ├── services/
│   │   └── file_upload_service.dart
│   └── theme/
│       ├── app_colors.dart       # Color palette
│       └── app_theme.dart        # Material theme config
├── models/                       # Data models (Order, Product, User, etc.)
├── services/                     # API service classes
├── providers/                    # Riverpod providers
├── features/
│   ├── splash/                   # Animated splash screen
│   ├── auth/                     # Login / Registration
│   ├── home/                     # Home screen & navigation
│   ├── product_detail/           # Product details
│   ├── cart/                     # Shopping cart
│   ├── orders/                   # Order list & details
│   ├── reports/                  # Reports & analytics
│   ├── profile/                  # User profile
│   └── admin/                    # Admin-only screens
└── widgets/
    └── common/                   # Reusable UI widgets
```

---

## Architecture

### State Management (Riverpod)

| Provider | Responsibility |
|----------|---------------|
| `authProvider` | Auth state (login, logout, token refresh) |
| `catalogProvider` | Products, categories, brands, banners |
| `cartProvider` | Cart (order draft) + item management |
| `orderProvider` | User orders list & details |
| `reportProvider` | Sales & analytics data |

### Navigation (go_router)
- Named routes with path parameters
- Route guards for auth-protected pages
- Deep linking support

### API Layer
- Centralized **Dio** instance in `api_client.dart`
- Automatic JWT token injection via interceptor
- Transparent access token refresh on 401
- Domain-specific service classes (`auth_service.dart`, `catalog_service.dart`, etc.)

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| API connection refused on device | Pass `--dart-define=API_BASE_URL=http://<LAN-IP>:3000` |
| `flutter pub get` fails | Delete `.dart_tool/` and retry |
| Build errors after upgrade | Run `flutter clean && flutter pub get` |
| JWT auth loop | Check token expiry and refresh logic in `api_client.dart` |

---

## Development Notes

- Money values are stored in **paise** on the backend; displayed as ₹ in the app via `intl` formatting.
- Cart is implemented as an **order draft** — no separate cart API needed.
- All network images use `cached_network_image` for performance.
- Hero animations are used for smooth product image transitions.

---

## License

Private — Avatar / SKW Bitslab
