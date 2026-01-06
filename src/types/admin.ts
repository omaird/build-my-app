// Admin-specific type definitions for CRUD operations

import type { TimeSlot } from './habit';

// =============================================================================
// DUA TYPES
// =============================================================================

// Database row type (snake_case from DB)
export interface AdminDuaRow {
  id: number;
  category_id: number | null;
  collection_id: number | null;
  title_en: string;
  title_ar: string | null;
  arabic_text: string;
  transliteration: string | null;
  translation_en: string | null;
  source: string | null;
  repetitions: number;
  best_time: string | null;
  difficulty: 'Beginner' | 'Intermediate' | 'Advanced' | null;
  est_duration_sec: number | null;
  rizq_benefit: string | null;
  context: string | null;
  prophetic_context: string | null;
  xp_value: number;
  audio_url: string | null;
  created_at: string;
  updated_at: string;
  // Joined fields
  category_name?: string;
  category_slug?: string;
  collection_name?: string;
  collection_slug?: string;
  is_premium?: boolean;
}

// Frontend dua type for admin (camelCase)
export interface AdminDua {
  id: number;
  categoryId: number | null;
  collectionId: number | null;
  titleEn: string;
  titleAr: string | null;
  arabicText: string;
  transliteration: string | null;
  translationEn: string | null;
  source: string | null;
  repetitions: number;
  bestTime: string | null;
  difficulty: 'Beginner' | 'Intermediate' | 'Advanced' | null;
  estDurationSec: number | null;
  rizqBenefit: string | null;
  context: string | null;
  propheticContext: string | null;
  xpValue: number;
  audioUrl: string | null;
  createdAt: string;
  updatedAt: string;
  // Joined fields
  categoryName?: string;
  categorySlug?: string;
  collectionName?: string;
  collectionSlug?: string;
  isPremium?: boolean;
}

// Form input for creating/updating duas
export interface DuaFormInput {
  titleEn: string;
  titleAr?: string;
  arabicText: string;
  transliteration?: string;
  translationEn?: string;
  categoryId: number | null;
  collectionId: number | null;
  source?: string;
  repetitions: number;
  bestTime?: string;
  difficulty: 'Beginner' | 'Intermediate' | 'Advanced' | null;
  estDurationSec?: number;
  rizqBenefit?: string;
  context?: string;
  propheticContext?: string;
  xpValue: number;
  audioUrl?: string;
}

// =============================================================================
// JOURNEY TYPES
// =============================================================================

// Database row type (snake_case from DB)
export interface AdminJourneyRow {
  id: number;
  name: string;
  slug: string;
  description: string | null;
  emoji: string | null;
  estimated_minutes: number | null;
  daily_xp: number | null;
  is_premium: boolean;
  is_featured: boolean;
  sort_order: number | null;
  created_at?: string;
  updated_at?: string;
  // Computed fields
  dua_count?: number;
}

// Frontend journey type for admin (camelCase)
export interface AdminJourney {
  id: number;
  name: string;
  slug: string;
  description: string | null;
  emoji: string;
  estimatedMinutes: number;
  dailyXp: number;
  isPremium: boolean;
  isFeatured: boolean;
  sortOrder: number;
  createdAt?: string;
  updatedAt?: string;
  duaCount?: number;
}

// Form input for creating/updating journeys
export interface JourneyFormInput {
  name: string;
  slug: string;
  description?: string;
  emoji?: string;
  estimatedMinutes: number;
  dailyXp: number;
  isPremium: boolean;
  isFeatured: boolean;
  sortOrder: number;
}

// Journey dua assignment for drag-and-drop
export interface JourneyDuaAssignment {
  journeyId: number;
  duaId: number;
  timeSlot: TimeSlot;
  sortOrder: number;
}

// =============================================================================
// CATEGORY TYPES
// =============================================================================

// Database row type
export interface AdminCategoryRow {
  id: number;
  name: string;
  slug: string;
  description: string | null;
  dua_count?: number;
}

// Frontend category type
export interface AdminCategory {
  id: number;
  name: string;
  slug: string;
  description: string | null;
  duaCount?: number;
}

// Form input
export interface CategoryFormInput {
  name: string;
  slug: string;
  description?: string;
}

// =============================================================================
// COLLECTION TYPES
// =============================================================================

// Database row type
export interface AdminCollectionRow {
  id: number;
  name: string;
  slug: string;
  description: string | null;
  is_premium: boolean;
  dua_count?: number;
}

// Frontend collection type
export interface AdminCollection {
  id: number;
  name: string;
  slug: string;
  description: string | null;
  isPremium: boolean;
  duaCount?: number;
}

// Form input
export interface CollectionFormInput {
  name: string;
  slug: string;
  description?: string;
  isPremium: boolean;
}

// =============================================================================
// USER TYPES
// =============================================================================

// Database row type (combining auth and profile tables)
export interface AdminUserRow {
  user_id: string;
  email: string;
  name: string | null;
  image: string | null;
  display_name: string | null;
  streak: number;
  total_xp: number;
  level: number;
  last_active_date: string | null;
  is_admin: boolean;
  created_at: string;
}

// Frontend user type for admin
export interface AdminUser {
  userId: string;
  email: string;
  name: string | null;
  image: string | null;
  displayName: string | null;
  streak: number;
  totalXp: number;
  level: number;
  lastActiveDate: string | null;
  isAdmin: boolean;
  createdAt: string;
}

// =============================================================================
// STATS TYPES
// =============================================================================

export interface AdminStats {
  totalDuas: number;
  totalJourneys: number;
  totalCategories: number;
  totalCollections: number;
  totalUsers: number;
  activeUsersToday: number;
}
