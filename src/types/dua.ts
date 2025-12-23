export interface Dua {
  id: string;
  title: string;
  arabic: string;
  transliteration: string;
  translation: string;
  category: DuaCategory;
  xpValue: number;
  repetitions: number;
}

export type DuaCategory = "morning" | "evening" | "rizq" | "gratitude";

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