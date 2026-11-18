# BizModule — Complete UI/UX Design Prompt for Generative AI

> **Purpose**: Feed this prompt to a generative AI (ChatGPT, Gemini, Midjourney, Figma AI, or similar) to produce a complete visual design system, screen flows, and interaction patterns for the BizModule Flutter mobile app.

---

## 🎯 Project Brief

**App Name**: BizModule  
**Platform**: Flutter mobile (Android-first, iOS later)  
**Design System**: Material 3 (Material You)  
**Target Market**: Nigerian small and medium businesses (SMBs) — retail shops, market traders, small manufacturers, service providers  
**Languages**: English (with potential for Pidgin English / Hausa / Yoruba / Igbo in future)

### Target Users

| Persona | Description | Tech Comfort |
|---|---|---|
| **Business Owner** | 30-55 years old, manages 1-3 small businesses (shops, market stalls). May have limited formal education. First time using business software. Uses WhatsApp and mobile banking daily. | Low to Medium |
| **Staff / Cashier** | 18-35 years old, hired to manage day-to-day sales. Needs to ring up sales FAST. May be shared across shifts. | Medium |
| **Accountant / Manager** | Handles reports, expenses, inventory orders. Slightly more tech-savvy. Needs data exports. | Medium to High |

### Key Environmental Constraints
- **Intermittent internet** — app MUST work offline and sync later; clear offline/online indicators
- **Data cost sensitivity** — users pay per MB; avoid heavy asset loading
- **Bright sunlight** — screens used outdoors in markets; needs high contrast
- **Dirty/wet hands** — large touch targets, forgiving gesture areas
- **Shared devices** — quick user/role switching needed
- **Low storage phones** — keep app lightweight

---

## 🎨 Design Philosophy: "Guided Confidence"

The design should make users feel **capable and in control** — never confused, never overwhelmed, but never patronized either. Think of it as a **friendly expert assistant**, not a toy.

### Core Principles

1. **Icon-First, Text-Second** — Every action should be understandable from its icon alone. Text labels reinforce, not replace. Use universally understood metaphors (shopping cart, barcode, wallet, box).

2. **Progressive Disclosure** — Show only what's needed NOW. Advanced features reveal themselves as users grow. First-time users see simplified views; power users unlock density.

3. **Instant Feedback** — Every tap produces immediate visual/haptic feedback. No silent failures. Success = green checkmark animation. Error = gentle shake + red highlight with plain-language explanation.

4. **Forgiving Design** — Undo for destructive actions. Confirmation dialogs only for irreversible operations (delete, void sale). Everything else is tappable without fear.

5. **Offline-Native** — The app never says "No internet connection" as an error. Instead, it works normally with a subtle status chip showing sync state. Data syncs silently when connection returns.

---

## 🖌️ Visual Identity

### Color Palette

Design a palette that feels **trustworthy, warm, and energetic** — reflecting Nigerian business culture.

| Role | Suggested Direction | Notes |
|---|---|---|
| **Primary** | Deep Teal / Forest Green (`#0D7377` range) | Trust, growth, money — resonates with business/finance |
| **Secondary** | Warm Amber / Gold (`#F5A623` range) | Energy, optimism, Nigerian cultural warmth |
| **Surface** | Off-white / Warm Gray (`#FAFAF8`) | Easy on eyes, works in bright sunlight |
| **Error** | Soft Coral Red (`#E74C3C`) | Not aggressive; clearly "something needs attention" |
| **Success** | Fresh Green (`#27AE60`) | Distinct from primary; "done/confirmed" |
| **Offline Indicator** | Muted Orange (`#E67E22`) | "Working locally" — not alarming |
| **Text Primary** | Near-black (`#1A1A2E`) | Maximum readability |
| **Text Secondary** | Warm Gray (`#6C7A89`) | De-emphasized but still readable |

Use Material 3's dynamic color theming — the palette adapts but these are the baseline seed colors.

### Typography

