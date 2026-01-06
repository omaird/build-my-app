import { motion } from "framer-motion";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { BookOpen, Route, Users, Folder } from "lucide-react";
import { useQuery } from "@tanstack/react-query";
import { getSql } from "@/lib/db";
import { Skeleton } from "@/components/ui/skeleton";

const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: { staggerChildren: 0.1 },
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

interface DashboardStats {
  totalDuas: number;
  totalJourneys: number;
  totalCategories: number;
  totalUsers: number;
  featuredJourneys: number;
}

function useAdminDashboardStats() {
  return useQuery({
    queryKey: ["admin-dashboard-stats"],
    queryFn: async (): Promise<DashboardStats> => {
      const sql = getSql();

      // Run all count queries in parallel
      const [duasResult, journeysResult, categoriesResult, usersResult, featuredResult] = await Promise.all([
        sql`SELECT COUNT(*) as count FROM duas`,
        sql`SELECT COUNT(*) as count FROM journeys`,
        sql`SELECT COUNT(*) as count FROM categories`,
        sql`SELECT COUNT(*) as count FROM user_profiles`,
        sql`SELECT COUNT(*) as count FROM journeys WHERE is_featured = TRUE`,
      ]);

      return {
        totalDuas: Number(duasResult[0]?.count || 0),
        totalJourneys: Number(journeysResult[0]?.count || 0),
        totalCategories: Number(categoriesResult[0]?.count || 0),
        totalUsers: Number(usersResult[0]?.count || 0),
        featuredJourneys: Number(featuredResult[0]?.count || 0),
      };
    },
  });
}

function StatCard({
  title,
  value,
  description,
  icon: Icon,
  isLoading,
}: {
  title: string;
  value: number;
  description: string;
  icon: React.ElementType;
  isLoading: boolean;
}) {
  return (
    <motion.div variants={itemVariants}>
      <Card>
        <CardHeader className="flex flex-row items-center justify-between pb-2">
          <CardTitle className="text-sm font-medium text-muted-foreground">
            {title}
          </CardTitle>
          <Icon className="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <Skeleton className="h-8 w-16" />
          ) : (
            <div className="text-2xl font-bold font-display">{value}</div>
          )}
          <p className="text-xs text-muted-foreground mt-1">{description}</p>
        </CardContent>
      </Card>
    </motion.div>
  );
}

export default function AdminDashboardPage() {
  const { data: stats, isLoading } = useAdminDashboardStats();

  return (
    <motion.div
      variants={containerVariants}
      initial="hidden"
      animate="visible"
      className="space-y-6"
    >
      <motion.div variants={itemVariants}>
        <h1 className="text-3xl font-display font-bold text-foreground">
          Dashboard
        </h1>
        <p className="text-muted-foreground mt-1">
          Overview of your RIZQ content and users
        </p>
      </motion.div>

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <StatCard
          title="Total Duas"
          value={stats?.totalDuas || 0}
          description="Duas in the library"
          icon={BookOpen}
          isLoading={isLoading}
        />
        <StatCard
          title="Journeys"
          value={stats?.totalJourneys || 0}
          description={`${stats?.featuredJourneys || 0} featured`}
          icon={Route}
          isLoading={isLoading}
        />
        <StatCard
          title="Categories"
          value={stats?.totalCategories || 0}
          description="Dua categories"
          icon={Folder}
          isLoading={isLoading}
        />
        <StatCard
          title="Users"
          value={stats?.totalUsers || 0}
          description="Registered users"
          icon={Users}
          isLoading={isLoading}
        />
      </div>

      <motion.div variants={itemVariants}>
        <Card>
          <CardHeader>
            <CardTitle>Quick Actions</CardTitle>
            <CardDescription>
              Common tasks for managing your RIZQ content
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
              <QuickActionCard
                title="Add New Dua"
                description="Create a new dua with Arabic text, translation, and context"
                href="/admin/duas"
              />
              <QuickActionCard
                title="Create Journey"
                description="Build a new themed collection of duas"
                href="/admin/journeys"
              />
              <QuickActionCard
                title="Manage Users"
                description="View user stats and manage admin access"
                href="/admin/users"
              />
            </div>
          </CardContent>
        </Card>
      </motion.div>
    </motion.div>
  );
}

function QuickActionCard({
  title,
  description,
  href,
}: {
  title: string;
  description: string;
  href: string;
}) {
  return (
    <a
      href={href}
      className="block p-4 rounded-lg border border-border hover:border-primary/50 hover:bg-muted/50 transition-colors"
    >
      <h3 className="font-medium text-foreground">{title}</h3>
      <p className="text-sm text-muted-foreground mt-1">{description}</p>
    </a>
  );
}
