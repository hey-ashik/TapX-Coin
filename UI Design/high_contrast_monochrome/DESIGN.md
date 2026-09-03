---
name: High-Contrast Monochrome
colors:
  surface: '#141313'
  surface-dim: '#141313'
  surface-bright: '#3a3939'
  surface-container-lowest: '#0e0e0e'
  surface-container-low: '#1c1b1b'
  surface-container: '#201f1f'
  surface-container-high: '#2a2a2a'
  surface-container-highest: '#353434'
  on-surface: '#e5e2e1'
  on-surface-variant: '#c4c7c8'
  inverse-surface: '#e5e2e1'
  inverse-on-surface: '#313030'
  outline: '#8e9192'
  outline-variant: '#444748'
  surface-tint: '#c6c6c7'
  primary: '#ffffff'
  on-primary: '#2f3131'
  primary-container: '#e2e2e2'
  on-primary-container: '#636565'
  inverse-primary: '#5d5f5f'
  secondary: '#c8c6c5'
  on-secondary: '#313030'
  secondary-container: '#4a4949'
  on-secondary-container: '#bab8b7'
  tertiary: '#ffffff'
  on-tertiary: '#2f3131'
  tertiary-container: '#e2e2e2'
  on-tertiary-container: '#636565'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#e2e2e2'
  primary-fixed-dim: '#c6c6c7'
  on-primary-fixed: '#1a1c1c'
  on-primary-fixed-variant: '#454747'
  secondary-fixed: '#e5e2e1'
  secondary-fixed-dim: '#c8c6c5'
  on-secondary-fixed: '#1c1b1b'
  on-secondary-fixed-variant: '#474646'
  tertiary-fixed: '#e2e2e2'
  tertiary-fixed-dim: '#c6c6c7'
  on-tertiary-fixed: '#1a1c1c'
  on-tertiary-fixed-variant: '#454747'
  background: '#141313'
  on-background: '#e5e2e1'
  surface-variant: '#353434'
  bg-base: '#000000'
  surface-subtle: '#1A1A1E'
  border-subtle: '#27272A'
  border-strong: '#3F3F46'
  text-secondary: '#A1A1AA'
  text-muted: '#71717A'
typography:
  display-hero:
    fontFamily: Plus Jakarta Sans
    fontSize: 44px
    fontWeight: '800'
    lineHeight: 48px
    letterSpacing: -0.03em
  metric-counter:
    fontFamily: Plus Jakarta Sans
    fontSize: 36px
    fontWeight: '800'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 30px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: -0.01em
  body-reg:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.01em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  margin-page: 1.5rem
  gutter-card: 1rem
  stack-gap: 0.75rem
  tap-target-min: 44px
---

# TAP_CORE Mobile Application — UI/UX Design Specification

A comprehensive design documentation file (`design.md`) specifying the architectural layout, component system, user flows, and aesthetic standards for the high-contrast monochrome **TAP_CORE** tap-to-earn mobile application.

---

## 1. Design System & Style Guide

### 1.1 Aesthetic Philosophy
- **Style:** Minimalist High-Contrast Monochrome (Pure Black & Stark White).
- **Tone:** Professional, modern, sleek, and tactile.
- **Hierarchy:** High visual weight on primary numbers and actionable buttons; muted zinc/gray for secondary metadata.

### 1.2 Color Tokens
| Token Name | Hex Code | Purpose / Usage |
| :--- | :--- | :--- |
| `color-bg-base` | `#000000` | Deep pure black app background |
| `color-surface-card` | `#111111` | Primary elevated cards & modal sheets |
| `color-surface-subtle`| `#1A1A1E` | Input fields, secondary badges, graph pillars |
| `color-border-subtle` | `#27272A` | Structural borders, dividers, subtle outlines |
| `color-border-strong` | `#3F3F46` | Active input borders, focused state outlines |
| `color-text-primary`  | `#FFFFFF` | Primary headings, score digits, active icons |
| `color-text-secondary`| `#A1A1AA` | Supporting labels, tab titles, subtitle copy |
| `color-text-muted`    | `#71717A` | Inactive placeholders, disabled states |
| `color-cta-fill`      | `#FFFFFF` | Primary call-to-action button surface |
| `color-cta-text`      | `#000000` | Inverted text inside primary CTA |

