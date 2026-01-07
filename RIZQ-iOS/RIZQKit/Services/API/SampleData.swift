import Foundation

// MARK: - Sample Data for Previews and Testing

public enum SampleData {
  // MARK: - Categories

  public static let categories: [DuaCategory] = [
    DuaCategory(id: 1, name: "Morning", slug: .morning, description: "Adhkar for the morning"),
    DuaCategory(id: 2, name: "Evening", slug: .evening, description: "Adhkar for the evening"),
    DuaCategory(id: 3, name: "Rizq", slug: .rizq, description: "Duas for sustenance and provision"),
    DuaCategory(id: 4, name: "Gratitude", slug: .gratitude, description: "Duas of thankfulness"),
  ]

  // MARK: - Collections

  public static let collections: [DuaCollection] = [
    DuaCollection(id: 1, name: "Essential Adhkar", slug: "essential", description: "Core daily remembrances"),
    DuaCollection(id: 2, name: "Fortress of the Muslim", slug: "fortress", description: "From Hisnul Muslim"),
  ]

  // MARK: - Duas

  public static let duas: [Dua] = [
    Dua(
      id: 1,
      categoryId: 1,
      collectionId: 1,
      titleEn: "Morning Dhikr",
      titleAr: "أذكار الصباح",
      arabicText: "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ",
      transliteration: "Asbahna wa asbahal mulku lillah",
      translationEn: "We have entered upon morning and the whole kingdom belongs to Allah",
      source: "Sahih Muslim",
      repetitions: 1,
      bestTime: .morning,
      difficulty: .beginner,
      estDurationSec: 10,
      rizqBenefit: "Start your day with gratitude",
      context: "Morning remembrance",
      propheticContext: "The Prophet (ﷺ) would say this every morning",
      xpValue: 10
    ),
    Dua(
      id: 2,
      categoryId: 1,
      collectionId: 1,
      titleEn: "Seeking Protection",
      titleAr: "الاستعاذة",
      arabicText: "أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ",
      transliteration: "A'udhu bikalimatillahit-tammati min sharri ma khalaq",
      translationEn: "I seek refuge in the perfect words of Allah from the evil of what He has created",
      source: "Sahih Muslim",
      repetitions: 3,
      bestTime: .morning,
      difficulty: .beginner,
      estDurationSec: 15,
      rizqBenefit: "Protection throughout the day",
      context: "Protection dua",
      propheticContext: "Recited by the Prophet (ﷺ) for protection",
      xpValue: 15
    ),
    Dua(
      id: 3,
      categoryId: 3,
      collectionId: 1,
      titleEn: "Seeking Rizq",
      titleAr: "دعاء الرزق",
      arabicText: "اللَّهُمَّ اكْفِنِي بِحَلَالِكَ عَنْ حَرَامِكَ وَأَغْنِنِي بِفَضْلِكَ عَمَّنْ سِوَاكَ",
      transliteration: "Allahumma akfini bihalalika 'an haramika wa aghnini bifadlika 'amman siwak",
      translationEn: "O Allah, suffice me with what is lawful against what is unlawful, and make me independent of all besides You",
      source: "Tirmidhi",
      repetitions: 3,
      bestTime: .anytime,
      difficulty: .intermediate,
      estDurationSec: 20,
      rizqBenefit: "Seeking halal sustenance",
      context: "Dua for provision",
      propheticContext: "The Prophet (ﷺ) taught this dua for seeking lawful provision",
      xpValue: 20
    ),
    Dua(
      id: 4,
      categoryId: 4,
      collectionId: 1,
      titleEn: "Gratitude",
      titleAr: "الحمد",
      arabicText: "الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ",
      transliteration: "Alhamdu lillahil-ladhi ahyana ba'da ma amatana wa ilayhin-nushur",
      translationEn: "All praise is for Allah who gave us life after having taken it from us, and unto Him is the resurrection",
      source: "Bukhari",
      repetitions: 1,
      bestTime: .morning,
      difficulty: .beginner,
      estDurationSec: 10,
      rizqBenefit: "Expressing gratitude for life",
      context: "Upon waking",
      propheticContext: "Said by the Prophet (ﷺ) upon waking",
      xpValue: 10
    ),
    Dua(
      id: 5,
      categoryId: 2,
      collectionId: 1,
      titleEn: "Evening Protection",
      titleAr: "أذكار المساء",
      arabicText: "أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ وَالْحَمْدُ لِلَّهِ",
      transliteration: "Amsayna wa amsal mulku lillahi wal hamdu lillah",
      translationEn: "We have entered upon evening and the whole kingdom belongs to Allah, and all praise is for Allah",
      source: "Abu Dawud",
      repetitions: 1,
      bestTime: .evening,
      difficulty: .beginner,
      estDurationSec: 10,
      rizqBenefit: "End your day with gratitude",
      context: "Evening remembrance",
      propheticContext: "The Prophet (ﷺ) would say this every evening",
      xpValue: 10
    ),
    Dua(
      id: 6,
      categoryId: 2,
      collectionId: 2,
      titleEn: "Ayatul Kursi",
      titleAr: "آية الكرسي",
      arabicText: "اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ",
      transliteration: "Allahu la ilaha illa huwal hayyul qayyum, la ta'khudhuhu sinatun wa la nawm",
      translationEn: "Allah - there is no deity except Him, the Ever-Living, the Sustainer of existence. Neither drowsiness overtakes Him nor sleep.",
      source: "Quran 2:255",
      repetitions: 1,
      bestTime: .evening,
      difficulty: .intermediate,
      estDurationSec: 30,
      rizqBenefit: "Protection during sleep",
      context: "Before sleeping",
      propheticContext: "Whoever recites it before sleeping is protected until morning",
      xpValue: 25
    ),
  ]

