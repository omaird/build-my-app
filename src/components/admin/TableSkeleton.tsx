import { Skeleton } from "@/components/ui/skeleton";

interface TableSkeletonProps {
  rows?: number;
  rowHeight?: string;
}

/**
 * Loading skeleton for table content.
 * Provides consistent loading UX across admin manager pages.
 */
export function TableSkeleton({ rows = 5, rowHeight = "h-14" }: TableSkeletonProps) {
  return (
    <div className="space-y-3">
      {[...Array(rows)].map((_, i) => (
        <Skeleton key={i} className={`${rowHeight} w-full`} />
      ))}
    </div>
  );
}

/**
 * Empty state for tables with no data.
 */
interface EmptyTableStateProps {
  message?: string;
  searchQuery?: string;
  entityName?: string;
}

export function EmptyTableState({
  message,
  searchQuery,
  entityName = "items",
}: EmptyTableStateProps) {
  const defaultMessage = searchQuery
    ? `No ${entityName} match your search`
    : `No ${entityName} yet.`;

  return (
    <div className="text-center py-8 text-muted-foreground">
      {message || defaultMessage}
    </div>
  );
}
