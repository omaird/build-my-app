import { useQuery } from '@tanstack/react-query';
import { collection, doc, getDoc, getDocs, orderBy, query, where } from 'firebase/firestore';
import { getSql, type DuaWithRelations, type Category, type Collection } from '@/lib/db';
import { getDb, isFirestoreCutoverEnabled } from '@/lib/firebase';
import type { Dua, DuaCategory, DuaContext, DuaDifficulty } from '@/types/dua';

// ---------------------------------------------------------------------------
// Shared mapper (Neon path)
// ---------------------------------------------------------------------------

// Map database record to frontend Dua format
function mapDbDuaToFrontend(dbDua: DuaWithRelations): Dua {
  // Build context object from DB fields
  const context: DuaContext = {
    source: dbDua.source || null,
    bestTime: dbDua.best_time || null,
    benefits: dbDua.rizq_benefit || null,
    story: dbDua.context || null,
    propheticContext: dbDua.prophetic_context || null,
    difficulty: (dbDua.difficulty as DuaDifficulty) || null,
    estimatedDuration: dbDua.est_duration_sec || null,
  };

  return {
    id: String(dbDua.id),
    title: dbDua.title_en,
    arabic: dbDua.arabic_text,
    transliteration: dbDua.transliteration || '',
    translation: dbDua.translation_en || '',
    category: (dbDua.category_slug || 'morning') as DuaCategory,
    xpValue: dbDua.xp_value,
    repetitions: dbDua.repetitions,
    context,
  };
}

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

async function fetchDuaFirestore(id: number): Promise<DuaWithRelations | null> {
  const db = getDb();
  const snap = await getDoc(doc(db, 'duas', String(id)));
  if (!snap.exists()) return null;

  const data = snap.data() as FsDuaDoc;
  const categorySlugById = await fetchCategorySlugMap();
  const numericId = typeof data.id === 'number' ? data.id : Number(snap.id);
  const categorySlug =
    data.categoryId != null ? categorySlugById.get(data.categoryId) ?? undefined : undefined;

  // Project Firestore shape into the legacy `DuaWithRelations` (snake_case)
  // contract so existing consumers of `useDua` keep working unchanged.
  const result: DuaWithRelations = {
    id: numericId,
    category_id: data.categoryId ?? null,
    collection_id: data.collectionId ?? null,
    title_en: data.titleEn ?? '',
    title_ar: data.titleAr ?? null,
    arabic_text: data.arabicText ?? '',
    transliteration: data.transliteration ?? null,
    translation_en: data.translationEn ?? null,
    source: data.source ?? null,
    repetitions: data.repetitions ?? 1,
    best_time: data.bestTime ?? null,
    difficulty: (data.difficulty as DuaWithRelations['difficulty']) ?? null,
    est_duration_sec: data.estDurationSec ?? null,
    rizq_benefit: data.rizqBenefit ?? null,
    context: data.context ?? null,
    prophetic_context: data.propheticContext ?? null,
    xp_value: data.xpValue ?? 0,
    audio_url: null,
    created_at: '',
    updated_at: '',
    category_slug: categorySlug,
  };
  return result;
}

