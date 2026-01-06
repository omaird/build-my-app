import { useState, useEffect, useCallback, useMemo } from "react";
import { useDuas } from "./useDuas";
import { useJourneysWithDuas } from "./useJourneys";
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
  activeJourneyIds: [],
  customHabits: [],
  habitCompletions: [],
  lastUpdated: new Date().toISOString(),
};

// Migration helper: convert old single activeJourneyId to new activeJourneyIds array
function migrateStorage(stored: unknown): UserHabitsStorage {
  const data = stored as Record<string, unknown>;

  // If already has activeJourneyIds array, return as-is
  if (Array.isArray(data.activeJourneyIds)) {
    return data as unknown as UserHabitsStorage;
  }

  // Migrate from old activeJourneyId (string | null) to activeJourneyIds (string[])
  const oldId = data.activeJourneyId as string | null | undefined;
  const activeJourneyIds = oldId ? [oldId] : [];

  return {
    activeJourneyIds,
    customHabits: (data.customHabits as UserHabit[]) || [],
    habitCompletions:
      (data.habitCompletions as UserHabitsStorage["habitCompletions"]) || [],
    lastUpdated: (data.lastUpdated as string) || new Date().toISOString(),
  };
}

export function useUserHabits() {
  const [storage, setStorage] = useState<UserHabitsStorage>(() => {
    const stored = localStorage.getItem(HABITS_KEY);
    if (stored) {
      try {
        const parsed = JSON.parse(stored);
        return migrateStorage(parsed);
      } catch {
        return defaultStorage;
      }
    }
    return defaultStorage;
  });

  // Fetch all duas for enrichment
  const { data: allDuas = [], isLoading: duasLoading } = useDuas();

  // Fetch all active journeys
  const journeyIds = useMemo(
    () => storage.activeJourneyIds.map((id) => parseInt(id, 10)),
    [storage.activeJourneyIds]
  );
  const { data: activeJourneys = [], isLoading: journeysLoading } =
    useJourneysWithDuas(journeyIds);

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

  // Add a journey to active journeys
  const addJourney = useCallback((journeyId: string) => {
    setStorage((prev) => {
      if (prev.activeJourneyIds.includes(journeyId)) {
        return prev; // Already active
      }
      return {
        ...prev,
        activeJourneyIds: [...prev.activeJourneyIds, journeyId],
        lastUpdated: new Date().toISOString(),
      };
    });
  }, []);

  // Remove a journey from active journeys
  const removeJourney = useCallback((journeyId: string) => {
    setStorage((prev) => ({
      ...prev,
      activeJourneyIds: prev.activeJourneyIds.filter((id) => id !== journeyId),
      lastUpdated: new Date().toISOString(),
    }));
  }, []);

  // Toggle a journey (add if not active, remove if active)
  const toggleJourney = useCallback((journeyId: string) => {
    setStorage((prev) => {
      const isActive = prev.activeJourneyIds.includes(journeyId);
      return {
        ...prev,
        activeJourneyIds: isActive
          ? prev.activeJourneyIds.filter((id) => id !== journeyId)
          : [...prev.activeJourneyIds, journeyId],
        lastUpdated: new Date().toISOString(),
      };
    });
  }, []);

  // Check if a journey is active
  const isJourneyActive = useCallback(
    (journeyId: string): boolean => {
      return storage.activeJourneyIds.includes(journeyId);
    },
    [storage.activeJourneyIds]
  );

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

  // Compute today's habits: merge duas from all active journeys + custom habits
  const todaysHabits = useMemo((): HabitWithDua[] => {
    const habits: HabitWithDua[] = [];
    const duaMap = new Map(allDuas.map((d) => [d.id, d]));
    const completedToday = getTodayCompletions();
    const addedDuaIds = new Set<string>();

    // Add habits from all active journeys (deduplicate by duaId)
    for (const journey of activeJourneys) {
      for (const jd of journey.duas) {
        const duaIdStr = String(jd.duaId);
        if (addedDuaIds.has(duaIdStr)) continue; // Skip duplicate duas

        const dua = duaMap.get(duaIdStr);
        if (!dua) {
          console.warn(
            `Dua ${jd.duaId} from journey "${journey.name}" not found in allDuas. ` +
            `This may indicate a data inconsistency.`
          );
          continue;
        }
        
        habits.push({
          id: `journey-${journey.id}-${jd.duaId}`,
          duaId: dua.id,
          timeSlot: jd.timeSlot,
          sortOrder: jd.sortOrder,
          addedAt: "",
          source: "journey",
          dua,
          isCompletedToday: completedToday.includes(dua.id),
        });
        addedDuaIds.add(duaIdStr);
      }
    }

    // Add custom habits (avoiding duplicates from journeys)
    for (const habit of storage.customHabits) {
      if (addedDuaIds.has(habit.duaId)) continue;

      const dua = duaMap.get(habit.duaId);
      if (dua) {
        habits.push({
          ...habit,
          dua,
          isCompletedToday: completedToday.includes(dua.id),
        });
        addedDuaIds.add(habit.duaId);
      }
    }

    return habits;
  }, [activeJourneys, storage.customHabits, allDuas, getTodayCompletions]);

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
    return storage.activeJourneyIds.length > 0 || storage.customHabits.length > 0;
  }, [storage.activeJourneyIds.length, storage.customHabits.length]);

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
  const isLoading = duasLoading || journeysLoading;

  return {
    // State
    storage,
    activeJourneys,
    activeJourneyIds: storage.activeJourneyIds,
    todaysHabits,
    groupedHabits,
    progress,
    hasHabits,
    nextUncompletedHabit,
    isLoading,

    // Actions
    addJourney,
    removeJourney,
    toggleJourney,
    isJourneyActive,
    addCustomHabit,
    removeCustomHabit,
    markHabitCompleted,
    isHabitCompletedToday,
    getTodayCompletions,
    clearAllHabits,
  };
}
