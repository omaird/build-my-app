import { AlertCircle, RotateCcw } from "lucide-react";
import { motion } from "framer-motion";
import { Button } from "@/components/ui/button";

interface ErrorStateProps {
  title?: string;
  description?: string;
  error?: unknown;
  onRetry?: () => void;
  className?: string;
}

export function ErrorState({
  title = "Something went wrong",
  description,
  error,
  onRetry,
  className,
}: ErrorStateProps) {
  const detail =
    description ??
    (error instanceof Error ? error.message : undefined) ??
    "We couldn't load this content. Check your connection and try again.";

  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.96 }}
      animate={{ opacity: 1, scale: 1 }}
      role="alert"
      aria-live="polite"
      className={
        "mx-auto max-w-md rounded-islamic border-2 border-destructive/30 bg-destructive/5 p-6 text-center " +
        (className ?? "")
      }
    >
      <div className="mx-auto mb-3 flex h-12 w-12 items-center justify-center rounded-full bg-destructive/10">
        <AlertCircle className="h-6 w-6 text-destructive" />
      </div>
      <p className="text-sm font-semibold text-destructive">{title}</p>
      <p className="mt-1 text-xs text-muted-foreground">{detail}</p>
      {onRetry && (
        <Button
          variant="outline"
          size="sm"
          className="mt-4 gap-2"
          onClick={onRetry}
        >
          <RotateCcw className="h-3.5 w-3.5" />
          Try again
        </Button>
      )}
    </motion.div>
  );
}
