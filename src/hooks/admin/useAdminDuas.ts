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
} from 'firebase/firestore';
import { getSql } from '@/lib/db';
import { getDb, isFirestoreCutoverEnabled } from '@/lib/firebase';
import type { AdminDua, AdminDuaRow, DuaFormInput } from '@/types/admin';

// =============================================================================
// MAPPERS
// =============================================================================

function mapDbDuaToAdmin(row: AdminDuaRow): AdminDua {
  return {
    id: row.id,
    categoryId: row.category_id,
    collectionId: row.collection_id,
    titleEn: row.title_en,
    titleAr: row.title_ar,
    arabicText: row.arabic_text,
    transliteration: row.transliteration,
    translationEn: row.translation_en,
    source: row.source,
    repetitions: row.repetitions,
    bestTime: row.best_time,
    difficulty: row.difficulty,
    estDurationSec: row.est_duration_sec,
    rizqBenefit: row.rizq_benefit,
    context: row.context,
    propheticContext: row.prophetic_context,
    xpValue: row.xp_value,
    audioUrl: row.audio_url,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    categoryName: row.category_name,
    categorySlug: row.category_slug,
    collectionName: row.collection_name,
    collectionSlug: row.collection_slug,
    isPremium: row.is_premium,
  };
}

// Firestore document shape — fields are camelCase per scripts/seed-firestore.cjs.
interface FirestoreDuaDoc {
  id?: number;
  categoryId?: number | null;
  collectionId?: number | null;
  titleEn?: string;
  titleAr?: string | null;
  arabicText?: string;
  transliteration?: string | null;
  translationEn?: string | null;
  source?: string | null;
  repetitions?: number;
  bestTime?: string | null;
  difficulty?: 'Beginner' | 'Intermediate' | 'Advanced' | string | null;
  estDurationSec?: number | null;
  rizqBenefit?: string | null;
  context?: string | null;
  propheticContext?: string | null;
  xpValue?: number;
  audioUrl?: string | null;
  createdAt?: unknown;
  updatedAt?: unknown;
}

function mapFsDuaToAdmin(docId: string, data: FirestoreDuaDoc): AdminDua {
  const fallbackId = Number(docId);
  // Normalise difficulty (seed data sometimes uses "beginner" lowercase).
  const rawDifficulty = data.difficulty ?? null;
  let difficulty: 'Beginner' | 'Intermediate' | 'Advanced' | null = null;
  if (typeof rawDifficulty === 'string') {
    const lower = rawDifficulty.toLowerCase();
    if (lower === 'beginner') difficulty = 'Beginner';
    else if (lower === 'intermediate') difficulty = 'Intermediate';
    else if (lower === 'advanced') difficulty = 'Advanced';
  }
  return {
    id: typeof data.id === 'number' ? data.id : fallbackId,
    categoryId: data.categoryId ?? null,
    collectionId: data.collectionId ?? null,
    titleEn: data.titleEn ?? '',
    titleAr: data.titleAr ?? null,
    arabicText: data.arabicText ?? '',
    transliteration: data.transliteration ?? null,
    translationEn: data.translationEn ?? null,
    source: data.source ?? null,
    repetitions: data.repetitions ?? 1,
    bestTime: data.bestTime ?? null,
    difficulty,
    estDurationSec: data.estDurationSec ?? null,
    rizqBenefit: data.rizqBenefit ?? null,
    context: data.context ?? null,
    propheticContext: data.propheticContext ?? null,
    xpValue: data.xpValue ?? 0,
    audioUrl: data.audioUrl ?? null,
    createdAt: '',
    updatedAt: '',
  };
}

/**
 * Build the Firestore payload from a form input. Strips undefined and converts
 * empty strings to null so that we don't accidentally store "undefined"
 * sentinel values.
 */
