import { createContext, useContext, useEffect, useState, useCallback, ReactNode } from "react";
import { useSession, signOut as authSignOut, extractGoogleProfilePicture } from "@/lib/auth-client";
import { getSql } from "@/lib/db";

// Types for user profile data stored in our database
export interface UserProfile {
  id: string;
  userId: string;
  displayName: string | null;
  streak: number;
  totalXp: number;
  level: number;
  lastActiveDate: string | null;
  isAdmin: boolean;
  createdAt: string;
  updatedAt: string;
}

interface AuthUser {
  id: string;
  email: string;
  name: string | null;
  image: string | null;
}

interface AuthContextType {
  user: AuthUser | null;
  profile: UserProfile | null;
  isLoading: boolean;
  isAuthenticated: boolean;
  isAdmin: boolean;
  signOut: () => Promise<void>;
  refreshProfile: () => Promise<void>;
  updateProfile: (updates: Partial<Pick<UserProfile, "displayName">>) => Promise<void>;
  addXp: (amount: number) => Promise<void>;
}

const AuthContext = createContext<AuthContextType | null>(null);

// Level calculation functions
const calculateLevel = (xp: number): number => {
  let level = 1;
  while (50 * level * level + 50 * level <= xp) {
    level++;
  }
  return level;
};

const getToday = () => new Date().toISOString().split("T")[0];

