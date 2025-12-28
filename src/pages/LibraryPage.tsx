import { useState, useMemo } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Search, Loader2, BookOpen } from "lucide-react";
import { BottomNav } from "@/components/BottomNav";
import { DuaCard } from "@/components/DuaCard";
import { AddToAdkharSheet } from "@/components/habits/AddToAdkharSheet";
import { useDuas } from "@/hooks/useDuas";
import { useUserProgress } from "@/hooks/useActivity";
import { useUserHabits } from "@/hooks/useUserHabits";
import { Dua, DuaCategory } from "@/types/dua";
import { Input } from "@/components/ui/input";
import { cn } from "@/lib/utils";

const categories: { value: DuaCategory | "all"; label: string; emoji: string }[] = [
  { value: "all", label: "All", emoji: "📿" },
  { value: "morning", label: "Morning", emoji: "🌅" },
  { value: "evening", label: "Evening", emoji: "🌙" },
  { value: "rizq", label: "Rizq", emoji: "💫" },
  { value: "gratitude", label: "Gratitude", emoji: "🤲" },
];

const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.06,
      delayChildren: 0.1,
    },
  },
};

const itemVariants = {
  hidden: { opacity: 0, y: 15 },
  visible: {
    opacity: 1,
    y: 0,
    transition: { duration: 0.3 },
  },
};

export default function LibraryPage() {
  const [search, setSearch] = useState("");
  const [activeCategory, setActiveCategory] = useState<DuaCategory | "all">("all");
  const [addSheetOpen, setAddSheetOpen] = useState(false);
  const [selectedDua, setSelectedDua] = useState<Dua | null>(null);
  const { hasCompletedToday } = useUserProgress();
  const { todaysHabits } = useUserHabits();

  const handleAddToAdkhar = (dua: Dua) => {
    setSelectedDua(dua);
    setAddSheetOpen(true);
  };

  const isInAdkhar = (duaId: string) => todaysHabits.some((h) => h.duaId === duaId);

  // Fetch duas from Neon database
  const { data: duas = [], isLoading, error } = useDuas();

  const filteredDuas = useMemo(() => {
    return duas.filter((dua) => {
      const matchesCategory = activeCategory === "all" || dua.category === activeCategory;
      const matchesSearch =
        search === "" ||
        dua.title.toLowerCase().includes(search.toLowerCase()) ||
        dua.translation.toLowerCase().includes(search.toLowerCase());
      return matchesCategory && matchesSearch;
    });
  }, [duas, search, activeCategory]);

  return (
    <div className="min-h-screen bg-background pb-24">
      {/* Background pattern */}
      <div className="fixed inset-0 islamic-pattern opacity-30 pointer-events-none" />

      {/* Gradient overlay at top */}
      <div className="fixed top-0 left-0 right-0 h-32 gradient-fade-down pointer-events-none z-10" />

      <motion.div
        className="relative mx-auto max-w-md px-4 pt-8"
        variants={containerVariants}
        initial="hidden"
        animate="visible"
      >
        {/* Header */}
        <motion.header className="mb-6" variants={itemVariants}>
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-islamic bg-primary/10">
              <BookOpen className="h-5 w-5 text-primary" />
            </div>
            <div>
              <h1 className="font-display text-2xl font-bold text-foreground">
                Dua Library
              </h1>
              <p className="text-sm text-muted-foreground">
                {isLoading ? "Loading..." : `${duas.length} duas to practice`}
              </p>
            </div>
          </div>
        </motion.header>

        {/* Search */}
        <motion.div className="relative mb-5" variants={itemVariants}>
          <Search className="absolute left-4 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            placeholder="Search duas..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="pl-11 h-12 rounded-btn border-primary/10 bg-card/80 backdrop-blur-sm shadow-soft focus:border-primary/30 focus:ring-primary/20"
          />
        </motion.div>

        {/* Category Pills */}
        <motion.div
          className="mb-6 flex gap-2 overflow-x-auto pb-2 scrollbar-hide"
          variants={itemVariants}
        >
          {categories.map((cat, index) => (
            <motion.button
              key={cat.value}
              onClick={() => setActiveCategory(cat.value)}
              className={cn(
                "flex items-center gap-2 px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap transition-all",
                "border shadow-sm",
                activeCategory === cat.value
                  ? "bg-primary text-primary-foreground border-primary shadow-glow-primary"
                  : "bg-card text-muted-foreground border-border hover:border-primary/30 hover:text-foreground"
              )}
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
              initial={{ opacity: 0, x: -10 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: index * 0.05 }}
            >
              <span>{cat.emoji}</span>
              <span>{cat.label}</span>
            </motion.button>
          ))}
        </motion.div>

        {/* Loading State */}
        <AnimatePresence mode="wait">
          {isLoading && (
            <motion.div
              key="loading"
              className="flex flex-col items-center justify-center py-16"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
            >
              <div className="relative">
                <Loader2 className="h-10 w-10 animate-spin text-primary" />
                <div className="absolute inset-0 rounded-full bg-primary/20 blur-xl animate-pulse" />
              </div>
              <p className="mt-4 text-sm text-muted-foreground">Loading duas...</p>
            </motion.div>
          )}
        </AnimatePresence>

        {/* Error State */}
        <AnimatePresence mode="wait">
          {error && (
            <motion.div
              key="error"
              className="rounded-islamic border-2 border-destructive/30 bg-destructive/5 p-6 text-center"
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
            >
              <p className="text-sm font-medium text-destructive">Failed to load duas</p>
              <p className="mt-1 text-xs text-muted-foreground">
                {error instanceof Error ? error.message : "Unknown error"}
              </p>
            </motion.div>
          )}
        </AnimatePresence>

        {/* Dua List */}
        <AnimatePresence mode="wait">
          {!isLoading && !error && (
            <motion.div
              key="list"
              className="space-y-3"
              variants={containerVariants}
              initial="hidden"
              animate="visible"
            >
              {filteredDuas.map((dua, index) => (
                <motion.div key={dua.id} variants={itemVariants}>
                  <DuaCard
                    dua={dua}
                    isCompleted={hasCompletedToday(dua.id)}
                    isInAdkhar={isInAdkhar(dua.id)}
                    onAddToAdkhar={handleAddToAdkhar}
                    index={index}
                  />
                </motion.div>
              ))}
            </motion.div>
          )}
        </AnimatePresence>

        {/* Empty State */}
        <AnimatePresence mode="wait">
          {!isLoading && !error && filteredDuas.length === 0 && (
            <motion.div
              key="empty"
              className="flex flex-col items-center justify-center py-16 text-center"
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
            >
              <motion.div
                className="relative mb-4"
                animate={{ rotate: [0, 5, -5, 0] }}
                transition={{ duration: 3, repeat: Infinity }}
              >
                <div className="flex h-16 w-16 items-center justify-center rounded-full bg-secondary/50">
                  <BookOpen className="h-7 w-7 text-muted-foreground" />
                </div>
              </motion.div>
              <p className="font-medium text-foreground">No duas found</p>
              <p className="mt-1 text-sm text-muted-foreground">
                Try adjusting your search or category
              </p>
            </motion.div>
          )}
        </AnimatePresence>
      </motion.div>

      {/* Add to Adkhar Sheet */}
      <AddToAdkharSheet
        dua={selectedDua}
        open={addSheetOpen}
        onOpenChange={setAddSheetOpen}
      />

      <BottomNav />
    </div>
  );
}
