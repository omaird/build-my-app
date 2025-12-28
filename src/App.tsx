import { useState, useEffect } from "react";
import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route, useLocation } from "react-router-dom";
import { AuthProvider, useAuth } from "@/contexts/AuthContext";
import { ProtectedRoute } from "@/components/ProtectedRoute";
import { WelcomeModal } from "@/components/WelcomeModal";
import HomePage from "./pages/HomePage";
import LibraryPage from "./pages/LibraryPage";
import PracticePage from "./pages/PracticePage";
import DailyAdkharPage from "./pages/DailyAdkharPage";
import SettingsPage from "./pages/SettingsPage";
import JourneysPage from "./pages/JourneysPage";
import JourneyDetailPage from "./pages/JourneyDetailPage";
import SignInPage from "./pages/SignInPage";
import SignUpPage from "./pages/SignUpPage";
import NotFound from "./pages/NotFound";

const queryClient = new QueryClient();

// Key for localStorage to track if welcome modal has been shown
const WELCOME_SHOWN_KEY = "rizq_welcome_shown";

function WelcomeModalWrapper() {
  const { user, profile, isLoading } = useAuth();
  const location = useLocation();
  const [showWelcome, setShowWelcome] = useState(false);

  useEffect(() => {
    // Only show welcome modal if:
    // 1. User is authenticated and profile is loaded
    // 2. This is a new user (totalXp === 0 and streak === 0)
    // 3. We haven't shown the modal in this session yet
    // 4. We're on a protected route (not signin/signup)
    if (
      user &&
      profile &&
      !isLoading &&
      profile.totalXp === 0 &&
      profile.streak === 0 &&
      !location.pathname.startsWith("/sign") &&
      !sessionStorage.getItem(WELCOME_SHOWN_KEY)
    ) {
      // Also check localStorage for persistent "don't show again"
      const hasSeenWelcome = localStorage.getItem(WELCOME_SHOWN_KEY);
      if (!hasSeenWelcome) {
        setShowWelcome(true);
      }
    }
  }, [user, profile, isLoading, location.pathname]);

  const handleCloseWelcome = () => {
    setShowWelcome(false);
    // Mark as shown for this session and permanently
    sessionStorage.setItem(WELCOME_SHOWN_KEY, "true");
    localStorage.setItem(WELCOME_SHOWN_KEY, "true");
  };

  return (
    <WelcomeModal
      isOpen={showWelcome}
      onClose={handleCloseWelcome}
      userName={user?.name || profile?.displayName || undefined}
    />
  );
}

function AppRoutes() {
  return (
    <>
      <WelcomeModalWrapper />
      <Routes>
        {/* Public routes */}
        <Route path="/signin" element={<SignInPage />} />
        <Route path="/signup" element={<SignUpPage />} />

        {/* Protected routes */}
        <Route path="/" element={<ProtectedRoute><HomePage /></ProtectedRoute>} />
        <Route path="/library" element={<ProtectedRoute><LibraryPage /></ProtectedRoute>} />
        <Route path="/adkhar" element={<ProtectedRoute><DailyAdkharPage /></ProtectedRoute>} />
        <Route path="/practice" element={<ProtectedRoute><PracticePage /></ProtectedRoute>} />
        <Route path="/practice/:duaId" element={<ProtectedRoute><PracticePage /></ProtectedRoute>} />
        <Route path="/journeys" element={<ProtectedRoute><JourneysPage /></ProtectedRoute>} />
        <Route path="/journeys/:slug" element={<ProtectedRoute><JourneyDetailPage /></ProtectedRoute>} />
        <Route path="/settings" element={<ProtectedRoute><SettingsPage /></ProtectedRoute>} />

        <Route path="*" element={<NotFound />} />
      </Routes>
    </>
  );
}

const App = () => (
  <QueryClientProvider client={queryClient}>
    <TooltipProvider>
      <Toaster />
      <Sonner />
      <BrowserRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
        <AuthProvider>
          <AppRoutes />
        </AuthProvider>
      </BrowserRouter>
    </TooltipProvider>
  </QueryClientProvider>
);

export default App;
