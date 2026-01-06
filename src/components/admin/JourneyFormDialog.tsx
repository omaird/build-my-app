import { useEffect } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
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
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import { Switch } from "@/components/ui/switch";
import { Loader2 } from "lucide-react";
import { useCreateJourney, useUpdateJourney } from "@/hooks/admin";
import type { AdminJourney, JourneyFormInput } from "@/types/admin";
import { toast } from "sonner";
import { ScrollArea } from "@/components/ui/scroll-area";

// Validation schema for journey form
const journeyFormSchema = z.object({
  name: z.string().min(3, "Name must be at least 3 characters"),
  slug: z.string()
    .min(3, "Slug must be at least 3 characters")
    .regex(/^[a-z0-9-]+$/, "Slug must be lowercase with hyphens only (e.g., morning-adhkar)"),
  description: z.string().optional(),
  emoji: z.string().optional(),
  estimatedMinutes: z.number().min(1).max(120).default(15),
  dailyXp: z.number().min(1).max(1000).default(100),
  isPremium: z.boolean().default(false),
  isFeatured: z.boolean().default(false),
  sortOrder: z.number().min(0).default(0),
});

type FormValues = z.infer<typeof journeyFormSchema>;

interface JourneyFormDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  journey: AdminJourney | null; // null = create mode, AdminJourney = edit mode
}

