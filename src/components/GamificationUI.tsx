import { motion } from "framer-motion";
import { Flame, Star, Sparkles } from "lucide-react";
import { cn } from "@/lib/utils";

interface StreakBadgeProps {
  streak: number;
  size?: "sm" | "md" | "lg";
  showLabel?: boolean;
}

export function StreakBadge({ streak, size = "md", showLabel = true }: StreakBadgeProps) {
  const sizeClasses = {
    sm: { container: "h-10 w-10", icon: 16, badge: "h-4 w-4 text-[8px]", label: "text-[10px]" },
    md: { container: "h-14 w-14", icon: 22, badge: "h-5 w-5 text-[10px]", label: "text-xs" },
    lg: { container: "h-20 w-20", icon: 30, badge: "h-6 w-6 text-xs", label: "text-sm" },
  };

  const config = sizeClasses[size];
  const hasStreak = streak > 0;

  return (
    <div className="flex flex-col items-center gap-1.5">
      <motion.div
        className={cn(
          "relative flex items-center justify-center rounded-full",
          "bg-gradient-to-br from-amber-100 via-amber-50 to-orange-100",
          "dark:from-amber-900/50 dark:via-amber-800/40 dark:to-orange-900/50",
          "border-2 border-primary/25",
          hasStreak && "shadow-glow-streak",
          config.container
        )}
        animate={hasStreak ? {
          boxShadow: [
            "0 0 20px rgba(230, 199, 156, 0.4)",
            "0 0 35px rgba(230, 199, 156, 0.6)",
            "0 0 20px rgba(230, 199, 156, 0.4)",
          ],
        } : {}}
        transition={{ duration: 2.5, repeat: Infinity, ease: "easeInOut" }}
      >
        <motion.div
          animate={hasStreak ? {
            y: [0, -2, 0, -1, 0],
            scale: [1, 1.05, 1, 1.02, 1],
            rotate: [-2, 2, -1, 1, 0],
          } : {}}
          transition={{ duration: 2, repeat: Infinity, ease: "easeInOut" }}
        >
          <Flame
            className={cn(
              "text-primary transition-all",
              hasStreak && "fill-primary drop-shadow-sm"
            )}
            size={config.icon}
          />
        </motion.div>

        {/* Streak count badge */}
        <motion.span
          className={cn(
            "absolute -bottom-0.5 -right-0.5 flex items-center justify-center rounded-full",
            "bg-accent font-bold text-accent-foreground shadow-sm",
            "border border-background",
            config.badge
          )}
          initial={false}
          animate={hasStreak ? { scale: [1, 1.15, 1] } : {}}
          transition={{ duration: 0.3 }}
          key={streak}
        >
          {streak}
        </motion.span>
      </motion.div>

      {showLabel && (
        <span className={cn("font-medium text-muted-foreground", config.label)}>
          {streak === 1 ? "day" : "days"}
        </span>
      )}
    </div>
  );
}

interface XpProgressBarProps {
  current: number;
  needed: number;
  percentage: number;
  level: number;
  showDetails?: boolean;
}

export function XpProgressBar({
  current,
  needed,
  percentage,
  level,
  showDetails = true,
}: XpProgressBarProps) {
  return (
    <div className="w-full space-y-3">
      {showDetails && (
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2.5">
            <LevelBadge level={level} size="sm" />
            <span className="font-display text-lg font-semibold text-foreground">
              Level {level}
            </span>
          </div>
          <div className="flex items-center gap-1.5 text-sm text-muted-foreground">
            <Sparkles className="h-3.5 w-3.5 text-primary" />
            <span className="font-mono tabular-nums">
              {current.toLocaleString()}
            </span>
            <span className="text-muted-foreground/60">/</span>
            <span className="font-mono tabular-nums">
              {needed.toLocaleString()}
            </span>
            <span className="text-xs">XP</span>
          </div>
        </div>
      )}

      {/* Progress bar */}
      <div className="relative h-3 w-full overflow-hidden rounded-full bg-secondary/70 shadow-inner-glow">
        <motion.div
          className="absolute inset-y-0 left-0 rounded-full gradient-primary"
          initial={{ width: 0 }}
          animate={{ width: `${percentage}%` }}
          transition={{ duration: 0.8, ease: [0.25, 0.46, 0.45, 0.94] }}
        />
        {/* Shimmer effect */}
        <motion.div
          className="absolute inset-y-0 left-0 w-full"
          style={{
            background: "linear-gradient(90deg, transparent, rgba(255,255,255,0.3), transparent)",
            width: `${percentage}%`,
          }}
          animate={{ x: ["-100%", "100%"] }}
          transition={{ duration: 2, repeat: Infinity, ease: "linear", repeatDelay: 3 }}
        />
      </div>
    </div>
  );
}

