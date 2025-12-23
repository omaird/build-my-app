import { Check } from "lucide-react";
import { cn } from "@/lib/utils";
import { DailyActivity } from "@/types/dua";

interface WeekCalendarProps {
  activities: (DailyActivity | null)[];
}

const DAYS = ["S", "M", "T", "W", "T", "F", "S"];

export function WeekCalendar({ activities }: WeekCalendarProps) {
  // Get today's day index (0 = Sunday)
  const today = new Date().getDay();
  
  // Reorder activities to match the week starting from Sunday
  const getWeekDays = () => {
    const result = [];
    for (let i = 6; i >= 0; i--) {
      const date = new Date(Date.now() - i * 86400000);
      const dayIndex = date.getDay();
      result.push({
        day: DAYS[dayIndex],
        activity: activities[6 - i],
        isToday: i === 0,
      });
    }
    return result;
  };

  const weekDays = getWeekDays();

  return (
    <div className="flex items-center justify-between gap-1 rounded-xl bg-secondary/50 p-3">
      {weekDays.map((item, index) => (
        <div key={index} className="flex flex-col items-center gap-1">
          <span className="text-[10px] font-medium text-muted-foreground">
            {item.day}
          </span>
          <div
            className={cn(
              "flex h-8 w-8 items-center justify-center rounded-full transition-all",
              item.activity?.completed 
                ? "bg-primary text-primary-foreground" 
                : "bg-muted",
              item.isToday && !item.activity?.completed && "ring-2 ring-primary ring-offset-2 ring-offset-background"
            )}
          >
            {item.activity?.completed ? (
              <Check className="h-4 w-4" />
            ) : (
              <span className="h-2 w-2 rounded-full bg-muted-foreground/30" />
            )}
          </div>
        </div>
      ))}
    </div>
  );
}