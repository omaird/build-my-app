# Daily Adkhar Tab Implementation Plan

## Overview

Replace the "Practice" tab with "Daily Adkhar" - a habit-focused daily routine tracker where users can view their habits grouped by time of day and quickly complete duas inline without navigating away.

---

## Problem Statement

1. The current "Practice" tab doesn't emphasize habit-building
2. Users must navigate away from their daily routine to practice duas
3. The "Practice" naming doesn't convey the routine nature of the feature

---

## Solution Summary

- **Rename:** "Practice" → "Adkhar" (or "Daily Adkhar" in full)
- **New Route:** `/adkhar` replaces `/practice` in bottom nav
- **Core Feature:** QuickPracticeSheet - complete duas inline without page navigation
- **Library Integration:** "Add to Adkhar" button to add custom habits

---

## Critical Files Reference

| File | Purpose |
|------|---------|
| `src/components/BottomNav.tsx` | Tab navigation - rename & reroute |
| `src/App.tsx` | Route definitions |
| `src/pages/PracticePage.tsx` | Tap counter logic to extract |
| `src/components/habits/TodaysHabits.tsx` | Current habit display - refactor |
| `src/components/habits/HabitItem.tsx` | Individual habit - update click handler |
| `src/components/habits/HabitPreviewSheet.tsx` | Preview modal - replace with QuickPractice |
| `src/hooks/useUserHabits.ts` | Habit state management |
| `src/hooks/useActivity.ts` | Completion tracking hooks |

---

## Implementation Phases

### Phase 1: Foundation (Routes & Page Structure)

#### Task 1.1: Create DailyAdkharPage
**File:** `src/pages/DailyAdkharPage.tsx` (NEW)

**Steps:**
1. Create new file at `src/pages/DailyAdkharPage.tsx`
2. Import required hooks:
   ```typescript
   import { useUserHabits } from "@/hooks/useUserHabits";
   import { useDailyActivity } from "@/hooks/useActivity";
   ```
3. Import existing components:
   ```typescript
   import { HabitTimeSlotSection } from "@/components/habits/HabitTimeSlotSection";
   import { HabitProgressBar } from "@/components/habits/HabitProgressBar";
   import { EmptyHabitsState } from "@/components/habits/EmptyHabitsState";
   ```
4. Implement page structure:
   - Header with "Daily Adkhar" title
   - Progress summary (X/Y completed, XP earned)
   - Time slot sections (Morning/Anytime/Evening)
   - Empty state when no habits configured
   - "Add Habit" CTA linking to Library/Journeys

**Component Structure:**
```typescript
export default function DailyAdkharPage() {
  const { hasHabits, groupedHabits, progress, isLoading } = useUserHabits();
  const [selectedHabit, setSelectedHabit] = useState<HabitWithDua | null>(null);
  const [practiceOpen, setPracticeOpen] = useState(false);

  // Handle habit click -> open QuickPracticeSheet
  const handleHabitClick = (habit: HabitWithDua) => {
    setSelectedHabit(habit);
    setPracticeOpen(true);
  };

  return (
    <div className="pb-20"> {/* Space for bottom nav */}
      {/* Header */}
      {/* Progress Bar */}
      {/* Time Slot Sections */}
      {/* QuickPracticeSheet */}
      {/* Empty State or Add CTA */}
    </div>
  );
}
```

#### Task 1.2: Update App.tsx Routes
**File:** `src/App.tsx`

**Steps:**
1. Add import for new page:
   ```typescript
   import DailyAdkharPage from "./pages/DailyAdkharPage";
   ```
2. Add new route (keep existing practice routes for deep links):
   ```typescript
   <Route path="/adkhar" element={<ProtectedRoute><DailyAdkharPage /></ProtectedRoute>} />
   ```