function buildFirestoreDuaPayload(
  input: DuaFormInput,
): Omit<FirestoreDuaDoc, 'id' | 'createdAt' | 'updatedAt'> {
  return {
    titleEn: input.titleEn,
    titleAr: input.titleAr || null,
    arabicText: input.arabicText,
    transliteration: input.transliteration || null,
    translationEn: input.translationEn || null,
    categoryId: input.categoryId,
    collectionId: input.collectionId,
    source: input.source || null,
    repetitions: input.repetitions,
    bestTime: input.bestTime || null,
    difficulty: input.difficulty,
    estDurationSec: input.estDurationSec ?? null,
    rizqBenefit: input.rizqBenefit || null,
    context: input.context || null,
    propheticContext: input.propheticContext || null,
    xpValue: input.xpValue,
    audioUrl: input.audioUrl || null,
  };
}

// =============================================================================
// QUERIES
// =============================================================================

/**
 * Fetch all duas with their category and collection info
 */
export function useAdminDuas() {
  return useQuery({
    queryKey: ['admin', 'duas'],
    queryFn: async (): Promise<AdminDua[]> => {
      if (isFirestoreCutoverEnabled()) {
        const db = getDb();
        const snap = await getDocs(
          fsQuery(collection(db, 'duas'), orderBy('id', 'desc')),
        );
        return snap.docs.map((d) =>
          mapFsDuaToAdmin(d.id, d.data() as FirestoreDuaDoc),
        );
      }

      const sql = getSql();
      const result = await sql`
        SELECT
          d.*,
          c.name as category_name,
          c.slug as category_slug,
          col.name as collection_name,
          col.slug as collection_slug,
          col.is_premium
        FROM duas d
        LEFT JOIN categories c ON d.category_id = c.id
        LEFT JOIN collections col ON d.collection_id = col.id
        ORDER BY d.id DESC
      `;
      return (result as AdminDuaRow[]).map(mapDbDuaToAdmin);
    },
  });
}

/**
 * Fetch a single dua by ID
 */
export function useAdminDua(id: number | null) {
  return useQuery({
    queryKey: ['admin', 'duas', id],
    queryFn: async (): Promise<AdminDua | null> => {
      if (!id) return null;

      if (isFirestoreCutoverEnabled()) {
        const db = getDb();
        const snap = await getDoc(doc(db, 'duas', String(id)));
        if (!snap.exists()) return null;
        return mapFsDuaToAdmin(snap.id, snap.data() as FirestoreDuaDoc);
      }

      const sql = getSql();
      const result = await sql`
        SELECT
          d.*,
          c.name as category_name,
          c.slug as category_slug,
          col.name as collection_name,
          col.slug as collection_slug,
          col.is_premium
        FROM duas d
        LEFT JOIN categories c ON d.category_id = c.id
        LEFT JOIN collections col ON d.collection_id = col.id
        WHERE d.id = ${id}
      `;
      if (!result.length) return null;
      return mapDbDuaToAdmin(result[0] as AdminDuaRow);
    },
    enabled: id !== null,
  });
}

// =============================================================================
// MUTATIONS
// =============================================================================

/**
 * Allocate the next integer id by reading the highest existing id and adding
 * one. For an admin-only single-editor UI this is safe; if contention ever
 * matters, wrap in runTransaction.
 */
async function allocateNextDuaId(): Promise<number> {
  const db = getDb();
  const snap = await getDocs(
    fsQuery(collection(db, 'duas'), orderBy('id', 'desc'), fsLimit(1)),
  );
  const top = snap.docs[0]?.data() as FirestoreDuaDoc | undefined;
  const currentMax = typeof top?.id === 'number' ? top.id : 0;
  return currentMax + 1;
}

/**
 * Create a new dua
 */
