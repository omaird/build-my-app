import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { motion } from "framer-motion";
import { Moon, Sun, RotateCcw, LogOut, Mail, User, Link2, Unlink, Loader2, Check, Settings, Sparkles, Flame, Trophy, Shield, ChevronRight } from "lucide-react";
import { BottomNav } from "@/components/BottomNav";
import { useAuth } from "@/contexts/AuthContext";
import { listAccounts, linkGoogleAccount, unlinkGoogleAccount } from "@/lib/auth-client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Avatar, AvatarImage, AvatarFallback } from "@/components/ui/avatar";
import { Separator } from "@/components/ui/separator";
import { Badge } from "@/components/ui/badge";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog";
import { useToast } from "@/hooks/use-toast";

// Account type from Better Auth
interface LinkedAccount {
  id: string;
  providerId: string;
  accountId: string;
  createdAt: Date;
  updatedAt: Date;
}

const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.08,
      delayChildren: 0.1,
    },
  },
};

const itemVariants = {
  hidden: { opacity: 0, y: 15 },
  visible: {
    opacity: 1,
    y: 0,
    transition: { duration: 0.4 },
  },
};

export default function SettingsPage() {
  const navigate = useNavigate();
  const { user, profile, isAdmin, updateProfile, signOut } = useAuth();
  const { toast } = useToast();
  const [name, setName] = useState(profile?.displayName || user?.name || "");
  const [isDarkMode, setIsDarkMode] = useState(() =>
    document.documentElement.classList.contains("dark")
  );
  const [isSaving, setIsSaving] = useState(false);

  // Connected accounts state
  const [linkedAccounts, setLinkedAccounts] = useState<LinkedAccount[]>([]);
  const [isLoadingAccounts, setIsLoadingAccounts] = useState(true);
  const [linkingProvider, setLinkingProvider] = useState<string | null>(null);
  const [unlinkingProvider, setUnlinkingProvider] = useState<string | null>(null);

  // Fetch linked accounts on mount
  useEffect(() => {
    const fetchAccounts = async () => {
      try {
        const result = await listAccounts();
        if (result.data) {
          setLinkedAccounts(result.data as LinkedAccount[]);
        }
      } catch (error) {
        console.error("Failed to fetch accounts:", error);
      } finally {
        setIsLoadingAccounts(false);
      }
    };
    fetchAccounts();
  }, []);

  // Check if a provider is linked
  const isProviderLinked = (providerId: string) =>
    linkedAccounts.some(acc => acc.providerId === providerId);

  // Handle linking Google account
  const handleLinkGoogle = async () => {
    setLinkingProvider("google");
    try {
      await linkGoogleAccount();
      // Redirect will happen, page will reload with updated accounts
    } catch (error) {
      toast({
        title: "Error",
        description: "Could not link Google account. Please try again.",
        variant: "destructive",
      });
      setLinkingProvider(null);
    }
  };

  // Handle unlinking Google account
  const handleUnlinkGoogle = async () => {
    // Prevent unlinking if it's the only auth method
    if (linkedAccounts.length <= 1) {
      toast({
        title: "Cannot unlink",
        description: "You need at least one sign-in method. Add another account first.",
        variant: "destructive",
      });
      return;
    }

    setUnlinkingProvider("google");
    try {
      await unlinkGoogleAccount();
      setLinkedAccounts(prev => prev.filter(acc => acc.providerId !== "google"));
      toast({
        title: "Account unlinked",
        description: "Google account has been disconnected.",
      });
    } catch (error) {
      toast({
        title: "Error",
        description: "Could not unlink Google account. Please try again.",
        variant: "destructive",
      });
    } finally {
      setUnlinkingProvider(null);
    }
  };

  const handleNameSave = async () => {
    if (name.trim()) {
      setIsSaving(true);
      try {
        await updateProfile({ displayName: name.trim() });
        toast({
          title: "Name updated",
          description: "Your profile name has been saved.",
        });
      } catch {
        toast({
          title: "Error",
          description: "Could not save your name. Please try again.",
          variant: "destructive",
        });
      } finally {
        setIsSaving(false);
      }
    }
  };

  const handleSignOut = async () => {
    try {
      await signOut();
      toast({
        title: "Signed out",
        description: "You have been signed out successfully.",
      });
      navigate("/signin");
    } catch {
      toast({
        title: "Error",
        description: "Could not sign out. Please try again.",
        variant: "destructive",
      });
    }
  };

  const handleDarkModeToggle = (checked: boolean) => {
    setIsDarkMode(checked);
    if (checked) {
      document.documentElement.classList.add("dark");
      localStorage.setItem("theme", "dark");
    } else {
      document.documentElement.classList.remove("dark");
      localStorage.setItem("theme", "light");
    }
  };

  const handleReset = () => {
    // TODO: Implement reset functionality with database
    setName("Traveler");
    toast({
      title: "Progress reset",
      description: "All your progress has been cleared.",
      variant: "destructive",
    });
  };

  return (
    <div className="min-h-screen bg-background pb-24">
      {/* Background pattern */}
      <div className="fixed inset-0 islamic-pattern opacity-30 pointer-events-none" />

      {/* Gradient overlay at top */}
      <div className="fixed top-0 left-0 right-0 h-32 gradient-fade-down pointer-events-none z-10" />

      <motion.div
        className="relative mx-auto max-w-md px-4 pt-8"
        variants={containerVariants}
        initial="hidden"
        animate="visible"
      >
        {/* Header */}
        <motion.header className="mb-6" variants={itemVariants}>
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-islamic bg-primary/10">
              <Settings className="h-5 w-5 text-primary" />
            </div>
            <div>
              <h1 className="font-display text-2xl font-bold text-foreground">
                Settings
              </h1>
              <p className="text-sm text-muted-foreground">Manage your preferences</p>
            </div>
          </div>
        </motion.header>

        {/* Account Section */}
        <motion.div variants={itemVariants}>
          <Card className="mb-4 overflow-hidden shadow-soft border-primary/10">
            <CardHeader className="pb-3">
              <CardTitle className="text-base font-display">Account</CardTitle>
              <CardDescription>Your account information</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              {/* Profile Picture */}
              <div className="flex items-center gap-4">
                <motion.div whileHover={{ scale: 1.05 }}>
                  <Avatar className="h-16 w-16 ring-2 ring-primary/20 ring-offset-2 ring-offset-background shadow-soft">
                    {user?.image && (
                      <AvatarImage src={user.image} alt={user.name || "Profile"} />
                    )}
                    <AvatarFallback className="bg-gradient-to-br from-primary/20 to-primary/10 text-primary font-display">
                      <User className="h-8 w-8" />
                    </AvatarFallback>
                  </Avatar>
                </motion.div>
                <div>
                  <p className="font-display font-semibold text-lg">{profile?.displayName || user?.name || "Traveler"}</p>
                  <p className="text-sm text-muted-foreground">Level {profile?.level ?? 1}</p>
                </div>
              </div>

              <Separator />

              <div className="flex items-center gap-3">
                <Mail className="h-4 w-4 text-muted-foreground" />
                <div>
                  <p className="text-xs text-muted-foreground uppercase tracking-wider">Email</p>
                  <p className="font-medium text-sm">{user?.email}</p>
                </div>
              </div>

              <Separator />

              <div className="space-y-2">
                <Label htmlFor="name" className="text-xs uppercase tracking-wider text-muted-foreground">
                  Display Name
                </Label>
                <div className="flex gap-2">
                  <Input
                    id="name"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    placeholder="Enter your name"
                    className="h-11 rounded-btn"
                  />
                  <motion.div whileTap={{ scale: 0.95 }}>
                    <Button
                      onClick={handleNameSave}
                      disabled={name === (profile?.displayName || "") || !name.trim() || isSaving}
                      className="h-11 rounded-btn"
                    >
                      {isSaving ? "Saving..." : "Save"}
                    </Button>
                  </motion.div>
                </div>
              </div>

              <Separator />

              {/* Statistics */}
              <div className="space-y-2">
                <p className="text-xs font-medium uppercase tracking-wider text-muted-foreground">Statistics</p>
                <div className="grid grid-cols-3 gap-3">
                  <motion.div
                    className="relative overflow-hidden rounded-islamic bg-secondary/50 p-3 text-center"
                    whileHover={{ scale: 1.02 }}
                  >
                    <Trophy className="h-4 w-4 text-primary mx-auto mb-1" />
                    <p className="text-xl font-bold text-foreground font-mono">{profile?.level ?? 1}</p>
                    <p className="text-[10px] text-muted-foreground uppercase">Level</p>
                  </motion.div>
                  <motion.div
                    className="relative overflow-hidden rounded-islamic bg-gold-soft/20 p-3 text-center"
                    whileHover={{ scale: 1.02 }}
                  >
                    <Sparkles className="h-4 w-4 text-primary mx-auto mb-1" />
                    <p className="text-xl font-bold text-foreground font-mono">{profile?.totalXp ?? 0}</p>
                    <p className="text-[10px] text-muted-foreground uppercase">Total XP</p>
                  </motion.div>
                  <motion.div
                    className="relative overflow-hidden rounded-islamic bg-teal/20 p-3 text-center"
                    whileHover={{ scale: 1.02 }}
                  >
                    <Flame className="h-4 w-4 text-teal mx-auto mb-1" />
                    <p className="text-xl font-bold text-foreground font-mono">{profile?.streak ?? 0}</p>
                    <p className="text-[10px] text-muted-foreground uppercase">Streak</p>
                  </motion.div>
                </div>
              </div>
            </CardContent>
          </Card>
        </motion.div>

        {/* Admin Panel Section - Only visible to admins */}
        {isAdmin && (
          <motion.div variants={itemVariants}>
            <Card className="mb-4 overflow-hidden shadow-soft border-primary/10">
              <CardHeader className="pb-3">
                <CardTitle className="flex items-center gap-2 text-base font-display">
                  <Shield className="h-4 w-4 text-primary" />
                  Admin Panel
                </CardTitle>
                <CardDescription>Manage duas, journeys, categories, and users</CardDescription>
              </CardHeader>
              <CardContent>
                <motion.div whileTap={{ scale: 0.98 }}>
                  <Button
                    onClick={() => navigate("/admin")}
                    className="w-full gap-2 h-11 rounded-btn"
                  >
                    Open Admin Panel
                    <ChevronRight className="h-4 w-4" />
                  </Button>
                </motion.div>
              </CardContent>
            </Card>
          </motion.div>
        )}

        {/* Connected Accounts Section */}
        <motion.div variants={itemVariants}>
          <Card className="mb-4 overflow-hidden shadow-soft border-primary/10">
            <CardHeader className="pb-3">
              <CardTitle className="text-base font-display">Connected Accounts</CardTitle>
              <CardDescription>Link accounts for easier sign-in</CardDescription>
            </CardHeader>
            <CardContent className="space-y-3">
              {isLoadingAccounts ? (
                <div className="flex items-center justify-center py-4">
                  <Loader2 className="h-5 w-5 animate-spin text-muted-foreground" />
                </div>
              ) : (
                <>
                  {/* Google Account */}
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className="flex h-10 w-10 items-center justify-center rounded-full bg-muted">
                        <svg className="h-5 w-5" viewBox="0 0 24 24">
                          <path
                            d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                            fill="#4285F4"
                          />
                          <path
                            d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                            fill="#34A853"
                          />
                          <path
                            d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
                            fill="#FBBC05"
                          />
                          <path
                            d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
                            fill="#EA4335"
                          />
                        </svg>
                      </div>
                      <div>
                        <p className="font-medium">Google</p>
                        <p className="text-sm text-muted-foreground">
                          {isProviderLinked("google") ? "Connected" : "Not connected"}
                        </p>
                      </div>
                    </div>
                    {isProviderLinked("google") ? (
                      <div className="flex items-center gap-2">
                        <Badge variant="secondary" className="gap-1 bg-primary/10 text-primary border-primary/20">
                          <Check className="h-3 w-3" />
                          Linked
                        </Badge>
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={handleUnlinkGoogle}
                          disabled={unlinkingProvider === "google" || linkedAccounts.length <= 1}
                          className="text-muted-foreground hover:text-destructive"
                        >
                          {unlinkingProvider === "google" ? (
                            <Loader2 className="h-4 w-4 animate-spin" />
                          ) : (
                            <Unlink className="h-4 w-4" />
                          )}
                        </Button>
                      </div>
                    ) : (
                      <motion.div whileTap={{ scale: 0.95 }}>
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={handleLinkGoogle}
                          disabled={linkingProvider === "google"}
                          className="gap-1 rounded-btn"
                        >
                          {linkingProvider === "google" ? (
                            <Loader2 className="h-4 w-4 animate-spin" />
                          ) : (
                            <Link2 className="h-4 w-4" />
                          )}
                          Connect
                        </Button>
                      </motion.div>
                    )}
                  </div>

                  {/* Email/Password indicator */}
                  {isProviderLinked("credential") && (
                    <>
                      <Separator />
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-3">
                          <div className="flex h-10 w-10 items-center justify-center rounded-full bg-muted">
                            <Mail className="h-5 w-5 text-muted-foreground" />
                          </div>
                          <div>
                            <p className="font-medium">Email & Password</p>
                            <p className="text-sm text-muted-foreground">{user?.email}</p>
                          </div>
                        </div>
                        <Badge variant="secondary" className="gap-1 bg-primary/10 text-primary border-primary/20">
                          <Check className="h-3 w-3" />
                          Primary
                        </Badge>
                      </div>
                    </>
                  )}

                  {linkedAccounts.length <= 1 && (
                    <p className="text-xs text-muted-foreground pt-2">
                      Connect additional accounts for backup sign-in options
                    </p>
                  )}
                </>
              )}
            </CardContent>
          </Card>
        </motion.div>

        {/* Appearance Section */}
        <motion.div variants={itemVariants}>
          <Card className="mb-4 overflow-hidden shadow-soft border-primary/10">
            <CardHeader className="pb-3">
              <CardTitle className="text-base font-display">Appearance</CardTitle>
              <CardDescription>Customize how the app looks</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <motion.div
                    className="flex h-10 w-10 items-center justify-center rounded-full bg-muted"
                    animate={{ rotate: isDarkMode ? 180 : 0 }}
                    transition={{ duration: 0.3 }}
                  >
                    {isDarkMode ? <Moon className="h-5 w-5" /> : <Sun className="h-5 w-5" />}
                  </motion.div>
                  <div>
                    <p className="font-medium">Dark Mode</p>
                    <p className="text-sm text-muted-foreground">
                      {isDarkMode ? "Dark theme enabled" : "Light theme enabled"}
                    </p>
                  </div>
                </div>
                <Switch checked={isDarkMode} onCheckedChange={handleDarkModeToggle} />
              </div>
            </CardContent>
          </Card>
        </motion.div>

        {/* Account Actions */}
        <motion.div variants={itemVariants}>
          <Card className="mb-4 overflow-hidden shadow-soft border-primary/10">
            <CardHeader className="pb-3">
              <CardTitle className="text-base font-display">Account Actions</CardTitle>
              <CardDescription>Manage your account</CardDescription>
            </CardHeader>
            <CardContent className="space-y-3">
              <motion.div whileTap={{ scale: 0.98 }}>
                <Button variant="outline" className="w-full gap-2 h-11 rounded-btn" onClick={handleSignOut}>
                  <LogOut className="h-4 w-4" />
                  Sign Out
                </Button>
              </motion.div>
            </CardContent>
          </Card>
        </motion.div>

        {/* Danger Zone */}
        <motion.div variants={itemVariants}>
          <Card className="mb-4 border-destructive/20 overflow-hidden shadow-soft">
            <CardHeader className="pb-3">
              <CardTitle className="text-base text-destructive font-display">Danger Zone</CardTitle>
              <CardDescription>Irreversible actions</CardDescription>
            </CardHeader>
            <CardContent className="space-y-3">
              <AlertDialog>
                <AlertDialogTrigger asChild>
                  <motion.div whileTap={{ scale: 0.98 }}>
                    <Button variant="outline" className="w-full gap-2 h-11 rounded-btn border-destructive/30 text-destructive hover:bg-destructive/10">
                      <RotateCcw className="h-4 w-4" />
                      Reset All Progress
                    </Button>
                  </motion.div>
                </AlertDialogTrigger>
                <AlertDialogContent className="rounded-islamic">
                  <AlertDialogHeader>
                    <AlertDialogTitle className="font-display">Are you sure?</AlertDialogTitle>
                    <AlertDialogDescription>
                      This will permanently delete all your progress, including XP, streaks, and completed duas. This action cannot be undone.
                    </AlertDialogDescription>
                  </AlertDialogHeader>
                  <AlertDialogFooter>
                    <AlertDialogCancel className="rounded-btn">Cancel</AlertDialogCancel>
                    <AlertDialogAction onClick={handleReset} className="bg-destructive text-destructive-foreground hover:bg-destructive/90 rounded-btn">
                      Reset Everything
                    </AlertDialogAction>
                  </AlertDialogFooter>
                </AlertDialogContent>
              </AlertDialog>
            </CardContent>
          </Card>
        </motion.div>

        {/* App Info */}
        <motion.div
          className="mt-8 text-center text-sm text-muted-foreground pb-4"
          variants={itemVariants}
        >
          <p className="font-display font-semibold text-foreground">RIZQ</p>
          <p className="text-xs">Version 1.0.0 (Demo)</p>
          <p className="mt-2 text-xs">
            A gamified dua practice app
          </p>
        </motion.div>
      </motion.div>

      <BottomNav />
    </div>
  );
}
