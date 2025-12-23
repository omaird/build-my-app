import { Link, useLocation } from "react-router-dom";
import { Home, BookOpen, Target, Settings } from "lucide-react";
import { cn } from "@/lib/utils";

const navItems = [
  { path: "/", icon: Home, label: "Home" },
  { path: "/library", icon: BookOpen, label: "Library" },
  { path: "/practice", icon: Target, label: "Practice" },
  { path: "/settings", icon: Settings, label: "Settings" },
];

export function BottomNav() {
  const location = useLocation();

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-50 border-t bg-card/95 backdrop-blur supports-[backdrop-filter]:bg-card/80">
      <div className="mx-auto flex h-16 max-w-md items-center justify-around px-4">
        {navItems.map((item) => {
          const isActive = location.pathname === item.path || 
            (item.path !== "/" && location.pathname.startsWith(item.path));
          
          return (
            <Link
              key={item.path}
              to={item.path}
              className={cn(
                "flex flex-col items-center gap-1 px-3 py-2 transition-colors btn-tap",
                isActive 
                  ? "text-primary" 
                  : "text-muted-foreground hover:text-foreground"
              )}
            >
              <item.icon 
                className={cn(
                  "h-5 w-5 transition-transform",
                  isActive && "scale-110"
                )} 
              />
              <span className="text-[10px] font-medium">{item.label}</span>
            </Link>
          );
        })}
      </div>
    </nav>
  );
}