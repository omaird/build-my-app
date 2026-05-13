import { useState, useEffect, useCallback } from "react";
import {
  arrayUnion,
  collection,
  doc,
  getDocs,
  increment,
  limit,
  orderBy,
  query,
  serverTimestamp,
  setDoc,
  Timestamp,
} from "firebase/firestore";
import { useAuth } from "@/contexts/AuthContext";
import { getSql } from "@/lib/db";
import { getDb, isFirestoreCutoverEnabled } from "@/lib/firebase";
import { toast } from "@/hooks/use-toast";

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

// ---------------------------------------------------------------------------
// Firestore helpers (only invoked when isFirestoreCutoverEnabled())
// ---------------------------------------------------------------------------

async function fetchActivitiesFromFirestore(
  userId: string
): Promise<DailyActivity[]> {
  const db = getDb();
  // Document IDs are `YYYY-MM-DD`, so __name__ desc = newest first.
  const snap = await getDocs(
    query(
      collection(db, "user_activity", userId, "dates"),
      orderBy("__name__", "desc"),
      limit(30)
    )
  );
  return snap.docs.map((d) => {
    const data = d.data() as { duasCompleted?: unknown; xpEarned?: unknown };
    // iOS writes `duasCompleted` as `[Int]`. Coerce each element to string for
    // the TS frontend type (which keeps the legacy `string[]` shape so callers
    // don't have to change). Tolerate string entries too in case legacy/test
    // data exists.
    const raw = Array.isArray(data.duasCompleted) ? data.duasCompleted : [];
    const duasCompleted = raw.map((v) => String(v));
    const xpEarned = typeof data.xpEarned === "number" ? data.xpEarned : 0;
    return {
      date: d.id,
      completed: duasCompleted.length > 0,
      duasCompleted,
      xpEarned,
    };
  });
}

async function writeActivityToFirestore(
  userId: string,
  date: string,
  duaId: string,
  xpEarned: number
): Promise<void> {
  // iOS reads `duasCompleted` as `[Int]`. Coerce at the firestore boundary so
  // web-written entries are visible to iOS readers.
  const numericDuaId = Number(duaId);
  if (!Number.isInteger(numericDuaId)) {
    throw new Error(`Invalid duaId: ${duaId} (not an integer)`);
  }
  const db = getDb();
  const ref = doc(db, "user_activity", userId, "dates", date);
  // Merge upsert: arrayUnion is idempotent (won't double-count a duaId).
  // Note: this means re-completing the same dua on the same day still adds
  // xpEarned — matches Neon's `array_append + xp_earned + ${xpEarned}` shape
  // (which is also non-idempotent on xp). Keep them consistent.
  await setDoc(
    ref,
    {
      duasCompleted: arrayUnion(numericDuaId),
      xpEarned: increment(xpEarned),
      updatedAt: serverTimestamp(),
    },
    { merge: true }
  );
}

/**
 * Coerce a Firestore `lastCompleted` value to a `YYYY-MM-DD` string for the
 * TS frontend type. iOS writes Firestore `Timestamp`; legacy/test data may be
 * a plain string or `Date`. Returns `null` for missing/unrecognised shapes.
 */
function lastCompletedToDateString(value: unknown): string | null {
  if (value == null) return null;
  if (typeof value === "string") {
    // Legacy or test-seeded data: split off any time component.
    return value.split("T")[0];
  }
  if (value instanceof Timestamp) {
    return value.toDate().toISOString().split("T")[0];
  }
  if (value instanceof Date) {
    return value.toISOString().split("T")[0];
  }
  return null;
}

async function fetchProgressFromFirestore(
  userId: string
): Promise<UserProgress[]> {
  const db = getDb();
  const snap = await getDocs(collection(db, "user_progress", userId, "duas"));
  return snap.docs.map((d) => {
    const data = d.data() as {
      duaId?: unknown;
      completedCount?: unknown;
      lastCompleted?: unknown;
    };
    return {
      // iOS writes `duaId` as `Int` and uses `String(duaId)` for the doc ID.
      // Prefer the explicit field, fall back to the doc ID. Always return a
      // string to match the legacy frontend type.
      duaId: data.duaId != null ? String(data.duaId) : d.id,
      completedCount:
        typeof data.completedCount === "number" ? data.completedCount : 0,
      lastCompleted: lastCompletedToDateString(data.lastCompleted),
    };
  });
}

