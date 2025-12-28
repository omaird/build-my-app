import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion";
import { Settings, BookOpen, Compass, Sparkles, CheckCircle2, Loader2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { BottomNav } from "@/components/BottomNav";
import { useUserHabits } from "@/hooks/useUserHabits";
import { useToast } from "@/hooks/use-toast";
import { HabitTimeSlotSection } from "@/components/habits/HabitTimeSlotSection";
import { HabitProgressBar } from "@/components/habits/HabitProgressBar";
import { QuickPracticeSheet } from "@/components/habits/QuickPracticeSheet";
import { CelebrationParticles } from "@/components/animations";
import type { HabitWithDua } from "@/types/habit";
import { cn } from "@/lib/utils";

const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.08,
      delayChildren: 0.1,
    },
  },
};

const itemVariants = {
  hidden: { opacity: 0, y: 20 },
  visible: {
    opacity: 1,
    y: 0,
    transition: { duration: 0.4, ease: [0.25, 0.46, 0.45, 0.94] },
  },
};

export default function DailyAdkharPage() {
  const navigate = useNavigate();
  const {
    hasHabits,
    groupedHabits,
    progress,
    activeJourney,
    isLoading,
    nextUncompletedHabit,
    removeCustomHabit,
    todaysHabits,
  } = useUserHabits();
  const { toast } = useToast();

  const [selectedHabit, setSelectedHabit] = useState<HabitWithDua | null>(null);
  const [practiceOpen, setPracticeOpen] = useState(false);

  const handleHabitClick = (habit: HabitWithDua) => {
    setSelectedHabit(habit);
    setPracticeOpen(true);
  };

  const handleHabitRemove = (habitId: string) => {
    const habit = todaysHabits.find((h) => h.id === habitId);
    removeCustomHabit(habitId);
    toast({
      title: "Habit removed",
      description: habit
        ? `"${habit.dua.title}" has been removed from your practice.`
        : "Habit has been removed from your practice.",
    });
  };

  const handlePracticeComplete = () => {
    // Auto-advance to next uncompleted habit
    if (nextUncompletedHabit && nextUncompletedHabit.id !== selectedHabit?.id) {
      setSelectedHabit(nextUncompletedHabit);
    }
  };

  const allCompleted = progress.completed === progress.total && progress.total > 0;

  // Loading state
  if (isLoading) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-background">
        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          className="flex flex-col items-center gap-4"
        >
          <div className="relative">
            <Loader2 className="h-10 w-10 animate-spin text-primary" />
            <div className="absolute inset-0 rounded-full bg-primary/20 blur-xl animate-pulse" />
          </div>
          <p className="text-sm text-muted-foreground">Loading your adkhar...</p>
        </motion.div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background pb-24">
      {/* Background pattern */}
      <div className="fixed inset-0 islamic-pattern opacity-30 pointer-events-none" />

      {/* Gradient overlay at top */}
      <div className="fixed top-0 left-0 right-0 h-32 gradient-fade-down pointer-events-none z-10" />

      <motion.div
        className="relative mx-auto max-w-md px-4 pt-6"
        variants={containerVariants}
        initial="hidden"
        animate="visible"
      >
        {/* Header */}
        <motion.header
          className="mb-6 flex items-center justify-between"
          variants={itemVariants}
        >
          <div>
            <h1 className="font-display text-2xl font-bold text-foreground">
              Daily Adkhar
            </h1>
            {activeJourney && (
              <motion.div
                className="mt-1 flex items-center gap-1.5 text-sm text-muted-foreground"
                initial={{ opacity: 0, x: -10 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: 0.3 }}
              >
                <span className="text-base">{activeJourney.emoji}</span>
                <span>{activeJourney.name}</span>
              </motion.div>
            )}
          </div>
          <motion.div whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }}>
            <Button
              variant="ghost"
              size="icon"
              className="rounded-full hover:bg-secondary"
              onClick={() => navigate("/settings")}
            >
              <Settings className="h-5 w-5" />
            </Button>
          </motion.div>
        </motion.header>

        {/* Empty State */}
        <AnimatePresence mode="wait">
          {!hasHabits && (
            <motion.div
              key="empty"
              className="mt-12 flex flex-col items-center justify-center text-center"
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              transition={{ duration: 0.3 }}
            >
              {/* Decorative element */}
              <div className="relative mb-6">
                <motion.div
                  className="absolute -inset-6 rounded-full bg-primary/10 blur-2xl"
                  animate={{ scale: [1, 1.1, 1], opacity: [0.5, 0.7, 0.5] }}
                  transition={{ duration: 3, repeat: Infinity }}
                />
                <motion.div
                  className="relative flex h-24 w-24 items-center justify-center rounded-full border-2 border-dashed border-primary/30 bg-card shadow-soft"
                  animate={{ rotate: [0, 5, -5, 0] }}
                  transition={{ duration: 4, repeat: Infinity }}
                >
                  <BookOpen className="h-10 w-10 text-primary/60" />
                </motion.div>
              </div>

              <h2 className="font-display text-xl font-semibold text-foreground">
                No Daily Adkhar Yet
              </h2>
              <p className="mt-2 max-w-xs text-sm text-muted-foreground">
                Start a journey or add duas from the library to build your daily
                spiritual routine.
              </p>

              <motion.div
                className="mt-8 flex w-full flex-col gap-3"
                variants={containerVariants}
                initial="hidden"
                animate="visible"
              >
                <motion.div variants={itemVariants}>
                  <Button
                    className="w-full gap-2 h-12 rounded-btn btn-gradient"
                    onClick={() => navigate("/journeys")}
                  >
                    <Compass className="h-4 w-4" />
                    Browse Journeys
                  </Button>
                </motion.div>
                <motion.div variants={itemVariants}>
                  <Button
                    variant="outline"
                    className="w-full gap-2 h-12 rounded-btn border-primary/20 hover:border-primary/40"
                    onClick={() => navigate("/library")}
                  >
                    <BookOpen className="h-4 w-4" />
                    Explore Library
                  </Button>
                </motion.div>
              </motion.div>
            </motion.div>
          )}
        </AnimatePresence>

        {/* Has Habits */}
        <AnimatePresence mode="wait">
          {hasHabits && (
            <motion.div
              key="habits"
              className="space-y-6"
              variants={containerVariants}
              initial="hidden"
              animate="visible"
              exit={{ opacity: 0 }}
            >
              {/* All Completed Celebration */}
              <AnimatePresence>
                {allCompleted && (
                  <motion.div
                    initial={{ opacity: 0, scale: 0.9, y: -20 }}
                    animate={{ opacity: 1, scale: 1, y: 0 }}
                    exit={{ opacity: 0, scale: 0.9, y: -20 }}
                    transition={{ type: "spring", stiffness: 300, damping: 25 }}
                    className={cn(
                      "relative overflow-hidden rounded-islamic p-6 text-center",
                      "bg-gradient-to-br from-primary/20 via-primary/10 to-gold-soft/10",
                      "border-2 border-primary/30 shadow-glow-primary"
                    )}
                  >
                    {/* Pattern overlay */}
                    <div className="absolute inset-0 islamic-pattern-dense opacity-30 pointer-events-none" />

                    {/* Celebration particles */}
                    <CelebrationParticles count={8} />

                    {/* Decorative sparkles */}
                    <motion.div
                      className="absolute right-4 top-4"
                      animate={{ rotate: [0, 15, -15, 0], scale: [1, 1.1, 1] }}
                      transition={{ duration: 2, repeat: Infinity }}
                    >
                      <Sparkles className="h-5 w-5 text-primary/60" />
                    </motion.div>
                    <motion.div
                      className="absolute bottom-4 left-4"
                      animate={{ rotate: [0, -15, 15, 0], scale: [1, 1.1, 1] }}
                      transition={{ duration: 2.5, repeat: Infinity, delay: 0.5 }}
                    >
                      <Sparkles className="h-4 w-4 text-gold-soft/60" />
                    </motion.div>

                    <motion.div
                      className="relative mb-3 flex justify-center"
                      initial={{ scale: 0 }}
                      animate={{ scale: 1 }}
                      transition={{ type: "spring", delay: 0.2 }}
                    >
                      <div className="flex h-16 w-16 items-center justify-center rounded-full gradient-primary shadow-glow-primary">
                        <motion.div
                          initial={{ scale: 0, rotate: -180 }}
                          animate={{ scale: 1, rotate: 0 }}
                          transition={{ delay: 0.4, type: "spring" }}
                        >
                          <CheckCircle2 className="h-8 w-8 text-primary-foreground" />
                        </motion.div>
                      </div>
                    </motion.div>

                    <motion.h3
                      className="font-display text-xl font-bold text-foreground"
                      initial={{ opacity: 0, y: 10 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={{ delay: 0.3 }}
                    >
                      Masha'Allah!
                    </motion.h3>
                    <motion.p
                      className="mt-1 text-sm text-muted-foreground"
                      initial={{ opacity: 0 }}
                      animate={{ opacity: 1 }}
                      transition={{ delay: 0.4 }}
                    >
                      You've completed all {progress.total} adkhar today
                    </motion.p>
                    <motion.div
                      className="mt-4 inline-flex items-center gap-2 rounded-full bg-gold-soft/20 border border-gold-soft/30 px-4 py-2 text-sm font-semibold text-primary"
                      initial={{ opacity: 0, scale: 0.8 }}
                      animate={{ opacity: 1, scale: 1 }}
                      transition={{ delay: 0.5 }}
                    >
                      <Sparkles className="h-4 w-4" />
                      +{progress.earnedXp} XP earned
                    </motion.div>
                  </motion.div>
                )}
              </AnimatePresence>

              {/* Progress Bar */}
              <AnimatePresence>
                {!allCompleted && (
                  <motion.div variants={itemVariants}>
                    <HabitProgressBar progress={progress} />
                  </motion.div>
                )}
              </AnimatePresence>

              {/* Time Slot Sections */}
              <motion.div className="space-y-4" variants={itemVariants}>
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
              </motion.div>

              {/* Add More CTA */}
              <motion.div className="pt-2" variants={itemVariants}>
                <motion.div whileHover={{ y: -2 }} whileTap={{ scale: 0.98 }}>
                  <Button
                    variant="ghost"
                    className="w-full gap-2 text-muted-foreground hover:text-foreground hover:bg-secondary/50 h-11 rounded-btn"
                    onClick={() => navigate("/library")}
                  >
                    <BookOpen className="h-4 w-4" />
                    Add more from Library
                  </Button>
                </motion.div>
              </motion.div>
            </motion.div>
          )}
        </AnimatePresence>
      </motion.div>

      {/* Quick Practice Sheet */}
      <QuickPracticeSheet
        habit={selectedHabit}
        open={practiceOpen}
        onOpenChange={setPracticeOpen}
        onComplete={handlePracticeComplete}
        nextHabit={nextUncompletedHabit}
        onNext={(habit) => setSelectedHabit(habit)}
      />

      <BottomNav />
    </div>
  );
}
