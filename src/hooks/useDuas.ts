import { useQuery } from '@tanstack/react-query';
import { getSql, type DuaWithRelations, type Category, type Collection } from '@/lib/db';
import type { Dua, DuaCategory } from '@/types/dua';

// Map database record to frontend Dua format
function mapDbDuaToFrontend(dbDua: DuaWithRelations): Dua {
  return {
    id: String(dbDua.id),
    title: dbDua.title_en,
    arabic: dbDua.arabic_text,
    transliteration: dbDua.transliteration || '',
    translation: dbDua.translation_en || '',
    category: (dbDua.category_slug || 'morning') as DuaCategory,
    xpValue: dbDua.xp_value,
    repetitions: dbDua.repetitions,
  };
}

// Fetch all duas with their category and collection info
export function useDuas() {
  return useQuery({
    queryKey: ['duas'],
    queryFn: async (): Promise<Dua[]> => {
      const sql = getSql();
      const result = await sql`
        SELECT
          d.*,
          c.name as category_name,
          c.slug as category_slug,
          col.name as collection_name,
          col.slug as collection_slug
        FROM duas d
        LEFT JOIN categories c ON d.category_id = c.id
        LEFT JOIN collections col ON d.collection_id = col.id
        ORDER BY d.id
      `;
      return (result as DuaWithRelations[]).map(mapDbDuaToFrontend);
    },
  });
}

// Fetch a single dua by ID
export function useDua(id: number) {
  return useQuery({
    queryKey: ['duas', id],
    queryFn: async (): Promise<DuaWithRelations | null> => {
      const sql = getSql();
      const result = await sql`
        SELECT
          d.*,
          c.name as category_name,
          c.slug as category_slug,
          col.name as collection_name,
          col.slug as collection_slug
        FROM duas d
        LEFT JOIN categories c ON d.category_id = c.id
        LEFT JOIN collections col ON d.collection_id = col.id
        WHERE d.id = ${id}
      `;
      return (result[0] as DuaWithRelations) || null;
    },
    enabled: !!id,
  });
}

// Fetch duas by category slug
export function useDuasByCategory(categorySlug: string) {
  return useQuery({
    queryKey: ['duas', 'category', categorySlug],
    queryFn: async (): Promise<DuaWithRelations[]> => {
      const sql = getSql();
      const result = await sql`
        SELECT
          d.*,
          c.name as category_name,
          c.slug as category_slug,
          col.name as collection_name,
          col.slug as collection_slug
        FROM duas d
        LEFT JOIN categories c ON d.category_id = c.id
        LEFT JOIN collections col ON d.collection_id = col.id
        WHERE c.slug = ${categorySlug}
        ORDER BY d.id
      `;
      return result as DuaWithRelations[];
    },
    enabled: !!categorySlug,
  });
}

// Fetch all categories
export function useCategories() {
  return useQuery({
    queryKey: ['categories'],
    queryFn: async (): Promise<Category[]> => {
      const sql = getSql();
      const result = await sql`
        SELECT * FROM categories ORDER BY name
      `;
      return result as Category[];
    },
  });
}

// Fetch all collections
export function useCollections() {
  return useQuery({
    queryKey: ['collections'],
    queryFn: async (): Promise<Collection[]> => {
      const sql = getSql();
      const result = await sql`
        SELECT * FROM collections ORDER BY name
      `;
      return result as Collection[];
    },
  });
}
