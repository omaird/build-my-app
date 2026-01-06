import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getSql } from '@/lib/db';
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
 * Create a new dua
 */
export function useCreateDua() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (input: DuaFormInput): Promise<AdminDua> => {
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
