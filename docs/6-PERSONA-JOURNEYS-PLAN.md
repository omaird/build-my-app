# 6 Persona Journeys Implementation Plan

## Executive Summary

This plan outlines the creation of 6 persona-aligned spiritual journeys for RIZQ, designed to serve our 3 target user personas with tailored spiritual pathways. Each journey addresses specific needs, pain points, and goals identified in our PRD.

---

## Target Personas Recap

| Persona | Key Needs | Pain Points | Primary Goal |
|---------|-----------|-------------|--------------|
| **Aspiring Consistent Muslim** | Build habits, learn pronunciation, track progress | Utilitarian apps, no progress sense, guilt on lapse | Daily consistency |
| **Returning Muslim** | Gentle intro, no assumptions, encouragement | Fear of judgment, knowledge gaps | Reconnect with faith |
| **Parent** | Beautiful UI, kid-friendly, gamification | Boring apps for kids, no family features | Teach children |

---

## The 6 Persona Journeys

### Journey 1: 🌅 **Morning Warrior** (Existing - Enhance)
**Primary Persona:** Aspiring Consistent Muslim

**Focus:** Start each day with protection and blessings after Fajr

**Time Slot:** Morning (After Fajr)

**Duas Included:**
1. Morning protection dua (Subhanallahi wa bihamdihi)
2. Seeking refuge from harm (A'udhu billahi)
3. Sayyidul Istighfar
4. Morning Tahleel
5. Dua for the day's guidance

**Daily Duration:** 22 minutes | **Daily XP:** 300

**Enhancement:** Add audio pronunciation guides (future), better onboarding tooltip

---

### Journey 2: 🌙 **Evening Peace** (Existing - Enhance)
**Primary Persona:** Aspiring Consistent Muslim

**Focus:** End the day with gratitude and protection through the night

**Time Slot:** Evening (After Maghrib)

**Duas Included:**
1. Ayatul Kursi
2. Evening protection duas
3. Gratitude dua
4. Sleep protection dua
5. Forgiveness dua

**Daily Duration:** 15 minutes | **Daily XP:** 225

**Enhancement:** Add peaceful animations, night mode aesthetic

---

### Journey 3: 🌱 **New Beginnings** (NEW)
**Primary Persona:** Returning Muslim

**Focus:** Gentle reintroduction to daily remembrance for those reconnecting with faith

**Time Slot:** Anytime (Flexible)

**Design Philosophy:**
- No pressure, no guilt messaging
- Start with just 1-2 duas, gradually increase
- Emphasis on meaning over quantity
- Encouraging completion messages

**Duas Included:**
1. Bismillah (Starting with Allah's name) - foundational
2. Alhamdulillah (Praise) - building gratitude
3. Subhanallah (Glory) - recognizing majesty
4. La ilaha illallah (Declaration) - core belief
5. Astaghfirullah (Forgiveness) - gentle mercy

**Daily Duration:** 5 minutes | **Daily XP:** 100

**Special Features:**
- "It's okay to miss a day" messaging
- Streak restoration is always free
- Extra encouraging animations
- Progress milestones celebrate small wins

**Onboarding Message:**
> "Welcome back. Every journey begins with a single step. There's no judgment here—only growth."

---

### Journey 4: 👨‍👩‍👧 **Family Fortress** (NEW)
**Primary Persona:** Parent

**Focus:** Protection and blessings for the entire family

**Time Slot:** Anytime (Flexible - can do together)

**Design Philosophy:**
- Colorful, engaging visuals
- Simple, memorable duas kids can learn
- Family achievement badges
- Fun animations that delight children

**Duas Included:**
1. Dua for entering the home (Bismillahi walajna)
2. Dua for parents (Rabbir hamhuma)
3. Dua for protection of children
4. Dua before eating (Bismillah)
5. Dua after eating (Alhamdulillah)
6. Dua before sleeping (Bismika Allahumma)

**Daily Duration:** 10 minutes | **Daily XP:** 200

**Special Features:**
- Large, kid-friendly tap targets
- Celebratory sounds and haptics
- Family streak (tracks family practice together)
- Achievement badges with fun Islamic themes
- "Teach mode" - simplified view for children

---

### Journey 5: 💰 **Rizq Abundance** (Enhanced from Rizq Seeker)
**Primary Persona:** Aspiring Consistent Muslim

**Focus:** Comprehensive duas for provision, sustenance, and halal income

**Time Slot:** Morning (Set intentions for the day)

**Duas Included:**
1. Dua for opening doors of rizq
2. Dua for barakah in work
3. Istighfar for provision (70x)
4. Dua for debt relief
5. Dua for contentment (Qana'ah)
6. Dua for halal sustenance
7. Dua of Prophet Musa for goodness

**Daily Duration:** 18 minutes | **Daily XP:** 350

**Enhancement:**
- Add context about each dua's source and when Prophet (SAW) used it
- Include hadith about rizq and sustenance
- Morning notification option

---

### Journey 6: 🧘 **Inner Peace** (NEW)
**Primary Persona:** All three personas

**Focus:** Anxiety relief, stress management, and finding tranquility through remembrance

**Time Slot:** Anytime (For moments of stress)

**Design Philosophy:**
- Calming color palette
- Slower animations
- Focus on breathing and mindfulness
- Emphasis on trust in Allah (Tawakkul)

**Duas Included:**
1. Dua for anxiety relief (Allahumma inni a'udhu bika)
2. Dua for patience in hardship
3. Ayatul Kursi (Protection and peace)
4. La hawla wa la quwwata illa billah
5. Hasbunallahu wa ni'mal wakeel
6. Dua for contentment and peace of heart

**Daily Duration:** 12 minutes | **Daily XP:** 250

**Special Features:**
- "Quick Relief" mode - single most powerful dua
- Breathing exercise before practice
- Soft haptic feedback
- Night mode always available
- Save "most helpful" duas to favorites

**Trigger Access:**
- Can be started from a floating "SOS" button in app
- Quick access widget on iOS home screen

---

## Persona-Journey Mapping

| Journey | Primary Persona | Secondary Benefit |
|---------|-----------------|-------------------|
| 🌅 Morning Warrior | Aspiring Consistent | All |
| 🌙 Evening Peace | Aspiring Consistent | All |
| 🌱 New Beginnings | Returning Muslim | Parents (for themselves) |
| 👨‍👩‍👧 Family Fortress | Parent | Aspiring Consistent |
| 💰 Rizq Abundance | Aspiring Consistent | All |
| 🧘 Inner Peace | All | Universal appeal |

---

## Implementation Phases

### Phase 1: Data & Content (Week 1-2)
- [ ] Curate authentic duas for each new journey
- [ ] Write prophetic context for each dua
- [ ] Create journey descriptions and onboarding text
- [ ] Design journey icons and color schemes
- [ ] Update `scripts/seed-firestore.cjs` with new journeys

### Phase 2: Backend & Database (Week 2-3)
- [ ] Add new journeys to Firestore
- [ ] Add new duas to database
- [ ] Create journey_duas mappings
- [ ] Sync to both Neon (web) and Firestore (iOS)
- [ ] Test data consistency

### Phase 3: UI Enhancements (Week 3-4)
- [ ] Implement persona-specific styling for Family Fortress
- [ ] Add "Quick Relief" floating button for Inner Peace
- [ ] Create encouraging messaging system for New Beginnings
- [ ] Design achievement badges
- [ ] Add breathing exercise component

### Phase 4: iOS Features (Week 4-5)
- [ ] Update iOS app with new journeys
- [ ] Add iOS widget support for Inner Peace
- [ ] Implement haptic feedback patterns
- [ ] Test on multiple iOS devices
- [ ] Submit for TestFlight

### Phase 5: Polish & Launch (Week 5-6)
- [ ] A/B test onboarding flows
- [ ] Gather early user feedback
- [ ] Refine copy and UX
- [ ] Full regression testing
- [ ] Production deployment

---

## Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Journey subscription rate | 60% of new users subscribe to 1+ journey | Analytics |
| 7-day retention | 40% of users return after 7 days | Analytics |
| Daily practice completion | 50% of subscribed users complete daily | Database |
| Returning Muslim engagement | 30% of New Beginnings users active after 30 days | Cohort analysis |
| Family journey adoption | 15% of users try Family Fortress | Analytics |
| Inner Peace quick access | 20% of users use SOS button | Analytics |

---

## Technical Requirements

### Database Schema Updates

```sql
-- New journeys
INSERT INTO journeys (name, slug, description, emoji, estimated_minutes, daily_xp, is_premium, is_featured, sort_order)
VALUES
  ('New Beginnings', 'new-beginnings', 'Gentle reintroduction to daily remembrance', '🌱', 5, 100, false, true, 3),
  ('Family Fortress', 'family-fortress', 'Protection and blessings for your family', '👨‍👩‍👧', 10, 200, false, true, 4),
  ('Inner Peace', 'inner-peace', 'Find tranquility through remembrance', '🧘', 12, 250, false, true, 6);
```

### Firestore Collections

```javascript
// New journey documents in 'journeys' collection
{
  id: 6,
  name: "New Beginnings",
  slug: "new-beginnings",
  description: "Gentle reintroduction to daily remembrance",
  emoji: "🌱",
  estimatedMinutes: 5,
  dailyXp: 100,
  isPremium: false,
  isFeatured: true,
  sortOrder: 3,
  personaTarget: "returning" // New field
}
```

### New Dua Fields

```typescript
interface Dua {
  // Existing fields...

  // New fields for persona journeys
  difficultyLevel?: 'beginner' | 'intermediate' | 'advanced';
  breathingPace?: 'slow' | 'normal'; // For Inner Peace
  familyFriendly?: boolean; // For Family Fortress
  encouragementMessage?: string; // For New Beginnings
}
```

---

## Design Specifications

### Journey Card Colors

| Journey | Primary Color | Accent Color |
|---------|--------------|--------------|
| Morning Warrior | #FFB347 (Sunrise Orange) | #FFD700 |
| Evening Peace | #4A5568 (Twilight Gray) | #805AD5 |
| New Beginnings | #68D391 (Fresh Green) | #48BB78 |
| Family Fortress | #4299E1 (Sky Blue) | #63B3ED |
| Rizq Abundance | #D4A574 (Sand/Gold) | #E6C79C |
| Inner Peace | #9F7AEA (Calm Purple) | #B794F4 |

### Animation Styles

- **Morning Warrior:** Energetic, upward motion, sun rays
- **Evening Peace:** Slow fade, stars appearing, moon glow
- **New Beginnings:** Gentle grow/bloom, seed sprouting
- **Family Fortress:** Warm embrace, shield forming
- **Rizq Abundance:** Coins/gems flowing, abundance rain
- **Inner Peace:** Breathing circle, calm waves, soft pulse

---

## Content Guidelines

### Tone by Journey

| Journey | Tone | Example Message |
|---------|------|-----------------|
| Morning Warrior | Energetic, purposeful | "Rise with purpose! Your day begins with dhikr." |
| Evening Peace | Calm, grateful | "As the day ends, let gratitude fill your heart." |
| New Beginnings | Gentle, encouraging | "Every moment is a chance to reconnect. No pressure." |
| Family Fortress | Warm, protective | "Together, your family grows stronger in faith." |
| Rizq Abundance | Hopeful, trusting | "Your sustenance is written. Trust and take action." |
| Inner Peace | Soothing, reassuring | "Breathe. Allah is with you. Let go of worry." |

---

## Next Steps

1. **Review and approve this plan**
2. **Prioritize which journeys to implement first** (recommend: New Beginnings + Inner Peace)
3. **Gather authentic duas** for each new journey
4. **Design mockups** for persona-specific UI elements
5. **Update Firestore seeder** with new content
6. **Begin development** following the phases above

---

*Document Version: 1.0*
*Created: January 2026*
*Author: Claude (assisted by Ralph Wiggum loop)*
