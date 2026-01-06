import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getSql } from '@/lib/db';
import type { AdminCollection, AdminCollectionRow, CollectionFormInput } from '@/types/admin';

// =============================================================================
// MAPPERS
// =============================================================================

function mapDbCollectionToAdmin(row: AdminCollectionRow): AdminCollection {
  return {
    id: row.id,
    name: row.name,
    slug: row.slug,
    description: row.description,
    isPremium: row.is_premium,
    duaCount: row.dua_count,
  };
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
      const sql = getSql();
      const result = await sql`
        SELECT
          c.*,
          COUNT(d.id)::int as dua_count
        FROM collections c
        LEFT JOIN duas d ON c.id = d.collection_id
        GROUP BY c.id
        ORDER BY c.name ASC
      `;
      return (result as AdminCollectionRow[]).map(mapDbCollectionToAdmin);
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
      const sql = getSql();
      const result = await sql`
        SELECT
          c.*,
          COUNT(d.id)::int as dua_count
        FROM collections c
        LEFT JOIN duas d ON c.id = d.collection_id
        WHERE c.id = ${id}
        GROUP BY c.id
      `;
      if (!result.length) return null;
      return mapDbCollectionToAdmin(result[0] as AdminCollectionRow);
    },
    enabled: id !== null,
  });
}

// =============================================================================
// MUTATIONS
// =============================================================================

/**
 * Create a new collection
 */
export function useCreateCollection() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (input: CollectionFormInput): Promise<AdminCollection> => {
      const sql = getSql();
      const result = await sql`
        INSERT INTO collections (name, slug, description, is_premium)
        VALUES (${input.name}, ${input.slug}, ${input.description || null}, ${input.isPremium})
        RETURNING *
      `;
      return mapDbCollectionToAdmin(result[0] as AdminCollectionRow);
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
      const sql = getSql();
      const result = await sql`
        UPDATE collections SET
          name = ${input.name},
          slug = ${input.slug},
          description = ${input.description || null},
          is_premium = ${input.isPremium}
        WHERE id = ${id}
        RETURNING *
      `;
      return mapDbCollectionToAdmin(result[0] as AdminCollectionRow);
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
      const sql = getSql();

      // Check if collection has duas
      const duaCheck = await sql`
        SELECT COUNT(*)::int as count FROM duas WHERE collection_id = ${id}
      `;

      if ((duaCheck[0] as { count: number }).count > 0) {
        throw new Error('Cannot delete collection with existing duas. Please reassign or delete the duas first.');
      }

      await sql`DELETE FROM collections WHERE id = ${id}`;
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
      const sql = getSql();
      await sql`
        UPDATE collections SET is_premium = ${isPremium}
        WHERE id = ${id}
      `;
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'collections'] });
      queryClient.invalidateQueries({ queryKey: ['admin', 'collections', variables.id] });
      queryClient.invalidateQueries({ queryKey: ['collections'] });
      queryClient.invalidateQueries({ queryKey: ['duas'] });
    },
  });
}
