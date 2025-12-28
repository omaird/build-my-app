import { motion } from 'framer-motion';
import { BookOpen, Info } from 'lucide-react';
import { cn } from '@/lib/utils';

interface PracticeContextTabsProps {
  value: 'practice' | 'context';
  onValueChange: (value: 'practice' | 'context') => void;
  hasContext?: boolean;
}

export function PracticeContextTabs({
  value,
  onValueChange,
  hasContext = true,
}: PracticeContextTabsProps) {
  return (
    <div className="w-full">
      <div
        className={cn(
          'grid w-full grid-cols-2 h-11',
          'bg-secondary/50 rounded-btn p-1'
        )}
      >
        <button
          onClick={() => onValueChange('practice')}
          className={cn(
            'relative flex items-center justify-center gap-2 rounded-[12px] text-sm font-medium',
            'transition-colors duration-200',
            value === 'practice'
              ? 'text-primary'
              : 'text-muted-foreground hover:text-foreground'
          )}
        >
          {value === 'practice' && (
            <motion.div
              layoutId="tab-indicator"
              className="absolute inset-0 bg-card shadow-sm rounded-[12px]"
              transition={{ type: 'spring', stiffness: 400, damping: 30 }}
            />
          )}
          <span className="relative z-10 flex items-center gap-2">
            <BookOpen className="h-4 w-4" />
            Practice
          </span>
        </button>

        <button
          onClick={() => hasContext && onValueChange('context')}
          disabled={!hasContext}
          className={cn(
            'relative flex items-center justify-center gap-2 rounded-[12px] text-sm font-medium',
            'transition-colors duration-200',
            value === 'context'
              ? 'text-primary'
              : 'text-muted-foreground hover:text-foreground',
            !hasContext && 'opacity-40 cursor-not-allowed hover:text-muted-foreground'
          )}
        >
          {value === 'context' && (
            <motion.div
              layoutId="tab-indicator"
              className="absolute inset-0 bg-card shadow-sm rounded-[12px]"
              transition={{ type: 'spring', stiffness: 400, damping: 30 }}
            />
          )}
          <span className="relative z-10 flex items-center gap-2">
            <Info className="h-4 w-4" />
            Context
          </span>
        </button>
      </div>
    </div>
  );
}
