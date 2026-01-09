import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { motion } from "framer-motion";
import { Mail, Lock, User, Loader2, Sparkles as SparklesIcon, Check } from "lucide-react";
import { signUp, signInWithGoogle } from "@/lib/auth-client";
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
      staggerChildren: 0.08,
      delayChildren: 0.15,
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

const benefits = [
  "Track your daily dua practice",
  "Build consistent spiritual habits",
  "Earn XP and maintain streaks",
];

import { Sparkles } from "@/components/animations/Sparkles";

export default function SignUpPage() {
  const navigate = useNavigate();
  const { toast } = useToast();
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [socialLoading, setSocialLoading] = useState<"google" | null>(null);

  const handleGoogleSignIn = async () => {
    setSocialLoading("google");
    try {
      await signInWithGoogle();
    } catch (err) {
      toast({
        title: "Error",
        description: "Could not sign up with Google. Please try again.",
        variant: "destructive",
      });
      setSocialLoading(null);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!name || !email || !password) {
      toast({
        title: "Missing fields",
        description: "Please fill in all required fields.",
        variant: "destructive",
      });
      return;
    }

    if (password.length < 8) {
      toast({
        title: "Password too short",
        description: "Password must be at least 8 characters long.",
        variant: "destructive",
      });
      return;
    }

    if (password !== confirmPassword) {
      toast({
        title: "Passwords don't match",
        description: "Please make sure your passwords match.",
        variant: "destructive",
      });
      return;
    }

    setIsLoading(true);

    try {
      const { error } = await signUp.email({
        email,
        password,
        name,
        callbackURL: "/",
      });

      if (error) {
        toast({
          title: "Sign up failed",
          description: error.message || "Could not create account. Please try again.",
          variant: "destructive",
        });
      } else {
        toast({
          title: "Account created!",
          description: "Welcome to RIZQ. Let's start your journey.",
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
    <div className="w-full min-h-screen lg:grid lg:grid-cols-2">
      {/* Left side - Form */}
      <div className="flex items-center justify-center py-12 px-0 sm:px-6 lg:px-8 bg-background relative overflow-hidden">
        {/* Background pattern */}
        <div className="fixed inset-0 islamic-pattern opacity-30 pointer-events-none lg:hidden" />
        <div className="absolute inset-0 islamic-pattern opacity-30 pointer-events-none hidden lg:block" />

        <motion.div
          className="relative w-full max-w-md z-10"
          variants={containerVariants}
          initial="hidden"
          animate="visible"
        >
          <motion.p
            className="text-center text-[29px] text-muted-foreground/60 mb-6 font-arabic"
            variants={itemVariants}
          >
            بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ
          </motion.p>
          <Card className="border-primary/10 shadow-elevated overflow-hidden bg-card/80 backdrop-blur-sm sm:rounded-xl rounded-none border-x-0 sm:border-x">
            {/* Dawn Illustration - Full Width Hero */}
            <motion.div
              className="relative w-full h-64 overflow-hidden"
              initial={{ opacity: 0, scale: 1.1 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ duration: 0.8 }}
            >
              <img
                src="/images/dawn-illustration.jpeg"
                alt="Dawn's First Light - A serene sunrise scene"
                className="w-full h-full object-cover object-[center_40%]"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-card/80 via-transparent to-transparent" />
              <Sparkles count={20} className="z-10" />
            </motion.div>

            {/* Top decorative border */}
            <div className="h-1 w-full bg-gradient-to-r from-transparent via-primary to-transparent" />

            <CardHeader className="text-center pb-2 pt-6">
              <motion.div variants={itemVariants}>
                <CardTitle className="font-display text-2xl">Begin Your Journey</CardTitle>
              </motion.div>
              <motion.div variants={itemVariants}>
                <CardDescription className="text-muted-foreground">
                  Create your account to start daily dua practice
                </CardDescription>
              </motion.div>

              {/* Benefits list */}
              <motion.div
                className="mt-4 space-y-2"
                variants={itemVariants}
              >
                {benefits.map((benefit, i) => (
                  <motion.div
                    key={benefit}
                    className="flex items-center justify-center gap-2 text-sm text-muted-foreground"
                    initial={{ opacity: 0, x: -10 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: 0.4 + i * 0.1 }}
                  >
                    <div className="flex h-4 w-4 items-center justify-center rounded-full bg-teal/20">
                      <Check className="h-2.5 w-2.5 text-teal" />
                    </div>
                    {benefit}
                  </motion.div>
                ))}
              </motion.div>
            </CardHeader>

            <form onSubmit={handleSubmit}>
              <CardContent className="space-y-3 pt-4">
                <motion.div className="space-y-2" variants={itemVariants}>
                  <Label htmlFor="name" className="text-sm font-medium">
                    Name
                  </Label>
                  <div className="relative">
                    <User className="absolute left-4 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                    <Input
                      id="name"
                      type="text"
                      placeholder="Your name"
                      value={name}
                      onChange={(e) => setName(e.target.value)}
                      className="pl-11 h-11 rounded-btn border-primary/10 bg-secondary/30 focus:border-primary/30 focus:ring-primary/20"
                      disabled={isLoading}
                    />
                  </div>
                </motion.div>

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
                      className="pl-11 h-11 rounded-btn border-primary/10 bg-secondary/30 focus:border-primary/30 focus:ring-primary/20"
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
                      placeholder="At least 8 characters"
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      className={cn(
                        "pl-11 h-11 rounded-btn border-primary/10 bg-secondary/30 focus:border-primary/30 focus:ring-primary/20",
                        password.length > 0 && password.length < 8 && "border-destructive/50"
                      )}
                      disabled={isLoading}
                    />
                    {password.length > 0 && (
                      <motion.span
                        className={cn(
                          "absolute right-3 top-1/2 -translate-y-1/2 text-xs",
                          password.length >= 8 ? "text-teal" : "text-muted-foreground"
                        )}
                        initial={{ opacity: 0, scale: 0.8 }}
                        animate={{ opacity: 1, scale: 1 }}
                      >
                        {password.length}/8
                      </motion.span>
                    )}
                  </div>
                </motion.div>

                <motion.div className="space-y-2" variants={itemVariants}>
                  <Label htmlFor="confirmPassword" className="text-sm font-medium">
                    Confirm Password
                  </Label>
                  <div className="relative">
                    <Lock className="absolute left-4 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                    <Input
                      id="confirmPassword"
                      type="password"
                      placeholder="Confirm your password"
                      value={confirmPassword}
                      onChange={(e) => setConfirmPassword(e.target.value)}
                      className={cn(
                        "pl-11 h-11 rounded-btn border-primary/10 bg-secondary/30 focus:border-primary/30 focus:ring-primary/20",
                        confirmPassword.length > 0 && password !== confirmPassword && "border-destructive/50"
                      )}
                      disabled={isLoading}
                    />
                    {confirmPassword.length > 0 && password === confirmPassword && (
                      <motion.div
                        className="absolute right-3 top-1/2 -translate-y-1/2"
                        initial={{ opacity: 0, scale: 0 }}
                        animate={{ opacity: 1, scale: 1 }}
                        transition={{ type: "spring", stiffness: 500, damping: 20 }}
                      >
                        <div className="flex h-5 w-5 items-center justify-center rounded-full bg-teal/20">
                          <Check className="h-3 w-3 text-teal" />
                        </div>
                      </motion.div>
                    )}
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
                          Creating account...
                        </>
                      ) : (
                        <>
                          <SparklesIcon className="h-4 w-4" />
                          Create Account
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

                {/* Google sign-up */}
                <motion.div className="w-full" variants={itemVariants}>
                  <motion.div whileHover={{ scale: 1.02 }} whileTap={{ scale: 0.98 }}>
                    <Button
                      type="button"
                      variant="outline"
                      className="w-full h-11 rounded-btn border-primary/10 bg-secondary/30 hover:bg-secondary/50"
                      onClick={handleGoogleSignIn}
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
                      Continue with Google
                    </Button>
                  </motion.div>
                </motion.div>

                <motion.p
                  className="text-sm text-center text-muted-foreground"
                  variants={itemVariants}
                >
                  Already have an account?{" "}
                  <Link
                    to="/signin"
                    className="text-primary hover:text-primary/80 font-medium transition-colors"
                  >
                    Sign in
                  </Link>
                </motion.p>
              </CardFooter>
            </form>

            {/* Bottom decorative border */}
            <div className="h-1 w-full bg-gradient-to-r from-transparent via-primary/30 to-transparent" />
          </Card>

        </motion.div>
      </div>

      {/* Right side - Image */}
      <div className="hidden lg:block relative overflow-hidden bg-muted">
        <img
          src="https://images.unsplash.com/photo-1596627685942-763483984530?q=80&w=2787&auto=format&fit=crop"
          alt="Beautiful Mosque Architecture"
          className="absolute inset-0 h-full w-full object-cover"
        />
        {/* Overlay */}
        <div className="absolute inset-0 bg-gradient-to-t from-background/80 via-background/20 to-transparent" />
        
        <div className="absolute bottom-12 left-12 right-12 z-10">
           <blockquote className="border-l-4 border-primary pl-4 py-2 bg-background/30 backdrop-blur-md rounded-r-lg">
             <p className="text-xl font-display text-white italic">
               "So remember Me; I will remember you. And be grateful to Me and do not deny Me."
             </p>
             <footer className="text-white/80 mt-2 text-sm">
               Surah Al-Baqarah (2:152)
             </footer>
           </blockquote>
        </div>
      </div>
    </div>
  );
}
