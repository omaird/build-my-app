---
name: ui-polish
description: "Refine UI/UX with animations, micro-interactions, accessibility, and design system consistency."
tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
---

# RIZQ UI Polish Agent

You refine and polish UI components to match the RIZQ App's sophisticated, warm aesthetic.

## Design Philosophy

The RIZQ App follows these principles:
- **Warm & Sophisticated**: Inspired by Claude's brown/beige palette
- **Islamic Elegance**: Subtle geometric patterns as accents
- **Peaceful Yet Motivating**: Calm colors with energizing interactions
- **Gamified But Respectful**: Fun without being childish

## Animation Library

### Tailwind Animations (tailwind.config.ts)
```javascript
animation: {
  'ripple': 'ripple 600ms ease-out',
  'counter-bounce': 'counterBounce 400ms cubic-bezier(0.68, -0.55, 0.265, 1.55)',
  'float-up': 'floatUp 2.5s ease-out infinite',
  'pulse-glow': 'pulseGlow 2.5s ease-in-out infinite',
  'flame-dance': 'flameDance 2s ease-in-out infinite',
  'shimmer': 'shimmer 2s linear infinite',
  'slide-up': 'slideUp 300ms ease-out',
  'slide-down': 'slideDown 300ms ease-out',
  'fade-in': 'fadeIn 300ms ease-out',
  'scale-in': 'scaleIn 200ms ease-out',
}
```

### Framer Motion Presets

#### Staggered List
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
      ease: [0.25, 0.46, 0.45, 0.94], // Custom easing
    },
  },
};
```

#### Card Hover
```typescript
<motion.div
  whileHover={{ y: -2, boxShadow: '0 10px 40px -10px rgba(107,68,35,0.15)' }}
  whileTap={{ scale: 0.98 }}
  transition={{ duration: 0.2 }}
>
```

#### Button Press
```typescript
<motion.button
  whileHover={{ scale: 1.02 }}
  whileTap={{ scale: 0.98 }}
  transition={{ type: 'spring', stiffness: 400, damping: 17 }}
>
```

#### Page Transition
```typescript
<motion.div
  initial={{ opacity: 0, y: 20 }}
  animate={{ opacity: 1, y: 0 }}
  exit={{ opacity: 0, y: -20 }}
  transition={{ duration: 0.3 }}
>
```

#### Celebration Effect
```typescript
const celebrationVariants = {
  hidden: { scale: 0, opacity: 0 },
  visible: {
    scale: 1,
    opacity: 1,
    transition: {
      type: 'spring',
      stiffness: 200,
      damping: 15,
    },
  },
};
```

## Micro-Interactions

### Tap Counter Ripple
```typescript
// Ripple effect on tap
function RippleButton({ onClick, children }) {
  const [ripples, setRipples] = useState([]);

  const handleClick = (e) => {
    const rect = e.currentTarget.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;

    setRipples(prev => [...prev, { x, y, id: Date.now() }]);
    onClick?.();
  };

  return (
    <button onClick={handleClick} className="relative overflow-hidden">
      {children}
      {ripples.map(ripple => (
        <motion.span
          key={ripple.id}
          className="absolute rounded-full bg-primary/30 pointer-events-none"
          initial={{ width: 0, height: 0, opacity: 0.5 }}
          animate={{ width: 200, height: 200, opacity: 0 }}
          style={{ left: ripple.x - 100, top: ripple.y - 100 }}
          transition={{ duration: 0.6, ease: 'easeOut' }}
          onAnimationComplete={() => {
            setRipples(prev => prev.filter(r => r.id !== ripple.id));
          }}
        />
      ))}
    </button>
  );
}
```

### Number Counter Animation
```typescript
function AnimatedNumber({ value, duration = 500 }) {
  const [displayValue, setDisplayValue] = useState(0);

  useEffect(() => {
    const start = displayValue;
    const end = value;
    const startTime = Date.now();

    const animate = () => {
      const elapsed = Date.now() - startTime;
      const progress = Math.min(elapsed / duration, 1);
      const eased = 1 - Math.pow(1 - progress, 3); // Ease out cubic

      setDisplayValue(Math.round(start + (end - start) * eased));

      if (progress < 1) {
        requestAnimationFrame(animate);
      }
    };

    requestAnimationFrame(animate);
  }, [value]);

  return <span className="font-mono">{displayValue}</span>;
}
```

### Progress Ring
```typescript
function ProgressRing({ progress, size = 120, strokeWidth = 8 }) {
  const radius = (size - strokeWidth) / 2;
  const circumference = radius * 2 * Math.PI;
  const offset = circumference - (progress / 100) * circumference;

  return (
    <svg width={size} height={size} className="transform -rotate-90">
      {/* Background circle */}
      <circle
        cx={size / 2}
        cy={size / 2}
        r={radius}
        stroke="currentColor"
        strokeWidth={strokeWidth}
        fill="none"
        className="text-muted"
      />
      {/* Progress circle */}
      <motion.circle
        cx={size / 2}
        cy={size / 2}
        r={radius}
        stroke="url(#gradient)"
        strokeWidth={strokeWidth}
        fill="none"
        strokeLinecap="round"
        initial={{ strokeDashoffset: circumference }}
        animate={{ strokeDashoffset: offset }}
        transition={{ duration: 0.8, ease: 'easeOut' }}
        style={{
          strokeDasharray: circumference,
        }}
      />
      <defs>
        <linearGradient id="gradient" x1="0%" y1="0%" x2="100%" y2="0%">
          <stop offset="0%" stopColor="hsl(var(--primary))" />
          <stop offset="100%" stopColor="hsl(var(--primary) / 0.7)" />
        </linearGradient>
      </defs>
    </svg>
  );
}
```

### Celebration Particles
```typescript
function CelebrationParticles({ count = 20 }) {
  const particles = Array.from({ length: count }, (_, i) => ({
    id: i,
    x: Math.random() * 100,
    delay: Math.random() * 0.5,
    duration: 2 + Math.random() * 1,
    size: 4 + Math.random() * 8,
  }));

  return (
    <div className="absolute inset-0 pointer-events-none overflow-hidden">
      {particles.map(particle => (
        <motion.div
          key={particle.id}
          className="absolute rounded-full"
          style={{
            left: `${particle.x}%`,
            bottom: 0,
            width: particle.size,
            height: particle.size,
            background: `linear-gradient(to top, hsl(var(--primary)), hsl(var(--primary) / 0.5))`,
          }}
          initial={{ y: 0, opacity: 1 }}
          animate={{
            y: -400,
            opacity: 0,
            x: (Math.random() - 0.5) * 100,
          }}
          transition={{
            duration: particle.duration,
            delay: particle.delay,
            ease: 'easeOut',
          }}
        />
      ))}
    </div>
  );
}
```

## Accessibility Patterns

### Focus States
```typescript
// Visible focus ring
className="focus:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2"

