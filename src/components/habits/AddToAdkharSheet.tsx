import { useState, useEffect } from "react";
import { Sun, Clock, Moon, Check, Plus, Sparkles } from "lucide-react";
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
  SheetDescription,
} from "@/components/ui/sheet";
import { Button } from "@/components/ui/button";
import { useUserHabits } from "@/hooks/useUserHabits";
import { useToast } from "@/hooks/use-toast";
import { cn } from "@/lib/utils";
import type { Dua, DuaCategory } from "@/types/dua";
import type { TimeSlot } from "@/types/habit";

interface AddToAdkharSheetProps {
  dua: Dua | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

// Map DuaCategory to recommended TimeSlot
const getRecommendedTimeSlot = (category: DuaCategory): TimeSlot => {
  switch (category) {
    case "morning":
      return "morning";
    case "evening":
      return "evening";
    case "rizq":
      return "morning";
    case "gratitude":
      return "evening";
    default:
      return "anytime";
  }
};

const timeSlotOptions: {
  value: TimeSlot;
  label: string;
  sublabel: string;
  Icon: typeof Sun;
  color: string;
  bgColor: string;
}[] = [
  {
    value: "morning",
    label: "Morning",
    sublabel: "After Fajr",
    Icon: Sun,
    color: "text-amber-600",
    bgColor: "bg-amber-50 dark:bg-amber-950/30",
  },
  {
    value: "anytime",
    label: "Anytime",
    sublabel: "Throughout day",
    Icon: Clock,
    color: "text-blue-600",
    bgColor: "bg-blue-50 dark:bg-blue-950/30",
  },
  {
    value: "evening",
    label: "Evening",
    sublabel: "After Maghrib",
    Icon: Moon,
    color: "text-indigo-600",
    bgColor: "bg-indigo-50 dark:bg-indigo-950/30",
  },
];

export function AddToAdkharSheet({
  dua,
  open,
  onOpenChange,
}: AddToAdkharSheetProps) {
  const { toast } = useToast();
  const { addCustomHabit, todaysHabits } = useUserHabits();
  const recommendedSlot = dua ? getRecommendedTimeSlot(dua.category) : "anytime";
  const [selectedSlot, setSelectedSlot] = useState<TimeSlot>(recommendedSlot);

  const isAlreadyAdded = todaysHabits.some((h) => h.duaId === dua?.id);

  // Update selected slot when dua changes
  useEffect(() => {
    if (dua) {
      setSelectedSlot(getRecommendedTimeSlot(dua.category));
    }
  }, [dua]);

  const handleAdd = () => {
    if (dua && !isAlreadyAdded) {
      addCustomHabit(dua.id, selectedSlot);
      toast({
        title: "Added to Daily Adkhar",
        description: `${dua.title} added to ${selectedSlot} routine`,
      });
      onOpenChange(false);
    }
  };

  if (!dua) return null;

  return (
    <Sheet open={open} onOpenChange={onOpenChange}>
      <SheetContent
        side="bottom"
        className="rounded-t-3xl border-t-2 border-primary/20"
      >
        <SheetHeader className="pb-2">
          <SheetTitle className="text-lg">Add to Daily Adkhar</SheetTitle>
          <SheetDescription className="text-sm">
            {dua.title}
          </SheetDescription>
        </SheetHeader>

        {/* Already Added State */}
        {isAlreadyAdded ? (
          <div className="flex flex-col items-center py-8 text-center">
            <div className="mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-green-100 dark:bg-green-900/30">
              <Check className="h-8 w-8 text-green-600 dark:text-green-400" />
            </div>
            <p className="font-medium text-foreground">
              Already in your Daily Adkhar
            </p>
            <p className="mt-1 text-sm text-muted-foreground">
              This dua is already part of your daily routine
            </p>
            <Button
              variant="outline"
              className="mt-6"
              onClick={() => onOpenChange(false)}
            >
              Close
            </Button>
          </div>
        ) : (
          <div className="pb-6 pt-4">
            {/* Prompt */}
            <p className="mb-4 text-sm text-muted-foreground">
              When would you like to practice this dua?
            </p>

            {/* Time slot selection */}
            <div className="grid grid-cols-3 gap-2">
              {timeSlotOptions.map((slot) => {
                const isSelected = selectedSlot === slot.value;
                const isRecommended = dua && getRecommendedTimeSlot(dua.category) === slot.value;
                return (
                  <button
                    key={slot.value}
                    onClick={() => setSelectedSlot(slot.value)}
                    className={cn(
                      "relative flex flex-col items-center gap-2 rounded-xl p-4",
                      "border-2 transition-all duration-200",
                      "hover:scale-[1.02] active:scale-[0.98]",
                      isSelected
                        ? "border-primary bg-primary/5"
                        : isRecommended
                        ? "border-blue-400 bg-blue-50 dark:bg-blue-950/30"
                        : "border-transparent bg-muted/50 hover:bg-muted"
                    )}
                  >
                    {/* Recommended Badge */}
                    {isRecommended && (
                      <div className="absolute -top-2 left-1/2 -translate-x-1/2 flex items-center gap-1 rounded-full bg-blue-500 px-2 py-0.5 shadow-md">
                        <Sparkles className="h-3 w-3 text-white" />
                        <span className="text-[10px] font-bold text-white uppercase tracking-wide">
                          Recommended
                        </span>
                      </div>
                    )}
                    <div
                      className={cn(
                        "flex h-10 w-10 items-center justify-center rounded-full",
                        slot.bgColor
                      )}
                    >
                      <slot.Icon className={cn("h-5 w-5", slot.color)} />
                    </div>
                    <div className="text-center">
                      <p
                        className={cn(
                          "text-sm font-medium",
                          isSelected ? "text-primary" : "text-foreground"
                        )}
                      >
                        {slot.label}
                      </p>
                      <p className="text-xs text-muted-foreground">
                        {slot.sublabel}
                      </p>
                    </div>
                    {isSelected && (
                      <div className="absolute -top-1 -right-1 flex h-5 w-5 items-center justify-center rounded-full bg-primary">
                        <Check className="h-3 w-3 text-primary-foreground" />
                      </div>
                    )}
                  </button>
                );
              })}
            </div>

            {/* Add button */}
            <Button className="mt-6 w-full gap-2" onClick={handleAdd}>
              <Plus className="h-4 w-4" />
              Add to Daily Adkhar
            </Button>
          </div>
        )}
      </SheetContent>
    </Sheet>
  );
}
