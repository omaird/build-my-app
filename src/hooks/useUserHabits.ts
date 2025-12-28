import { useState, useEffect, useCallback, useMemo } from "react";
import { useDuas } from "./useDuas";
import { useJourneyWithDuas } from "./useJourneys";
import type {
  UserHabitsStorage,
  UserHabit,
  HabitWithDua,
  GroupedHabits,
  TimeSlot,
  HabitProgress,
} from "@/types/habit";

const HABITS_KEY = "rizq_user_habits";

const getToday = () => new Date().toISOString().split("T")[0];

const defaultStorage: UserHabitsStorage = {
  activeJourneyId: null,
  customHabits: [],
  habitCompletions: [],
  lastUpdated: new Date().toISOString(),
};

export function useUserHabits() {
  const [storage, setStorage] = useState<UserHabitsStorage>(() => {
    const stored = localStorage.getItem(HABITS_KEY);
    if (stored) {
      try {
        return JSON.parse(stored) as UserHabitsStorage;
      } catch {
        return defaultStorage;
      }
    }
    return defaultStorage;
  });

  // Fetch all duas for enrichment
  const { data: allDuas = [], isLoading: duasLoading } = useDuas();

  // Fetch active journey if set
  const journeyId = storage.activeJourneyId
    ? parseInt(storage.activeJourneyId, 10)
    : null;
  const { data: activeJourney, isLoading: journeyLoading } =
    useJourneyWithDuas(journeyId);

  // Persist to localStorage
  useEffect(() => {
    localStorage.setItem(HABITS_KEY, JSON.stringify(storage));
  }, [storage]);

  // Get today's completion status
  const getTodayCompletions = useCallback((): string[] => {
    const today = getToday();
    const todayRecord = storage.habitCompletions.find((c) => c.date === today);
    return todayRecord?.completedDuaIds || [];
  }, [storage.habitCompletions]);

  // Check if a specific dua is completed today
  const isHabitCompletedToday = useCallback(
    (duaId: string): boolean => {
      return getTodayCompletions().includes(duaId);
    },
    [getTodayCompletions]
  );

  // Mark a habit as completed for today
  const markHabitCompleted = useCallback((duaId: string) => {
    const today = getToday();
    setStorage((prev) => {
      const existingIndex = prev.habitCompletions.findIndex(
        (c) => c.date === today
      );

      if (existingIndex >= 0) {
        // Update existing day's completions
        const updated = [...prev.habitCompletions];
        if (!updated[existingIndex].completedDuaIds.includes(duaId)) {
          updated[existingIndex] = {
            ...updated[existingIndex],
            completedDuaIds: [...updated[existingIndex].completedDuaIds, duaId],
          };
        }
        return {
          ...prev,
          habitCompletions: updated,
          lastUpdated: new Date().toISOString(),
        };
      }

      // Create new day's record
      return {
        ...prev,
        habitCompletions: [
          ...prev.habitCompletions,
          { date: today, completedDuaIds: [duaId] },
        ],
        lastUpdated: new Date().toISOString(),
      };
    });
  }, []);

  // Set active journey
  const setActiveJourney = useCallback((journeyId: string | null) => {
    setStorage((prev) => ({
      ...prev,
      activeJourneyId: journeyId,
      lastUpdated: new Date().toISOString(),
    }));
  }, []);

  // Add custom habit
  const addCustomHabit = useCallback(
    (duaId: string, timeSlot: TimeSlot) => {
      // Check if already exists
      const exists = storage.customHabits.some((h) => h.duaId === duaId);
      if (exists) return;

      const newHabit: UserHabit = {
        id: crypto.randomUUID(),
        duaId,
        timeSlot,
        sortOrder: storage.customHabits.length,
        addedAt: new Date().toISOString(),
        source: "custom",
      };

      setStorage((prev) => ({
        ...prev,
        customHabits: [...prev.customHabits, newHabit],
        lastUpdated: new Date().toISOString(),
      }));
    },
    [storage.customHabits]
  );

  // Remove custom habit
  const removeCustomHabit = useCallback((habitId: string) => {
    setStorage((prev) => ({
      ...prev,
      customHabits: prev.customHabits.filter((h) => h.id !== habitId),
      lastUpdated: new Date().toISOString(),
    }));
  }, []);

  // Clear all habits (for testing/reset)
  const clearAllHabits = useCallback(() => {
    setStorage(defaultStorage);
  }, []);

  // Compute today's habits (journey + custom) with dua details
  const todaysHabits = useMemo((): HabitWithDua[] => {
    const habits: HabitWithDua[] = [];
    const duaMap = new Map(allDuas.map((d) => [d.id, d]));
    const completedToday = getTodayCompletions();

    // Add journey habits if active
    if (activeJourney) {
      activeJourney.duas.forEach((jd) => {
        const dua = duaMap.get(String(jd.duaId));
        if (dua) {
          habits.push({
            id: `journey-${activeJourney.id}-${jd.duaId}`,
            duaId: dua.id,
            timeSlot: jd.timeSlot,
            sortOrder: jd.sortOrder,
            addedAt: "",
            source: "journey",
            dua,
            isCompletedToday: completedToday.includes(dua.id),
          });
        }
      });
    }

    // Add custom habits (avoiding duplicates from journey)
    const journeyDuaIds = new Set(habits.map((h) => h.duaId));
    storage.customHabits.forEach((habit) => {
      if (!journeyDuaIds.has(habit.duaId)) {
        const dua = duaMap.get(habit.duaId);
        if (dua) {
          habits.push({
            ...habit,
            dua,
            isCompletedToday: completedToday.includes(dua.id),
          });
        }
      }
    });

    return habits;
  }, [activeJourney, storage.customHabits, allDuas, getTodayCompletions]);

  // Group habits by time slot
  const groupedHabits = useMemo((): GroupedHabits => {
    return {
      morning: todaysHabits
        .filter((h) => h.timeSlot === "morning")
        .sort((a, b) => a.sortOrder - b.sortOrder),
      anytime: todaysHabits
        .filter((h) => h.timeSlot === "anytime")
        .sort((a, b) => a.sortOrder - b.sortOrder),
      evening: todaysHabits
        .filter((h) => h.timeSlot === "evening")
        .sort((a, b) => a.sortOrder - b.sortOrder),
    };
  }, [todaysHabits]);

  // Calculate progress stats
  const progress = useMemo((): HabitProgress => {
    const total = todaysHabits.length;
    const completed = todaysHabits.filter((h) => h.isCompletedToday).length;
    const totalXp = todaysHabits.reduce((sum, h) => sum + h.dua.xpValue, 0);
    const earnedXp = todaysHabits
      .filter((h) => h.isCompletedToday)
      .reduce((sum, h) => sum + h.dua.xpValue, 0);

    return {
      total,
      completed,
      percentage: total > 0 ? Math.round((completed / total) * 100) : 0,
      totalXp,
      earnedXp,
    };
  }, [todaysHabits]);

  // Check if user has any habits configured
  const hasHabits = useMemo(() => {
    return storage.activeJourneyId !== null || storage.customHabits.length > 0;
  }, [storage.activeJourneyId, storage.customHabits.length]);

  // Get next uncompleted habit (for "Continue Practice" button)
  const nextUncompletedHabit = useMemo((): HabitWithDua | null => {
    // Priority: morning > anytime > evening
    const uncompleted = todaysHabits.filter((h) => !h.isCompletedToday);
    if (uncompleted.length === 0) return null;

    // Sort by time slot priority then sort order
    const slotPriority = { morning: 0, anytime: 1, evening: 2 };
    return uncompleted.sort((a, b) => {
      const priorityDiff = slotPriority[a.timeSlot] - slotPriority[b.timeSlot];
      if (priorityDiff !== 0) return priorityDiff;
      return a.sortOrder - b.sortOrder;
    })[0];
  }, [todaysHabits]);

  // Loading state
  const isLoading = duasLoading || journeyLoading;

  return {
    // State
    storage,
    activeJourney,
    todaysHabits,
    groupedHabits,
    progress,
    hasHabits,
    nextUncompletedHabit,
    isLoading,

    // Actions
    setActiveJourney,
    addCustomHabit,
    removeCustomHabit,
    markHabitCompleted,
    isHabitCompletedToday,
    getTodayCompletions,
    clearAllHabits,
  };
}
