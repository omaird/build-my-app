import { createAuthClient } from "better-auth/react";

// Create the Better Auth client pointing to Neon Auth
export const authClient = createAuthClient({
  baseURL: import.meta.env.VITE_AUTH_URL || "https://ep-green-fire-af4a3sg5.neonauth.c-2.us-west-2.aws.neon.tech/neondb/auth",
});

// Export commonly used methods and hooks for convenience
export const {
  signIn,
  signUp,
  signOut,
  useSession,
  getSession,
  linkSocial,
  unlinkAccount,
  listAccounts,
} = authClient;

// Social sign-in helpers with "last used" tracking
export const signInWithGoogle = () => {
  localStorage.setItem("lastUsedProvider", "google");
  return signIn.social({ provider: "google", callbackURL: "/" });
};


// Track email sign-in as well
export const signInWithEmail = async (email: string, password: string) => {
  localStorage.setItem("lastUsedProvider", "credential");
  return signIn.email({ email, password, callbackURL: "/" });
};

// Get the last used provider
export const getLastUsedProvider = (): string | null => {
  return localStorage.getItem("lastUsedProvider");
};

// Link social account helpers
export const linkGoogleAccount = () => linkSocial({ provider: "google", callbackURL: "/settings" });

// Unlink account helper
export const unlinkGoogleAccount = () => unlinkAccount({ providerId: "google" });

// Helper to decode JWT payload (base64url to JSON)
const decodeJwtPayload = (token: string): Record<string, unknown> | null => {
  try {
    const parts = token.split(".");
    if (parts.length !== 3) return null;
    const payload = parts[1]
      .replace(/-/g, "+")
      .replace(/_/g, "/");
    const decoded = atob(payload);
    return JSON.parse(decoded);
  } catch {
    return null;
  }
};

// Extract Google profile picture from idToken
export const extractGoogleProfilePicture = (idToken: string): string | null => {
  const payload = decodeJwtPayload(idToken);
  if (payload && typeof payload.picture === "string") {
    return payload.picture;
  }
  return null;
};