3. Keep existing routes:
   ```typescript
   // Keep for deep links and batch practice
   <Route path="/practice" element={<ProtectedRoute><PracticePage /></ProtectedRoute>} />
   <Route path="/practice/:duaId" element={<ProtectedRoute><PracticePage /></ProtectedRoute>} />
   ```

#### Task 1.3: Update BottomNav
**File:** `src/components/BottomNav.tsx`

**Steps:**
1. Change navItems array:
   ```typescript
   // Before:
   { path: "/practice", icon: Target, label: "Practice" }

   // After:
   { path: "/adkhar", icon: BookHeart, label: "Adkhar" }
   ```
2. Import new icon (consider options):
   - `BookHeart` - book with heart (spiritual)
   - `CalendarCheck` - daily routine feel
   - `ListChecks` - task completion
   - `Sparkles` - spiritual/blessed

**Icon Recommendation:** `BookHeart` from lucide-react - conveys spiritual reading/practice

---

### Phase 2: Quick Practice Flow (Core Feature)

#### Task 2.1: Create QuickPracticeSheet Component
**File:** `src/components/habits/QuickPracticeSheet.tsx` (NEW)

**Purpose:** Full-screen bottom sheet for completing a dua inline without page navigation

**Steps:**
1. Create new file
2. Define props interface:
   ```typescript
   interface QuickPracticeSheetProps {
     habit: HabitWithDua | null;
     open: boolean;
     onOpenChange: (open: boolean) => void;
     onComplete?: () => void;
   }
   ```

3. Import required hooks (extract from PracticePage.tsx):
   ```typescript
   import { useDailyActivity, useUserProgress } from "@/hooks/useActivity";
   import { useUserHabits } from "@/hooks/useUserHabits";
   ```

4. Implement state management:
   ```typescript
   const [tapCount, setTapCount] = useState(0);
   const [isCompleted, setIsCompleted] = useState(false);
   const [isAnimating, setIsAnimating] = useState(false);
   const [showTransliteration, setShowTransliteration] = useState(true);
   ```

5. Implement completion logic (from PracticePage.tsx lines 45-65):
   ```typescript
   const { markDuaCompleted: markActivityCompleted } = useDailyActivity();
   const { markDuaCompleted: markProgressCompleted, hasCompletedToday } = useUserProgress();
   const { markHabitCompleted } = useUserHabits();

   const handleTap = useCallback(() => {
     if (!habit || isCompleted || habit.isCompletedToday) return;

     setIsAnimating(true);
     setTimeout(() => setIsAnimating(false), 150);

     const newCount = tapCount + 1;
     setTapCount(newCount);

     if (newCount >= habit.dua.repetitions) {
       setIsCompleted(true);
       markActivityCompleted(habit.dua.id, habit.dua.xpValue);
       markProgressCompleted(habit.dua.id);
       markHabitCompleted(habit.dua.id);
       toast({ title: "Completed! ✨", description: `+${habit.dua.xpValue} XP` });
     }
   }, [habit, tapCount, isCompleted]);
   ```

