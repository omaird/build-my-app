import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getSql } from '@/lib/db';
import type { AdminUser, AdminUserRow } from '@/types/admin';

// =============================================================================
// MAPPERS
// =============================================================================

function mapDbUserToAdmin(row: AdminUserRow): AdminUser {
  return {
    userId: row.user_id,
    email: row.email,
    name: row.name,
    image: row.image,
    displayName: row.display_name,
    streak: row.streak,
    totalXp: row.total_xp,
    level: row.level,
    lastActiveDate: row.last_active_date,
    isAdmin: row.is_admin,
    createdAt: row.created_at,
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
      const sql = getSql();
      const result = await sql`
        SELECT
          up.user_id,
          u.email,
          u.name,
          u.image,
          up.display_name,
          up.streak,
          up.total_xp,
          up.level,
          up.last_active_date,
          up.is_admin,
          up.created_at
        FROM user_profiles up
        JOIN neon_auth."user" u ON up.user_id = u.id
        ORDER BY up.created_at DESC
      `;
      return (result as AdminUserRow[]).map(mapDbUserToAdmin);
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
      const sql = getSql();
      const result = await sql`
        SELECT
          up.user_id,
          u.email,
          u.name,
          u.image,
          up.display_name,
          up.streak,
          up.total_xp,
          up.level,
          up.last_active_date,
          up.is_admin,
          up.created_at
        FROM user_profiles up
        JOIN neon_auth."user" u ON up.user_id = u.id
        WHERE up.user_id = ${userId}::uuid
      `;
      if (!result.length) return null;
      return mapDbUserToAdmin(result[0] as AdminUserRow);
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

interface DbActivityRow {
  date: string;
  duas_completed: number[] | null;
  xp_earned: number;
}

export function useAdminUserActivity(userId: string | null, limit: number = 30) {
  return useQuery({
    queryKey: ['admin', 'users', userId, 'activity', limit],
    queryFn: async (): Promise<UserActivitySummary[]> => {
      if (!userId) return [];
      const sql = getSql();
      const result = await sql`
        SELECT
          date,
          duas_completed,
          xp_earned
        FROM user_activity
        WHERE user_id = ${userId}::uuid
        ORDER BY date DESC
        LIMIT ${limit}
      `;
      return (result as DbActivityRow[]).map(row => ({
        date: row.date,
        duasCompleted: row.duas_completed?.length || 0,
        xpEarned: row.xp_earned,
      }));
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

      const sql = getSql();
      await sql`
        UPDATE user_profiles
        SET is_admin = ${isAdmin}, updated_at = NOW()
        WHERE user_id = ${userId}::uuid
      `;
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

interface DbStatsRow {
  total_duas: number;
  total_journeys: number;
  total_categories: number;
  total_collections: number;
  total_users: number;
  active_users_today: number;
}

export function useAdminStats() {
  return useQuery({
    queryKey: ['admin', 'stats'],
    queryFn: async (): Promise<AdminStats> => {
      const sql = getSql();
      const result = await sql`
        SELECT
          (SELECT COUNT(*)::int FROM duas) as total_duas,
          (SELECT COUNT(*)::int FROM journeys) as total_journeys,
          (SELECT COUNT(*)::int FROM categories) as total_categories,
          (SELECT COUNT(*)::int FROM collections) as total_collections,
          (SELECT COUNT(*)::int FROM user_profiles) as total_users,
          (SELECT COUNT(*)::int FROM user_profiles WHERE last_active_date = CURRENT_DATE) as active_users_today
      `;
      const row = result[0] as DbStatsRow;
      return {
        totalDuas: row.total_duas,
        totalJourneys: row.total_journeys,
        totalCategories: row.total_categories,
        totalCollections: row.total_collections,
        totalUsers: row.total_users,
        activeUsersToday: row.active_users_today,
      };
    },
  });
}
