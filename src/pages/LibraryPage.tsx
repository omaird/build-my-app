import { useState, useMemo } from "react";
import { Search } from "lucide-react";
import { BottomNav } from "@/components/BottomNav";
import { DuaCard } from "@/components/DuaCard";
import { duaLibrary } from "@/data/duaLibrary";
import { useUserProgress } from "@/hooks/useUserData";
import { DuaCategory } from "@/types/dua";
import { Input } from "@/components/ui/input";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";

const categories: { value: DuaCategory | "all"; label: string }[] = [
  { value: "all", label: "All" },
  { value: "morning", label: "Morning" },
  { value: "evening", label: "Evening" },
  { value: "rizq", label: "Rizq" },
  { value: "gratitude", label: "Gratitude" },
];

export default function LibraryPage() {
  const [search, setSearch] = useState("");
  const [activeCategory, setActiveCategory] = useState<DuaCategory | "all">("all");
  const { hasCompletedToday } = useUserProgress();

  const filteredDuas = useMemo(() => {
    return duaLibrary.filter((dua) => {
      const matchesCategory = activeCategory === "all" || dua.category === activeCategory;
      const matchesSearch = 
        search === "" ||
        dua.title.toLowerCase().includes(search.toLowerCase()) ||
        dua.translation.toLowerCase().includes(search.toLowerCase());
      return matchesCategory && matchesSearch;
    });
  }, [search, activeCategory]);

  return (
    <div className="min-h-screen bg-background pb-20">
      <div className="mx-auto max-w-md px-4 pt-8">
        {/* Header */}
        <header className="mb-6">
          <h1 className="text-2xl font-bold text-foreground">Dua Library</h1>
          <p className="text-sm text-muted-foreground">
            {duaLibrary.length} duas to practice
          </p>
        </header>

        {/* Search */}
        <div className="relative mb-4">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            placeholder="Search duas..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="pl-9"
          />
        </div>

        {/* Category Tabs */}
        <Tabs
          value={activeCategory}
          onValueChange={(v) => setActiveCategory(v as DuaCategory | "all")}
          className="mb-6"
        >
          <TabsList className="w-full justify-start overflow-x-auto">
            {categories.map((cat) => (
              <TabsTrigger key={cat.value} value={cat.value} className="flex-shrink-0">
                {cat.label}
              </TabsTrigger>
            ))}
          </TabsList>
        </Tabs>

        {/* Dua List */}
        <div className="space-y-3">
          {filteredDuas.map((dua) => (
            <DuaCard
              key={dua.id}
              dua={dua}
              isCompleted={hasCompletedToday(dua.id)}
            />
          ))}
        </div>

        {filteredDuas.length === 0 && (
          <div className="py-12 text-center">
            <p className="text-muted-foreground">No duas found</p>
          </div>
        )}
      </div>

      <BottomNav />
    </div>
  );
}