### 1.3 Typography Scale
- **Primary Font Family:** Geometric Sans-Serif (`Inter`, `SF Pro Display`, or `Plus Jakarta Sans`).
- **Number Font Feature:** Tabular Numbers (`font-feature-settings: 'tnum' 1`).

| Style Key | Size | Weight | Line Height | Tracking / Spacing |
| :--- | :--- | :--- | :--- | :--- |
| `Display-Hero` | 44px | 800 (Extra Bold)| 48px | -0.03em |
| `Heading-Large` | 24px | 700 (Bold) | 30px | -0.02em |
| `Heading-Medium`| 18px | 600 (SemiBold) | 24px | -0.01em |
| `Body-Regular` | 14px | 400 (Regular) | 20px | Normal |
| `Body-Small` | 12px | 500 (Medium) | 16px | +0.01em |
| `Metric-Counter`| 36px | 800 (Extra Bold)| 40px | -0.02em |

### 1.4 Elevation, Borders & Radii
- **Card Radius:** `24px`
- **Bottom Sheet / Modal Top Radius:** `32px`
- **Button & Input Radius:** `16px`
- **Tap Action Target Radius:** `50%` (Fully Circular)
- **Standard Border Width:** `1px solid #27272A`
- **Shadows:** Minimal soft ambient shadows (`0px 8px 24px rgba(0,0,0,0.8)`).

---

## 2. Screen Architecture & User Flow

```
                     +-----------------------+
                     |  Splash / Initial App  |
                     +-----------+-----------+
                                 |
                     +-----------v-----------+
                     |  Auth Screen (Modal)  |
                     | [Sign In] [Register]  |
                     +-----------+-----------+
                                 |
                                 v
          +---------------------------------------------+
          |      Persistent 4-Tab Bottom Navigation     |
          +----------+-----------+-----------+----------+
                     |           |           |          |
         +-----------v+  +-------v---+  +----v------+ +-v----------+
         | Tab 1:     |  | Tab 2:    |  | Tab 3:    | | Tab 4:     |
         | Leaderboard|  | Tap-Tap   |  | Payout /  | | Settings & |
         | & Profiles |  | Engine    |  | Withdraw  | | Security   |
         +------------+  +-----------+  +-----------+ +------------+
```

---

## 3. Detailed Screen Specifications

### Screen 1: Authentication (Login & Registration)
* **Layout Structure:**
  - **Top Viewport (35%):**
    - Pure Jet Black (`#000000`).
    - App Brand Mark: Minimalist stark-white vector mark.
    - App Title: `TAP_CORE` (Display typography, tracked).
  - **Bottom Viewport (65%):**
    - Bottom modal sheet surface (`#111111`) with `32px` rounded top corners and `1px` subtle top border (`#27272A`).
    - Top segment switch: `[ Sign In ] | [ Register ]` in pill container (`#1A1A1E`).
* **Form Components:**
  - Email input field (`#1A1A1E` background, `16px` radius, `#71717A` placeholder).
  - Password input field with trailing "Show/Hide" toggle icon.
  - "Forgot Password?" right-aligned link (`#A1A1AA`).
* **Actions:**
  - Primary CTA Button: Full width, solid white (`#FFFFFF`), `16px` radius, bold black text: **"Continue"**.
  - Social Auth: Outlined black-and-white buttons for Apple and Google authentication.

---

### Screen 2: Tap-Tap Engine (Home Dashboard)
* **Top Header & Live Stats Dashboard:**
  - Full-width hero card (`#111111` surface, `24px` radius, `1px` border).
  - **Main Display Metric:**
    - Label: `TOTAL SCORE` (`12px`, uppercase, `#71717A`).
    - Large Counter: e.g., `1,428,950` (`36px`, bold, `#FFFFFF`).
  - **Milestone Progress Sub-bar:**
    - Label: `Progress to next $1.00 reward (3,600 / 5,000 taps)`.
    - Horizontal progress bar: `#1A1A1E` track with solid `#FFFFFF` active fill indicator.
