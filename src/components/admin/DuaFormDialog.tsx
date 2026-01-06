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
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Loader2 } from "lucide-react";
import { useCreateDua, useUpdateDua, useAdminCategories, useAdminCollections } from "@/hooks/admin";
import type { AdminDua, DuaFormInput } from "@/types/admin";
import { toast } from "sonner";
import { ScrollArea } from "@/components/ui/scroll-area";

// Validation schema for dua form
const duaFormSchema = z.object({
  titleEn: z.string().min(3, "Title must be at least 3 characters"),
  titleAr: z.string().optional(),
  arabicText: z.string().min(1, "Arabic text is required"),
  transliteration: z.string().optional(),
  translationEn: z.string().optional(),
  categoryId: z.number().nullable(),
  collectionId: z.number().nullable(),
  source: z.string().optional(),
  repetitions: z.number().min(1).max(100).default(1),
  bestTime: z.string().optional(),
  difficulty: z.enum(["Beginner", "Intermediate", "Advanced"]).nullable(),
  estDurationSec: z.number().optional(),
  rizqBenefit: z.string().optional(),
  context: z.string().optional(),
  propheticContext: z.string().optional(),
  xpValue: z.number().min(1).max(500).default(10),
  audioUrl: z.string().optional(),
});

type FormValues = z.infer<typeof duaFormSchema>;

interface DuaFormDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  dua: AdminDua | null; // null = create mode, AdminDua = edit mode
}

