🎯 COMPREHENSIVE ONBOARDING FLOW EXPLANATION
📊 OVERVIEW

    Total Steps: 7
    Progress Bar: Animated gradient progress bar at the top
    Navigation: Back/Continue buttons at the bottom
    Validation: Smart validation prevents proceeding without required fields
    Theme: Fully themed with user-selected color scheme
    AI Assistant: Bizi is available throughout onboarding

🔍 DETAILED STEP-BY-STEP BREAKDOWN
STEP 0: LANGUAGE SELECTION 🌍
UI Layout:

┌─────────────────────────────────────────────┐
│         [Globe Icon in Gradient Circle]     │
│                                             │
│      Welcome to BizMod! 🎉                  │
│   Let's get you set up in just a few minutes│
│                                             │
│   ┌─────────────────────────────────────┐  │
│   │  Choose your language               │  │
│   │                                     │  │
│   │  ┌──────────┐    ┌──────────┐      │  │
│   │  │ 🇬🇧       │    │ 🇳🇬       │      │  │
│   │  │ English  │    │ Hausa    │      │  │
│   │  └──────────┘    └──────────┘      │  │
│   │                                     │  │
│   │  ┌──────────┐    ┌──────────┐      │  │
│   │  │ 🇳🇬       │    │ 🇳🇬       │      │  │
│   │  │ Yoruba   │    │ Igbo     │      │  │
│   │  └──────────┘    └──────────┘      │  │
│   └─────────────────────────────────────┘  │
└─────────────────────────────────────────────┘

Elements:

    Hero Section:
        Animated gradient circle with Globe icon (scales in with spring animation)
        Large welcome heading
        Friendly subtitle
    Language Cards:
        2x2 grid layout
        Each card shows flag emoji + language name
        Hover effect: scales to 1.02x
        Selected: Indigo border + gradient background
        Tap effect: scales to 0.98x

Data Collected:

    language: string ("en", "ha", "yo", "ig")

Validation:

    ✅ REQUIRED - Must select a language
    Cannot proceed without selection

Logic:

    Default: "en" (English)
    Single selection only
    Clicking a card sets the language

STEP 1: BUSINESS PROFILE 📝
UI Layout:

┌──────────────────────────────────────────────────┐
│      Tell us about your business                 │
│   This helps us customize BizMod for you         │
│                                                   │
│  ┌────────────────────────────────────────────┐  │
│  │ Business Name *                            │  │
│  │ [________________________]                 │  │
│  │                                            │  │
│  │ Industry Type *                            │  │
│  │ ┌─────────┐ ┌─────────┐ ┌─────────┐       │  │
│  │ │🏪 Retail│ │💇Services│ │📦Wholsle│       │  │
│  │ │E-commerce│ │Salons   │ │Distrib  │       │  │
│  │ └─────────┘ └─────────┘ └─────────┘       │  │
│  │ (6 options in 2-column grid)               │  │
│  │                                            │  │
│  │ Business Size *                            │  │
│  │ ┌────┐ ┌────┐ ┌────┐ ┌────┐               │  │
│  │ │👤  │ │👥  │ │👨👩👧│ │🏢  │               │  │
│  │ │Just│ │Small│ │Grow│ │Est │               │  │
│  │ │me  │ │team │ │ing │ │ablsh│               │  │
│  │ └────┘ └────┘ └────┘ └────┘               │  │
│  │                                            │  │
│  │ Location(s)                                │  │
│  │ [Lagos, Victoria Island______]             │  │
│  │ + Add another location                     │  │
│  │                                            │  │
│  │ ☐ I manage multiple businesses            │  │
│  └────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────┘

Elements:

    Business Name Input:
        Text input field
        Placeholder: "e.g., Chic Boutique"
        Full width, rounded border
        Focus: Border turns indigo

    Industry Selection:
        2-column grid (responsive)
        6 industry cards:
            🏪 Retail & E-commerce
            💇 Services
            📦 Wholesale & Distribution
            🍔 Food & Beverage
            🏥 Healthcare
            💼 Other
        Each shows icon + name + description
        Selected: Indigo border + light indigo background

    Business Size:
        4-column grid
        Cards with emoji + name + employee range:
            👤 Just me (1 person)
            👥 Small team (2-10)
            👨‍👩‍👧‍👦 Growing (11-50)
            🏢 Established (50+)

    Locations:
        Dynamic array of text inputs
        Starts with 1 empty field
        "+ Add another location" button
        Placeholder: "e.g., Lagos, Victoria Island"

    Multiple Businesses:
        Checkbox at bottom
        Separated by border-top

