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
      bestTime: "After Fajr",
      difficulty: .beginner,
      estDurationSec: 10,
      rizqBenefit: "Start your day with gratitude",
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
      bestTime: "After Fajr",
      difficulty: .beginner,
      estDurationSec: 15,
      rizqBenefit: "Protection throughout the day",
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
      bestTime: "Anytime",
      difficulty: .intermediate,
      estDurationSec: 20,
      rizqBenefit: "Seeking halal sustenance",
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
      bestTime: "Upon waking",
      difficulty: .beginner,
      estDurationSec: 10,
      rizqBenefit: "Expressing gratitude for life",
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
      bestTime: "After Maghrib",
      difficulty: .beginner,
      estDurationSec: 10,
      rizqBenefit: "End your day with gratitude",
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
      bestTime: "Before sleep",
      difficulty: .intermediate,
      estDurationSec: 30,
      rizqBenefit: "Protection during sleep",
      propheticContext: "Whoever recites it before sleeping is protected until morning",
      xpValue: 25
    ),
  ]

  // MARK: - Journeys (matches Neon database)

  public static let journeys: [Journey] = [
    Journey(
      id: 1,
      name: "Rizq Seeker",
      slug: "rizq-seeker",
      description: "A comprehensive daily practice focused on increasing provision and blessings in your life.",
      emoji: "/images/icons/The Rizq Seeker.png",
      estimatedMinutes: 15,
      dailyXp: 270,
      isPremium: false,
      isFeatured: true,
      sortOrder: 0
    ),
    Journey(
      id: 2,
      name: "Morning Warrior",
      slug: "morning-warrior",
      description: "Start your day with powerful duas for protection and blessings.",
      emoji: "/images/icons/Morning Warrior.png",
      estimatedMinutes: 12,
      dailyXp: 250,
      isPremium: false,
      isFeatured: true,
      sortOrder: 1
    ),
    Journey(
      id: 3,
      name: "Debt Freedom",
      slug: "debt-freedom",
      description: "Daily duas specifically for relief from debt and financial hardship.",
      emoji: "/images/icons/default-journey.png",
      estimatedMinutes: 10,
      dailyXp: 125,
      isPremium: false,
      isFeatured: true,
      sortOrder: 2
    ),
    Journey(
      id: 4,
      name: "Evening Peace",
      slug: "evening-peace",
      description: "End your day with duas for gratitude and protection through the night.",
      emoji: "/images/icons/Evening Peace.png",
      estimatedMinutes: 10,
      dailyXp: 195,
      isPremium: false,
      isFeatured: false,
      sortOrder: 3
    ),
    Journey(
      id: 5,
      name: "Gratitude Builder",
      slug: "gratitude-builder",
      description: "Build a habit of thankfulness with these powerful duas of gratitude.",
      emoji: "/images/icons/Gratitude Builder.png",
      estimatedMinutes: 10,
      dailyXp: 155,
      isPremium: false,
      isFeatured: false,
      sortOrder: 4
    ),
    Journey(
      id: 6,
      name: "Tahajjud Night Warrior",
      slug: "tahajjud-night-warrior",
      description: "Embrace the blessed night prayers and strengthen your connection with Allah.",
      emoji: "/images/icons/Tahajjud Night Warrior.png",
      estimatedMinutes: 8,
      dailyXp: 180,
      isPremium: false,
      isFeatured: true,
      sortOrder: 5
    ),
    Journey(
      id: 7,
      name: "Salawat on Prophet",
      slug: "salawat-on-prophet",
      description: "Send blessings upon the Prophet Muhammad ﷺ and earn immense rewards.",
      emoji: "/images/icons/Salawat on Prophet.png",
      estimatedMinutes: 5,
      dailyXp: 120,
      isPremium: false,
      isFeatured: false,
      sortOrder: 6
    ),
    Journey(
      id: 8,
      name: "Salah Companion",
      slug: "salah-companion",
      description: "Perfect your prayer with essential duas before, during, and after Salah.",
      emoji: "/images/icons/Salah Companion.png",
      estimatedMinutes: 10,
      dailyXp: 200,
      isPremium: false,
      isFeatured: true,
      sortOrder: 7
    ),
    Journey(
      id: 9,
      name: "Quran Reflection",
      slug: "quran-reflection",
      description: "Deepen your connection with the Quran through daily reflection and study.",
      emoji: "/images/icons/Quran Reflection.png",
      estimatedMinutes: 15,
      dailyXp: 220,
      isPremium: false,
      isFeatured: false,
      sortOrder: 8
    ),
    Journey(
      id: 10,
      name: "New Muslim Starter",
      slug: "new-muslim-starter",
      description: "Essential duas and practices for those beginning their Islamic journey.",
      emoji: "/images/icons/New Muslim Starter.png",
      estimatedMinutes: 8,
      dailyXp: 150,
      isPremium: false,
      isFeatured: true,
      sortOrder: 9
    ),
    Journey(
      id: 11,
      name: "Morning Adhkar",
      slug: "morning-adhkar",
      description: "Comprehensive morning remembrance to start your day with barakah.",
      emoji: "/images/icons/Morning Adhkar.png",
      estimatedMinutes: 12,
      dailyXp: 230,
      isPremium: false,
      isFeatured: false,
      sortOrder: 10
    ),
    Journey(
      id: 12,
      name: "Job Seeker",
      slug: "job-seeker",
      description: "Powerful supplications for finding halal employment and career success.",
      emoji: "/images/icons/Job Seeker.png",
      estimatedMinutes: 10,
      dailyXp: 160,
      isPremium: false,
      isFeatured: false,
      sortOrder: 11
    ),
    Journey(
      id: 13,
      name: "Istighfar Habit",
      slug: "istighfar-habit",
      description: "Build a consistent practice of seeking forgiveness and purifying your heart.",
      emoji: "/images/icons/Istighfar Habit.png",
      estimatedMinutes: 7,
      dailyXp: 140,
      isPremium: false,
      isFeatured: false,
      sortOrder: 12
    ),
    Journey(
      id: 14,
      name: "Family Provider",
      slug: "family-provider",
      description: "Duas for those striving to provide for their families and loved ones.",
      emoji: "/images/icons/Family provider.png",
      estimatedMinutes: 10,
      dailyXp: 175,
      isPremium: false,
      isFeatured: false,
      sortOrder: 13
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