6. Build UI structure:
   ```typescript
   <Sheet open={open} onOpenChange={onOpenChange}>
     <SheetContent side="bottom" className="h-[85vh] rounded-t-3xl">
       {/* Header with close button */}
       <SheetHeader>
         <SheetTitle>{habit?.dua.title}</SheetTitle>
       </SheetHeader>

       {/* Arabic text - large, centered */}
       <div dir="rtl" className="text-2xl font-arabic text-center py-8">
         {habit?.dua.arabic}
       </div>

       {/* Transliteration toggle */}
       {showTransliteration && (
         <p className="text-center text-muted-foreground italic">
           {habit?.dua.transliteration}
         </p>
       )}

       {/* Translation */}
       <p className="text-center text-sm text-muted-foreground mt-4">
         {habit?.dua.translation}
       </p>

       {/* Tap Counter Area */}
       <div
         onClick={handleTap}
         className={cn(
           "flex flex-col items-center justify-center py-12 cursor-pointer",
           isAnimating && "scale-[0.98]"
         )}
       >
         {/* Progress ring or counter */}
         <div className="relative w-32 h-32 rounded-full border-4 flex items-center justify-center">
           {isCompleted || habit?.isCompletedToday ? (
             <Check className="h-12 w-12 text-primary" />
           ) : (
             <span className="text-4xl font-bold">
               {tapCount}/{habit?.dua.repetitions}
             </span>
           )}
         </div>

         {/* Status text */}
         <p className="mt-4 text-muted-foreground">
           {isCompleted || habit?.isCompletedToday
             ? "Completed"
             : "Tap to count"}
         </p>
       </div>

       {/* Action buttons */}
       <div className="flex gap-2 mt-auto">
         <Button variant="outline" onClick={() => setTapCount(0)}>
           Reset
         </Button>
         <Button
           variant="outline"
           onClick={() => setShowTransliteration(!showTransliteration)}
         >
           {showTransliteration ? "Hide" : "Show"} Transliteration
         </Button>
       </div>
     </SheetContent>
   </Sheet>
   ```

7. Reset state when habit changes:
   ```typescript
   useEffect(() => {
     if (habit) {
       setTapCount(0);
       setIsCompleted(false);
     }
   }, [habit?.id]);
   ```

#### Task 2.2: Update HabitItem Click Behavior
**File:** `src/components/habits/HabitItem.tsx`

**Current Behavior:** Calls `onClick` prop which opens HabitPreviewSheet
**New Behavior:** Same - but parent will open QuickPracticeSheet instead

**Steps:**
1. No changes needed to HabitItem itself
2. Update parent (DailyAdkharPage) to pass handler that opens QuickPracticeSheet

#### Task 2.3: Integrate QuickPracticeSheet in DailyAdkharPage
**File:** `src/pages/DailyAdkharPage.tsx`

**Steps:**
1. Import QuickPracticeSheet:
   ```typescript
   import { QuickPracticeSheet } from "@/components/habits/QuickPracticeSheet";
   ```

2. Add state for selected habit:
   ```typescript
   const [selectedHabit, setSelectedHabit] = useState<HabitWithDua | null>(null);
   const [practiceOpen, setPracticeOpen] = useState(false);
   ```

3. Handle completion (refresh data):
   ```typescript
   const handleComplete = () => {
     // Data updates via hooks automatically
     // Optionally auto-advance to next habit
   };
   ```

4. Render sheet:
   ```typescript
   <QuickPracticeSheet
     habit={selectedHabit}
     open={practiceOpen}
     onOpenChange={setPracticeOpen}
     onComplete={handleComplete}
   />
   ```

---

### Phase 3: Library Integration

#### Task 3.1: Create AddToAdkharSheet Component
**File:** `src/components/habits/AddToAdkharSheet.tsx` (NEW)

**Purpose:** Time slot selector when adding a dua from Library

**Steps:**
1. Create new file
2. Define props:
   ```typescript
   interface AddToAdkharSheetProps {
     dua: Dua | null;
     open: boolean;
     onOpenChange: (open: boolean) => void;
   }
   ```

3. Import hook:
   ```typescript
   import { useUserHabits } from "@/hooks/useUserHabits";
   ```

4. Implement time slot selection:
   ```typescript
   const { addCustomHabit, todaysHabits } = useUserHabits();
   const [selectedSlot, setSelectedSlot] = useState<TimeSlot>("anytime");

   const isAlreadyAdded = todaysHabits.some(h => h.duaId === dua?.id);

   const handleAdd = () => {
     if (dua && !isAlreadyAdded) {
       addCustomHabit(dua.id, selectedSlot);
       toast({ title: "Added to Daily Adkhar", description: `${dua.title} added to ${selectedSlot}` });
       onOpenChange(false);
     }
   };
   ```

