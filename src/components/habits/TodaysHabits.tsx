import { useState } from "react";
import { Link } from "react-router-dom";
import { Settings, ArrowRight, Sparkles, CheckCircle2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { HabitProgressBar } from "./HabitProgressBar";
import { HabitTimeSlotSection } from "./HabitTimeSlotSection";
import { HabitPreviewSheet } from "./HabitPreviewSheet";
import { EmptyHabitsState } from "./EmptyHabitsState";
import { useUserHabits } from "@/hooks/useUserHabits";
import { useToast } from "@/hooks/use-toast";
import { JourneyIcon } from "@/components/journeys/JourneyIcon";
import type { HabitWithDua } from "@/types/habit";

export function TodaysHabits() {
  const {
    hasHabits,
    groupedHabits,
    progress,
    nextUncompletedHabit,
    activeJourneys,
    isLoading,
    removeCustomHabit,
    todaysHabits,
  } = useUserHabits();
  const { toast } = useToast();

  const [selectedHabit, setSelectedHabit] = useState<HabitWithDua | null>(null);
  const [sheetOpen, setSheetOpen] = useState(false);

  const handleHabitClick = (habit: HabitWithDua) => {
    setSelectedHabit(habit);
    setSheetOpen(true);
  };

  const handleHabitRemove = (habitId: string) => {
    // Find the habit to get its name for the toast
    const habit = todaysHabits.find((h) => h.id === habitId);
    removeCustomHabit(habitId);
    toast({
      title: "Habit removed",
      description: habit
        ? `"${habit.dua.title}" has been removed from your practice.`
        : "Habit has been removed from your practice.",
    });
  };

  // Loading state
  if (isLoading) {
    return (
      <div className="space-y-4">
        <div className="h-8 w-32 animate-pulse rounded bg-muted" />
        <div className="h-24 animate-pulse rounded-lg bg-muted" />
        <div className="h-48 animate-pulse rounded-lg bg-muted" />
      </div>
    );
  }

  // No habits configured - show empty state with Quick Start
  if (!hasHabits) {
    return <EmptyHabitsState />;
  }

  const allCompleted = progress.completed === progress.total && progress.total > 0;

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-lg font-semibold text-foreground">
            Today's Habits
          </h2>
          {activeJourneys.length > 0 && (
            <p className="text-xs text-muted-foreground flex items-center gap-1">
              {activeJourneys.length === 1 ? (
                <>
                  <JourneyIcon emoji={activeJourneys[0].emoji} name={activeJourneys[0].name} size="sm" />
                  <span>{activeJourneys[0].name}</span>
                </>
              ) : (
                <>
                  {activeJourneys.map((j) => (
                    <JourneyIcon key={j.id} emoji={j.emoji} name={j.name} size="sm" />
                  ))}
                  <span>{activeJourneys.length} journeys</span>
                </>
              )}
            </p>
          )}
        </div>
        <Link to="/settings/habits">
          <Button variant="ghost" size="icon" className="h-8 w-8">
            <Settings className="h-4 w-4" />
            <span className="sr-only">Manage habits</span>
          </Button>
        </Link>
      </div>

      {/* Progress bar */}
      <HabitProgressBar progress={progress} />

      {/* All completed celebration */}
      {allCompleted && (
        <div className="flex items-center gap-2 rounded-lg bg-primary/10 p-3 text-primary">
          <CheckCircle2 className="h-5 w-5" />
          <span className="text-sm font-medium">
            Mashallah! All duas completed for today!
          </span>
        </div>
      )}

      {/* Time slot sections */}
      <div className="space-y-4">
        <HabitTimeSlotSection
          timeSlot="morning"
          habits={groupedHabits.morning}
          onHabitClick={handleHabitClick}
          onHabitRemove={handleHabitRemove}
        />
        <HabitTimeSlotSection
          timeSlot="anytime"
          habits={groupedHabits.anytime}
          onHabitClick={handleHabitClick}
          onHabitRemove={handleHabitRemove}
        />
        <HabitTimeSlotSection
          timeSlot="evening"
          habits={groupedHabits.evening}
          onHabitClick={handleHabitClick}
          onHabitRemove={handleHabitRemove}
        />
      </div>

      {/* Continue Practice button */}
      {nextUncompletedHabit && (
        <Button
          onClick={() => handleHabitClick(nextUncompletedHabit)}
          className="w-full gap-2"
          size="lg"
        >
          <Sparkles className="h-4 w-4" />
          Continue Practice
          <ArrowRight className="h-4 w-4" />
        </Button>
      )}

      {/* Habit preview sheet */}
      <HabitPreviewSheet
        habit={selectedHabit}
        open={sheetOpen}
        onOpenChange={setSheetOpen}
      />
    </div>
  );
}
