import { useState } from "react";
import { motion } from "framer-motion";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Switch } from "@/components/ui/switch";
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
import {
  Plus,
  Search,
  MoreHorizontal,
  Pencil,
  Trash2,
  Loader2,
  Star,
  Crown,
  BookOpen,
} from "lucide-react";
import {
  useAdminJourneys,
  useDeleteJourney,
  useToggleJourneyFeatured,
  useToggleJourneyPremium,
} from "@/hooks/admin";
import { Skeleton } from "@/components/ui/skeleton";
import { JourneyFormDialog } from "@/components/admin/JourneyFormDialog";
import type { AdminJourney } from "@/types/admin";
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

export default function JourneysManagerPage() {
  const { data: journeys, isLoading } = useAdminJourneys();
  const deleteJourney = useDeleteJourney();
  const toggleFeatured = useToggleJourneyFeatured();
  const togglePremium = useToggleJourneyPremium();

  const [searchQuery, setSearchQuery] = useState("");
  const [journeyToEdit, setJourneyToEdit] = useState<AdminJourney | null>(null);
  const [journeyToDelete, setJourneyToDelete] = useState<AdminJourney | null>(null);
  const [isFormOpen, setIsFormOpen] = useState(false);

  // Filter journeys by search query
  const filteredJourneys = journeys?.filter(journey => {
    const query = searchQuery.toLowerCase();
    return (
      journey.name.toLowerCase().includes(query) ||
      journey.description?.toLowerCase().includes(query) ||
      journey.slug.toLowerCase().includes(query)
    );
  }) || [];

  const handleDelete = async () => {
    if (!journeyToDelete) return;

    try {
      await deleteJourney.mutateAsync(journeyToDelete.id);
      toast.success(`Deleted "${journeyToDelete.name}"`);
      setJourneyToDelete(null);
    } catch (error) {
      toast.error("Failed to delete journey");
      console.error(error);
    }
  };

  const handleToggleFeatured = async (journey: AdminJourney) => {
    try {
      await toggleFeatured.mutateAsync({ id: journey.id, isFeatured: !journey.isFeatured });
      toast.success(journey.isFeatured ? "Removed from featured" : "Added to featured");
    } catch (error) {
      toast.error("Failed to update featured status");
    }
  };

  const handleTogglePremium = async (journey: AdminJourney) => {
    try {
      await togglePremium.mutateAsync({ id: journey.id, isPremium: !journey.isPremium });
      toast.success(journey.isPremium ? "Removed premium status" : "Marked as premium");
    } catch (error) {
      toast.error("Failed to update premium status");
    }
  };

  const handleEditClick = (journey: AdminJourney) => {
    setJourneyToEdit(journey);
    setIsFormOpen(true);
  };

  const handleAddClick = () => {
    setJourneyToEdit(null);
    setIsFormOpen(true);
  };

  const handleFormClose = () => {
    setIsFormOpen(false);
    setJourneyToEdit(null);
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
            Journeys Manager
          </h1>
          <p className="text-muted-foreground mt-1">
            Create and manage themed dua collections
          </p>
        </div>
        <Button onClick={handleAddClick}>
          <Plus className="h-4 w-4 mr-2" />
          Add Journey
        </Button>
      </motion.div>

      <motion.div variants={itemVariants}>
        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <div>
                <CardTitle>All Journeys</CardTitle>
                <CardDescription>
                  {filteredJourneys.length} {filteredJourneys.length === 1 ? "journey" : "journeys"}
                </CardDescription>
              </div>
              <div className="relative w-64">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                <Input
                  placeholder="Search journeys..."
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
                {[...Array(4)].map((_, i) => (
                  <Skeleton key={i} className="h-16 w-full" />
                ))}
              </div>
            ) : filteredJourneys.length === 0 ? (
              <div className="text-center py-8 text-muted-foreground">
                {searchQuery ? "No journeys match your search" : "No journeys yet. Create your first journey!"}
              </div>
            ) : (
              <div className="rounded-md border">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead className="w-[250px]">Journey</TableHead>
                      <TableHead className="text-center">Duas</TableHead>
                      <TableHead className="text-center">Duration</TableHead>
                      <TableHead className="text-center">Daily XP</TableHead>
                      <TableHead className="text-center">Featured</TableHead>
                      <TableHead className="text-center">Premium</TableHead>
                      <TableHead className="w-[50px]"></TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {filteredJourneys.map((journey) => (
                      <TableRow key={journey.id}>
                        <TableCell>
                          <div className="flex items-center gap-3">
                            <span className="text-2xl">{journey.emoji}</span>
                            <div className="flex flex-col">
                              <span className="font-medium">{journey.name}</span>
                              <span className="text-xs text-muted-foreground">
                                /{journey.slug}
                              </span>
                            </div>
                          </div>
                        </TableCell>
                        <TableCell className="text-center">
                          <div className="flex items-center justify-center gap-1">
                            <BookOpen className="h-4 w-4 text-muted-foreground" />
                            <span>{journey.duaCount || 0}</span>
                          </div>
                        </TableCell>
                        <TableCell className="text-center">
                          {journey.estimatedMinutes} min
                        </TableCell>
                        <TableCell className="text-center">
                          <Badge variant="secondary">{journey.dailyXp} XP</Badge>
                        </TableCell>
                        <TableCell className="text-center">
                          <Switch
                            checked={journey.isFeatured}
                            onCheckedChange={() => handleToggleFeatured(journey)}
                            disabled={toggleFeatured.isPending}
                          />
                        </TableCell>
                        <TableCell className="text-center">
                          <Switch
                            checked={journey.isPremium}
                            onCheckedChange={() => handleTogglePremium(journey)}
                            disabled={togglePremium.isPending}
                          />
                        </TableCell>
                        <TableCell>
                          <DropdownMenu>
                            <DropdownMenuTrigger asChild>
                              <Button variant="ghost" size="icon" className="h-8 w-8">
                                <MoreHorizontal className="h-4 w-4" />
                              </Button>
                            </DropdownMenuTrigger>
                            <DropdownMenuContent align="end">
                              <DropdownMenuItem onClick={() => handleEditClick(journey)}>
                                <Pencil className="h-4 w-4 mr-2" />
                                Edit
                              </DropdownMenuItem>
                              <DropdownMenuItem
                                onClick={() => setJourneyToDelete(journey)}
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

      {/* Journey Form Dialog */}
      <JourneyFormDialog
        open={isFormOpen}
        onOpenChange={handleFormClose}
        journey={journeyToEdit}
      />

      {/* Delete Confirmation Dialog */}
      <AlertDialog open={!!journeyToDelete} onOpenChange={() => setJourneyToDelete(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete Journey</AlertDialogTitle>
            <AlertDialogDescription>
              Are you sure you want to delete "{journeyToDelete?.name}"? This will remove the journey
              and all its dua assignments (the duas themselves will not be deleted).
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction
              onClick={handleDelete}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
              disabled={deleteJourney.isPending}
            >
              {deleteJourney.isPending ? (
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
