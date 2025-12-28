import { motion, AnimatePresence } from "framer-motion";
import { CelebrationParticles } from "./CelebrationParticles";
import { AnimatedCheckmark } from "./AnimatedCheckmark";
import { cn } from "@/lib/utils";

interface CelebrationOverlayProps {
  isVisible: boolean;
  title?: string;
  subtitle?: string;
  xpEarned?: number;
  onComplete?: () => void;
  onDismiss?: () => void;
}

export function CelebrationOverlay({
  isVisible,
  title = "Masha'Allah!",
  subtitle = "Dua completed",
  xpEarned = 0,
  onComplete,
  onDismiss,
}: CelebrationOverlayProps) {
  return (
    <AnimatePresence>
      {isVisible && (
        <motion.div
          className="fixed inset-0 z-50 flex items-center justify-center"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.3 }}
          onClick={onDismiss}
        >
          {/* Background overlay with radial gradient */}
          <motion.div
            className="absolute inset-0 gradient-celebration"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
          />

          {/* Islamic pattern overlay */}
          <div className="absolute inset-0 islamic-pattern opacity-40" />

          {/* Content container */}
          <motion.div
            className="relative z-10 flex flex-col items-center px-8"
            initial={{ scale: 0.8, opacity: 0, y: 20 }}
            animate={{ scale: 1, opacity: 1, y: 0 }}
            exit={{ scale: 0.9, opacity: 0, y: -20 }}
            transition={{
              type: "spring",
              stiffness: 260,
              damping: 20,
              delay: 0.1,
            }}
            onClick={(e) => e.stopPropagation()}
          >
            {/* Celebration particles */}
            <CelebrationParticles isActive={isVisible} particleCount={20} />

            {/* Animated checkmark */}
            <AnimatedCheckmark
              isVisible={isVisible}
              size={100}
              delay={0.2}
              className="mb-8"
            />

            {/* Title */}
            <motion.h2
              className="font-display text-4xl font-bold text-mocha-deep mb-2 text-center"
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.4 }}
            >
              {title}
            </motion.h2>

            {/* Subtitle */}
            <motion.p
              className="text-lg text-muted-foreground mb-6 text-center"
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.5 }}
            >
              {subtitle}
            </motion.p>

            {/* XP Badge */}
            {xpEarned > 0 && (
              <motion.div
                className={cn(
                  "flex items-center gap-2 px-6 py-3 rounded-full",
                  "bg-white/80 backdrop-blur-sm shadow-elevated",
                  "border border-gold-soft/50"
                )}
                initial={{ opacity: 0, scale: 0.8, y: 10 }}
                animate={{ opacity: 1, scale: 1, y: 0 }}
                transition={{
                  delay: 0.6,
                  type: "spring",
                  stiffness: 300,
                  damping: 20,
                }}
              >
                <motion.span
                  className="text-2xl"
                  animate={{ rotate: [0, 15, -15, 0] }}
                  transition={{ delay: 0.8, duration: 0.5 }}
                >
                  ✨
                </motion.span>
                <span className="font-display text-xl font-bold text-gradient-primary">
                  +{xpEarned} XP
                </span>
              </motion.div>
            )}

            {/* Tap to continue hint */}
            <motion.p
              className="mt-10 text-sm text-muted-foreground/60"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 1.2 }}
            >
              Tap anywhere to continue
            </motion.p>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}

// Smaller inline celebration for completing items in a list
export function MiniCelebration({
  isVisible,
  message = "Done!",
}: {
  isVisible: boolean;
  message?: string;
}) {
  return (
    <AnimatePresence>
      {isVisible && (
        <motion.div
          className="flex items-center gap-2 px-3 py-1.5 rounded-full bg-primary/10 text-primary text-sm font-medium"
          initial={{ opacity: 0, scale: 0.8, x: -10 }}
          animate={{ opacity: 1, scale: 1, x: 0 }}
          exit={{ opacity: 0, scale: 0.8, x: 10 }}
          transition={{ type: "spring", stiffness: 300, damping: 20 }}
        >
          <motion.span
            animate={{ scale: [1, 1.3, 1] }}
            transition={{ duration: 0.4, delay: 0.1 }}
          >
            ✓
          </motion.span>
          {message}
        </motion.div>
      )}
    </AnimatePresence>
  );
}
