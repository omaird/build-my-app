import { motion } from 'framer-motion';
import { Book, Clock, Sparkles, ScrollText, GraduationCap, Quote } from 'lucide-react';
import { cn } from '@/lib/utils';
import type { DuaContext } from '@/types/dua';

interface DuaContextViewProps {
  context: DuaContext;
  className?: string;
}

interface ContextItemProps {
  icon: React.ReactNode;
  label: string;
  value: string;
  colorClass: string;
  index: number;
}

const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: { staggerChildren: 0.08, delayChildren: 0.1 },
  },
};

const itemVariants = {
  hidden: { opacity: 0, y: 15 },
  visible: {
    opacity: 1,
    y: 0,
    transition: { duration: 0.4, ease: [0.25, 0.46, 0.45, 0.94] },
  },
};

function ContextItem({ icon, label, value, colorClass, index }: ContextItemProps) {
  return (
    <motion.div
      className={cn(
        'p-4 rounded-islamic bg-card/50 border border-primary/10',
        'hover:border-primary/20 transition-colors'
      )}
      variants={itemVariants}
    >
      <div className="flex items-start gap-3">
        <div
          className={cn(
            'flex h-10 w-10 shrink-0 items-center justify-center rounded-lg',
            colorClass
          )}
        >
          {icon}
        </div>
        <div className="flex-1 min-w-0">
          <p className="text-xs font-medium text-muted-foreground uppercase tracking-wide mb-1">
            {label}
          </p>
          <p className="text-lg text-foreground leading-relaxed">{value}</p>
        </div>
      </div>
    </motion.div>
  );
}

export function DuaContextView({ context, className }: DuaContextViewProps) {
  const items: Array<{
    icon: React.ReactNode;
    label: string;
    value: string | null;
    colorClass: string;
  }> = [
    {
      icon: <Book className="h-5 w-5 text-amber-700" />,
      label: 'Source',
      value: context.source,
      colorClass: 'bg-amber-100/70',
    },
    {
      icon: <Sparkles className="h-5 w-5 text-emerald-700" />,
      label: 'Benefits & Virtues',
      value: context.benefits,
      colorClass: 'bg-emerald-100/70',
    },
    {
      icon: <Clock className="h-5 w-5 text-blue-700" />,
      label: 'Best Time to Recite',
      value: context.bestTime,
      colorClass: 'bg-blue-100/70',
    },
    {
      icon: <ScrollText className="h-5 w-5 text-purple-700" />,
      label: 'Story & Background',
      value: context.story,
      colorClass: 'bg-purple-100/70',
    },
    {
      icon: <Quote className="h-5 w-5 text-rose-700" />,
      label: 'Prophetic Guidance',
      value: context.propheticContext,
      colorClass: 'bg-rose-100/70',
    },
  ];

  // Filter to only items with values
  const visibleItems = items.filter((item) => item.value);

  if (visibleItems.length === 0) {
    return (
      <motion.div
        className={cn('text-center py-12 px-4', className)}
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
      >
        <ScrollText className="h-12 w-12 text-muted-foreground/40 mx-auto mb-4" />
        <p className="text-muted-foreground">
          No additional context available for this dua.
        </p>
      </motion.div>
    );
  }

  return (
    <motion.div
      className={cn('space-y-3', className)}
      variants={containerVariants}
      initial="hidden"
      animate="visible"
    >
      {/* Difficulty and duration badge */}
      {(context.difficulty || context.estimatedDuration) && (
        <motion.div
          className="flex items-center justify-center gap-3 mb-4 py-2"
          variants={itemVariants}
        >
          {context.difficulty && (
            <div className="flex items-center gap-1.5 text-muted-foreground">
              <GraduationCap className="h-4 w-4" />
              <span className="text-xs font-medium">{context.difficulty}</span>
            </div>
          )}
          {context.difficulty && context.estimatedDuration && (
            <span className="text-muted-foreground/40">|</span>
          )}
          {context.estimatedDuration && (
            <div className="flex items-center gap-1.5 text-muted-foreground">
              <Clock className="h-4 w-4" />
              <span className="text-xs font-medium">
                ~{Math.ceil(context.estimatedDuration / 60)} min
              </span>
            </div>
          )}
        </motion.div>
      )}

      {/* Context items */}
      {visibleItems.map((item, index) => (
        <ContextItem
          key={item.label}
          icon={item.icon}
          label={item.label}
          value={item.value!}
          colorClass={item.colorClass}
          index={index}
        />
      ))}
    </motion.div>
  );
}
