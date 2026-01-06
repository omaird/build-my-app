import { JourneyCard } from "./JourneyCard";
import type { Journey } from "@/types/habit";

interface JourneyListProps {
  journeys: Journey[];
  activeJourneyIds: number[];
  onJourneySelect: (journey: Journey) => void;
}

export function JourneyList({
  journeys,
  activeJourneyIds,
  onJourneySelect,
}: JourneyListProps) {
  // Separate featured and regular journeys
  const featuredJourneys = journeys.filter((j) => j.isFeatured);
  const regularJourneys = journeys.filter((j) => !j.isFeatured);

  // Check if a journey is active
  const isJourneyActive = (journeyId: number) => activeJourneyIds.includes(journeyId);

  return (
    <div className="space-y-6">
      {/* Active journeys section (if any are active) */}
      {activeJourneyIds.length > 0 && (
        <div className="space-y-3">
          <h2 className="text-sm font-medium text-muted-foreground">
            Your Active Journeys ({activeJourneyIds.length})
          </h2>
          <div className="space-y-3">
            {journeys
              .filter((j) => isJourneyActive(j.id))
              .map((journey, index) => (
                <JourneyCard
                  key={journey.id}
                  journey={journey}
                  isActive={true}
                  onClick={() => onJourneySelect(journey)}
                  index={index}
                />
              ))}
          </div>
        </div>
      )}

      {/* Featured journeys (excluding active ones) */}
      {featuredJourneys.filter((j) => !isJourneyActive(j.id)).length > 0 && (
        <div className="space-y-3">
          <h2 className="text-sm font-medium text-muted-foreground">
            Featured Journeys
          </h2>
          <div className="space-y-3">
            {featuredJourneys
              .filter((j) => !isJourneyActive(j.id))
              .map((journey, index) => (
                <JourneyCard
                  key={journey.id}
                  journey={journey}
                  isActive={false}
                  onClick={() => onJourneySelect(journey)}
                  index={index}
                />
              ))}
          </div>
        </div>
      )}

      {/* Regular journeys (excluding active ones) */}
      {regularJourneys.filter((j) => !isJourneyActive(j.id)).length > 0 && (
        <div className="space-y-3">
          <h2 className="text-sm font-medium text-muted-foreground">
            All Journeys
          </h2>
          <div className="space-y-3">
            {regularJourneys
              .filter((j) => !isJourneyActive(j.id))
              .map((journey, index) => (
                <JourneyCard
                  key={journey.id}
                  journey={journey}
                  isActive={false}
                  onClick={() => onJourneySelect(journey)}
                  index={index}
                />
              ))}
          </div>
        </div>
      )}
    </div>
  );
}
