import { useQuery } from '@tanstack/react-query';
import { collection, getDocs, limit, orderBy, query } from 'firebase/firestore';
import { useAuth } from '@/contexts/AuthContext';
import { getDb } from '@/lib/firebase';

/**
 * A single day's activity row from `user_activity/{uid}/dates/{YYYY-MM-DD}`.
 *
 * Field shape matches the iOS Firestore schema (camelCase) so cross-device
 * reads see the same data.
 */
export interface FirestoreDailyActivity {
  date: string;
  duasCompleted: string[];
  xpEarned: number;
}

/**
 * Fetch the most recent 7 days of activity for the signed-in user from
 * Firestore. Disabled when no user is signed in.
 *
 * Intentionally returns the docs in descending-date order (Firestore document
 * IDs are `YYYY-MM-DD`, so lex order over `__name__` matches calendar order).
 * Callers that need ascending order can `.slice().reverse()`.
 *
 * Not yet wired into `useDailyActivity` — that hook still owns the read path
 * behind the cutover flag. This hook exists for future consumers (e.g. a
 * week-chart that wants a Firestore-only read without the legacy Neon
 * fallback baggage).
 */
export function useFirestoreWeekActivity() {
  const { user } = useAuth();

  return useQuery({
    queryKey: ['user_activity', 'week', user?.id],
    enabled: !!user,
    queryFn: async (): Promise<FirestoreDailyActivity[]> => {
      // `enabled: !!user` guarantees user is set when queryFn runs.
      const uid = user!.id;
      const db = getDb();
      const snap = await getDocs(
        query(
          collection(db, 'user_activity', uid, 'dates'),
          orderBy('__name__', 'desc'),
          limit(7)
        )
      );

      return snap.docs.map((d) => {
        const data = d.data() as {
          duasCompleted?: unknown;
          xpEarned?: unknown;
        };
        return {
          date: d.id,
          duasCompleted: Array.isArray(data.duasCompleted)
            ? (data.duasCompleted as string[])
            : [],
          xpEarned: typeof data.xpEarned === 'number' ? data.xpEarned : 0,
        };
      });
    },
  });
}