// Circular XP Progress variant
interface CircularXpProgressProps {
  current: number;
  needed: number;
  percentage: number;
  level: number;
  size?: number;
}

export function CircularXpProgress({
  current,
  needed,
  percentage,
  level,
  size = 100,
}: CircularXpProgressProps) {
  const strokeWidth = 8;
  const radius = (size - strokeWidth) / 2;
  const circumference = 2 * Math.PI * radius;

  return (
    <div className="relative inline-flex items-center justify-center" style={{ width: size, height: size }}>
      <svg width={size} height={size} className="transform -rotate-90">
        {/* Background track */}
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          stroke="hsl(var(--secondary))"
          strokeWidth={strokeWidth}
          className="opacity-50"
        />
        {/* Progress arc */}
        <motion.circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          stroke="url(#xpGradient)"
          strokeWidth={strokeWidth}
          strokeLinecap="round"
          strokeDasharray={circumference}
          initial={{ strokeDashoffset: circumference }}
          animate={{ strokeDashoffset: circumference - (percentage / 100) * circumference }}
          transition={{ duration: 1, ease: "easeOut" }}
        />
        <defs>
          <linearGradient id="xpGradient" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#D4A574" />
            <stop offset="100%" stopColor="#A67C52" />
          </linearGradient>
        </defs>
      </svg>

      {/* Center content */}
      <div className="absolute inset-0 flex flex-col items-center justify-center">
        <LevelBadge level={level} size="md" />
      </div>
    </div>
  );
}

interface LevelBadgeProps {
  level: number;
  size?: "sm" | "md" | "lg";
}

export function LevelBadge({ level, size = "md" }: LevelBadgeProps) {
  const sizeClasses = {
    sm: "h-7 w-7 text-xs",
    md: "h-9 w-9 text-sm",
    lg: "h-12 w-12 text-lg",
  };

  return (
    <motion.div
      className={cn(
        "flex items-center justify-center rounded-full",
        "bg-gradient-to-br from-accent to-mocha font-bold text-accent-foreground",
        "shadow-sm border border-accent/20",
        sizeClasses[size]
      )}
      whileHover={{ scale: 1.05 }}
      whileTap={{ scale: 0.95 }}
    >
      <Star className="h-3 w-3 fill-current opacity-80 mr-0.5" />
      {level}
    </motion.div>
  );
}

// XP Earned animation badge
interface XpEarnedBadgeProps {
  amount: number;
  isVisible: boolean;
}

export function XpEarnedBadge({ amount, isVisible }: XpEarnedBadgeProps) {
  return (
    <motion.div
      className={cn(
        "inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full",
        "bg-gold-soft/20 border border-gold-soft/40 text-primary font-semibold"
      )}
      initial={{ opacity: 0, y: 10, scale: 0.9 }}
      animate={isVisible ? { opacity: 1, y: 0, scale: 1 } : { opacity: 0, y: 10, scale: 0.9 }}
      transition={{ type: "spring", stiffness: 300, damping: 20 }}
    >
      <Sparkles className="h-4 w-4" />
      <span className="font-mono">+{amount}</span>
      <span className="text-sm">XP</span>
    </motion.div>
  );
}
