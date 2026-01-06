import { useQuery } from "@tanstack/react-query";
import { getSql } from "@/lib/db";
import type { Journey, JourneyWithDuas, JourneyDua, TimeSlot } from "@/types/habit";

// Database row types
interface DbJourney {
  id: number;
  name: string;
  slug: string;
  description: string | null;
  emoji: string | null;
  estimated_minutes: number | null;
  daily_xp: number | null;
  is_premium: boolean | null;
  is_featured: boolean | null;
  sort_order: number | null;
}

interface DbJourneyDua {
  dua_id: number;
  time_slot: string;
  sort_order: number;
  title_en: string;
  xp_value: number;
  repetitions: number;
  category_slug: string | null;
}

// Map database journey to frontend format
function mapDbJourneyToFrontend(row: DbJourney): Journey {
  return {
    id: row.id,
    name: row.name,
    slug: row.slug,
    description: row.description,
    emoji: row.emoji || "📿",
    estimatedMinutes: row.estimated_minutes || 15,
    dailyXp: row.daily_xp || 100,
    isPremium: row.is_premium || false,
    isFeatured: row.is_featured || false,
  };
}

// Map database journey dua to frontend format
function mapDbJourneyDuaToFrontend(row: DbJourneyDua): JourneyDua {
  return {
    duaId: row.dua_id,
    timeSlot: row.time_slot as TimeSlot,
    sortOrder: row.sort_order,
    title: row.title_en,
    xpValue: row.xp_value,
    repetitions: row.repetitions,
    category: row.category_slug || "morning",
  };
}

// Fetch all journeys (for journey selection screen)
export function useJourneys() {
  return useQuery({
    queryKey: ["journeys"],
    queryFn: async (): Promise<Journey[]> => {
      const sql = getSql();
      const result = await sql`
        SELECT
          id, name, slug, description, emoji,
          estimated_minutes, daily_xp, is_premium, is_featured, sort_order
        FROM journeys
        ORDER BY is_featured DESC, sort_order ASC, name ASC
      `;
      return (result as DbJourney[]).map(mapDbJourneyToFrontend);
    },
  });
}

// Fetch featured journeys only
export function useFeaturedJourneys() {
  return useQuery({
    queryKey: ["journeys", "featured"],
    queryFn: async (): Promise<Journey[]> => {
      const sql = getSql();
      const result = await sql`
        SELECT
          id, name, slug, description, emoji,
          estimated_minutes, daily_xp, is_premium, is_featured, sort_order
        FROM journeys
        WHERE is_featured = TRUE
        ORDER BY sort_order ASC
      `;
      return (result as DbJourney[]).map(mapDbJourneyToFrontend);
    },
  });
}

// Fetch single journey by ID with its duas
export function useJourneyWithDuas(journeyId: number | null) {
  return useQuery({
    queryKey: ["journeys", journeyId, "duas"],
    queryFn: async (): Promise<JourneyWithDuas | null> => {
      if (!journeyId) return null;

      const sql = getSql();

      // Fetch journey
      const journeyResult = await sql`
        SELECT
          id, name, slug, description, emoji,
          estimated_minutes, daily_xp, is_premium, is_featured
        FROM journeys
        WHERE id = ${journeyId}
      `;

      if (!journeyResult.length) return null;

      // Fetch journey duas with dua details
      const duasResult = await sql`
        SELECT
          jd.dua_id,
          jd.time_slot,
          jd.sort_order,
          d.title_en,
          d.xp_value,
          d.repetitions,
          c.slug as category_slug
        FROM journey_duas jd
        JOIN duas d ON jd.dua_id = d.id
        LEFT JOIN categories c ON d.category_id = c.id
        WHERE jd.journey_id = ${journeyId}
        ORDER BY jd.sort_order ASC
      `;

      return {
        ...mapDbJourneyToFrontend(journeyResult[0] as DbJourney),
        duas: (duasResult as DbJourneyDua[]).map(mapDbJourneyDuaToFrontend),
      };
    },
    enabled: journeyId !== null,
  });
}

