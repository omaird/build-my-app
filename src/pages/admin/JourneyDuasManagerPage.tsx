import { useState } from "react";
import { useParams, useNavigate, Link } from "react-router-dom";
import { motion } from "framer-motion";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
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
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
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
  ArrowLeft,
  Plus,
  Trash2,
  Loader2,
  Sun,
  Clock,
  Moon,
  BookOpen,
} from "lucide-react";
import {
  useAdminJourney,
  useAdminJourneyDuas,
  useAssignDuaToJourney,
  useRemoveDuaFromJourney,
  type AdminJourneyDua,
} from "@/hooks/admin/useAdminJourneys";
import { useAdminDuas } from "@/hooks/admin/useAdminDuas";
import { Skeleton } from "@/components/ui/skeleton";
import type { TimeSlot } from "@/types/habit";
import { toast } from "sonner";

const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: { staggerChildren: 0.08 },
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

const timeSlotConfig: Record<TimeSlot, { icon: typeof Sun; label: string; badgeClass: string }> = {
  morning: { icon: Sun, label: "Morning", badgeClass: "bg-amber-100 text-amber-800" },
  anytime: { icon: Clock, label: "Anytime", badgeClass: "bg-blue-100 text-blue-800" },
  evening: { icon: Moon, label: "Evening", badgeClass: "bg-indigo-100 text-indigo-800" },
};

