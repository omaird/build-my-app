import { useState, useEffect } from "react";
import { Link, useNavigate } from "react-router-dom";
import { motion } from "framer-motion";
import { Mail, Lock, Loader2, Clock, Sparkles } from "lucide-react";
import { signInWithGoogle, signInWithGitHub, signInWithEmail, getLastUsedProvider } from "@/lib/auth-client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";
import { useToast } from "@/hooks/use-toast";
import { cn } from "@/lib/utils";

const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.1,
      delayChildren: 0.2,
    },
  },
};

const itemVariants = {
  hidden: { opacity: 0, y: 20 },
  visible: {
    opacity: 1,
    y: 0,
    transition: { duration: 0.4 },
  },
};

export default function SignInPage() {
  const navigate = useNavigate();
  const { toast } = useToast();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [socialLoading, setSocialLoading] = useState<"google" | "github" | null>(null);
  const [lastUsedProvider, setLastUsedProvider] = useState<string | null>(null);

  useEffect(() => {
    setLastUsedProvider(getLastUsedProvider());
  }, []);

  const handleSocialSignIn = async (provider: "google" | "github") => {
    setSocialLoading(provider);
    try {
      if (provider === "google") {
        await signInWithGoogle();
      } else {
        await signInWithGitHub();
      }
    } catch (err) {
      toast({
        title: "Error",
        description: `Could not sign in with ${provider}. Please try again.`,
        variant: "destructive",
      });
      setSocialLoading(null);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!email || !password) {
      toast({
        title: "Missing fields",
        description: "Please enter both email and password.",
        variant: "destructive",
      });
      return;
    }

    setIsLoading(true);

    try {
      const { error } = await signInWithEmail(email, password);

      if (error) {
        toast({
          title: "Sign in failed",
          description: error.message || "Invalid email or password.",
          variant: "destructive",
        });
      } else {
        toast({
          title: "Welcome back!",
          description: "You have successfully signed in.",
        });
        navigate("/");
      }
    } catch (err) {
      toast({
        title: "Error",
        description: "Something went wrong. Please try again.",
        variant: "destructive",
      });
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-background flex items-center justify-center px-4 py-8 overflow-hidden">
      {/* Background pattern */}
      <div className="fixed inset-0 islamic-pattern opacity-30 pointer-events-none" />

      {/* Gradient overlays */}
      <div className="fixed top-0 left-0 right-0 h-48 gradient-fade-down pointer-events-none" />
      <div className="fixed bottom-0 left-0 right-0 h-48 bg-gradient-to-t from-background to-transparent pointer-events-none" />

      {/* Floating decorative elements */}
      <motion.div
        className="fixed top-20 left-10 text-4xl opacity-20 pointer-events-none"
        animate={{
          y: [0, -10, 0],
          rotate: [0, 5, 0],
        }}
        transition={{ duration: 6, repeat: Infinity }}
      >
        ✦
      </motion.div>
      <motion.div
        className="fixed bottom-32 right-10 text-3xl opacity-20 pointer-events-none"
        animate={{
          y: [0, 10, 0],
          rotate: [0, -5, 0],
        }}
        transition={{ duration: 5, repeat: Infinity, delay: 1 }}
      >
        ✧
      </motion.div>
      <motion.div
        className="fixed top-1/3 right-16 text-2xl opacity-15 pointer-events-none"
        animate={{
          scale: [1, 1.2, 1],
          opacity: [0.15, 0.25, 0.15],
        }}
        transition={{ duration: 4, repeat: Infinity, delay: 0.5 }}
      >
        ❋
      </motion.div>

      <motion.div
        className="relative w-full max-w-md"
        variants={containerVariants}
        initial="hidden"
        animate="visible"
      >
        <Card className="border-primary/10 shadow-elevated overflow-hidden">
          {/* Top decorative border */}
          <div className="h-1 w-full bg-gradient-to-r from-transparent via-primary to-transparent" />

          <CardHeader className="text-center pb-2">
            <motion.div variants={itemVariants}>
              {/* Ornate logo container */}
              <motion.div
                className="relative mx-auto mb-4 inline-block"
                whileHover={{ scale: 1.05 }}
              >
                {/* Outer decorative ring */}
                <div className="absolute -inset-3 rounded-full border-2 border-dashed border-primary/20 animate-[spin_20s_linear_infinite]" />

                {/* Glow effect */}
                <motion.div
                  className="absolute -inset-2 rounded-full bg-primary/10 blur-xl"
                  animate={{ scale: [1, 1.1, 1], opacity: [0.3, 0.5, 0.3] }}
                  transition={{ duration: 3, repeat: Infinity }}
                />

                {/* Main logo circle */}
                <div className="relative flex h-20 w-20 items-center justify-center rounded-full bg-gradient-to-br from-gold-soft/30 to-primary/20 border-2 border-primary/20 shadow-lg">
                  {/* Corner ornaments */}
                  <div className="absolute -top-1 -right-1 h-3 w-3 border-t-2 border-r-2 border-primary/40 rounded-tr-lg" />
                  <div className="absolute -bottom-1 -left-1 h-3 w-3 border-b-2 border-l-2 border-primary/40 rounded-bl-lg" />

                  <span className="text-4xl">🤲</span>
                </div>
              </motion.div>
            </motion.div>

            <motion.div variants={itemVariants}>
              <CardTitle className="font-display text-2xl">Welcome to RIZQ</CardTitle>
            </motion.div>
            <motion.div variants={itemVariants}>
              <CardDescription className="text-muted-foreground">
                Sign in to continue your dua practice journey
              </CardDescription>
            </motion.div>
          </CardHeader>

          <form onSubmit={handleSubmit}>
            <CardContent className="space-y-4">
              <motion.div className="space-y-2" variants={itemVariants}>
                <Label htmlFor="email" className="text-sm font-medium">
                  Email
                </Label>
                <div className="relative">
                  <Mail className="absolute left-4 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                  <Input
                    id="email"
                    type="email"
                    placeholder="you@example.com"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="pl-11 h-12 rounded-btn border-primary/10 bg-secondary/30 focus:border-primary/30 focus:ring-primary/20"
                    disabled={isLoading}
                  />
                </div>
              </motion.div>

              <motion.div className="space-y-2" variants={itemVariants}>
                <Label htmlFor="password" className="text-sm font-medium">
                  Password
                </Label>
                <div className="relative">
                  <Lock className="absolute left-4 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                  <Input
                    id="password"
                    type="password"
                    placeholder="Enter your password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    className="pl-11 h-12 rounded-btn border-primary/10 bg-secondary/30 focus:border-primary/30 focus:ring-primary/20"
                    disabled={isLoading}
                  />
                </div>
              </motion.div>
            </CardContent>

            <CardFooter className="flex flex-col gap-4 pt-2">
              <motion.div className="w-full" variants={itemVariants}>
                <motion.div whileTap={{ scale: 0.98 }}>
                  <Button
                    type="submit"
                    className="w-full h-12 rounded-btn btn-gradient gap-2"
                    disabled={isLoading || socialLoading !== null}
                  >
                    {isLoading ? (
                      <>
                        <Loader2 className="h-4 w-4 animate-spin" />
                        Signing in...
                      </>
                    ) : (
                      <>
                        <Sparkles className="h-4 w-4" />
                        Sign In
                      </>
                    )}
                  </Button>
                </motion.div>
              </motion.div>

              {/* Divider */}
              <motion.div className="relative w-full" variants={itemVariants}>
                <div className="absolute inset-0 flex items-center">
                  <span className="w-full border-t border-primary/10" />
                </div>
                <div className="relative flex justify-center">
                  <span className="bg-card px-3 text-xs uppercase text-muted-foreground tracking-wider">
                    Or continue with
                  </span>
                </div>
              </motion.div>

              {/* Social buttons */}
              <motion.div
                className="grid grid-cols-2 gap-3 w-full"
                variants={itemVariants}
              >
                <div className="relative">
                  <motion.div whileHover={{ scale: 1.02 }} whileTap={{ scale: 0.98 }}>
                    <Button
                      type="button"
                      variant="outline"
                      className={cn(
                        "w-full h-11 rounded-btn border-primary/10 bg-secondary/30 hover:bg-secondary/50",
                        lastUsedProvider === "google" && "ring-2 ring-primary/30"
                      )}
                      onClick={() => handleSocialSignIn("google")}
                      disabled={isLoading || socialLoading !== null}
                    >
                      {socialLoading === "google" ? (
                        <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                      ) : (
                        <svg className="mr-2 h-4 w-4" viewBox="0 0 24 24">
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
                      )}
                      Google
                    </Button>
                  </motion.div>
                  {lastUsedProvider === "google" && (
                    <motion.span
                      className="absolute -top-2 -right-2 flex items-center gap-1 rounded-full gradient-primary px-2 py-0.5 text-[10px] font-medium text-primary-foreground shadow-sm"
                      initial={{ scale: 0 }}
                      animate={{ scale: 1 }}
                      transition={{ type: "spring", stiffness: 500, damping: 20 }}
                    >
                      <Clock className="h-2.5 w-2.5" />
                      Last used
                    </motion.span>
                  )}
                </div>

                <div className="relative">
                  <motion.div whileHover={{ scale: 1.02 }} whileTap={{ scale: 0.98 }}>
                    <Button
                      type="button"
                      variant="outline"
                      className={cn(
                        "w-full h-11 rounded-btn border-primary/10 bg-secondary/30 hover:bg-secondary/50",
                        lastUsedProvider === "github" && "ring-2 ring-primary/30"
                      )}
                      onClick={() => handleSocialSignIn("github")}
                      disabled={isLoading || socialLoading !== null}
                    >
                      {socialLoading === "github" ? (
                        <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                      ) : (
                        <svg className="mr-2 h-4 w-4" viewBox="0 0 24 24" fill="currentColor">
                          <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z" />
                        </svg>
                      )}
                      GitHub
                    </Button>
                  </motion.div>
                  {lastUsedProvider === "github" && (
                    <motion.span
                      className="absolute -top-2 -right-2 flex items-center gap-1 rounded-full gradient-primary px-2 py-0.5 text-[10px] font-medium text-primary-foreground shadow-sm"
                      initial={{ scale: 0 }}
                      animate={{ scale: 1 }}
                      transition={{ type: "spring", stiffness: 500, damping: 20 }}
                    >
                      <Clock className="h-2.5 w-2.5" />
                      Last used
                    </motion.span>
                  )}
                </div>
              </motion.div>

              {lastUsedProvider === "credential" && (
                <motion.p
                  className="text-xs text-center text-muted-foreground flex items-center justify-center gap-1.5"
                  variants={itemVariants}
                >
                  <Clock className="h-3 w-3 text-primary" />
                  You last signed in with email
                </motion.p>
              )}

              <motion.p
                className="text-sm text-center text-muted-foreground"
                variants={itemVariants}
              >
                Don't have an account?{" "}
                <Link
                  to="/signup"
                  className="text-primary hover:text-primary/80 font-medium transition-colors"
                >
                  Sign up
                </Link>
              </motion.p>
            </CardFooter>
          </form>

          {/* Bottom decorative border */}
          <div className="h-1 w-full bg-gradient-to-r from-transparent via-primary/30 to-transparent" />
        </Card>

        {/* Bismillah text below card */}
        <motion.p
          className="text-center text-xs text-muted-foreground/60 mt-6 font-arabic"
          variants={itemVariants}
        >
          بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ
        </motion.p>
      </motion.div>
    </div>
  );
}
