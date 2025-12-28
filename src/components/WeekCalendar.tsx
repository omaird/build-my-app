import { motion } from "framer-motion";
import { Check } from "lucide-react";
import { cn } from "@/lib/utils";
import { DailyActivity } from "@/types/dua";

interface WeekCalendarProps {
  activities: (DailyActivity | null)[];
}

const DAYS = ["S", "M", "T", "W", "T", "F", "S"];

export function WeekCalendar({ activities }: WeekCalendarProps) {
  const getWeekDays = () => {
    const result = [];
    for (let i = 6; i >= 0; i--) {
      const date = new Date(Date.now() - i * 86400000);
      const dayIndex = date.getDay();
      result.push({
        day: DAYS[dayIndex],
        activity: activities[6 - i],
        isToday: i === 0,
        date: date.getDate(),
      });
    }
    return result;
  };

  const weekDays = getWeekDays();
  const completedCount = weekDays.filter((d) => d.activity?.completed).length;

  return (
    <div className="relative overflow-hidden rounded-islamic bg-card border shadow-soft p-4">
      {/* Subtle pattern background */}
      <div className="absolute inset-0 islamic-pattern-dense opacity-30" />

      {/* Header with streak info */}
      <div className="relative mb-4 flex items-center justify-between">
        <span className="text-xs font-medium text-muted-foreground uppercase tracking-wider">
          This Week
        </span>
        <div className="flex items-center gap-1.5">
          <span className="text-xs text-muted-foreground">
            {completedCount}/7 days
          </span>
          <motion.div
            className="flex"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.3 }}
          >
            {Array.from({ length: 7 }).map((_, i) => (
              <motion.div
                key={i}
                className={cn(
                  "h-1.5 w-1.5 rounded-full mx-0.5",
                  i < completedCount ? "bg-primary" : "bg-muted"
                )}
                initial={{ scale: 0 }}
                animate={{ scale: 1 }}
                transition={{ delay: 0.1 * i }}
              />
            ))}
          </motion.div>
        </div>
      </div>

      {/* Calendar grid */}
      <div className="relative flex items-center justify-between gap-2">
        {weekDays.map((item, index) => (
          <motion.div
            key={index}
            className="flex flex-col items-center gap-2"
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: index * 0.05 }}
          >
            {/* Day label */}
            <span
              className={cn(
                "text-[10px] font-semibold uppercase tracking-wide",
                item.isToday ? "text-primary" : "text-muted-foreground"
              )}
            >
              {item.day}
            </span>

            {/* Day circle */}
            <motion.div
              className={cn(
                "relative flex h-9 w-9 items-center justify-center rounded-full transition-all",
                item.activity?.completed
                  ? "bg-primary text-primary-foreground shadow-glow-primary"
                  : item.isToday
                  ? "bg-secondary border-2 border-primary"
                  : "bg-muted/50"
              )}
              whileHover={{ scale: 1.1 }}
              whileTap={{ scale: 0.95 }}
            >
              {item.activity?.completed ? (
                <motion.div
                  initial={{ scale: 0 }}
                  animate={{ scale: 1 }}
                  transition={{ type: "spring", stiffness: 400, damping: 15 }}
                >
                  <Check className="h-4 w-4" />
                </motion.div>
              ) : item.isToday ? (
                <motion.div
                  className="absolute inset-0 rounded-full border-2 border-primary"
                  animate={{ scale: [1, 1.15, 1], opacity: [1, 0.5, 1] }}
                  transition={{ duration: 2, repeat: Infinity }}
                />
              ) : (
                <span className="h-1.5 w-1.5 rounded-full bg-muted-foreground/20" />
              )}
            </motion.div>

            {/* XP earned indicator */}
            {item.activity?.xpEarned && item.activity.xpEarned > 0 && (
              <motion.span
                className="text-[9px] font-medium text-primary"
                initial={{ opacity: 0, y: -5 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.3 + index * 0.05 }}
              >
                +{item.activity.xpEarned}
              </motion.span>
            )}
          </motion.div>
        ))}
      </div>

      {/* Connecting line behind circles */}
      <div className="absolute left-8 right-8 top-[72px] h-0.5 -z-10">
        <div className="absolute inset-0 bg-gradient-to-r from-transparent via-border to-transparent" />
      </div>
    </div>
  );
}
