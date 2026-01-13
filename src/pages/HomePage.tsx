import { Link } from "react-router-dom";
import { motion } from "framer-motion";
import { ArrowRight, User, Sparkles, Compass } from "lucide-react";
import { BottomNav } from "@/components/BottomNav";
import { StreakBadge, XpProgressBar, CircularXpProgress } from "@/components/GamificationUI";
import { WeekCalendar } from "@/components/WeekCalendar";
import { HabitsSummaryCard } from "@/components/habits/HabitsSummaryCard";
import { useAuth } from "@/contexts/AuthContext";
import { useDailyActivity } from "@/hooks/useActivity";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Avatar, AvatarImage, AvatarFallback } from "@/components/ui/avatar";

// Helper function to calculate XP progress
const getXpForLevel = (level: number): number => {
  return 50 * level * level + 50 * level;
};

const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.08,
      delayChildren: 0.1,
    },
  },
};

const itemVariants = {
  hidden: { opacity: 0, y: 20 },
  visible: {
    opacity: 1,
    y: 0,
    transition: { duration: 0.4, ease: [0.25, 0.46, 0.45, 0.94] },
  },
};

export default function HomePage() {
  const { user, profile } = useAuth();
  const { getWeekActivities, getTodayActivity } = useDailyActivity();

  // Calculate XP progress based on profile from auth context
  const getXpProgress = () => {
    const level = profile?.level ?? 1;
    const totalXp = profile?.totalXp ?? 0;
    const currentLevelXp = getXpForLevel(level - 1);
    const nextLevelXp = getXpForLevel(level);
    const progressXp = totalXp - currentLevelXp;
    const neededXp = nextLevelXp - currentLevelXp;
    return {
      current: progressXp,
      needed: neededXp,
      percentage: Math.min((progressXp / neededXp) * 100, 100),
    };
  };

  const xpProgress = getXpProgress();
  const weekActivities = getWeekActivities();
  const todayActivity = getTodayActivity();

  // Get user's first name from Google account or profile
  const getFirstName = () => {
    // Prefer Google account name, then profile display name
    const fullName = user?.name || profile?.displayName;
    if (!fullName || fullName === "Traveler") return null;
    // Extract first name (first word)
    return fullName.split(" ")[0];
  };

  const firstName = getFirstName();
  const displayName = firstName || "Traveler";

  const getGreeting = () => {
    const hour = new Date().getHours();
    if (hour < 12) return "Good morning";
    if (hour < 17) return "Good afternoon";
    return "Good evening";
  };

  // Rotating inspirational Islamic quotes about beginning and Allah
  const inspirationalQuotes = [
    "Bismillah — In the name of Allah, begin your journey",
    "Every good deed starts with intention and ends with gratitude",
    "The journey of a thousand prayers begins with a single step",
    "Trust in Allah, but tie your camel — begin with purpose",
    "With Allah's name, nothing is impossible",
    "Start each day remembering the One who gave it to you",
    "Your rizq is written — walk towards it with faith",
    "Begin with Bismillah, end with Alhamdulillah",
    "The best provision for the journey is taqwa",
    "When you call upon Allah, know that He hears you",
    "Take the first step, and Allah will guide your path",
    "Patience and prayer — your companions on this journey",
  ];

  const getInspirationalQuote = () => {
    // Rotate quotes based on current minute for gentle variety
    const minuteIndex = Math.floor(Date.now() / 60000) % inspirationalQuotes.length;
    return inspirationalQuotes[minuteIndex];
  };

  return (
    <div className="min-h-screen bg-background pb-24">
      {/* Background pattern */}
      <div className="fixed inset-0 islamic-pattern opacity-40 pointer-events-none" />

      {/* Gradient overlay at top */}
      <div className="fixed top-0 left-0 right-0 h-32 gradient-fade-down pointer-events-none z-10" />

      <motion.div
        className="relative z-20 mx-auto max-w-md px-4 pt-8"
        variants={containerVariants}
        initial="hidden"
        animate="visible"
      >
        {/* Header */}
        <motion.header
          className="mb-8 flex items-start justify-between"
          variants={itemVariants}
        >
          <div className="flex items-center gap-4">
            <Link to="/settings">
              <motion.div whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }}>
                <Avatar className="h-14 w-14 ring-2 ring-primary/20 ring-offset-2 ring-offset-background shadow-soft">
                  {user?.image && (
                    <AvatarImage src={user.image} alt={user.name || "Profile"} />
                  )}
                  <AvatarFallback className="bg-gradient-to-br from-primary/20 to-primary/10 text-primary font-display">
                    <User className="h-6 w-6" />
                  </AvatarFallback>
                </Avatar>
              </motion.div>
            </Link>
            <div>
              <p className="text-sm text-muted-foreground">{getGreeting()}</p>
              <h1 className="font-display text-2xl font-bold text-foreground">
                {displayName}
              </h1>
              <p className="text-sm text-primary/70 mt-0.5 italic">
                {getInspirationalQuote()}
              </p>
            </div>
          </div>
          <StreakBadge streak={profile?.streak ?? 0} size="md" />
        </motion.header>

        {/* Hero Stats Card */}
        <motion.div variants={itemVariants}>
          <Card className="mb-6 overflow-hidden border-2 border-primary/10 shadow-elevated">
            <div className="relative">
              {/* Pattern overlay */}
              <div className="absolute inset-0 islamic-pattern-dense opacity-30" />

              <CardContent className="relative p-5">
                <div className="flex items-center gap-6">
                  {/* Circular XP Progress */}
                  <CircularXpProgress
                    current={xpProgress.current}
                    needed={xpProgress.needed}
                    percentage={xpProgress.percentage}
                    level={profile?.level ?? 1}
                    size={90}
                  />

                  {/* Progress details */}
                  <div className="flex-1 space-y-3">
                    <div>
                      <p className="font-display text-lg font-semibold text-foreground">
                        Level {profile?.level ?? 1}
                      </p>
                      <p className="text-xs text-muted-foreground">
                        {xpProgress.current.toLocaleString()} / {xpProgress.needed.toLocaleString()} XP to next level
                      </p>
                    </div>

                    {/* Linear progress bar */}
                    <div className="h-2 w-full overflow-hidden rounded-full bg-secondary/70">
                      <motion.div
                        className="h-full rounded-full gradient-primary"
                        initial={{ width: 0 }}
                        animate={{ width: `${xpProgress.percentage}%` }}
                        transition={{ duration: 0.8, delay: 0.3 }}
                      />
                    </div>
                  </div>
                </div>
              </CardContent>
            </div>
          </Card>
        </motion.div>

        {/* Week Calendar */}
        <motion.div className="mb-6" variants={itemVariants}>
          <WeekCalendar activities={weekActivities} />
        </motion.div>

        {/* Today's Stats */}
        {todayActivity && (
          <motion.div variants={itemVariants}>
            <Card className="mb-6 border-primary/15 bg-primary/[0.03] shadow-soft">
              <CardContent className="p-4">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="font-display text-sm font-semibold text-foreground">
                      Today's Progress
                    </p>
                    <p className="text-xs text-muted-foreground mt-0.5">
                      {todayActivity.duasCompleted.length} duas completed
                    </p>
                  </div>
                  <motion.div
                    className="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-gold-soft/20 border border-gold-soft/30"
                    initial={{ scale: 0.8, opacity: 0 }}
                    animate={{ scale: 1, opacity: 1 }}
                    transition={{ delay: 0.5 }}
                  >
                    <Sparkles className="h-4 w-4 text-primary" />
                    <span className="font-display text-lg font-bold text-primary">
                      +{todayActivity.xpEarned}
                    </span>
                    <span className="text-xs text-muted-foreground">XP</span>
                  </motion.div>
                </div>
              </CardContent>
            </Card>
          </motion.div>
        )}

        {/* Daily Adkhar Summary */}
        <motion.div className="mb-6" variants={itemVariants}>
          <h2 className="mb-3 text-xs font-semibold text-muted-foreground uppercase tracking-wider">
            Daily Adkhar
          </h2>
          <HabitsSummaryCard />
        </motion.div>

        {/* Explore CTAs */}
        <motion.div className="flex gap-3" variants={itemVariants}>
          <Link to="/journeys" className="flex-1">
            <motion.div
              whileHover={{ y: -2 }}
              whileTap={{ scale: 0.98 }}
            >
              <Button className="w-full gap-2 h-12 rounded-btn btn-gradient" size="lg">
                <Compass className="h-4 w-4" />
                <span className="font-display font-semibold">Browse Journeys</span>
              </Button>
            </motion.div>
          </Link>
          <Link to="/library" className="flex-1">
            <motion.div
              whileHover={{ y: -2 }}
              whileTap={{ scale: 0.98 }}
            >
              <Button
                variant="outline"
                className="w-full gap-2 h-12 rounded-islamic border-primary/20 hover:border-primary/40 hover:bg-primary/5"
                size="lg"
              >
                <span className="font-display font-semibold">Explore All Duas</span>
                <ArrowRight className="h-4 w-4" />
              </Button>
            </motion.div>
          </Link>
        </motion.div>
      </motion.div>

      <BottomNav />
    </div>
  );
}
