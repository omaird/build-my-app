import { SidebarTrigger } from "@/components/ui/sidebar";
import { Separator } from "@/components/ui/separator";
import {
  Breadcrumb,
  BreadcrumbItem,
  BreadcrumbLink,
  BreadcrumbList,
  BreadcrumbPage,
  BreadcrumbSeparator,
} from "@/components/ui/breadcrumb";
import { useLocation, Link } from "react-router-dom";

// Map routes to readable titles
const routeTitles: Record<string, string> = {
  "/admin": "Dashboard",
  "/admin/duas": "Duas",
  "/admin/journeys": "Journeys",
  "/admin/categories": "Categories",
  "/admin/collections": "Collections",
  "/admin/users": "Users",
};

export function AdminHeader() {
  const location = useLocation();
  const currentTitle = routeTitles[location.pathname] || "Admin";
  const isNested = location.pathname !== "/admin";

  return (
    <header className="flex h-14 shrink-0 items-center gap-2 border-b border-border/50 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60 px-4">
      <SidebarTrigger className="-ml-1" />
      <Separator orientation="vertical" className="mr-2 h-4" />

      <Breadcrumb>
        <BreadcrumbList>
          <BreadcrumbItem>
            {isNested ? (
              <BreadcrumbLink asChild>
                <Link to="/admin">Admin</Link>
              </BreadcrumbLink>
            ) : (
              <BreadcrumbPage>Admin</BreadcrumbPage>
            )}
          </BreadcrumbItem>

          {isNested && (
            <>
              <BreadcrumbSeparator />
              <BreadcrumbItem>
                <BreadcrumbPage>{currentTitle}</BreadcrumbPage>
              </BreadcrumbItem>
            </>
          )}
        </BreadcrumbList>
      </Breadcrumb>
    </header>
  );
}
