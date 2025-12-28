---
name: design-system
description: "Complete reference for the RIZQ App design system - colors, typography, spacing, animations, and Islamic patterns"
---

# RIZQ Design System Reference

## Color Palette

### Primary Colors (HSL format for CSS variables)
```
Primary (Warm Sand):     30 52% 56%   → #D4A574
Primary Foreground:      24 50% 98%   → #FDF9F5
```

### Accent Colors
```
Accent (Deep Mocha):     24 50% 30%   → #6B4423
Accent Foreground:       38 35% 96%   → #F5EFE7
```

### Background & Surface
```
Background (Cream):      38 35% 96%   → #F5EFE7
Card (Warm White):       40 45% 98%   → #FFFCF7
Muted:                   36 30% 91%   → #EDE5DA
```

### Text
```
Foreground (Charcoal):   24 32% 12%   → #2C2416
Muted Foreground:        24 15% 45%   → #7A7067
```

### Semantic Colors
```
Success (Muted Teal):    158 35% 42%  → #5B8A8A
Destructive:             0 84% 60%    → #EF4444
Warning (Amber):         38 92% 50%   → #F59E0B
```

### Borders & Rings
```
Border:                  30 25% 88%   → #E8DFD4
Ring:                    30 52% 56%   → Primary
```

## Typography

### Font Families
```css
font-display: "Playfair Display", serif   /* Headings, luxury feel */
font-serif: "Crimson Pro", serif          /* Body text */
font-arabic: "Amiri", serif               /* Arabic text */
font-mono: "JetBrains Mono", monospace    /* Numbers, counters */
font-sans: "Inter", sans-serif            /* UI elements */
```

### Font Sizes
```
text-xs:    12px / 16px line-height
text-sm:    14px / 20px
text-base:  16px / 24px
text-lg:    18px / 28px
text-xl:    20px / 28px
text-2xl:   24px / 32px
text-3xl:   30px / 36px
```

### Arabic Text
```typescript
className="font-arabic text-xl leading-[2.2]"
dir="rtl"
```

## Spacing (8px base)

```
0.5: 2px    4: 16px    10: 40px
1:   4px    5: 20px    12: 48px
2:   8px    6: 24px    16: 64px
3:   12px   8: 32px    20: 80px
```

## Border Radius

```
rounded-sm:      8px   (0.5rem)
rounded-md:      10px  (0.625rem)
rounded-lg:      12px  (0.75rem)
rounded-btn:     16px  (1rem)      ← Buttons
rounded-islamic: 20px  (1.25rem)   ← Cards, containers
rounded-full:    50%               ← Circles, avatars
```

## Shadows

```css
shadow-soft:     0 2px 15px -3px rgba(0,0,0,0.07),
                 0 10px 20px -2px rgba(0,0,0,0.04)

shadow-elevated: 0 10px 40px -10px rgba(107,68,35,0.15),
                 0 4px 6px -2px rgba(107,68,35,0.05)

shadow-glow-primary: 0 0 30px rgba(212,165,116,0.4)

shadow-inner-glow: inset 0 2px 10px rgba(212,165,116,0.1)
```

## Animations (Tailwind)

| Class | Duration | Use Case |
|-------|----------|----------|
| `animate-ripple` | 600ms | Tap feedback |
| `animate-counter-bounce` | 400ms | Number changes |
| `animate-float-up` | 2.5s | Celebration particles |
| `animate-pulse-glow` | 2.5s | Streak badge glow |
| `animate-flame-dance` | 2s | Fire icon animation |
| `animate-shimmer` | 2s | Skeleton loading |
| `animate-slide-up` | 300ms | Sheet/modal enter |
| `animate-fade-in` | 300ms | Content appear |
| `animate-spin` | 1s | Loading spinner |

## Framer Motion Variants

### Container (Staggered List)
```typescript
const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: { staggerChildren: 0.08, delayChildren: 0.1 },
  },
};
```

### Item (List Child)
```typescript
const itemVariants = {
  hidden: { opacity: 0, y: 20 },
  visible: {
    opacity: 1,
    y: 0,
    transition: { duration: 0.4, ease: [0.25, 0.46, 0.45, 0.94] },
  },
};
```

### Interactive States
```typescript
whileHover={{ y: -2 }}           // Cards
whileHover={{ scale: 1.02 }}     // Buttons
whileTap={{ scale: 0.98 }}       // All interactive
whileHover={{ x: 4 }}            // List items
```

## Component Patterns

### Card
```typescript
className="p-4 rounded-islamic bg-card border border-border/50 shadow-soft"
```

### Button (Primary)
```typescript
className="px-6 py-3 rounded-btn bg-primary text-primary-foreground font-medium shadow-soft hover:shadow-elevated transition-all"
```

### Input
```typescript
className="w-full px-4 py-3 rounded-lg bg-background border border-border focus:border-primary focus:ring-2 focus:ring-primary/20 transition-colors"
```

### Badge
```typescript
className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-primary/10 text-primary"
```

## Islamic Patterns

### Subtle Background Pattern
```typescript
<div className="absolute inset-0 islamic-pattern opacity-5 pointer-events-none" />
```

### Decorative Border
```typescript
className="border-2 border-primary/20 rounded-islamic relative"
// With corner ornament
<div className="absolute -top-2 left-4 bg-background px-2 text-xs text-primary">✦</div>
```

## Responsive Breakpoints

```
sm:  640px   (mobile landscape)
md:  768px   (tablet)
lg:  1024px  (desktop)
xl:  1280px  (large desktop)
2xl: 1536px  (extra large)
```

## Accessibility

### Focus States
```typescript
className="focus:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2"
```

### Touch Targets
```typescript
className="min-h-[44px] min-w-[44px]"
```

### Reduced Motion
```typescript
className="motion-safe:animate-bounce motion-reduce:animate-none"
```
