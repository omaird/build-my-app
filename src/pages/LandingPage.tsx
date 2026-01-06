import { Link } from "react-router-dom";
import { motion } from "framer-motion";
import { ArrowRight, BookOpen, Compass, Trophy, Heart, Sparkles, Sun } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";

const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.1,
      delayChildren: 0.2,
    },
  },
};

const itemVariants = {
  hidden: { opacity: 0, y: 20 },
  visible: {
    opacity: 1,
    y: 0,
    transition: { duration: 0.5, ease: [0.25, 0.46, 0.45, 0.94] as const },
  },
};

const features = [
  {
    icon: <img src="/daily-adkhar-icon.png" alt="Daily Adkhar" className="h-8 w-8 object-contain" />,
    title: "Daily Adkhar",
    description: "Build a consistent spiritual routine with morning and evening rememberances."
  },
  {
    icon: <BookOpen className="h-6 w-6 text-primary" />,
    title: "Dua Library",
    description: "Access a curated collection of authentic duas for every moment of your life."
  },
  {
    icon: <Compass className="h-6 w-6 text-primary" />,
    title: "Spiritual Journeys",
    description: "Embark on guided paths to deepen your connection and understanding."
  },
  {
    icon: <Trophy className="h-6 w-6 text-primary" />,
    title: "Track Progress",
    description: "Stay motivated with streaks, levels, and achievements on your journey."
  }
];

