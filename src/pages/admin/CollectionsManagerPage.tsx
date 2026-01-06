import { useState, useEffect } from "react";
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
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  Form,
  FormControl,
  FormDescription,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";
import { Textarea } from "@/components/ui/textarea";
import { Plus, Search, MoreHorizontal, Pencil, Trash2, Loader2, BookOpen, Crown } from "lucide-react";
import {
  useAdminCollections,
  useCreateCollection,
  useUpdateCollection,
  useDeleteCollection,
  useToggleCollectionPremium,
} from "@/hooks/admin";
import { Skeleton } from "@/components/ui/skeleton";
import type { AdminCollection, CollectionFormInput } from "@/types/admin";
import { toast } from "sonner";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";

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

// Form validation schema
const collectionFormSchema = z.object({
  name: z.string().min(2, "Name must be at least 2 characters"),
  slug: z.string()
    .min(2, "Slug must be at least 2 characters")
    .regex(/^[a-z0-9-]+$/, "Slug must be lowercase with hyphens only"),
  description: z.string().optional(),
  isPremium: z.boolean().default(false),
});

type FormValues = z.infer<typeof collectionFormSchema>;

export default function CollectionsManagerPage() {
  const { data: collections, isLoading } = useAdminCollections();
  const createCollection = useCreateCollection();
  const updateCollection = useUpdateCollection();
  const deleteCollection = useDeleteCollection();
  const togglePremium = useToggleCollectionPremium();

  const [searchQuery, setSearchQuery] = useState("");
  const [collectionToEdit, setCollectionToEdit] = useState<AdminCollection | null>(null);
  const [collectionToDelete, setCollectionToDelete] = useState<AdminCollection | null>(null);
  const [isFormOpen, setIsFormOpen] = useState(false);

  const form = useForm<FormValues>({
    resolver: zodResolver(collectionFormSchema),
    defaultValues: { name: "", slug: "", description: "", isPremium: false },
  });

  useEffect(() => {
    if (collectionToEdit) {
      form.reset({
        name: collectionToEdit.name,
        slug: collectionToEdit.slug,
        description: collectionToEdit.description || "",
        isPremium: collectionToEdit.isPremium,
      });
    } else {
      form.reset({ name: "", slug: "", description: "", isPremium: false });
    }
  }, [collectionToEdit, form]);

  const filteredCollections = collections?.filter(col => {
    const query = searchQuery.toLowerCase();
    return col.name.toLowerCase().includes(query) || col.slug.toLowerCase().includes(query);
  }) || [];

  const handleDelete = async () => {
    if (!collectionToDelete) return;
    try {
      await deleteCollection.mutateAsync(collectionToDelete.id);
      toast.success(`Deleted "${collectionToDelete.name}"`);
      setCollectionToDelete(null);
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : "Failed to delete collection";
      toast.error(message);
    }
  };

  const handleTogglePremium = async (col: AdminCollection) => {
    try {
      await togglePremium.mutateAsync({ id: col.id, isPremium: !col.isPremium });
      toast.success(col.isPremium ? "Removed premium status" : "Marked as premium");
    } catch (error) {
      toast.error("Failed to update premium status");
    }
  };

  const handleNameChange = (name: string) => {
    if (!collectionToEdit) {
      const slug = name.toLowerCase().replace(/[^a-z0-9\s-]/g, "").replace(/\s+/g, "-");
      form.setValue("slug", slug);
    }
  };

  const onSubmit = async (values: FormValues) => {
    try {
      const input: CollectionFormInput = {
        name: values.name,
        slug: values.slug,
        description: values.description,
        isPremium: values.isPremium,
      };

      if (collectionToEdit) {
        await updateCollection.mutateAsync({ id: collectionToEdit.id, ...input });
        toast.success("Collection updated successfully");
      } else {
        await createCollection.mutateAsync(input);
        toast.success("Collection created successfully");
      }
      setIsFormOpen(false);
      setCollectionToEdit(null);
    } catch (error) {
      toast.error(collectionToEdit ? "Failed to update collection" : "Failed to create collection");
    }
  };

  const handleEditClick = (col: AdminCollection) => {
    setCollectionToEdit(col);
    setIsFormOpen(true);
  };

  const handleAddClick = () => {
    setCollectionToEdit(null);
    setIsFormOpen(true);
  };

  const isPending = createCollection.isPending || updateCollection.isPending;

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
            Collections Manager
          </h1>
          <p className="text-muted-foreground mt-1">
            Manage content tiers (free vs premium)
          </p>
        </div>
        <Button onClick={handleAddClick}>
          <Plus className="h-4 w-4 mr-2" />
          Add Collection
        </Button>
      </motion.div>

      <motion.div variants={itemVariants}>
        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <div>
                <CardTitle>All Collections</CardTitle>
                <CardDescription>
                  {filteredCollections.length} {filteredCollections.length === 1 ? "collection" : "collections"}
                </CardDescription>
              </div>
              <div className="relative w-64">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                <Input
                  placeholder="Search collections..."
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
                {[...Array(3)].map((_, i) => (
                  <Skeleton key={i} className="h-14 w-full" />
                ))}
              </div>
            ) : filteredCollections.length === 0 ? (
              <div className="text-center py-8 text-muted-foreground">
                {searchQuery ? "No collections match your search" : "No collections yet."}
              </div>
            ) : (
              <div className="rounded-md border">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Name</TableHead>
                      <TableHead>Slug</TableHead>
                      <TableHead className="text-center">Duas</TableHead>
                      <TableHead className="text-center">Premium</TableHead>
                      <TableHead className="w-[50px]"></TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {filteredCollections.map((col) => (
                      <TableRow key={col.id}>
                        <TableCell>
                          <div className="flex items-center gap-2">
                            {col.isPremium && <Crown className="h-4 w-4 text-amber-500" />}
                            <span className="font-medium">{col.name}</span>
                          </div>
                        </TableCell>
                        <TableCell className="text-muted-foreground font-mono text-sm">
                          {col.slug}
                        </TableCell>
                        <TableCell className="text-center">
                          <div className="flex items-center justify-center gap-1">
                            <BookOpen className="h-4 w-4 text-muted-foreground" />
                            <span>{col.duaCount || 0}</span>
                          </div>
                        </TableCell>
                        <TableCell className="text-center">
                          <Switch
                            checked={col.isPremium}
                            onCheckedChange={() => handleTogglePremium(col)}
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
                              <DropdownMenuItem onClick={() => handleEditClick(col)}>
                                <Pencil className="h-4 w-4 mr-2" />
                                Edit
                              </DropdownMenuItem>
                              <DropdownMenuItem
                                onClick={() => setCollectionToDelete(col)}
                                className="text-destructive focus:text-destructive"
                                disabled={(col.duaCount || 0) > 0}
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

      {/* Collection Form Dialog */}
      <Dialog open={isFormOpen} onOpenChange={(open) => { setIsFormOpen(open); if (!open) setCollectionToEdit(null); }}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{collectionToEdit ? "Edit Collection" : "Add Collection"}</DialogTitle>
            <DialogDescription>
              {collectionToEdit ? "Update collection details" : "Create a new collection for content access tiers"}
            </DialogDescription>
          </DialogHeader>
          <Form {...form}>
            <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
              <FormField
                control={form.control}
                name="name"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Name *</FormLabel>
                    <FormControl>
                      <Input
                        placeholder="e.g., Essential Duas"
                        {...field}
                        onChange={(e) => { field.onChange(e); handleNameChange(e.target.value); }}
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={form.control}
                name="slug"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Slug *</FormLabel>
                    <FormControl>
                      <Input placeholder="essential-duas" {...field} />
                    </FormControl>
                    <FormDescription>Used for internal identification</FormDescription>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={form.control}
                name="description"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Description</FormLabel>
                    <FormControl>
                      <Textarea placeholder="Optional description..." {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={form.control}
                name="isPremium"
                render={({ field }) => (
                  <FormItem className="flex items-center justify-between rounded-lg border p-4">
                    <div>
                      <FormLabel>Premium Collection</FormLabel>
                      <FormDescription>
                        Duas in this collection require a subscription
                      </FormDescription>
                    </div>
                    <FormControl>
                      <Switch checked={field.value} onCheckedChange={field.onChange} />
                    </FormControl>
                  </FormItem>
                )}
              />
              <div className="flex justify-end gap-3 pt-4">
                <Button type="button" variant="outline" onClick={() => setIsFormOpen(false)} disabled={isPending}>
                  Cancel
                </Button>
                <Button type="submit" disabled={isPending}>
                  {isPending && <Loader2 className="h-4 w-4 animate-spin mr-2" />}
                  {collectionToEdit ? "Update" : "Create"}
                </Button>
              </div>
            </form>
          </Form>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation */}
      <AlertDialog open={!!collectionToDelete} onOpenChange={() => setCollectionToDelete(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete Collection</AlertDialogTitle>
            <AlertDialogDescription>
              Are you sure you want to delete "{collectionToDelete?.name}"?
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction
              onClick={handleDelete}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
              disabled={deleteCollection.isPending}
            >
              {deleteCollection.isPending && <Loader2 className="h-4 w-4 animate-spin mr-2" />}
              Delete
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </motion.div>
  );
}
