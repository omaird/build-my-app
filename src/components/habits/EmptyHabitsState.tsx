import { Link } from "react-router-dom";
import { Target, ArrowRight, Sun, Moon, Sparkles, Heart } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";

// Quick start options (same as original HomePage)
const quickStartOptions = [
  {
    path: "/practice?category=morning",
    icon: Sun,
    label: "Morning Adhkar",
    color:
      "bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300",
  },
  {
    path: "/practice?category=evening",
    icon: Moon,
    label: "Evening Adhkar",
    color:
      "bg-indigo-100 text-indigo-700 dark:bg-indigo-900/30 dark:text-indigo-300",
  },
  {
    path: "/practice?category=rizq",
    icon: Sparkles,
    label: "Rizq Duas",
    color:
      "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-300",
  },
  {
    path: "/practice?category=gratitude",
    icon: Heart,
    label: "Gratitude",
    color: "bg-rose-100 text-rose-700 dark:bg-rose-900/30 dark:text-rose-300",
  },
];

export function EmptyHabitsState() {
  return (
    <div className="space-y-6">
      {/* Journey CTA Card */}
      <Card className="border-primary/20 bg-gradient-to-br from-primary/5 to-primary/10">
        <CardContent className="p-4">
          <div className="flex items-start gap-3">
            <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-primary/10">
              <Target className="h-5 w-5 text-primary" />
            </div>
            <div className="flex-1 space-y-3">
              <div>
                <h3 className="font-semibold text-foreground">
                  Set Up Your Daily Duas
                </h3>
                <p className="text-sm text-muted-foreground">
                  Choose a journey to build your daily dua practice habit with
                  structured guidance.
                </p>
              </div>
              <Link to="/journeys">
                <Button size="sm" className="gap-1">
                  Choose a Journey
                  <ArrowRight className="h-3.5 w-3.5" />
                </Button>
              </Link>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Quick Start Section (fallback) */}
      <div>
        <h2 className="mb-3 text-sm font-medium text-muted-foreground">
          Quick Start
        </h2>
        <div className="grid grid-cols-2 gap-3">
          {quickStartOptions.map((option) => (
            <Link key={option.path} to={option.path}>
              <Card className="card-elevated btn-tap h-full">
                <CardContent className="flex flex-col items-center gap-2 p-4 text-center">
                  <div
                    className={`flex h-10 w-10 items-center justify-center rounded-full ${option.color}`}
                  >
                    <option.icon className="h-5 w-5" />
                  </div>
                  <span className="text-sm font-medium">{option.label}</span>
                </CardContent>
              </Card>
            </Link>
          ))}
        </div>
      </div>
    </div>
  );
}