export default function LandingPage() {
  return (
    <div className="min-h-screen bg-background overflow-hidden flex flex-col">
      {/* Background pattern */}
      <div className="fixed inset-0 islamic-pattern opacity-30 pointer-events-none" />
      
      {/* Gradient overlays */}
      <div className="fixed top-0 left-0 right-0 h-32 gradient-fade-down pointer-events-none z-10" />
      <div className="fixed bottom-0 left-0 right-0 h-32 bg-gradient-to-t from-background to-transparent pointer-events-none z-10" />

      {/* Navigation */}
      <nav className="relative z-20 px-6 py-6 flex justify-between items-center max-w-7xl mx-auto w-full">
        <div className="flex items-center gap-2">
            <div className="h-10 w-10 rounded-full bg-gradient-to-br from-gold-soft/30 to-primary/20 border border-primary/20 flex items-center justify-center">
                <span className="text-xl">🤲</span>
            </div>
            <span className="font-display text-2xl font-bold text-foreground">RIZQ</span>
        </div>
        <div className="flex gap-4">
          <Link to="/signin">
            <Button variant="ghost" className="font-semibold text-muted-foreground hover:text-foreground">
              Sign In
            </Button>
          </Link>
          <Link to="/signup">
            <Button className="rounded-btn btn-gradient gap-2 shadow-lg hover:shadow-primary/25 transition-all duration-300">
              Get Started <ArrowRight className="h-4 w-4" />
            </Button>
          </Link>
        </div>
      </nav>

      {/* Hero Section */}
      <main className="flex-grow relative z-20">
        <div className="max-w-7xl mx-auto px-6 py-12 lg:py-20 grid lg:grid-cols-2 gap-12 items-center">
          
          <motion.div 
            className="space-y-8"
            variants={containerVariants}
            initial="hidden"
            animate="visible"
          >
            <motion.div variants={itemVariants} className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-primary/10 border border-primary/20 text-primary text-sm font-medium">
              <Sparkles className="h-4 w-4" />
              <span>Your Companion for Spiritual Growth</span>
            </motion.div>
            
            <motion.h1 variants={itemVariants} className="font-display text-5xl lg:text-7xl font-bold leading-tight text-foreground">
              Connect with your <span className="text-transparent bg-clip-text bg-gradient-to-r from-primary to-gold-soft">Creator</span> Daily
            </motion.h1>
            
            <motion.p variants={itemVariants} className="text-xl text-muted-foreground leading-relaxed max-w-lg">
              Cultivate a habit of remembrance through daily adkhar, authentic duas, and guided spiritual journeys designed for the modern believer.
            </motion.p>
            
            <motion.div variants={itemVariants} className="flex flex-col sm:flex-row gap-4">
              <Link to="/signup">
                <Button size="lg" className="w-full sm:w-auto h-14 px-8 rounded-btn btn-gradient text-lg gap-2 shadow-xl hover:shadow-primary/30 transition-all duration-300 hover:-translate-y-1">
                  Start Your Journey
                </Button>
              </Link>
              <Link to="/signin">
                <Button size="lg" variant="outline" className="w-full sm:w-auto h-14 px-8 rounded-btn border-primary/20 hover:bg-primary/5 text-lg">
                  Continue Practice
                </Button>
              </Link>
            </motion.div>

            <motion.div variants={itemVariants} className="pt-8 flex items-center gap-8 text-muted-foreground/80">
                <div className="flex -space-x-3">
                    {[1,2,3,4].map(i => (
                        <div key={i} className={`h-10 w-10 rounded-full border-2 border-background bg-secondary flex items-center justify-center overflow-hidden bg-[url('https://i.pravatar.cc/100?img=${i+10}')] bg-cover`} />
                    ))}
                    <div className="h-10 w-10 rounded-full border-2 border-background bg-secondary flex items-center justify-center text-xs font-bold text-foreground">
                        +2k
                    </div>
                </div>
                <div className="text-sm">
                    <p className="font-semibold text-foreground">Join thousands</p>
                    <p>of daily practitioners</p>
                </div>
            </motion.div>
          </motion.div>

          <motion.div 
            className="relative lg:h-[600px] flex items-center justify-center"
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.8, delay: 0.4 }}
          >
             {/* Decorative circles */}
             <div className="absolute inset-0 flex items-center justify-center">
                <div className="w-[500px] h-[500px] border border-primary/10 rounded-full animate-[spin_60s_linear_infinite]" />
                <div className="absolute w-[400px] h-[400px] border border-primary/20 rounded-full animate-[spin_40s_linear_infinite_reverse]" />
                <div className="absolute w-[300px] h-[300px] border border-gold-soft/20 rounded-full animate-[spin_20s_linear_infinite]" />
             </div>

             {/* App Preview Card (Mockup) */}
             <div className="relative z-10 w-[320px] bg-background border border-border/50 rounded-[2.5rem] shadow-2xl overflow-hidden rotate-[-6deg] hover:rotate-0 transition-transform duration-500">
                <div className="absolute top-0 inset-x-0 h-32 bg-gradient-to-b from-primary/10 to-transparent pointer-events-none" />
                <div className="p-6 space-y-6">
                    <div className="flex justify-between items-center">
                        <div>
                            <p className="text-xs text-muted-foreground">Good Morning</p>
                            <p className="font-display font-bold text-lg">Abdullah</p>
                        </div>
                        <div className="h-10 w-10 rounded-full bg-primary/10 flex items-center justify-center">
                            <span className="text-lg">🧔</span>
                        </div>
                    </div>

                    <Card className="bg-primary text-primary-foreground border-none shadow-lg">
                        <CardContent className="p-4 flex items-center gap-4">
                            <div className="h-12 w-12 rounded-full bg-white/20 flex items-center justify-center backdrop-blur-sm">
                                <span className="text-xl">🔥</span>
                            </div>
                            <div>
                                <p className="font-bold text-lg">12 Day Streak</p>
                                <p className="text-primary-foreground/80 text-xs">Keep it up!</p>
                            </div>
                        </CardContent>
                    </Card>

                    <div className="space-y-3">
                        <p className="font-semibold text-sm text-muted-foreground uppercase tracking-wider">Today's Goals</p>
                        {[
                            { title: "Morning Adkhar", time: "10 mins", done: true },
                            { title: "Surah Al-Kahf", time: "25 mins", done: false },
                            { title: "Evening Adkhar", time: "10 mins", done: false }
                        ].map((item, i) => (
                            <div key={i} className="flex items-center gap-3 p-3 rounded-xl bg-secondary/50 border border-border/50">
                                <div className={`h-6 w-6 rounded-full border-2 flex items-center justify-center ${item.done ? 'bg-primary border-primary' : 'border-muted-foreground/30'}`}>
                                    {item.done && <span className="text-white text-xs">✓</span>}
                                </div>
                                <div className="flex-1">
                                    <p className={`font-medium text-sm ${item.done ? 'line-through text-muted-foreground' : 'text-foreground'}`}>{item.title}</p>
                                    <p className="text-xs text-muted-foreground">{item.time}</p>
                                </div>
                            </div>
                        ))}
                    </div>
                </div>
             </div>

             {/* Floating elements */}
             <motion.div 
                className="absolute -right-4 top-20 bg-card p-4 rounded-2xl shadow-xl border border-border/50 flex items-center gap-3 z-20"
                animate={{ y: [0, -10, 0] }}
                transition={{ duration: 4, repeat: Infinity, ease: "easeInOut" }}
             >
                <div className="h-10 w-10 rounded-full bg-green-100 dark:bg-green-900/30 text-green-600 dark:text-green-400 flex items-center justify-center">
                    <Trophy className="h-5 w-5" />
                </div>
                <div>
                    <p className="font-bold text-sm">Level Up!</p>
                    <p className="text-xs text-muted-foreground">You reached Level 5</p>
                </div>
             </motion.div>

             <motion.div 
                className="absolute -left-4 bottom-32 bg-card p-4 rounded-2xl shadow-xl border border-border/50 flex items-center gap-3 z-20"
                animate={{ y: [0, 10, 0] }}
                transition={{ duration: 5, repeat: Infinity, ease: "easeInOut", delay: 1 }}
             >
                <div className="h-10 w-10 rounded-full bg-blue-100 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 flex items-center justify-center">
                    <Heart className="h-5 w-5" />
                </div>
                <div>
                    <p className="font-bold text-sm">Heart at Peace</p>
                    <p className="text-xs text-muted-foreground">Completed 500 duas</p>
                </div>
             </motion.div>

          </motion.div>
        </div>
      </main>

      {/* Features Section */}
      <section className="relative z-20 py-24 bg-secondary/30">
        <div className="max-w-7xl mx-auto px-6">
            <div className="text-center mb-16 space-y-4">
                <h2 className="font-display text-3xl md:text-4xl font-bold">Everything you need to grow</h2>
                <p className="text-muted-foreground max-w-2xl mx-auto text-lg">
                    Designed to help you build meaningful spiritual habits that last a lifetime.
                </p>
            </div>

            <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
                {features.map((feature, idx) => (
                    <Card key={idx} className="border-primary/10 hover:border-primary/30 transition-all duration-300 hover:shadow-lg bg-card/50 backdrop-blur-sm">
                        <CardContent className="p-6 space-y-4">
                            <div className="h-12 w-12 rounded-2xl bg-primary/10 flex items-center justify-center mb-4">
                                {feature.icon}
                            </div>
                            <h3 className="font-display text-xl font-bold">{feature.title}</h3>
                            <p className="text-muted-foreground text-sm leading-relaxed">
                                {feature.description}
                            </p>
                        </CardContent>
                    </Card>
                ))}
            </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="relative z-20 py-8 border-t border-border/40 bg-background/50 backdrop-blur-sm">
        <div className="max-w-7xl mx-auto px-6 flex flex-col md:flex-row justify-between items-center gap-4 text-sm text-muted-foreground">
            <p>&copy; {new Date().getFullYear()} RIZQ. All rights reserved.</p>
            <div className="flex gap-6">
                <Link to="/privacy" className="hover:text-foreground transition-colors">Privacy</Link>
                <Link to="/terms" className="hover:text-foreground transition-colors">Terms</Link>
                <Link to="/about" className="hover:text-foreground transition-colors">About</Link>
            </div>
        </div>
      </footer>
    </div>
  );
}

