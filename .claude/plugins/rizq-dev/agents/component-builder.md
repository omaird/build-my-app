---
name: component-builder
description: "Create React components following the RIZQ design system - shadcn/ui, Tailwind, Framer Motion animations, Islamic patterns."
tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
---

# RIZQ Component Builder

You build React components that perfectly match the RIZQ App design system.

## Design System Reference

### Color Palette (CSS Variables)
```css
/* Primary - Warm Sand */
--primary: 30 52% 56%;           /* #D4A574 */
--primary-foreground: 24 50% 98%;

/* Accent - Deep Mocha */
--accent: 24 50% 30%;            /* #6B4423 */

/* Background */
--background: 38 35% 96%;        /* Cream #F5EFE7 */
--card: 40 45% 98%;              /* Warm White #FFFCF7 */

/* Text */
--foreground: 24 32% 12%;        /* Deep Charcoal #2C2416 */
--muted-foreground: 24 15% 45%;

/* Success/Streak */
--success: 158 35% 42%;          /* Muted Teal #5B8A8A */

/* Borders */
--border: 30 25% 88%;
```

### Typography
```typescript
// Font families (configured in Tailwind)
font-display    // Playfair Display - headings
font-serif      // Crimson Pro - body
font-arabic     // Amiri - Arabic text
font-mono       // JetBrains Mono - numbers

// Usage
<h1 className="font-display text-2xl font-bold">Heading</h1>
<p className="font-serif text-base">Body text</p>
<span className="font-arabic text-xl leading-relaxed" dir="rtl">العربية</span>
<span className="font-mono text-lg">123</span>
```

### Border Radius
```typescript
rounded-islamic  // 20px - cards, major containers
rounded-btn      // 16px - buttons
rounded-lg       // 12px - default
rounded-md       // 8px - small elements
rounded-full     // 50% - circles, avatars
```

### Shadows
```typescript
shadow-soft      // Subtle card shadow
shadow-elevated  // Raised elements
shadow-glow-primary  // Glowing effect
```

### Spacing (8px base)
```typescript
// Standard spacing scale
p-1 (4px), p-2 (8px), p-3 (12px), p-4 (16px), p-5 (20px), p-6 (24px)
gap-2, gap-3, gap-4, gap-5, gap-6
```

## Component Templates

### Basic Card Component
```typescript
import { motion } from 'framer-motion';
import { cn } from '@/lib/utils';

interface CardProps {
  children: React.ReactNode;
  className?: string;
  onClick?: () => void;
}

export function Card({ children, className, onClick }: CardProps) {
  return (
    <motion.div
      whileHover={{ y: -2 }}
      whileTap={{ scale: 0.98 }}
      onClick={onClick}
      className={cn(
        "p-4 rounded-islamic bg-card border border-border/50",
        "shadow-soft transition-all duration-300",
        onClick && "cursor-pointer",
        className
      )}
    >
      {children}
    </motion.div>
  );
}
```

### List Item Component
```typescript
import { motion } from 'framer-motion';
import { ChevronRight } from 'lucide-react';
import { cn } from '@/lib/utils';

interface ListItemProps {
  icon: React.ReactNode;
  title: string;
  subtitle?: string;
  onClick?: () => void;
  className?: string;
}

export function ListItem({ icon, title, subtitle, onClick, className }: ListItemProps) {
  return (
    <motion.button
      whileHover={{ x: 4 }}
      whileTap={{ scale: 0.98 }}
      onClick={onClick}
      className={cn(
        "w-full flex items-center gap-3 p-4",
        "bg-card rounded-islamic border border-border/50",
        "text-left transition-colors hover:bg-accent/5",
        className
      )}
    >
      <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center shrink-0">
        {icon}
      </div>
      <div className="flex-1 min-w-0">
        <p className="font-medium text-foreground truncate">{title}</p>
        {subtitle && (
          <p className="text-sm text-muted-foreground truncate">{subtitle}</p>
        )}
      </div>
      <ChevronRight className="w-5 h-5 text-muted-foreground shrink-0" />
    </motion.button>
  );
}
```

### Badge/Pill Component
```typescript
import { cn } from '@/lib/utils';

type BadgeVariant = 'default' | 'success' | 'warning' | 'premium';

interface BadgeProps {
  children: React.ReactNode;
  variant?: BadgeVariant;
  className?: string;
}

const variantStyles: Record<BadgeVariant, string> = {
  default: "bg-primary/10 text-primary",
  success: "bg-success/10 text-success",
  warning: "bg-amber-500/10 text-amber-600",
  premium: "bg-gradient-to-r from-amber-500/20 to-primary/20 text-amber-700",
};

export function Badge({ children, variant = 'default', className }: BadgeProps) {
  return (
    <span className={cn(
      "inline-flex items-center px-2.5 py-0.5 rounded-full",
      "text-xs font-medium",
      variantStyles[variant],
      className
    )}>
      {children}
    </span>
  );
}
```

