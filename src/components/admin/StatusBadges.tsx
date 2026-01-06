import { Crown, Star, Sparkles } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";

interface StatusBadgeProps {
  className?: string;
}

/**
 * Badge indicating premium content that requires a subscription.
 */
export function PremiumBadge({ className }: StatusBadgeProps) {
  return (
    <Badge
      variant="secondary"
      className={cn(
        "bg-amber-100 text-amber-800 border-amber-200",
        "dark:bg-amber-900/30 dark:text-amber-300 dark:border-amber-800",
        className
      )}
    >
      <Crown className="h-3 w-3 mr-1" />
      Premium
    </Badge>
  );
}

/**
 * Badge indicating featured content shown prominently in the app.
 */
export function FeaturedBadge({ className }: StatusBadgeProps) {
  return (
    <Badge
      variant="secondary"
      className={cn(
        "bg-primary/10 text-primary border-primary/20",
        className
      )}
    >
      <Star className="h-3 w-3 mr-1" />
      Featured
    </Badge>
  );
}

/**
 * Compact icon-only version for tables where space is limited.
 */
export function PremiumIcon({ className }: StatusBadgeProps) {
  return (
    <Crown
      className={cn("h-4 w-4 text-amber-500", className)}
      aria-label="Premium"
    />
  );
}

/**
 * Compact icon-only version for tables where space is limited.
 */
export function FeaturedIcon({ className }: StatusBadgeProps) {
  return (
    <Star
      className={cn("h-4 w-4 text-primary fill-primary", className)}
      aria-label="Featured"
    />
  );
}

/**
 * XP badge with sparkle effect for gamification display.
 */
export function XpBadge({ xp, className }: { xp: number } & StatusBadgeProps) {
  return (
    <Badge variant="secondary" className={cn("font-mono", className)}>
      <Sparkles className="h-3 w-3 mr-1" />
      {xp} XP
    </Badge>
  );
}
