import { Link, useLocation } from "react-router-dom";
import { motion } from "framer-motion";
import { Home, BookOpen, Sparkles, Settings } from "lucide-react";
import { cn } from "@/lib/utils";

const navItems = [
  { path: "/", icon: Home, label: "Home" },
  { path: "/library", icon: BookOpen, label: "Library" },
  { path: "/adkhar", icon: Sparkles, label: "Adkhar" },
  { path: "/settings", icon: Settings, label: "Settings" },
];

export function BottomNav() {
  const location = useLocation();

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-50">
      {/* Gradient fade at top */}
      <div className="absolute -top-6 left-0 right-0 h-6 gradient-fade-up pointer-events-none" />

      {/* Main navigation bar */}
      <div className="relative bg-card/95 backdrop-blur-md border-t border-border/50 shadow-soft">
        {/* Subtle pattern */}
        <div className="absolute inset-0 islamic-pattern-dense opacity-20 pointer-events-none" />

        <div className="relative mx-auto flex h-[72px] max-w-md items-center justify-around px-4">
          {navItems.map((item) => {
            const isActive =
              location.pathname === item.path ||
              (item.path !== "/" && location.pathname.startsWith(item.path));

            return (
              <Link
                key={item.path}
                to={item.path}
                className="relative flex flex-col items-center gap-1 px-4 py-2"
              >
                <motion.div
                  className={cn(
                    "relative flex flex-col items-center gap-1 transition-colors",
                    isActive ? "text-primary" : "text-muted-foreground hover:text-foreground"
                  )}
                  whileTap={{ scale: 0.9 }}
                >
                  {/* Icon container */}
                  <motion.div
                    className="relative"
                    animate={isActive ? { y: -2 } : { y: 0 }}
                    transition={{ type: "spring", stiffness: 400, damping: 20 }}
                  >
                    <item.icon
                      className={cn(
                        "h-6 w-6 transition-all duration-200",
                        isActive && "drop-shadow-sm"
                      )}
                      strokeWidth={isActive ? 2.5 : 2}
                    />

                    {/* Active glow */}
                    {isActive && (
                      <motion.div
                        className="absolute inset-0 -z-10 rounded-full bg-primary/20 blur-md"
                        initial={{ opacity: 0, scale: 0.5 }}
                        animate={{ opacity: 1, scale: 1.5 }}
                        transition={{ duration: 0.3 }}
                      />
                    )}
                  </motion.div>

                  {/* Label */}
                  <span
                    className={cn(
                      "text-[10px] font-semibold tracking-wide transition-colors",
                      isActive && "text-primary"
                    )}
                  >
                    {item.label}
                  </span>

                  {/* Active indicator dot */}
                  {isActive && (
                    <motion.div
                      className="absolute -bottom-1 left-1/2 h-1 w-1 rounded-full bg-primary shadow-glow-primary"
                      initial={{ scale: 0, x: "-50%" }}
                      animate={{ scale: 1, x: "-50%" }}
                      transition={{ type: "spring", stiffness: 400, damping: 15 }}
                    />
                  )}
                </motion.div>
              </Link>
            );
          })}
        </div>

        {/* Bottom safe area for iPhone */}
        <div className="h-safe-area-inset-bottom bg-card" />
      </div>
    </nav>
  );
}
