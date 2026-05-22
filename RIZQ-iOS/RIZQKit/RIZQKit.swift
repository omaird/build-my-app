// RIZQKit - Shared framework for RIZQ iOS App
// Contains models, services, and design system

import Foundation
import SwiftUI

// MARK: - Framework Exports

/// RIZQKit version
public let rizqKitVersion = "1.0.0"

// MARK: - Public API Summary
//
// Models:
// - Dua, DuaCategory, DuaCollection, DuaDifficulty
// - Journey, JourneyDua, JourneyWithDuas
// - UserProfile, UserActivity, UserProgress
// - UserHabit, HabitCompletion, CustomHabit
// - TimeSlot, CategorySlug
//
// Auth Models:
// - AuthUser, AuthSession, AuthState
// - AuthProvider, AuthError, AuthResponse
// - LinkedAccount, SignUpRequest, SignInRequest
//
// Services:
// - FirebaseAuthService (Firebase Authentication: email/password + OAuth)
// - FirestoreContentService (content reads: duas, journeys, categories)
// - FirebaseUserService (user data: profiles, activity, progress)
// - FirebaseAdminService (admin CRUD operations)
// - KeychainService (secure token storage)
// - ServiceContainer (dependency injection)
//
// Design System:
// - Colors (rizqPrimary, rizqBackground, etc.)
// - Typography (rizqDisplayFont, rizqSansFont, etc.)
// - Spacing (rizqSpacing, rizqCornerRadius, etc.)
