// Admin hooks barrel file

// Duas
export {
  useAdminDuas,
  useAdminDua,
  useCreateDua,
  useUpdateDua,
  useDeleteDua,
} from './useAdminDuas';

// Journeys
export {
  useAdminJourneys,
  useAdminJourney,
  useAdminJourneyDuas,
  useCreateJourney,
  useUpdateJourney,
  useDeleteJourney,
  useAssignDuaToJourney,
  useRemoveDuaFromJourney,
  useReorderJourneyDuas,
  useToggleJourneyFeatured,
  useToggleJourneyPremium,
} from './useAdminJourneys';
export type { AdminJourneyDua } from './useAdminJourneys';

// Categories
export {
  useAdminCategories,
  useAdminCategory,
  useCreateCategory,
  useUpdateCategory,
  useDeleteCategory,
} from './useAdminCategories';

// Collections
export {
  useAdminCollections,
  useAdminCollection,
  useCreateCollection,
  useUpdateCollection,
  useDeleteCollection,
  useToggleCollectionPremium,
} from './useAdminCollections';

// Users
export {
  useAdminUsers,
  useAdminUser,
  useAdminUserActivity,
  useToggleAdmin,
  useAdminStats,
} from './useAdminUsers';
export type { UserActivitySummary, AdminStats } from './useAdminUsers';
