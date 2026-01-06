import { useNavigate, useParams } from "react-router-dom";
import { motion } from "framer-motion";
import { ArrowLeft, Loader2, Compass } from "lucide-react";
import { Button } from "@/components/ui/button";
import { JourneyPreview } from "@/components/journeys";
import { useJourneyBySlugWithDuas } from "@/hooks/useJourneys";
import { useUserHabits } from "@/hooks/useUserHabits";
import { toast } from "sonner";

export default function JourneyDetailPage() {
  const navigate = useNavigate();
  const { slug } = useParams<{ slug: string }>();
  const { data: journey, isLoading } = useJourneyBySlugWithDuas(slug || null);
  const { storage, addJourney, removeJourney } = useUserHabits();

  const activeJourneyIds = storage.activeJourneyIds.map((id) => parseInt(id, 10));
  const isActive = journey ? activeJourneyIds.includes(journey.id) : false;

  const handleActivate = () => {
    if (journey) {
      addJourney(String(journey.id));
      toast.success(`Added ${journey.name} journey!`, {
        description: "Your daily habits have been updated.",
      });
      navigate("/");
    }
  };

  const handleDeactivate = () => {
    if (journey) {
      removeJourney(String(journey.id));
      toast.info("Journey removed", {
        description: "This journey has been removed from your habits.",
      });
      navigate("/");
    }
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
          <p className="text-sm text-muted-foreground">Loading journey...</p>
        </motion.div>
      </div>
    );
  }

  if (!journey) {
    return (
      <div className="min-h-screen bg-background pb-20">
        {/* Background pattern */}
        <div className="fixed inset-0 islamic-pattern opacity-30 pointer-events-none" />

        <motion.div
          className="relative mx-auto max-w-md px-4 pt-4"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
        >
          <header className="mb-6 flex items-center gap-3">
            <Button
              variant="ghost"
              size="icon"
              onClick={() => navigate(-1)}
              className="shrink-0 rounded-full"
            >
              <ArrowLeft className="h-5 w-5" />
            </Button>
            <h1 className="font-display text-xl font-bold text-foreground">
              Journey Not Found
            </h1>
          </header>

          <motion.div
            className="flex flex-col items-center justify-center py-16 text-center"
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
          >
            <div className="flex h-20 w-20 items-center justify-center rounded-full bg-secondary/50 mb-4">
              <Compass className="h-9 w-9 text-muted-foreground" />
            </div>
            <p className="text-muted-foreground mb-4">
              The journey you're looking for doesn't exist.
            </p>
            <Button
              onClick={() => navigate("/journeys")}
              className="gap-2 rounded-btn"
            >
              Browse Journeys
            </Button>
          </motion.div>
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
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
      >
        {/* Header */}
        <motion.header
          className="mb-6"
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
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
        </motion.header>

        {/* Journey preview */}
        <JourneyPreview
          journey={journey}
          isActive={isActive}
          activeCount={activeJourneyIds.length}
          onActivate={handleActivate}
          onDeactivate={handleDeactivate}
        />
      </motion.div>
    </div>
  );
}