export function DuaFormDialog({ open, onOpenChange, dua }: DuaFormDialogProps) {
  const createDua = useCreateDua();
  const updateDua = useUpdateDua();
  const { data: categories } = useAdminCategories();
  const { data: collections } = useAdminCollections();

  const isEditing = !!dua;

  const form = useForm<FormValues>({
    resolver: zodResolver(duaFormSchema),
    defaultValues: {
      titleEn: "",
      titleAr: "",
      arabicText: "",
      transliteration: "",
      translationEn: "",
      categoryId: null,
      collectionId: null,
      source: "",
      repetitions: 1,
      bestTime: "",
      difficulty: null,
      estDurationSec: undefined,
      rizqBenefit: "",
      context: "",
      propheticContext: "",
      xpValue: 10,
      audioUrl: "",
    },
  });

  // Reset form when dua changes
  useEffect(() => {
    if (dua) {
      form.reset({
        titleEn: dua.titleEn,
        titleAr: dua.titleAr || "",
        arabicText: dua.arabicText,
        transliteration: dua.transliteration || "",
        translationEn: dua.translationEn || "",
        categoryId: dua.categoryId,
        collectionId: dua.collectionId,
        source: dua.source || "",
        repetitions: dua.repetitions,
        bestTime: dua.bestTime || "",
        difficulty: dua.difficulty,
        estDurationSec: dua.estDurationSec || undefined,
        rizqBenefit: dua.rizqBenefit || "",
        context: dua.context || "",
        propheticContext: dua.propheticContext || "",
        xpValue: dua.xpValue,
        audioUrl: dua.audioUrl || "",
      });
    } else {
      form.reset({
        titleEn: "",
        titleAr: "",
        arabicText: "",
        transliteration: "",
        translationEn: "",
        categoryId: null,
        collectionId: null,
        source: "",
        repetitions: 1,
        bestTime: "",
        difficulty: null,
        estDurationSec: undefined,
        rizqBenefit: "",
        context: "",
        propheticContext: "",
        xpValue: 10,
        audioUrl: "",
      });
    }
  }, [dua, form]);

  const onSubmit = async (values: FormValues) => {
    try {
      const input: DuaFormInput = {
        titleEn: values.titleEn,
        titleAr: values.titleAr,
        arabicText: values.arabicText,
        transliteration: values.transliteration,
        translationEn: values.translationEn,
        categoryId: values.categoryId,
        collectionId: values.collectionId,
        source: values.source,
        repetitions: values.repetitions,
        bestTime: values.bestTime,
        difficulty: values.difficulty,
        estDurationSec: values.estDurationSec,
        rizqBenefit: values.rizqBenefit,
        context: values.context,
        propheticContext: values.propheticContext,
        xpValue: values.xpValue,
        audioUrl: values.audioUrl,
      };

      if (isEditing && dua) {
        await updateDua.mutateAsync({ id: dua.id, ...input });
        toast.success("Dua updated successfully");
      } else {
        await createDua.mutateAsync(input);
        toast.success("Dua created successfully");
      }

      onOpenChange(false);
    } catch (error) {
      toast.error(isEditing ? "Failed to update dua" : "Failed to create dua");
      console.error(error);
    }
  };

  const isPending = createDua.isPending || updateDua.isPending;

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-2xl max-h-[90vh]">
        <DialogHeader>
          <DialogTitle>{isEditing ? "Edit Dua" : "Add New Dua"}</DialogTitle>
          <DialogDescription>
            {isEditing
              ? "Update the dua details below"
              : "Fill in the details to add a new dua to the library"}
          </DialogDescription>
        </DialogHeader>

        <ScrollArea className="max-h-[70vh] pr-4">
          <Form {...form}>
            <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
              {/* Title Section */}
              <div className="grid grid-cols-2 gap-4">
                <FormField
                  control={form.control}
                  name="titleEn"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Title (English) *</FormLabel>
                      <FormControl>
                        <Input placeholder="Enter dua title" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="titleAr"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Title (Arabic)</FormLabel>
                      <FormControl>
                        <Input
                          dir="rtl"
                          className="font-arabic"
                          placeholder="اسم الدعاء"
                          {...field}
                        />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>

              {/* Arabic Text */}
              <FormField
                control={form.control}
                name="arabicText"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Arabic Text *</FormLabel>
                    <FormControl>
                      <Textarea
                        dir="rtl"
                        className="font-arabic text-xl leading-[2.2] min-h-[100px]"
                        placeholder="أدخل النص العربي للدعاء"
                        {...field}
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              {/* Transliteration */}
              <FormField
                control={form.control}
                name="transliteration"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Transliteration</FormLabel>
                    <FormControl>
                      <Textarea
                        placeholder="Enter transliteration (e.g., Bismillah...)"
                        className="min-h-[80px]"
                        {...field}
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              {/* Translation */}
              <FormField
                control={form.control}
                name="translationEn"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Translation (English)</FormLabel>
                    <FormControl>
                      <Textarea
                        placeholder="Enter English translation"
                        className="min-h-[80px]"
                        {...field}
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              {/* Category & Collection */}
              <div className="grid grid-cols-2 gap-4">
                <FormField
                  control={form.control}
                  name="categoryId"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Category</FormLabel>
                      <Select
                        value={field.value?.toString() || ""}
                        onValueChange={(val) => field.onChange(val ? parseInt(val) : null)}
                      >
                        <FormControl>
                          <SelectTrigger>
                            <SelectValue placeholder="Select category" />
                          </SelectTrigger>
                        </FormControl>
                        <SelectContent>
                          {categories?.map((cat) => (
                            <SelectItem key={cat.id} value={cat.id.toString()}>
                              {cat.name}
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="collectionId"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Collection</FormLabel>
                      <Select
                        value={field.value?.toString() || ""}
                        onValueChange={(val) => field.onChange(val ? parseInt(val) : null)}
                      >
                        <FormControl>
                          <SelectTrigger>
                            <SelectValue placeholder="Select collection" />
                          </SelectTrigger>
                        </FormControl>
                        <SelectContent>
                          {collections?.map((col) => (
                            <SelectItem key={col.id} value={col.id.toString()}>
                              {col.name} {col.isPremium && "⭐"}
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>

              {/* Source & Best Time */}
              <div className="grid grid-cols-2 gap-4">
                <FormField
                  control={form.control}
                  name="source"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Source</FormLabel>
                      <FormControl>
                        <Input placeholder="e.g., Sahih Bukhari 6306" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="bestTime"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Best Time</FormLabel>
                      <FormControl>
                        <Input placeholder="e.g., Morning after Fajr" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>

              {/* Repetitions, XP, Difficulty */}
              <div className="grid grid-cols-3 gap-4">
                <FormField
                  control={form.control}
                  name="repetitions"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Repetitions *</FormLabel>
                      <FormControl>
                        <Input
                          type="number"
                          min={1}
                          max={100}
                          {...field}
                          onChange={(e) => field.onChange(parseInt(e.target.value) || 1)}
                        />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="xpValue"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>XP Value *</FormLabel>
                      <FormControl>
                        <Input
                          type="number"
                          min={1}
                          max={500}
                          {...field}
                          onChange={(e) => field.onChange(parseInt(e.target.value) || 10)}
                        />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="difficulty"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Difficulty</FormLabel>
                      <Select
                        value={field.value || ""}
                        onValueChange={(val) => field.onChange(val || null)}
                      >
                        <FormControl>
                          <SelectTrigger>
                            <SelectValue placeholder="Select" />
                          </SelectTrigger>
                        </FormControl>
                        <SelectContent>
                          <SelectItem value="Beginner">Beginner</SelectItem>
                          <SelectItem value="Intermediate">Intermediate</SelectItem>
                          <SelectItem value="Advanced">Advanced</SelectItem>
                        </SelectContent>
                      </Select>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>

              {/* Rizq Benefit */}
              <FormField
                control={form.control}
                name="rizqBenefit"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Rizq Benefit</FormLabel>
                    <FormControl>
                      <Textarea
                        placeholder="Describe the benefits and virtues of this dua"
                        className="min-h-[80px]"
                        {...field}
                      />
                    </FormControl>
                    <FormDescription>
                      Benefits and rewards mentioned in authentic sources
                    </FormDescription>
                    <FormMessage />
                  </FormItem>
                )}
              />

              {/* Context / Story */}
              <FormField
                control={form.control}
                name="context"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Context / Story</FormLabel>
                    <FormControl>
                      <Textarea
                        placeholder="Historical background or narrative context"
                        className="min-h-[80px]"
                        {...field}
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              {/* Prophetic Context */}
              <FormField
                control={form.control}
                name="propheticContext"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Prophetic Context</FormLabel>
                    <FormControl>
                      <Textarea
                        placeholder="What the Prophet ﷺ said about this dua, when recommended, circumstances"
                        className="min-h-[80px]"
                        {...field}
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

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
                  {isEditing ? "Update Dua" : "Create Dua"}
                </Button>
              </div>
            </form>
          </Form>
        </ScrollArea>
      </DialogContent>
    </Dialog>
  );
}
