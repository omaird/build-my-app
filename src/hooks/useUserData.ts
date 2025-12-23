import { useState, useEffect, useCallback } from "react";
import { UserProfile, DailyActivity, UserProgress } from "@/types/dua";

const PROFILE_KEY = "rizq_user_profile";
const ACTIVITY_KEY = "rizq_daily_activity";
const PROGRESS_KEY = "rizq_user_progress";

const getToday = () => new Date().toISOString().split("T")[0];

const calculateLevel = (xp: number): number => {
  // Level thresholds: 0, 100, 250, 500, 850, 1300, 1850, 2500...
  // Formula: threshold = 50 * level^2 + 50 * level
  let level = 1;
  while (50 * level * level + 50 * level <= xp) {
    level++;
  }
  return level;
};

const getXpForLevel = (level: number): number => {
  return 50 * level * level + 50 * level;
};

const defaultProfile: UserProfile = {
  name: "Traveler",
  streak: 0,
  totalXp: 0,
  level: 1,
  lastActiveDate: null,
  createdAt: new Date().toISOString(),
};

export function useUserProfile() {
  const [profile, setProfile] = useState<UserProfile>(() => {
    const stored = localStorage.getItem(PROFILE_KEY);
    if (stored) {
      const parsed = JSON.parse(stored) as UserProfile;
      // Check streak validity
      const today = getToday();
      const yesterday = new Date(Date.now() - 86400000).toISOString().split("T")[0];
      
      if (parsed.lastActiveDate !== today && parsed.lastActiveDate !== yesterday) {
        // Streak broken
        return { ...parsed, streak: 0 };
      }
      return parsed;
    }
    return defaultProfile;
  });

  useEffect(() => {
    localStorage.setItem(PROFILE_KEY, JSON.stringify(profile));
  }, [profile]);

  const updateName = useCallback((name: string) => {
    setProfile(prev => ({ ...prev, name }));
  }, []);

  const addXp = useCallback((amount: number) => {
    setProfile(prev => {
      const newXp = prev.totalXp + amount;
      const newLevel = calculateLevel(newXp);
      const today = getToday();
      const isNewDay = prev.lastActiveDate !== today;
      
      return {
        ...prev,
        totalXp: newXp,
        level: newLevel,
        streak: isNewDay ? prev.streak + 1 : prev.streak,
        lastActiveDate: today,
      };
    });
  }, []);

  const getXpProgress = useCallback(() => {
    const currentLevelXp = getXpForLevel(profile.level - 1);
    const nextLevelXp = getXpForLevel(profile.level);
    const progressXp = profile.totalXp - currentLevelXp;
    const neededXp = nextLevelXp - currentLevelXp;
    return {
      current: progressXp,
      needed: neededXp,
      percentage: Math.min((progressXp / neededXp) * 100, 100),
    };
  }, [profile]);

  const resetProfile = useCallback(() => {
    setProfile(defaultProfile);
    localStorage.removeItem(ACTIVITY_KEY);
    localStorage.removeItem(PROGRESS_KEY);
  }, []);

  return {
    profile,
    updateName,
    addXp,
    getXpProgress,
    resetProfile,
  };
}

export function useDailyActivity() {
  const [activities, setActivities] = useState<DailyActivity[]>(() => {
    const stored = localStorage.getItem(ACTIVITY_KEY);
    return stored ? JSON.parse(stored) : [];
  });

  useEffect(() => {
    localStorage.setItem(ACTIVITY_KEY, JSON.stringify(activities));
  }, [activities]);

  const getTodayActivity = useCallback((): DailyActivity | null => {
    const today = getToday();
    return activities.find(a => a.date === today) || null;
  }, [activities]);

  const getWeekActivities = useCallback((): (DailyActivity | null)[] => {
    const result: (DailyActivity | null)[] = [];
    for (let i = 6; i >= 0; i--) {
      const date = new Date(Date.now() - i * 86400000).toISOString().split("T")[0];
      result.push(activities.find(a => a.date === date) || null);
    }
    return result;
  }, [activities]);

  const markDuaCompleted = useCallback((duaId: string, xpEarned: number) => {
    const today = getToday();
    setActivities(prev => {
      const existing = prev.find(a => a.date === today);
      if (existing) {
        return prev.map(a => 
          a.date === today 
            ? { 
                ...a, 
                completed: true,
                duasCompleted: [...a.duasCompleted, duaId],
                xpEarned: a.xpEarned + xpEarned,
              }
            : a
        );
      }
      return [...prev, {
        date: today,
        completed: true,
        duasCompleted: [duaId],
        xpEarned,
      }];
    });
  }, []);

  return {
    activities,
    getTodayActivity,
    getWeekActivities,
    markDuaCompleted,
  };
}

export function useUserProgress() {
  const [progress, setProgress] = useState<UserProgress[]>(() => {
    const stored = localStorage.getItem(PROGRESS_KEY);
    return stored ? JSON.parse(stored) : [];
  });

  useEffect(() => {
    localStorage.setItem(PROGRESS_KEY, JSON.stringify(progress));
  }, [progress]);

  const getDuaProgress = useCallback((duaId: string): UserProgress | null => {
    return progress.find(p => p.duaId === duaId) || null;
  }, [progress]);

  const markDuaCompleted = useCallback((duaId: string) => {
    const today = getToday();
    setProgress(prev => {
      const existing = prev.find(p => p.duaId === duaId);
      if (existing) {
        return prev.map(p => 
          p.duaId === duaId 
            ? { ...p, completedCount: p.completedCount + 1, lastCompleted: today }
            : p
        );
      }
      return [...prev, {
        duaId,
        completedCount: 1,
        lastCompleted: today,
      }];
    });
  }, []);

  const hasCompletedToday = useCallback((duaId: string): boolean => {
    const today = getToday();
    const duaProgress = progress.find(p => p.duaId === duaId);
    return duaProgress?.lastCompleted === today;
  }, [progress]);

  return {
    progress,
    getDuaProgress,
    markDuaCompleted,
    hasCompletedToday,
  };
}