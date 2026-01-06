import type { Dua } from "./dua";

// Time slots for habit scheduling (matches Islamic prayer structure)
export type TimeSlot = "morning" | "anytime" | "evening";

// Journey from database (pre-built paths users can subscribe to)
export interface Journey {
  id: number;
  name: string;
  slug: string;
  description: string | null;
  /** Emoji character or path to icon image (e.g., '/images/icons/name.png') */
  emoji: string;
  estimatedMinutes: number;
  dailyXp: number;
  isPremium: boolean;
  isFeatured: boolean;
}

// Dua within a journey with scheduling info
export interface JourneyDua {
  duaId: number;
  timeSlot: TimeSlot;
  sortOrder: number;
  // Joined dua fields for display
  title: string;
  xpValue: number;
  repetitions: number;
  category: string;
}

// Journey with its duas (from JOIN query)
export interface JourneyWithDuas extends Journey {
  duas: JourneyDua[];
}

// User's habit (either from journey or custom)
export interface UserHabit {
  id: string;
  duaId: string;
  timeSlot: TimeSlot;
  sortOrder: number;
  addedAt: string;
  source: "journey" | "custom";
}

// Habit with full dua details for display
export interface HabitWithDua extends UserHabit {
  dua: Dua;
  isCompletedToday: boolean;
}

// Grouped habits for UI display
export interface GroupedHabits {
  morning: HabitWithDua[];
  anytime: HabitWithDua[];
  evening: HabitWithDua[];
}

// Habit completion record (for daily tracking)
export interface HabitCompletion {
  date: string; // ISO format: YYYY-MM-DD
  completedDuaIds: string[];
}

// User habits localStorage schema
export interface UserHabitsStorage {
  activeJourneyIds: string[];
  customHabits: UserHabit[];
  habitCompletions: HabitCompletion[];
  lastUpdated: string;
}

// Progress stats for display
export interface HabitProgress {
  total: number;
  completed: number;
  percentage: number;
  totalXp: number;
  earnedXp: number;
}

// Time slot display info
export interface TimeSlotInfo {
  key: TimeSlot;
  label: string;
  subLabel: string;
  icon: string;
}

export const TIME_SLOT_INFO: Record<TimeSlot, Omit<TimeSlotInfo, "key">> = {
  morning: {
    label: "Morning",
    subLabel: "After Fajr",
    icon: "sun",
  },
  anytime: {
    label: "Anytime",
    subLabel: "Throughout the day",
    icon: "clock",
  },
  evening: {
    label: "Evening",
    subLabel: "After Maghrib",
    icon: "moon",
  },
};
