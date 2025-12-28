import { useEffect, useState } from "react";
import { motion, AnimatePresence } from "framer-motion";

interface Particle {
  id: number;
  x: number;
  y: number;
  size: number;
  delay: number;
  duration: number;
  type: "star" | "sparkle" | "dot";
}

interface CelebrationParticlesProps {
  isActive: boolean;
  particleCount?: number;
  duration?: number;
  onComplete?: () => void;
}

const StarSVG = ({ size }: { size: number }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor">
    <path d="M12 2L14.5 9.5L22 12L14.5 14.5L12 22L9.5 14.5L2 12L9.5 9.5L12 2Z" />
  </svg>
);

const SparkleSVG = ({ size }: { size: number }) => (
  <svg width={size} height={size} viewBox="0 0 16 16" fill="currentColor">
    <path d="M8 0L9.5 6.5L16 8L9.5 9.5L8 16L6.5 9.5L0 8L6.5 6.5L8 0Z" />
  </svg>
);

export function CelebrationParticles({
  isActive,
  particleCount = 16,
  duration = 2500,
  onComplete,
}: CelebrationParticlesProps) {
  const [particles, setParticles] = useState<Particle[]>([]);

  useEffect(() => {
    if (isActive) {
      const newParticles: Particle[] = Array.from({ length: particleCount }, (_, i) => ({
        id: i,
        x: Math.random() * 100, // percentage across container
        y: 60 + Math.random() * 30, // start from bottom third
        size: 8 + Math.random() * 16,
        delay: Math.random() * 0.4,
        duration: 2 + Math.random() * 1,
        type: ["star", "sparkle", "dot"][Math.floor(Math.random() * 3)] as Particle["type"],
      }));
      setParticles(newParticles);

      const timer = setTimeout(() => {
        setParticles([]);
        onComplete?.();
      }, duration);

      return () => clearTimeout(timer);
    } else {
      setParticles([]);
    }
  }, [isActive, particleCount, duration, onComplete]);

  return (
    <AnimatePresence>
      {particles.map((particle) => (
        <motion.div
          key={particle.id}
          className="absolute pointer-events-none text-primary"
          style={{
            left: `${particle.x}%`,
            top: `${particle.y}%`,
          }}
          initial={{
            opacity: 0,
            scale: 0,
            y: 0,
            rotate: 0,
          }}
          animate={{
            opacity: [0, 1, 1, 0],
            scale: [0.5, 1.2, 1, 0.5],
            y: [-20, -80, -140, -180],
            rotate: [0, 180, 360],
            x: [0, (Math.random() - 0.5) * 60],
          }}
          exit={{ opacity: 0, scale: 0 }}
          transition={{
            duration: particle.duration,
            delay: particle.delay,
            ease: [0.25, 0.46, 0.45, 0.94],
          }}
        >
          {particle.type === "star" && <StarSVG size={particle.size} />}
          {particle.type === "sparkle" && <SparkleSVG size={particle.size * 0.8} />}
          {particle.type === "dot" && (
            <div
              className="rounded-full bg-gold-soft"
              style={{ width: particle.size * 0.5, height: particle.size * 0.5 }}
            />
          )}
        </motion.div>
      ))}
    </AnimatePresence>
  );
}
