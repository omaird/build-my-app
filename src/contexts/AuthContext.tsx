import { createContext, useContext, useEffect, useState, useCallback, ReactNode } from "react";
import {
  GithubAuthProvider,
  GoogleAuthProvider,
  onAuthStateChanged,
  signInWithPopup,
  signOut as firebaseSignOut,
  type User as FirebaseUser,
} from "firebase/auth";
import {
  doc,
  getDoc,
  runTransaction,
  serverTimestamp,
  setDoc,
  Timestamp,
  updateDoc,
} from "firebase/firestore";
import { getDb, getFirebaseAuth } from "@/lib/firebase";
import { toast } from "@/hooks/use-toast";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface UserProfile {
  id?: string;
  userId: string;
  displayName: string | null;
  email: string | null;
  photoURL: string | null;
  streak: number;
  totalXp: number;
  level: number;
  lastActiveDate: string | null;
  isAdmin: boolean;
  createdAt?: string;
  updatedAt?: string;
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
  signInWithGoogle: () => Promise<void>;
  signInWithGithub: () => Promise<void>;
  refreshProfile: () => Promise<void>;
  updateProfile: (updates: Partial<Pick<UserProfile, "displayName">>) => Promise<void>;
  addXp: (amount: number) => Promise<void>;
}

const AuthContext = createContext<AuthContextType | null>(null);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const calculateLevel = (xp: number): number => {
  let level = 1;
  while (50 * level * level + 50 * level <= xp) {
    level++;
  }
  return level;
};

const getToday = () => new Date().toISOString().split("T")[0];

const getYesterday = () =>
  new Date(Date.now() - 86_400_000).toISOString().split("T")[0];

function mapFirebaseUserToAuthUser(fbUser: FirebaseUser): AuthUser {
  return {
    id: fbUser.uid,
    email: fbUser.email ?? "",
    name: fbUser.displayName,
    image: fbUser.photoURL,
  };
}

function timestampToIsoString(value: unknown): string | undefined {
  if (!value) return undefined;
  if (value instanceof Timestamp) return value.toDate().toISOString();
  if (value instanceof Date) return value.toISOString();
  return undefined;
}

