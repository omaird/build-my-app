---
name: component-patterns
description: "Standard patterns for RIZQ components: props interfaces, variants, animations, and composition"
---

# RIZQ Component Patterns

## File Structure

```typescript
// 1. Imports
import { motion } from 'framer-motion';
import { LucideIcon } from 'lucide-react';
import { cn } from '@/lib/utils';

// 2. Types/Interfaces
interface MyComponentProps {
  title: string;
  subtitle?: string;
  icon?: LucideIcon;
  variant?: 'default' | 'accent';
  size?: 'sm' | 'md' | 'lg';
  className?: string;
  onClick?: () => void;
  children?: React.ReactNode;
}

// 3. Variants (if using CVA or manual)
const sizeStyles = {
  sm: "p-3 text-sm",
  md: "p-4 text-base",
  lg: "p-5 text-lg",
};

// 4. Component Export
export function MyComponent({
  title,
  subtitle,
  icon: Icon,
  variant = 'default',
  size = 'md',
  className,
  onClick,
  children,
}: MyComponentProps) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      whileHover={onClick ? { y: -2 } : undefined}
      whileTap={onClick ? { scale: 0.98 } : undefined}
      onClick={onClick}
      className={cn(
        "rounded-islamic bg-card border border-border/50",
        sizeStyles[size],
        onClick && "cursor-pointer",
        className
      )}
    >
      {Icon && <Icon className="w-5 h-5 text-primary" />}
      <h3 className="font-semibold text-foreground">{title}</h3>
      {subtitle && <p className="text-sm text-muted-foreground">{subtitle}</p>}
      {children}
    </motion.div>
  );
}
```

## Props Patterns

### Required vs Optional
```typescript
interface Props {
  id: string;              // Required
  title: string;           // Required
  description?: string;    // Optional
  isActive?: boolean;      // Optional with implicit undefined
  count?: number;          // Optional
}
```

### Event Handlers
```typescript
interface Props {
  onClick?: () => void;
  onComplete?: (id: string) => void;
  onChange?: (value: string) => void;
  onSubmit?: (data: FormData) => Promise<void>;
}
```

### Icon Props
```typescript
import { LucideIcon } from 'lucide-react';

interface Props {
  icon?: LucideIcon;  // Pass component, not element
}

// Usage
<MyComponent icon={Star} />

// Inside component
{Icon && <Icon className="w-5 h-5" />}
```

### Children Patterns
```typescript
// Simple children
interface Props {
  children: React.ReactNode;
}

// Render prop
interface Props {
  children: (data: Data) => React.ReactNode;
}

// Named slots
interface Props {
  header?: React.ReactNode;
  footer?: React.ReactNode;
  children: React.ReactNode;
}
```

## Animation Patterns

### Entry Animation (Single Element)
```typescript
<motion.div
  initial={{ opacity: 0, y: 20 }}
  animate={{ opacity: 1, y: 0 }}
  transition={{ duration: 0.4 }}
>
```

### Staggered List
```typescript
const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: { staggerChildren: 0.08, delayChildren: 0.1 },
  },
};

const itemVariants = {
  hidden: { opacity: 0, y: 20 },
  visible: {
    opacity: 1,
    y: 0,
    transition: { duration: 0.4, ease: [0.25, 0.46, 0.45, 0.94] },
  },
};

// Usage
<motion.div variants={containerVariants} initial="hidden" animate="visible">
  {items.map(item => (
    <motion.div key={item.id} variants={itemVariants}>
      <ItemComponent item={item} />
    </motion.div>
  ))}
</motion.div>
```

### Exit Animation
```typescript
import { AnimatePresence } from 'framer-motion';

<AnimatePresence mode="wait">
  {isVisible && (
    <motion.div
      key="modal"
      initial={{ opacity: 0, scale: 0.95 }}
      animate={{ opacity: 1, scale: 1 }}
      exit={{ opacity: 0, scale: 0.95 }}
    >
      {content}
    </motion.div>
  )}
</AnimatePresence>
```