Data Collected:

{
  businessName: string,        // e.g., "Masanawa Clothing"
  industry: string,            // "retail", "services", etc.
  businessSize: string,        // "solo", "small", "medium", "large"
  locations: string[],         // ["Kaduna", "Lagos"]
  hasMultipleBusinesses: boolean // true/false
}

Validation:

    ✅ REQUIRED:
        Business name must not be empty
        Must select an industry
        Must select a business size
    ⚪ OPTIONAL:
        Locations (can be added later)
        Multiple businesses checkbox

Logic:

    Locations array starts with [""]
    Empty locations are filtered out before submission
    All text fields trimmed before validation

STEP 2: GOALS 🎯
UI Layout:

┌────────────────────────────────────────────┐
│       [Target Icon in Gradient Circle]     │
│                                            │
│         What are your goals?               │
│  Select all that apply (helps recommend    │
│           the right features)              │
│                                            │
│  ┌──────────────────────────────────────┐ │
│  │ ┌────────────┐  ┌────────────┐       │ │
│  │ │📦 Track    │  │📈 Increase │       │ │
│  │ │  inventory │  │   sales    │ ✓     │ │
│  │ └────────────┘  └────────────┘       │ │
│  │                                      │ │
│  │ ┌────────────┐  ┌────────────┐       │ │
│  │ │💰 Better   │  │✅ Manage   │       │ │
│  │ │  finance   │  │   CRM      │       │ │
│  │ └────────────┘  └────────────┘       │ │
│  │                                      │ │
│  │ (8 goals in 2-column grid)          │ │
│  │                                      │ │
│  │    I'll figure this out later →     │ │
│  └──────────────────────────────────────┘ │
└────────────────────────────────────────────┘

Elements:

    Header:
        Animated Target icon in gradient circle
        Heading + explanatory text

    Goal Cards:
        2-column grid, 8 options total:
            📦 Track inventory accurately
            📈 Increase sales & revenue
            💰 Better financial management
            ✅ Manage customer relationships
            📊 Understand my business data
            ⏰ Save time on daily operations
            🚚 Manage deliveries efficiently
            💬 Communicate better with customers
        Each card:
            Icon in colored box (changes when selected)
            Goal text
            Checkmark appears when selected
        Multi-select enabled

    Skip Link:
        Bottom center
        "I'll figure this out later →"
        Triggers handleNext() directly

Data Collected:

{
  goals: string[]  // ["inventory", "sales", "finance", "crm", "analytics", "time", "delivery", "communication"]
}

Validation:

    ⚪ OPTIONAL - Can proceed without selecting any goals
    Multi-select allowed (0 to 8 goals)

Logic:

const toggleGoal = (goalId: string) => {
  if (goals.includes(goalId)) {
    // Remove if already selected
    goals = goals.filter(g => g !== goalId);
  } else {
    // Add if not selected
    goals = [...goals, goalId];
  }
};

    Selected goals feed into AI module recommendations in Step 3
    Skip button bypasses selection entirely

STEP 3: AI MODULE RECOMMENDATIONS 🤖✨
UI Layout:

