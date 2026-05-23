import { useState, useEffect, useRef } from "react";
import { motion, AnimatePresence, type Variants } from "framer-motion";
import { Sparkles, Star, BookOpen, Compass, ArrowRight, X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

const FOCUSABLE_SELECTOR =
  'a[href], button:not([disabled]), textarea:not([disabled]), input:not([disabled]), select:not([disabled]), [tabindex]:not([tabindex="-1"])';

interface WelcomeModalProps {
  isOpen: boolean;
  onClose: () => void;
  userName?: string;
}

const features = [
  {
    icon: BookOpen,
    title: "Daily Duas",
    description: "Build a consistent practice with curated duas",
    color: "text-amber-500",
    bg: "bg-amber-500/10",
  },
  {
    icon: Compass,
    title: "Guided Journeys",
    description: "Follow structured paths for spiritual growth",
    color: "text-teal-500",
    bg: "bg-teal-500/10",
  },
  {
    icon: Sparkles,
    title: "Track Progress",
    description: "Earn XP and maintain your streak",
    color: "text-primary",
    bg: "bg-primary/10",
  },
];

const backdropVariants: Variants = {
  hidden: { opacity: 0 },
  visible: { opacity: 1 },
};

const modalVariants: Variants = {
  hidden: {
    opacity: 0,
    scale: 0.9,
    y: 20,
  },
  visible: {
    opacity: 1,
    scale: 1,
    y: 0,
    transition: {
      type: "spring",
      stiffness: 300,
      damping: 25,
      staggerChildren: 0.1,
      delayChildren: 0.2,
    },
  },
  exit: {
    opacity: 0,
    scale: 0.95,
    y: -10,
    transition: { duration: 0.2 },
  },
};

const itemVariants: Variants = {
  hidden: { opacity: 0, y: 15 },
  visible: {
    opacity: 1,
    y: 0,
    transition: { duration: 0.4 },
  },
};

const starPositions = [
  { top: "10%", left: "15%", delay: 0 },
  { top: "20%", right: "20%", delay: 0.5 },
  { bottom: "30%", left: "10%", delay: 1 },
  { bottom: "15%", right: "15%", delay: 1.5 },
  { top: "40%", left: "5%", delay: 0.8 },
  { top: "60%", right: "8%", delay: 1.2 },
];

export function WelcomeModal({ isOpen, onClose, userName }: WelcomeModalProps) {
  const [currentStep, setCurrentStep] = useState(0);
  const displayName = userName || "there";
  const modalRef = useRef<HTMLDivElement>(null);
  const previousFocusRef = useRef<HTMLElement | null>(null);

  useEffect(() => {
    if (isOpen) {
      setCurrentStep(0);
    }
  }, [isOpen]);

  // Focus trap: capture previous focus, move into modal, restore on close.
  useEffect(() => {
    if (!isOpen) return;

    previousFocusRef.current = document.activeElement as HTMLElement | null;

    // Defer focus until after the animation begins so the modal element exists.
    const focusTimer = window.setTimeout(() => {
      const first = modalRef.current?.querySelector<HTMLElement>(FOCUSABLE_SELECTOR);
      first?.focus();
    }, 50);

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        e.preventDefault();
        onClose();
        return;
      }
      if (e.key !== "Tab" || !modalRef.current) return;

      const focusables = Array.from(
        modalRef.current.querySelectorAll<HTMLElement>(FOCUSABLE_SELECTOR),
      ).filter((el) => !el.hasAttribute("disabled"));
      if (focusables.length === 0) return;

      const first = focusables[0];
      const last = focusables[focusables.length - 1];
      const active = document.activeElement as HTMLElement | null;

      if (e.shiftKey && active === first) {
        e.preventDefault();
        last.focus();
      } else if (!e.shiftKey && active === last) {
        e.preventDefault();
        first.focus();
      }
    };

    document.addEventListener("keydown", handleKeyDown);
    return () => {
      window.clearTimeout(focusTimer);
      document.removeEventListener("keydown", handleKeyDown);
      previousFocusRef.current?.focus?.();
    };
  }, [isOpen, onClose]);

  const handleNext = () => {
    if (currentStep < features.length - 1) {
      setCurrentStep(currentStep + 1);
    } else {
      onClose();
    }
  };

  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div
          className="fixed inset-0 z-50 flex items-center justify-center px-4"
          variants={backdropVariants}
          initial="hidden"
          animate="visible"
          exit="hidden"
        >
          {/* Backdrop */}
          <motion.div
            className="absolute inset-0 bg-background/80 backdrop-blur-md"
            onClick={onClose}
          />

          {/* Floating stars */}
          {starPositions.map((pos, i) => (
            <motion.div
              key={i}
              className="absolute pointer-events-none"
              style={{ top: pos.top, left: pos.left, right: pos.right, bottom: pos.bottom }}
              initial={{ opacity: 0, scale: 0 }}
              animate={{
                opacity: [0, 0.6, 0],
                scale: [0.5, 1, 0.5],
                rotate: [0, 180],
              }}
              transition={{
                duration: 3,
                delay: pos.delay,
                repeat: Infinity,
                repeatDelay: 1,
              }}
            >
              <Star className="h-4 w-4 text-gold-soft fill-gold-soft/30" />
            </motion.div>
          ))}

          {/* Modal */}
          <motion.div
            ref={modalRef}
            role="dialog"
            aria-modal="true"
            aria-labelledby="welcome-modal-title"
            aria-describedby="welcome-modal-description"
            className="relative w-full max-w-sm overflow-hidden rounded-2xl bg-card border border-primary/10 shadow-elevated"
            variants={modalVariants}
            initial="hidden"
            animate="visible"
            exit="exit"
          >
            {/* Islamic pattern overlay */}
            <div className="absolute inset-0 islamic-pattern opacity-20 pointer-events-none" />

            {/* Close button */}
            <motion.button
              type="button"
              aria-label="Close welcome modal"
              className="absolute top-4 right-4 z-10 flex h-8 w-8 items-center justify-center rounded-full bg-secondary/50 text-muted-foreground hover:bg-secondary hover:text-foreground transition-colors"
              onClick={onClose}
              whileHover={{ scale: 1.1 }}
              whileTap={{ scale: 0.9 }}
            >
              <X className="h-4 w-4" />
            </motion.button>

            {/* Content */}
            <div className="relative px-6 py-8">
              {/* Header */}
              <motion.div className="text-center mb-6" variants={itemVariants}>
                {/* Decorative emoji */}
                <motion.div
                  className="relative inline-block mb-4"
                  animate={{
                    rotate: [0, 5, -5, 0],
                  }}
                  transition={{ duration: 4, repeat: Infinity }}
                >
                  <div className="absolute -inset-3 rounded-full bg-primary/10 blur-xl animate-pulse" />
                  <div className="relative flex h-20 w-20 items-center justify-center rounded-full bg-gradient-to-br from-gold-soft/30 to-primary/20 border-2 border-primary/20 shadow-lg">
                    <span className="text-4xl">🤲</span>
                  </div>
                </motion.div>

                <motion.h2
                  id="welcome-modal-title"
                  className="font-display text-2xl font-bold text-foreground"
                  variants={itemVariants}
                >
                  Assalamu Alaikum, {displayName}!
                </motion.h2>
                <motion.p
                  id="welcome-modal-description"
                  className="mt-2 text-sm text-muted-foreground"
                  variants={itemVariants}
                >
                  Welcome to your dua practice journey
                </motion.p>
              </motion.div>

              {/* Feature carousel */}
              <motion.div
                className="relative h-32 mb-6"
                variants={itemVariants}
              >
                <AnimatePresence mode="wait">
                  <motion.div
                    key={currentStep}
                    className="absolute inset-0 flex flex-col items-center text-center"
                    initial={{ opacity: 0, x: 20 }}
                    animate={{ opacity: 1, x: 0 }}
                    exit={{ opacity: 0, x: -20 }}
                    transition={{ duration: 0.3 }}
                  >
                    <div className={cn(
                      "flex h-14 w-14 items-center justify-center rounded-full mb-3",
                      features[currentStep].bg
                    )}>
                      {(() => {
                        const Icon = features[currentStep].icon;
                        return <Icon className={cn("h-7 w-7", features[currentStep].color)} />;
                      })()}
                    </div>
                    <h3 className="font-semibold text-foreground">
                      {features[currentStep].title}
                    </h3>
                    <p className="mt-1 text-sm text-muted-foreground">
                      {features[currentStep].description}
                    </p>
                  </motion.div>
                </AnimatePresence>
              </motion.div>

              {/* Step indicators */}
              <motion.div
                className="flex justify-center gap-2 mb-6"
                variants={itemVariants}
              >
                {features.map((_, i) => (
                  <motion.button
                    key={i}
                    className={cn(
                      "h-2 rounded-full transition-all duration-300",
                      i === currentStep
                        ? "w-6 bg-primary"
                        : "w-2 bg-primary/20 hover:bg-primary/40"
                    )}
                    onClick={() => setCurrentStep(i)}
                    whileHover={{ scale: 1.2 }}
                    whileTap={{ scale: 0.9 }}
                  />
                ))}
              </motion.div>

              {/* CTA Button */}
              <motion.div variants={itemVariants}>
                <motion.div whileTap={{ scale: 0.98 }}>
                  <Button
                    onClick={handleNext}
                    className="w-full h-12 gap-2 rounded-btn btn-gradient"
                    size="lg"
                  >
                    {currentStep === features.length - 1 ? (
                      <>
                        <Sparkles className="h-4 w-4" />
                        Start Your Journey
                      </>
                    ) : (
                      <>
                        Next
                        <ArrowRight className="h-4 w-4" />
                      </>
                    )}
                  </Button>
                </motion.div>
              </motion.div>
            </div>

            {/* Bottom decorative border */}
            <div className="h-1 w-full bg-gradient-to-r from-transparent via-primary/30 to-transparent" />
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