async function fetchDuasByCategoryFirestore(
  categorySlug: string
): Promise<DuaWithRelations[]> {
  const db = getDb();

  // Look up the numeric category id by slug.
  const catSnap = await getDocs(
    query(collection(db, 'categories'), where('slug', '==', categorySlug))
  );
  if (catSnap.empty) return [];
  const catDoc = catSnap.docs[0];
  const catData = catDoc.data() as FsCategoryDoc;
  const categoryId =
    typeof catData.id === 'number' ? catData.id : Number(catDoc.id);
  if (!Number.isFinite(categoryId)) return [];

  const duasSnap = await getDocs(
    query(
      collection(db, 'duas'),
      where('categoryId', '==', categoryId),
      orderBy('id')
    )
  );

  return duasSnap.docs.map((d) => {
    const data = d.data() as FsDuaDoc;
    const numericId = typeof data.id === 'number' ? data.id : Number(d.id);
    return {
      id: numericId,
      category_id: data.categoryId ?? null,
      collection_id: data.collectionId ?? null,
      title_en: data.titleEn ?? '',
      title_ar: data.titleAr ?? null,
      arabic_text: data.arabicText ?? '',
      transliteration: data.transliteration ?? null,
      translation_en: data.translationEn ?? null,
      source: data.source ?? null,
      repetitions: data.repetitions ?? 1,
      best_time: data.bestTime ?? null,
      difficulty: (data.difficulty as DuaWithRelations['difficulty']) ?? null,
      est_duration_sec: data.estDurationSec ?? null,
      rizq_benefit: data.rizqBenefit ?? null,
      context: data.context ?? null,
      prophetic_context: data.propheticContext ?? null,
      xp_value: data.xpValue ?? 0,
      audio_url: null,
      created_at: '',
      updated_at: '',
      category_slug: catData.slug ?? undefined,
      category_name: catData.name ?? undefined,
    } satisfies DuaWithRelations;
  });
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
// Neon fetchers (preserve byte-for-byte the previous implementation)
// ---------------------------------------------------------------------------

async function fetchDuasNeon(): Promise<Dua[]> {
  const sql = getSql();
  const result = await sql`
    SELECT
      d.*,
      c.name as category_name,
      c.slug as category_slug,
      col.name as collection_name,
      col.slug as collection_slug
    FROM duas d
    LEFT JOIN categories c ON d.category_id = c.id
    LEFT JOIN collections col ON d.collection_id = col.id
    ORDER BY d.id
  `;
  return (result as DuaWithRelations[]).map(mapDbDuaToFrontend);
}

async function fetchDuaNeon(id: number): Promise<DuaWithRelations | null> {
  const sql = getSql();
  const result = await sql`
    SELECT
      d.*,
      c.name as category_name,
      c.slug as category_slug,
      col.name as collection_name,
      col.slug as collection_slug
    FROM duas d
    LEFT JOIN categories c ON d.category_id = c.id
    LEFT JOIN collections col ON d.collection_id = col.id
    WHERE d.id = ${id}
  `;
  return (result[0] as DuaWithRelations) || null;
}

async function fetchDuasByCategoryNeon(
  categorySlug: string
): Promise<DuaWithRelations[]> {
  const sql = getSql();
  const result = await sql`
    SELECT
      d.*,
      c.name as category_name,
      c.slug as category_slug,
      col.name as collection_name,
      col.slug as collection_slug
    FROM duas d
    LEFT JOIN categories c ON d.category_id = c.id
    LEFT JOIN collections col ON d.collection_id = col.id
    WHERE c.slug = ${categorySlug}
    ORDER BY d.id
  `;
  return result as DuaWithRelations[];
}

async function fetchCategoriesNeon(): Promise<Category[]> {
  const sql = getSql();
  const result = await sql`
    SELECT * FROM categories ORDER BY name
  `;
  return result as Category[];
}

async function fetchCollectionsNeon(): Promise<Collection[]> {
  const sql = getSql();
  const result = await sql`
    SELECT * FROM collections ORDER BY name
  `;
  return result as Collection[];
}

// ---------------------------------------------------------------------------
// Public hooks (dual-path, keyed on isFirestoreCutoverEnabled())
// ---------------------------------------------------------------------------

// Fetch all duas with their category and collection info
export function useDuas() {
  const useFirestore = isFirestoreCutoverEnabled();
  return useQuery({
    queryKey: ['duas', useFirestore],
    queryFn: (): Promise<Dua[]> =>
      useFirestore ? fetchDuasFirestore() : fetchDuasNeon(),
  });
}

// Fetch a single dua by ID
export function useDua(id: number) {
  const useFirestore = isFirestoreCutoverEnabled();
  return useQuery({
    queryKey: ['duas', id, useFirestore],
    queryFn: (): Promise<DuaWithRelations | null> =>
      useFirestore ? fetchDuaFirestore(id) : fetchDuaNeon(id),
    enabled: !!id,
  });
}

// Fetch duas by category slug
export function useDuasByCategory(categorySlug: string) {
  const useFirestore = isFirestoreCutoverEnabled();
  return useQuery({
    queryKey: ['duas', 'category', categorySlug, useFirestore],
    queryFn: (): Promise<DuaWithRelations[]> =>
      useFirestore
        ? fetchDuasByCategoryFirestore(categorySlug)
        : fetchDuasByCategoryNeon(categorySlug),
    enabled: !!categorySlug,
  });
}

// Fetch all categories
export function useCategories() {
  const useFirestore = isFirestoreCutoverEnabled();
  return useQuery({
    queryKey: ['categories', useFirestore],
    queryFn: (): Promise<Category[]> =>
      useFirestore ? fetchCategoriesFirestore() : fetchCategoriesNeon(),
  });
}

// Fetch all collections
export function useCollections() {
  const useFirestore = isFirestoreCutoverEnabled();
  return useQuery({
    queryKey: ['collections', useFirestore],
    queryFn: (): Promise<Collection[]> =>
      useFirestore ? fetchCollectionsFirestore() : fetchCollectionsNeon(),
  });
}
