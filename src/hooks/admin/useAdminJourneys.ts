import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  limit as fsLimit,
  orderBy,
  query as fsQuery,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore';
import { getSql } from '@/lib/db';
import { getDb, isFirestoreCutoverEnabled } from '@/lib/firebase';
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

interface FirestoreJourneyDoc {
  id?: number;
  name?: string;
  slug?: string;
  description?: string | null;
  emoji?: string | null;
  estimatedMinutes?: number | null;
  dailyXp?: number | null;
  isPremium?: boolean;
  isFeatured?: boolean;
  sortOrder?: number | null;
}

function mapFsJourneyToAdmin(
  docId: string,
  data: FirestoreJourneyDoc,
  duaCount?: number,
): AdminJourney {
  return {
    id: typeof data.id === 'number' ? data.id : Number(docId),
    name: data.name ?? '',
    slug: data.slug ?? '',
    description: data.description ?? null,
    emoji: data.emoji || '📿',
    estimatedMinutes: data.estimatedMinutes ?? 15,
    dailyXp: data.dailyXp ?? 100,
    isPremium: data.isPremium ?? false,
    isFeatured: data.isFeatured ?? false,
    sortOrder: data.sortOrder ?? 0,
    duaCount,
  };
}

async function countDuasInJourneyFirestore(journeyId: number): Promise<number> {
  const db = getDb();
  const snap = await getDocs(
    fsQuery(collection(db, 'journey_duas'), where('journeyId', '==', journeyId)),
  );
  return snap.size;
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
      if (isFirestoreCutoverEnabled()) {
        const db = getDb();
        const [jSnap, jdSnap] = await Promise.all([
          getDocs(fsQuery(collection(db, 'journeys'), orderBy('sortOrder', 'asc'))),
          getDocs(collection(db, 'journey_duas')),
        ]);

        const counts = new Map<number, number>();
        for (const d of jdSnap.docs) {
          const data = d.data() as { journeyId?: number };
          if (typeof data.journeyId === 'number') {
            counts.set(data.journeyId, (counts.get(data.journeyId) ?? 0) + 1);
          }
        }

        return jSnap.docs.map((d) => {
          const data = d.data() as FirestoreJourneyDoc;
          const id = typeof data.id === 'number' ? data.id : Number(d.id);
          return mapFsJourneyToAdmin(d.id, data, counts.get(id) ?? 0);
        });
      }

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

      if (isFirestoreCutoverEnabled()) {
        const db = getDb();
        const snap = await getDoc(doc(db, 'journeys', String(id)));
        if (!snap.exists()) return null;
        const duaCount = await countDuasInJourneyFirestore(id);
        return mapFsJourneyToAdmin(
          snap.id,
          snap.data() as FirestoreJourneyDoc,
          duaCount,
        );
      }

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

interface FirestoreJourneyDuaDoc {
  journeyId?: number;
  duaId?: number;
  timeSlot?: string;
  sortOrder?: number;
}

const TIME_SLOT_RANK: Record<TimeSlot, number> = {
  morning: 1,
  anytime: 2,
  evening: 3,
};

/**
 * Composite document ID convention for journey_duas: "{journeyId}_{duaId}".
 * Matches scripts/seed-firestore.cjs.
 */
function journeyDuaDocId(journeyId: number, duaId: number): string {
  return `${journeyId}_${duaId}`;
}

/**
 * Fetch duas assigned to a journey
 */
export function useAdminJourneyDuas(journeyId: number | null) {
  return useQuery({
    queryKey: ['admin', 'journeys', journeyId, 'duas'],
    queryFn: async (): Promise<AdminJourneyDua[]> => {
      if (!journeyId) return [];

      if (isFirestoreCutoverEnabled()) {
        const db = getDb();
        // Fetch assignments for this journey and all duas (categories joined
        // lazily by client-side lookup).
        const [jdSnap, duasSnap, catSnap] = await Promise.all([
          getDocs(
            fsQuery(
              collection(db, 'journey_duas'),
              where('journeyId', '==', journeyId),
            ),
          ),
          getDocs(collection(db, 'duas')),
          getDocs(collection(db, 'categories')),
        ]);

        const duasById = new Map<number, Record<string, unknown>>();
        for (const d of duasSnap.docs) {
          const data = d.data() as { id?: number };
          const id = typeof data.id === 'number' ? data.id : Number(d.id);
          duasById.set(id, data as Record<string, unknown>);
        }
        const catNameById = new Map<number, string>();
        for (const c of catSnap.docs) {
          const data = c.data() as { id?: number; name?: string };
          const id = typeof data.id === 'number' ? data.id : Number(c.id);
          if (typeof data.name === 'string') catNameById.set(id, data.name);
        }

        const assignments = jdSnap.docs
          .map((d) => d.data() as FirestoreJourneyDuaDoc)
          .filter((a): a is Required<FirestoreJourneyDuaDoc> =>
            typeof a.duaId === 'number' &&
            typeof a.journeyId === 'number' &&
            typeof a.timeSlot === 'string' &&
            typeof a.sortOrder === 'number'
          );

        const mapped: AdminJourneyDua[] = assignments
          .map((a) => {
            const dua = duasById.get(a.duaId) as
              | {
                  titleEn?: string;
                  arabicText?: string;
                  xpValue?: number;
                  repetitions?: number;
                  categoryId?: number;
                }
              | undefined;
            const categoryName =
              dua && typeof dua.categoryId === 'number'
                ? catNameById.get(dua.categoryId) ?? null
                : null;
            return {
              duaId: a.duaId,
              timeSlot: a.timeSlot as TimeSlot,
              sortOrder: a.sortOrder,
              titleEn: dua?.titleEn ?? '',
              arabicText: dua?.arabicText ?? '',
              xpValue: dua?.xpValue ?? 0,
              repetitions: dua?.repetitions ?? 1,
              categoryName,
            };
          })
          .sort((a, b) => {
            const slotDiff =
              (TIME_SLOT_RANK[a.timeSlot] ?? 99) -
              (TIME_SLOT_RANK[b.timeSlot] ?? 99);
            if (slotDiff !== 0) return slotDiff;
            return a.sortOrder - b.sortOrder;
          });

        return mapped;
      }

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

async function allocateNextJourneyId(): Promise<number> {
  const db = getDb();
  const snap = await getDocs(
    fsQuery(collection(db, 'journeys'), orderBy('id', 'desc'), fsLimit(1)),
  );
  const top = snap.docs[0]?.data() as FirestoreJourneyDoc | undefined;
  const currentMax = typeof top?.id === 'number' ? top.id : 0;
  return currentMax + 1;
}

/**
 * Create a new journey
 */
export function useCreateJourney() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (input: JourneyFormInput): Promise<AdminJourney> => {
      if (isFirestoreCutoverEnabled()) {
        const db = getDb();
        const nextId = await allocateNextJourneyId();
        const payload: FirestoreJourneyDoc = {
          id: nextId,
          name: input.name,
          slug: input.slug,
          description: input.description || null,
          emoji: input.emoji || '📿',
          estimatedMinutes: input.estimatedMinutes,
          dailyXp: input.dailyXp,
          isPremium: input.isPremium,
          isFeatured: input.isFeatured,
          sortOrder: input.sortOrder,
        };
        await setDoc(doc(db, 'journeys', String(nextId)), {
          ...payload,
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
        });
        return mapFsJourneyToAdmin(String(nextId), payload, 0);
      }

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
      if (isFirestoreCutoverEnabled()) {
        const db = getDb();
        const payload: FirestoreJourneyDoc = {
          name: input.name,
          slug: input.slug,
          description: input.description || null,
          emoji: input.emoji || '📿',
          estimatedMinutes: input.estimatedMinutes,
          dailyXp: input.dailyXp,
          isPremium: input.isPremium,
          isFeatured: input.isFeatured,
          sortOrder: input.sortOrder,
        };
        await updateDoc(doc(db, 'journeys', String(id)), {
          ...payload,
          updatedAt: serverTimestamp(),
        });
        const duaCount = await countDuasInJourneyFirestore(id);
        return mapFsJourneyToAdmin(String(id), { ...payload, id }, duaCount);
      }

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
      if (isFirestoreCutoverEnabled()) {
        const db = getDb();
        // Remove journey_duas associations for this journey.
        const assignmentsSnap = await getDocs(
          fsQuery(collection(db, 'journey_duas'), where('journeyId', '==', id)),
        );
        await Promise.all(
          assignmentsSnap.docs.map((d) => deleteDoc(d.ref)),
        );
        // Delete the journey doc.
        await deleteDoc(doc(db, 'journeys', String(id)));
        return;
      }

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
      if (isFirestoreCutoverEnabled()) {
        const db = getDb();
        // Composite doc id mirrors scripts/seed-firestore.cjs.
        const docId = journeyDuaDocId(assignment.journeyId, assignment.duaId);
        await setDoc(
          doc(db, 'journey_duas', docId),
          {
            journeyId: assignment.journeyId,
            duaId: assignment.duaId,
            timeSlot: assignment.timeSlot,
            sortOrder: assignment.sortOrder,
            updatedAt: serverTimestamp(),
          },
          { merge: true },
        );
        return;
      }

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
      if (isFirestoreCutoverEnabled()) {
        const db = getDb();
        const docId = journeyDuaDocId(journeyId, duaId);
        await deleteDoc(doc(db, 'journey_duas', docId));
        return;
      }

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
      if (isFirestoreCutoverEnabled()) {
        const db = getDb();
        const batch = writeBatch(db);
        for (const update of updates) {
          const ref = doc(db, 'journey_duas', journeyDuaDocId(journeyId, update.duaId));
          batch.update(ref, {
            sortOrder: update.sortOrder,
            timeSlot: update.timeSlot,
            updatedAt: serverTimestamp(),
          });
        }
        await batch.commit();
        return;
      }

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
      if (isFirestoreCutoverEnabled()) {
        const db = getDb();
        await updateDoc(doc(db, 'journeys', String(id)), {
          isFeatured,
          updatedAt: serverTimestamp(),
        });
        return;
      }

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
      if (isFirestoreCutoverEnabled()) {
        const db = getDb();
        await updateDoc(doc(db, 'journeys', String(id)), {
          isPremium,
          updatedAt: serverTimestamp(),
        });
        return;
      }

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