- **Primary Font**: Google Sans or Inter — clean, modern, highly legible at all sizes
- **Numbers/Money**: Use tabular (monospaced) figures for all financial amounts so columns align
- **Minimum body text**: 16sp (never smaller for any user-facing content)
- **Headers**: Bold, 20-28sp
- **Financial amounts**: 24-32sp, bold, primary color
- **Currency symbol** (₦): Always prefix, same weight as the number

### Iconography

- Use **filled icons** (not outlined) — they're more recognizable at small sizes and for users with lower visual acuity
- Icon size minimum: **24dp**, touch target minimum: **48dp**
- Consider custom illustrated icons for core modules (a small box for inventory, a receipt roll for POS, a calculator for expenses) — slightly playful, not corporate

### Corner Radius & Elevation

- Cards: **16dp** corner radius — friendly, approachable
- Buttons: **12dp** corner radius — clearly tappable
- Bottom sheet: **24dp** top corners — smooth drawer feel
- Use subtle shadows (elevation 1-2) rather than borders to separate elements
- Avoid sharp corners entirely — the app should feel "soft" and approachable

---

## 📱 App Structure & Navigation

### Bottom Navigation Bar (5 items max)

```
┌──────────────────────────────────────────────┐
│                                              │
│              [Active Screen]                 │
│                                              │
├──────┬──────┬──────┬──────┬──────────────────┤
│  🏠  │  📦  │  🛒  │  📊  │       ⚙️        │
│ Home │Stock │ Sell │Report│      More        │
└──────┴──────┴──────┴──────┴──────────────────┘
```

- **Home** (Dashboard) — Today's snapshot
- **Stock** (Inventory) — Products, stock levels, suppliers
- **Sell** (POS) — Quick sale screen — THE most used screen
- **Reports** (Dashboard analytics, expenses, sales history)
- **More** (Settings, Profile, Modules, Zakat Tracker, Receipts, Help)

The **Sell** tab should have a visually distinct treatment (larger icon, accent color, or FAB-style raised button) because it's the primary daily action.

### Top App Bar

```
┌──────────────────────────────────────────────┐
│ [Business Logo/Avatar]  Business Name  ▼  🔔 │
│                                         [sync]│
└──────────────────────────────────────────────┘
```

- **Business Switcher** (▼ dropdown): Users may own multiple businesses. Tapping shows a bottom sheet with business list + "Add Business" option
- **Sync Indicator**: Small animated icon — ✅ synced / 🔄 syncing / ⚠️ offline (queued changes count)
- **Notification Bell**: Badge count for low stock alerts, pending invitations, sync conflicts

---

## 📐 Screen-by-Screen Design Specifications

### 1. Onboarding Flow (First-Time Setup)

**Goal**: Get a new user from install → first sale in under 3 minutes.

#### Screen 1.1 — Welcome / Value Proposition (3 swipeable cards)
- Card 1: "Track your sales" — illustration of phone with sale notification
- Card 2: "Know your stock" — illustration of organized shelves with counts
- Card 3: "Grow your business" — illustration of upward chart with naira signs
- Each card: large illustration (60% of screen), bold headline, one-line subtitle
- Bottom: dot indicators + "Get Started" button (full-width, primary color)
- Skip option: subtle text link top-right

