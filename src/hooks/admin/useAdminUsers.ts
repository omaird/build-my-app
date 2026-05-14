import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  collection,
  doc,
  getDoc,
  getDocs,
  orderBy,
  query as fsQuery,
  serverTimestamp,
  Timestamp,
  updateDoc,
} from 'firebase/firestore';
import { getDb } from '@/lib/firebase';
import type { AdminUser } from '@/types/admin';

// =============================================================================
// MAPPERS
// =============================================================================

interface FirestoreUserProfileDoc {
  displayName?: string | null;
  streak?: number;
  totalXp?: number;
  level?: number;
  lastActiveDate?: string | null;
  isAdmin?: boolean;
  createdAt?: unknown;
  updatedAt?: unknown;
  email?: string | null;
  photoURL?: string | null;
}

function timestampToIso(value: unknown): string {
  if (value instanceof Timestamp) return value.toDate().toISOString();
  if (value instanceof Date) return value.toISOString();
  if (typeof value === 'string') return value;
  return '';
}

function mapFsUserProfileToAdmin(
  userId: string,
  data: FirestoreUserProfileDoc,
): AdminUser {
  return {
    userId,
    // The auth account email/name/image live in Firebase Auth, not the
    // profile doc. For an admin user listing we surface what the profile has.
    // If the profile doc denormalises email/photoURL we'll pick them up here.
    email: data.email ?? '',
    name: data.displayName ?? null,
    image: data.photoURL ?? null,
    displayName: data.displayName ?? null,
    streak: data.streak ?? 0,
    totalXp: data.totalXp ?? 0,
    level: data.level ?? 1,
    lastActiveDate: data.lastActiveDate ?? null,
    isAdmin: data.isAdmin ?? false,
    createdAt: timestampToIso(data.createdAt),
  };
}

// =============================================================================
// QUERIES
// =============================================================================

/**
 * Fetch all users with their profiles
 */
export function useAdminUsers() {
  return useQuery({
    queryKey: ['admin', 'users'],
    queryFn: async (): Promise<AdminUser[]> => {
      const db = getDb();
      const snap = await getDocs(
        fsQuery(collection(db, 'user_profiles'), orderBy('createdAt', 'desc')),
      );
      return snap.docs.map((d) =>
        mapFsUserProfileToAdmin(d.id, d.data() as FirestoreUserProfileDoc),
      );
    },
  });
}

/**
 * Fetch a single user by ID
 */
export function useAdminUser(userId: string | null) {
  return useQuery({
    queryKey: ['admin', 'users', userId],
    queryFn: async (): Promise<AdminUser | null> => {
      if (!userId) return null;

      const db = getDb();
      const snap = await getDoc(doc(db, 'user_profiles', userId));
      if (!snap.exists()) return null;
      return mapFsUserProfileToAdmin(
        snap.id,
        snap.data() as FirestoreUserProfileDoc,
      );
    },
    enabled: userId !== null,
  });
}

/**
 * Get user activity summary (duas completed, XP earned by date)
 */
export interface UserActivitySummary {
  date: string;
  duasCompleted: number;
  xpEarned: number;
}

interface FirestoreActivityDoc {
  duasCompleted?: number[];
  xpEarned?: number;
}

export function useAdminUserActivity(userId: string | null, limit: number = 30) {
  return useQuery({
    queryKey: ['admin', 'users', userId, 'activity', limit],
    queryFn: async (): Promise<UserActivitySummary[]> => {
      if (!userId) return [];

      const db = getDb();
      // user_activity/{userId}/dates/{date}. Document IDs are `YYYY-MM-DD`.
      // Firestore (and the emulator) rejects `orderBy(documentId(), 'desc')`
      // without a backing index, so fetch unsorted and sort client-side.
      const snap = await getDocs(
        collection(db, 'user_activity', userId, 'dates'),
      );
      const sortedDocs = [...snap.docs]
        .sort((a, b) => (a.id < b.id ? 1 : a.id > b.id ? -1 : 0))
        .slice(0, limit);
      return sortedDocs.map((d) => {
        const data = d.data() as FirestoreActivityDoc;
        return {
          date: d.id,
          duasCompleted: data.duasCompleted?.length ?? 0,
          xpEarned: data.xpEarned ?? 0,
        };
      });
    },
    enabled: userId !== null,
  });
}

// =============================================================================
// MUTATIONS
// =============================================================================

/**
 * Toggle user admin status
 * @param currentUserId - The ID of the current admin (to prevent self-demotion)
 */
export function useToggleAdmin(currentUserId: string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ userId, isAdmin }: { userId: string; isAdmin: boolean }): Promise<void> => {
      // Prevent self-demotion
      if (userId === currentUserId && !isAdmin) {
        throw new Error('You cannot remove your own admin privileges.');
      }

      const db = getDb();
      await updateDoc(doc(db, 'user_profiles', userId), {
        isAdmin,
        updatedAt: serverTimestamp(),
      });
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'users'] });
      queryClient.invalidateQueries({ queryKey: ['admin', 'users', variables.userId] });
    },
  });
}

/**
 * Get admin stats summary
 */
export interface AdminStats {
  totalDuas: number;
  totalJourneys: number;
  totalCategories: number;
  totalCollections: number;
  totalUsers: number;
  activeUsersToday: number;
}

export function useAdminStats() {
  return useQuery({
    queryKey: ['admin', 'stats'],
    queryFn: async (): Promise<AdminStats> => {
      const db = getDb();
      const today = new Date().toISOString().slice(0, 10);
      const [
        duasSnap,
        journeysSnap,
        categoriesSnap,
        collectionsSnap,
        usersSnap,
      ] = await Promise.all([
        getDocs(collection(db, 'duas')),
        getDocs(collection(db, 'journeys')),
        getDocs(collection(db, 'categories')),
        getDocs(collection(db, 'collections')),
        getDocs(collection(db, 'user_profiles')),
      ]);
      const activeUsersToday = usersSnap.docs.filter(
        (d) => (d.data() as { lastActiveDate?: string }).lastActiveDate === today,
      ).length;
      return {
        totalDuas: duasSnap.size,
        totalJourneys: journeysSnap.size,
        totalCategories: categoriesSnap.size,
        totalCollections: collectionsSnap.size,
        totalUsers: usersSnap.size,
        activeUsersToday,
      };
    },
  });
}
