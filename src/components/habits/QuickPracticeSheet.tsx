import { useState, useCallback, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Check, RotateCcw, Eye, EyeOff, ChevronRight, Sparkles } from "lucide-react";
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet";
import { Button } from "@/components/ui/button";
import { useDailyActivity, useUserProgress } from "@/hooks/useActivity";
import { useUserHabits } from "@/hooks/useUserHabits";
import { useToast } from "@/hooks/use-toast";
import { cn } from "@/lib/utils";
import { RippleEffect } from "@/components/animations/RippleEffect";
import { CelebrationParticles } from "@/components/animations/CelebrationParticles";
import { AnimatedCheckmark } from "@/components/animations/AnimatedCheckmark";
import { PracticeContextTabs } from "@/components/dua/PracticeContextTabs";
import { DuaContextView } from "@/components/dua/DuaContextView";
import { hasContext } from "@/types/dua";
import type { HabitWithDua } from "@/types/habit";

interface QuickPracticeSheetProps {
  habit: HabitWithDua | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onComplete?: () => void;
  nextHabit?: HabitWithDua | null;
  onNext?: (habit: HabitWithDua) => void;
}

export function QuickPracticeSheet({
  habit,
  open,
  onOpenChange,
  onComplete,
  nextHabit,
  onNext,
}: QuickPracticeSheetProps) {
  const { toast } = useToast();
  const { markDuaCompleted: markActivityCompleted } = useDailyActivity();
  const { markDuaCompleted: markProgressCompleted } = useUserProgress();
  const { markHabitCompleted } = useUserHabits();

  const [tapCount, setTapCount] = useState(0);
  const [isCompleted, setIsCompleted] = useState(false);
  const [showTransliteration, setShowTransliteration] = useState(true);
  const [showCelebration, setShowCelebration] = useState(false);
  const [activeTab, setActiveTab] = useState<'practice' | 'context'>('practice');

  // Reset state when habit changes or sheet opens
  useEffect(() => {
    if (habit && open) {
      setTapCount(0);
      setIsCompleted(false);
      setShowCelebration(false);
      setActiveTab('practice');
    }
  }, [habit?.id, open]);

  const handleTap = useCallback(() => {
    if (!habit || isCompleted || habit.isCompletedToday) return;

    const newCount = tapCount + 1;
    setTapCount(newCount);

    // Check if completed
    if (newCount >= habit.dua.repetitions) {
      setIsCompleted(true);
      setShowCelebration(true);

      // Mark completed in all tracking systems
      markActivityCompleted(habit.dua.id, habit.dua.xpValue);
      markProgressCompleted(habit.dua.id);
      markHabitCompleted(habit.dua.id);

      // Show toast
      toast({
        title: "Completed! ✨",
        description: `+${habit.dua.xpValue} XP earned`,
      });

      // Trigger callback
      onComplete?.();

      // Hide celebration after animation
      setTimeout(() => setShowCelebration(false), 3000);
    }
  }, [
    habit,
    tapCount,
    isCompleted,
    markActivityCompleted,
    markProgressCompleted,
    markHabitCompleted,
    toast,
    onComplete,
  ]);

  const handleReset = () => {
    setTapCount(0);
    setIsCompleted(false);
  };

  const handleNext = () => {
    if (nextHabit && onNext) {
      onNext(nextHabit);
    }
  };

  if (!habit) return null;

  const { dua } = habit;
  const progress = Math.min((tapCount / dua.repetitions) * 100, 100);
  const isAlreadyCompleted = habit.isCompletedToday;
  const showCompleted = isCompleted || isAlreadyCompleted;
  const duaHasContext = hasContext(dua);

  return (
    <Sheet open={open} onOpenChange={onOpenChange}>
      <SheetContent
        side="bottom"
        className={cn(
          "h-[90vh] rounded-t-[24px] border-t-2 border-primary/20",
          "bg-gradient-to-b from-card to-background"
        )}
      >
        {/* Islamic pattern overlay */}
        <div className="absolute inset-0 islamic-pattern opacity-20 pointer-events-none rounded-t-[24px]" />

        {/* Celebration overlay */}
        <AnimatePresence>
          {showCelebration && (
            <motion.div
              className="absolute inset-0 z-50 flex items-center justify-center pointer-events-none"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
            >
              <CelebrationParticles count={16} />
              <motion.div
                className="flex flex-col items-center gap-3"
                initial={{ scale: 0, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                transition={{ type: "spring", delay: 0.2 }}
              >
                <div className="flex h-20 w-20 items-center justify-center rounded-full gradient-primary shadow-glow-primary">
                  <AnimatedCheckmark size={48} />
                </div>
                <motion.span
                  className="font-display text-xl font-bold text-foreground"
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.4 }}
                >
                  Masha'Allah!
                </motion.span>
              </motion.div>
            </motion.div>
          )}
        </AnimatePresence>

        <div className="relative flex h-full flex-col">
          {/* Header */}
          <SheetHeader className="pb-4 pt-2">
            <div className="flex items-center justify-between">
              <SheetTitle className="font-display text-lg font-semibold">
                {dua.title}
              </SheetTitle>
              <motion.div whileHover={{ scale: 1.1 }} whileTap={{ scale: 0.9 }}>
                <Button
                  variant="ghost"
                  size="icon"
                  className="h-9 w-9 rounded-full"
                  onClick={() => setShowTransliteration(!showTransliteration)}
                >
                  {showTransliteration ? (
                    <Eye className="h-4 w-4" />
                  ) : (
                    <EyeOff className="h-4 w-4" />
                  )}
                </Button>
              </motion.div>
            </div>

            {/* Progress bar */}
            <div className="mt-3 h-2 w-full overflow-hidden rounded-full bg-secondary/70 shadow-inner-glow">
              <motion.div
                className={cn(
                  "h-full rounded-full",
                  showCompleted ? "bg-primary" : "gradient-primary"
                )}
                initial={{ width: 0 }}
                animate={{ width: `${showCompleted ? 100 : progress}%` }}
                transition={{ duration: 0.3 }}
              />
            </div>

            {/* Practice/Context Tabs */}
            <div className="mt-4">
              <PracticeContextTabs
                value={activeTab}
                onValueChange={setActiveTab}
                hasContext={duaHasContext}
              />
            </div>
          </SheetHeader>

          {/* Scrollable content */}
          <div className="flex-1 overflow-y-auto px-1">
            <AnimatePresence mode="wait">
              {activeTab === 'practice' ? (
                <motion.div
                  key="practice"
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  exit={{ opacity: 0, x: 20 }}
                  transition={{ duration: 0.2 }}
                >
                  {/* Tappable Arabic Text Area */}
            <RippleEffect
              className={cn(
                "rounded-islamic overflow-hidden cursor-pointer select-none",
                "bg-card/50 border-2 shadow-soft transition-all duration-200",
                showCompleted
                  ? "border-primary/30"
                  : "border-primary/10 active:scale-[0.99]"
              )}
              onClick={handleTap}
              disabled={showCompleted}
            >
              {/* Corner ornament */}
              <div className="corner-ornament" />

              <motion.div
                className="relative px-4 py-8 text-center"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ delay: 0.2 }}
              >
                <p
                  className="text-3xl leading-[2.5] text-arabic text-foreground font-medium tracking-wide"
                  dir="rtl"
                >
                  {dua.arabic}
                </p>
              </motion.div>
            </RippleEffect>

            {/* Transliteration */}
            <AnimatePresence>
              {showTransliteration && dua.transliteration && (
                <motion.p
                  className="mt-4 text-center text-lg italic text-muted-foreground"
                  initial={{ opacity: 0, height: 0 }}
                  animate={{ opacity: 1, height: "auto" }}
                  exit={{ opacity: 0, height: 0 }}
                  transition={{ duration: 0.2 }}
                >
                  {dua.transliteration}
                </motion.p>
              )}
            </AnimatePresence>

            {/* Divider */}
            <div className="islamic-divider my-4">
              <span className="text-primary/40">✦</span>
            </div>

            {/* Translation */}
            <motion.p
              className="text-center text-sm text-foreground/80 leading-relaxed"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.3 }}
            >
              "{dua.translation}"
            </motion.p>

            {/* Tap Counter Area */}
            <RippleEffect
              className="mt-8 flex flex-col items-center justify-center cursor-pointer select-none"
              onClick={handleTap}
              disabled={showCompleted}
            >
              {/* Counter Circle */}
              <motion.div
                className={cn(
                  "relative flex h-32 w-32 items-center justify-center rounded-full",
                  "border-4 transition-all duration-300",
                  showCompleted
                    ? "border-primary bg-primary/10 shadow-glow-primary"
                    : "border-primary/30 bg-card hover:border-primary/50"
                )}
                whileHover={!showCompleted ? { scale: 1.05 } : {}}
                whileTap={!showCompleted ? { scale: 0.95 } : {}}
              >
                {/* Progress ring */}
                <svg
                  className="absolute inset-0 -rotate-90"
                  viewBox="0 0 128 128"
                >
                  <circle
                    cx="64"
                    cy="64"
                    r="58"
                    fill="none"
                    strokeWidth="4"
                    className="stroke-secondary"
                  />
                  <motion.circle
                    cx="64"
                    cy="64"
                    r="58"
                    fill="none"
                    strokeWidth="4"
                    className={cn(
                      "transition-all duration-300",
                      showCompleted ? "stroke-primary" : "stroke-primary"
                    )}
                    strokeDasharray={364}
                    strokeDashoffset={364 - (progress / 100) * 364}
                    strokeLinecap="round"
                    initial={{ strokeDashoffset: 364 }}
                    animate={{ strokeDashoffset: 364 - (progress / 100) * 364 }}
                    transition={{ duration: 0.3 }}
                  />
                </svg>

                {/* Counter content */}
                {showCompleted ? (
                  <motion.div
                    initial={{ scale: 0 }}
                    animate={{ scale: 1 }}
                    transition={{ type: "spring", stiffness: 300 }}
                  >
                    <Check className="h-14 w-14 text-primary" />
                  </motion.div>
                ) : (
                  <div className="text-center">
                    <motion.span
                      className="text-5xl font-bold text-primary font-mono"
                      key={tapCount}
                      initial={{ scale: 1.3, opacity: 0.5 }}
                      animate={{ scale: 1, opacity: 1 }}
                      transition={{ type: "spring", stiffness: 400, damping: 15 }}
                    >
                      {tapCount}
                    </motion.span>
                    <span className="text-lg text-muted-foreground">
                      /{dua.repetitions}
                    </span>
                  </div>
                )}
              </motion.div>

              {/* Status text */}
              <motion.p
                className="mt-4 text-sm text-muted-foreground"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ delay: 0.4 }}
              >
                {showCompleted
                  ? isAlreadyCompleted
                    ? "Completed today"
                    : "Completed!"
                  : "Tap anywhere to count"}
              </motion.p>

              {/* XP badge */}
                    {!showCompleted && (
                      <motion.div
                        className="mt-3 inline-flex items-center gap-1.5 rounded-full bg-gold-soft/20 border border-gold-soft/30 px-3 py-1.5 text-sm font-medium text-primary"
                        initial={{ opacity: 0, scale: 0.8 }}
                        animate={{ opacity: 1, scale: 1 }}
                        transition={{ delay: 0.5 }}
                      >
                        <Sparkles className="h-3.5 w-3.5" />
                        +{dua.xpValue} XP
                      </motion.div>
                    )}
                  </RippleEffect>
                </motion.div>
              ) : (
                <motion.div
                  key="context"
                  initial={{ opacity: 0, x: 20 }}
                  animate={{ opacity: 1, x: 0 }}
                  exit={{ opacity: 0, x: -20 }}
                  transition={{ duration: 0.2 }}
                  className="py-4"
                >
                  <DuaContextView context={dua.context} />
                </motion.div>
              )}
            </AnimatePresence>
          </div>

          {/* Action buttons */}
          <motion.div
            className="mt-auto space-y-3 pb-6 pt-4"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.3 }}
          >
            {/* Next habit button (shown after completion) */}
            <AnimatePresence>
              {showCompleted && nextHabit && nextHabit.id !== habit.id && (
                <motion.div
                  initial={{ opacity: 0, height: 0 }}
                  animate={{ opacity: 1, height: "auto" }}
                  exit={{ opacity: 0, height: 0 }}
                >
                  <Button
                    className="w-full gap-2 h-12 rounded-btn btn-gradient"
                    onClick={handleNext}
                  >
                    Next: {nextHabit.dua.title}
                    <ChevronRight className="h-4 w-4" />
                  </Button>
                </motion.div>
              )}
            </AnimatePresence>

            {/* Reset and close buttons */}
            <div className="flex gap-3">
              {!showCompleted && (
                <motion.div className="flex-1" whileTap={{ scale: 0.98 }}>
                  <Button
                    variant="outline"
                    className="w-full gap-2 h-12 rounded-btn"
                    onClick={handleReset}
                    disabled={tapCount === 0}
                  >
                    <RotateCcw className="h-4 w-4" />
                    Reset
                  </Button>
                </motion.div>
              )}
              <motion.div
                className="flex-1"
                whileTap={{ scale: 0.98 }}
              >
                <Button
                  variant={showCompleted ? "default" : "outline"}
                  className={cn(
                    "w-full h-12 rounded-btn",
                    showCompleted && "btn-gradient"
                  )}
                  onClick={() => onOpenChange(false)}
                >
                  {showCompleted ? "Done" : "Close"}
                </Button>
              </motion.div>
            </div>
          </motion.div>
        </div>
      </SheetContent>
    </Sheet>
  );
}