5. Build UI:
   ```typescript
   <Sheet open={open} onOpenChange={onOpenChange}>
     <SheetContent side="bottom" className="rounded-t-2xl">
       <SheetHeader>
         <SheetTitle>Add to Daily Adkhar</SheetTitle>
         <SheetDescription>{dua?.title}</SheetDescription>
       </SheetHeader>

       {isAlreadyAdded ? (
         <div className="py-6 text-center">
           <Check className="h-8 w-8 mx-auto text-primary" />
           <p>Already in your Daily Adkhar</p>
         </div>
       ) : (
         <>
           <div className="py-6 space-y-3">
             <p className="text-sm text-muted-foreground">When would you like to practice this?</p>

             {/* Time slot buttons */}
             <div className="grid grid-cols-3 gap-2">
               <Button
                 variant={selectedSlot === "morning" ? "default" : "outline"}
                 onClick={() => setSelectedSlot("morning")}
               >
                 <Sun className="h-4 w-4 mr-2" />
                 Morning
               </Button>
               <Button
                 variant={selectedSlot === "anytime" ? "default" : "outline"}
                 onClick={() => setSelectedSlot("anytime")}
               >
                 <Clock className="h-4 w-4 mr-2" />
                 Anytime
               </Button>
               <Button
                 variant={selectedSlot === "evening" ? "default" : "outline"}
                 onClick={() => setSelectedSlot("evening")}
               >
                 <Moon className="h-4 w-4 mr-2" />
                 Evening
               </Button>
             </div>
           </div>

           <Button onClick={handleAdd} className="w-full">
             Add to Daily Adkhar
           </Button>
         </>
       )}
     </SheetContent>
   </Sheet>
   ```

#### Task 3.2: Update DuaCard with Add Button
**File:** `src/components/DuaCard.tsx`

**Steps:**
1. Add prop for add action:
   ```typescript
   interface DuaCardProps {
     dua: Dua;
     isCompleted?: boolean;
     onAddToAdkhar?: (dua: Dua) => void; // NEW
   }
   ```

2. Add button to card (subtle, in corner or as action):
   ```typescript
   {onAddToAdkhar && (
     <Button
       variant="ghost"
       size="icon"
       className="absolute top-2 right-2"
       onClick={(e) => {
         e.stopPropagation(); // Prevent card click
         onAddToAdkhar(dua);
       }}
     >
       <Plus className="h-4 w-4" />
     </Button>
   )}
   ```

3. Show indicator if already added:
   ```typescript
   const { todaysHabits } = useUserHabits();
   const isInAdkhar = todaysHabits.some(h => h.duaId === dua.id);

   {isInAdkhar && (
     <Badge variant="secondary" className="absolute top-2 right-2">
       <Check className="h-3 w-3 mr-1" /> In Adkhar
     </Badge>
   )}
   ```

#### Task 3.3: Update LibraryPage
**File:** `src/pages/LibraryPage.tsx`

**Steps:**
1. Add state for add sheet:
   ```typescript
   const [addSheetOpen, setAddSheetOpen] = useState(false);
   const [selectedDua, setSelectedDua] = useState<Dua | null>(null);

   const handleAddToAdkhar = (dua: Dua) => {
     setSelectedDua(dua);
     setAddSheetOpen(true);
   };
   ```

2. Pass handler to DuaCard:
   ```typescript
   <DuaCard
     dua={dua}
     isCompleted={completedToday.includes(dua.id)}
     onAddToAdkhar={handleAddToAdkhar}
   />
   ```

3. Render AddToAdkharSheet:
   ```typescript
   <AddToAdkharSheet
     dua={selectedDua}
     open={addSheetOpen}
     onOpenChange={setAddSheetOpen}
   />
   ```

---

### Phase 4: Home Page Simplification

#### Task 4.1: Create HabitsSummaryCard Component
**File:** `src/components/habits/HabitsSummaryCard.tsx` (NEW)

**Purpose:** Compact summary card for HomePage that links to Daily Adkhar

