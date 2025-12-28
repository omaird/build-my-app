---
name: auth-patterns
description: "Authentication patterns for RIZQ App: Better Auth setup, protected routes, user profiles, and session management"
---

# RIZQ Authentication Patterns

## Auth Architecture

```
Better Auth (Session Management)
        ↓
  auth-client.ts (Client SDK)
        ↓
  AuthContext.tsx (React Context)
        ↓
  useAuth() Hook (Components)
```

## Auth Client Setup

```typescript
// src/lib/auth-client.ts
import { createAuthClient } from "better-auth/react";

export const authClient = createAuthClient({
  baseURL: import.meta.env.VITE_AUTH_URL,
});

export const {
  signIn,
  signUp,
  signOut,
  useSession,
} = authClient;
```

## Auth Context

```typescript
// src/contexts/AuthContext.tsx
import { createContext, useContext, useEffect, useState } from 'react';
import { useSession } from '@/lib/auth-client';
import { getSql } from '@/lib/db';

interface AuthUser {
  id: string;
  email: string;
  name: string | null;
  image: string | null;
}

interface UserProfile {
  id: number;
  userId: string;
  displayName: string;
  streak: number;
  totalXp: number;
  level: number;
  lastActiveDate: string | null;
}

interface AuthContextType {
  user: AuthUser | null;
  profile: UserProfile | null;
  isLoading: boolean;
  isAuthenticated: boolean;
  signOut: () => Promise<void>;
  refreshProfile: () => Promise<void>;
  updateProfile: (updates: Partial<UserProfile>) => Promise<void>;
  addXp: (amount: number) => Promise<void>;
}

const AuthContext = createContext<AuthContextType | null>(null);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const { data: session, isPending } = useSession();
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [isProfileLoading, setIsProfileLoading] = useState(true);

  const user = session?.user ? {
    id: session.user.id,
    email: session.user.email,
    name: session.user.name,
    image: session.user.image,
  } : null;

  // Fetch/create profile when user changes
  useEffect(() => {
    if (user?.id) {
      fetchOrCreateProfile(user.id);
    } else {
      setProfile(null);
      setIsProfileLoading(false);
    }
  }, [user?.id]);

  const fetchOrCreateProfile = async (userId: string) => {
    const sql = getSql();
    setIsProfileLoading(true);

    try {
      // Try to get existing profile
      let result = await sql`
        SELECT * FROM user_profiles WHERE user_id = ${userId}::uuid
      `;

      if (result.length === 0) {
        // Create new profile
        result = await sql`
          INSERT INTO user_profiles (user_id, display_name)
          VALUES (${userId}::uuid, 'Traveler')
          RETURNING *
        `;
      }

      setProfile(mapDbToProfile(result[0]));
    } catch (error) {
      console.error('Failed to fetch profile:', error);
    } finally {
      setIsProfileLoading(false);
    }
  };

  // ... rest of context implementation

  return (
    <AuthContext.Provider value={{
      user,
      profile,
      isLoading: isPending || isProfileLoading,
      isAuthenticated: !!user,
      signOut,
      refreshProfile,
      updateProfile,
      addXp,
    }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
}
```

## Protected Route

```typescript
// src/components/ProtectedRoute.tsx
import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { Loader2 } from 'lucide-react';

interface ProtectedRouteProps {
  children: React.ReactNode;
}

export function ProtectedRoute({ children }: ProtectedRouteProps) {
  const { isAuthenticated, isLoading } = useAuth();
  const location = useLocation();

  // Show loading while checking auth
  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background">
        <Loader2 className="w-8 h-8 animate-spin text-primary" />
      </div>
    );
  }

  // Redirect to signin if not authenticated
  if (!isAuthenticated) {
    return <Navigate to="/signin" state={{ from: location }} replace />;
  }

  return <>{children}</>;
}
```

## Route Setup

```typescript
// src/App.tsx
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { AuthProvider } from '@/contexts/AuthContext';
import { ProtectedRoute } from '@/components/ProtectedRoute';

function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Routes>
          {/* Public routes */}
          <Route path="/signin" element={<SignInPage />} />
          <Route path="/signup" element={<SignUpPage />} />

          {/* Protected routes */}
          <Route path="/" element={
            <ProtectedRoute><HomePage /></ProtectedRoute>
          } />
          <Route path="/library" element={
            <ProtectedRoute><LibraryPage /></ProtectedRoute>
          } />
          <Route path="/settings" element={
            <ProtectedRoute><SettingsPage /></ProtectedRoute>
          } />

          {/* Fallback */}
          <Route path="*" element={<NotFound />} />
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  );
}
```

## Sign In Page Pattern

