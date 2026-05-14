import { useQuery } from '@tanstack/react-query';
import { collection, getDocs } from 'firebase/firestore';
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
      // Document IDs are `YYYY-MM-DD`. The emulator rejects
      // `orderBy(documentId(), 'desc')` without a backing index, so we fetch
      // unsorted and sort client-side. The collection is per-user; sub-10 docs
      // for the 7-day window plus older history.
      const snap = await getDocs(collection(db, 'user_activity', uid, 'dates'));
      const sortedDocs = [...snap.docs]
        .sort((a, b) => (a.id < b.id ? 1 : a.id > b.id ? -1 : 0))
        .slice(0, 7);

      return sortedDocs.map((d) => {
        const data = d.data() as {
          duasCompleted?: unknown;
          xpEarned?: unknown;
        };
        // iOS writes `duasCompleted` as `[Int]`. Coerce each element to string
        // for the TS frontend type so cross-device reads stay consistent.
        const raw = Array.isArray(data.duasCompleted) ? data.duasCompleted : [];
        return {
          date: d.id,
          duasCompleted: raw.map((v) => String(v)),
          xpEarned: typeof data.xpEarned === 'number' ? data.xpEarned : 0,
        };
      });
    },
  });
}