**Steps:**
1. Create new file
2. Implement compact display:
   ```typescript
   export function HabitsSummaryCard() {
     const { progress, hasHabits, nextUncompletedHabit } = useUserHabits();
     const navigate = useNavigate();

     if (!hasHabits) {
       return (
         <Card className="p-4">
           <p className="text-muted-foreground">No habits configured</p>
           <Button variant="link" onClick={() => navigate("/journeys")}>
             Browse Journeys →
           </Button>
         </Card>
       );
     }

     const allCompleted = progress.completed === progress.total;

     return (
       <Card
         className="p-4 cursor-pointer hover:bg-muted/50"
         onClick={() => navigate("/adkhar")}
       >
         <div className="flex items-center justify-between">
           <div>
             <h3 className="font-semibold">Daily Adkhar</h3>
             <p className="text-sm text-muted-foreground">
               {progress.completed}/{progress.total} completed • {progress.earnedXp} XP
             </p>
           </div>
           {allCompleted ? (
             <Check className="h-6 w-6 text-primary" />
           ) : (
             <ChevronRight className="h-5 w-5 text-muted-foreground" />
           )}
         </div>

         {/* Mini progress bar */}
         <div className="mt-3 h-2 bg-muted rounded-full overflow-hidden">
           <div
             className="h-full bg-primary transition-all"
             style={{ width: `${progress.percentage}%` }}
           />
         </div>
       </Card>
     );
   }
   ```

#### Task 4.2: Update HomePage
**File:** `src/pages/HomePage.tsx`

**Steps:**
1. Replace TodaysHabits with HabitsSummaryCard:
   ```typescript
   // Before:
   import { TodaysHabits } from "@/components/habits/TodaysHabits";

   // After:
   import { HabitsSummaryCard } from "@/components/habits/HabitsSummaryCard";
   ```

2. Update render:
   ```typescript
   // Before (around line 100):
   <TodaysHabits />

   // After:
   <HabitsSummaryCard />
   ```

3. Update "Continue Practice" button to navigate to `/adkhar`:
   ```typescript
   // Before:
   navigate(`/practice/${nextUncompletedHabit.id}`);

   // After:
   navigate("/adkhar");
   ```

---

### Phase 5: Polish & Edge Cases

#### Task 5.1: Empty State for DailyAdkharPage
**File:** `src/pages/DailyAdkharPage.tsx`

**Steps:**
1. Create or update EmptyHabitsState component:
   ```typescript
   {!hasHabits && (
     <div className="flex flex-col items-center justify-center py-12 text-center">
       <BookOpen className="h-16 w-16 text-muted-foreground/50 mb-4" />
       <h3 className="text-lg font-semibold">No Daily Adkhar Yet</h3>
       <p className="text-muted-foreground mt-2 max-w-xs">
         Start a journey or add duas from the library to build your daily routine.
       </p>
       <div className="flex gap-3 mt-6">
         <Button onClick={() => navigate("/journeys")}>
           Browse Journeys
         </Button>
         <Button variant="outline" onClick={() => navigate("/library")}>
           Explore Library
         </Button>
       </div>
     </div>
   )}
   ```

#### Task 5.2: All Completed State
**File:** `src/pages/DailyAdkharPage.tsx`

**Steps:**
1. Add celebration state:
   ```typescript
   const allCompleted = progress.completed === progress.total && progress.total > 0;

   {allCompleted && (
     <div className="bg-primary/10 rounded-lg p-6 text-center mb-6">
       <div className="text-4xl mb-2">🎉</div>
       <h3 className="text-lg font-semibold text-primary">All Done!</h3>
       <p className="text-sm text-muted-foreground mt-1">
         You've completed all {progress.total} adkhar today
       </p>
       <p className="text-sm font-medium text-primary mt-2">
         +{progress.earnedXp} XP earned
       </p>
     </div>
   )}
   ```

