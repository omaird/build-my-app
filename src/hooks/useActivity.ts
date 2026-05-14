import { useState, useEffect, useCallback } from "react";
import {
  arrayUnion,
  collection,
  doc,
  getDocs,
  increment,
  serverTimestamp,
  setDoc,
  Timestamp,
} from "firebase/firestore";
import { useAuth } from "@/contexts/AuthContext";
import { getDb } from "@/lib/firebase";
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
// Firestore helpers
// ---------------------------------------------------------------------------

async function fetchActivitiesFromFirestore(
  userId: string
): Promise<DailyActivity[]> {
  const db = getDb();
  // Document IDs are `YYYY-MM-DD`. Firestore (and the emulator in particular)
  // rejects `orderBy(documentId(), 'desc')` without a backing index, so we
  // fetch unsorted and sort client-side. The collection is per-user and
  // bounded by user lifetime, so this is cheap.
  const snap = await getDocs(collection(db, "user_activity", userId, "dates"));
  const sortedDocs = [...snap.docs]
    .sort((a, b) => (a.id < b.id ? 1 : a.id > b.id ? -1 : 0))
    .slice(0, 30);
  return sortedDocs.map((d) => {
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

  // Fetch activities from Firestore.
  const fetchActivities = useCallback(async () => {
    if (!user) {
      setActivities([]);
      setIsLoading(false);
      return;
    }

    try {
      const formatted = await fetchActivitiesFromFirestore(user.id);
      setActivities(formatted);
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
        await writeActivityToFirestore(user.id, today, duaId, xpEarned);

        // Update local state optimistically.
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

  // Fetch progress from Firestore.
  const fetchProgress = useCallback(async () => {
    if (!user) {
      setProgress([]);
      setIsLoading(false);
      return;
    }

    try {
      const rows = await fetchProgressFromFirestore(user.id);
      setProgress(rows);
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
        await writeProgressToFirestore(user.id, duaId);

        // Update local state optimistically.
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
