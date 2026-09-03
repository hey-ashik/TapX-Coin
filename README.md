# TapX - Coin

TapX is a high-performance, full-stack Tap-to-Earn gaming and reward platform. Built with Flutter for cross-platform delivery across Mobile and Web, it is powered by a secure PHP REST API and MySQL database.

---

## Overview

TapX delivers an engaging tap-engine experience where users earn coins through active tapping, maintain daily activity streaks, climb competitive leaderboards, and convert earned assets into verified real-world payouts and cryptocurrency.

---

## Core Features

### Tap Engine
* Responsive Tap Mechanic: Real-time tap detection with combo multiplier acceleration up to 2.5x.
* Energy Management: Dynamic energy pool that charges during continuous tapping and regenerates over time.
* Visual and Haptic Feedback: Particle burst physics, audio effects, and device vibration with user-configurable toggles.
* Daily Streak Bonus: Seven-day progressive reward ladder with doubling incentives and automated midnight reset cycles.

### Wallet and Withdrawals
* Multi-Currency Display: Instant conversion between Tap Coins, Bangladeshi Taka (BDT), and Tether (USDT).
* Milestone Tracking: Visual tier progression with customizable payout threshold gates.
* Gateway Integrations: Pre-configured payment pathways for mobile financial services (bKash, Nagad, Rocket) and crypto (USDT TRC20).
* Transaction Ledger: Transparent transaction history tracking pending, processing, and completed payouts.

### User Profile and Navigation
* Interactive Profile Modal: Sliding switcher allowing seamless toggling between Coins View and Rewards View.
* Activity Analytics: Seven-day interactive progression bar chart rendering daily engagement and payout volume.
* Global Leaderboard: Ranked listings with Daily, Weekly, and All-Time filters, live user search, and verified payout tags.

### Authentication and Security
* Verification Pipeline: Six-digit one-time password (OTP) email verification flow.
* Access Modes: Full user registration, credential login, password recovery, and frictionless Guest Mode.
* Session Persistence: Encrypted local token storage with automatic session re-validation.

---

## Tech Stack

### Client (Frontend)
* Framework: Flutter 3.47+ (Dart 3.13+)
* Target Platforms: Android, iOS, Web (PWA / CanvasKit), Desktop
* State Management: Provider Architecture with ProxyProvider dependencies
* Typography & UI: Google Fonts (Plus Jakarta Sans, Inter), Flutter Animate
* Storage & Networking: Shared Preferences, HTTP client

### Server (Backend)
* Runtime: PHP 8.1+ / Apache
* Database: MySQL 8.0+ / MariaDB
* Authentication: Stateless JSON Web Tokens (JWT)
* Content Delivery: JSON RESTful endpoints with CORS headers

---

## Project Structure

```text
TapX-Coin/
├── android/               # Native Android configuration and build files
├── ios/                   # Native iOS project structure
├── web/                   # Web platform shell, manifest, and service worker
├── windows/               # Windows desktop runner configuration
├── api/                   # Backend PHP REST API
│   ├── config/            # Database and environment handlers
│   ├── services/          # Core business logic (Auth, Mail, JWT)
│   ├── v1/                # Versioned REST endpoints
│   │   ├── auth/          # Registration, login, OTP verification
│   │   ├── sync/          # Tap and score synchronization
│   │   ├── wallet/        # Payout requests and transaction history
│   │   └── leaderboard/   # Ranked listings and public profiles
│   ├── admin/             # Administrative utilities
│   ├── schema.sql         # Database schema definition and seed data
│   └── .env.example       # Example backend configuration template
├── lib/                   # Flutter Application Source
│   ├── models/            # Immutable data models
│   ├── providers/         # Business logic and application state
│   ├── screens/           # Main views (Auth, Tap Engine, Wallet, Leaderboard)
│   ├── services/          # API integration and hardware services
│   ├── theme/             # Color tokens, typography, and theme definitions
│   └── widgets/           # Modular UI components and modals
├── test/                  # Automated unit and widget test suites
└── pubspec.yaml           # Flutter dependencies and asset registrations
```