```typescript
// src/pages/SignInPage.tsx
import { useState } from 'react';
import { useNavigate, useLocation, Link } from 'react-router-dom';
import { signIn } from '@/lib/auth-client';

export default function SignInPage() {
  const navigate = useNavigate();
  const location = useLocation();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  // Where to redirect after login
  const from = location.state?.from?.pathname || '/';

  const handleEmailSignIn = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError('');

    try {
      await signIn.email({ email, password });
      navigate(from, { replace: true });
    } catch (err) {
      setError('Invalid email or password');
    } finally {
      setIsLoading(false);
    }
  };

  const handleGoogleSignIn = async () => {
    setIsLoading(true);
    try {
      await signIn.social({ provider: 'google' });
      // Redirect happens automatically
    } catch (err) {
      setError('Failed to sign in with Google');
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center p-4">
      <div className="w-full max-w-md space-y-6">
        <h1 className="text-2xl font-bold text-center">Welcome Back</h1>

        <form onSubmit={handleEmailSignIn} className="space-y-4">
          {error && (
            <div className="p-3 bg-destructive/10 text-destructive rounded-lg">
              {error}
            </div>
          )}

          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="Email"
            className="w-full p-3 rounded-lg border"
            required
          />

          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="Password"
            className="w-full p-3 rounded-lg border"
            required
          />

          <button
            type="submit"
            disabled={isLoading}
            className="w-full p-3 bg-primary text-primary-foreground rounded-btn"
          >
            {isLoading ? 'Signing in...' : 'Sign In'}
          </button>
        </form>

        <div className="relative">
          <div className="absolute inset-0 flex items-center">
            <div className="w-full border-t" />
          </div>
          <div className="relative flex justify-center text-sm">
            <span className="px-2 bg-background text-muted-foreground">or</span>
          </div>
        </div>

        <button
          onClick={handleGoogleSignIn}
          disabled={isLoading}
          className="w-full p-3 border rounded-btn flex items-center justify-center gap-2"
        >
          <GoogleIcon /> Continue with Google
        </button>

        <p className="text-center text-muted-foreground">
          Don't have an account? <Link to="/signup" className="text-primary">Sign up</Link>
        </p>
      </div>
    </div>
  );
}
```

## Using Auth in Components

```typescript
// In any component
import { useAuth } from '@/contexts/AuthContext';

function MyComponent() {
  const { user, profile, isAuthenticated, signOut } = useAuth();

  if (!isAuthenticated) {
    return <Navigate to="/signin" />;
  }

  return (
    <div>
      <p>Welcome, {profile?.displayName || user?.name || 'Traveler'}</p>
      <p>Level {profile?.level} • {profile?.totalXp} XP</p>
      <p>🔥 {profile?.streak} day streak</p>
      <button onClick={signOut}>Sign Out</button>
    </div>
  );
}
```

## Profile Updates

```typescript
// Update display name
const { updateProfile } = useAuth();
await updateProfile({ displayName: 'New Name' });

// Add XP (also updates level)
const { addXp } = useAuth();
await addXp(25);

// Refresh profile from database
const { refreshProfile } = useAuth();
await refreshProfile();
```

## Streak Calculation

```typescript
// In AuthContext
const calculateStreak = (lastActiveDate: string | null, currentStreak: number) => {
  if (!lastActiveDate) return 0;

  const last = new Date(lastActiveDate);
  const today = new Date();

  // Reset hours for date comparison
  last.setHours(0, 0, 0, 0);
  today.setHours(0, 0, 0, 0);

  const diffDays = Math.floor(
    (today.getTime() - last.getTime()) / (1000 * 60 * 60 * 24)
  );

  if (diffDays === 0) {
    // Already active today
    return currentStreak;
  } else if (diffDays === 1) {
    // Active yesterday, streak continues
    return currentStreak;
  } else {
    // Missed a day, streak resets
    return 0;
  }
};
```

## Level Calculation

```typescript
// XP required for each level: 50 * level² + 50 * level
// Level 1: 100 XP
// Level 2: 300 XP (total)
// Level 3: 600 XP (total)

const calculateLevel = (totalXp: number): number => {
  // Solve: 50n² + 50n = xp
  // n = (-50 + sqrt(2500 + 200*xp)) / 100
  return Math.floor((-50 + Math.sqrt(2500 + 200 * totalXp)) / 100);
};

const xpForLevel = (level: number): number => {
  return 50 * level * level + 50 * level;
};

const xpToNextLevel = (totalXp: number): { current: number; required: number } => {
  const currentLevel = calculateLevel(totalXp);
  const currentLevelXp = xpForLevel(currentLevel);
  const nextLevelXp = xpForLevel(currentLevel + 1);

  return {
    current: totalXp - currentLevelXp,
    required: nextLevelXp - currentLevelXp,
  };
};
```

## Session Persistence

Better Auth handles session persistence automatically via cookies. The session survives:
- Page refreshes
- Browser restarts
- App updates

Session is invalidated when:
- User explicitly signs out
- Session expires (configured on server)
- Token is revoked

## Last-Used Provider Tracking

```typescript
// Store last-used auth provider
const LAST_PROVIDER_KEY = 'rizq_last_auth_provider';

const handleSignIn = async (provider: 'email' | 'google' | 'github') => {
  localStorage.setItem(LAST_PROVIDER_KEY, provider);
  // ... sign in logic
};

// On sign-in page, highlight last-used provider
const lastProvider = localStorage.getItem(LAST_PROVIDER_KEY);
```
