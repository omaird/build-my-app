import { useState, useEffect, useCallback } from "react";
import { useAuth } from "@/contexts/AuthContext";
import { getSql } from "@/lib/db";

export interface DailyActivity {
  date: string;
  completed: boolean;
  duasCompleted: string[];
  xpEarned: number;
}

export interface UserProgress {
  duaId: string;
  completedCount: number;
  lastCompleted: string | null;
}

const getToday = () => new Date().toISOString().split("T")[0];

export function useDailyActivity() {
  const { user, isAuthenticated, addXp } = useAuth();
  const [activities, setActivities] = useState<DailyActivity[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  // Fetch activities from database
  const fetchActivities = useCallback(async () => {
    if (!user) {
      setActivities([]);
      setIsLoading(false);
      return;
    }

    try {
      const sql = getSql();
      const result = await sql`
        SELECT
          date::text,
          duas_completed as "duasCompleted",
          xp_earned as "xpEarned"
        FROM user_activity
        WHERE user_id = ${user.id}::uuid
        ORDER BY date DESC
        LIMIT 30
      `;

      const formattedActivities: DailyActivity[] = result.map((row) => ({
        date: row.date,
        completed: (row.duasCompleted as string[]).length > 0,
        duasCompleted: row.duasCompleted as string[],
        xpEarned: row.xpEarned as number,
      }));

      setActivities(formattedActivities);
    } catch (error) {
      console.error("Error fetching activities:", error);
    } finally {
      setIsLoading(false);
    }
  }, [user]);

  useEffect(() => {
    if (isAuthenticated) {
      fetchActivities();
    }
  }, [isAuthenticated, fetchActivities]);

  const getTodayActivity = useCallback((): DailyActivity | null => {
    const today = getToday();
    return activities.find((a) => a.date === today) || null;
  }, [activities]);

  const getWeekActivities = useCallback((): (DailyActivity | null)[] => {
    const result: (DailyActivity | null)[] = [];
    for (let i = 6; i >= 0; i--) {
      const date = new Date(Date.now() - i * 86400000).toISOString().split("T")[0];
      result.push(activities.find((a) => a.date === date) || null);
    }
    return result;
  }, [activities]);

  const markDuaCompleted = useCallback(
    async (duaId: string, xpEarned: number) => {
      if (!user) return;

      const today = getToday();

      try {
        const sql = getSql();

        // Upsert: insert or update today's activity
        await sql`
          INSERT INTO user_activity (user_id, date, duas_completed, xp_earned)
          VALUES (${user.id}::uuid, ${today}::date, ARRAY[${duaId}], ${xpEarned})
          ON CONFLICT (user_id, date)
          DO UPDATE SET
            duas_completed = array_append(user_activity.duas_completed, ${duaId}),
            xp_earned = user_activity.xp_earned + ${xpEarned}
        `;

        // Update local state optimistically
        setActivities((prev) => {
          const existing = prev.find((a) => a.date === today);
          if (existing) {
            return prev.map((a) =>
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
          return [
            {
              date: today,
              completed: true,
              duasCompleted: [duaId],
              xpEarned,
            },
            ...prev,
          ];
        });

        // Update XP in profile (this also updates streak)
        await addXp(xpEarned);
      } catch (error) {
        console.error("Error marking dua completed:", error);
        // Refetch to sync state
        fetchActivities();
      }
    },
    [user, addXp, fetchActivities]
  );

  return {
    activities,
    isLoading,
    getTodayActivity,
    getWeekActivities,
    markDuaCompleted,
    refetch: fetchActivities,
  };
}

export function useUserProgress() {
  const { user, isAuthenticated } = useAuth();
  const [progress, setProgress] = useState<UserProgress[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  // Fetch progress from database
  const fetchProgress = useCallback(async () => {
    if (!user) {
      setProgress([]);
      setIsLoading(false);
      return;
    }

    try {
      const sql = getSql();
      const result = await sql`
        SELECT
          dua_id::text as "duaId",
          completed_count as "completedCount",
          last_completed::text as "lastCompleted"
        FROM user_progress
        WHERE user_id = ${user.id}::uuid
      `;

      setProgress(
        result.map((row) => ({
          duaId: row.duaId as string,
          completedCount: row.completedCount as number,
          lastCompleted: row.lastCompleted as string | null,
        }))
      );
    } catch (error) {
      console.error("Error fetching progress:", error);
    } finally {
      setIsLoading(false);
    }
  }, [user]);

  useEffect(() => {
    if (isAuthenticated) {
      fetchProgress();
    }
  }, [isAuthenticated, fetchProgress]);

  const getDuaProgress = useCallback(
    (duaId: string): UserProgress | null => {
      return progress.find((p) => p.duaId === duaId) || null;
    },
    [progress]
  );

  const markDuaCompleted = useCallback(
    async (duaId: string) => {
      if (!user) return;

      const today = getToday();

      try {
        const sql = getSql();

        // Upsert: insert or update progress
        await sql`
          INSERT INTO user_progress (user_id, dua_id, completed_count, last_completed)
          VALUES (${user.id}::uuid, ${parseInt(duaId)}, 1, ${today}::date)
          ON CONFLICT (user_id, dua_id)
          DO UPDATE SET
            completed_count = user_progress.completed_count + 1,
            last_completed = ${today}::date,
            updated_at = NOW()
        `;

        // Update local state optimistically
        setProgress((prev) => {
          const existing = prev.find((p) => p.duaId === duaId);
          if (existing) {
            return prev.map((p) =>
              p.duaId === duaId
                ? { ...p, completedCount: p.completedCount + 1, lastCompleted: today }
                : p
            );
          }
          return [...prev, { duaId, completedCount: 1, lastCompleted: today }];
        });
      } catch (error) {
        console.error("Error marking progress:", error);
        fetchProgress();
      }
    },
    [user, fetchProgress]
  );

  const hasCompletedToday = useCallback(
    (duaId: string): boolean => {
      const today = getToday();
      const duaProgress = progress.find((p) => p.duaId === duaId);
      return duaProgress?.lastCompleted === today;
    },
    [progress]
  );

  return {
    progress,
    isLoading,
    getDuaProgress,
    markDuaCompleted,
    hasCompletedToday,
    refetch: fetchProgress,
  };
}
