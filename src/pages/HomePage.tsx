import { Link } from "react-router-dom";
import { Sun, Moon, Sparkles, Heart, ArrowRight } from "lucide-react";
import { BottomNav } from "@/components/BottomNav";
import { StreakBadge, XpProgressBar } from "@/components/GamificationUI";
import { WeekCalendar } from "@/components/WeekCalendar";
import { useUserProfile, useDailyActivity } from "@/hooks/useUserData";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";

const quickStartOptions = [
  { path: "/practice?category=morning", icon: Sun, label: "Morning Adhkar", color: "bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300" },
  { path: "/practice?category=evening", icon: Moon, label: "Evening Adhkar", color: "bg-indigo-100 text-indigo-700 dark:bg-indigo-900/30 dark:text-indigo-300" },
  { path: "/practice?category=rizq", icon: Sparkles, label: "Rizq Duas", color: "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-300" },
  { path: "/practice?category=gratitude", icon: Heart, label: "Gratitude", color: "bg-rose-100 text-rose-700 dark:bg-rose-900/30 dark:text-rose-300" },
];

export default function HomePage() {
  const { profile, getXpProgress } = useUserProfile();
  const { getWeekActivities, getTodayActivity } = useDailyActivity();
  
  const xpProgress = getXpProgress();
  const weekActivities = getWeekActivities();
  const todayActivity = getTodayActivity();

  const getGreeting = () => {
    const hour = new Date().getHours();
    if (hour < 12) return "Good morning";
    if (hour < 17) return "Good afternoon";
    return "Good evening";
  };

  return (
    <div className="min-h-screen bg-background pb-20 islamic-pattern">
      <div className="mx-auto max-w-md px-4 pt-8">
        {/* Header */}
        <header className="mb-6 flex items-start justify-between">
          <div>
            <p className="text-sm text-muted-foreground">{getGreeting()}</p>
            <h1 className="text-2xl font-bold text-foreground">{profile.name}</h1>
          </div>
          <StreakBadge streak={profile.streak} size="md" />
        </header>

        {/* XP Progress */}
        <Card className="mb-6 card-elevated">
          <CardContent className="p-4">
            <XpProgressBar
              current={xpProgress.current}
              needed={xpProgress.needed}
              percentage={xpProgress.percentage}
              level={profile.level}
            />
          </CardContent>
        </Card>

        {/* Week Calendar */}
        <div className="mb-6">
          <h2 className="mb-3 text-sm font-medium text-muted-foreground">This Week</h2>
          <WeekCalendar activities={weekActivities} />
        </div>

        {/* Today's Stats */}
        {todayActivity && (
          <Card className="mb-6 border-primary/20 bg-primary/5">
            <CardContent className="p-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-foreground">Today's Progress</p>
                  <p className="text-xs text-muted-foreground">
                    {todayActivity.duasCompleted.length} duas completed
                  </p>
                </div>
                <div className="text-right">
                  <p className="text-lg font-bold text-primary">+{todayActivity.xpEarned}</p>
                  <p className="text-xs text-muted-foreground">XP earned</p>
                </div>
              </div>
            </CardContent>
          </Card>
        )}

        {/* Quick Start */}
        <div className="mb-6">
          <h2 className="mb-3 text-sm font-medium text-muted-foreground">Quick Start</h2>
          <div className="grid grid-cols-2 gap-3">
            {quickStartOptions.map((option) => (
              <Link key={option.path} to={option.path}>
                <Card className="card-elevated btn-tap h-full">
                  <CardContent className="flex flex-col items-center gap-2 p-4 text-center">
                    <div className={`flex h-10 w-10 items-center justify-center rounded-full ${option.color}`}>
                      <option.icon className="h-5 w-5" />
                    </div>
                    <span className="text-sm font-medium">{option.label}</span>
                  </CardContent>
                </Card>
              </Link>
            ))}
          </div>
        </div>

        {/* Continue Practice CTA */}
        <Link to="/library">
          <Button className="w-full gap-2" size="lg">
            Explore All Duas
            <ArrowRight className="h-4 w-4" />
          </Button>
        </Link>
      </div>

      <BottomNav />
    </div>
  );
}