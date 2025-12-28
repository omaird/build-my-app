import { JourneyCard } from "./JourneyCard";
import type { Journey } from "@/types/habit";

interface JourneyListProps {
  journeys: Journey[];
  activeJourneyId: number | null;
  onJourneySelect: (journey: Journey) => void;
}

export function JourneyList({
  journeys,
  activeJourneyId,
  onJourneySelect,
}: JourneyListProps) {
  // Separate featured and regular journeys
  const featuredJourneys = journeys.filter((j) => j.isFeatured);
  const regularJourneys = journeys.filter((j) => !j.isFeatured);

  return (
    <div className="space-y-6">
      {/* Featured journeys */}
      {featuredJourneys.length > 0 && (
        <div className="space-y-3">
          <h2 className="text-sm font-medium text-muted-foreground">
            Featured Journeys
          </h2>
          <div className="space-y-3">
            {featuredJourneys.map((journey) => (
              <JourneyCard
                key={journey.id}
                journey={journey}
                isActive={journey.id === activeJourneyId}
                onClick={() => onJourneySelect(journey)}
              />
            ))}
          </div>
        </div>
      )}

      {/* Regular journeys */}
      {regularJourneys.length > 0 && (
        <div className="space-y-3">
          <h2 className="text-sm font-medium text-muted-foreground">
            All Journeys
          </h2>
          <div className="space-y-3">
            {regularJourneys.map((journey) => (
              <JourneyCard
                key={journey.id}
                journey={journey}
                isActive={journey.id === activeJourneyId}
                onClick={() => onJourneySelect(journey)}
              />
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