export default function JourneyDuasManagerPage() {
  const { journeyId } = useParams<{ journeyId: string }>();
  const navigate = useNavigate();
  const parsedJourneyId = journeyId ? parseInt(journeyId, 10) : null;

  const { data: journey, isLoading: isLoadingJourney } = useAdminJourney(parsedJourneyId);
  const { data: journeyDuas, isLoading: isLoadingDuas } = useAdminJourneyDuas(parsedJourneyId);
  const { data: allDuas, isLoading: isLoadingAllDuas } = useAdminDuas();
  const assignDua = useAssignDuaToJourney();
  const removeDua = useRemoveDuaFromJourney();

  const [isAddDialogOpen, setIsAddDialogOpen] = useState(false);
  const [selectedDuaId, setSelectedDuaId] = useState<string>("");
  const [selectedTimeSlot, setSelectedTimeSlot] = useState<TimeSlot>("anytime");
  const [duaToRemove, setDuaToRemove] = useState<AdminJourneyDua | null>(null);

  // Get duas not already in this journey
  const availableDuas = allDuas?.filter(
    dua => !journeyDuas?.some(jd => jd.duaId === dua.id)
  ) || [];

  const handleAddDua = async () => {
    if (!selectedDuaId || !parsedJourneyId) return;

    try {
      const maxSortOrder = journeyDuas?.reduce((max, jd) => Math.max(max, jd.sortOrder), 0) || 0;
      await assignDua.mutateAsync({
        id: 0, // Not used for insert
        journeyId: parsedJourneyId,
        duaId: parseInt(selectedDuaId, 10),
        timeSlot: selectedTimeSlot,
        sortOrder: maxSortOrder + 1,
      });
      toast.success("Dua added to journey");
      setIsAddDialogOpen(false);
      setSelectedDuaId("");
      setSelectedTimeSlot("anytime");
    } catch (error) {
      toast.error("Failed to add dua to journey");
    }
  };

  const handleRemoveDua = async () => {
    if (!duaToRemove || !parsedJourneyId) return;

    try {
      await removeDua.mutateAsync({
        journeyId: parsedJourneyId,
        duaId: duaToRemove.duaId,
      });
      toast.success("Dua removed from journey");
      setDuaToRemove(null);
    } catch (error) {
      toast.error("Failed to remove dua");
    }
  };

  const handleTimeSlotChange = async (dua: AdminJourneyDua, newTimeSlot: TimeSlot) => {
    if (!parsedJourneyId) return;

    try {
      await assignDua.mutateAsync({
        id: 0,
        journeyId: parsedJourneyId,
        duaId: dua.duaId,
        timeSlot: newTimeSlot,
        sortOrder: dua.sortOrder,
      });
      toast.success("Time slot updated");
    } catch (error) {
      toast.error("Failed to update time slot");
    }
  };

  const isLoading = isLoadingJourney || isLoadingDuas;

  if (!parsedJourneyId) {
    return (
      <div className="p-6 text-center">
        <p className="text-muted-foreground">Invalid journey ID</p>
        <Button variant="ghost" onClick={() => navigate("/admin/journeys")} className="mt-4">
          <ArrowLeft className="h-4 w-4 mr-2" />
          Back to Journeys
        </Button>
      </div>
    );
  }

  return (
    <motion.div
      className="space-y-6"
      variants={containerVariants}
      initial="hidden"
      animate="visible"
    >
      {/* Header */}
      <motion.div variants={itemVariants} className="flex items-center gap-4">
        <Button variant="ghost" size="icon" asChild>
          <Link to="/admin/journeys">
            <ArrowLeft className="h-4 w-4" />
          </Link>
        </Button>
        <div className="flex-1">
          {isLoadingJourney ? (
            <Skeleton className="h-8 w-64" />
          ) : (
            <div className="flex items-center gap-3">
              <span className="text-3xl">{journey?.emoji || "📿"}</span>
              <div>
                <h1 className="text-2xl font-display font-semibold">{journey?.name}</h1>
                <p className="text-sm text-muted-foreground">
                  Manage duas in this journey
                </p>
              </div>
            </div>
          )}
        </div>
        <Button onClick={() => setIsAddDialogOpen(true)} disabled={isLoadingAllDuas}>
          <Plus className="h-4 w-4 mr-2" />
          Add Dua
        </Button>
      </motion.div>

      {/* Journey Stats */}
      {journey && (
        <motion.div variants={itemVariants}>
          <Card>
            <CardHeader className="py-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-6 text-sm text-muted-foreground">
                  <span>{journeyDuas?.length || 0} duas</span>
                  <span>{journey.estimatedMinutes} min</span>
                  <span>{journey.dailyXp} XP/day</span>
                </div>
                <div className="flex gap-2">
                  {journey.isPremium && (
                    <Badge variant="secondary">Premium</Badge>
                  )}
                  {journey.isFeatured && (
                    <Badge variant="default">Featured</Badge>
                  )}
                </div>
              </div>
            </CardHeader>
          </Card>
        </motion.div>
      )}

      {/* Duas Table */}
      <motion.div variants={itemVariants}>
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <BookOpen className="h-5 w-5" />
              Assigned Duas
            </CardTitle>
            <CardDescription>
              Duas included in this journey, grouped by time slot
            </CardDescription>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <div className="space-y-3">
                {[...Array(5)].map((_, i) => (
                  <Skeleton key={i} className="h-16 w-full" />
                ))}
              </div>
            ) : !journeyDuas?.length ? (
              <div className="text-center py-12">
                <BookOpen className="h-12 w-12 mx-auto text-muted-foreground/50 mb-4" />
                <p className="text-muted-foreground mb-4">
                  No duas assigned to this journey yet
                </p>
                <Button onClick={() => setIsAddDialogOpen(true)}>
                  <Plus className="h-4 w-4 mr-2" />
                  Add First Dua
                </Button>
              </div>
            ) : (
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="w-12">#</TableHead>
                    <TableHead>Dua</TableHead>
                    <TableHead>Category</TableHead>
                    <TableHead>Time Slot</TableHead>
                    <TableHead className="text-right">XP</TableHead>
                    <TableHead className="w-12"></TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {journeyDuas.map((dua, index) => {
                    const config = timeSlotConfig[dua.timeSlot];
                    const TimeIcon = config.icon;
                    return (
                      <TableRow key={dua.duaId}>
                        <TableCell className="text-muted-foreground">
                          {index + 1}
                        </TableCell>
                        <TableCell>
                          <div>
                            <p className="font-medium">{dua.titleEn}</p>
                            <p className="text-sm text-muted-foreground font-arabic" dir="rtl">
                              {dua.arabicText.slice(0, 50)}...
                            </p>
                          </div>
                        </TableCell>
                        <TableCell>
                          {dua.categoryName && (
                            <Badge variant="outline">{dua.categoryName}</Badge>
                          )}
                        </TableCell>
                        <TableCell>
                          <Select
                            value={dua.timeSlot}
                            onValueChange={(value) => handleTimeSlotChange(dua, value as TimeSlot)}
                          >
                            <SelectTrigger className="w-32">
                              <SelectValue />
                            </SelectTrigger>
                            <SelectContent>
                              {(Object.keys(timeSlotConfig) as TimeSlot[]).map((slot) => {
                                const slotConfig = timeSlotConfig[slot];
                                const SlotIcon = slotConfig.icon;
                                return (
                                  <SelectItem key={slot} value={slot}>
                                    <div className="flex items-center gap-2">
                                      <SlotIcon className="h-4 w-4" />
                                      {slotConfig.label}
                                    </div>
                                  </SelectItem>
                                );
                              })}
                            </SelectContent>
                          </Select>
                        </TableCell>
                        <TableCell className="text-right font-mono">
                          {dua.xpValue}
                        </TableCell>
                        <TableCell>
                          <Button
                            variant="ghost"
                            size="icon"
                            className="text-destructive hover:text-destructive"
                            onClick={() => setDuaToRemove(dua)}
                          >
                            <Trash2 className="h-4 w-4" />
                          </Button>
                        </TableCell>
                      </TableRow>
                    );
                  })}
                </TableBody>
              </Table>
            )}
          </CardContent>
        </Card>
      </motion.div>

      {/* Add Dua Dialog */}
      <Dialog open={isAddDialogOpen} onOpenChange={setIsAddDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Add Dua to Journey</DialogTitle>
            <DialogDescription>
              Select a dua and time slot to add to this journey
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <label className="text-sm font-medium">Dua</label>
              <Select value={selectedDuaId} onValueChange={setSelectedDuaId}>
                <SelectTrigger>
                  <SelectValue placeholder="Select a dua..." />
                </SelectTrigger>
                <SelectContent className="max-h-64">
                  {availableDuas.map((dua) => (
                    <SelectItem key={dua.id} value={dua.id.toString()}>
                      <div className="flex flex-col">
                        <span>{dua.titleEn}</span>
                        <span className="text-xs text-muted-foreground">
                          {dua.categoryName || "Uncategorized"}
                        </span>
                      </div>
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              {availableDuas.length === 0 && (
                <p className="text-sm text-muted-foreground">
                  All duas have already been added to this journey
                </p>
              )}
            </div>
            <div className="space-y-2">
              <label className="text-sm font-medium">Time Slot</label>
              <Select value={selectedTimeSlot} onValueChange={(v) => setSelectedTimeSlot(v as TimeSlot)}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {(Object.keys(timeSlotConfig) as TimeSlot[]).map((slot) => {
                    const config = timeSlotConfig[slot];
                    const SlotIcon = config.icon;
                    return (
                      <SelectItem key={slot} value={slot}>
                        <div className="flex items-center gap-2">
                          <SlotIcon className="h-4 w-4" />
                          {config.label}
                        </div>
                      </SelectItem>
                    );
                  })}
                </SelectContent>
              </Select>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setIsAddDialogOpen(false)}>
              Cancel
            </Button>
            <Button
              onClick={handleAddDua}
              disabled={!selectedDuaId || assignDua.isPending}
            >
              {assignDua.isPending && <Loader2 className="h-4 w-4 mr-2 animate-spin" />}
              Add Dua
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Remove Confirmation Dialog */}
      <AlertDialog open={!!duaToRemove} onOpenChange={(open) => !open && setDuaToRemove(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Remove Dua from Journey?</AlertDialogTitle>
            <AlertDialogDescription>
              This will remove "{duaToRemove?.titleEn}" from this journey.
              The dua itself will not be deleted.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction
              onClick={handleRemoveDua}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
            >
              {removeDua.isPending && <Loader2 className="h-4 w-4 mr-2 animate-spin" />}
              Remove
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </motion.div>
  );
}
