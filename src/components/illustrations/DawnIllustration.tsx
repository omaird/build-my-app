import { motion } from "framer-motion";
import { useMemo } from "react";

interface DawnIllustrationProps {
  className?: string;
}

export function DawnIllustration({ className }: DawnIllustrationProps) {
  // Generate sparkle positions
  const sparkles = useMemo(() =>
    Array.from({ length: 25 }).map((_, i) => ({
      id: i,
      cx: 50 + (Math.random() - 0.5) * 70,
      cy: 20 + Math.random() * 50,
      r: 0.5 + Math.random() * 1.2,
      delay: Math.random() * 3,
      duration: 2 + Math.random() * 2,
    })), []
  );

  return (
    <div className={className}>
      <svg
        viewBox="0 0 400 500"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        className="w-full h-full"
        style={{ filter: "drop-shadow(0 4px 20px rgba(212, 165, 116, 0.3))" }}
      >
        <defs>
          {/* Sunrise gradient */}
          <radialGradient id="sunriseGlow" cx="50%" cy="35%" r="60%" fx="50%" fy="35%">
            <stop offset="0%" stopColor="#FFE4B5" stopOpacity="1" />
            <stop offset="25%" stopColor="#FFB366" stopOpacity="0.8" />
            <stop offset="50%" stopColor="#FF9966" stopOpacity="0.5" />
            <stop offset="75%" stopColor="#E8A5C5" stopOpacity="0.3" />
            <stop offset="100%" stopColor="#B8C5E8" stopOpacity="0.1" />
          </radialGradient>

          {/* Sky gradient */}
          <linearGradient id="skyGradient" x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor="#C5B8D9" />
            <stop offset="30%" stopColor="#E8B5C5" />
            <stop offset="50%" stopColor="#FFB899" />
            <stop offset="70%" stopColor="#FFD4A8" />
            <stop offset="100%" stopColor="#FFE8C5" />
          </linearGradient>

          {/* Water gradient */}
          <linearGradient id="waterGradient" x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor="#B8D4E8" />
            <stop offset="30%" stopColor="#99C2D9" />
            <stop offset="100%" stopColor="#7AA8C2" />
          </linearGradient>

          {/* Water reflection gradient */}
          <linearGradient id="waterReflection" x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor="#FFD4A8" stopOpacity="0.6" />
            <stop offset="50%" stopColor="#FFB899" stopOpacity="0.3" />
            <stop offset="100%" stopColor="#99C2D9" stopOpacity="0" />
          </linearGradient>

          {/* Sand gradient */}
          <linearGradient id="sandGradient" x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor="#E6C79C" />
            <stop offset="100%" stopColor="#D4A574" />
          </linearGradient>

          {/* Cream background */}
          <linearGradient id="creamBg" x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor="#FDF8F0" />
            <stop offset="100%" stopColor="#F5EFE7" />
          </linearGradient>

          {/* Gold pattern stroke */}
          <linearGradient id="goldStroke" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#D4A574" />
            <stop offset="50%" stopColor="#E6C79C" />
            <stop offset="100%" stopColor="#C4956A" />
          </linearGradient>

          {/* Figure gradient */}
          <linearGradient id="figureGradient" x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor="#D4A574" />
            <stop offset="100%" stopColor="#B8956A" />
          </linearGradient>

          {/* Sun glow filter */}
          <filter id="sunGlow" x="-50%" y="-50%" width="200%" height="200%">
            <feGaussianBlur stdDeviation="8" result="blur" />
            <feComposite in="SourceGraphic" in2="blur" operator="over" />
          </filter>

          {/* Sparkle glow filter */}
          <filter id="sparkleGlow" x="-100%" y="-100%" width="300%" height="300%">
            <feGaussianBlur stdDeviation="1.5" result="blur" />
            <feComposite in="SourceGraphic" in2="blur" operator="over" />
          </filter>

          {/* Arch clip path */}
          <clipPath id="archClip">
            <path d="M80 460 L80 200 Q80 100 200 80 Q320 100 320 200 L320 460 Z" />
          </clipPath>

          {/* Islamic geometric pattern */}
          <pattern id="islamicPattern" x="0" y="0" width="40" height="40" patternUnits="userSpaceOnUse">
            <rect width="40" height="40" fill="none" />
            {/* 8-pointed star pattern */}
            <path
              d="M20 0 L23 8 L31 5 L28 13 L36 16 L28 19 L31 27 L23 24 L20 32 L17 24 L9 27 L12 19 L4 16 L12 13 L9 5 L17 8 Z"
              fill="none"
              stroke="url(#goldStroke)"
              strokeWidth="0.5"
              transform="translate(0, 4)"
            />
            {/* Interlocking circles */}
            <circle cx="0" cy="0" r="6" fill="none" stroke="url(#goldStroke)" strokeWidth="0.3" />
            <circle cx="40" cy="0" r="6" fill="none" stroke="url(#goldStroke)" strokeWidth="0.3" />
            <circle cx="0" cy="40" r="6" fill="none" stroke="url(#goldStroke)" strokeWidth="0.3" />
            <circle cx="40" cy="40" r="6" fill="none" stroke="url(#goldStroke)" strokeWidth="0.3" />
            <circle cx="20" cy="20" r="4" fill="none" stroke="url(#goldStroke)" strokeWidth="0.3" />
          </pattern>

          {/* Corner arabesque pattern */}
          <pattern id="cornerPattern" x="0" y="0" width="60" height="60" patternUnits="userSpaceOnUse">
            <path
              d="M0 30 Q15 15 30 0 M30 0 Q45 15 60 30 M60 30 Q45 45 30 60 M30 60 Q15 45 0 30"
              fill="none"
              stroke="url(#goldStroke)"
              strokeWidth="0.8"
            />
            <circle cx="30" cy="30" r="8" fill="none" stroke="url(#goldStroke)" strokeWidth="0.5" />
            <circle cx="30" cy="30" r="4" fill="none" stroke="url(#goldStroke)" strokeWidth="0.5" />
          </pattern>
        </defs>

        {/* Main background */}
        <rect width="400" height="500" fill="url(#creamBg)" />

        {/* Background Islamic pattern */}
        <rect width="400" height="500" fill="url(#islamicPattern)" opacity="0.4" />

        {/* Top left corner ornament */}
        <g opacity="0.6">
          <circle cx="0" cy="0" r="80" fill="none" stroke="url(#goldStroke)" strokeWidth="1" />
          <circle cx="0" cy="0" r="60" fill="none" stroke="url(#goldStroke)" strokeWidth="0.8" />
          <circle cx="0" cy="0" r="40" fill="none" stroke="url(#goldStroke)" strokeWidth="0.5" />
          <path d="M0 0 L80 0 A80 80 0 0 0 0 80 Z" fill="url(#cornerPattern)" opacity="0.5" />
        </g>

        {/* Top right corner ornament */}
        <g opacity="0.6" transform="translate(400, 0) scale(-1, 1)">
          <circle cx="0" cy="0" r="80" fill="none" stroke="url(#goldStroke)" strokeWidth="1" />
          <circle cx="0" cy="0" r="60" fill="none" stroke="url(#goldStroke)" strokeWidth="0.8" />
          <circle cx="0" cy="0" r="40" fill="none" stroke="url(#goldStroke)" strokeWidth="0.5" />
        </g>

        {/* Bottom left corner ornament - large rosette */}
        <g opacity="0.5" transform="translate(50, 450)">
          {[...Array(12)].map((_, i) => (
            <ellipse
              key={i}
              cx="0"
              cy="-25"
              rx="8"
              ry="25"
              fill="none"
              stroke="url(#goldStroke)"
              strokeWidth="0.6"
              transform={`rotate(${i * 30})`}
            />
          ))}
          <circle cx="0" cy="0" r="12" fill="none" stroke="url(#goldStroke)" strokeWidth="1" />
          <circle cx="0" cy="0" r="6" fill="none" stroke="url(#goldStroke)" strokeWidth="0.5" />
        </g>

        {/* Bottom right corner ornament - large rosette */}
        <g opacity="0.5" transform="translate(350, 450)">
          {[...Array(12)].map((_, i) => (
            <ellipse
              key={i}
              cx="0"
              cy="-25"
              rx="8"
              ry="25"
              fill="none"
              stroke="url(#goldStroke)"
              strokeWidth="0.6"
              transform={`rotate(${i * 30})`}
            />
          ))}
          <circle cx="0" cy="0" r="12" fill="none" stroke="url(#goldStroke)" strokeWidth="1" />
          <circle cx="0" cy="0" r="6" fill="none" stroke="url(#goldStroke)" strokeWidth="0.5" />
        </g>

        {/* Moroccan arch frame outer border */}
        <path
          d="M60 480 L60 200 Q60 80 200 50 Q340 80 340 200 L340 480"
          fill="none"
          stroke="url(#goldStroke)"
          strokeWidth="3"
        />

        {/* Arch decorative inner line */}
        <path
          d="M70 475 L70 200 Q70 90 200 65 Q330 90 330 200 L330 475"
          fill="none"
          stroke="url(#goldStroke)"
          strokeWidth="1.5"
        />

        {/* Scene inside arch (clipped) */}
        <g clipPath="url(#archClip)">
          {/* Sky */}
          <rect x="80" y="80" width="240" height="400" fill="url(#skyGradient)" />

          {/* Sunrise glow */}
          <ellipse cx="200" cy="180" rx="180" ry="120" fill="url(#sunriseGlow)" />

          {/* Sun */}
          <g filter="url(#sunGlow)">
            <motion.circle
              cx="200"
              cy="175"
              r={35}
              fill="#FFE4B5"
              initial={{ opacity: 0.9, scale: 1 }}
              animate={{
                opacity: [0.9, 1, 0.9],
                scale: [1, 1.08, 1],
              }}
              transition={{
                duration: 4,
                repeat: Infinity,
                ease: "easeInOut",
              }}
              style={{ transformOrigin: "200px 175px" }}
            />
            <circle cx="200" cy="175" r="28" fill="#FFF5E0" />
          </g>

          {/* Distant mountains/dunes */}
          <path
            d="M80 240 Q120 210 160 230 Q200 200 240 220 Q280 190 320 210 L320 260 L80 260 Z"
            fill="#C4A882"
            opacity="0.5"
          />

          {/* Mosque silhouette */}
          <g fill="#5C4A3A" opacity="0.7">
            {/* Main dome */}
            <ellipse cx="240" cy="215" rx="25" ry="18" />
            <rect x="220" y="215" width="40" height="25" />

            {/* Left minaret */}
            <rect x="175" y="195" width="8" height="45" />
            <ellipse cx="179" cy="195" rx="6" ry="4" />
            <rect x="176" y="188" width="6" height="8" />
            <ellipse cx="179" cy="185" rx="4" ry="3" />

            {/* Right minaret */}
            <rect x="270" y="200" width="7" height="40" />
            <ellipse cx="273.5" cy="200" rx="5" ry="3.5" />
            <rect x="271" y="194" width="5" height="7" />
            <ellipse cx="273.5" cy="192" rx="3.5" ry="2.5" />

            {/* Small dome */}
            <ellipse cx="200" cy="225" rx="12" ry="8" />
            <rect x="192" y="225" width="16" height="15" />
          </g>

          {/* Water */}
          <rect x="80" y="260" width="240" height="100" fill="url(#waterGradient)" />

          {/* Water reflection of sun */}
          <ellipse cx="200" cy="280" rx="60" ry="40" fill="url(#waterReflection)" />

          {/* Water ripples */}
          {[...Array(8)].map((_, i) => {
            const baseX = 100 + i * 15;
            const baseY = 270 + (i % 3) * 25;
            return (
              <motion.line
                key={i}
                x1={baseX}
                y1={baseY}
                x2={baseX + 30}
                y2={baseY}
                stroke="#FFFFFF"
                strokeWidth="1"
                strokeLinecap="round"
                initial={{ opacity: 0.3 }}
                animate={{
                  opacity: [0.3, 0.5, 0.3],
                }}
                transition={{
                  duration: 3 + i * 0.2,
                  repeat: Infinity,
                  ease: "easeInOut",
                  delay: i * 0.3,
                }}
              />
            );
          })}

          {/* Sandy shore foreground */}
          <path
            d="M80 350 Q150 340 200 355 Q250 340 320 350 L320 480 L80 480 Z"
            fill="url(#sandGradient)"
          />

          {/* Sand texture details */}
          <path
            d="M100 380 Q130 375 160 385"
            fill="none"
            stroke="#C4956A"
            strokeWidth="0.5"
            opacity="0.5"
          />
          <path
            d="M220 390 Q260 385 300 395"
            fill="none"
            stroke="#C4956A"
            strokeWidth="0.5"
            opacity="0.5"
          />

          {/* Cute meditating figure */}
          <g transform="translate(140, 360)">
            {/* Shadow */}
            <ellipse cx="30" cy="75" rx="35" ry="8" fill="#B8956A" opacity="0.3" />

            {/* Body (sitting pose) */}
            <ellipse cx="30" cy="55" rx="28" ry="22" fill="url(#figureGradient)" />

            {/* Crossed legs suggestion */}
            <ellipse cx="30" cy="70" rx="32" ry="10" fill="url(#figureGradient)" />

            {/* Head */}
            <circle cx="30" cy="22" r="22" fill="url(#figureGradient)" />

            {/* Subtle highlight on head */}
            <ellipse cx="24" cy="16" rx="8" ry="6" fill="#E6C79C" opacity="0.4" />

            {/* Arms in dua position */}
            <ellipse cx="8" cy="45" rx="8" ry="12" fill="url(#figureGradient)" transform="rotate(-20, 8, 45)" />
            <ellipse cx="52" cy="45" rx="8" ry="12" fill="url(#figureGradient)" transform="rotate(20, 52, 45)" />

            {/* Hands */}
            <circle cx="2" cy="36" r="6" fill="url(#figureGradient)" />
            <circle cx="58" cy="36" r="6" fill="url(#figureGradient)" />
          </g>

          {/* Floating sparkles */}
          {sparkles.map((sparkle) => {
            const baseCx = 80 + (sparkle.cx / 100) * 240;
            const baseCy = 80 + (sparkle.cy / 100) * 300;
            return (
              <motion.circle
                key={sparkle.id}
                cx={baseCx}
                cy={baseCy}
                r={sparkle.r}
                fill="#FFE4B5"
                filter="url(#sparkleGlow)"
                initial={{ opacity: 0 }}
                animate={{
                  opacity: [0, 1, 0],
                  y: [0, -15, 0],
                }}
                transition={{
                  duration: sparkle.duration,
                  repeat: Infinity,
                  delay: sparkle.delay,
                  ease: "easeInOut",
                }}
              />
            );
          })}
        </g>

        {/* Inner arch decorative scalloped edge */}
        <g fill="none" stroke="url(#goldStroke)" strokeWidth="1">
          {/* Left side scallops */}
          {[...Array(8)].map((_, i) => (
            <path
              key={`left-${i}`}
              d={`M75 ${200 + i * 35} Q85 ${210 + i * 35} 75 ${220 + i * 35}`}
            />
          ))}
          {/* Right side scallops */}
          {[...Array(8)].map((_, i) => (
            <path
              key={`right-${i}`}
              d={`M325 ${200 + i * 35} Q315 ${210 + i * 35} 325 ${220 + i * 35}`}
            />
          ))}
        </g>

        {/* Arch keystone decoration */}
        <g transform="translate(200, 55)">
          <path
            d="M-15 0 L0 -15 L15 0 L0 15 Z"
            fill="none"
            stroke="url(#goldStroke)"
            strokeWidth="1.5"
          />
          <circle cx="0" cy="0" r="5" fill="none" stroke="url(#goldStroke)" strokeWidth="1" />
        </g>

        {/* Side decorative medallions */}
        <g transform="translate(35, 280)">
          <circle cx="0" cy="0" r="20" fill="none" stroke="url(#goldStroke)" strokeWidth="1" />
          {[...Array(8)].map((_, i) => (
            <line
              key={i}
              x1="0"
              y1="-12"
              x2="0"
              y2="-20"
              stroke="url(#goldStroke)"
              strokeWidth="0.8"
              transform={`rotate(${i * 45})`}
            />
          ))}
          <circle cx="0" cy="0" r="8" fill="none" stroke="url(#goldStroke)" strokeWidth="0.8" />
        </g>

        <g transform="translate(365, 280)">
          <circle cx="0" cy="0" r="20" fill="none" stroke="url(#goldStroke)" strokeWidth="1" />
          {[...Array(8)].map((_, i) => (
            <line
              key={i}
              x1="0"
              y1="-12"
              x2="0"
              y2="-20"
              stroke="url(#goldStroke)"
              strokeWidth="0.8"
              transform={`rotate(${i * 45})`}
            />
          ))}
          <circle cx="0" cy="0" r="8" fill="none" stroke="url(#goldStroke)" strokeWidth="0.8" />
        </g>

        {/* Additional floating particles outside arch */}
        {useMemo(() =>
          Array.from({ length: 10 }).map((_, i) => {
            const cx = 20 + (i * 36) % 360;
            const cy = 100 + (i * 47) % 350;
            const r = 0.8 + (i % 3) * 0.4;
            return (
              <motion.circle
                key={`outer-${i}`}
                cx={cx}
                cy={cy}
                r={r}
                fill="#D4A574"
                initial={{ opacity: 0.5 }}
                animate={{
                  opacity: [0.3, 0.7, 0.3],
                  y: [0, 8, 0],
                }}
                transition={{
                  duration: 3 + (i % 3),
                  repeat: Infinity,
                  delay: i * 0.3,
                  ease: "easeInOut",
                }}
              />
            );
          }), [])}
      </svg>
    </div>
  );
}
