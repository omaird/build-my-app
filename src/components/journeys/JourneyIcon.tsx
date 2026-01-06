import { cn } from "@/lib/utils";
import type { Journey } from "@/types/habit";

interface JourneyIconProps {
  emoji: string;
  name: string;
  className?: string;
  size?: "sm" | "md" | "lg";
}

const sizeClasses = {
  sm: "w-4 h-4",
  md: "w-6 h-6",
  lg: "text-2xl",
};

export function JourneyIcon({ emoji, name, className, size = "lg" }: JourneyIconProps) {
  if (emoji.startsWith('/images/')) {
    const sizeClass = size === "lg" ? "w-6 h-6" : sizeClasses[size];
    return (
      <img 
        src={emoji} 
        alt={name} 
        className={cn("object-cover rounded-full inline-block align-middle", sizeClass, className)}
      />
    );
  }
  
  const textSizeClass = size === "lg" ? "text-2xl" : size === "md" ? "text-lg" : "text-base";
  return <span className={cn("inline-block align-middle", textSizeClass, className)}>{emoji}</span>;
}