#### Screen 1.2 — Authentication
- **Phone number login** (primary — most Nigerian users don't have email habits)
- Big phone number input with Nigerian flag 🇳🇬 and +234 prefix
- OTP verification screen with auto-fill support
- Alternative: "Continue with Google" secondary button
- No password creation — reduce friction

#### Screen 1.3 — Business Setup (Wizard - 3 steps with progress bar)
- Step 1: "What's your business name?" — single large text input + business type dropdown (Retail, Food, Services, Manufacturing, Other)
- Step 2: "Add your first product" — name, price, optional photo (camera button). Show "Skip, I'll do this later" option
- Step 3: "You're ready!" — summary card + "Start Selling" CTA button
- Progress: horizontal stepper at top showing 1/3, 2/3, 3/3

#### States
- **Loading**: Skeleton shimmer on cards
- **Error**: Inline error messages below inputs (red text, shake animation)
- **Offline during setup**: Banner: "You're offline. Your setup will sync when connected." — allow completion anyway

---

### 2. Dashboard (Home)

**Goal**: At a glance, answer "How is my business doing TODAY?"

#### Layout
```
┌──────────────────────────────────────┐
│  Good morning, Alhaji! ☀️            │
│  [Business Name] ▼                   │
├──────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐   │
│  │ Today Sales  │  │ Items Sold  │   │
│  │ ₦ 45,200    │  │    23       │   │
│  │ ↑12% vs avg │  │ ↑5 vs avg  │   │
│  └─────────────┘  └─────────────┘   │
│  ┌─────────────┐  ┌─────────────┐   │
│  │ Expenses    │  │ Net Profit  │   │
│  │ ₦ 8,500     │  │ ₦ 36,700   │   │
│  │ 3 entries   │  │ ↑ healthy   │   │
│  └─────────────┘  └─────────────┘   │
├──────────────────────────────────────┤
│  ⚠️ Low Stock Alerts (3)        →   │
│  • Rice (5kg) — 2 bags left         │
│  • Palm Oil — 3 bottles left        │
├──────────────────────────────────────┤
│  📈 Sales Trend (7-day mini chart)  │
│  [sparkline graph]                   │
├──────────────────────────────────────┤
│  Recent Sales                    →   │
│  • ₦2,500 — 10:32 AM               │
│  • ₦850 — 9:15 AM                  │
│  • ₦12,000 — 8:45 AM               │
└──────────────────────────────────────┘
```

#### Design Notes
- **Greeting**: Personalized with time-of-day greeting + user's name
- **Stat Cards**: 2x2 grid, each card has: label (small, secondary color), value (large, bold, primary), trend indicator (small, green/red arrow with context)
- **Low Stock Alerts**: Amber warning card, expandable, tapping navigates to that product
- **Sales Trend**: 7-day sparkline, no axis labels needed — just the visual shape
- **Recent Sales**: Scrollable list, each row shows amount + time. Tap to see detail

#### States
- **Empty** (new business, no sales yet): Friendly illustration + "Make your first sale!" CTA pointing to POS tab
- **Loading**: Skeleton shimmer matching card layout
- **Offline**: Subtle chip at top: "📴 Offline — showing local data" (warm orange, not red)
- **Error**: "Couldn't load dashboard. Pull to refresh." with retry illustration

---

### 3. POS / Sell Screen (MOST CRITICAL)

**Goal**: Complete a sale in under 10 seconds. This screen must be FAST and FRICTIONLESS.

#### Layout — Product Grid Mode (Default)
```
┌──────────────────────────────────────┐
│  🔍 Search products...    [≡] [▦]   │
│  [📷 Scan Barcode]                   │
├──────────────────────────────────────┤
│  Categories: [All] [Food] [Drinks].. │
├──────────────────────────────────────┤
│  ┌────────┐ ┌────────┐ ┌────────┐   │
│  │ 🍚     │ │ 🫒     │ │ 🧴     │   │
│  │ Rice   │ │ Oil    │ │ Soap   │   │
│  │ ₦4,500 │ │ ₦2,200 │ │ ₦350  │   │
│  │ [+]    │ │ [+]    │ │ [+]    │   │
│  └────────┘ └────────┘ └────────┘   │
│  ┌────────┐ ┌────────┐ ┌────────┐   │
│  │ 🥤     │ │ 📦     │ │ 🧹     │   │
│  │ Drink  │ │ Sugar  │ │ Broom  │   │
│  │ ₦200   │ │ ₦1,800 │ │ ₦500  │   │
│  │ [+]    │ │ [+]    │ │ [+]    │   │
│  └────────┘ └────────┘ └────────┘   │
├──────────────────────────────────────┤
│  🛒 Cart (3 items)      ₦7,050   ▲  │
└──────────────────────────────────────┘
```

#### Interaction Flow
1. **Add to cart**: Tap product card → item added with "+1" animation. Tap again to increment. Long-press to set custom quantity.
2. **Cart preview**: Sticky bottom bar showing item count + total. Pull up to expand full cart.
3. **Cart expanded** (bottom sheet):
   - Each item: name, qty (with -/+ steppers), unit price, line total, swipe-to-remove
   - Discount field (optional): flat amount or percentage toggle
   - Customer name (optional): text input + recent customers dropdown
   - **Total**: Large, bold, impossible to miss
   - **Charge ₦7,050** — Big green button, full width
4. **Payment method** (after tapping Charge):
   - Quick selection: [💵 Cash] [📱 Transfer] [💳 POS/Card] [📝 Credit]
   - For Cash: amount tendered input + auto-calculated change
   - For Transfer: show business account details + "Confirm Received" button
   - For Credit: customer selection required + due date
5. **Sale Complete**: 
   - ✅ Full-screen success animation (green checkmark, brief)
   - Receipt preview with [📤 Share via WhatsApp] [🖨️ Print] [✅ Done] buttons
   - Auto-returns to POS grid after 3 seconds if no action

#### Product Display Modes
- **Grid** (default): 3 columns, product image/emoji + name + price
- **List**: Single column, more detail per row (shows stock count)
- Toggle via [≡] / [▦] icons in search bar

#### States
- **Empty inventory**: "Add your first product to start selling" + quick-add button
- **No search results**: "No products match '[query]'" + "Add new product" shortcut
- **Out of stock item**: Grayed out card with "Out of stock" badge, not tappable
- **Offline**: Normal operation (sales queue locally). Subtle sync indicator in cart.

---

### 4. Inventory / Stock

**Goal**: Know what you have, what's running low, what to reorder.

#### Layout — Product List
```
┌──────────────────────────────────────┐
│  Inventory              [+ Add]  🔍  │
├──────────────────────────────────────┤
│  Filter: [All] [Low Stock] [Out]     │
│  Sort:   [Name ▼] [Stock] [Price]    │
├──────────────────────────────────────┤
│  ┌──────────────────────────────┐    │
│  │ 🍚 Rice (5kg)          12 ▼ │    │
│  │ ₦4,500  •  Cost: ₦3,800    │    │
│  │ ████████░░░░ Low stock      │    │
│  └──────────────────────────────┘    │
│  ┌──────────────────────────────┐    │
│  │ 🫒 Palm Oil (1L)       45   │    │
│  │ ₦2,200  •  Cost: ₦1,900    │    │
│  │ █████████████████ OK        │    │
│  └──────────────────────────────┘    │
│  ...                                 │
└──────────────────────────────────────┘
```

#### Product Detail Screen
- Hero image / emoji at top
- Editable fields: Name, Price, Cost, SKU/Barcode, Category, Description
- **Stock section**: Current quantity + "Stock In" / "Stock Out" quick actions
- **Stock history**: Timeline of stock movements (added 50 on Oct 12, sold 3 on Oct 13...)
- **Supplier link**: Which supplier provides this item
- **Archive** (not delete): Soft removal with "Archived" filter to restore

#### Add Product Flow
- Quick add: Name + Price only (2 fields!) → done
- Full add: Name, Price, Cost, Category, Barcode (scan), Photo (camera), Initial Stock, Supplier, Description
- **Barcode scanning**: Camera viewfinder with overlay guide. If barcode found in database, auto-fill product name

#### Suppliers Sub-Tab
- List of suppliers with contact info
- Tap to see all products from that supplier
- Quick actions: 📞 Call, 💬 WhatsApp

#### States
- **Empty**: "Your inventory is empty. Add your first product!" + illustration of empty shelves
- **All filtered out**: "No products match these filters" + clear filters button
- **Low stock**: Amber progress bar + stock count in red if below threshold

---

### 5. Expenses

**Goal**: Track where money goes. Simple categorized expense logging.

#### Layout
```
┌──────────────────────────────────────┐
│  Expenses                    [+ Add] │
│  November 2026               ◀  ▶   │
├──────────────────────────────────────┤
│  Total: ₦125,400                     │
│  ┌──────────────────────────────┐    │
│  │ [Donut chart by category]    │    │
│  │  🏪 Rent: 40%               │    │
│  │  📦 Stock: 35%              │    │
│  │  🚗 Transport: 15%          │    │
│  │  📱 Other: 10%              │    │
│  └──────────────────────────────┘    │
├──────────────────────────────────────┤
│  Today, Nov 4                        │
│  • 🚗 Transport — ₦2,500           │
│  • 📦 Stock Purchase — ₦15,000     │
│  Yesterday, Nov 3                    │
│  • 🏪 Shop Rent — ₦80,000          │
│  ...                                 │
└──────────────────────────────────────┘
```

#### Add Expense
- Bottom sheet with: Amount (big number input), Category (icon grid picker), Description (optional), Date (defaults to today)
- **Quick categories** with icons: Rent, Stock/Inventory, Transport, Salary, Utilities, Food, Maintenance, Other
- Optional: attach photo of receipt (camera)

---

### 6. Receipts

**Goal**: View past transactions and share proof of sale.

#### Layout
- Searchable list of all completed sales, newest first
- Each row: date, time, amount, item count, payment method icon
- Tap to open receipt detail:
  - Itemized list with quantities and prices
  - Payment method and amount
  - Customer name (if recorded)
  - Business name, address, phone
  - **Actions**: [📤 Share WhatsApp] [🖨️ Print] [📋 Copy]
- Receipt format: clean, simple, looks like a real receipt when shared as image

---

### 7. Settings & Profile

#### Settings Screen
```
┌──────────────────────────────────────┐
│  Settings                            │
├──────────────────────────────────────┤
│  👤 Profile                      →   │
│  🏪 Business Details             →   │
│  🧩 Modules                      →   │
│  🖨️ Receipt Settings             →   │
│  🔔 Notifications                →   │
│  🌙 Dark Mode               [toggle] │
│  🌐 Language                     →   │
│  📱 About BizModule              →   │
│  🚪 Sign Out                         │
└──────────────────────────────────────┘
```

#### Modules Screen (Core Feature)
This is where the "modular" nature shines. Users enable/disable business tools:

```
┌──────────────────────────────────────┐
│  My Modules                          │
│  Customize your business tools       │
├──────────────────────────────────────┤
│  ┌──────────────────────────────┐    │
│  │ 📦 Inventory          [ON ✓] │    │
│  │ Track products & stock       │    │
│  └──────────────────────────────┘    │
│  ┌──────────────────────────────┐    │
│  │ 🛒 Point of Sale      [ON ✓] │    │
│  │ Sell & record payments       │    │
│  └──────────────────────────────┘    │
│  ┌──────────────────────────────┐    │
│  │ 💰 Expense Tracker    [ON ✓] │    │
│  │ Track business expenses      │    │
│  └──────────────────────────────┘    │
│  ┌──────────────────────────────┐    │
│  │ 🕌 Zakat Calculator   [OFF]  │    │
│  │ Calculate & track zakat      │    │
│  └──────────────────────────────┘    │
│  ┌──────────────────────────────┐    │
│  │ 👥 Customer Manager   [OFF]  │    │
│  │ Track customers & credit     │    │
│  └──────────────────────────────┘    │
└──────────────────────────────────────┘
```

- Each module: icon, name, one-line description, toggle switch
- Toggling OFF shows confirmation: "Hide [Module]? You can re-enable anytime. Your data is safe."
- Toggling ON: module appears in navigation immediately with brief tooltip intro

#### Business Details
- Business name, type, address, phone, logo upload
- **Staff Management**: Invite staff via phone number, assign roles (Owner, Manager, Cashier)
- **Role Permissions**: Visual grid showing what each role can do

#### Profile
- Name, phone, email
- Business memberships list (cards for each business they belong to)
- Switch active business

---

### 8. Zakat Tracker

**Goal**: Help Muslim business owners calculate and track annual zakat obligations.

#### Layout
- **Assets input**: Cash on hand, inventory value, receivables, savings
- **Liabilities input**: Debts, payables
- **Calculation**: Auto-calculates zakatable amount and 2.5% due
- **Nisab threshold**: Shows current gold/silver nisab value
- **Payment tracking**: Mark zakat as paid, to whom, when
- **Annual reminder**: Notification when zakat year completes

---

### 9. Customer Management

**Goal**: Track who buys from you, especially credit customers.

#### Layout
- Customer list with search
- Each customer card: name, phone, total purchases, outstanding credit balance
- **Credit Management**: Running balance, payment history, "Send Reminder" (via WhatsApp/SMS)
- **Quick actions**: 📞 Call, 💬 WhatsApp, 📝 Add Payment

---

## 🔄 Universal States & Patterns

### Loading States
- **Skeleton screens** (shimmer) matching the layout of actual content — NEVER a centered spinner
- Duration: if loading takes > 500ms, show skeleton. Under 500ms, show content directly (no flash)

### Empty States
Every list/screen has a custom empty state:
- Relevant illustration (friendly, not sad)
- Brief message explaining what goes here
- ONE clear CTA button to create the first item
- Example: Empty inventory → illustration of empty shelves → "Add your first product" button

### Error States
- **Network error**: "Couldn't connect. You're offline but your data is safe. We'll sync when you're back online." + [Retry] button
- **Generic error**: "Something went wrong. Try again." + [Retry] + [Report Issue]
- **Form validation**: Inline errors below each field, red border, shake animation
- NEVER show technical error messages to users

### Offline Mode
- **Status chip** in app bar: 🟢 "Synced" / 🟠 "Offline (3 pending)" / 🔄 "Syncing..."
- All CRUD operations work offline
- When back online: automatic sync with subtle "✅ All caught up!" toast
- **Conflict resolution**: If same record edited on web and mobile, show side-by-side comparison with "Keep mine" / "Keep other" / "Keep both" options

### Pull-to-Refresh
- Available on all list screens
- Custom animation: business-themed (e.g., cash register "ka-ching" or box opening)

### Confirmation & Feedback
- **Success**: Brief green toast at bottom (auto-dismiss 2s) or inline success state
- **Destructive actions**: Bottom sheet confirmation with clear consequences ("This will delete 5 products. This cannot be undone.")
- **Haptic feedback**: Light vibration on add-to-cart, medium on sale completion

---

## 🌗 Dark Mode

- Full dark theme using Material 3 dark color scheme
- Surface: `#121212` with slight warm tint
- Cards: `#1E1E2E` — slightly elevated from background
- Primary color stays the same (teal/green pops beautifully on dark)
- Amber accent becomes slightly more muted
- All text meets WCAG AA contrast ratios minimum

---

## 📐 Responsive & Accessibility

### Touch Targets
- Minimum 48x48dp for ALL interactive elements
- Spacing between tappable items: minimum 8dp
- Bottom navigation icons: 32dp with 48dp touch target

### Text Scaling
- Support system font size up to 200%
- Test all screens at largest system font — nothing should clip or overflow

### Accessibility
- All icons have semantic labels
- Color is NEVER the only indicator (always paired with icon or text)
- Screen reader support for all interactive elements
- Sufficient contrast ratios (4.5:1 minimum for text)

---

## 🎬 Animations & Micro-interactions

Keep animations **purposeful and brief** (150-300ms). They should guide attention, not entertain:

| Interaction | Animation |
|---|---|
| Add to cart | Product card briefly scales up (1.05x) + quantity badge bounces in |
| Remove from cart | Item slides out left + cart total animates down |
| Sale complete | Green checkmark draws itself (Lottie) + confetti burst (subtle, 1s) |
| Screen transition | Shared element transitions for product images |
| Pull to refresh | Custom branded loading animation |
| Tab switch | Crossfade (200ms) |
| Bottom sheet | Spring physics slide-up |
| Toggle module ON | Satisfying "click" haptic + switch slides with color fill |
| Offline → Online | Status chip color transition (orange → green) with "Synced ✅" |
| Number change | Odometer-style rolling number animation for financial amounts |

---

## 🖼️ Illustration Style

- **Style**: Flat illustration with subtle gradients, 2-3 colors per illustration
- **Characters**: Diverse, Nigerian-looking characters (various skin tones, traditional and modern dress, hijabs represented)
- **Scenes**: Market stalls, small shops, phones, products, naira notes/coins
- **Mood**: Optimistic, warm, professional — not childish, not corporate
- **Usage**: Onboarding, empty states, error states, feature discovery tooltips

---

## 📱 Screen Flow Summary

Please generate complete, pixel-ready screen designs for the following flows:

### Flow 1: First-Time User Journey
`Install → Welcome Slides (3) → Phone Login → OTP → Business Setup (3 steps) → Dashboard (empty state) → Add First Product → Make First Sale → Sale Complete → Dashboard (with data)`

### Flow 2: Daily Cashier Workflow
`Open App → Dashboard → Tap "Sell" → Search/Browse Products → Add Items to Cart → Review Cart → Select Payment Method → Enter Amount Tendered → Sale Complete → Share Receipt via WhatsApp → Return to POS`

### Flow 3: Inventory Management
`Stock Tab → Browse Products → Tap Product → View Detail → Edit Price → Stock In (add 50 units) → Back to List → Filter "Low Stock" → Tap Low Item → Reorder from Supplier (WhatsApp)`

### Flow 4: End-of-Day Review
`Dashboard → View Today's Sales → View Expenses → Add New Expense → Check Net Profit → View Reports → Export Daily Summary`

### Flow 5: Business Owner Setup
`Settings → Business Details → Invite Staff → Set Roles → Staff Receives Invitation → Staff Signs Up → Staff Dashboard (limited view)`

### Flow 6: Offline Usage
`Normal operation → Connection lost (subtle indicator change) → Make sale (works normally) → Add product (works normally) → Connection returns → Auto-sync animation → "All caught up" toast`

### Flow 7: Module Customization
`Settings → Modules → Enable "Customer Manager" → Module appears in navigation → First-time tooltip → Browse empty Customer list → Add first customer`

### Flow 8: Multi-Business
`Dashboard → Tap Business Name dropdown → Business Switcher bottom sheet → Select different business → Dashboard updates with that business's data → All tabs reflect new business context`

---

## 📋 Deliverables Checklist

When generating designs, please provide:

- [ ] **Complete color palette** with hex codes, applied to light and dark themes
- [ ] **Typography scale** showing all text styles used in the app
- [ ] **Icon set** for all modules and common actions
- [ ] **Component library**: Buttons, cards, inputs, toggles, badges, chips, bottom sheets, dialogs, toasts, navigation bar
- [ ] **All screens listed above** in both light and dark mode
- [ ] **All states**: empty, loading (skeleton), populated, error, offline
- [ ] **Onboarding flow** complete with illustrations
- [ ] **POS flow** with all interaction states (empty cart, items in cart, payment selection, success)
- [ ] **Flow diagrams** showing navigation between screens
- [ ] **Responsive behavior** notes for different screen sizes (5" to 7" phones)

---

> [!TIP]
> **For image generation AI (Midjourney/DALL-E)**: Use this prompt as context, then ask for specific screens one at a time: "Generate a mobile app screenshot for the Dashboard screen of BizModule, following the design specifications above. Material 3, teal primary color, warm amber accents, Nigerian SMB context."
>
> **For conversational AI (ChatGPT/Gemini)**: Paste this entire prompt and ask: "Based on this design spec, generate a Figma-ready component library and screen wireframes for each flow listed. Start with the POS/Sell screen as it's the highest priority."
>
> **For Figma AI / design tools**: Use the color palette and component specs to set up a design system first, then generate screens following the layout specs above.