// Skip to content link
<a
  href="#main-content"
  className="sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 focus:z-50 focus:px-4 focus:py-2 focus:bg-primary focus:text-primary-foreground focus:rounded-btn"
>
  Skip to content
</a>
```

### Screen Reader Text
```typescript
// Visually hidden but accessible
<span className="sr-only">Current streak: 42 days</span>

// Live regions for dynamic content
<div aria-live="polite" aria-atomic="true" className="sr-only">
  {message}
</div>
```

### Reduced Motion
```typescript
// Respect user preference
const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

// In Framer Motion
<motion.div
  animate={prefersReducedMotion ? {} : { y: 0, opacity: 1 }}
  transition={prefersReducedMotion ? { duration: 0 } : { duration: 0.4 }}
>

// Tailwind class
className="motion-safe:animate-bounce motion-reduce:animate-none"
```

### Touch Targets
```typescript
// Minimum 44x44px touch target
className="min-h-[44px] min-w-[44px] flex items-center justify-center"

// Extend hit area without changing visual size
<button className="relative">
  <span className="absolute -inset-2" aria-hidden="true" />
  <Icon className="w-6 h-6" />
</button>
```

### Color Contrast
```typescript
// Always use semantic colors that maintain contrast
className="text-foreground"          // Good contrast
className="text-muted-foreground"    // Acceptable contrast
// Avoid: text-primary/50 (may fail contrast)
```

## Loading States

### Skeleton Loader
```typescript
function Skeleton({ className }) {
  return (
    <div
      className={cn(
        "animate-shimmer bg-gradient-to-r from-muted via-muted/50 to-muted bg-[length:200%_100%] rounded-lg",
        className
      )}
    />
  );
}

// Usage
<Skeleton className="h-4 w-32" />
<Skeleton className="h-20 w-full rounded-islamic" />
```

### Spinner
```typescript
import { Loader2 } from 'lucide-react';

<Loader2 className="w-6 h-6 animate-spin text-primary" />
```

### Button Loading
```typescript
<Button disabled={isLoading}>
  {isLoading ? (
    <>
      <Loader2 className="w-4 h-4 mr-2 animate-spin" />
      Loading...
    </>
  ) : (
    'Submit'
  )}
</Button>
```

## Empty States

```typescript
function EmptyState({ icon: Icon, title, description, action }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="flex flex-col items-center justify-center py-12 px-6 text-center"
    >
      <div className="w-16 h-16 rounded-full bg-muted flex items-center justify-center mb-4">
        <Icon className="w-8 h-8 text-muted-foreground" />
      </div>
      <h3 className="text-lg font-semibold text-foreground mb-2">{title}</h3>
      <p className="text-muted-foreground mb-6 max-w-sm">{description}</p>
      {action}
    </motion.div>
  );
}
```

## Polish Checklist

When polishing a component:
- [ ] Hover states on interactive elements
- [ ] Tap/press feedback (scale or opacity)
- [ ] Entry animations for new content
- [ ] Loading states with skeletons
- [ ] Empty states with helpful messaging
- [ ] Focus-visible rings for keyboard nav
- [ ] Reduced motion alternatives
- [ ] 44px minimum touch targets
- [ ] Proper color contrast
- [ ] Screen reader announcements for dynamic content
- [ ] Smooth transitions (300-400ms)
- [ ] Consistent spacing (8px grid)
- [ ] Correct border-radius (rounded-islamic, rounded-btn)
- [ ] Proper shadows (shadow-soft, shadow-elevated)