┌─────────────────────────────────────────────────┐
│      [Sparkles Icon in Gradient Circle]         │
│                                                 │
│       Bizi's Recommendations for You            │
│   Based on your retail business                 │
│                                                 │
│  ┌───────────────────────────────────────────┐ │
│  │ [Bizi Avatar]  💡 Bizi says:              │ │
│  │ "I've analyzed your business needs and     │ │
│  │  selected the perfect modules..."          │ │
│  └───────────────────────────────────────────┘ │
│                                                 │
│  ┌───────────────────────────────────────────┐ │
│  │ Select Your Modules                        │ │
│  │                                            │ │
│  │ ┌──────────────────────────────────────┐  │ │
│  │ │📦 Inventory Management [Recommended]  │  │ │
│  │ │✨ Essential for tracking your products│ ✓│ │
│  │ └──────────────────────────────────────┘  │ │
│  │                                            │ │
│  │ ┌──────────────────────────────────────┐  │ │
│  │ │🛒 Sales & POS [Recommended]          │  │ │
│  │ │✨ Perfect for your retail operations │ ✓│ │
│  │ └──────────────────────────────────────┘  │ │
│  │                                            │ │
│  │ ┌──────────────────────────────────────┐  │ │
│  │ │ ⚡ Free Tier Benefits                 │  │ │
│  │ │ ✓ Up to 2 modules FREE                │  │ │
│  │ │ ✓ 60 sales/month                      │  │ │
│  │ │ ✓ 50 products                         │  │ │
│  │ │ ✓ 100 customers                       │  │ │
│  │ │ ✓ Full AI assistant - always free!    │  │ │
│  │ │                                       │  │ │
│  │ │ Selected: 2 modules - Perfect! 🎉    │  │ │
│  │ └──────────────────────────────────────┘  │ │
│  └───────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘

Elements:

    Bizi Message Box:
        Gradient background (indigo to cyan)
        Bizi's circular avatar
        Personalized message explaining recommendations

    Module Cards:
        Full-width cards, stacked vertically
        Each shows:
            Icon in colored box
            Module name
            "Recommended" badge (yellow)
            AI reason/explanation with sparkle emoji
            Checkmark when selected
        Staggered entrance animation (0.1s delay each)
        Multi-select enabled

    Free Tier Info Box:
        Green gradient background
        Zap icon
        Lists all free tier limitations
        Dynamic text: Shows module count and if it fits free tier

AI Recommendation Logic:

getRecommendedModules() {
  modules = [];
  
  // 1. INDUSTRY-BASED RECOMMENDATIONS
  if (industry === "retail" || industry === "wholesale") {
    modules.push(
      { id: "inventory", reason: "Essential for tracking your products" },
      { id: "sales", reason: "Perfect for your retail operations" }
    );
  }
  
  if (industry === "services") {
    modules.push(
      { id: "scheduling", reason: "Manage appointments efficiently" },
      { id: "crm", reason: "Build stronger customer relationships" }
    );
  }
  
  // 2. GOAL-BASED RECOMMENDATIONS
  if (goals.includes("finance")) {
    modules.push({ id: "accounting", reason: "Track your finances effectively" });
  }
  
  if (goals.includes("analytics")) {
    modules.push({ id: "analytics", reason: "You want to understand your data" });
  }
  
  if (goals.includes("communication")) {
    modules.push({ id: "sms", reason: "Stay connected with customers" });
  }
  
  if (goals.includes("delivery")) {
    modules.push({ id: "delivery", reason: "Streamline your logistics" });
  }
  
  // 3. ALWAYS SUGGEST CRM (if not already added)
  if (!modules.find(m => m.id === "crm")) {
    modules.push({ id: "crm", reason: "Build customer loyalty" });
  }
  
  return modules;
}

Available Modules:

    📦 Inventory Management
    🛒 Sales & POS
    ✅ Customer Relations (CRM)
    💰 Accounting & Finance
    📅 Scheduling & Booking
    📊 Advanced Analytics
    💬 SMS & Messaging
    🚚 Delivery Management

Data Collected:

{
  selectedModules: string[]  // ["inventory", "sales", "crm"]
}

Validation:

    ✅ REQUIRED - Must select at least 1 module
    Multi-select enabled (no upper limit)

Pricing Logic:

    ✅ 0-2 modules: FREE tier
    ⚠️ 3+ modules: Paid plan required
    Info box shows real-time feedback

STEP 4: QUICK SETUP ⚙️
UI Layout:

