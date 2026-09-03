# TapX Production Deployment & Server Upload Guide

## 📁 Overview of Deployment Files

| Directory / File | Description | Server Destination |
| :--- | :--- | :--- |
| `r:/Soul - TapTap/build/web/` | Production Flutter Web App (Compiled HTML, JS, Assets) | `public_html/` (or web root) |
| `r:/Soul - TapTap/api/` | PHP REST API Backend & Admin Portal | `public_html/api/` |
| `r:/Soul - TapTap/api/schema.sql` | MySQL Database Schema & Initial Seeds | Import into phpMyAdmin / MySQL |
| `r:/Soul - TapTap/api/.env` | Environment Variables & Database Credentials | `public_html/api/.env` |

---

## 🚀 Step 1: Uploading the Web App Files
1. Copy everything inside `build/web/` to your web server root (e.g. `public_html/` on Hostinger / cPanel).
2. Ensure `index.html`, `flutter_bootstrap.js`, `main.dart.js`, and the `assets/` folder are placed directly in the web root.

---

## 🗄️ Step 2: Database Setup
1. Open your hosting control panel (Hostinger / cPanel / phpMyAdmin).
2. Create your database (e.g. `u697802579_tapxdb`) and MySQL user (`u697802579_tapxuser`).
3. Import `api/schema.sql` into phpMyAdmin.
   *(Note: If you skip importing, `api/config/database.php` also features automatic schema self-healing on first run).*

---

## ⚙️ Step 3: Backend API & Admin Portal Setup
1. Upload the entire `api/` folder to `public_html/api/`.
2. Ensure the `.env` file in `public_html/api/.env` contains your active database credentials:
   ```ini
   APP_ENV=production
   APP_URL=https://tapx.ashiik.com
   API_BASE_URL=https://tapx.ashiik.com/api

   DB_HOST=localhost
   DB_PORT=3306
   DB_NAME=u697802579_tapxdb
   DB_USER=u697802579_tapxuser
   DB_PASS=YourDatabasePassword
   ```
3. Verify file permissions:
   - `api/uploads/` & `api/uploads/avatars/`: `755` (writable)
   - `api/logs/`: `755` (writable)

---

## 🩺 Step 4: Health Check & Verification
Open your browser and navigate to:
```
https://tapx.ashiik.com/api/health.php
```
You should receive a JSON response confirming `status: healthy` and `database.status: connected`.

---

## 🔐 Step 5: Admin Portal Access
- **URL**: `https://tapx.ashiik.com/api/admin/` (or `/login.php`)
- **Username**: `admin`
- **Password**: `TapX@Admin2026`

From the admin portal, you can:
- Review & approve bKash / Nagad withdrawal requests
- Send instant payout confirmation emails
- Broadcast system notifications to all users
- Manage and inspect registered player profiles
- Update OTA app version codes & APK download URLs
