// Difficulty levels for duas
export type DuaDifficulty = 'Beginner' | 'Intermediate' | 'Advanced';

// Contextual information for a dua
export interface DuaContext {
  source: string | null;           // e.g., "Sahih Bukhari 6306"
  bestTime: string | null;         // e.g., "Morning after Fajr"
  benefits: string | null;         // Rewards/virtues from hadith
  story: string | null;            // Historical background/narrative
  propheticContext: string | null; // What the Prophet ﷺ said, when recommended, circumstances
  difficulty: DuaDifficulty | null;
  estimatedDuration: number | null; // seconds
}

export interface Dua {
  id: string;
  title: string;
  arabic: string;
  transliteration: string;
  translation: string;
  category: DuaCategory;
  xpValue: number;
  repetitions: number;
  context: DuaContext;
}

export type DuaCategory = "morning" | "evening" | "rizq" | "gratitude";

// Helper to check if dua has any displayable context
export function hasContext(dua: Dua): boolean {
  const ctx = dua.context;
  return !!(ctx.source || ctx.bestTime || ctx.benefits || ctx.story || ctx.propheticContext);
}

export interface UserProgress {
  duaId: string;
  completedCount: number;
  lastCompleted: string | null;
}

export interface DailyActivity {
  date: string;
  completed: boolean;
  duasCompleted: string[];
  xpEarned: number;
}

export interface UserProfile {
  name: string;
  streak: number;
  totalXp: number;
  level: number;
  lastActiveDate: string | null;
  createdAt: string;
}