---

## Getting Started

### Prerequisites
* Flutter SDK (3.47.2 or higher)
* Dart SDK (3.13.2 or higher)
* PHP (8.1 or higher) and MySQL (for local API hosting)
* Google Chrome (for Web testing) or Android Studio (for Android builds)

---

### Client Setup (Flutter)

1. Clone the repository:
   ```bash
   git clone https://github.com/hey-ashik/TapX-Coin.git
   cd TapX-Coin
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run static analysis:
   ```bash
   dart analyze
   ```

4. Launch the application:
   * Run on Web:
     ```bash
     flutter run -d chrome
     ```
   * Run on Connected Mobile Device:
     ```bash
     flutter run
     ```

---

### Backend Setup (PHP & MySQL)

1. Navigate to the API directory:
   ```bash
   cd api
   ```

2. Configure environment settings:
   * Copy `.env.example` to `.env`:
     ```bash
     cp .env.example .env
     ```
   * Configure database credentials, JWT secret, and application URLs.

3. Import database schema:
   * Import `schema.sql` into your MySQL instance using phpMyAdmin or terminal:
     ```bash
     mysql -u username -p database_name < schema.sql
     ```

4. Verify backend health:
   * Visit `http://your-server/api/health.php` to confirm database connectivity.

---

## Production Builds

### Build Web Release
Generate the minified, production-ready web application:
```bash
flutter build web --release
```
Compiled output is placed in `build/web/`.

### Build Android APK
Compile the standalone Android application package:
```bash
flutter build apk --release
```
Compiled output is placed in `build/app/outputs/flutter-apk/app-release.apk`.

### Build Android App Bundle (Google Play)
```bash
flutter build appbundle --release
```

---

## REST API Summary

| Endpoint | Method | Description | Authentication |
| :--- | :--- | :--- | :--- |
| `/api/v1/auth/register.php` | POST | Registers new user and dispatches 6-digit email OTP | None |
| `/api/v1/auth/verify-otp.php` | POST | Verifies OTP code and returns JWT token | None |
| `/api/v1/auth/login.php` | POST | Authenticates user credentials | None |
| `/api/v1/auth/reset-password.php` | POST | Handles password recovery and reset | None |
| `/api/v1/sync/taps.php` | POST | Synchronizes offline/online tap increments and scores | Bearer JWT |
| `/api/v1/sync/bonus.php` | POST | Claims daily streak reward points | Bearer JWT |
| `/api/v1/wallet/balance.php` | GET | Fetches live wallet balances and milestones | Bearer JWT |
| `/api/v1/wallet/withdraw.php` | POST | Submits a withdrawal request | Bearer JWT |
| `/api/v1/wallet/transactions.php` | GET | Retrieves paginated withdrawal ledger | Bearer JWT |
| `/api/v1/leaderboard/index.php` | GET | Fetches Daily, Weekly, and All-Time rankings | None / Optional |
| `/api/health.php` | GET | System and database diagnostic report | None |

---

## Deployment

* Web Server (Apache / cPanel / Hostinger):
  * Copy contents of `build/web/` to `public_html/`.
  * Upload `api/` folder to `public_html/api/`.
  * Ensure Apache `mod_rewrite` is enabled to process `.htaccess` routing rules.

* Nginx:
  * Route web client requests to `build/web/index.html` via `try_files $uri $uri/ /index.html;`.
  * Proxy `/api` requests to the PHP-FPM socket handler.

---

## Security Highlights

* Prepared SQL statements across all endpoints preventing SQL injection.
* Input sanitization and payload validation on incoming requests.
* Cryptographic password hashing using standard password_hash algorithms.
* Cryptographically signed JWT tokens with expiration handling.
* Local session authentication with zero plain-text password retention.

---

## License

This project is licensed under the terms described in the project repository. For proprietary inquiries, contact the repository maintainers.
