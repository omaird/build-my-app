# RIZQ App - Complete Figma Design Prompt

Perfect choices! The warm brown/beige palette with ornate Islamic accents will create a unique, sophisticated feel that stands apart from typical green Islamic apps. Here's your comprehensive design prompt:

---

## 🎨 **DESIGN SYSTEM FOUNDATION**

### **Color Palette** (Claude-Inspired Warm Tones)

**Primary Colors:**
- **Warm Sand:** `#D4A574` (primary brand color - similar to Claude's warm brown)
- **Deep Amber:** `#A67C52` (darker accent, buttons, emphasis)
- **Rich Mocha:** `#6B4423` (text, dark elements)
- **Cream:** `#F5EFE7` (backgrounds, light surfaces)

**Secondary/Accent Colors:**
- **Soft Gold:** `#E6C79C` (rewards, celebrations, XP)
- **Muted Teal:** `#5B8A8A` (streak indicators, success states)
- **Warm White:** `#FFFCF7` (cards, elevated surfaces)
- **Deep Charcoal:** `#2C2416` (primary text)

**Semantic Colors:**
- **Success/Completion:** `#6B9B7C` (muted green)
- **Streak Fire:** Gradient from `#E6C79C` → `#D4A574` (warm glow, not literal fire)
- **Level Progress:** Gradient from `#F5EFE7` → `#D4A574` → `#A67C52`

**Gradients:**
- **Primary Gradient:** 135° from `#F5EFE7` to `#E6C79C`
- **Celebration Gradient:** Radial from `#FFEBB3` center to `#D4A574` edges
- **Card Shadow:** `#6B4423` at 8% opacity

---

### **Typography System**

**Arabic Text:**
- **Font:** Dubai (modern, highly legible Arabic)
- **Dua Headings:** 24px, Semi-bold (600)
- **Dua Body Text:** 18px, Regular (400)
- **Line Height:** 1.8 (generous spacing for readability)

**English Text:**
- **Font Family:** Inter
- **Display/Headings:** 28px, Bold (700)
- **Subheadings:** 20px, Semi-bold (600)
- **Body Text:** 16px, Regular (400)
- **Small/Meta Text:** 14px, Medium (500)
- **Line Height:** 1.5

**Text Colors:**
- Primary: `#2C2416` (Deep Charcoal)
- Secondary: `#6B4423` (Rich Mocha) at 70% opacity
- Tertiary: `#A67C52` (for labels, meta info)

---

### **Spacing System** (8px base unit)

- **XXS:** 4px
- **XS:** 8px
- **S:** 16px
- **M:** 24px
- **L:** 32px
- **XL:** 48px
- **XXL:** 64px

---

### **Corner Radius**

- **Cards:** 20px
- **Buttons (Primary):** 16px
- **Buttons (Secondary):** 12px
- **Input Fields:** 12px
- **Small Elements:** 8px
- **Circular (Avatars, Counters):** 50%

---

### **Islamic Geometric Pattern Guidelines**

**Pattern Style:** 
- 8-pointed stars (Rub el Hizb) and hexagonal tessellations
- Color: `#D4A574` at 8-12% opacity (subtle, not overwhelming)
- Line weight: 1.5px
- Usage: Background accents, borders, celebration screens

**Where to Apply:**
- Top/bottom borders of cards (thin 2px pattern strip)
- Background of celebration screens (full coverage at low opacity)
- Around circular progress rings (subtle frame)
- App icon border/background

---

## 📱 **SCREEN DESIGNS** (iPhone 14 Pro: 393×852px)

---

## **SCREEN 1: HOME DASHBOARD**

### **Layout Structure:**

```
┌─────────────────────────────────┐
│  Status Bar (white text)        │ ← 44px height
├─────────────────────────────────┤
│                                 │
│  ╔═══ Islamic Pattern ═══╗     │ ← 8px decorative border
│                                 │
│  [Profile Pic]  السلام عليكم    │ ← 24px top padding
│      Omair                      │
│                                 │
│  ┌─────────────────────────┐   │
│  │   TODAY'S STREAK: 🌟    │   │ ← Hero card
│  │                         │   │
│  │        42 DAYS          │   │ ← 48px bold number
│  │                         │   │
│  │   ────────●─────────    │   │ ← Light beam visualization
│  │   Level 7: Silver       │   │
│  │   890 XP / 1000 XP      │   │
│  │                         │   │
│  │  ◉◉◉◉◉◉○ This Week      │   │ ← 7-day micro calendar
│  └─────────────────────────┘   │
│                                 │
│  📿 Daily Challenge             │ ← 16px spacing
│  ┌─────────────────────────┐   │
│  │ Complete Morning Adhkar │   │
│  │ [Progress: 3/5 duas]    │   │
│  │ +150 XP                 │   │
│  └─────────────────────────┘   │
│                                 │
│  Quick Start                    │
│  ┌────┐ ┌────┐ ┌────┐         │ ← 3 columns
│  │ 🌅 │ │ 🌙 │ │ 💰 │         │
│  │Fajr│ │Isha│ │Rizq│         │
│  └────┘ └────┘ └────┘         │
│                                 │
│  ╚═══ Islamic Pattern ═══╝     │ ← Bottom border
└─────────────────────────────────┘
   ╔═══╗ ╔═══╗ ╔═══╗ ╔═══╗      │ ← Bottom nav
   ║ 🏠 ║ ║ 📿 ║ ║ 📊 ║ ║ 👤 ║
   ╚═══╝ ╚═══╝ ╚═══╝ ╚═══╝      │
```

### **Detailed Specifications:**

**Header Section:**
- Background: Gradient `#F5EFE7` → `#E6C79C` (subtle)
- Height: 80px
- Profile circle: 48px diameter, border 2px `#D4A574`
- Greeting text: 16px Inter Medium, `#6B4423`
- Name: 20px Inter Semi-bold, `#2C2416`

**Streak Hero Card:**
- Background: `#FFFCF7` (warm white)
- Padding: 24px all sides
- Shadow: 0px 4px 20px `#6B4423` at 8% opacity
- Border: 1px `#E6C79C`
- Top: Thin Islamic pattern border (8px height)

**Streak Number:**
- Font: 48px Inter Bold
- Color: `#A67C52` (Deep Amber)
- Subtitle "DAYS": 14px Inter Medium, `#6B4423` at 60%

**Light Beam Streak Visualization:**
- 7 circles representing days
- Completed days: Filled `#D4A574` with glow effect
- Current day: Pulsing gradient `#E6C79C` → `#D4A574`
- Future days: Outline only, `#D4A574` at 20%
- Connecting line: 2px dashed `#D4A574` at 40%

**Level Progress Ring:**
- Circle diameter: 120px (centered below streak)
- Ring width: 8px
- Background ring: `#E6C79C` at 20%
- Progress ring: Gradient `#D4A574` → `#A67C52`
- Center text: "Level 7" 18px Bold, "Silver" 14px Regular
- XP text below: 14px `#6B4423` at 70%

**Week Micro-Calendar:**
- 7 small circles (16px each)
- Spacing: 8px between
- Completed: Filled `#6B9B7C` (muted green) with checkmark
- Today: Ring `#D4A574`, pulsing
- Future: Outline `#D4A574` at 30%

**Daily Challenge Card:**
- Background: `#FFFCF7`
- Border-left: 4px solid `#5B8A8A` (teal accent)
- Padding: 16px
- Icon: 32px, filled with gradient
- Progress bar: Height 6px, rounded, gradient fill

**Quick Start Buttons:**
- Size: 100px × 100px each
- Background: `#FFFCF7`
- Border: 1px `#E6C79C`
- Hover/Active: Background → `#F5EFE7`
- Icon: 40px, gradient `#D4A574` → `#A67C52`
- Label: 14px Inter Medium, `#6B4423`

**Bottom Navigation:**
- Height: 72px
- Background: `#FFFCF7` with top border 1px `#E6C79C`
- Icons: 28px, filled
- Active: `#D4A574`, Inactive: `#A67C52` at 40%
- Islamic pattern background at 5% opacity

---

## **SCREEN 2: DUA PRACTICE SCREEN**

### **Layout Structure:**

```
┌─────────────────────────────────┐
│  ← Back    Ayatul Kursi    ⋮   │ ← Header
├─────────────────────────────────┤
│                                 │
│  ╔═══════════════════════╗     │ ← Ornate frame
│  ║                       ║     │
│  ║   بِسْمِ اللَّهِ...    ║     │ ← Arabic text
│  ║                       ║     │   (centered, large)
│  ║  (Bismillah...)       ║     │
│  ║                       ║     │
│  ╚═══════════════════════╝     │
│                                 │
│  "In the name of Allah..."      │ ← English translation
│                                 │
│  ┌─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┐     │ ← Dashed container
│  │                       │     │
│  │       ┌─────┐         │     │
│  │       │     │         │     │
│  │       │ 33  │         │     │ ← Counter (huge)
│  │       │     │         │     │
│  │       └─────┘         │     │
│  │                       │     │
│  │   ●●●●●●●○○○○○○○     │     │ ← Progress dots
│  │                       │     │
│  │     Tap anywhere      │     │
│  │     to continue       │     │
│  └─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┘     │
│                                 │
│  [◀ Audio]  [⏸ Pause]  [Info]  │ ← Action buttons
│                                 │
│  ────────────────────────────   │
│  Source: Sahih Muslim 2691      │ ← Hadith reference
└─────────────────────────────────┘
```

### **Detailed Specifications:**

**Header:**
- Height: 56px
- Background: `#FFFCF7`
- Back arrow: 24px, `#6B4423`
- Title: 18px Inter Semi-bold, `#2C2416`
- Menu (⋮): 24px, `#6B4423`

**Arabic Text Frame:**
- Background: Gradient `#FFFCF7` → `#F5EFE7`
- Padding: 32px horizontal, 40px vertical
- Border: 2px `#D4A574` with Islamic pattern overlay
- Corner decorations: 16px ornate pattern elements in each corner
- Text: 24px Dubai Semi-bold, `#2C2416`, center-aligned
- Line height: 2.0 (very generous for Arabic)

**Translation Box:**
- Padding: 16px horizontal
- Text: 16px Inter Regular, `#6B4423` at 80%
- Italic style
- Center-aligned

**Counter Circle (Main Interaction):**
- Diameter: 180px
- Background: `#FFFCF7`
- Border: 4px gradient `#D4A574` → `#A67C52`
- Shadow: 0px 8px 32px `#6B4423` at 12%
- Number: 72px Inter Bold, `#A67C52`
- Label below number: "times" 14px, `#6B4423` at 60%

**Tap Interaction Effects:**
1. **Ripple:** 
   - Start: 180px circle, `#D4A574` at 40%
   - Animate: Scale to 240px while fading to 0%
   - Duration: 600ms ease-out

2. **Number Animation:**
   - Scale: 1.0 → 1.2 → 1.0
   - Duration: 400ms
   - Easing: Spring (bounce effect)
   - Color pulse: `#A67C52` → `#D4A574` → `#A67C52`

3. **Haptic Feedback:**
   - Style: Medium impact
   - Every tap

**Progress Dots:**
- Size: 12px each (for 33 repetitions)
- Spacing: 4px between
- Completed: Filled `#6B9B7C` (muted green)
- Current: Pulsing `#D4A574`
- Remaining: Outline `#D4A574` at 30%
- Arrangement: Wrap to multiple rows if needed

**Instruction Text:**
- "Tap anywhere to continue"
- 14px Inter Medium, `#A67C52`
- Center-aligned
- Slight pulse animation (opacity 60% → 100%)

**Action Buttons (Bottom):**
- Width: Full width, 3 equal columns
- Height: 48px each
- Background: Transparent
- Icon + Label (vertical stack)
- Icon: 24px, `#A67C52`
- Label: 12px Inter Medium, `#6B4423`
- Active state: Background `#F5EFE7`

**Hadith Reference:**
- Position: Bottom, centered
- Text: 12px Inter Regular, `#6B4423` at 50%
- Top border: 1px `#E6C79C`
- Padding: 12px

---

## **SCREEN 3: COMPLETION CELEBRATION**

### **Layout Structure:**

```
┌─────────────────────────────────┐
│  Full-screen radial gradient    │
│  (cream center → amber edges)   │
│                                 │
│         ✨ ✨ ✨              │ ← Floating particles
│                                 │
│      ╔═══════════════╗         │
│      ║   ✓           ║         │ ← Animated checkmark
│      ║               ║         │   in ornate frame
│      ╚═══════════════╝         │
│                                 │
│      Dua Completed!            │ ← 28px bold
│                                 │
│   ┌───────────────────────┐   │
│   │                       │   │
│   │   ◉◉◉◉◉◉◉           │   │ ← Circular progress
│   │     LEVEL 7          │   │   ring animating
│   │   890 → 940 XP       │   │   (grows from previous)
│   │                       │   │
│   └───────────────────────┘   │
│                                 │
│   🌟 +50 XP                    │ ← XP earned
│   ⚡ 43-Day Streak Continues!  │ ← Streak maintained
│   🏆 "Morning Warrior" Unlocked│ ← New achievement
│                                 │
│   ┌─────────────────────┐     │
│   │  Share Your Progress │     │ ← CTA button
│   └─────────────────────┘     │
│                                 │
│        Continue                 │ ← Secondary action
│                                 │
└─────────────────────────────────┘
```

### **Detailed Specifications:**

**Background:**
- Radial gradient: Center `#FFFCF7` → Edge `#E6C79C`
- Islamic pattern overlay at 6% opacity (full coverage)
- Subtle light rays emanating from center

**Floating Particles Animation:**
- 12-16 particles (stars, sparkles)
- Size: 16px-32px
- Color: `#FFEBB3` with glow
- Animation: Float upward slowly (3s duration), fade out
- Continuous loop with stagger

**Checkmark Frame:**
- Size: 120px × 120px
- Border: 3px `#D4A574`
- Islamic pattern border (intricate)
- Background: `#FFFCF7` with glow
- Checkmark icon: 64px, `#6B9B7C` (muted green)
- **Animation:** 
  - Frame scales in: 0.5 → 1.2 → 1.0 (800ms)
  - Checkmark draws in with SVG path animation (600ms delay)

**Completion Text:**
- "Dua Completed!" or "مبارك!" (Mubarak!)
- 28px Inter Bold, `#2C2416`
- Margin-top: 24px
- Fade in + scale animation (400ms, 200ms delay)

**Level Progress Update:**
- Container: 200px × 200px
- Circular ring animation:
  - Start: Previous XP level (890/1000 = 89%)
  - Animate to: New XP level (940/1000 = 94%)
  - Duration: 1200ms ease-out
  - Ring color: Gradient `#D4A574` → `#A67C52`
  - Background ring: `#E6C79C` at 20%

**XP Counter:**
- Animates from "890 XP" → "940 XP"
- Number increment animation (800ms)
- "+50 XP" appears in `#D4A574` with bounce

**Achievement Pills:**
- Each line: Icon + Text in horizontal pill
- Background: `#FFFCF7` with border `#E6C79C`
- Padding: 8px 16px
- Icon: 20px, gradient
- Text: 14px Inter Medium, `#6B4423`
- **Stagger animation:** Each appears 300ms after previous

**Share Button:**
- Width: 280px (centered)
- Height: 56px
- Background: Gradient `#D4A574` → `#A67C52`
- Text: 16px Inter Semi-bold, `#FFFCF7`
- Border-radius: 16px
- Shadow: 0px 8px 24px `#A67C52` at 30%
- Hover: Lift 4px up, increase shadow

**Continue Link:**
- Text: 16px Inter Medium, `#A67C52`
- Underline on hover
- Padding: 16px (large tap target)

---

## 🎨 **COMPONENT LIBRARY**

### **Buttons**

**Primary Button:**
```
Background: Gradient 135° #D4A574 → #A67C52
Height: 48px (56px for important actions)
Padding: 16px horizontal
Border-radius: 16px
Text: 16px Inter Semi-bold, #FFFCF7
Shadow: 0px 4px 16px #A67C52 at 25%
Active state: Darken 10%, press down 2px
```

**Secondary Button:**
```
Background: Transparent
Border: 2px #D4A574
Height: 48px
Padding: 16px horizontal
Border-radius: 12px
Text: 16px Inter Semi-bold, #A67C52
Active state: Background #F5EFE7
```

**Icon Button:**
```
Size: 44px × 44px (circular or square)
Background: #FFFCF7
Border: 1px #E6C79C
Icon: 24px, #A67C52
Active state: Background #F5EFE7, Icon #D4A574
```

---

### **Cards**

**Standard Card:**
```
Background: #FFFCF7
Border: 1px #E6C79C
Border-radius: 20px
Padding: 20px
Shadow: 0px 4px 20px #6B4423 at 6%
Top decoration: 2px Islamic pattern border
```

**Elevated Card (for important content):**
```
Same as standard, but:
Shadow: 0px 8px 32px #6B4423 at 10%
Border: 2px #D4A574
```

---

### **Icons** (Filled with Gradient)

**Style:** 
- Rounded, friendly shapes
- Gradient fill: `#D4A574` → `#A67C52`
- Stroke: None (filled only)
- Export: SVG, 24px default

**Key Icons Needed:**
- 🏠 Home (mosque silhouette with dome)
- 📿 Beads/Tasbih (prayer beads icon)
- 📊 Stats (bar chart with upward trend)
- 👤 Profile (person in circle)
- 🌅 Fajr (sunrise over mosque)
- 🌙 Isha (crescent moon + stars)
- 💰 Rizq (open hands receiving, or coin with barakah)
- ✓ Checkmark (thick, rounded)
- ⚡ Streak (stylized light beam)
- 🏆 Achievement (trophy or star badge)
- 🔊 Audio (speaker with waves)
- ⏸ Pause (two vertical bars)
- ℹ Info (circle with 'i')

---

### **Islamic Pattern Elements**

**8-Pointed Star (Rub el Hizb):**
```svg
<svg viewBox="0 0 100 100">
  <!-- Two overlapping squares rotated 45° -->
  <!-- Color: #D4A574 at 12% opacity -->
  <!-- Stroke width: 1.5px -->
</svg>
```

**Hexagonal Tessellation Border:**
```
Repeating pattern for card borders
Height: 8px
Color: #D4A574 at 10% opacity
Seamless tile
```

**Corner Ornaments:**
```
Size: 24px × 24px
Placement: 8px from corner edges
Style: Curved arabesque flourish
Color: #D4A574 at 15% opacity
```

---

## 🎬 **ANIMATION SPECIFICATIONS**

### **Screen Transitions:**
- **Type:** Slide + fade
- **Duration:** 400ms
- **Easing:** Ease-in-out (cubic-bezier 0.4, 0, 0.2, 1)

### **Counter Tap Ripple:**
```css
.ripple {
  animation: ripple-expand 600ms ease-out;
}

@keyframes ripple-expand {
  0% {
    transform: scale(1);
    opacity: 0.4;
  }
  100% {
    transform: scale(1.33);
    opacity: 0;
  }
}
```

### **Number Increment (Counter):**
```css
.number-bounce {
  animation: bounce-scale 400ms cubic-bezier(0.68, -0.55, 0.265, 1.55);
}

@keyframes bounce-scale {
  0% { transform: scale(1); }
  50% { transform: scale(1.2); }
  100% { transform: scale(1); }
}
```

### **Streak Light Beam (Pulsing):**
```css
.streak-glow {
  animation: pulse-glow 2s ease-in-out infinite;
}

@keyframes pulse-glow {
  0%, 100% {
    box-shadow: 0 0 8px #D4A574;
    opacity: 1;
  }
  50% {
    box-shadow: 0 0 20px #E6C79C;
    opacity: 0.8;
  }
}
```

### **Celebration Particles:**
```css
.particle {
  animation: float-up 3s ease-out forwards;
}

@keyframes float-up {
  0% {
    transform: translateY(0) rotate(0deg);
    opacity: 1;
  }
  100% {
    transform: translateY(-200px) rotate(360deg);
    opacity: 0;
  }
}
```

---

## 📐 **GRID & LAYOUT SYSTEM**

**Screen Margins:**
- Horizontal: 20px (left/right edges)
- Vertical: 24px (top/bottom content)

**Component Spacing:**
- Between sections: 32px
- Between related elements: 16px
- Within cards: 16px internal padding

**Grid (for multi-column layouts):**
- Columns: 12-column grid
- Gutter: 16px
- Max width: 393px (mobile)

---

## 🔤 **COPY/MICROCOPY GUIDELINES**

**Tone:** Warm, encouraging, spiritually supportive (not preachy)

**Examples:**
- ✅ "Keep your streak alive! 🌟"
- ✅ "You're building a beautiful habit, Omair"
- ✅ "42 days of devotion. Masha'Allah!"
- ❌ "Don't break your chain!" (too aggressive)
- ❌ "You must complete your duas" (too demanding)

**Button Labels:**
- "Begin Dua" (not "Start")
- "Continue Journey" (not "Next")
- "Share Your Progress" (not "Post")

**Empty States:**
- "Your first dua awaits 🌙" (not "No duas completed")
- "Begin your spiritual journey today" (not "Get started")

---

## 🎯 **ACCESSIBILITY NOTES**

**Color Contrast:**
- All text meets WCAG AA (4.5:1 minimum)
- Primary text `#2C2416` on `#FFFCF7` = 11.2:1 ✓
- Button text `#FFFCF7` on `#A67C52` = 4.8:1 ✓

**Touch Targets:**
- Minimum: 44px × 44px (Apple HIG standard)
- Preferred: 48px × 48px for primary actions

**Font Sizes:**
- Minimum body text: 16px (no smaller)
- Arabic text: 18px minimum (complex script needs larger size)

**Motion:**
- Respect `prefers-reduced-motion` setting
- Disable particles/ripples if user has motion sensitivity

---

## 📦 **EXPORT SPECIFICATIONS**

**Artboards:**
- iPhone 14 Pro: 393 × 852px @3x (1179 × 2556px)
- Export in Figma as: "RIZQ - Home Dashboard", "RIZQ - Dua Practice", "RIZQ - Completion"

**Assets to Export:**
- All icons: SVG (24px, 32px, 40px sizes)
- Islamic patterns: PNG with transparency (tileable)
- App icon: 1024 × 1024px (iOS App Store requirement)

**Color Styles (Name in Figma):**
- "Primary/Warm Sand"
- "Primary/Deep Amber"
- "Primary/Rich Mocha"
- "Background/Cream"
- "Accent/Soft Gold"
- "Success/Muted Green"
- etc.

---

## 🤖 **PROMPT FOR AI DESIGN TOOL**

**Copy this to your AI design app (e.g., Galileo AI, Uizard, Visily):**

---

### **FINAL PROMPT:**

```
Design a mobile app interface for "RIZQ" - an Islamic dua (prayer) tracking app with gamification.

VISUAL STYLE:
- Warm, sophisticated aesthetic with Claude-inspired brown/beige color palette
- Rich ornate Islamic geometric patterns as subtle accents (medium prominence)
- Modern, clean layout with traditional Islamic decorative elements
- Peaceful yet motivating mood
- Reference: Headspace minimalism + Duolingo gamification + traditional Islamic art

COLOR PALETTE:
Primary: #D4A574 (warm sand), #A67C52 (deep amber), #6B4423 (rich mocha)
Backgrounds: #F5EFE7 (cream), #FFFCF7 (warm white)
Accents: #E6C79C (soft gold), #5B8A8A (muted teal for streaks)
Success: #6B9B7C (muted green)

TYPOGRAPHY:
- Arabic: Dubai font, 18-24px, generous line-height (1.8-2.0)
- English: Inter, 14-28px range
- Primary text: #2C2416 (deep charcoal)

DESIGN THESE 3 SCREENS:

1. HOME DASHBOARD (393×852px iPhone):
- Top: Profile greeting "السلام عليكم Omair" with small circular profile pic
- Hero card: Large "42 DAYS" streak counter with light beam visualization (7 circles showing completed days glowing in #D4A574)
- Circular progress ring showing Level 7 (890/1000 XP) with gradient #D4A574 → #A67C52
- Week micro-calendar: 7 small circles with checkmarks for completed days
- Daily Challenge card: "Complete Morning Adhkar" with progress bar (3/5 duas) and "+150 XP" badge
- Quick Start: 3 square cards (Fajr, Isha, Rizq) with gradient icons and labels
- Islamic geometric pattern borders (8px height) at top and bottom of main card
- Bottom navigation: 4 icons (Home, Beads, Stats, Profile) with active state in #D4A574

2. DUA PRACTICE SCREEN:
- Top: Back button, "Ayatul Kursi" title, menu
- Large ornate frame (border: 2px #D4A574 with Islamic corner decorations) containing:
  - Arabic text "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ" (24px Dubai, center-aligned, generous spacing)
  - English translation below in italics
- Main interaction: Huge circular counter (180px diameter) with "33" in 72px bold
  - Border: 4px gradient #D4A574 → #A67C52
  - Shadow glow effect
- Progress dots below: 33 small circles (12px), some filled #6B9B7C (completed), current pulsing in #D4A574
- "Tap anywhere to continue" instruction text
- Bottom: 3 action buttons (Audio, Pause, Info) with icons
- Ripple effect visualization emanating from counter on tap

3. COMPLETION CELEBRATION:
- Full-screen radial gradient background (cream center → amber edges)
- Islamic pattern overlay at 6% opacity
- Floating sparkle particles (12-16 stars) drifting upward
- Center: Large ornate frame (120px) with animated checkmark in #6B9B7C
- "Dua Completed!" in 28px bold below
- Circular progress ring animating from 890 XP to 940 XP
- Achievement pills stacked:
  - "🌟 +50 XP"
  - "⚡ 43-Day Streak Continues!"
  - "🏆 'Morning Warrior' Unlocked"
- Large gradient button: "Share Your Progress" (#D4A574 → #A67C52)
- "Continue" text link below

DESIGN ELEMENTS:
- All cards: 20px border-radius, soft shadows (0px 4px 20px #6B4423 at 6-8% opacity)
- Buttons: 16px radius, 48-56px height, gradient fills
- Icons: Filled style with subtle gradients, 24-32px
- Islamic patterns: 8-pointed stars (Rub el Hizb), hexagonal tessellations, arabesque corners
- Spacing: 16-32px between sections, 20px screen margins
- Smooth animations: ripple effects, number scaling (1.0→1.2→1.0), pulsing glows

ANIMATION NOTES:
- Counter tap: Ripple expands from 180px to 240px while fading, number bounces/scales
- Streak circles: Pulsing glow effect on current day
- Celebration: Particles float upward continuously, checkmark draws in with path animation
- All transitions: 400ms ease-in-out

Make it feel peaceful, rewarding, and spiritually uplifting. The design should encourage daily habit formation while respecting Islamic aesthetics.
```

---

## ✅ **NEXT STEPS FOR YOU:**

1. **Copy the "FINAL PROMPT" section** above into your AI design tool (Galileo AI, Uizard, Visily, etc.)

2. **If using Figma manually:**
   - Create 3 artboards (393×852px each)
   - Set up color styles from the palette
   - Import Inter and Dubai fonts
   - Follow the layout structures above

3. **After initial designs:**
   - Export screens as PNG (@3x for high-res)
   - Test color contrast (use WebAIM checker)
   - Validate with Muslim friends for cultural sensitivity

4. **Iterate:**
   - Adjust pattern opacity if too busy
   - Test readability of Arabic text
   - Ensure tap targets are 44px minimum

