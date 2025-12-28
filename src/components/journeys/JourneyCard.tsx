import { motion } from "framer-motion";
import { Clock, Sparkles, Lock, Check, Star } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";
import type { Journey } from "@/types/habit";

interface JourneyCardProps {
  journey: Journey;
  isActive?: boolean;
  onClick: () => void;
  index?: number;
}

export function JourneyCard({ journey, isActive, onClick, index = 0 }: JourneyCardProps) {
  const { name, emoji, description, estimatedMinutes, dailyXp, isPremium, isFeatured } =
    journey;

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: index * 0.1, duration: 0.4 }}
    >
      <motion.div
        whileHover={{ y: -4, scale: 1.01 }}
        whileTap={{ scale: 0.98 }}
      >
        <Card
          className={cn(
            "relative cursor-pointer overflow-hidden transition-all duration-300",
            "shadow-soft hover:shadow-elevated",
            isActive && "ring-2 ring-primary shadow-glow-primary",
            isFeatured && !isActive && "border-primary/30 bg-gradient-to-br from-primary/[0.03] to-transparent"
          )}
          onClick={onClick}
        >
          {/* Pattern overlay for featured */}
          {isFeatured && (
            <div className="absolute inset-0 islamic-pattern-dense opacity-20 pointer-events-none" />
          )}

          {/* Featured badge */}
          {isFeatured && !isActive && (
            <motion.div
              className="absolute -right-8 top-3 rotate-45"
              initial={{ x: 20, opacity: 0 }}
              animate={{ x: 0, opacity: 1 }}
              transition={{ delay: index * 0.1 + 0.2 }}
            >
              <Badge className="bg-primary text-primary-foreground gap-1 px-8 py-0.5 rounded-none text-[10px]">
                <Star className="h-2.5 w-2.5" />
                Featured
              </Badge>
            </motion.div>
          )}

          <CardContent className="relative p-4">
            <div className="flex items-start justify-between gap-3">
              {/* Emoji with decorative frame */}
              <div className="flex items-start gap-3.5">
                <motion.div
                  className={cn(
                    "relative flex h-14 w-14 items-center justify-center rounded-islamic",
                    "bg-gradient-to-br from-secondary/80 to-secondary/30",
                    "border border-primary/10 shadow-sm",
                    isActive && "from-primary/20 to-primary/5 border-primary/30"
                  )}
                  whileHover={{ rotate: [0, -5, 5, 0] }}
                  transition={{ duration: 0.5 }}
                >
                  {/* Decorative corner */}
                  <div className="absolute -top-0.5 -right-0.5 h-2 w-2 border-t border-r border-primary/30 rounded-tr" />
                  <div className="absolute -bottom-0.5 -left-0.5 h-2 w-2 border-b border-l border-primary/30 rounded-bl" />

                  <span className="text-2xl">{emoji}</span>

                  {/* Active glow */}
                  {isActive && (
                    <motion.div
                      className="absolute inset-0 rounded-islamic bg-primary/20 blur-md -z-10"
                      animate={{ scale: [1, 1.2, 1], opacity: [0.5, 0.8, 0.5] }}
                      transition={{ duration: 2, repeat: Infinity }}
                    />
                  )}
                </motion.div>

                <div className="space-y-1.5 min-w-0">
                  <div className="flex items-center gap-2 flex-wrap">
                    <h3 className="font-display font-semibold text-foreground">
                      {name}
                    </h3>
                    {isPremium && (
                      <Badge variant="secondary" className="gap-1 text-[10px] px-2 py-0">
                        <Lock className="h-2.5 w-2.5" />
                        Premium
                      </Badge>
                    )}
                  </div>
                  <p className="text-xs text-muted-foreground line-clamp-2 leading-relaxed">
                    {description}
                  </p>
                </div>
              </div>

              {/* Active indicator */}
              {isActive && (
                <motion.div
                  className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full gradient-primary shadow-glow-primary"
                  initial={{ scale: 0 }}
                  animate={{ scale: 1 }}
                  transition={{ type: "spring", stiffness: 400, damping: 15 }}
                >
                  <Check className="h-4 w-4 text-primary-foreground" />
                </motion.div>
              )}
            </div>

            {/* Stats row */}
            <motion.div
              className="mt-4 flex items-center gap-4"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: index * 0.1 + 0.1 }}
            >
              <div className="flex items-center gap-1.5 text-xs text-muted-foreground">
                <Clock className="h-3.5 w-3.5" />
                <span>{estimatedMinutes} min/day</span>
              </div>
              <div className="flex items-center gap-1.5">
                <Sparkles className="h-3.5 w-3.5 text-primary" />
                <span className="text-xs font-semibold text-primary font-mono">
                  {dailyXp} XP/day
                </span>
              </div>
            </motion.div>
          </CardContent>

          {/* Active accent line */}
          {isActive && (
            <motion.div
              className="absolute bottom-0 left-0 right-0 h-1 gradient-primary"
              initial={{ scaleX: 0 }}
              animate={{ scaleX: 1 }}
              transition={{ duration: 0.4 }}
            />
          )}
        </Card>
      </motion.div>
    </motion.div>
  );
}
