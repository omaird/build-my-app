import { useQuery } from '@tanstack/react-query';
import { collection, getDocs, orderBy, query } from 'firebase/firestore';
import { getDb } from '@/lib/firebase';
import type { DuaWithRelations, Category, Collection } from '@/types/db-rows';
import type { Dua, DuaCategory, DuaContext, DuaDifficulty } from '@/types/dua';

// ---------------------------------------------------------------------------
// Firestore mappers
// ---------------------------------------------------------------------------

// Firestore document shape for a dua (per scripts/seed-firestore.cjs)
interface FsDuaDoc {
  id?: number;
  categoryId?: number | null;
  collectionId?: number | null;
  titleEn?: string;
  titleAr?: string | null;
  arabicText?: string;
  transliteration?: string | null;
  translationEn?: string | null;
  source?: string | null;
  repetitions?: number;
  bestTime?: string | null;
  difficulty?: string | null;
  estDurationSec?: number | null;
  rizqBenefit?: string | null;
  context?: string | null;
  propheticContext?: string | null;
  xpValue?: number;
}

interface FsCategoryDoc {
  id?: number;
  name?: string;
  slug?: string;
  description?: string | null;
  emoji?: string | null;
}

interface FsCollectionDoc {
  id?: number;
  name?: string;
  slug?: string;
  description?: string | null;
  isPremium?: boolean;
}

// Map a Firestore dua doc + resolved category slug into a frontend Dua.
function mapFsDuaToFrontend(
  docId: string,
  data: FsDuaDoc,
  categorySlugById: Map<number, string>
): Dua {
  const numericId = typeof data.id === 'number' ? data.id : Number(docId);
  const categorySlug =
    data.categoryId != null ? categorySlugById.get(data.categoryId) ?? null : null;

  const context: DuaContext = {
    source: data.source ?? null,
    bestTime: data.bestTime ?? null,
    benefits: data.rizqBenefit ?? null,
    story: data.context ?? null,
    propheticContext: data.propheticContext ?? null,
    difficulty: (data.difficulty as DuaDifficulty) || null,
    estimatedDuration: data.estDurationSec ?? null,
  };

  return {
    id: String(numericId),
    title: data.titleEn ?? '',
    arabic: data.arabicText ?? '',
    transliteration: data.transliteration ?? '',
    translation: data.translationEn ?? '',
    category: (categorySlug || 'morning') as DuaCategory,
    xpValue: data.xpValue ?? 0,
    repetitions: data.repetitions ?? 1,
    context,
  };
}

// Build a `categoryId -> slug` map from a fresh Firestore fetch.
async function fetchCategorySlugMap(): Promise<Map<number, string>> {
  const db = getDb();
  const snap = await getDocs(collection(db, 'categories'));
  const map = new Map<number, string>();
  for (const d of snap.docs) {
    const data = d.data() as FsCategoryDoc;
    const numericId = typeof data.id === 'number' ? data.id : Number(d.id);
    if (Number.isFinite(numericId) && typeof data.slug === 'string') {
      map.set(numericId, data.slug);
    }
  }
  return map;
}

// ---------------------------------------------------------------------------
// Firestore fetchers
// ---------------------------------------------------------------------------

async function fetchDuasFirestore(): Promise<Dua[]> {
  const db = getDb();
  const [categorySlugById, duasSnap] = await Promise.all([
    fetchCategorySlugMap(),
    getDocs(query(collection(db, 'duas'), orderBy('id'))),
  ]);

  return duasSnap.docs.map((d) =>
    mapFsDuaToFrontend(d.id, d.data() as FsDuaDoc, categorySlugById)
  );
}

async function fetchCategoriesFirestore(): Promise<Category[]> {
  const db = getDb();
  const snap = await getDocs(collection(db, 'categories'));
  const categories: Category[] = snap.docs.map((d) => {
    const data = d.data() as FsCategoryDoc;
    const numericId = typeof data.id === 'number' ? data.id : Number(d.id);
    return {
      id: numericId,
      name: data.name ?? '',
      slug: data.slug ?? '',
      description: data.description ?? null,
    };
  });
  // Match Neon ORDER BY name ASC
  categories.sort((a, b) => a.name.localeCompare(b.name));
  return categories;
}

async function fetchCollectionsFirestore(): Promise<Collection[]> {
  const db = getDb();
  const snap = await getDocs(collection(db, 'collections'));
  const collections: Collection[] = snap.docs.map((d) => {
    const data = d.data() as FsCollectionDoc;
    const numericId = typeof data.id === 'number' ? data.id : Number(d.id);
    return {
      id: numericId,
      name: data.name ?? '',
      slug: data.slug ?? '',
      description: data.description ?? null,
      is_premium: data.isPremium ?? false,
    };
  });
  // Match Neon ORDER BY name ASC
  collections.sort((a, b) => a.name.localeCompare(b.name));
  return collections;
}

// ---------------------------------------------------------------------------
// Public hooks (Firestore-only post-decommission)
// ---------------------------------------------------------------------------

export function useDuas() {
  return useQuery({
    queryKey: ['duas'],
    queryFn: fetchDuasFirestore,
  });
}

export function useCategories() {
  return useQuery({
    queryKey: ['categories'],
    queryFn: fetchCategoriesFirestore,
  });
}

export function useCollections() {
  return useQuery({
    queryKey: ['collections'],
    queryFn: fetchCollectionsFirestore,
  });
}
