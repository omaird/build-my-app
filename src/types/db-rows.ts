// Legacy snake_case row shapes that started life as Neon Postgres column
// projections. Firestore hooks project into these shapes so existing UI
// components keep working without a wider type refactor. Migration to
// camelCase frontend types is a separate, post-M1 task.

export interface Category {
  id: number;
  name: string;
  slug: string;
  description: string | null;
}

export interface Collection {
  id: number;
  name: string;
  slug: string;
  description: string | null;
  is_premium: boolean;
}

export interface Dua {
  id: number;
  category_id: number | null;
  collection_id: number | null;
  title_en: string;
  title_ar: string | null;
  arabic_text: string;
  transliteration: string | null;
  translation_en: string | null;
  source: string | null;
  repetitions: number;
  best_time: string | null;
  difficulty: 'Beginner' | 'Intermediate' | 'Advanced' | null;
  est_duration_sec: number | null;
  rizq_benefit: string | null;
  context: string | null;
  prophetic_context: string | null;
  xp_value: number;
  audio_url: string | null;
  created_at: string;
  updated_at: string;
}

export interface DuaWithRelations extends Dua {
  category_name?: string;
  category_slug?: string;
  collection_name?: string;
  collection_slug?: string;
}
