import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getSql } from '@/lib/db';
import type {
  AdminJourney,
  AdminJourneyRow,
  JourneyFormInput,
  JourneyDuaAssignment
} from '@/types/admin';
import type { TimeSlot } from '@/types/habit';

// =============================================================================
// MAPPERS
// =============================================================================

function mapDbJourneyToAdmin(row: AdminJourneyRow): AdminJourney {
  return {
    id: row.id,
    name: row.name,
    slug: row.slug,
    description: row.description,
    emoji: row.emoji || '📿',
    estimatedMinutes: row.estimated_minutes || 15,
    dailyXp: row.daily_xp || 100,
    isPremium: row.is_premium,
    isFeatured: row.is_featured,
    sortOrder: row.sort_order || 0,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    duaCount: row.dua_count,
  };
}

// =============================================================================
// QUERIES
// =============================================================================

/**
 * Fetch all journeys with dua counts
 */
export function useAdminJourneys() {
  return useQuery({
    queryKey: ['admin', 'journeys'],
    queryFn: async (): Promise<AdminJourney[]> => {
      const sql = getSql();
      const result = await sql`
        SELECT
          j.*,
          COUNT(jd.dua_id)::int as dua_count
        FROM journeys j
        LEFT JOIN journey_duas jd ON j.id = jd.journey_id
        GROUP BY j.id
        ORDER BY j.sort_order ASC, j.name ASC
      `;
      return (result as AdminJourneyRow[]).map(mapDbJourneyToAdmin);
    },
  });
}

/**
 * Fetch a single journey by ID
 */
export function useAdminJourney(id: number | null) {
  return useQuery({
    queryKey: ['admin', 'journeys', id],
    queryFn: async (): Promise<AdminJourney | null> => {
      if (!id) return null;
      const sql = getSql();
      const result = await sql`
        SELECT
          j.*,
          COUNT(jd.dua_id)::int as dua_count
        FROM journeys j
        LEFT JOIN journey_duas jd ON j.id = jd.journey_id
        WHERE j.id = ${id}
        GROUP BY j.id
      `;
      if (!result.length) return null;
      return mapDbJourneyToAdmin(result[0] as AdminJourneyRow);
    },
    enabled: id !== null,
  });
}

// Journey dua type for admin
export interface AdminJourneyDua {
  duaId: number;
  timeSlot: TimeSlot;
  sortOrder: number;
  titleEn: string;
  arabicText: string;
  xpValue: number;
  repetitions: number;
  categoryName: string | null;
}

interface DbJourneyDuaRow {
  dua_id: number;
  time_slot: string;
  sort_order: number;
  title_en: string;
  arabic_text: string;
  xp_value: number;
  repetitions: number;
  category_name: string | null;
}

/**
 * Fetch duas assigned to a journey
 */
export function useAdminJourneyDuas(journeyId: number | null) {
  return useQuery({
    queryKey: ['admin', 'journeys', journeyId, 'duas'],
    queryFn: async (): Promise<AdminJourneyDua[]> => {
      if (!journeyId) return [];
      const sql = getSql();
      const result = await sql`
        SELECT
          jd.dua_id,
          jd.time_slot,
          jd.sort_order,
          d.title_en,
          d.arabic_text,
          d.xp_value,
          d.repetitions,
          c.name as category_name
        FROM journey_duas jd
        JOIN duas d ON jd.dua_id = d.id
        LEFT JOIN categories c ON d.category_id = c.id
        WHERE jd.journey_id = ${journeyId}
        ORDER BY
          CASE jd.time_slot
            WHEN 'morning' THEN 1
            WHEN 'anytime' THEN 2
            WHEN 'evening' THEN 3
          END,
          jd.sort_order ASC
      `;
      return (result as DbJourneyDuaRow[]).map(row => ({
        duaId: row.dua_id,
        timeSlot: row.time_slot as TimeSlot,
        sortOrder: row.sort_order,
        titleEn: row.title_en,
        arabicText: row.arabic_text,
        xpValue: row.xp_value,
        repetitions: row.repetitions,
        categoryName: row.category_name,
      }));
    },
    enabled: journeyId !== null,
  });
}

// =============================================================================
// MUTATIONS
// =============================================================================

/**
 * Create a new journey
 */
export function useCreateJourney() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (input: JourneyFormInput): Promise<AdminJourney> => {
      const sql = getSql();
      const result = await sql`
        INSERT INTO journeys (
          name, slug, description, emoji, estimated_minutes,
          daily_xp, is_premium, is_featured, sort_order
        ) VALUES (
          ${input.name},
          ${input.slug},
          ${input.description || null},
          ${input.emoji || '📿'},
          ${input.estimatedMinutes},
          ${input.dailyXp},
          ${input.isPremium},
          ${input.isFeatured},
          ${input.sortOrder}
        )
        RETURNING *
      `;
      return mapDbJourneyToAdmin(result[0] as AdminJourneyRow);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'journeys'] });
      queryClient.invalidateQueries({ queryKey: ['journeys'] });
    },
  });
}