### Interactive States
```typescript
// Card - lift on hover
<motion.div whileHover={{ y: -2 }} whileTap={{ scale: 0.98 }}>

// Button - scale
<motion.button whileHover={{ scale: 1.02 }} whileTap={{ scale: 0.98 }}>

// List item - slide right
<motion.div whileHover={{ x: 4 }}>

// Icon button - rotate
<motion.button whileHover={{ rotate: 15 }}>
```

## Conditional Styling

### Using cn() Utility
```typescript
className={cn(
  // Base styles (always applied)
  "p-4 rounded-islamic bg-card",

  // Conditional styles
  isActive && "ring-2 ring-primary",
  isDisabled && "opacity-50 cursor-not-allowed",
  variant === 'accent' && "bg-accent text-accent-foreground",

  // Size variants
  size === 'sm' && "p-2 text-sm",
  size === 'lg' && "p-6 text-lg",

  // External className (last for override)
  className
)}
```

### Variant Objects
```typescript
const variants = {
  default: "bg-card text-foreground",
  primary: "bg-primary text-primary-foreground",
  accent: "bg-accent text-accent-foreground",
  ghost: "bg-transparent hover:bg-muted",
};

className={cn(variants[variant], className)}
```

## Composition Patterns

### Compound Components
```typescript
// Card.tsx
function Card({ children, className }: CardProps) {
  return <div className={cn("rounded-islamic bg-card", className)}>{children}</div>;
}

function CardHeader({ children }: { children: React.ReactNode }) {
  return <div className="p-4 border-b border-border">{children}</div>;
}

function CardContent({ children }: { children: React.ReactNode }) {
  return <div className="p-4">{children}</div>;
}

Card.Header = CardHeader;
Card.Content = CardContent;

export { Card };

// Usage
<Card>
  <Card.Header>Title</Card.Header>
  <Card.Content>Content</Card.Content>
</Card>
```

### Wrapper Components
```typescript
// AnimatedCard.tsx
export function AnimatedCard({ children, ...props }: CardProps) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      whileHover={{ y: -2 }}
    >
      <Card {...props}>{children}</Card>
    </motion.div>
  );
}
```

## Loading & Empty States

### Loading State
```typescript
if (isLoading) {
  return (
    <div className="flex items-center justify-center min-h-[200px]">
      <Loader2 className="w-8 h-8 animate-spin text-primary" />
    </div>
  );
}
```

### Empty State
```typescript
if (!data?.length) {
  return (
    <div className="flex flex-col items-center justify-center py-12 text-center">
      <div className="w-16 h-16 rounded-full bg-muted flex items-center justify-center mb-4">
        <Icon className="w-8 h-8 text-muted-foreground" />
      </div>
      <h3 className="font-semibold text-foreground">No items yet</h3>
      <p className="text-muted-foreground mt-1">Get started by adding your first item</p>
    </div>
  );
}
```

### Skeleton Loading
```typescript
function Skeleton({ className }: { className?: string }) {
  return (
    <div className={cn(
      "animate-shimmer bg-gradient-to-r from-muted via-muted/50 to-muted",
      "bg-[length:200%_100%] rounded-lg",
      className
    )} />
  );
}

// Usage
<Skeleton className="h-4 w-32" />
<Skeleton className="h-20 w-full rounded-islamic" />
```

## Page Component Pattern

```typescript
export default function MyPage() {
  const { data, isLoading } = useMyData();

  if (isLoading) {
    return <LoadingState />;
  }

  return (
    <div className="min-h-screen bg-background pb-24">
      {/* Header */}
      <div className="px-5 pt-6 pb-4">
        <h1 className="text-2xl font-bold text-foreground">Page Title</h1>
        <p className="text-muted-foreground mt-1">Subtitle</p>
      </div>

      {/* Content */}
      <motion.div
        variants={containerVariants}
        initial="hidden"
        animate="visible"
        className="px-5 space-y-4"
      >
        {data?.length ? (
          data.map(item => (
            <motion.div key={item.id} variants={itemVariants}>
              <ItemCard item={item} />
            </motion.div>
          ))
        ) : (
          <EmptyState />
        )}
      </motion.div>
    </div>
  );
}
```