export function JourneyFormDialog({ open, onOpenChange, journey }: JourneyFormDialogProps) {
  const createJourney = useCreateJourney();
  const updateJourney = useUpdateJourney();

  const isEditing = !!journey;

  const form = useForm<FormValues>({
    resolver: zodResolver(journeyFormSchema),
    defaultValues: {
      name: "",
      slug: "",
      description: "",
      emoji: "📿",
      estimatedMinutes: 15,
      dailyXp: 100,
      isPremium: false,
      isFeatured: false,
      sortOrder: 0,
    },
  });

  // Reset form when journey changes
  useEffect(() => {
    if (journey) {
      form.reset({
        name: journey.name,
        slug: journey.slug,
        description: journey.description || "",
        emoji: journey.emoji,
        estimatedMinutes: journey.estimatedMinutes,
        dailyXp: journey.dailyXp,
        isPremium: journey.isPremium,
        isFeatured: journey.isFeatured,
        sortOrder: journey.sortOrder,
      });
    } else {
      form.reset({
        name: "",
        slug: "",
        description: "",
        emoji: "📿",
        estimatedMinutes: 15,
        dailyXp: 100,
        isPremium: false,
        isFeatured: false,
        sortOrder: 0,
      });
    }
  }, [journey, form]);

  // Auto-generate slug from name
  const handleNameChange = (name: string) => {
    if (!isEditing) {
      const slug = name
        .toLowerCase()
        .replace(/[^a-z0-9\s-]/g, "")
        .replace(/\s+/g, "-")
        .replace(/-+/g, "-");
      form.setValue("slug", slug);
    }
  };

  const onSubmit = async (values: FormValues) => {
    try {
      const input: JourneyFormInput = {
        name: values.name,
        slug: values.slug,
        description: values.description,
        emoji: values.emoji,
        estimatedMinutes: values.estimatedMinutes,
        dailyXp: values.dailyXp,
        isPremium: values.isPremium,
        isFeatured: values.isFeatured,
        sortOrder: values.sortOrder,
      };

      if (isEditing && journey) {
        await updateJourney.mutateAsync({ id: journey.id, ...input });
        toast.success("Journey updated successfully");
      } else {
        await createJourney.mutateAsync(input);
        toast.success("Journey created successfully");
      }

      onOpenChange(false);
    } catch (error) {
      toast.error(isEditing ? "Failed to update journey" : "Failed to create journey");
      console.error(error);
    }
  };

  const isPending = createJourney.isPending || updateJourney.isPending;

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-lg max-h-[90vh]">
        <DialogHeader>
          <DialogTitle>{isEditing ? "Edit Journey" : "Create New Journey"}</DialogTitle>
          <DialogDescription>
            {isEditing
              ? "Update the journey details below"
              : "Create a new themed collection of duas"}
          </DialogDescription>
        </DialogHeader>

        <ScrollArea className="max-h-[70vh] pr-4">
          <Form {...form}>
            <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
              {/* Name & Emoji */}
              <div className="grid grid-cols-[1fr,80px] gap-4">
                <FormField
                  control={form.control}
                  name="name"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Journey Name *</FormLabel>
                      <FormControl>
                        <Input
                          placeholder="e.g., Morning Adhkar"
                          {...field}
                          onChange={(e) => {
                            field.onChange(e);
                            handleNameChange(e.target.value);
                          }}
                        />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="emoji"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Emoji</FormLabel>
                      <FormControl>
                        <Input
                          className="text-center text-2xl"
                          placeholder="📿"
                          {...field}
                        />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>

              {/* Slug */}
              <FormField
                control={form.control}
                name="slug"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Slug *</FormLabel>
                    <FormControl>
                      <Input placeholder="morning-adhkar" {...field} />
                    </FormControl>
                    <FormDescription>
                      URL path: /journeys/{field.value || "slug"}
                    </FormDescription>
                    <FormMessage />
                  </FormItem>
                )}
              />

              {/* Description */}
              <FormField
                control={form.control}
                name="description"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Description</FormLabel>
                    <FormControl>
                      <Textarea
                        placeholder="Describe what this journey includes..."
                        className="min-h-[80px]"
                        {...field}
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              {/* Duration & XP */}
              <div className="grid grid-cols-2 gap-4">
                <FormField
                  control={form.control}
                  name="estimatedMinutes"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Est. Duration (min) *</FormLabel>
                      <FormControl>
                        <Input
                          type="number"
                          min={1}
                          max={120}
                          {...field}
                          onChange={(e) => field.onChange(parseInt(e.target.value) || 15)}
                        />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="dailyXp"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Daily XP *</FormLabel>
                      <FormControl>
                        <Input
                          type="number"
                          min={1}
                          max={1000}
                          {...field}
                          onChange={(e) => field.onChange(parseInt(e.target.value) || 100)}
                        />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>

              {/* Sort Order */}
              <FormField
                control={form.control}
                name="sortOrder"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Sort Order</FormLabel>
                    <FormControl>
                      <Input
                        type="number"
                        min={0}
                        {...field}
                        onChange={(e) => field.onChange(parseInt(e.target.value) || 0)}
                      />
                    </FormControl>
                    <FormDescription>
                      Lower numbers appear first in journey lists
                    </FormDescription>
                    <FormMessage />
                  </FormItem>
                )}
              />

              {/* Featured & Premium toggles */}
              <div className="flex flex-col gap-4 rounded-lg border p-4">
                <FormField
                  control={form.control}
                  name="isFeatured"
                  render={({ field }) => (
                    <FormItem className="flex items-center justify-between">
                      <div>
                        <FormLabel>Featured Journey</FormLabel>
                        <FormDescription>
                          Featured journeys appear prominently on the home page
                        </FormDescription>
                      </div>
                      <FormControl>
                        <Switch
                          checked={field.value}
                          onCheckedChange={field.onChange}
                        />
                      </FormControl>
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="isPremium"
                  render={({ field }) => (
                    <FormItem className="flex items-center justify-between">
                      <div>
                        <FormLabel>Premium Journey</FormLabel>
                        <FormDescription>
                          Premium journeys require a subscription
                        </FormDescription>
                      </div>
                      <FormControl>
                        <Switch
                          checked={field.value}
                          onCheckedChange={field.onChange}
                        />
                      </FormControl>
                    </FormItem>
                  )}
                />
              </div>

              {/* Submit Button */}
              <div className="flex justify-end gap-3 pt-4">
                <Button
                  type="button"
                  variant="outline"
                  onClick={() => onOpenChange(false)}
                  disabled={isPending}
                >
                  Cancel
                </Button>
                <Button type="submit" disabled={isPending}>
                  {isPending && <Loader2 className="h-4 w-4 animate-spin mr-2" />}
                  {isEditing ? "Update Journey" : "Create Journey"}
                </Button>
              </div>
            </form>
          </Form>
        </ScrollArea>
      </DialogContent>
    </Dialog>
  );
}
