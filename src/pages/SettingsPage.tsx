import { useState } from "react";
import { Moon, Sun, RotateCcw, LogOut } from "lucide-react";
import { BottomNav } from "@/components/BottomNav";
import { useUserProfile } from "@/hooks/useUserData";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Separator } from "@/components/ui/separator";
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

export default function SettingsPage() {
  const { profile, updateName, resetProfile } = useUserProfile();
  const { toast } = useToast();
  const [name, setName] = useState(profile.name);
  const [isDarkMode, setIsDarkMode] = useState(() => 
    document.documentElement.classList.contains("dark")
  );

  const handleNameSave = () => {
    if (name.trim()) {
      updateName(name.trim());
      toast({
        title: "Name updated",
        description: "Your profile name has been saved.",
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
    resetProfile();
    setName("Traveler");
    toast({
      title: "Progress reset",
      description: "All your progress has been cleared.",
      variant: "destructive",
    });
  };

  return (
    <div className="min-h-screen bg-background pb-20">
      <div className="mx-auto max-w-md px-4 pt-8">
        {/* Header */}
        <header className="mb-6">
          <h1 className="text-2xl font-bold text-foreground">Settings</h1>
          <p className="text-sm text-muted-foreground">Manage your preferences</p>
        </header>

        {/* Profile Section */}
        <Card className="mb-4">
          <CardHeader>
            <CardTitle className="text-base">Profile</CardTitle>
            <CardDescription>Your personal information</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="name">Display Name</Label>
              <div className="flex gap-2">
                <Input
                  id="name"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="Enter your name"
                />
                <Button onClick={handleNameSave} disabled={name === profile.name || !name.trim()}>
                  Save
                </Button>
              </div>
            </div>

            <Separator />

            <div className="space-y-2">
              <p className="text-sm font-medium">Statistics</p>
              <div className="grid grid-cols-3 gap-4 text-center">
                <div className="rounded-lg bg-secondary p-3">
                  <p className="text-lg font-bold text-foreground">{profile.level}</p>
                  <p className="text-xs text-muted-foreground">Level</p>
                </div>
                <div className="rounded-lg bg-secondary p-3">
                  <p className="text-lg font-bold text-foreground">{profile.totalXp}</p>
                  <p className="text-xs text-muted-foreground">Total XP</p>
                </div>
                <div className="rounded-lg bg-secondary p-3">
                  <p className="text-lg font-bold text-foreground">{profile.streak}</p>
                  <p className="text-xs text-muted-foreground">Streak</p>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Appearance Section */}
        <Card className="mb-4">
          <CardHeader>
            <CardTitle className="text-base">Appearance</CardTitle>
            <CardDescription>Customize how the app looks</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                {isDarkMode ? <Moon className="h-5 w-5" /> : <Sun className="h-5 w-5" />}
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

        {/* Danger Zone */}
        <Card className="border-destructive/20">
          <CardHeader>
            <CardTitle className="text-base text-destructive">Danger Zone</CardTitle>
            <CardDescription>Irreversible actions</CardDescription>
          </CardHeader>
          <CardContent className="space-y-3">
            <AlertDialog>
              <AlertDialogTrigger asChild>
                <Button variant="outline" className="w-full gap-2 border-destructive/30 text-destructive hover:bg-destructive/10">
                  <RotateCcw className="h-4 w-4" />
                  Reset All Progress
                </Button>
              </AlertDialogTrigger>
              <AlertDialogContent>
                <AlertDialogHeader>
                  <AlertDialogTitle>Are you sure?</AlertDialogTitle>
                  <AlertDialogDescription>
                    This will permanently delete all your progress, including XP, streaks, and completed duas. This action cannot be undone.
                  </AlertDialogDescription>
                </AlertDialogHeader>
                <AlertDialogFooter>
                  <AlertDialogCancel>Cancel</AlertDialogCancel>
                  <AlertDialogAction onClick={handleReset} className="bg-destructive text-destructive-foreground hover:bg-destructive/90">
                    Reset Everything
                  </AlertDialogAction>
                </AlertDialogFooter>
              </AlertDialogContent>
            </AlertDialog>
          </CardContent>
        </Card>

        {/* App Info */}
        <div className="mt-8 text-center text-sm text-muted-foreground">
          <p className="font-medium">RIZQ</p>
          <p>Version 1.0.0 (Demo)</p>
          <p className="mt-2 text-xs">
            A gamified dua practice app
          </p>
        </div>
      </div>

      <BottomNav />
    </div>
  );
}