// Fetch single journey by slug with its duas
export function useJourneyBySlugWithDuas(slug: string | null) {
  return useQuery({
    queryKey: ["journeys", "slug", slug, "duas"],
    queryFn: async (): Promise<JourneyWithDuas | null> => {
      if (!slug) return null;

      const sql = getSql();

      // Fetch journey by slug
      const journeyResult = await sql`
        SELECT
          id, name, slug, description, emoji,
          estimated_minutes, daily_xp, is_premium, is_featured
        FROM journeys
        WHERE slug = ${slug}
      `;

      if (!journeyResult.length) return null;

      const journey = journeyResult[0] as DbJourney;

      // Fetch journey duas with dua details
      const duasResult = await sql`
        SELECT
          jd.dua_id,
          jd.time_slot,
          jd.sort_order,
          d.title_en,
          d.xp_value,
          d.repetitions,
          c.slug as category_slug
        FROM journey_duas jd
        JOIN duas d ON jd.dua_id = d.id
        LEFT JOIN categories c ON d.category_id = c.id
        WHERE jd.journey_id = ${journey.id}
        ORDER BY jd.sort_order ASC
      `;

      return {
        ...mapDbJourneyToFrontend(journey),
        duas: (duasResult as DbJourneyDua[]).map(mapDbJourneyDuaToFrontend),
      };
    },
    enabled: slug !== null,
  });
}

// Fetch multiple journeys by ID array with their duas (for multi-journey support)
export function useJourneysWithDuas(journeyIds: number[]) {
  // Sort and create stable query key
  const sortedIds = [...journeyIds].sort((a, b) => a - b);
  const queryKey = ["journeys", "multiple", sortedIds];
  
  return useQuery({
    queryKey,
    queryFn: async (): Promise<JourneyWithDuas[]> => {
      if (!journeyIds.length) return [];

      const sql = getSql();

      // Fetch all journeys in one query
      const journeysResult = await sql`
        SELECT
          id, name, slug, description, emoji,
          estimated_minutes, daily_xp, is_premium, is_featured, sort_order
        FROM journeys
        WHERE id = ANY(${journeyIds}::int[])
        ORDER BY sort_order ASC, name ASC
      `;

      if (!journeysResult.length) return [];

      // Fetch all duas for all journeys in one query
      const duasResult = await sql`
        SELECT
          jd.journey_id,
          jd.dua_id,
          jd.time_slot,
          jd.sort_order,
          d.title_en,
          d.xp_value,
          d.repetitions,
          c.slug as category_slug
        FROM journey_duas jd
        JOIN duas d ON jd.dua_id = d.id
        LEFT JOIN categories c ON d.category_id = c.id
        WHERE jd.journey_id = ANY(${journeyIds}::int[])
        ORDER BY jd.sort_order ASC
      `;

      // Group duas by journey ID
      const duasByJourney = new Map<number, JourneyDua[]>();
      for (const row of duasResult as (DbJourneyDua & { journey_id: number })[]) {
        const journeyDuas = duasByJourney.get(row.journey_id) || [];
        journeyDuas.push(mapDbJourneyDuaToFrontend(row));
        duasByJourney.set(row.journey_id, journeyDuas);
      }

      // Combine journeys with their duas
      return (journeysResult as DbJourney[]).map((journey) => ({
        ...mapDbJourneyToFrontend(journey),
        duas: duasByJourney.get(journey.id) || [],
      }));
    },
    enabled: journeyIds.length > 0,
  });
}

// Get merged duas from multiple journeys (deduplicated by duaId)
export function useMergedJourneyDuas(journeyIds: number[]) {
  const { data: journeys, ...rest } = useJourneysWithDuas(journeyIds);

  const mergedDuas = journeys
    ? (() => {
        const duaMap = new Map<number, JourneyDua>();
        // Process in order - first journey's dua takes precedence
        for (const journey of journeys) {
          for (const dua of journey.duas) {
            if (!duaMap.has(dua.duaId)) {
              duaMap.set(dua.duaId, dua);
            }
          }
        }
        // Return sorted by time slot and sort order
        return Array.from(duaMap.values()).sort((a, b) => {
          const slotOrder = { morning: 0, anytime: 1, evening: 2 };
          const slotDiff = slotOrder[a.timeSlot] - slotOrder[b.timeSlot];
          if (slotDiff !== 0) return slotDiff;
          return a.sortOrder - b.sortOrder;
        });
      })()
    : [];

  return {
    data: mergedDuas,
    journeys,
    ...rest,
  };
}