┌────────────────────────────────────────┐
│         Quick Setup                    │
│   Let's configure a few basics (optional)│
│                                        │
│  ┌──────────────────────────────────┐ │
│  │ Preferred Currency                │ │
│  │                                  │ │
│  │ ┌────────┐ ┌────────┐ ┌────────┐ │ │
│  │ │ 🇳🇬     │ │ 🇺🇸     │ │ 🌍     │ │ │
│  │ │₦ Naira │ │$ Dollar│ │Multi-  │ │ │
│  │ │        │ │        │ │currency│ │ │
│  │ └────────┘ └────────┘ └────────┘ │ │
│  │                                  │ │
│  │ ┌──────────────────────────────┐ │ │
│  │ │ 📤 Import Existing Data      │ │ │
│  │ │                              │ │ │
│  │ │ Already have products,       │ │ │
│  │ │ customers, or sales data?    │ │ │
│  │ │ We can help you migrate...   │ │ │
│  │ │                              │ │ │
│  │ │ ☐ Yes, I want to import data │ │ │
│  │ │    later                     │ │ │
│  │ └──────────────────────────────┘ │ │
│  │                                  │ │
│  │     Skip this step →             │ │
│  └──────────────────────────────────┘ │
└────────────────────────────────────────┘

Elements:

    Currency Selection:
        3-column grid
        Options:
            🇳🇬 ₦ Naira (NGN) - Default
            🇺🇸 $ Dollar (USD)
            🌍 Multi-currency (MULTI)
        Cards with flag + symbol + name
        Single selection

    Import Data Section:
        Blue info box with border
        Upload icon
        Heading + explanatory text
        Checkbox: "Yes, I want to import data later"
        Does NOT actually import - just flags intent

    Skip Link:
        "Skip this step →"
        Bottom center

Data Collected:

{
  currency: string,      // "NGN", "USD", "MULTI"
  importData: boolean    // true/false
}

Validation:

    ⚪ FULLY OPTIONAL - Can skip entirely
    Currency defaults to "NGN"
    Import defaults to false

Logic:

    Currency: Single selection (replaces previous)
    Import: Simple checkbox toggle
    Skip button proceeds without changes

STEP 5: TEAM INVITATION 👥
UI Layout:

┌────────────────────────────────────────────┐
│       [Users Icon in Gradient Circle]      │
│                                            │
│         Invite Your Team                   │
│  Collaborate with your team members (optional)│
│                                            │
│  ┌──────────────────────────────────────┐ │
│  │ Team Member Emails                   │ │
│  │                                      │ │
│  │ [colleague@company.com_________]     │ │
│  │ [colleague@company.com_________]     │ │
│  │                                      │ │
│  │ 📧 Add another team member           │ │
│  │                                      │ │
│  │ ┌──────────────────────────────────┐ │ │
│  │ │ Team Roles Available:            │ │ │
│  │ │ 👑 Admin - Full access           │ │ │
│  │ │ 👔 Manager - Operations & reports│ │ │
│  │ │ 👤 Staff - Daily operations      │ │ │
│  │ │                                  │ │ │
│  │ │ You can set roles after sending  │ │ │
│  │ └──────────────────────────────────┘ │ │
│  │                                      │ │
│  │   I'll add team members later →      │ │
│  └──────────────────────────────────────┘ │
└────────────────────────────────────────────┘

Elements:

    Email Input Fields:
        Dynamic array (starts with 1 empty field)
        Each input:
            Type: email
            Placeholder: "colleague@company.com"
            Full width
        Validation happens after submission

    Add Button:
        Link-style button with Mail icon
        "Add another team member"
        Adds new empty field to array

    Team Roles Info Box:
        Gray background
        Lists 3 available roles with icons:
            👑 Admin (full access)
            👔 Manager (operations + reports)
            👤 Staff (daily operations only)
        Note: Roles assigned after sending invites

    Skip Link:
        "I'll add team members later →"

Data Collected:

{
  teamMembers: string[]  // ["user1@email.com", "user2@email.com"]
}

Validation:

    ⚪ FULLY OPTIONAL - Can skip entirely
    No email validation at this step
    Empty emails filtered out before submission

Logic:

// Starts with one empty field
teamEmails = [""];

// Add new field
addTeamMember() {
  teamEmails = [...teamEmails, ""];
}

