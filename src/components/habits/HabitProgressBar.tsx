import { motion } from "framer-motion";
import { Sparkles } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import type { HabitProgress } from "@/types/habit";

interface HabitProgressBarProps {
  progress: HabitProgress;
}

export function HabitProgressBar({ progress }: HabitProgressBarProps) {
  const { completed, total, percentage, earnedXp, totalXp } = progress;

  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4 }}
    >
      <Card className="overflow-hidden border-primary/10 shadow-soft">
        <CardContent className="p-4">
          {/* Header row */}
          <div className="flex items-center justify-between mb-3">
            <div className="flex items-center gap-2">
              <span className="text-xs font-medium text-muted-foreground uppercase tracking-wider">
                Today's Progress
              </span>
              <span className="text-sm font-semibold text-foreground">
                {completed}/{total}
              </span>
            </div>
            <motion.div
              className="flex items-center gap-1.5 rounded-full bg-gold-soft/20 border border-gold-soft/30 px-2.5 py-1"
              initial={{ opacity: 0, scale: 0.8 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ delay: 0.2 }}
            >
              <Sparkles className="h-3 w-3 text-primary" />
              <span className="text-xs font-semibold text-primary font-mono">
                {earnedXp}/{totalXp}
              </span>
              <span className="text-[10px] text-muted-foreground">XP</span>
            </motion.div>
          </div>

          {/* Progress bar */}
          <div className="relative h-3 w-full overflow-hidden rounded-full bg-secondary/70 shadow-inner-glow">
            {/* Animated gradient fill */}
            <motion.div
              className="absolute inset-y-0 left-0 rounded-full gradient-primary"
              initial={{ width: 0 }}
              animate={{ width: `${percentage}%` }}
              transition={{ duration: 0.6, ease: [0.25, 0.46, 0.45, 0.94] }}
            >
              {/* Shimmer effect */}
              <motion.div
                className="absolute inset-0 bg-gradient-to-r from-transparent via-white/20 to-transparent"
                animate={{ x: ["-100%", "200%"] }}
                transition={{ duration: 2, repeat: Infinity, repeatDelay: 1 }}
              />
            </motion.div>

            {/* Segment markers */}
            <div className="absolute inset-0 flex items-center justify-around pointer-events-none">
              {Array.from({ length: Math.min(total - 1, 6) }).map((_, i) => (
                <div
                  key={i}
                  className="h-full w-px bg-background/30"
                  style={{ left: `${((i + 1) / total) * 100}%` }}
                />
              ))}
            </div>
          </div>

          {/* Completion indicators */}
          <div className="flex justify-between mt-2">
            {Array.from({ length: Math.min(total, 7) }).map((_, i) => (
              <motion.div
                key={i}
                className={`h-1.5 w-1.5 rounded-full transition-colors ${
                  i < completed ? "bg-primary" : "bg-muted"
                }`}
                initial={{ scale: 0 }}
                animate={{ scale: 1 }}
                transition={{ delay: 0.1 * i }}
              />
            ))}
          </div>
        </CardContent>
      </Card>
    </motion.div>
  );
}