/**
 * Update an existing journey
 */
export function useUpdateJourney() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, ...input }: JourneyFormInput & { id: number }): Promise<AdminJourney> => {
      const sql = getSql();
      const result = await sql`
        UPDATE journeys SET
          name = ${input.name},
          slug = ${input.slug},
          description = ${input.description || null},
          emoji = ${input.emoji || '📿'},
          estimated_minutes = ${input.estimatedMinutes},
          daily_xp = ${input.dailyXp},
          is_premium = ${input.isPremium},
          is_featured = ${input.isFeatured},
          sort_order = ${input.sortOrder},
          updated_at = NOW()
        WHERE id = ${id}
        RETURNING *
      `;
      return mapDbJourneyToAdmin(result[0] as AdminJourneyRow);
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'journeys'] });
      queryClient.invalidateQueries({ queryKey: ['admin', 'journeys', variables.id] });
      queryClient.invalidateQueries({ queryKey: ['journeys'] });
    },
  });
}

/**
 * Delete a journey
 */
export function useDeleteJourney() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: number): Promise<void> => {
      const sql = getSql();
      // First remove journey_duas associations
      await sql`DELETE FROM journey_duas WHERE journey_id = ${id}`;
      // Then delete the journey
      await sql`DELETE FROM journeys WHERE id = ${id}`;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'journeys'] });
      queryClient.invalidateQueries({ queryKey: ['journeys'] });
    },
  });
}

/**
 * Assign a dua to a journey
 */
export function useAssignDuaToJourney() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (assignment: JourneyDuaAssignment): Promise<void> => {
      const sql = getSql();
      await sql`
        INSERT INTO journey_duas (journey_id, dua_id, time_slot, sort_order)
        VALUES (${assignment.journeyId}, ${assignment.duaId}, ${assignment.timeSlot}, ${assignment.sortOrder})
        ON CONFLICT (journey_id, dua_id)
        DO UPDATE SET time_slot = ${assignment.timeSlot}, sort_order = ${assignment.sortOrder}
      `;
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'journeys', variables.journeyId, 'duas'] });
      queryClient.invalidateQueries({ queryKey: ['admin', 'journeys'] });
      queryClient.invalidateQueries({ queryKey: ['journeys'] });
    },
  });
}

/**
 * Remove a dua from a journey
 */
export function useRemoveDuaFromJourney() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ journeyId, duaId }: { journeyId: number; duaId: number }): Promise<void> => {
      const sql = getSql();
      await sql`
        DELETE FROM journey_duas
        WHERE journey_id = ${journeyId} AND dua_id = ${duaId}
      `;
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'journeys', variables.journeyId, 'duas'] });
      queryClient.invalidateQueries({ queryKey: ['admin', 'journeys'] });
      queryClient.invalidateQueries({ queryKey: ['journeys'] });
    },
  });
}

/**
 * Reorder duas within a journey (batch update sort_order)
 */
export function useReorderJourneyDuas() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      journeyId,
      updates
    }: {
      journeyId: number;
      updates: Array<{ duaId: number; sortOrder: number; timeSlot: TimeSlot }>
    }): Promise<void> => {
      const sql = getSql();
      // Batch update using a transaction-like approach
      for (const update of updates) {
        await sql`
          UPDATE journey_duas
          SET sort_order = ${update.sortOrder}, time_slot = ${update.timeSlot}
          WHERE journey_id = ${journeyId} AND dua_id = ${update.duaId}
        `;
      }
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'journeys', variables.journeyId, 'duas'] });
      queryClient.invalidateQueries({ queryKey: ['journeys'] });
    },
  });
}

/**
 * Toggle journey featured status
 */
export function useToggleJourneyFeatured() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, isFeatured }: { id: number; isFeatured: boolean }): Promise<void> => {
      const sql = getSql();
      await sql`
        UPDATE journeys SET is_featured = ${isFeatured}, updated_at = NOW()
        WHERE id = ${id}
      `;
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'journeys'] });
      queryClient.invalidateQueries({ queryKey: ['admin', 'journeys', variables.id] });
      queryClient.invalidateQueries({ queryKey: ['journeys'] });
    },
  });
}

/**
 * Toggle journey premium status
 */
export function useToggleJourneyPremium() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, isPremium }: { id: number; isPremium: boolean }): Promise<void> => {
      const sql = getSql();
      await sql`
        UPDATE journeys SET is_premium = ${isPremium}, updated_at = NOW()
        WHERE id = ${id}
      `;
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'journeys'] });
      queryClient.invalidateQueries({ queryKey: ['admin', 'journeys', variables.id] });
      queryClient.invalidateQueries({ queryKey: ['journeys'] });
    },
  });
}
