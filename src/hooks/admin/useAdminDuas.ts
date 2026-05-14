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
import { getDb } from '@/lib/firebase';
import type { AdminDua, DuaFormInput } from '@/types/admin';

// =============================================================================
// MAPPERS
// =============================================================================

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
      const db = getDb();
      const snap = await getDocs(
        fsQuery(collection(db, 'duas'), orderBy('id', 'desc')),
      );
      return snap.docs.map((d) =>
        mapFsDuaToAdmin(d.id, d.data() as FirestoreDuaDoc),
      );
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

      const db = getDb();
      const snap = await getDoc(doc(db, 'duas', String(id)));
      if (!snap.exists()) return null;
      return mapFsDuaToAdmin(snap.id, snap.data() as FirestoreDuaDoc);
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
      const db = getDb();
      const payload = buildFirestoreDuaPayload(input);
      await updateDoc(doc(db, 'duas', String(id)), {
        ...payload,
        updatedAt: serverTimestamp(),
      });
      return mapFsDuaToAdmin(String(id), { ...payload, id });
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
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'duas'] });
      queryClient.invalidateQueries({ queryKey: ['duas'] });
      queryClient.invalidateQueries({ queryKey: ['journeys'] });
    },
  });
}