export function useCreateDua() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (input: DuaFormInput): Promise<AdminDua> => {
      if (isFirestoreCutoverEnabled()) {
        const db = getDb();
        const nextId = await allocateNextDuaId();
        const payload = buildFirestoreDuaPayload(input);
        await setDoc(doc(db, 'duas', String(nextId)), {
          ...payload,
          id: nextId,
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
        });
        return mapFsDuaToAdmin(String(nextId), {
          ...payload,
          id: nextId,
        });
      }

      const sql = getSql();
      const result = await sql`
        INSERT INTO duas (
          title_en, title_ar, arabic_text, transliteration, translation_en,
          category_id, collection_id, source, repetitions, best_time,
          difficulty, est_duration_sec, rizq_benefit, context, prophetic_context,
          xp_value, audio_url
        ) VALUES (
          ${input.titleEn},
          ${input.titleAr || null},
          ${input.arabicText},
          ${input.transliteration || null},
          ${input.translationEn || null},
          ${input.categoryId},
          ${input.collectionId},
          ${input.source || null},
          ${input.repetitions},
          ${input.bestTime || null},
          ${input.difficulty},
          ${input.estDurationSec || null},
          ${input.rizqBenefit || null},
          ${input.context || null},
          ${input.propheticContext || null},
          ${input.xpValue},
          ${input.audioUrl || null}
        )
        RETURNING *
      `;
      return mapDbDuaToAdmin(result[0] as AdminDuaRow);
    },
    onSuccess: () => {
      // Invalidate both admin and public dua queries
      queryClient.invalidateQueries({ queryKey: ['admin', 'duas'] });
      queryClient.invalidateQueries({ queryKey: ['duas'] });
    },
  });
}

/**
 * Update an existing dua
 */
export function useUpdateDua() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, ...input }: DuaFormInput & { id: number }): Promise<AdminDua> => {
      if (isFirestoreCutoverEnabled()) {
        const db = getDb();
        const payload = buildFirestoreDuaPayload(input);
        await updateDoc(doc(db, 'duas', String(id)), {
          ...payload,
          updatedAt: serverTimestamp(),
        });
        return mapFsDuaToAdmin(String(id), { ...payload, id });
      }

      const sql = getSql();
      const result = await sql`
        UPDATE duas SET
          title_en = ${input.titleEn},
          title_ar = ${input.titleAr || null},
          arabic_text = ${input.arabicText},
          transliteration = ${input.transliteration || null},
          translation_en = ${input.translationEn || null},
          category_id = ${input.categoryId},
          collection_id = ${input.collectionId},
          source = ${input.source || null},
          repetitions = ${input.repetitions},
          best_time = ${input.bestTime || null},
          difficulty = ${input.difficulty},
          est_duration_sec = ${input.estDurationSec || null},
          rizq_benefit = ${input.rizqBenefit || null},
          context = ${input.context || null},
          prophetic_context = ${input.propheticContext || null},
          xp_value = ${input.xpValue},
          audio_url = ${input.audioUrl || null},
          updated_at = NOW()
        WHERE id = ${id}
        RETURNING *
      `;
      return mapDbDuaToAdmin(result[0] as AdminDuaRow);
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'duas'] });
      queryClient.invalidateQueries({ queryKey: ['admin', 'duas', variables.id] });
      queryClient.invalidateQueries({ queryKey: ['duas'] });
    },
  });
}

/**
 * Delete a dua
 */
export function useDeleteDua() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: number): Promise<void> => {
      if (isFirestoreCutoverEnabled()) {
        const db = getDb();
        // 1) Remove any journey_duas assignments that reference this dua.
        // journey_duas docs use composite IDs like "{journeyId}_{duaId}" per
        // scripts/seed-firestore.cjs — but to be robust against historical
        // documents that may not follow that convention, query by duaId field.
        const assignmentsSnap = await getDocs(
          fsQuery(collection(db, 'journey_duas')),
        );
        const toDelete = assignmentsSnap.docs.filter(
          (d) => (d.data() as { duaId?: number }).duaId === id,
        );
        await Promise.all(toDelete.map((d) => deleteDoc(d.ref)));

        // 2) Remove user_progress is owned per-user and gated by rules; we do
        // NOT attempt to delete those from the admin client. User-scoped
        // progress will simply orphan, which is acceptable for now.

        // 3) Delete the dua itself.
        await deleteDoc(doc(db, 'duas', String(id)));
        return;
      }

      const sql = getSql();
      // First remove from journey_duas
      await sql`DELETE FROM journey_duas WHERE dua_id = ${id}`;
      // Then remove from user_progress
      await sql`DELETE FROM user_progress WHERE dua_id = ${id}`;
      // Then delete the dua
      await sql`DELETE FROM duas WHERE id = ${id}`;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'duas'] });
      queryClient.invalidateQueries({ queryKey: ['duas'] });
      queryClient.invalidateQueries({ queryKey: ['journeys'] });
    },
  });
}