export function AuthProvider({ children }: { children: ReactNode }) {
  const { data: session, isPending } = useSession();
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [isLoadingProfile, setIsLoadingProfile] = useState(false);

  const user: AuthUser | null = session?.user ? {
    id: session.user.id,
    email: session.user.email,
    name: session.user.name,
    image: session.user.image,
  } : null;

  // Fetch or create user profile when user logs in
  const fetchOrCreateProfile = useCallback(async (userId: string, userName: string | null) => {
    setIsLoadingProfile(true);
    try {
      const sql = getSql();

      // Try to fetch existing profile
      const existingProfiles = await sql`
        SELECT
          id, user_id as "userId", display_name as "displayName",
          streak, total_xp as "totalXp", level,
          last_active_date as "lastActiveDate",
          is_admin as "isAdmin",
          created_at as "createdAt", updated_at as "updatedAt"
        FROM user_profiles
        WHERE user_id = ${userId}::uuid
      `;

      if (existingProfiles.length > 0) {
        const p = existingProfiles[0] as UserProfile;
        // Check and update streak
        const today = getToday();
        const yesterday = new Date(Date.now() - 86400000).toISOString().split("T")[0];

        if (p.lastActiveDate !== today && p.lastActiveDate !== yesterday) {
          // Streak broken - reset it
          await sql`
            UPDATE user_profiles
            SET streak = 0, updated_at = NOW()
            WHERE user_id = ${userId}::uuid
          `;
          p.streak = 0;
        }
        setProfile(p);
      } else {
        // Create new profile (is_admin defaults to FALSE)
        const newProfiles = await sql`
          INSERT INTO user_profiles (user_id, display_name, streak, total_xp, level)
          VALUES (${userId}::uuid, ${userName || "Traveler"}, 0, 0, 1)
          RETURNING
            id, user_id as "userId", display_name as "displayName",
            streak, total_xp as "totalXp", level,
            last_active_date as "lastActiveDate",
            is_admin as "isAdmin",
            created_at as "createdAt", updated_at as "updatedAt"
        `;
        setProfile(newProfiles[0] as UserProfile);
      }
    } catch (error) {
      console.error("Error fetching/creating profile:", error);
    } finally {
      setIsLoadingProfile(false);
    }
  }, []);

  // Refresh profile from database
  const refreshProfile = useCallback(async () => {
    if (!user) return;
    await fetchOrCreateProfile(user.id, user.name);
  }, [user, fetchOrCreateProfile]);

  // Update profile in database
  const updateProfile = useCallback(async (updates: Partial<Pick<UserProfile, "displayName">>) => {
    if (!user || !profile) return;

    try {
      const sql = getSql();
      const result = await sql`
        UPDATE user_profiles
        SET
          display_name = COALESCE(${updates.displayName ?? null}, display_name),
          updated_at = NOW()
        WHERE user_id = ${user.id}::uuid
        RETURNING
          id, user_id as "userId", display_name as "displayName",
          streak, total_xp as "totalXp", level,
          last_active_date as "lastActiveDate",
          is_admin as "isAdmin",
          created_at as "createdAt", updated_at as "updatedAt"
      `;
      if (result.length > 0) {
        setProfile(result[0] as UserProfile);
      }
    } catch (error) {
      console.error("Error updating profile:", error);
      throw error;
    }
  }, [user, profile]);

  // Add XP and update streak/level
  const addXp = useCallback(async (amount: number) => {
    if (!user || !profile) return;

    try {
      const sql = getSql();
      const today = getToday();
      const isNewDay = profile.lastActiveDate !== today;
      const newXp = profile.totalXp + amount;
      const newLevel = calculateLevel(newXp);
      const newStreak = isNewDay ? profile.streak + 1 : profile.streak;

      const result = await sql`
        UPDATE user_profiles
        SET
          total_xp = ${newXp},
          level = ${newLevel},
          streak = ${newStreak},
          last_active_date = ${today}::date,
          updated_at = NOW()
        WHERE user_id = ${user.id}::uuid
        RETURNING
          id, user_id as "userId", display_name as "displayName",
          streak, total_xp as "totalXp", level,
          last_active_date as "lastActiveDate",
          is_admin as "isAdmin",
          created_at as "createdAt", updated_at as "updatedAt"
      `;
      if (result.length > 0) {
        setProfile(result[0] as UserProfile);
      }
    } catch (error) {
      console.error("Error adding XP:", error);
      throw error;
    }
  }, [user, profile]);

  // Sign out handler
  const handleSignOut = useCallback(async () => {
    await authSignOut();
    setProfile(null);
  }, []);

  // Sync Google profile picture to user record if missing
  const syncGoogleProfilePicture = useCallback(async () => {
    if (!user || user.image) return; // Skip if no user or already has image

    try {
      const sql = getSql();

      // Query the Google account's idToken directly from the database
      const accounts = await sql`
        SELECT "idToken"
        FROM neon_auth.account
        WHERE "userId" = ${user.id}::uuid
          AND "providerId" = 'google'
          AND "idToken" IS NOT NULL
        LIMIT 1
      `;

      if (accounts.length === 0 || !accounts[0].idToken) return;

      const pictureUrl = extractGoogleProfilePicture(accounts[0].idToken);
      if (!pictureUrl) return;

      // Update the user's image in the database
      await sql`
        UPDATE neon_auth.user
        SET image = ${pictureUrl}
        WHERE id = ${user.id}::uuid AND (image IS NULL OR image = '')
      `;

      console.log("Synced Google profile picture to user record");

      // Reload the page to refresh the session with the new image
      window.location.reload();
    } catch (error) {
      console.error("Failed to sync Google profile picture:", error);
    }
  }, [user]);

  // Fetch profile when user changes
  useEffect(() => {
    if (user && !profile && !isLoadingProfile) {
      fetchOrCreateProfile(user.id, user.name);
    }
    if (!user) {
      setProfile(null);
    }
  }, [user, profile, isLoadingProfile, fetchOrCreateProfile]);

  // Sync Google profile picture when user logs in
  useEffect(() => {
    if (user && !user.image) {
      syncGoogleProfilePicture();
    }
  }, [user, syncGoogleProfilePicture]);

  const value: AuthContextType = {
    user,
    profile,
    isLoading: isPending || isLoadingProfile,
    isAuthenticated: !!user,
    isAdmin: profile?.isAdmin ?? false,
    signOut: handleSignOut,
    refreshProfile,
    updateProfile,
    addXp,
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
}
