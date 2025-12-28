import { Link } from "react-router-dom";
import { motion } from "framer-motion";
import { ChevronRight, Check, Plus, Sparkles } from "lucide-react";
import { cn } from "@/lib/utils";
import { Dua, DuaCategory } from "@/types/dua";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";

interface DuaCardProps {
  dua: Dua;
  isCompleted?: boolean;
  isInAdkhar?: boolean;
  onAddToAdkhar?: (dua: Dua) => void;
  index?: number;
}

const categoryConfig: Record<DuaCategory, { className: string; label: string }> = {
  morning: {
    className: "badge-morning",
    label: "Morning",
  },
  evening: {
    className: "badge-evening",
    label: "Evening",
  },
  rizq: {
    className: "badge-rizq",
    label: "Rizq",
  },
  gratitude: {
    className: "badge-gratitude",
    label: "Gratitude",
  },
};

export function DuaCard({
  dua,
  isCompleted = false,
  isInAdkhar = false,
  onAddToAdkhar,
  index = 0,
}: DuaCardProps) {
  const handleAddClick = (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    onAddToAdkhar?.(dua);
  };

  const config = categoryConfig[dua.category];

  return (
    <motion.div
      initial={{ opacity: 0, y: 15 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: index * 0.05, duration: 0.3 }}
    >
      <Link to={`/practice/${dua.id}`}>
        <motion.div
          className={cn(
            "group relative overflow-hidden rounded-islamic bg-card border",
            "shadow-soft hover:shadow-elevated transition-all duration-300",
            isCompleted && "border-primary/25 bg-primary/[0.03]"
          )}
          whileHover={{ y: -2 }}
          whileTap={{ scale: 0.98 }}
        >
          {/* Subtle gradient overlay on hover */}
          <div className="absolute inset-0 bg-gradient-to-r from-primary/0 via-primary/0 to-primary/5 opacity-0 group-hover:opacity-100 transition-opacity duration-300" />

          <div className="relative flex items-center gap-4 p-4">
            {/* Left content */}
            <div className="flex-1 space-y-2.5 min-w-0">
              {/* Title row */}
              <div className="flex items-center gap-2.5">
                <h3 className="font-display text-base font-semibold text-foreground truncate">
                  {dua.title}
                </h3>
                {isCompleted && (
                  <motion.div
                    className="flex h-5 w-5 items-center justify-center rounded-full bg-primary shadow-sm"
                    initial={{ scale: 0 }}
                    animate={{ scale: 1 }}
                    transition={{ type: "spring", stiffness: 400, damping: 15 }}
                  >
                    <Check className="h-3 w-3 text-primary-foreground" />
                  </motion.div>
                )}
              </div>

              {/* Meta row */}
              <div className="flex flex-wrap items-center gap-2">
                <Badge
                  variant="secondary"
                  className={cn("text-[10px] font-medium px-2 py-0.5", config.className)}
                >
                  {config.label}
                </Badge>

                <div className="flex items-center gap-1.5 text-xs text-muted-foreground">
                  <Sparkles className="h-3 w-3 text-primary/70" />
                  <span className="font-mono font-medium text-primary">+{dua.xpValue}</span>
                  <span className="text-muted-foreground/50">•</span>
                  <span>{dua.repetitions}×</span>
                </div>

                {isInAdkhar && (
                  <Badge
                    variant="outline"
                    className="gap-1 border-primary/30 text-[10px] text-primary px-2 py-0.5"
                  >
                    <Sparkles className="h-2.5 w-2.5" />
                    Active
                  </Badge>
                )}
              </div>
            </div>

            {/* Right action */}
            {onAddToAdkhar && !isInAdkhar ? (
              <Button
                variant="ghost"
                size="icon"
                className={cn(
                  "h-9 w-9 shrink-0 rounded-full",
                  "hover:bg-primary/10 hover:text-primary",
                  "border border-transparent hover:border-primary/20",
                  "transition-all duration-200"
                )}
                onClick={handleAddClick}
              >
                <Plus className="h-4 w-4" />
              </Button>
            ) : (
              <div className="flex items-center justify-center h-9 w-9 shrink-0">
                <ChevronRight
                  className={cn(
                    "h-5 w-5 text-muted-foreground/50",
                    "transition-transform duration-200 group-hover:translate-x-1 group-hover:text-primary"
                  )}
                />
              </div>
            )}
          </div>

          {/* Bottom accent line for completed */}
          {isCompleted && (
            <motion.div
              className="absolute bottom-0 left-0 right-0 h-0.5 gradient-primary"
              initial={{ scaleX: 0 }}
              animate={{ scaleX: 1 }}
              transition={{ duration: 0.4 }}
            />
          )}
        </motion.div>
      </Link>
    </motion.div>
  );
}

// Compact variant for lists
export function DuaCardCompact({
  dua,
  isCompleted = false,
  onClick,
}: {
  dua: Dua;
  isCompleted?: boolean;
  onClick?: () => void;
}) {
  return (
    <motion.button
      className={cn(
        "w-full text-left p-3 rounded-lg border bg-card",
        "hover:bg-secondary/50 transition-colors",
        isCompleted && "border-primary/20 bg-primary/5"
      )}
      onClick={onClick}
      whileTap={{ scale: 0.98 }}
    >
      <div className="flex items-center justify-between gap-3">
        <div className="flex-1 min-w-0">
          <p className="font-medium text-sm truncate">{dua.title}</p>
          <p className="text-xs text-muted-foreground">
            {dua.repetitions}× • +{dua.xpValue} XP
          </p>
        </div>
        {isCompleted && (
          <div className="h-5 w-5 rounded-full bg-primary flex items-center justify-center">
            <Check className="h-3 w-3 text-primary-foreground" />
          </div>
        )}
      </div>
    </motion.button>
  );
}
