import { neon, type NeonQueryFunction } from '@neondatabase/serverless';

// Lazy initialization of the SQL client
let _sql: NeonQueryFunction<false, false> | null = null;

// Get the SQL query function (lazily initialized)
export const getSql = (): NeonQueryFunction<false, false> => {
  if (!_sql) {
    const url = import.meta.env.VITE_DATABASE_URL;
    if (!url) {
      throw new Error(
        'VITE_DATABASE_URL is not set. Please add it to your .env file.\n' +
        'Get your connection string from: https://console.neon.tech'
      );
    }
    _sql = neon(url, { disableWarningInBrowsers: true });
  }
  return _sql;
};

// Type definitions for your database tables
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
  xp_value: number;
  audio_url: string | null;
  created_at: string;
  updated_at: string;
}

// Extended Dua type with joined category and collection info
export interface DuaWithRelations extends Dua {
  category_name?: string;
  category_slug?: string;
  collection_name?: string;
  collection_slug?: string;
}
