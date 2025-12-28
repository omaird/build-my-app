import { useState, useCallback } from "react";
import { motion, AnimatePresence } from "framer-motion";

interface Ripple {
  id: number;
  x: number;
  y: number;
}

interface RippleEffectProps {
  children: React.ReactNode;
  className?: string;
  rippleColor?: string;
  disabled?: boolean;
  onClick?: (e: React.MouseEvent<HTMLDivElement>) => void;
}

export function RippleEffect({
  children,
  className = "",
  rippleColor = "rgba(212, 165, 116, 0.35)",
  disabled = false,
  onClick,
}: RippleEffectProps) {
  const [ripples, setRipples] = useState<Ripple[]>([]);

  const handleClick = useCallback(
    (e: React.MouseEvent<HTMLDivElement>) => {
      if (disabled) return;

      const rect = e.currentTarget.getBoundingClientRect();
      const x = e.clientX - rect.left;
      const y = e.clientY - rect.top;

      const newRipple: Ripple = {
        id: Date.now(),
        x,
        y,
      };

      setRipples((prev) => [...prev, newRipple]);

      // Clean up ripple after animation
      setTimeout(() => {
        setRipples((prev) => prev.filter((r) => r.id !== newRipple.id));
      }, 700);

      onClick?.(e);
    },
    [disabled, onClick]
  );

  return (
    <div
      className={`relative overflow-hidden ${className}`}
      onClick={handleClick}
    >
      {children}
      <AnimatePresence>
        {ripples.map((ripple) => (
          <motion.span
            key={ripple.id}
            className="absolute rounded-full pointer-events-none"
            style={{
              left: ripple.x,
              top: ripple.y,
              backgroundColor: rippleColor,
              transform: "translate(-50%, -50%)",
            }}
            initial={{
              width: 0,
              height: 0,
              opacity: 0.6,
            }}
            animate={{
              width: 300,
              height: 300,
              opacity: 0,
            }}
            exit={{
              opacity: 0,
            }}
            transition={{
              duration: 0.6,
              ease: [0.25, 0.46, 0.45, 0.94],
            }}
          />
        ))}
      </AnimatePresence>
    </div>
  );
}

// Hook for manual ripple control
export function useRipple() {
  const [ripples, setRipples] = useState<Ripple[]>([]);

  const triggerRipple = useCallback((x: number, y: number) => {
    const newRipple: Ripple = { id: Date.now(), x, y };
    setRipples((prev) => [...prev, newRipple]);

    setTimeout(() => {
      setRipples((prev) => prev.filter((r) => r.id !== newRipple.id));
    }, 700);
  }, []);

  const RippleContainer = useCallback(
    ({ color = "rgba(212, 165, 116, 0.35)" }: { color?: string }) => (
      <AnimatePresence>
        {ripples.map((ripple) => (
          <motion.span
            key={ripple.id}
            className="absolute rounded-full pointer-events-none"
            style={{
              left: ripple.x,
              top: ripple.y,
              backgroundColor: color,
              transform: "translate(-50%, -50%)",
            }}
            initial={{ width: 0, height: 0, opacity: 0.6 }}
            animate={{ width: 300, height: 300, opacity: 0 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.6, ease: [0.25, 0.46, 0.45, 0.94] }}
          />
        ))}
      </AnimatePresence>
    ),
    [ripples]
  );

  return { triggerRipple, RippleContainer };
}
