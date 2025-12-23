import { Link } from "react-router-dom";
import { ChevronRight, Check } from "lucide-react";
import { cn } from "@/lib/utils";
import { Dua, DuaCategory } from "@/types/dua";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";

interface DuaCardProps {
  dua: Dua;
  isCompleted?: boolean;
}

const categoryColors: Record<DuaCategory, string> = {
  morning: "bg-amber-100 text-amber-800 dark:bg-amber-900/30 dark:text-amber-300",
  evening: "bg-indigo-100 text-indigo-800 dark:bg-indigo-900/30 dark:text-indigo-300",
  rizq: "bg-emerald-100 text-emerald-800 dark:bg-emerald-900/30 dark:text-emerald-300",
  gratitude: "bg-rose-100 text-rose-800 dark:bg-rose-900/30 dark:text-rose-300",
};

const categoryLabels: Record<DuaCategory, string> = {
  morning: "Morning",
  evening: "Evening",
  rizq: "Rizq",
  gratitude: "Gratitude",
};

export function DuaCard({ dua, isCompleted = false }: DuaCardProps) {
  return (
    <Link to={`/practice/${dua.id}`}>
      <Card className={cn(
        "card-elevated btn-tap group",
        isCompleted && "border-primary/30 bg-primary/5"
      )}>
        <CardContent className="flex items-center gap-4 p-4">
          <div className="flex-1 space-y-2">
            <div className="flex items-center gap-2">
              <h3 className="font-semibold text-foreground">{dua.title}</h3>
              {isCompleted && (
                <div className="flex h-5 w-5 items-center justify-center rounded-full bg-primary">
                  <Check className="h-3 w-3 text-primary-foreground" />
                </div>
              )}
            </div>
            <div className="flex items-center gap-2">
              <Badge variant="secondary" className={cn("text-[10px]", categoryColors[dua.category])}>
                {categoryLabels[dua.category]}
              </Badge>
              <span className="text-xs text-muted-foreground">
                +{dua.xpValue} XP • {dua.repetitions}x
              </span>
            </div>
          </div>
          <ChevronRight className="h-5 w-5 text-muted-foreground transition-transform group-hover:translate-x-1" />
        </CardContent>
      </Card>
    </Link>
  );
}