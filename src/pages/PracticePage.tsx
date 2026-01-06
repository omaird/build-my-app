import { useState, useCallback, useEffect, useMemo } from "react";
import { useParams, useNavigate, useSearchParams } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion";
import { ArrowLeft, RotateCcw, Eye, EyeOff, Loader2, Sparkles, ChevronRight } from "lucide-react";
import { BottomNav } from "@/components/BottomNav";
import { useDuas } from "@/hooks/useDuas";
import { useDailyActivity, useUserProgress } from "@/hooks/useActivity";
import { useUserHabits } from "@/hooks/useUserHabits";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import { useToast } from "@/hooks/use-toast";
import { CelebrationOverlay } from "@/components/animations/CelebrationOverlay";
import { AnimatedCounter } from "@/components/animations/AnimatedCounter";
import { RippleEffect } from "@/components/animations/RippleEffect";
import { PracticeContextTabs } from "@/components/dua/PracticeContextTabs";
import { DuaContextView } from "@/components/dua/DuaContextView";
import { hasContext } from "@/types/dua";

export default function PracticePage() {
  const { duaId } = useParams();
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const { toast } = useToast();

  // Fetch duas from database
  const { data: allDuas = [], isLoading } = useDuas();

  const { markDuaCompleted: markActivityCompleted } = useDailyActivity();
  const { markDuaCompleted: markProgressCompleted, hasCompletedToday } = useUserProgress();
  const { markHabitCompleted } = useUserHabits();

  const [currentDuaIndex, setCurrentDuaIndex] = useState(0);
  const [tapCount, setTapCount] = useState(0);
  const [showTransliteration, setShowTransliteration] = useState(true);
  const [isCompleted, setIsCompleted] = useState(false);
  const [showCelebration, setShowCelebration] = useState(false);
  const [activeTab, setActiveTab] = useState<'practice' | 'context'>('practice');

  // Get filtered duas based on category or specific dua
  const filteredDuas = useMemo(() => {
    if (duaId) {
      return allDuas.filter((d) => d.id === duaId);
    }
    const category = searchParams.get("category");
    if (category) {
      return allDuas.filter((d) => d.category === category);
    }
    return allDuas;
  }, [allDuas, duaId, searchParams]);

  const currentDua = filteredDuas[currentDuaIndex];
  const alreadyCompletedToday = currentDua ? hasCompletedToday(currentDua.id) : false;

  useEffect(() => {
    // Reset state when dua changes
    setTapCount(0);
    setIsCompleted(false);
    setShowCelebration(false);
    setActiveTab('practice');
  }, [currentDuaIndex, duaId]);

  const handleTap = useCallback(() => {
    if (!currentDua || isCompleted || alreadyCompletedToday) return;

    const newCount = tapCount + 1;
    setTapCount(newCount);

    if (newCount >= currentDua.repetitions) {
      // Dua completed!
      setIsCompleted(true);
      setShowCelebration(true);
      markActivityCompleted(currentDua.id, currentDua.xpValue);
      markProgressCompleted(currentDua.id);
      markHabitCompleted(currentDua.id);
    }
  }, [currentDua, tapCount, isCompleted, alreadyCompletedToday, markActivityCompleted, markProgressCompleted, markHabitCompleted]);

  const handleReset = () => {
    setTapCount(0);
    setIsCompleted(false);
    setShowCelebration(false);
  };

  const handleNext = () => {
    if (currentDuaIndex < filteredDuas.length - 1) {
      setCurrentDuaIndex(currentDuaIndex + 1);
    } else {
      navigate("/library");
    }
  };

  const handleCelebrationDismiss = () => {
    setShowCelebration(false);
  };

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
          <p className="text-sm text-muted-foreground">Loading dua...</p>
        </motion.div>
      </div>
    );
  }

  if (!currentDua) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-background">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="text-center px-8"
        >
          <div className="mb-4 text-4xl">📿</div>
          <p className="text-muted-foreground mb-4">Dua not found</p>
          <Button variant="outline" onClick={() => navigate("/library")}>
            Go to Library
          </Button>
        </motion.div>
      </div>
    );
  }

  const progress = Math.min((tapCount / currentDua.repetitions) * 100, 100);
  const duaHasContext = hasContext(currentDua);

  return (
    <>
      <div className="min-h-screen bg-background pb-24">
        {/* Background pattern */}
        <div className="fixed inset-0 islamic-pattern opacity-30 pointer-events-none" />

        <motion.div
          className="relative mx-auto max-w-md px-4 pt-4"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 0.3 }}
        >
          {/* Header */}
          <motion.header
            className="mb-6 flex items-center justify-between"
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
          >
            <Button
              variant="ghost"
              size="icon"
              onClick={() => navigate(-1)}
              className="rounded-full hover:bg-secondary"
            >
              <ArrowLeft className="h-5 w-5" />
            </Button>
            <div className="text-center flex-1">
              <h1 className="font-display text-lg font-semibold truncate px-4">
                {currentDua.title}
              </h1>
              {filteredDuas.length > 1 && (
                <p className="text-xs text-muted-foreground mt-0.5">
                  {currentDuaIndex + 1} of {filteredDuas.length}
                </p>
              )}
            </div>
            <Button
              variant="ghost"
              size="icon"
              onClick={() => setShowTransliteration(!showTransliteration)}
              className="rounded-full hover:bg-secondary"
            >
              {showTransliteration ? (
                <Eye className="h-5 w-5" />
              ) : (
                <EyeOff className="h-5 w-5" />
              )}
            </Button>
          </motion.header>

          {/* Practice/Context Tabs */}
          <motion.div
            className="mb-6"
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.15 }}
          >
            <PracticeContextTabs
              value={activeTab}
              onValueChange={setActiveTab}
              hasContext={duaHasContext}
            />
          </motion.div>

          {/* Tab Content */}
          <AnimatePresence mode="wait">
            {activeTab === 'practice' ? (
              <motion.div
                key="practice"
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: 20 }}
                transition={{ duration: 0.2 }}
              >
                {/* Progress indicator */}
          <motion.div
            className="mb-6"
            initial={{ opacity: 0, scaleX: 0 }}
            animate={{ opacity: 1, scaleX: 1 }}
            transition={{ delay: 0.2 }}
          >
            <div className="flex items-center justify-between text-sm mb-2">
              <span className="text-muted-foreground text-xs font-medium uppercase tracking-wide">
                Progress
              </span>
              <span className="font-mono font-semibold text-primary">
                {tapCount} / {currentDua.repetitions}
              </span>
            </div>
            <div className="h-2 w-full overflow-hidden rounded-full bg-secondary/70 shadow-inner-glow">
              <motion.div
                className="h-full rounded-full gradient-primary"
                initial={{ width: 0 }}
                animate={{ width: `${progress}%` }}
                transition={{ duration: 0.3 }}
              />
            </div>
          </motion.div>

          {/* Dua Card - Tappable Area */}
          <RippleEffect
            className={cn(
              "rounded-islamic overflow-hidden cursor-pointer select-none",
              "bg-card border-2 shadow-elevated transition-all duration-200",
              isCompleted || alreadyCompletedToday
                ? "border-primary/30"
                : "border-primary/10 active:scale-[0.99]"
            )}
            onClick={handleTap}
            disabled={isCompleted || alreadyCompletedToday}
          >
            {/* Pattern overlay */}
            <div className="absolute inset-0 islamic-pattern-dense opacity-20 pointer-events-none" />

            {/* Corner ornaments */}
            <div className="corner-ornament" />

            <motion.div
              className="relative p-6 text-center"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.3 }}
            >
              {/* Arabic Text */}
              <motion.p
                className="mb-6 text-arabic text-3xl leading-[2] text-foreground"
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.4 }}
              >
                {currentDua.arabic}
              </motion.p>

              {/* Divider */}
              <div className="islamic-divider mb-4">
                <span className="text-primary/40">✦</span>
              </div>

              {/* Transliteration */}
              <AnimatePresence>
                {showTransliteration && (
                  <motion.p
                    className="mb-4 text-sm italic text-muted-foreground"
                    initial={{ opacity: 0, height: 0 }}
                    animate={{ opacity: 1, height: "auto" }}
                    exit={{ opacity: 0, height: 0 }}
                    transition={{ duration: 0.2 }}
                  >
                    {currentDua.transliteration}
                  </motion.p>
                )}
              </AnimatePresence>

              {/* Translation */}
              <motion.p
                className="text-sm text-foreground/80 leading-relaxed"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ delay: 0.5 }}
              >
                {currentDua.translation}
              </motion.p>

              {/* Counter Circle */}
              <div className="mt-8 flex flex-col items-center gap-4">
                {isCompleted || alreadyCompletedToday ? (
                  <motion.div
                    className="flex flex-col items-center gap-3"
                    initial={{ scale: 0 }}
                    animate={{ scale: 1 }}
                    transition={{ type: "spring", stiffness: 300, damping: 20 }}
                  >
                    <div className="flex h-20 w-20 items-center justify-center rounded-full gradient-primary shadow-glow-primary">
                      <motion.svg
                        width="36"
                        height="36"
                        viewBox="0 0 24 24"
                        fill="none"
                        className="text-white"
                      >
                        <motion.path
                          d="M5 13l4 4L19 7"
                          stroke="currentColor"
                          strokeWidth={3}
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          initial={{ pathLength: 0 }}
                          animate={{ pathLength: 1 }}
                          transition={{ duration: 0.4, delay: 0.2 }}
                        />
                      </motion.svg>
                    </div>
                    <span className="text-sm font-semibold text-primary">
                      {alreadyCompletedToday && !isCompleted
                        ? "Completed Today"
                        : "Completed!"}
                    </span>
                  </motion.div>
                ) : (
                  <>
                    <AnimatedCounter
                      value={tapCount}
                      max={currentDua.repetitions}
                      size="lg"
                      showProgress={false}
                    />
                    <span className="text-xs text-muted-foreground">
                      Tap anywhere to count
                    </span>
                  </>
                )}
              </div>
            </motion.div>
          </RippleEffect>

          {/* Action Buttons */}
          <motion.div
            className="mt-6 flex gap-3"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.6 }}
          >
            {!isCompleted && !alreadyCompletedToday && (
              <Button
                variant="outline"
                className="flex-1 gap-2 h-12 rounded-btn"
                onClick={handleReset}
              >
                <RotateCcw className="h-4 w-4" />
                Reset
              </Button>
            )}
            <Button
              className="flex-1 gap-2 h-12 rounded-btn btn-gradient"
              onClick={handleNext}
              disabled={
                !isCompleted && !alreadyCompletedToday && filteredDuas.length === 1
              }
            >
              {currentDuaIndex < filteredDuas.length - 1 ? (
                <>
                  Next Dua
                  <ChevronRight className="h-4 w-4" />
                </>
              ) : (
                "Done"
              )}
            </Button>
          </motion.div>

          {/* XP Reward Badge */}
                <motion.div
                  className="mt-6 flex justify-center"
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  transition={{ delay: 0.7 }}
                >
                  <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-secondary/50 text-sm">
                    <Sparkles className="h-4 w-4 text-primary" />
                    <span className="text-muted-foreground">Complete to earn</span>
                    <span className="font-mono font-bold text-primary">
                      +{currentDua.xpValue} XP
                    </span>
                  </div>
                </motion.div>
              </motion.div>
            ) : (
              <motion.div
                key="context"
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: -20 }}
                transition={{ duration: 0.2 }}
              >
                <DuaContextView context={currentDua.context} />
              </motion.div>
            )}
          </AnimatePresence>
        </motion.div>

        <BottomNav />
      </div>

      {/* Celebration Overlay */}
      <CelebrationOverlay
        isVisible={showCelebration}
        title="Masha'Allah!"
        subtitle="Dua completed"
        xpEarned={currentDua.xpValue}
        onDismiss={handleCelebrationDismiss}
      />
    </>
  );
}
