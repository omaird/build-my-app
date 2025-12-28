import { motion } from "framer-motion";
import { Check, Sparkles } from "lucide-react";
import { cn } from "@/lib/utils";
import type { HabitWithDua } from "@/types/habit";

interface HabitItemProps {
  habit: HabitWithDua;
  onClick: () => void;
  index?: number;
}

export function HabitItem({ habit, onClick, index = 0 }: HabitItemProps) {
  const { dua, isCompletedToday } = habit;

  return (
    <motion.button
      onClick={onClick}
      className={cn(
        "flex w-full items-center justify-between px-4 py-3.5 text-left transition-all",
        "hover:bg-secondary/50 active:scale-[0.99]",
        isCompletedToday && "bg-primary/[0.03]"
      )}
      initial={{ opacity: 0, x: -10 }}
      animate={{ opacity: 1, x: 0 }}
      transition={{ delay: index * 0.05, duration: 0.3 }}
      whileTap={{ scale: 0.98 }}
    >
      <div className="flex items-center gap-3">
        {/* Animated checkbox circle */}
        <motion.div
          className={cn(
            "relative flex h-7 w-7 shrink-0 items-center justify-center rounded-full border-2 transition-all",
            isCompletedToday
              ? "border-primary bg-primary text-primary-foreground shadow-glow-primary"
              : "border-muted-foreground/30 hover:border-primary/50"
          )}
          whileHover={!isCompletedToday ? { scale: 1.1 } : {}}
          whileTap={!isCompletedToday ? { scale: 0.9 } : {}}
        >
          {isCompletedToday && (
            <motion.div
              initial={{ scale: 0, rotate: -180 }}
              animate={{ scale: 1, rotate: 0 }}
              transition={{ type: "spring", stiffness: 400, damping: 15 }}
            >
              <Check className="h-4 w-4" />
            </motion.div>
          )}

          {/* Pulse ring on hover for uncompleted */}
          {!isCompletedToday && (
            <motion.div
              className="absolute inset-0 rounded-full border-2 border-primary/30"
              initial={{ scale: 1, opacity: 0 }}
              whileHover={{ scale: 1.3, opacity: 1 }}
              transition={{ duration: 0.2 }}
            />
          )}
        </motion.div>

        {/* Dua title */}
        <span
          className={cn(
            "text-sm font-medium transition-all",
            isCompletedToday && "line-through text-muted-foreground"
          )}
        >
          {dua.title}
        </span>
      </div>

      {/* XP value badge */}
      <motion.div
        className={cn(
          "flex items-center gap-1 rounded-full px-2.5 py-1 text-xs font-medium",
          isCompletedToday
            ? "bg-primary/10 text-primary/60"
            : "bg-gold-soft/20 text-primary"
        )}
        initial={{ opacity: 0, scale: 0.8 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ delay: index * 0.05 + 0.1 }}
      >
        <Sparkles className="h-3 w-3" />
        <span className="font-mono">{dua.xpValue}</span>
      </motion.div>
    </motion.button>
  );
}
