import { useState, useCallback, useEffect } from "react";
import { useParams, useNavigate, useSearchParams } from "react-router-dom";
import { ArrowLeft, RotateCcw, Eye, EyeOff, Check, Sparkles } from "lucide-react";
import { BottomNav } from "@/components/BottomNav";
import { duaLibrary } from "@/data/duaLibrary";
import { useUserProfile, useDailyActivity, useUserProgress } from "@/hooks/useUserData";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { cn } from "@/lib/utils";
import { useToast } from "@/hooks/use-toast";

export default function PracticePage() {
  const { duaId } = useParams();
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const { toast } = useToast();
  
  const { addXp } = useUserProfile();
  const { markDuaCompleted: markActivityCompleted } = useDailyActivity();
  const { markDuaCompleted: markProgressCompleted, hasCompletedToday } = useUserProgress();

  const [currentDuaIndex, setCurrentDuaIndex] = useState(0);
  const [tapCount, setTapCount] = useState(0);
  const [showTransliteration, setShowTransliteration] = useState(true);
  const [isCompleted, setIsCompleted] = useState(false);
  const [isAnimating, setIsAnimating] = useState(false);

  // Get filtered duas based on category or specific dua
  const filteredDuas = duaId
    ? duaLibrary.filter((d) => d.id === duaId)
    : searchParams.get("category")
    ? duaLibrary.filter((d) => d.category === searchParams.get("category"))
    : duaLibrary;

  const currentDua = filteredDuas[currentDuaIndex];
  const alreadyCompletedToday = currentDua ? hasCompletedToday(currentDua.id) : false;

  useEffect(() => {
    // Reset state when dua changes
    setTapCount(0);
    setIsCompleted(false);
  }, [currentDuaIndex, duaId]);

  const handleTap = useCallback(() => {
    if (!currentDua || isCompleted || alreadyCompletedToday) return;

    setIsAnimating(true);
    setTimeout(() => setIsAnimating(false), 150);

    const newCount = tapCount + 1;
    setTapCount(newCount);

    if (newCount >= currentDua.repetitions) {
      // Dua completed!
      setIsCompleted(true);
      addXp(currentDua.xpValue);
      markActivityCompleted(currentDua.id, currentDua.xpValue);
      markProgressCompleted(currentDua.id);

      toast({
        title: "Dua Completed! ✨",
        description: `You earned +${currentDua.xpValue} XP`,
      });
    }
  }, [currentDua, tapCount, isCompleted, alreadyCompletedToday, addXp, markActivityCompleted, markProgressCompleted, toast]);

  const handleReset = () => {
    setTapCount(0);
    setIsCompleted(false);
  };

  const handleNext = () => {
    if (currentDuaIndex < filteredDuas.length - 1) {
      setCurrentDuaIndex(currentDuaIndex + 1);
    } else {
      navigate("/library");
    }
  };

  if (!currentDua) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-background">
        <div className="text-center">
          <p className="text-muted-foreground">Dua not found</p>
          <Button variant="link" onClick={() => navigate("/library")}>
            Go to Library
          </Button>
        </div>
      </div>
    );
  }

  const progress = Math.min((tapCount / currentDua.repetitions) * 100, 100);

  return (
    <div className="min-h-screen bg-background pb-20">
      <div className="mx-auto max-w-md px-4 pt-4">
        {/* Header */}
        <header className="mb-6 flex items-center justify-between">
          <Button variant="ghost" size="icon" onClick={() => navigate(-1)}>
            <ArrowLeft className="h-5 w-5" />
          </Button>
          <div className="text-center">
            <h1 className="text-lg font-semibold">{currentDua.title}</h1>
            {filteredDuas.length > 1 && (
              <p className="text-xs text-muted-foreground">
                {currentDuaIndex + 1} of {filteredDuas.length}
              </p>
            )}
          </div>
          <Button
            variant="ghost"
            size="icon"
            onClick={() => setShowTransliteration(!showTransliteration)}
          >
            {showTransliteration ? <Eye className="h-5 w-5" /> : <EyeOff className="h-5 w-5" />}
          </Button>
        </header>

        {/* Progress Bar */}
        <div className="mb-6">
          <div className="flex items-center justify-between text-sm">
            <span className="text-muted-foreground">Progress</span>
            <span className="font-medium">
              {tapCount} / {currentDua.repetitions}
            </span>
          </div>
          <div className="mt-2 h-2 w-full overflow-hidden rounded-full bg-secondary">
            <div
              className="h-full rounded-full bg-primary transition-all duration-300"
              style={{ width: `${progress}%` }}
            />
          </div>
        </div>

        {/* Dua Card - Tappable Area */}
        <Card
          className={cn(
            "cursor-pointer select-none transition-all duration-150",
            isAnimating && "scale-[0.98]",
            (isCompleted || alreadyCompletedToday) && "border-primary/30 bg-primary/5"
          )}
          onClick={handleTap}
        >
          <CardContent className="p-6 text-center">
            {/* Arabic Text */}
            <p className="mb-6 text-3xl leading-loose text-arabic text-foreground">
              {currentDua.arabic}
            </p>

            {/* Transliteration */}
            {showTransliteration && (
              <p className="mb-4 text-sm italic text-muted-foreground">
                {currentDua.transliteration}
              </p>
            )}

            {/* Translation */}
            <p className="text-sm text-foreground/80">{currentDua.translation}</p>

            {/* Tap Counter */}
            <div className="mt-8">
              {isCompleted || alreadyCompletedToday ? (
                <div className="flex flex-col items-center gap-2">
                  <div className="flex h-16 w-16 items-center justify-center rounded-full bg-primary">
                    <Check className="h-8 w-8 text-primary-foreground" />
                  </div>
                  <span className="text-sm font-medium text-primary">
                    {alreadyCompletedToday && !isCompleted ? "Completed Today" : "Completed!"}
                  </span>
                </div>
              ) : (
                <div className="flex flex-col items-center gap-2">
                  <div
                    className={cn(
                      "flex h-20 w-20 items-center justify-center rounded-full bg-primary/10 border-4 border-primary text-3xl font-bold text-primary transition-transform",
                      isAnimating && "animate-counter-pop"
                    )}
                  >
                    {tapCount}
                  </div>
                  <span className="text-xs text-muted-foreground">Tap anywhere to count</span>
                </div>
              )}
            </div>
          </CardContent>
        </Card>

        {/* Action Buttons */}
        <div className="mt-6 flex gap-3">
          {!isCompleted && !alreadyCompletedToday && (
            <Button variant="outline" className="flex-1 gap-2" onClick={handleReset}>
              <RotateCcw className="h-4 w-4" />
              Reset
            </Button>
          )}
          <Button
            className="flex-1 gap-2"
            onClick={handleNext}
            disabled={!isCompleted && !alreadyCompletedToday && filteredDuas.length === 1}
          >
            {currentDuaIndex < filteredDuas.length - 1 ? (
              <>
                Next Dua
                <Sparkles className="h-4 w-4" />
              </>
            ) : (
              "Done"
            )}
          </Button>
        </div>

        {/* XP Reward Badge */}
        <div className="mt-4 text-center text-sm text-muted-foreground">
          Complete to earn <span className="font-semibold text-primary">+{currentDua.xpValue} XP</span>
        </div>
      </div>

      <BottomNav />
    </div>
  );
}