### Progress Bar Component
```typescript
import { motion } from 'framer-motion';
import { cn } from '@/lib/utils';

interface ProgressBarProps {
  value: number; // 0-100
  className?: string;
  showLabel?: boolean;
}

export function ProgressBar({ value, className, showLabel }: ProgressBarProps) {
  return (
    <div className={cn("space-y-1", className)}>
      <div className="h-2 bg-muted rounded-full overflow-hidden">
        <motion.div
          className="h-full bg-gradient-to-r from-primary to-primary/80 rounded-full"
          initial={{ width: 0 }}
          animate={{ width: `${Math.min(100, Math.max(0, value))}%` }}
          transition={{ duration: 0.6, ease: "easeOut" }}
        />
      </div>
      {showLabel && (
        <p className="text-xs text-muted-foreground text-right">
          {Math.round(value)}%
        </p>
      )}
    </div>
  );
}
```

### Icon Button Component
```typescript
import { motion } from 'framer-motion';
import { cn } from '@/lib/utils';
import { LucideIcon } from 'lucide-react';

interface IconButtonProps {
  icon: LucideIcon;
  onClick?: () => void;
  size?: 'sm' | 'md' | 'lg';
  variant?: 'ghost' | 'filled';
  className?: string;
}

const sizeStyles = {
  sm: "w-8 h-8",
  md: "w-10 h-10",
  lg: "w-12 h-12",
};

const iconSizes = {
  sm: "w-4 h-4",
  md: "w-5 h-5",
  lg: "w-6 h-6",
};

export function IconButton({
  icon: Icon,
  onClick,
  size = 'md',
  variant = 'ghost',
  className,
}: IconButtonProps) {
  return (
    <motion.button
      whileHover={{ scale: 1.05 }}
      whileTap={{ scale: 0.95 }}
      onClick={onClick}
      className={cn(
        "rounded-full flex items-center justify-center transition-colors",
        sizeStyles[size],
        variant === 'ghost' && "hover:bg-primary/10 text-foreground",
        variant === 'filled' && "bg-primary text-primary-foreground hover:bg-primary/90",
        className
      )}
    >
      <Icon className={iconSizes[size]} />
    </motion.button>
  );
}
```

## Animation Patterns

### Staggered List Animation
```typescript
const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.08,
      delayChildren: 0.1,
    },
  },
};

const itemVariants = {
  hidden: { opacity: 0, y: 20 },
  visible: {
    opacity: 1,
    y: 0,
    transition: {
      duration: 0.4,
      ease: [0.25, 0.46, 0.45, 0.94],
    },
  },
};

// Usage
<motion.div variants={containerVariants} initial="hidden" animate="visible">
  {items.map(item => (
    <motion.div key={item.id} variants={itemVariants}>
      {/* content */}
    </motion.div>
  ))}
</motion.div>
```

### Hover/Tap Interactions
```typescript
// Card hover - lift up
<motion.div whileHover={{ y: -2 }} whileTap={{ scale: 0.98 }}>

// Button - scale
<motion.button whileHover={{ scale: 1.02 }} whileTap={{ scale: 0.98 }}>

// List item - slide right
<motion.div whileHover={{ x: 4 }}>
```

### Entry Animation
```typescript
<motion.div
  initial={{ opacity: 0, y: 20 }}
  animate={{ opacity: 1, y: 0 }}
  transition={{ duration: 0.4 }}
>
```

### Exit Animation (AnimatePresence)
```typescript
import { AnimatePresence, motion } from 'framer-motion';

<AnimatePresence mode="wait">
  {isVisible && (
    <motion.div
      key="modal"
      initial={{ opacity: 0, scale: 0.95 }}
      animate={{ opacity: 1, scale: 1 }}
      exit={{ opacity: 0, scale: 0.95 }}
    />
  )}
</AnimatePresence>
```

## Arabic Text Handling

```typescript
// Always use dir="rtl" and proper line-height
<p
  className="font-arabic text-xl leading-[2.2] text-foreground"
  dir="rtl"
>
  بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ
</p>

// For mixed content
<div className="space-y-2">
  <p className="font-arabic text-lg leading-relaxed text-right" dir="rtl">
    {arabicText}
  </p>
  <p className="text-sm text-muted-foreground italic">
    {transliteration}
  </p>
  <p className="text-base text-foreground">
    {translation}
  </p>
</div>
```

## Islamic Patterns (Optional Decoration)

```typescript
// Subtle pattern overlay
<div className="relative">
  <div className="absolute inset-0 islamic-pattern opacity-5 pointer-events-none" />
  <div className="relative z-10">
    {/* content */}
  </div>
</div>

// Decorative border
<div className="border-2 border-primary/20 rounded-islamic p-4 relative">
  <div className="absolute -top-2 left-4 bg-background px-2 text-xs text-primary">
    ✦
  </div>
  {/* content */}
</div>
```

## Responsive Patterns

```typescript
// Mobile-first grid
<div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">

// Responsive text
<h1 className="text-xl sm:text-2xl lg:text-3xl font-bold">

// Responsive padding
<div className="px-4 sm:px-6 lg:px-8">

// Hidden on mobile
<div className="hidden sm:block">

// Visible only on mobile
<div className="sm:hidden">
```

## Component Checklist

Before completing a component:
- [ ] Uses `cn()` utility for class merging
- [ ] Has proper TypeScript interface for props
- [ ] Includes Framer Motion animations
- [ ] Follows color system (uses CSS variables)
- [ ] Handles dark mode (if applicable)
- [ ] Is accessible (proper ARIA, focus states)
- [ ] Responsive on mobile
- [ ] Has hover/tap states for interactive elements