  // MARK: - Journeys

  public static let journeys: [Journey] = [
    Journey(
      id: 1,
      name: "Morning Routine",
      slug: "morning-routine",
      description: "Start your day with beautiful morning adhkar",
      emoji: "🌅",
      estimatedMinutes: 10,
      dailyXp: 50,
      isPremium: false,
      isFeatured: true,
      sortOrder: 1
    ),
    Journey(
      id: 2,
      name: "Evening Serenity",
      slug: "evening-serenity",
      description: "End your day with peaceful evening remembrance",
      emoji: "🌙",
      estimatedMinutes: 10,
      dailyXp: 50,
      isPremium: false,
      isFeatured: true,
      sortOrder: 2
    ),
    Journey(
      id: 3,
      name: "Rizq Path",
      slug: "rizq-path",
      description: "Duas for sustenance and Allah's provision",
      emoji: "✨",
      estimatedMinutes: 15,
      dailyXp: 75,
      isPremium: false,
      isFeatured: false,
      sortOrder: 3
    ),
    Journey(
      id: 4,
      name: "Gratitude Journey",
      slug: "gratitude-journey",
      description: "Cultivate a heart of thankfulness",
      emoji: "💚",
      estimatedMinutes: 10,
      dailyXp: 50,
      isPremium: false,
      isFeatured: false,
      sortOrder: 4
    ),
  ]

  // MARK: - Journey Duas

  public static let journeyDuas: [JourneyDuaFull] = [
    // Morning Routine (Journey 1)
    JourneyDuaFull(
      journeyDua: JourneyDua(journeyId: 1, duaId: 1, timeSlot: .morning, sortOrder: 1),
      dua: duas[0]
    ),
    JourneyDuaFull(
      journeyDua: JourneyDua(journeyId: 1, duaId: 2, timeSlot: .morning, sortOrder: 2),
      dua: duas[1]
    ),
    JourneyDuaFull(
      journeyDua: JourneyDua(journeyId: 1, duaId: 4, timeSlot: .morning, sortOrder: 3),
      dua: duas[3]
    ),
    // Evening Serenity (Journey 2)
    JourneyDuaFull(
      journeyDua: JourneyDua(journeyId: 2, duaId: 5, timeSlot: .evening, sortOrder: 1),
      dua: duas[4]
    ),
    JourneyDuaFull(
      journeyDua: JourneyDua(journeyId: 2, duaId: 6, timeSlot: .evening, sortOrder: 2),
      dua: duas[5]
    ),
    // Rizq Path (Journey 3)
    JourneyDuaFull(
      journeyDua: JourneyDua(journeyId: 3, duaId: 3, timeSlot: .anytime, sortOrder: 1),
      dua: duas[2]
    ),
  ]

  // MARK: - User Profile

  public static let userProfile = UserProfile(
    id: UUID().uuidString,
    userId: UUID().uuidString,
    displayName: "Test User",
    streak: 7,
    totalXp: 350,
    level: 3,
    lastActiveDate: Date(),
    isAdmin: false
  )

  // MARK: - User Habits

  public static let userHabits: [UserHabit] = [
    UserHabit.from(dua: duas[0], journeyId: 1, timeSlot: .morning),
    UserHabit.from(dua: duas[1], journeyId: 1, timeSlot: .morning),
    UserHabit.from(dua: duas[3], journeyId: 1, timeSlot: .morning),
    UserHabit.from(dua: duas[2], journeyId: 3, timeSlot: .anytime),
    UserHabit.from(dua: duas[4], journeyId: 2, timeSlot: .evening),
    UserHabit.from(dua: duas[5], journeyId: 2, timeSlot: .evening),
  ]
}
