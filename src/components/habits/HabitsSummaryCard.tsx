import { useNavigate } from "react-router-dom";
import { Check, ChevronRight, Compass, Sparkles } from "lucide-react";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { useUserHabits } from "@/hooks/useUserHabits";
import { cn } from "@/lib/utils";

export function HabitsSummaryCard() {
  const navigate = useNavigate();
  const { progress, hasHabits, activeJourney } = useUserHabits();

  const allCompleted =
    progress.completed === progress.total && progress.total > 0;

  // No habits configured state
  if (!hasHabits) {
    return (
      <Card className="overflow-hidden border-dashed">
        <div className="p-4">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-full bg-muted">
              <Compass className="h-5 w-5 text-muted-foreground" />
            </div>
            <div className="flex-1">
              <p className="font-medium text-foreground">Daily Adkhar</p>
              <p className="text-sm text-muted-foreground">
                No habits configured yet
              </p>
            </div>
          </div>
          <Button
            variant="link"
            className="mt-2 h-auto p-0 text-primary"
            onClick={() => navigate("/journeys")}
          >
            Browse Journeys →
          </Button>
        </div>
      </Card>
    );
  }

  return (
    <Card
      className={cn(
        "cursor-pointer overflow-hidden transition-all duration-200",
        "hover:shadow-md hover:border-primary/30",
        "active:scale-[0.99]",
        allCompleted && "border-green-500/30 bg-green-50/50 dark:bg-green-950/20"
      )}
      onClick={() => navigate("/adkhar")}
    >
      <div className="p-4">
        {/* Header row */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            {/* Icon */}
            <div
              className={cn(
                "flex h-10 w-10 items-center justify-center rounded-full",
                allCompleted
                  ? "bg-green-100 dark:bg-green-900/30"
                  : "bg-primary/10"
              )}
            >
              {allCompleted ? (
                <Check className="h-5 w-5 text-green-600 dark:text-green-400" />
              ) : (
                <Sparkles className="h-5 w-5 text-primary" />
              )}
            </div>

            {/* Text */}
            <div>
              <div className="flex items-center gap-2">
                <p className="font-semibold text-foreground">Daily Adkhar</p>
                {activeJourney && (
                  <span className="text-xs text-muted-foreground">
                    {activeJourney.emoji}
                  </span>
                )}
              </div>
              <p className="text-sm text-muted-foreground">
                {allCompleted ? (
                  <span className="text-green-600 dark:text-green-400">
                    All {progress.total} completed!
                  </span>
                ) : (
                  <>
                    {progress.completed}/{progress.total} completed •{" "}
                    {progress.earnedXp} XP
                  </>
                )}
              </p>
            </div>
          </div>

          {/* Arrow */}
          <ChevronRight
            className={cn(
              "h-5 w-5",
              allCompleted
                ? "text-green-500"
                : "text-muted-foreground"
            )}
          />
        </div>

        {/* Progress bar */}
        <div className="mt-3 h-2 overflow-hidden rounded-full bg-muted">
          <div
            className={cn(
              "h-full rounded-full transition-all duration-500",
              allCompleted ? "bg-green-500" : "bg-primary"
            )}
            style={{ width: `${progress.percentage}%` }}
          />
        </div>
      </div>
    </Card>
  );
}
