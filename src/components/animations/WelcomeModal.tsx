import { useState, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Button } from "@/components/ui/button";
import { Sparkles } from "lucide-react";

const STORAGE_KEY = "riza_welcome_seen";

interface WelcomeModalProps {
  forceShow?: boolean;
  onComplete?: () => void;
}

export function WelcomeModal({ forceShow = false, onComplete }: WelcomeModalProps) {
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    if (forceShow) {
      setIsVisible(true);
      return;
    }

    const hasSeenWelcome = localStorage.getItem(STORAGE_KEY);
    if (!hasSeenWelcome) {
      // Small delay for smoother UX after page load
      const timer = setTimeout(() => setIsVisible(true), 500);
      return () => clearTimeout(timer);
    }
  }, [forceShow]);

  const handleDismiss = () => {
    setIsVisible(false);
    localStorage.setItem(STORAGE_KEY, "true");
    onComplete?.();
  };

  return (
    <AnimatePresence>
      {isVisible && (
        <motion.div
          className="fixed inset-0 z-50 flex items-center justify-center p-4"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.3 }}
        >
          {/* Backdrop */}
          <motion.div
            className="absolute inset-0 bg-mocha-deep/40 backdrop-blur-sm"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={handleDismiss}
          />

          {/* Modal */}
          <motion.div
            className="relative z-10 w-full max-w-sm overflow-hidden rounded-islamic bg-card shadow-elevated"
            initial={{ opacity: 0, scale: 0.9, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.95, y: 10 }}
            transition={{
              type: "spring",
              stiffness: 300,
              damping: 25,
            }}
          >
            {/* Islamic pattern header */}
            <div className="relative h-32 overflow-hidden gradient-primary">
              <div className="absolute inset-0 islamic-pattern opacity-20" />

              {/* Decorative star */}
              <motion.div
                className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2"
                initial={{ scale: 0, rotate: -180 }}
                animate={{ scale: 1, rotate: 0 }}
                transition={{ delay: 0.3, type: "spring", stiffness: 200 }}
              >
                <svg
                  width="80"
                  height="80"
                  viewBox="0 0 80 80"
                  fill="none"
                  className="text-white/90"
                >
                  <path
                    d="M40 0L47 30L77 33L50 50L55 80L40 60L25 80L30 50L3 33L33 30L40 0Z"
                    fill="currentColor"
                  />
                </svg>
              </motion.div>
            </div>

            {/* Content */}
            <div className="p-6 text-center">
              <motion.div
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.2 }}
              >
                <h2 className="font-display text-2xl font-bold text-foreground mb-1">
                  Assalamu Alaikum
                </h2>
                <p className="text-arabic text-xl text-primary mb-4">
                  السلام عليكم
                </p>
              </motion.div>

              <motion.p
                className="text-muted-foreground mb-6 leading-relaxed"
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.3 }}
              >
                Welcome to RIZA — your companion for building a consistent dua practice.
                Build your streak, earn rewards, and grow spiritually.
              </motion.p>

              {/* Features preview */}
              <motion.div
                className="grid grid-cols-3 gap-3 mb-6"
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.4 }}
              >
                {[
                  { icon: "🔥", label: "Daily Streaks" },
                  { icon: "✨", label: "Earn XP" },
                  { icon: "📿", label: "Track Duas" },
                ].map((item, i) => (
                  <motion.div
                    key={item.label}
                    className="flex flex-col items-center gap-1 p-3 rounded-lg bg-secondary/50"
                    initial={{ opacity: 0, scale: 0.8 }}
                    animate={{ opacity: 1, scale: 1 }}
                    transition={{ delay: 0.5 + i * 0.1 }}
                  >
                    <span className="text-xl">{item.icon}</span>
                    <span className="text-xs text-muted-foreground">{item.label}</span>
                  </motion.div>
                ))}
              </motion.div>

              <motion.div
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.6 }}
              >
                <Button
                  onClick={handleDismiss}
                  className="w-full btn-gradient gap-2"
                  size="lg"
                >
                  <Sparkles className="h-4 w-4" />
                  Begin Your Journey
                </Button>
              </motion.div>
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}

// Reset welcome modal (for testing)
export function resetWelcomeModal() {
  localStorage.removeItem(STORAGE_KEY);
}
