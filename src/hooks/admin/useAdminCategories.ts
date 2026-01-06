import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getSql } from '@/lib/db';
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

/**
 * Create a new category
 */
export function useCreateCategory() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (input: CategoryFormInput): Promise<AdminCategory> => {
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