// Update specific field
updateTeamEmail(index, value) {
  teamEmails[index] = value;
}

// On submit: filter out empty emails
teamMembers: teamEmails.filter(e => e.trim())

STEP 6: MEET BIZI & SUCCESS 🎉
UI Layout:

┌─────────────────────────────────────────────────┐
│      [Large Bizi Avatar with Sparkles]          │
│           (Animated rotation + sparkle)         │
│                                                 │
│            Meet Bizi! 🎉                        │
│       Your AI Business Companion                │
│                                                 │
│  ┌───────────────────────────────────────────┐ │
│  │ What I Can Do For You:                    │ │
│  │                                           │ │
│  │ ┌───────┐ ┌───────┐                       │ │
│  │ │💬     │ │📊     │ (6 cards in 2x3 grid) │ │
│  │ │Answer │ │Reports│                       │ │
│  │ │questions│ │& data │                       │ │
│  │ └───────┘ └───────┘                       │ │
│  │                                           │ │
│  │ *Voice interaction coming soon!           │ │
│  │                                           │ │
│  │ ┌─────────────────────────────────────┐   │ │
│  │ │ 💡 Try asking Bizi:                 │   │ │
│  │ │ • "How do I create my first invoice?"│   │ │
│  │ │ • "Show me my sales from last week" │   │ │
│  │ │ • "What products are low in stock?" │   │ │
│  │ │ • "Help me set up payment methods"  │   │ │
│  │ └─────────────────────────────────────┘   │ │
│  │                                           │ │
│  │ You'll find Bizi in the bottom-right     │ │
│  │ corner whenever you need help!            │ │
│  │                                           │ │
│  │ Look for this: [Bizi Icon Badge]         │ │
│  └───────────────────────────────────────────┘ │
│                                                 │
│  ┌───────────────────────────────────────────┐ │
│  │      🎊 You're All Set!                   │ │
│  │  Welcome to BizMod, Masanawa Clothing!    │ │
│  │    Let's start growing your business.     │ │
│  └───────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘

Elements:

    Animated Bizi Avatar:
        Large circular gradient background (w-24 h-24)
        White circle with Bizi's face (eyes + smile)
        Antenna on top
        Sparkles icon animating in corner:
            Scale: 1 → 1.2 → 1
            Rotate: 0 → 10 → -10 → 0
            Infinite loop, 2s duration
        Main avatar rotates in (-180° to 0°)

    Capabilities Grid:
        2x3 grid of capability cards
        Each card:
            Icon in indigo box
            Short description text
            White background, rounded
            Staggered entrance animation (0.1s delays)
        6 capabilities:
            💬 Answer questions about BizMod
            📊 Generate reports and analyze data
            ✨ Give smart suggestions
            📄 Help create invoices/receipts
            📈 Spot trends and opportunities
            ⚡ Navigate with voice commands*

    Try Asking Box:
        Yellow background
        Lightbulb icon
        4 example questions users can ask

    Location Indicator:
        Shows where to find Bizi
        Small preview of the floating button
        "Look for this:" + mini Bizi icon

    Success Banner:
        Green gradient (emerald to green)
        White text
        Confetti emoji
        Personalized with business name
        Scale-in animation with spring

Data Collected:

    NONE - This is an informational step

Validation:

    ✅ ALWAYS CAN PROCEED - No validation needed

Button Text:

    Final step shows: "Go to Dashboard" (not "Continue")

🚦 NAVIGATION & VALIDATION SUMMARY
canProceed() Logic:

switch (currentStep) {
  case 0: return language !== "";                    // REQUIRED
  case 1: return businessName && industry && size;   // REQUIRED (3 fields)
  case 2: return true;                               // OPTIONAL
  case 3: return selectedModules.length > 0;         // REQUIRED (min 1)
  case 4: return true;                               // OPTIONAL
  case 5: return true;                               // OPTIONAL
  case 6: return true;                               // ALWAYS (info only)
}