* **Central Tap Engine:**
  - Massive circular tap button (`220px x 220px`) centered in screen.
  - Double-ring boundary design:
    - Outer ring: `1px solid #27272A` with `12px` breathing margin.
    - Inner surface: `#111111` with tactile press compression animation (`scale: 0.94`).
    - Center Icon: Bold white `+` glyph.
  - **Physics & FX:**
    - On-tap floating indicator `+1` rendered at touch coordinate, rising vertically and fading out over 600ms.
    - Haptic tactile feedback triggered on every valid tap event.

---

### Screen 3: Global Leaderboard & Public Profiles
* **Leaderboard Screen:**
  - Segmented toggle: `[ Global All-Time ]` | `[ Weekly Top 10 ]`.
  - **Incentive Banner:** Outlined card highlighting *"Top 10 Qualify for Weekly Real-Cash Payouts"*.
  - **Ranked User List:**
    - Each row card (`#111111`, `16px` radius):
      - Left: Rank badge (`#01`, `#02`, `#03` styled with white inverted badges; subsequent ranks with `#A1A1AA` labels).
      - Middle: User Avatar (circle), Username handle, Level indicator.
      - Right: Total Tap Score (bold tabular digits).
* **Public Profile Modal (On User Tap):**
  - Slides up as an interactive bottom drawer.
  - User Header: Large avatar, Display Name, Global Rank status.
  - Cumulative Stats: Lifetime Taps, Current Daily Streak, Payout Eligibility.
  - **Behavior & Activity Chart:**
    - 7-Day Monochrome Bar Chart (Monday to Sunday).
    - Bars rendered with `#FFFFFF` (peak days) and `#27272A` (off-peak days).
    - Bottom axis showing weekday initials (`M, T, W, T, F, S, S`).

---

### Screen 4: Withdrawals & Rewards Conversion
* **Balance Hero Card:**
  - Available Redeemable Balance: `$XX.XX USD` in `Display-Hero` font.
  - Formula Note: `Rate: 5,000 Valid Taps = $1.00 USD`.
* **Milestone Tiers:**
  - Grid of payout milestone cards:
    - Tier 1: `$5.00` (25,000 Taps)
    - Tier 2: `$10.00` (50,000 Taps)
    - Tier 3: `$25.00` (125,000 Taps)
    - Tier 4: `$50.00` (250,000 Taps)
  - Locked vs. Unlocked visual indicators.
* **Withdrawal Execution:**
  - Payment Method Selection: Bank Transfer, Digital Wallet, Crypto/P2P.
  - Primary CTA: **"Request Payout"** (Solid `#FFFFFF` button).

---

### Screen 5: Settings & Account Management
* **Sections:**
  - **Account Settings:** Edit Profile Name, Toggle Public Score Visibility on Leaderboard.
  - **Preferences:** Haptic Feedback Intensity (Off / Medium / Strong), Low Power Mode toggle.
  - **Security:** Reset Password, Two-Factor Authentication, Linked Accounts.
  - **Danger Zone:** Sign Out (Outlined Zinc) & Delete Account (Subtle Red / Dim Gray).

---

### Persistent Navigation Bar (Bottom)
- Floating or anchored bottom bar (`#000000` with top border `1px solid #27272A`).
- Four Icon Slots (Equal 25% width distribution):
  1. **Leaderboard:** Trophy / Rank Vector Icon.
  2. **Tap-Tap:** Central Bolt / Plus Vector Icon.
  3. **Withdraw:** Wallet / Currency Vector Icon.
  4. **Settings:** Gear / Sliders Vector Icon.
- Active State: Pure White `#FFFFFF` with small under-dot. Inactive State: Muted Zinc `#71717A`.
