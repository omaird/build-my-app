import { motion } from "framer-motion";
import { Sun, Clock, Moon, Sparkles, Check, Plus, X } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";
import type { JourneyWithDuas, TimeSlot } from "@/types/habit";

interface JourneyPreviewProps {
  journey: JourneyWithDuas;
  isActive: boolean;
  activeCount?: number; // Number of currently active journeys
  onActivate: () => void;
  onDeactivate: () => void;
}

const slotIcons = {
  morning: Sun,
  anytime: Clock,
  evening: Moon,
};

const slotColors = {
  morning: {
    icon: "text-amber-500",
    bg: "bg-amber-500/10",
  },
  anytime: {
    icon: "text-blue-500",
    bg: "bg-blue-500/10",
  },
  evening: {
    icon: "text-indigo-500",
    bg: "bg-indigo-500/10",
  },
};

const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.1,
      delayChildren: 0.2,
    },
  },
};

const itemVariants = {
  hidden: { opacity: 0, y: 15 },
  visible: {
    opacity: 1,
    y: 0,
    transition: { duration: 0.4 },
  },
};

export function JourneyPreview({
  journey,
  isActive,
  activeCount = 0,
  onActivate,
  onDeactivate,
}: JourneyPreviewProps) {
  // Group duas by time slot for display
  const groupedDuas = journey.duas.reduce(
    (acc, dua) => {
      acc[dua.timeSlot].push(dua);
      return acc;
    },
    { morning: [], anytime: [], evening: [] } as Record<
      TimeSlot,
      typeof journey.duas
    >
  );

  const totalXp = journey.duas.reduce((sum, d) => sum + d.xpValue, 0);

  return (
    <motion.div
      className="space-y-6"
      variants={containerVariants}
      initial="hidden"
      animate="visible"
    >
      {/* Header with ornate emoji frame */}
      <motion.div className="text-center" variants={itemVariants}>
        {/* Decorative emoji container */}
        <motion.div
          className="relative inline-block"
          whileHover={{ scale: 1.05 }}
        >
          {/* Outer decorative ring */}
          <div className="absolute -inset-4 rounded-full border-2 border-dashed border-primary/20 animate-[spin_20s_linear_infinite]" />

          {/* Inner glow */}
          <motion.div
            className="absolute -inset-2 rounded-full bg-primary/10 blur-xl"
            animate={{ scale: [1, 1.1, 1], opacity: [0.3, 0.5, 0.3] }}
            transition={{ duration: 3, repeat: Infinity }}
          />

          {/* Emoji frame */}
          <div className="relative flex h-20 w-20 items-center justify-center rounded-full bg-gradient-to-br from-secondary to-secondary/30 border-2 border-primary/20 shadow-elevated overflow-hidden">
            {/* Corner ornaments */}
            <div className="absolute -top-1 -right-1 h-3 w-3 border-t-2 border-r-2 border-primary/40 rounded-tr-lg z-10" />
            <div className="absolute -bottom-1 -left-1 h-3 w-3 border-b-2 border-l-2 border-primary/40 rounded-bl-lg z-10" />

            {journey.emoji.startsWith('/images/') ? (
              <img 
                src={journey.emoji} 
                alt={journey.name} 
                className="w-full h-full object-cover rounded-full"
              />
            ) : (
              <span className="text-4xl">{journey.emoji}</span>
            )}
          </div>
        </motion.div>

        <motion.h1
          className="mt-4 font-display text-2xl font-bold text-foreground"
          variants={itemVariants}
        >
          {journey.name}
        </motion.h1>

        <motion.p
          className="mt-2 text-sm text-muted-foreground max-w-xs mx-auto"
          variants={itemVariants}
        >
          {journey.description}
        </motion.p>

        {/* Stats badges */}
        <motion.div
          className="mt-4 flex items-center justify-center gap-3 flex-wrap"
          variants={itemVariants}
        >
          <Badge variant="secondary" className="gap-1.5 px-3 py-1">
            <Clock className="h-3.5 w-3.5" />
            ~{journey.estimatedMinutes} min/day
          </Badge>
          <Badge variant="secondary" className="gap-1.5 px-3 py-1 bg-gold-soft/20 text-primary border-gold-soft/30">
            <Sparkles className="h-3.5 w-3.5" />
            {totalXp} XP/day
          </Badge>
          <Badge variant="secondary" className="gap-1.5 px-3 py-1">
            {journey.duas.length} duas
          </Badge>
        </motion.div>
      </motion.div>

      {/* Divider */}
      <motion.div className="islamic-divider" variants={itemVariants}>
        <span className="text-primary/40">✦</span>
      </motion.div>

      {/* Duas by time slot */}
      <motion.div className="space-y-4" variants={itemVariants}>
        {(["morning", "anytime", "evening"] as TimeSlot[]).map((slot, slotIndex) => {
          const duas = groupedDuas[slot];
          if (duas.length === 0) return null;

          const SlotIcon = slotIcons[slot];
          const colors = slotColors[slot];

          return (
            <motion.div
              key={slot}
              className="space-y-2"
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.3 + slotIndex * 0.1 }}
            >
              <div className="flex items-center gap-2.5 px-1">
                <div className={cn(
                  "flex h-7 w-7 items-center justify-center rounded-full",
                  colors.bg
                )}>
                  <SlotIcon className={cn("h-4 w-4", colors.icon)} />
                </div>
                <span className="text-sm font-semibold capitalize text-foreground">
                  {slot}
                </span>
                <span className="text-xs text-muted-foreground">
                  ({duas.length} duas)
                </span>
              </div>

              <Card className="overflow-hidden shadow-soft">
                <CardContent className="divide-y divide-border/50 p-0">
                  {duas
                    .sort((a, b) => a.sortOrder - b.sortOrder)
                    .map((dua, index) => (
                      <motion.div
                        key={`${dua.duaId}-${index}`}
                        className="flex items-center justify-between px-4 py-3 hover:bg-secondary/30 transition-colors"
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        transition={{ delay: 0.4 + index * 0.05 }}
                      >
                        <span className="text-sm font-medium text-foreground">
                          {dua.title}
                        </span>
                        <span className="text-xs text-primary font-mono font-medium">
                          +{dua.xpValue} XP
                        </span>
                      </motion.div>
                    ))}
                </CardContent>
              </Card>
            </motion.div>
          );
        })}
      </motion.div>

      {/* Action button */}
      <motion.div variants={itemVariants}>
        {isActive ? (
          <div className="space-y-3">
            <motion.div
              className="flex items-center justify-center gap-2 text-sm"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
            >
              <div className="flex h-6 w-6 items-center justify-center rounded-full gradient-primary shadow-sm">
                <Check className="h-3.5 w-3.5 text-primary-foreground" />
              </div>
              <span className="font-medium text-primary">
                {activeCount > 1 
                  ? `Active (1 of ${activeCount} journeys)` 
                  : "Currently active"}
              </span>
            </motion.div>

            <motion.div whileTap={{ scale: 0.98 }}>
              <Button
                variant="outline"
                className="w-full h-12 gap-2 rounded-btn border-destructive/30 text-destructive hover:bg-destructive/10"
                size="lg"
                onClick={onDeactivate}
              >
                <X className="h-4 w-4" />
                Remove Journey
              </Button>
            </motion.div>
          </div>
        ) : (
          <motion.div whileTap={{ scale: 0.98 }}>
            <Button
              className="w-full h-12 gap-2 rounded-btn btn-gradient"
              size="lg"
              onClick={onActivate}
            >
              <Plus className="h-4 w-4" />
              {activeCount > 0 ? "Add to My Journeys" : "Start This Journey"}
            </Button>
          </motion.div>
        )}
      </motion.div>
    </motion.div>
  );
}
