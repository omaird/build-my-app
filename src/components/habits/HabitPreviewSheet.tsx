import { useNavigate } from "react-router-dom";
import { Book, RotateCcw, Clock, Sparkles } from "lucide-react";
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import type { HabitWithDua } from "@/types/habit";

interface HabitPreviewSheetProps {
  habit: HabitWithDua | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function HabitPreviewSheet({
  habit,
  open,
  onOpenChange,
}: HabitPreviewSheetProps) {
  const navigate = useNavigate();

  if (!habit) return null;

  const { dua, isCompletedToday } = habit;

  const handleStartPractice = () => {
    onOpenChange(false);
    navigate(`/practice/${dua.id}`);
  };

  return (
    <Sheet open={open} onOpenChange={onOpenChange}>
      <SheetContent side="bottom" className="rounded-t-2xl">
        <SheetHeader className="text-left">
          <SheetTitle className="text-lg">{dua.title}</SheetTitle>
        </SheetHeader>

        <div className="mt-4 space-y-4">
          {/* Arabic text */}
          <div className="rounded-lg bg-muted/50 p-4 text-center">
            <p
              className="font-arabic text-xl leading-loose text-foreground"
              dir="rtl"
            >
              {dua.arabic}
            </p>
          </div>

          {/* Translation */}
          <p className="text-sm italic text-muted-foreground">
            "{dua.translation}"
          </p>

          {/* Metadata */}
          <div className="flex flex-wrap gap-2">
            <Badge variant="secondary" className="gap-1">
              <RotateCcw className="h-3 w-3" />
              {dua.repetitions}x
            </Badge>
            <Badge variant="secondary" className="gap-1">
              <Clock className="h-3 w-3" />
              ~{Math.ceil(dua.repetitions * 5)}s
            </Badge>
            <Badge variant="secondary" className="gap-1">
              <Sparkles className="h-3 w-3" />
              {dua.xpValue} XP
            </Badge>
            <Badge variant="outline" className="capitalize">
              <Book className="mr-1 h-3 w-3" />
              {dua.category}
            </Badge>
          </div>

          {/* Action button */}
          <Button
            onClick={handleStartPractice}
            className="w-full gap-2"
            size="lg"
            disabled={isCompletedToday}
          >
            {isCompletedToday ? (
              "Already Completed Today"
            ) : (
              <>
                <Sparkles className="h-4 w-4" />
                Start Practice
              </>
            )}
          </Button>
        </div>
      </SheetContent>
    </Sheet>
  );
}