async function writeProgressToFirestore(
  userId: string,
  duaId: string
): Promise<void> {
  // iOS stores `duaId` as `Int` and uses `String(duaId)` for the doc ID.
  // Coerce at the firestore boundary so cross-device reads stay consistent.
  const numericDuaId = Number(duaId);
  if (!Number.isInteger(numericDuaId)) {
    throw new Error(`Invalid duaId: ${duaId} (not an integer)`);
  }
  const db = getDb();
  const ref = doc(db, "user_progress", userId, "duas", String(numericDuaId));
  // Single merge upsert: `increment(1)` initialises a missing field to the
  // delta, and `duaId` is set on first write and harmlessly re-set on
  // subsequent merges. Atomic + idempotent — replaces the prior
  // read-then-write branch.
  await setDoc(
    ref,
    {
      duaId: numericDuaId,
      completedCount: increment(1),
      lastCompleted: Timestamp.now(),
      updatedAt: serverTimestamp(),
    },
    { merge: true }
  );
}

// ---------------------------------------------------------------------------
// useDailyActivity
// ---------------------------------------------------------------------------

export function useDailyActivity() {
  const { user, isAuthenticated, addXp } = useAuth();
  const [activities, setActivities] = useState<DailyActivity[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  // Fetch activities from the active backend (Firestore when cutover, Neon otherwise).
  const fetchActivities = useCallback(async () => {
    if (!user) {
      setActivities([]);
      setIsLoading(false);
      return;
    }

    try {
      if (isFirestoreCutoverEnabled()) {
        const formatted = await fetchActivitiesFromFirestore(user.id);
        setActivities(formatted);
      } else {
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
          date: row.date as string,
          completed: (row.duasCompleted as string[]).length > 0,
          duasCompleted: row.duasCompleted as string[],
          xpEarned: row.xpEarned as number,
        }));

        setActivities(formattedActivities);
      }
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

      // Step 1: persist activity row + optimistic local update.
      // If this fails, the user shouldn't see the dua marked complete.
      try {
        if (isFirestoreCutoverEnabled()) {
          await writeActivityToFirestore(user.id, today, duaId, xpEarned);
        } else {
          const sql = getSql();
          await sql`
            INSERT INTO user_activity (user_id, date, duas_completed, xp_earned)
            VALUES (${user.id}::uuid, ${today}::date, ARRAY[${duaId}], ${xpEarned})
            ON CONFLICT (user_id, date)
            DO UPDATE SET
              duas_completed = array_append(user_activity.duas_completed, ${duaId}),
              xp_earned = user_activity.xp_earned + ${xpEarned}
          `;
        }

        // Update local state optimistically (backend-agnostic).
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
      } catch (error) {
        console.error("Error marking dua completed:", error);
        toast({
          title: "Couldn't save your practice",
          description: "Please try again.",
          variant: "destructive",
        });
        // Resync local state from the server so the optimistic update is rolled back.
        fetchActivities();
        return;
      }

      // Step 2: update XP/streak. If this fails (e.g. Firestore rules denial,
      // transaction contention, network drop, "Profile not found"), the activity
      // row is already persisted — surface a non-destructive notice and let
      // the next completion retry the XP sync rather than re-throwing.
      try {
        await addXp(xpEarned);
      } catch (error) {
        console.error("Error syncing XP after dua completion:", error);
        toast({
          title: "Practice saved",
          description: "But XP didn't sync. It'll retry next time.",
        });
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

// ---------------------------------------------------------------------------
// useUserProgress
// ---------------------------------------------------------------------------

export function useUserProgress() {
  const { user, isAuthenticated } = useAuth();
  const [progress, setProgress] = useState<UserProgress[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  // Fetch progress from the active backend.
  const fetchProgress = useCallback(async () => {
    if (!user) {
      setProgress([]);
      setIsLoading(false);
      return;
    }

    try {
      if (isFirestoreCutoverEnabled()) {
        const rows = await fetchProgressFromFirestore(user.id);
        setProgress(rows);
      } else {
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
      }
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
        if (isFirestoreCutoverEnabled()) {
          await writeProgressToFirestore(user.id, duaId);
        } else {
          const sql = getSql();
          await sql`
            INSERT INTO user_progress (user_id, dua_id, completed_count, last_completed)
            VALUES (${user.id}::uuid, ${parseInt(duaId)}, 1, ${today}::date)
            ON CONFLICT (user_id, dua_id)
            DO UPDATE SET
              completed_count = user_progress.completed_count + 1,
              last_completed = ${today}::date,
              updated_at = NOW()
          `;
        }

        // Update local state optimistically (backend-agnostic).
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
