import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { motion } from "framer-motion";
import { ArrowLeft, Compass, Loader2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { JourneyList } from "@/components/journeys";
import { useJourneys } from "@/hooks/useJourneys";
import { useUserHabits } from "@/hooks/useUserHabits";
import type { Journey } from "@/types/habit";

const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.1,
      delayChildren: 0.1,
    },
  },
};

const itemVariants = {
  hidden: { opacity: 0, y: 20 },
  visible: {
    opacity: 1,
    y: 0,
    transition: { duration: 0.4 },
  },
};

export default function JourneysPage() {
  const navigate = useNavigate();
  const { data: journeys = [], isLoading } = useJourneys();
  const { storage, setActiveJourney } = useUserHabits();
  const [isSubmitting, setIsSubmitting] = useState(false);

  const activeJourneyId = storage.activeJourneyId
    ? parseInt(storage.activeJourneyId, 10)
    : null;

  const handleJourneySelect = async (journey: Journey) => {
    // Navigate to journey detail page
    navigate(`/journeys/${journey.slug}`);
  };

  if (isLoading) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-background">
        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          className="flex flex-col items-center gap-4"
        >
          <div className="relative">
            <Loader2 className="h-10 w-10 animate-spin text-primary" />
            <div className="absolute inset-0 rounded-full bg-primary/20 blur-xl animate-pulse" />
          </div>
          <p className="text-sm text-muted-foreground">Loading journeys...</p>
        </motion.div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background pb-20">
      {/* Background pattern */}
      <div className="fixed inset-0 islamic-pattern opacity-30 pointer-events-none" />

      {/* Gradient overlay at top */}
      <div className="fixed top-0 left-0 right-0 h-32 gradient-fade-down pointer-events-none z-10" />

      <motion.div
        className="relative mx-auto max-w-md px-4 pt-4"
        variants={containerVariants}
        initial="hidden"
        animate="visible"
      >
        {/* Header */}
        <motion.header
          className="mb-6 flex items-center gap-3"
          variants={itemVariants}
        >
          <motion.div whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }}>
            <Button
              variant="ghost"
              size="icon"
              onClick={() => navigate(-1)}
              className="shrink-0 rounded-full hover:bg-secondary"
            >
              <ArrowLeft className="h-5 w-5" />
            </Button>
          </motion.div>
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-islamic bg-primary/10">
              <Compass className="h-5 w-5 text-primary" />
            </div>
            <div>
              <h1 className="font-display text-xl font-bold text-foreground">
                Choose Your Journey
              </h1>
              <p className="text-sm text-muted-foreground">
                Select a path to build your daily dua practice
              </p>
            </div>
          </div>
        </motion.header>

        {/* Journey list */}
        <motion.div variants={itemVariants}>
          <JourneyList
            journeys={journeys}
            activeJourneyId={activeJourneyId}
            onJourneySelect={handleJourneySelect}
          />
        </motion.div>
      </motion.div>
    </div>
  );
}
