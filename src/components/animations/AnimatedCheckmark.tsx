import { motion } from "framer-motion";
import { cn } from "@/lib/utils";

interface AnimatedCheckmarkProps {
  isVisible: boolean;
  size?: number;
  strokeWidth?: number;
  className?: string;
  delay?: number;
  onComplete?: () => void;
}

export function AnimatedCheckmark({
  isVisible,
  size = 64,
  strokeWidth = 4,
  className,
  delay = 0.2,
  onComplete,
}: AnimatedCheckmarkProps) {
  const checkmarkPath = "M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z";

  return (
    <motion.div
      className={cn("relative", className)}
      initial={{ scale: 0, opacity: 0 }}
      animate={isVisible ? { scale: 1, opacity: 1 } : { scale: 0, opacity: 0 }}
      transition={{
        type: "spring",
        stiffness: 260,
        damping: 20,
        delay,
      }}
      onAnimationComplete={() => {
        if (isVisible) onComplete?.();
      }}
    >
      {/* Outer glow ring */}
      <motion.div
        className="absolute inset-0 rounded-full bg-primary/20"
        initial={{ scale: 0.8, opacity: 0 }}
        animate={isVisible ? { scale: 1.3, opacity: [0, 0.5, 0] } : {}}
        transition={{ duration: 0.8, delay: delay + 0.1 }}
      />

      {/* Main circle */}
      <motion.div
        className="relative flex items-center justify-center rounded-full gradient-primary shadow-glow-primary"
        style={{ width: size, height: size }}
      >
        {/* Checkmark SVG with draw animation */}
        <svg
          width={size * 0.5}
          height={size * 0.5}
          viewBox="0 0 24 24"
          fill="none"
          className="text-white"
        >
          <motion.path
            d="M5 13l4 4L19 7"
            stroke="currentColor"
            strokeWidth={strokeWidth}
            strokeLinecap="round"
            strokeLinejoin="round"
            initial={{ pathLength: 0 }}
            animate={isVisible ? { pathLength: 1 } : { pathLength: 0 }}
            transition={{
              duration: 0.4,
              delay: delay + 0.3,
              ease: "easeOut",
            }}
          />
        </svg>
      </motion.div>
    </motion.div>
  );
}

// Smaller inline checkmark for lists
export function InlineCheckmark({
  isChecked,
  size = 20,
  className,
}: {
  isChecked: boolean;
  size?: number;
  className?: string;
}) {
  return (
    <motion.div
      className={cn(
        "flex items-center justify-center rounded-full",
        isChecked
          ? "bg-primary text-primary-foreground"
          : "border-2 border-muted-foreground/30",
        className
      )}
      style={{ width: size, height: size }}
      animate={isChecked ? { scale: [1, 1.2, 1] } : {}}
      transition={{ duration: 0.3 }}
    >
      {isChecked && (
        <motion.svg
          width={size * 0.6}
          height={size * 0.6}
          viewBox="0 0 24 24"
          fill="none"
          initial={{ scale: 0 }}
          animate={{ scale: 1 }}
          transition={{ type: "spring", stiffness: 300, damping: 20 }}
        >
          <motion.path
            d="M5 13l4 4L19 7"
            stroke="currentColor"
            strokeWidth={3}
            strokeLinecap="round"
            strokeLinejoin="round"
            initial={{ pathLength: 0 }}
            animate={{ pathLength: 1 }}
            transition={{ duration: 0.3, delay: 0.1 }}
          />
        </motion.svg>
      )}
    </motion.div>
  );
}