Required vs Optional Steps:
Step	Name	Required Fields	Optional Fields	Can Skip?
0	Language	✅ Language	-	❌ No
1	Business Profile	✅ Name, Industry, Size	Locations, Multi-biz	❌ No
2	Goals	-	All goals	✅ Yes
3	AI Modules	✅ Min 1 module	All modules	❌ No
4	Quick Setup	-	Currency, Import	✅ Yes
5	Team	-	All emails	✅ Yes
6	Meet Bizi	-	-	✅ (Info only)
Navigation Buttons:

Back Button:

    Disabled on Step 0
    Opacity 50%, gray, no interaction
    Enabled on Steps 1-6
    Hover scale: 1.05x
    Tap scale: 0.95x

Continue/Dashboard Button:

    Disabled when !canProceed()
    Enabled with gradient background when can proceed
    Text changes:
        Steps 0-5: "Continue"
        Step 6: "Go to Dashboard"
    Hover scale: 1.05x
    Tap scale: 0.95x

🎨 UI/UX FEATURES
Animations:

    Page Transitions:
        Enter: x: 20 → 0, opacity: 0 → 1
        Exit: x: 0 → -20, opacity: 1 → 0
        Creates smooth slide effect

    Icon Animations:
        Step 0: Globe scales in with spring
        Step 2: Target scales in
        Step 3: Sparkles rotate + scale
        Step 5: Users icon scales in
        Step 6: Bizi rotates 180° + sparkles pulse

    Card Interactions:
        Hover: Scale 1.02x
        Tap: Scale 0.98x
        Selected: Border color + background change

    Progress Bar:
        Animated width based on step
        Gradient background
        Smooth 0.3s transition

Theme Integration:

    Uses useTheme() context throughout
    Dynamic classes:
        theme.backgroundColor
        theme.primaryGradient
        theme.secondaryGradient
        theme.buttonPrimary
    All gradients match user's selected color scheme

Header:

    Fixed at top
    BizMod logo + name
    "Step X of 7" counter
    Progress bar underneath

📊 COMPLETE DATA FLOW
On Completion (Step 6 → Dashboard):

onComplete({
  // Step 0
  language: "en",
  
  // Step 1
  businessName: "Masanawa Clothing",
  industry: "retail",
  businessSize: "small",
  locations: ["Kaduna", "Lagos"],        // Filtered (empty removed)
  hasMultipleBusinesses: false,
  
  // Step 2
  goals: ["inventory", "sales", "finance"],
  
  // Step 3
  selectedModules: ["inventory", "sales", "crm"],
  
  // Step 4
  currency: "NGN",
  importData: false,
  
  // Step 5
  teamMembers: ["user@email.com"],      // Filtered (empty removed)
});

Post-Onboarding Actions:

    AuthContext receives data

    Creates Business via createBusiness():

    {
      name: businessName,
      industry: industry,
      currency: currency,
      size: businessSize,
      goals: goals,
      enabledModules: selectedModules,
      importData: importData
    }

    Creates Location(s) for each location string:

    for (location of locations) {
      createLocation({
        businessId: business.id,
        name: location,
        city: location,
        country: "Nigeria",
        isDefault: (index === 0)
      });
    }

    Saves onboarding status:
        localStorage: onboarding-completed-{userId} = true
        Server: /user/preferences with onboardingCompleted: true

    Redirects to Dashboard (/dashboard)

🎯 KEY INSIGHTS
Smart AI Recommendations:

    Analyzes industry + goals to suggest modules
    Always includes CRM (customer relationships matter!)
    Shows reasoning for each recommendation
    Real-time free tier feedback

Progressive Disclosure:

    Starts easy (language)
    Gets detailed (business profile)
    Gets strategic (goals, modules)
    Gets practical (setup, team)
    Ends inspirational (meet Bizi)

Flexible Yet Guided:

    3 required steps (language, profile, modules)
    4 optional steps (goals, setup, team, info)
    Clear skip options where appropriate
    No friction for users who want to move fast

Contextual Help:

    Bizi assistant available throughout
    Info boxes explain features
    Example text in placeholders
    Reasons for recommendations

This onboarding flow balances user freedom with data collection, ensuring BizMod can provide personalized recommendations while not overwhelming first-time users! 🚀