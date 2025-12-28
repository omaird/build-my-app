---
name: new-component
description: "Create a new React component with proper RIZQ patterns"
---

# New Component Command

Create a new component following RIZQ App conventions.

## Usage

```
/new-component [ComponentName] [--feature=habits]
```

## Options

- `--feature=X` - Place in `src/components/X/` (e.g., habits, journeys, achievements)
- Without feature flag: Place in `src/components/`

## Templates

### Basic Card Component

```typescript
import { motion } from 'framer-motion';
import { cn } from '@/lib/utils';

interface [Name]CardProps {
  title: string;
  subtitle?: string;
  className?: string;
  onClick?: () => void;
}

export function [Name]Card({
  title,
  subtitle,
  className,
  onClick,
}: [Name]CardProps) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      whileHover={onClick ? { y: -2 } : undefined}
      whileTap={onClick ? { scale: 0.98 } : undefined}
      onClick={onClick}
      className={cn(
        "p-4 rounded-islamic bg-card border border-border/50",
        "shadow-soft transition-all duration-300",
        onClick && "cursor-pointer",
        className
      )}
    >
      <h3 className="font-semibold text-foreground">{title}</h3>
      {subtitle && (
        <p className="text-sm text-muted-foreground mt-1">{subtitle}</p>
      )}
    </motion.div>
  );
}
```

### List Item Component

```typescript
import { motion } from 'framer-motion';
import { ChevronRight, LucideIcon } from 'lucide-react';
import { cn } from '@/lib/utils';

interface [Name]ItemProps {
  icon: LucideIcon;
  title: string;
  subtitle?: string;
  onClick?: () => void;
  className?: string;
}

export function [Name]Item({
  icon: Icon,
  title,
  subtitle,
  onClick,
  className,
}: [Name]ItemProps) {
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
        <Icon className="w-5 h-5 text-primary" />
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

### Empty State Component

```typescript
import { motion } from 'framer-motion';
import { LucideIcon } from 'lucide-react';

interface [Name]EmptyProps {
  icon: LucideIcon;
  title: string;
  description: string;
  action?: React.ReactNode;
}

export function [Name]Empty({
  icon: Icon,
  title,
  description,
  action,
}: [Name]EmptyProps) {
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

### Badge Component

```typescript
import { cn } from '@/lib/utils';

type [Name]BadgeVariant = 'default' | 'success' | 'warning' | 'premium';

interface [Name]BadgeProps {
  children: React.ReactNode;
  variant?: [Name]BadgeVariant;
  className?: string;
}

const variantStyles: Record<[Name]BadgeVariant, string> = {
  default: "bg-primary/10 text-primary",
  success: "bg-success/10 text-success",
  warning: "bg-amber-500/10 text-amber-600",
  premium: "bg-gradient-to-r from-amber-500/20 to-primary/20 text-amber-700",
};

export function [Name]Badge({
  children,
  variant = 'default',
  className,
}: [Name]BadgeProps) {
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

## Checklist

After creating:
- [ ] Props interface defined
- [ ] Uses `cn()` for class merging
- [ ] Has Framer Motion animations
- [ ] Follows naming conventions
- [ ] Exported from file
