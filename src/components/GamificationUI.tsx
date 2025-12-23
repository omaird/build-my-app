import { Flame, Star } from "lucide-react";
import { cn } from "@/lib/utils";

interface StreakBadgeProps {
  streak: number;
  size?: "sm" | "md" | "lg";
  showLabel?: boolean;
}

export function StreakBadge({ streak, size = "md", showLabel = true }: StreakBadgeProps) {
  const sizeClasses = {
    sm: "h-8 w-8 text-sm",
    md: "h-12 w-12 text-lg",
    lg: "h-16 w-16 text-2xl",
  };

  const iconSizes = {
    sm: 14,
    md: 20,
    lg: 28,
  };

  return (
    <div className="flex flex-col items-center gap-1">
      <div
        className={cn(
          "relative flex items-center justify-center rounded-full bg-primary/10 border-2 border-primary",
          streak > 0 && "glow-streak animate-streak-flame",
          sizeClasses[size]
        )}
      >
        <Flame 
          className={cn(
            "text-primary",
            streak > 0 && "fill-primary"
          )} 
          size={iconSizes[size]} 
        />
        <span className="absolute -bottom-1 -right-1 flex h-5 w-5 items-center justify-center rounded-full bg-accent text-[10px] font-bold text-accent-foreground">
          {streak}
        </span>
      </div>
      {showLabel && (
        <span className="text-xs font-medium text-muted-foreground">
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
}

export function XpProgressBar({ current, needed, percentage, level }: XpProgressBarProps) {
  return (
    <div className="w-full space-y-2">
      <div className="flex items-center justify-between text-sm">
        <div className="flex items-center gap-2">
          <div className="flex h-6 w-6 items-center justify-center rounded-full bg-accent">
            <Star className="h-3.5 w-3.5 fill-accent-foreground text-accent-foreground" size={14} />
          </div>
          <span className="font-semibold">Level {level}</span>
        </div>
        <span className="text-muted-foreground">
          {current} / {needed} XP
        </span>
      </div>
      <div className="h-3 w-full overflow-hidden rounded-full bg-secondary">
        <div
          className="h-full rounded-full bg-primary transition-all duration-500 ease-out"
          style={{ width: `${percentage}%` }}
        />
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
    sm: "h-6 w-6 text-xs",
    md: "h-8 w-8 text-sm",
    lg: "h-10 w-10 text-base",
  };

  return (
    <div
      className={cn(
        "flex items-center justify-center rounded-full bg-accent font-bold text-accent-foreground",
        sizeClasses[size]
      )}
    >
      {level}
    </div>
  );
}