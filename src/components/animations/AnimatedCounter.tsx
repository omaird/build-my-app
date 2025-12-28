import { useEffect, useState, useRef } from "react";
import { motion, AnimatePresence, useSpring, useTransform } from "framer-motion";
import { cn } from "@/lib/utils";

interface AnimatedCounterProps {
  value: number;
  max?: number;
  size?: "sm" | "md" | "lg" | "xl";
  showProgress?: boolean;
  onTap?: () => void;
  isCompleted?: boolean;
  className?: string;
}

const sizeConfig = {
  sm: { width: 64, height: 64, fontSize: "text-2xl", strokeWidth: 3 },
  md: { width: 96, height: 96, fontSize: "text-3xl", strokeWidth: 4 },
  lg: { width: 120, height: 120, fontSize: "text-4xl", strokeWidth: 5 },
  xl: { width: 160, height: 160, fontSize: "text-5xl", strokeWidth: 6 },
};

export function AnimatedCounter({
  value,
  max = 33,
  size = "lg",
  showProgress = true,
  onTap,
  isCompleted = false,
  className,
}: AnimatedCounterProps) {
  const [prevValue, setPrevValue] = useState(value);
  const [isAnimating, setIsAnimating] = useState(false);
  const config = sizeConfig[size];
  const progress = Math.min(value / max, 1);

  // Spring animation for smooth progress
  const springProgress = useSpring(progress, {
    stiffness: 100,
    damping: 20,
  });

  const circumference = 2 * Math.PI * ((config.width - config.strokeWidth * 2) / 2);
  const strokeDashoffset = useTransform(
    springProgress,
    [0, 1],
    [circumference, 0]
  );

  useEffect(() => {
    if (value !== prevValue) {
      setIsAnimating(true);
      setPrevValue(value);
      setTimeout(() => setIsAnimating(false), 400);
    }
  }, [value, prevValue]);

  return (
    <motion.div
      className={cn(
        "relative flex items-center justify-center cursor-pointer select-none",
        className
      )}
      style={{ width: config.width, height: config.height }}
      whileTap={{ scale: 0.95 }}
      onClick={onTap}
    >
      {/* Background circle */}
      <svg
        className="absolute inset-0"
        width={config.width}
        height={config.height}
        viewBox={`0 0 ${config.width} ${config.height}`}
      >
        {/* Track */}
        <circle
          cx={config.width / 2}
          cy={config.height / 2}
          r={(config.width - config.strokeWidth * 2) / 2}
          fill="none"
          stroke="hsl(var(--secondary))"
          strokeWidth={config.strokeWidth}
        />
        {/* Progress */}
        {showProgress && (
          <motion.circle
            cx={config.width / 2}
            cy={config.height / 2}
            r={(config.width - config.strokeWidth * 2) / 2}
            fill="none"
            stroke="url(#progressGradient)"
            strokeWidth={config.strokeWidth}
            strokeLinecap="round"
            strokeDasharray={circumference}
            style={{ strokeDashoffset }}
            transform={`rotate(-90 ${config.width / 2} ${config.height / 2})`}
          />
        )}
        {/* Gradient definition */}
        <defs>
          <linearGradient id="progressGradient" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#D4A574" />
            <stop offset="100%" stopColor="#A67C52" />
          </linearGradient>
        </defs>
      </svg>

      {/* Inner circle with counter */}
      <motion.div
        className={cn(
          "absolute flex items-center justify-center rounded-full",
          "bg-card border-2 border-primary/20 shadow-inner-glow",
          isCompleted && "bg-primary/10 border-primary/30"
        )}
        style={{
          width: config.width - config.strokeWidth * 4,
          height: config.height - config.strokeWidth * 4,
        }}
        animate={isAnimating ? { scale: [1, 1.15, 1] } : {}}
        transition={{
          duration: 0.3,
          type: "spring",
          stiffness: 400,
          damping: 15,
        }}
      >
        <AnimatePresence mode="wait">
          <motion.span
            key={value}
            className={cn(
              "font-mono font-bold text-primary",
              config.fontSize
            )}
            initial={{ opacity: 0, y: 10, scale: 0.8 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: -10, scale: 0.8 }}
            transition={{ duration: 0.15 }}
          >
            {value}
          </motion.span>
        </AnimatePresence>
      </motion.div>

      {/* Tap ripple effect */}
      <AnimatePresence>
        {isAnimating && (
          <motion.div
            className="absolute inset-0 rounded-full border-2 border-primary/40"
            initial={{ scale: 1, opacity: 0.6 }}
            animate={{ scale: 1.3, opacity: 0 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.4, ease: "easeOut" }}
          />
        )}
      </AnimatePresence>
    </motion.div>
  );
}

// Simple number counter with pop animation
export function NumberPop({
  value,
  prefix = "",
  suffix = "",
  className,
}: {
  value: number;
  prefix?: string;
  suffix?: string;
  className?: string;
}) {
  const [displayValue, setDisplayValue] = useState(value);
  const [isPopping, setIsPopping] = useState(false);

  useEffect(() => {
    if (value !== displayValue) {
      setIsPopping(true);
      setDisplayValue(value);
      setTimeout(() => setIsPopping(false), 500);
    }
  }, [value, displayValue]);

  return (
    <motion.span
      className={cn("font-mono tabular-nums", className)}
      animate={isPopping ? { scale: [1, 1.2, 1] } : {}}
      transition={{ duration: 0.3, type: "spring" }}
    >
      {prefix}
      {displayValue}
      {suffix}
    </motion.span>
  );
}