function snapshotToProfile(userId: string, data: Record<string, unknown>): UserProfile {
  return {
    id: userId,
    userId,
    displayName: (data.displayName as string | null | undefined) ?? null,
    email: (data.email as string | null | undefined) ?? null,
    photoURL: (data.photoURL as string | null | undefined) ?? null,
    streak: (data.streak as number | undefined) ?? 0,
    totalXp: (data.totalXp as number | undefined) ?? 0,
    level: (data.level as number | undefined) ?? 1,
    lastActiveDate: (data.lastActiveDate as string | null | undefined) ?? null,
    isAdmin: (data.isAdmin as boolean | undefined) ?? false,
    createdAt: timestampToIsoString(data.createdAt),
    updatedAt: timestampToIsoString(data.updatedAt),
  };
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AuthUser | null>(null);
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [isAuthLoading, setIsAuthLoading] = useState(true);
  const [isLoadingProfile, setIsLoadingProfile] = useState(false);

  const getOrCreateProfile = useCallback(
    async (fbUser: FirebaseUser): Promise<UserProfile> => {
      const db = getDb();
      const ref = doc(db, "user_profiles", fbUser.uid);
      const snapshot = await getDoc(ref);

      if (snapshot.exists()) {
        const data = snapshot.data() as Record<string, unknown>;
        const profile = snapshotToProfile(fbUser.uid, data);

        // Keep email/photoURL on the profile doc in sync with the auth account.
        // The admin Users page reads these denormalized fields from the doc,
        // so drift here means blank rows in the admin UI.
        const fbEmail = fbUser.email ?? null;
        const fbPhoto = fbUser.photoURL ?? null;
        if (profile.email !== fbEmail || profile.photoURL !== fbPhoto) {
          // Best-effort: don't block sign-in if this write fails.
          try {
            await updateDoc(ref, {
              email: fbEmail,
              photoURL: fbPhoto,
              updatedAt: serverTimestamp(),
            });
            profile.email = fbEmail;
            profile.photoURL = fbPhoto;
          } catch (error) {
            console.warn(
              "Failed to refresh denormalized email/photoURL on user_profiles:",
              error,
            );
          }
        }

        return profile;
      }

      const defaults = {
        userId: fbUser.uid,
        displayName: fbUser.displayName ?? "Traveler",
        email: fbUser.email ?? null,
        photoURL: fbUser.photoURL ?? null,
        streak: 0,
        totalXp: 0,
        level: 1,
        lastActiveDate: null,
        isAdmin: false,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      };
      await setDoc(ref, defaults);

      return {
        id: fbUser.uid,
        userId: fbUser.uid,
        displayName: defaults.displayName,
        email: defaults.email,
        photoURL: defaults.photoURL,
        streak: 0,
        totalXp: 0,
        level: 1,
        lastActiveDate: null,
        isAdmin: false,
      };
    },
    [],
  );

  // Listen to Firebase auth state changes
  useEffect(() => {
    const auth = getFirebaseAuth();
    const unsubscribe = onAuthStateChanged(auth, async (fbUser) => {
      if (!fbUser) {
        setUser(null);
        setProfile(null);
        setIsAuthLoading(false);
        return;
      }

      const mapped = mapFirebaseUserToAuthUser(fbUser);
      setUser(mapped);
      setIsLoadingProfile(true);
      try {
        const loadedProfile = await getOrCreateProfile(fbUser);
        setProfile(loadedProfile);
      } catch (error) {
        // If the profile read/create fails (Firestore rules denial, network
        // drop, etc.) we'd otherwise leave the user "authenticated" but with
        // no profile — a zombie state with no recovery path. Sign them out so
        // the listener fires again with fbUser === null and routes them back
        // to sign-in cleanly.
        console.error("Failed to load user profile, signing out:", error);
        toast({
          title: "Couldn't load your profile",
          description: "Please sign in again.",
          variant: "destructive",
        });
        try {
          await firebaseSignOut(auth);
        } catch (signOutError) {
          console.error("Failed to sign out after profile load failure:", signOutError);
        }
        // Don't set profile here — the next listener fire will clear state.
      } finally {
        setIsLoadingProfile(false);
        setIsAuthLoading(false);
      }
    });

    return () => unsubscribe();
  }, [getOrCreateProfile]);

  // ---------------------------------------------------------------------
  // Public actions
  // ---------------------------------------------------------------------

  const refreshProfile = useCallback(async () => {
    const auth = getFirebaseAuth();
    const fbUser = auth.currentUser;
    if (!fbUser) return;

    setIsLoadingProfile(true);
    try {
      const loadedProfile = await getOrCreateProfile(fbUser);
      setProfile(loadedProfile);
    } finally {
      setIsLoadingProfile(false);
    }
  }, [getOrCreateProfile]);

  const updateProfile = useCallback(
    async (updates: Partial<Pick<UserProfile, "displayName">>) => {
      const auth = getFirebaseAuth();
      const fbUser = auth.currentUser;
      if (!fbUser) return;

      const db = getDb();
      const ref = doc(db, "user_profiles", fbUser.uid);

      await updateDoc(ref, {
        updatedAt: serverTimestamp(),
        ...(updates.displayName !== undefined && { displayName: updates.displayName }),
      });
      await refreshProfile();
    },
    [refreshProfile],
  );

  const addXp = useCallback(async (amount: number) => {
    const auth = getFirebaseAuth();
    const fbUser = auth.currentUser;
    if (!fbUser) return;

    const db = getDb();
    const ref = doc(db, "user_profiles", fbUser.uid);
    const today = getToday();
    const yesterday = getYesterday();

    const updated = await runTransaction(db, async (transaction) => {
      const snap = await transaction.get(ref);
      if (!snap.exists()) {
        throw new Error("Profile not found");
      }
      const data = snap.data() as Record<string, unknown>;
      const currentXp = (data.totalXp as number | undefined) ?? 0;
      const currentStreak = (data.streak as number | undefined) ?? 0;
      const lastActive = (data.lastActiveDate as string | null | undefined) ?? null;

      const newXp = currentXp + amount;
      const newLevel = calculateLevel(newXp);
      let newStreak: number;
      if (lastActive === today) {
        newStreak = currentStreak;
      } else if (lastActive === yesterday) {
        newStreak = currentStreak + 1;
      } else {
        newStreak = 1;
      }

      transaction.update(ref, {
        totalXp: newXp,
        level: newLevel,
        streak: newStreak,
        lastActiveDate: today,
        updatedAt: serverTimestamp(),
      });

      return {
        ...snapshotToProfile(fbUser.uid, data),
        totalXp: newXp,
        level: newLevel,
        streak: newStreak,
        lastActiveDate: today,
      } as UserProfile;
    });

    setProfile(updated);
  }, []);

  const handleSignOut = useCallback(async () => {
    const auth = getFirebaseAuth();
    await firebaseSignOut(auth);
    // onAuthStateChanged listener will clear user/profile state
  }, []);

  const signInWithGoogle = useCallback(async () => {
    const auth = getFirebaseAuth();
    const provider = new GoogleAuthProvider();
    await signInWithPopup(auth, provider);
    localStorage.setItem("lastUsedProvider", "google");
  }, []);

  const signInWithGithub = useCallback(async () => {
    const auth = getFirebaseAuth();
    const provider = new GithubAuthProvider();
    await signInWithPopup(auth, provider);
    localStorage.setItem("lastUsedProvider", "github");
  }, []);

  const value: AuthContextType = {
    user,
    profile,
    isLoading: isAuthLoading || isLoadingProfile,
    isAuthenticated: !!user,
    isAdmin: profile?.isAdmin ?? false,
    signOut: handleSignOut,
    signInWithGoogle,
    signInWithGithub,
    refreshProfile,
    updateProfile,
    addXp,
  };

  return (
    <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
}
