import { useState } from "react";
import { motion } from "framer-motion";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { Plus, Search, MoreHorizontal, Pencil, Trash2, Loader2, Crown } from "lucide-react";
import { useAdminDuas, useDeleteDua } from "@/hooks/admin";
import { Skeleton } from "@/components/ui/skeleton";
import { DuaFormDialog } from "@/components/admin/DuaFormDialog";
import type { AdminDua } from "@/types/admin";
import { toast } from "sonner";

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

export default function DuasManagerPage() {
  const { data: duas, isLoading } = useAdminDuas();
  const deleteDua = useDeleteDua();

  const [searchQuery, setSearchQuery] = useState("");
  const [duaToEdit, setDuaToEdit] = useState<AdminDua | null>(null);
  const [duaToDelete, setDuaToDelete] = useState<AdminDua | null>(null);
  const [isFormOpen, setIsFormOpen] = useState(false);

  // Filter duas by search query
  const filteredDuas = duas?.filter(dua => {
    const query = searchQuery.toLowerCase();
    return (
      dua.titleEn.toLowerCase().includes(query) ||
      dua.arabicText.includes(searchQuery) ||
      dua.categoryName?.toLowerCase().includes(query) ||
      dua.collectionName?.toLowerCase().includes(query)
    );
  }) || [];

  const handleDelete = async () => {
    if (!duaToDelete) return;

    try {
      await deleteDua.mutateAsync(duaToDelete.id);
      toast.success(`Deleted "${duaToDelete.titleEn}"`);
      setDuaToDelete(null);
    } catch (error) {
      toast.error("Failed to delete dua");
      console.error(error);
    }
  };

  const handleEditClick = (dua: AdminDua) => {
    setDuaToEdit(dua);
    setIsFormOpen(true);
  };

  const handleAddClick = () => {
    setDuaToEdit(null);
    setIsFormOpen(true);
  };

  const handleFormClose = () => {
    setIsFormOpen(false);
    setDuaToEdit(null);
  };

  return (
    <motion.div
      variants={containerVariants}
      initial="hidden"
      animate="visible"
      className="space-y-6"
    >
      <motion.div variants={itemVariants} className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-display font-bold text-foreground">
            Duas Manager
          </h1>
          <p className="text-muted-foreground mt-1">
            Add, edit, and organize duas in the library
          </p>
        </div>
        <Button onClick={handleAddClick}>
          <Plus className="h-4 w-4 mr-2" />
          Add Dua
        </Button>
      </motion.div>

      <motion.div variants={itemVariants}>
        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <div>
                <CardTitle>All Duas</CardTitle>
                <CardDescription>
                  {filteredDuas.length} {filteredDuas.length === 1 ? "dua" : "duas"} in the library
                </CardDescription>
              </div>
              <div className="relative w-64">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                <Input
                  placeholder="Search duas..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="pl-9"
                />
              </div>
            </div>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <div className="space-y-3">
                {[...Array(5)].map((_, i) => (
                  <Skeleton key={i} className="h-16 w-full" />
                ))}
              </div>
            ) : filteredDuas.length === 0 ? (
              <div className="text-center py-8 text-muted-foreground">
                {searchQuery ? "No duas match your search" : "No duas yet. Add your first dua!"}
              </div>
            ) : (
              <div className="rounded-md border">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead className="w-[300px]">Title</TableHead>
                      <TableHead>Category</TableHead>
                      <TableHead>Collection</TableHead>
                      <TableHead className="text-center">Reps</TableHead>
                      <TableHead className="text-center">XP</TableHead>
                      <TableHead className="w-[50px]"></TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {filteredDuas.map((dua) => (
                      <TableRow key={dua.id}>
                        <TableCell>
                          <div className="flex flex-col gap-1">
                            <span className="font-medium">{dua.titleEn}</span>
                            <span className="text-xs text-muted-foreground font-arabic" dir="rtl">
                              {dua.arabicText.slice(0, 50)}...
                            </span>
                          </div>
                        </TableCell>
                        <TableCell>
                          {dua.categoryName && (
                            <Badge variant="outline" className={`badge-${dua.categorySlug}`}>
                              {dua.categoryName}
                            </Badge>
                          )}
                        </TableCell>
                        <TableCell>
                          {dua.collectionName && (
                            <div className="flex items-center gap-1">
                              {dua.isPremium && (
                                <Crown className="h-3 w-3 text-amber-500" />
                              )}
                              <span className="text-sm">{dua.collectionName}</span>
                            </div>
                          )}
                        </TableCell>
                        <TableCell className="text-center font-mono">
                          {dua.repetitions}x
                        </TableCell>
                        <TableCell className="text-center">
                          <Badge variant="secondary">{dua.xpValue} XP</Badge>
                        </TableCell>
                        <TableCell>
                          <DropdownMenu>
                            <DropdownMenuTrigger asChild>
                              <Button variant="ghost" size="icon" className="h-8 w-8">
                                <MoreHorizontal className="h-4 w-4" />
                              </Button>
                            </DropdownMenuTrigger>
                            <DropdownMenuContent align="end">
                              <DropdownMenuItem onClick={() => handleEditClick(dua)}>
                                <Pencil className="h-4 w-4 mr-2" />
                                Edit
                              </DropdownMenuItem>
                              <DropdownMenuItem
                                onClick={() => setDuaToDelete(dua)}
                                className="text-destructive focus:text-destructive"
                              >
                                <Trash2 className="h-4 w-4 mr-2" />
                                Delete
                              </DropdownMenuItem>
                            </DropdownMenuContent>
                          </DropdownMenu>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </div>
            )}
          </CardContent>
        </Card>
      </motion.div>

      {/* Dua Form Dialog */}
      <DuaFormDialog
        open={isFormOpen}
        onOpenChange={handleFormClose}
        dua={duaToEdit}
      />

      {/* Delete Confirmation Dialog */}
      <AlertDialog open={!!duaToDelete} onOpenChange={() => setDuaToDelete(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete Dua</AlertDialogTitle>
            <AlertDialogDescription>
              Are you sure you want to delete "{duaToDelete?.titleEn}"? This action cannot be undone
              and will remove this dua from all journeys.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction
              onClick={handleDelete}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
              disabled={deleteDua.isPending}
            >
              {deleteDua.isPending ? (
                <Loader2 className="h-4 w-4 animate-spin mr-2" />
              ) : (
                <Trash2 className="h-4 w-4 mr-2" />
              )}
              Delete
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </motion.div>
  );
}
