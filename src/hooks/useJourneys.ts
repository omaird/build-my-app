import { useQuery } from "@tanstack/react-query";
import {
  collection,
  doc,
  documentId,
  getDoc,
  getDocs,
  query,
  where,
} from "firebase/firestore";
import { getDb } from "@/lib/firebase";
import type { Journey, JourneyWithDuas, JourneyDua, TimeSlot } from "@/types/habit";

// ---------------------------------------------------------------------------
// Firestore document shapes (per scripts/seed-firestore.cjs)
// ---------------------------------------------------------------------------

interface FsJourneyDoc {
  id?: number;
  name?: string;
  slug?: string;
  description?: string | null;
  emoji?: string | null;
  estimatedMinutes?: number | null;
  dailyXp?: number | null;
  isPremium?: boolean | null;
  isFeatured?: boolean | null;
  sortOrder?: number | null;
}

interface FsJourneyDuaDoc {
  journeyId?: number;
  duaId?: number;
  timeSlot?: string;
  sortOrder?: number;
}

interface FsDuaDoc {
  id?: number;
  titleEn?: string;
  xpValue?: number;
  repetitions?: number;
  categoryId?: number | null;
}

interface FsCategoryDoc {
  id?: number;
  slug?: string;
}

function mapFsJourneyToFrontend(docId: string, data: FsJourneyDoc): Journey {
  const numericId = typeof data.id === "number" ? data.id : Number(docId);
  return {
    id: numericId,
    name: data.name ?? "",
    slug: data.slug ?? "",
    description: data.description ?? null,
    emoji: data.emoji || "📿",
    estimatedMinutes: data.estimatedMinutes ?? 15,
    dailyXp: data.dailyXp ?? 100,
    isPremium: data.isPremium ?? false,
    isFeatured: data.isFeatured ?? false,
  };
}

function sortJourneysFirestore(journeys: Array<Journey & { sortOrder: number }>) {
  // Match Neon: ORDER BY is_featured DESC, sort_order ASC, name ASC
  return journeys.sort((a, b) => {
    if (a.isFeatured !== b.isFeatured) return a.isFeatured ? -1 : 1;
    if (a.sortOrder !== b.sortOrder) return a.sortOrder - b.sortOrder;
    return a.name.localeCompare(b.name);
  });
}

// Build a `categoryId -> slug` map (used to join dua category slugs client-side).
async function fetchCategorySlugMap(): Promise<Map<number, string>> {
  const db = getDb();
  const snap = await getDocs(collection(db, "categories"));
  const map = new Map<number, string>();
  for (const d of snap.docs) {
    const data = d.data() as FsCategoryDoc;
    const numericId = typeof data.id === "number" ? data.id : Number(d.id);
    if (Number.isFinite(numericId) && typeof data.slug === "string") {
      map.set(numericId, data.slug);
    }
  }
  return map;
}

// Fetch every dua referenced by a set of ids and return as a Map keyed by dua id.
// Firestore `in` queries are capped at 30 values, so we chunk if needed.
async function fetchDuasByIds(duaIds: number[]): Promise<Map<number, FsDuaDoc>> {
  const db = getDb();
  const map = new Map<number, FsDuaDoc>();
  if (duaIds.length === 0) return map;

  const unique = Array.from(new Set(duaIds.map(String)));
  const chunkSize = 30;
  const chunks: string[][] = [];
  for (let i = 0; i < unique.length; i += chunkSize) {
    chunks.push(unique.slice(i, i + chunkSize));
  }

  await Promise.all(
    chunks.map(async (chunk) => {
      const snap = await getDocs(
        query(collection(db, "duas"), where(documentId(), "in", chunk))
      );
      for (const d of snap.docs) {
        const data = d.data() as FsDuaDoc;
        const numericId =
          typeof data.id === "number" ? data.id : Number(d.id);
        if (Number.isFinite(numericId)) {
          map.set(numericId, data);
        }
      }
    })
  );

  return map;
}

// Build a JourneyDua from a journey_duas row by resolving the referenced dua + category slug.
function buildJourneyDua(
  row: FsJourneyDuaDoc,
  duaMap: Map<number, FsDuaDoc>,
  categorySlugById: Map<number, string>
): JourneyDua | null {
  const duaId = row.duaId;
  if (typeof duaId !== "number") return null;
  const dua = duaMap.get(duaId);
  if (!dua) return null;

  const categorySlug =
    dua.categoryId != null ? categorySlugById.get(dua.categoryId) ?? null : null;

  return {
    duaId,
    timeSlot: (row.timeSlot as TimeSlot) ?? "anytime",
    sortOrder: row.sortOrder ?? 0,
    title: dua.titleEn ?? "",
    xpValue: dua.xpValue ?? 0,
    repetitions: dua.repetitions ?? 1,
    category: categorySlug || "morning",
  };
}