#### Task 5.3: Auto-Advance to Next Habit (Optional)
**File:** `src/components/habits/QuickPracticeSheet.tsx`

**Steps:**
1. Add prop for next habit:
   ```typescript
   interface QuickPracticeSheetProps {
     // ... existing
     nextHabit?: HabitWithDua | null;
     onNext?: (habit: HabitWithDua) => void;
   }
   ```

2. Show "Next" button after completion:
   ```typescript
   {isCompleted && nextHabit && (
     <Button
       className="w-full mt-4"
       onClick={() => {
         onNext?.(nextHabit);
       }}
     >
       Next: {nextHabit.dua.title}
       <ChevronRight className="h-4 w-4 ml-2" />
     </Button>
   )}
   ```

#### Task 5.4: Update Navigation References
**Files to check and update:**
- `src/components/habits/HabitPreviewSheet.tsx` - Update "Start Practice" navigation
- `src/pages/JourneyDetailPage.tsx` - Update "Start Journey" navigation
- Any other files with `/practice` navigation

**Steps:**
1. Search for `/practice` references:
   ```bash
   grep -r "\/practice" src/
   ```
2. Update relevant navigation to `/adkhar`
3. Keep `/practice/:duaId` references for deep links

---

## File Checklist

### New Files to Create
- [ ] `src/pages/DailyAdkharPage.tsx`
- [ ] `src/components/habits/QuickPracticeSheet.tsx`
- [ ] `src/components/habits/AddToAdkharSheet.tsx`
- [ ] `src/components/habits/HabitsSummaryCard.tsx`

### Files to Modify
- [ ] `src/App.tsx` - Add route
- [ ] `src/components/BottomNav.tsx` - Rename tab
- [ ] `src/components/DuaCard.tsx` - Add "Add to Adkhar" button
- [ ] `src/pages/LibraryPage.tsx` - Integrate AddToAdkharSheet
- [ ] `src/pages/HomePage.tsx` - Replace TodaysHabits with summary
- [ ] `src/components/habits/HabitPreviewSheet.tsx` - Update navigation (optional: deprecate)

### Files to Keep Unchanged
- [ ] `src/pages/PracticePage.tsx` - Keep for deep links
- [ ] `src/hooks/useUserHabits.ts` - Core logic unchanged
- [ ] `src/types/habit.ts` - Types unchanged
- [ ] `src/components/habits/HabitItem.tsx` - No changes needed
- [ ] `src/components/habits/HabitTimeSlotSection.tsx` - No changes needed

---

## Implementation Order (Recommended)

1. **Phase 1.1** - Create DailyAdkharPage (basic structure)
2. **Phase 1.2** - Update App.tsx routes
3. **Phase 1.3** - Update BottomNav
4. **Phase 2.1** - Create QuickPracticeSheet
5. **Phase 2.3** - Integrate QuickPracticeSheet in DailyAdkharPage
6. **Phase 3.1** - Create AddToAdkharSheet
7. **Phase 3.2** - Update DuaCard
8. **Phase 3.3** - Update LibraryPage
9. **Phase 4.1** - Create HabitsSummaryCard
10. **Phase 4.2** - Update HomePage
11. **Phase 5.1-5.4** - Polish and edge cases

---

## Testing Checklist

- [ ] Bottom nav shows "Adkhar" and navigates to `/adkhar`
- [ ] DailyAdkharPage displays habits grouped by time slot
- [ ] Tapping a habit opens QuickPracticeSheet
- [ ] Tap counter works correctly (count increments, completion triggers)
- [ ] Completion marks habit as done (persists on refresh)
- [ ] XP is awarded on completion
- [ ] Library shows "Add to Adkhar" option
- [ ] Adding from Library creates custom habit in correct time slot
- [ ] HomePage shows summary card linking to Daily Adkhar
- [ ] Empty state displays when no habits configured
- [ ] All completed state shows celebration
- [ ] Deep links to `/practice/:duaId` still work
<!--  -->