import { motion } from "framer-motion";
import { Sun, Clock, Moon } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { HabitItem } from "./HabitItem";
import { cn } from "@/lib/utils";
import type { HabitWithDua, TimeSlot } from "@/types/habit";

interface HabitTimeSlotSectionProps {
  timeSlot: TimeSlot;
  habits: HabitWithDua[];
  onHabitClick: (habit: HabitWithDua) => void;
  onHabitRemove?: (habitId: string) => void;
}

const slotConfig = {
  morning: {
    label: "Morning",
    subLabel: "After Fajr",
    Icon: Sun,
    iconColor: "text-amber-500",
    bgColor: "bg-amber-500/10",
    borderColor: "border-amber-500/20",
  },
  anytime: {
    label: "Anytime",
    subLabel: "Throughout the day",
    Icon: Clock,
    iconColor: "text-blue-500",
    bgColor: "bg-blue-500/10",
    borderColor: "border-blue-500/20",
  },
  evening: {
    label: "Evening",
    subLabel: "After Maghrib",
    Icon: Moon,
    iconColor: "text-indigo-500",
    bgColor: "bg-indigo-500/10",
    borderColor: "border-indigo-500/20",
  },
};

export function HabitTimeSlotSection({
  timeSlot,
  habits,
  onHabitClick,
  onHabitRemove,
}: HabitTimeSlotSectionProps) {
  if (habits.length === 0) return null;

  const config = slotConfig[timeSlot];
  const completedCount = habits.filter((h) => h.isCompletedToday).length;
  const allCompleted = completedCount === habits.length;

  return (
    <motion.div
      className="space-y-2"
      initial={{ opacity: 0, y: 15 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4 }}
    >
      {/* Section header */}
      <div className="flex items-center justify-between px-1">
        <div className="flex items-center gap-2.5">
          <motion.div
            className={cn(
              "flex h-7 w-7 items-center justify-center rounded-full",
              config.bgColor,
              allCompleted && "shadow-sm"
            )}
            whileHover={{ scale: 1.1 }}
          >
            <config.Icon className={cn("h-4 w-4", config.iconColor)} />
          </motion.div>
          <div className="flex items-baseline gap-2">
            <span className="text-sm font-semibold text-foreground">
              {config.label}
            </span>
            <span className="text-xs text-muted-foreground">
              {config.subLabel}
            </span>
          </div>
        </div>

        {/* Completion counter */}
        <div className="flex items-center gap-1.5">
          <span
            className={cn(
              "text-xs font-medium font-mono",
              allCompleted ? "text-primary" : "text-muted-foreground"
            )}
          >
            {completedCount}/{habits.length}
          </span>
          {/* Mini progress dots */}
          <div className="flex gap-0.5">
            {habits.slice(0, 5).map((h, i) => (
              <motion.div
                key={i}
                className={cn(
                  "h-1.5 w-1.5 rounded-full",
                  h.isCompletedToday ? "bg-primary" : "bg-muted"
                )}
                initial={{ scale: 0 }}
                animate={{ scale: 1 }}
                transition={{ delay: i * 0.05 }}
              />
            ))}
          </div>
        </div>
      </div>

      {/* Habit items */}
      <Card
        className={cn(
          "overflow-hidden shadow-soft transition-all",
          allCompleted && "border-primary/20 bg-primary/[0.02]"
        )}
      >
        <CardContent className="divide-y divide-border/50 p-0">
          {habits.map((habit, index) => (
            <HabitItem
              key={habit.id}
              habit={habit}
              onClick={() => onHabitClick(habit)}
              onRemove={onHabitRemove}
              index={index}
            />
          ))}
        </CardContent>

        {/* Completed accent line */}
        {allCompleted && (
          <motion.div
            className="h-0.5 gradient-primary"
            initial={{ scaleX: 0 }}
            animate={{ scaleX: 1 }}
            transition={{ duration: 0.5 }}
          />
        )}
      </Card>
    </motion.div>
  );
}