// ---------------------------------------------------------------------------
// Firestore fetchers
// ---------------------------------------------------------------------------

async function fetchAllJourneysFirestore(): Promise<Journey[]> {
  const db = getDb();
  const snap = await getDocs(collection(db, "journeys"));
  const withSort = snap.docs.map((d) => {
    const data = d.data() as FsJourneyDoc;
    return {
      ...mapFsJourneyToFrontend(d.id, data),
      sortOrder: data.sortOrder ?? 0,
    };
  });
  return sortJourneysFirestore(withSort).map(({ sortOrder: _sortOrder, ...j }) => j);
}

async function fetchFeaturedJourneysFirestore(): Promise<Journey[]> {
  const db = getDb();
  const snap = await getDocs(
    query(collection(db, "journeys"), where("isFeatured", "==", true))
  );
  const withSort = snap.docs.map((d) => {
    const data = d.data() as FsJourneyDoc;
    return {
      ...mapFsJourneyToFrontend(d.id, data),
      sortOrder: data.sortOrder ?? 0,
    };
  });
  // Match Neon: ORDER BY sort_order ASC
  withSort.sort((a, b) => a.sortOrder - b.sortOrder);
  return withSort.map(({ sortOrder: _sortOrder, ...j }) => j);
}

async function fetchJourneyDuasForJourneyFirestore(
  journeyId: number,
  duaMap?: Map<number, FsDuaDoc>,
  categorySlugById?: Map<number, string>
): Promise<JourneyDua[]> {
  const db = getDb();
  const linksSnap = await getDocs(
    query(collection(db, "journey_duas"), where("journeyId", "==", journeyId))
  );
  const links = linksSnap.docs
    .map((d) => d.data() as FsJourneyDuaDoc)
    .sort((a, b) => (a.sortOrder ?? 0) - (b.sortOrder ?? 0));

  const duaIds = links
    .map((l) => l.duaId)
    .filter((id): id is number => typeof id === "number");

  const [duasResolved, slugsResolved] = await Promise.all([
    duaMap ?? fetchDuasByIds(duaIds),
    categorySlugById ?? fetchCategorySlugMap(),
  ]);

  return links
    .map((row) => buildJourneyDua(row, duasResolved, slugsResolved))
    .filter((d): d is JourneyDua => d !== null);
}

async function fetchJourneyWithDuasFirestore(
  journeyId: number | null
): Promise<JourneyWithDuas | null> {
  if (!journeyId) return null;
  const db = getDb();

  // Doc ids in `journeys/` match the numeric primary key (see seed-firestore.cjs),
  // so we can read by doc id directly instead of issuing a `where` query.
  const snap = await getDoc(doc(db, "journeys", String(journeyId)));
  if (!snap.exists()) return null;

  const journey = mapFsJourneyToFrontend(snap.id, snap.data() as FsJourneyDoc);
  const duas = await fetchJourneyDuasForJourneyFirestore(journeyId);
  return { ...journey, duas };
}

async function fetchJourneyBySlugWithDuasFirestore(
  slug: string | null
): Promise<JourneyWithDuas | null> {
  if (!slug) return null;
  const db = getDb();

  const snap = await getDocs(
    query(collection(db, "journeys"), where("slug", "==", slug))
  );
  if (snap.empty) return null;

  const d = snap.docs[0];
  const data = d.data() as FsJourneyDoc;
  const journey = mapFsJourneyToFrontend(d.id, data);
  const duas = await fetchJourneyDuasForJourneyFirestore(journey.id);
  return { ...journey, duas };
}

