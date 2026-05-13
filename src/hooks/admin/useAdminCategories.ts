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
import { getSql } from '@/lib/db';
import { getDb, isFirestoreCutoverEnabled } from '@/lib/firebase';
import type { AdminCategory, AdminCategoryRow, CategoryFormInput } from '@/types/admin';

// =============================================================================
// MAPPERS
// =============================================================================

function mapDbCategoryToAdmin(row: AdminCategoryRow): AdminCategory {
  return {
    id: row.id,
    name: row.name,
    slug: row.slug,
    description: row.description,
    duaCount: row.dua_count,
  };
}

interface FirestoreCategoryDoc {
  id?: number;
  name?: string;
  slug?: string;
  description?: string | null;
}

function mapFsCategoryToAdmin(
  docId: string,
  data: FirestoreCategoryDoc,
  duaCount?: number,
): AdminCategory {
  return {
    id: typeof data.id === 'number' ? data.id : Number(docId),
    name: data.name ?? '',
    slug: data.slug ?? '',
    description: data.description ?? null,
    duaCount,
  };
}

async function countDuasInCategoryFirestore(categoryId: number): Promise<number> {
  const db = getDb();
  const snap = await getDocs(
    fsQuery(collection(db, 'duas'), where('categoryId', '==', categoryId)),
  );
  return snap.size;
}

// =============================================================================
// QUERIES
// =============================================================================

/**
 * Fetch all categories with dua counts
 */
export function useAdminCategories() {
  return useQuery({
    queryKey: ['admin', 'categories'],
    queryFn: async (): Promise<AdminCategory[]> => {
      if (isFirestoreCutoverEnabled()) {
        const db = getDb();
        const [catSnap, duasSnap] = await Promise.all([
          getDocs(fsQuery(collection(db, 'categories'), orderBy('name', 'asc'))),
          getDocs(collection(db, 'duas')),
        ]);

        // Build a count map: categoryId -> count
        const counts = new Map<number, number>();
        for (const d of duasSnap.docs) {
          const data = d.data() as { categoryId?: number };
          if (typeof data.categoryId === 'number') {
            counts.set(data.categoryId, (counts.get(data.categoryId) ?? 0) + 1);
          }
        }

        return catSnap.docs.map((d) => {
          const data = d.data() as FirestoreCategoryDoc;
          const id = typeof data.id === 'number' ? data.id : Number(d.id);
          return mapFsCategoryToAdmin(d.id, data, counts.get(id) ?? 0);
        });
      }

      const sql = getSql();
      const result = await sql`
        SELECT
          c.*,
          COUNT(d.id)::int as dua_count
        FROM categories c
        LEFT JOIN duas d ON c.id = d.category_id
        GROUP BY c.id
        ORDER BY c.name ASC
      `;
      return (result as AdminCategoryRow[]).map(mapDbCategoryToAdmin);
    },
  });
}

/**
 * Fetch a single category by ID
 */
export function useAdminCategory(id: number | null) {
  return useQuery({
    queryKey: ['admin', 'categories', id],
    queryFn: async (): Promise<AdminCategory | null> => {
      if (!id) return null;

      if (isFirestoreCutoverEnabled()) {
        const db = getDb();
        const snap = await getDoc(doc(db, 'categories', String(id)));
        if (!snap.exists()) return null;
        const data = snap.data() as FirestoreCategoryDoc;
        const duaCount = await countDuasInCategoryFirestore(id);
        return mapFsCategoryToAdmin(snap.id, data, duaCount);
      }

      const sql = getSql();
      const result = await sql`
        SELECT
          c.*,
          COUNT(d.id)::int as dua_count
        FROM categories c
        LEFT JOIN duas d ON c.id = d.category_id
        WHERE c.id = ${id}
        GROUP BY c.id
      `;
      if (!result.length) return null;
      return mapDbCategoryToAdmin(result[0] as AdminCategoryRow);
    },
    enabled: id !== null,
  });
}

// =============================================================================
// MUTATIONS
// =============================================================================

async function allocateNextCategoryId(): Promise<number> {
  const db = getDb();
  const snap = await getDocs(
    fsQuery(collection(db, 'categories'), orderBy('id', 'desc'), fsLimit(1)),
  );
  const top = snap.docs[0]?.data() as FirestoreCategoryDoc | undefined;
  const currentMax = typeof top?.id === 'number' ? top.id : 0;
  return currentMax + 1;
}

/**
 * Create a new category
 */
export function useCreateCategory() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (input: CategoryFormInput): Promise<AdminCategory> => {
      if (isFirestoreCutoverEnabled()) {
        const db = getDb();
        const nextId = await allocateNextCategoryId();
        const payload: FirestoreCategoryDoc = {
          id: nextId,
          name: input.name,
          slug: input.slug,
          description: input.description || null,
        };
        await setDoc(doc(db, 'categories', String(nextId)), {
          ...payload,
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
        });
        return mapFsCategoryToAdmin(String(nextId), payload, 0);
      }

      const sql = getSql();
      const result = await sql`
        INSERT INTO categories (name, slug, description)
        VALUES (${input.name}, ${input.slug}, ${input.description || null})
        RETURNING *
      `;
      return mapDbCategoryToAdmin(result[0] as AdminCategoryRow);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'categories'] });
      queryClient.invalidateQueries({ queryKey: ['categories'] });
    },
  });
}

/**
 * Update an existing category
 */
export function useUpdateCategory() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, ...input }: CategoryFormInput & { id: number }): Promise<AdminCategory> => {
      if (isFirestoreCutoverEnabled()) {
        const db = getDb();
        const payload: FirestoreCategoryDoc = {
          name: input.name,
          slug: input.slug,
          description: input.description || null,
        };
        await updateDoc(doc(db, 'categories', String(id)), {
          ...payload,
          updatedAt: serverTimestamp(),
        });
        const duaCount = await countDuasInCategoryFirestore(id);
        return mapFsCategoryToAdmin(String(id), { ...payload, id }, duaCount);
      }

      const sql = getSql();
      const result = await sql`
        UPDATE categories SET
          name = ${input.name},
          slug = ${input.slug},
          description = ${input.description || null}
        WHERE id = ${id}
        RETURNING *
      `;
      return mapDbCategoryToAdmin(result[0] as AdminCategoryRow);
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'categories'] });
      queryClient.invalidateQueries({ queryKey: ['admin', 'categories', variables.id] });
      queryClient.invalidateQueries({ queryKey: ['categories'] });
      queryClient.invalidateQueries({ queryKey: ['duas'] }); // Category names shown in dua list
    },
  });
}

/**
 * Delete a category
 * Note: Will fail if there are duas in this category
 */
export function useDeleteCategory() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: number): Promise<void> => {
      if (isFirestoreCutoverEnabled()) {
        const count = await countDuasInCategoryFirestore(id);
        if (count > 0) {
          throw new Error(
            'Cannot delete category with existing duas. Please reassign or delete the duas first.',
          );
        }
        const db = getDb();
        await deleteDoc(doc(db, 'categories', String(id)));
        return;
      }

      const sql = getSql();

      // Check if category has duas
      const duaCheck = await sql`
        SELECT COUNT(*)::int as count FROM duas WHERE category_id = ${id}
      `;

      if ((duaCheck[0] as { count: number }).count > 0) {
        throw new Error('Cannot delete category with existing duas. Please reassign or delete the duas first.');
      }

      await sql`DELETE FROM categories WHERE id = ${id}`;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'categories'] });
      queryClient.invalidateQueries({ queryKey: ['categories'] });
    },
  });
}
