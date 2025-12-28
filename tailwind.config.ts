import type { Config } from "tailwindcss";

export default {
  darkMode: ["class"],
  content: ["./pages/**/*.{ts,tsx}", "./components/**/*.{ts,tsx}", "./app/**/*.{ts,tsx}", "./src/**/*.{ts,tsx}"],
  prefix: "",
  theme: {
    container: {
      center: true,
      padding: "2rem",
      screens: {
        "2xl": "1400px",
      },
    },
    extend: {
      fontFamily: {
        // Refined serif for body - elegant and readable
        sans: ['Crimson Pro', 'Georgia', 'serif'],
        // Display font for headings - luxury feel
        display: ['Playfair Display', 'Georgia', 'serif'],
        // Arabic typography - enhanced Amiri with fallbacks
        arabic: ['Amiri', 'Traditional Arabic', 'serif'],
        // Mono for numbers/counters
        mono: ['JetBrains Mono', 'monospace'],
      },
      colors: {
        border: "hsl(var(--border))",
        input: "hsl(var(--input))",
        ring: "hsl(var(--ring))",
        background: "hsl(var(--background))",
        foreground: "hsl(var(--foreground))",
        primary: {
          DEFAULT: "hsl(var(--primary))",
          foreground: "hsl(var(--primary-foreground))",
        },
        secondary: {
          DEFAULT: "hsl(var(--secondary))",
          foreground: "hsl(var(--secondary-foreground))",
        },
        destructive: {
          DEFAULT: "hsl(var(--destructive))",
          foreground: "hsl(var(--destructive-foreground))",
        },
        muted: {
          DEFAULT: "hsl(var(--muted))",
          foreground: "hsl(var(--muted-foreground))",
        },
        accent: {
          DEFAULT: "hsl(var(--accent))",
          foreground: "hsl(var(--accent-foreground))",
        },
        popover: {
          DEFAULT: "hsl(var(--popover))",
          foreground: "hsl(var(--popover-foreground))",
        },
        card: {
          DEFAULT: "hsl(var(--card))",
          foreground: "hsl(var(--card-foreground))",
        },
        success: {
          DEFAULT: "hsl(var(--success))",
          foreground: "hsl(var(--success-foreground))",
        },
        sidebar: {
          DEFAULT: "hsl(var(--sidebar-background))",
          foreground: "hsl(var(--sidebar-foreground))",
          primary: "hsl(var(--sidebar-primary))",
          "primary-foreground": "hsl(var(--sidebar-primary-foreground))",
          accent: "hsl(var(--sidebar-accent))",
          "accent-foreground": "hsl(var(--sidebar-accent-foreground))",
          border: "hsl(var(--sidebar-border))",
          ring: "hsl(var(--sidebar-ring))",
        },
        // Named design tokens for direct use
        sand: {
          warm: '#D4A574',
          light: '#E6C79C',
          deep: '#A67C52',
        },
        mocha: {
          DEFAULT: '#6B4423',
          deep: '#2C2416',
        },
        cream: {
          DEFAULT: '#F5EFE7',
          warm: '#FFFCF7',
        },
        gold: {
          soft: '#E6C79C',
          bright: '#FFEBB3',
        },
        teal: {
          muted: '#5B8A8A',
          success: '#6B9B7C',
        },
        xp: "hsl(var(--xp-bar))",
        streak: "hsl(var(--streak-glow))",
        level: "hsl(var(--level-badge))",
      },
      borderRadius: {
        lg: "var(--radius)",
        md: "calc(var(--radius) - 2px)",
        sm: "calc(var(--radius) - 4px)",
        // Islamic-inspired curves
        'islamic': '20px',
        'btn': '16px',
      },
      boxShadow: {
        // Refined shadows for depth
        'soft': '0 2px 15px -3px rgba(0, 0, 0, 0.07), 0 10px 20px -2px rgba(0, 0, 0, 0.04)',
        'elevated': '0 10px 40px -10px rgba(107, 68, 35, 0.15)',
        'glow-primary': '0 0 30px rgba(212, 165, 116, 0.4)',
        'glow-gold': '0 0 40px rgba(230, 199, 156, 0.5)',
        'glow-streak': '0 0 25px rgba(230, 199, 156, 0.6)',
        'inner-glow': 'inset 0 2px 10px rgba(212, 165, 116, 0.1)',
      },
      keyframes: {
        "accordion-down": {
          from: { height: "0" },
          to: { height: "var(--radix-accordion-content-height)" },
        },
        "accordion-up": {
          from: { height: "var(--radix-accordion-content-height)" },
          to: { height: "0" },
        },
        // Tap ripple - expands outward with fade
        "ripple-expand": {
          "0%": { transform: "scale(0.8)", opacity: "0.6" },
          "100%": { transform: "scale(2)", opacity: "0" },
        },
        // Counter bounce - satisfying spring feel
        "counter-bounce": {
          "0%": { transform: "scale(1)" },
          "30%": { transform: "scale(1.25)" },
          "50%": { transform: "scale(0.95)" },
          "70%": { transform: "scale(1.05)" },
          "100%": { transform: "scale(1)" },
        },
        // Celebration particles floating up
        "float-up": {
          "0%": { transform: "translateY(0) rotate(0deg) scale(1)", opacity: "1" },
          "100%": { transform: "translateY(-120px) rotate(180deg) scale(0.5)", opacity: "0" },
        },
        // Checkmark draw animation
        "draw-check": {
          "0%": { strokeDashoffset: "100" },
          "100%": { strokeDashoffset: "0" },
        },
        // Celebration scale in
        "scale-in-bounce": {
          "0%": { transform: "scale(0)", opacity: "0" },
          "60%": { transform: "scale(1.1)", opacity: "1" },
          "100%": { transform: "scale(1)", opacity: "1" },
        },
        // Gentle pulse glow
        "pulse-glow": {
          "0%, 100%": { boxShadow: "0 0 20px rgba(212, 165, 116, 0.3)", opacity: "1" },
          "50%": { boxShadow: "0 0 40px rgba(212, 165, 116, 0.6)", opacity: "0.9" },
        },
        // Streak flame animation
        "flame-dance": {
          "0%, 100%": { transform: "translateY(0) scale(1) rotate(-2deg)" },
          "25%": { transform: "translateY(-3px) scale(1.05) rotate(2deg)" },
          "50%": { transform: "translateY(-1px) scale(1.02) rotate(-1deg)" },
          "75%": { transform: "translateY(-4px) scale(1.08) rotate(1deg)" },
        },
        // Slide up with fade
        "slide-up-fade": {
          "0%": { transform: "translateY(20px)", opacity: "0" },
          "100%": { transform: "translateY(0)", opacity: "1" },
        },
        // XP counter increment
        "xp-pop": {
          "0%": { transform: "scale(1)", color: "inherit" },
          "50%": { transform: "scale(1.2)", color: "#E6C79C" },
          "100%": { transform: "scale(1)", color: "inherit" },
        },
        // Shimmer effect for loading
        "shimmer": {
          "0%": { backgroundPosition: "-200% 0" },
          "100%": { backgroundPosition: "200% 0" },
        },
        // Gentle float for decorative elements
        "gentle-float": {
          "0%, 100%": { transform: "translateY(0)" },
          "50%": { transform: "translateY(-8px)" },
        },
        // Ring pulse for active states
        "ring-pulse": {
          "0%, 100%": { boxShadow: "0 0 0 0 rgba(212, 165, 116, 0.4)" },
          "50%": { boxShadow: "0 0 0 8px rgba(212, 165, 116, 0)" },
        },
        // Stagger fade in for lists
        "fade-in": {
          "0%": { opacity: "0", transform: "translateY(10px)" },
          "100%": { opacity: "1", transform: "translateY(0)" },
        },
        // Tap bounce
        "tap-bounce": {
          "0%, 100%": { transform: "scale(1)" },
          "50%": { transform: "scale(0.95)" },
        },
      },
      animation: {
        "accordion-down": "accordion-down 0.2s ease-out",
        "accordion-up": "accordion-up 0.2s ease-out",
        // Core interactions
        "ripple": "ripple-expand 600ms ease-out forwards",
        "counter-bounce": "counter-bounce 400ms cubic-bezier(0.68, -0.55, 0.265, 1.55)",
        "tap-bounce": "tap-bounce 150ms ease-out",
        // Celebrations
        "float-up": "float-up 2.5s ease-out forwards",
        "scale-in": "scale-in-bounce 600ms cubic-bezier(0.68, -0.55, 0.265, 1.55)",
        "draw-check": "draw-check 500ms ease-out 200ms forwards",
        // Continuous effects
        "pulse-glow": "pulse-glow 2.5s ease-in-out infinite",
        "flame": "flame-dance 2s ease-in-out infinite",
        "gentle-float": "gentle-float 4s ease-in-out infinite",
        "ring-pulse": "ring-pulse 2s ease-in-out infinite",
        "shimmer": "shimmer 2s linear infinite",
        // Transitions
        "slide-up": "slide-up-fade 400ms ease-out",
        "fade-in": "fade-in 300ms ease-out forwards",
        "xp-pop": "xp-pop 500ms ease-out",
      },
    },
  },
  plugins: [require("tailwindcss-animate")],
} satisfies Config;
