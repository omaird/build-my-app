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
} from 'firebase/firestore';
import { getDb } from '@/lib/firebase';
import type { AdminCollection, CollectionFormInput } from '@/types/admin';

// =============================================================================
// MAPPERS
// =============================================================================

interface FirestoreCollectionDoc {
  id?: number;
  name?: string;
  slug?: string;
  description?: string | null;
  isPremium?: boolean;
}

function mapFsCollectionToAdmin(
  docId: string,
  data: FirestoreCollectionDoc,
  duaCount?: number,
): AdminCollection {
  return {
    id: typeof data.id === 'number' ? data.id : Number(docId),
    name: data.name ?? '',
    slug: data.slug ?? '',
    description: data.description ?? null,
    isPremium: data.isPremium ?? false,
    duaCount,
  };
}

async function countDuasInCollectionFirestore(collectionId: number): Promise<number> {
  const db = getDb();
  const snap = await getDocs(
    fsQuery(collection(db, 'duas'), where('collectionId', '==', collectionId)),
  );
  return snap.size;
}

// =============================================================================
// QUERIES
// =============================================================================

/**
 * Fetch all collections with dua counts
 */
export function useAdminCollections() {
  return useQuery({
    queryKey: ['admin', 'collections'],
    queryFn: async (): Promise<AdminCollection[]> => {
      const db = getDb();
      const [colSnap, duasSnap] = await Promise.all([
        getDocs(fsQuery(collection(db, 'collections'), orderBy('name', 'asc'))),
        getDocs(collection(db, 'duas')),
      ]);

      const counts = new Map<number, number>();
      for (const d of duasSnap.docs) {
        const data = d.data() as { collectionId?: number };
        if (typeof data.collectionId === 'number') {
          counts.set(data.collectionId, (counts.get(data.collectionId) ?? 0) + 1);
        }
      }

      return colSnap.docs.map((d) => {
        const data = d.data() as FirestoreCollectionDoc;
        const id = typeof data.id === 'number' ? data.id : Number(d.id);
        return mapFsCollectionToAdmin(d.id, data, counts.get(id) ?? 0);
      });
    },
  });
}

/**
 * Fetch a single collection by ID
 */
export function useAdminCollection(id: number | null) {
  return useQuery({
    queryKey: ['admin', 'collections', id],
    queryFn: async (): Promise<AdminCollection | null> => {
      if (!id) return null;

      const db = getDb();
      const snap = await getDoc(doc(db, 'collections', String(id)));
      if (!snap.exists()) return null;
      const data = snap.data() as FirestoreCollectionDoc;
      const duaCount = await countDuasInCollectionFirestore(id);
      return mapFsCollectionToAdmin(snap.id, data, duaCount);
    },
    enabled: id !== null,
  });
}

// =============================================================================
// MUTATIONS
// =============================================================================

async function allocateNextCollectionId(): Promise<number> {
  const db = getDb();
  const snap = await getDocs(
    fsQuery(collection(db, 'collections'), orderBy('id', 'desc'), fsLimit(1)),
  );
  const top = snap.docs[0]?.data() as FirestoreCollectionDoc | undefined;
  const currentMax = typeof top?.id === 'number' ? top.id : 0;
  return currentMax + 1;
}

/**
 * Create a new collection
 */
export function useCreateCollection() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (input: CollectionFormInput): Promise<AdminCollection> => {
      const db = getDb();
      const nextId = await allocateNextCollectionId();
      const payload: FirestoreCollectionDoc = {
        id: nextId,
        name: input.name,
        slug: input.slug,
        description: input.description || null,
        isPremium: input.isPremium,
      };
      await setDoc(doc(db, 'collections', String(nextId)), {
        ...payload,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      });
      return mapFsCollectionToAdmin(String(nextId), payload, 0);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'collections'] });
      queryClient.invalidateQueries({ queryKey: ['collections'] });
    },
  });
}

/**
 * Update an existing collection
 */
export function useUpdateCollection() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, ...input }: CollectionFormInput & { id: number }): Promise<AdminCollection> => {
      const db = getDb();
      const payload: FirestoreCollectionDoc = {
        name: input.name,
        slug: input.slug,
        description: input.description || null,
        isPremium: input.isPremium,
      };
      await updateDoc(doc(db, 'collections', String(id)), {
        ...payload,
        updatedAt: serverTimestamp(),
      });
      const duaCount = await countDuasInCollectionFirestore(id);
      return mapFsCollectionToAdmin(String(id), { ...payload, id }, duaCount);
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'collections'] });
      queryClient.invalidateQueries({ queryKey: ['admin', 'collections', variables.id] });
      queryClient.invalidateQueries({ queryKey: ['collections'] });
      queryClient.invalidateQueries({ queryKey: ['duas'] }); // Collection info shown in dua list
    },
  });
}

/**
 * Delete a collection
 * Note: Will fail if there are duas in this collection
 */
export function useDeleteCollection() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: number): Promise<void> => {
      const count = await countDuasInCollectionFirestore(id);
      if (count > 0) {
        throw new Error(
          'Cannot delete collection with existing duas. Please reassign or delete the duas first.',
        );
      }
      const db = getDb();
      await deleteDoc(doc(db, 'collections', String(id)));
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'collections'] });
      queryClient.invalidateQueries({ queryKey: ['collections'] });
    },
  });
}

/**
 * Toggle collection premium status
 */
export function useToggleCollectionPremium() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, isPremium }: { id: number; isPremium: boolean }): Promise<void> => {
      const db = getDb();
      await updateDoc(doc(db, 'collections', String(id)), {
        isPremium,
        updatedAt: serverTimestamp(),
      });
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'collections'] });
      queryClient.invalidateQueries({ queryKey: ['admin', 'collections', variables.id] });
      queryClient.invalidateQueries({ queryKey: ['collections'] });
      queryClient.invalidateQueries({ queryKey: ['duas'] });
    },
  });
}