async function fetchJourneysWithDuasFirestore(
  journeyIds: number[]
): Promise<JourneyWithDuas[]> {
  if (!journeyIds.length) return [];
  const db = getDb();

  // 1. Fetch matching journeys (`in` query, chunked to 30).
  // Use `documentId()` since doc ids in `journeys/` match the numeric PK
  // (see seed-firestore.cjs) — cheaper and avoids needing an index on `id`.
  const uniqueIds = Array.from(new Set(journeyIds));
  const chunkSize = 30;
  const chunks: number[][] = [];
  for (let i = 0; i < uniqueIds.length; i += chunkSize) {
    chunks.push(uniqueIds.slice(i, i + chunkSize));
  }

  const journeyDocs: Array<Journey & { sortOrder: number }> = [];
  await Promise.all(
    chunks.map(async (chunk) => {
      const snap = await getDocs(
        query(
          collection(db, "journeys"),
          where(
            documentId(),
            "in",
            chunk.map((id) => String(id))
          )
        )
      );
      for (const d of snap.docs) {
        const data = d.data() as FsJourneyDoc;
        journeyDocs.push({
          ...mapFsJourneyToFrontend(d.id, data),
          sortOrder: data.sortOrder ?? 0,
        });
      }
    })
  );

  if (!journeyDocs.length) return [];

  // 2. Fetch all journey_duas for those journeys (chunked `in`).
  // `journey_duas` docs have their own composite ids, so we must filter on the
  // `journeyId` field (not docId).
  const allLinks: FsJourneyDuaDoc[] = [];
  await Promise.all(
    chunks.map(async (chunk) => {
      const snap = await getDocs(
        query(collection(db, "journey_duas"), where("journeyId", "in", chunk))
      );
      for (const d of snap.docs) {
        allLinks.push(d.data() as FsJourneyDuaDoc);
      }
    })
  );

  // 3. Fetch every referenced dua in one batched call + category slug map.
  const duaIds = allLinks
    .map((l) => l.duaId)
    .filter((id): id is number => typeof id === "number");
  const [duaMap, categorySlugById] = await Promise.all([
    fetchDuasByIds(duaIds),
    fetchCategorySlugMap(),
  ]);

  // 4. Group links by journeyId, sorted by sortOrder.
  const linksByJourney = new Map<number, FsJourneyDuaDoc[]>();
  for (const link of allLinks) {
    if (typeof link.journeyId !== "number") continue;
    const arr = linksByJourney.get(link.journeyId) || [];
    arr.push(link);
    linksByJourney.set(link.journeyId, arr);
  }

  // 5. Match Neon: ORDER BY sort_order ASC, name ASC
  journeyDocs.sort((a, b) => {
    if (a.sortOrder !== b.sortOrder) return a.sortOrder - b.sortOrder;
    return a.name.localeCompare(b.name);
  });

  return journeyDocs.map(({ sortOrder: _sortOrder, ...journey }) => {
    const links = (linksByJourney.get(journey.id) || []).sort(
      (a, b) => (a.sortOrder ?? 0) - (b.sortOrder ?? 0)
    );
    const duas = links
      .map((row) => buildJourneyDua(row, duaMap, categorySlugById))
      .filter((d): d is JourneyDua => d !== null);
    return { ...journey, duas };
  });
}

// ---------------------------------------------------------------------------
// Public hooks
// ---------------------------------------------------------------------------

// Fetch all journeys (for journey selection screen)
export function useJourneys() {
  return useQuery({
    queryKey: ["journeys"],
    queryFn: (): Promise<Journey[]> => fetchAllJourneysFirestore(),
  });
}

// Fetch featured journeys only
export function useFeaturedJourneys() {
  return useQuery({
    queryKey: ["journeys", "featured"],
    queryFn: (): Promise<Journey[]> => fetchFeaturedJourneysFirestore(),
  });
}

// Fetch single journey by ID with its duas
export function useJourneyWithDuas(journeyId: number | null) {
  return useQuery({
    queryKey: ["journeys", journeyId, "duas"],
    queryFn: (): Promise<JourneyWithDuas | null> =>
      fetchJourneyWithDuasFirestore(journeyId),
    enabled: journeyId !== null,
  });
}

// Fetch single journey by slug with its duas
export function useJourneyBySlugWithDuas(slug: string | null) {
  return useQuery({
    queryKey: ["journeys", "slug", slug, "duas"],
    queryFn: (): Promise<JourneyWithDuas | null> =>
      fetchJourneyBySlugWithDuasFirestore(slug),
    enabled: slug !== null,
  });
}

// Fetch multiple journeys by ID array with their duas (for multi-journey support)
export function useJourneysWithDuas(journeyIds: number[]) {
  // Sort and create stable query key
  const sortedIds = [...journeyIds].sort((a, b) => a - b);
  const queryKey = ["journeys", "multiple", sortedIds];

  return useQuery({
    queryKey,
    queryFn: (): Promise<JourneyWithDuas[]> =>
      fetchJourneysWithDuasFirestore(journeyIds),
    enabled: journeyIds.length > 0,
  });
}

// Get merged duas from multiple journeys (deduplicated by duaId)
export function useMergedJourneyDuas(journeyIds: number[]) {
  const { data: journeys, ...rest } = useJourneysWithDuas(journeyIds);

  const mergedDuas = journeys
    ? (() => {
        const duaMap = new Map<number, JourneyDua>();
        // Process in order - first journey's dua takes precedence
        for (const journey of journeys) {
          for (const dua of journey.duas) {
            if (!duaMap.has(dua.duaId)) {
              duaMap.set(dua.duaId, dua);
            }
          }
        }
        // Return sorted by time slot and sort order
        return Array.from(duaMap.values()).sort((a, b) => {
          const slotOrder = { morning: 0, anytime: 1, evening: 2 };
          const slotDiff = slotOrder[a.timeSlot] - slotOrder[b.timeSlot];
          if (slotDiff !== 0) return slotDiff;
          return a.sortOrder - b.sortOrder;
        });
      })()
    : [];

  return {
    data: mergedDuas,
    journeys,
    ...rest,
  };
}
