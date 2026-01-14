#!/usr/bin/env node

/**
 * Seed Firestore with RIZQ dua data
 *
 * Run with: node scripts/seed-firestore.js
 *
 * Prerequisites:
 * 1. npm install firebase-admin
 * 2. Download service account key from Firebase Console:
 *    Project Settings > Service Accounts > Generate new private key
 * 3. Set environment variable: export GOOGLE_APPLICATION_CREDENTIALS="/path/to/key.json"
 *    OR place the key at ./service-account-key.json
 */

const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

// Initialize Firebase Admin
const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS ||
  path.join(__dirname, 'service-account-key.json');

if (fs.existsSync(serviceAccountPath)) {
  const serviceAccount = require(serviceAccountPath);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
} else {
  // Use application default credentials (works in Cloud Shell, Cloud Functions, etc.)
  admin.initializeApp({
    projectId: 'rizq-app-c6468'
  });
}

const db = admin.firestore();

// ============================================
// SEED DATA
// ============================================

const categories = [
  { id: 1, name: "Morning", slug: "morning", description: "Adhkar for the morning", emoji: "🌅" },
  { id: 2, name: "Evening", slug: "evening", description: "Adhkar for the evening", emoji: "🌙" },
  { id: 3, name: "Rizq", slug: "rizq", description: "Duas for sustenance and provision", emoji: "💫" },
  { id: 4, name: "Gratitude", slug: "gratitude", description: "Duas of thankfulness", emoji: "🤲" },
  { id: 5, name: "Foundation", slug: "foundation", description: "Core adhkar for building your practice", emoji: "🌱" },
];

const duas = [
  {
    id: 1,
    categoryId: 1,
    collectionId: 1,
    titleEn: "Morning Dhikr",
    titleAr: "أذكار الصباح",
    arabicText: "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ",
    transliteration: "Asbahna wa asbahal-mulku lillah, wal-hamdu lillah, la ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamdu wa huwa 'ala kulli shay'in qadir.",
    translationEn: "We have entered the morning and so has the dominion of Allah. All praise is due to Allah. There is no god but Allah alone, with no partner. His is the dominion and His is the praise, and He is over all things capable.",
    source: "Abu Dawud 5071",
    repetitions: 1,
    bestTime: "After Fajr",
    difficulty: "beginner",
    estDurationSec: 20,
    rizqBenefit: "Start your day acknowledging Allah's sovereignty - this sets the spiritual foundation for blessings throughout the day",
    propheticContext: "The Prophet (ﷺ) would say this every morning to establish remembrance of Allah at the start of the day",
    xpValue: 15
  },
  {
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
    difficulty: "beginner",
    estDurationSec: 15,
    rizqBenefit: "Protection throughout the day",
    propheticContext: "Recited by the Prophet (ﷺ) for protection",
    xpValue: 15
  },
  {
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
    difficulty: "intermediate",
    estDurationSec: 20,
    rizqBenefit: "Seeking halal sustenance",
    propheticContext: "The Prophet (ﷺ) taught this dua for seeking lawful provision",
    xpValue: 20
  },
  {
    id: 4,
    categoryId: 4,
    collectionId: 1,
    titleEn: "Gratitude Upon Waking",
    titleAr: "الحمد",
    arabicText: "الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ",
    transliteration: "Alhamdu lillahil-ladhi ahyana ba'da ma amatana wa ilayhin-nushur",
    translationEn: "All praise is for Allah who gave us life after having taken it from us, and unto Him is the resurrection",
    source: "Bukhari",
    repetitions: 1,
    bestTime: "Upon waking",
    difficulty: "beginner",
    estDurationSec: 10,
    rizqBenefit: "Expressing gratitude for life",
    propheticContext: "Said by the Prophet (ﷺ) upon waking",
    xpValue: 10
  },
  {
    id: 5,
    categoryId: 2,
    collectionId: 1,
    titleEn: "Evening Protection",
    titleAr: "أذكار المساء",
    arabicText: "أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ",
    transliteration: "Amsayna wa amsal-mulku lillah, wal-hamdu lillah, la ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamdu wa huwa 'ala kulli shay'in qadir.",
    translationEn: "We have entered the evening and so has the dominion of Allah. All praise is due to Allah. There is no god but Allah alone, with no partner. His is the dominion and His is the praise, and He is over all things capable.",
    source: "Abu Dawud 5071",
    repetitions: 1,
    bestTime: "After Maghrib",
    difficulty: "beginner",
    estDurationSec: 20,
    rizqBenefit: "End your day acknowledging Allah's sovereignty - this brings protection and blessings through the night",
    propheticContext: "The Prophet (ﷺ) would say this every evening to establish remembrance of Allah at the end of the day",
    xpValue: 15
  },
  {
    id: 6,
    categoryId: 2,
    collectionId: 2,
    titleEn: "Ayatul Kursi",
    titleAr: "آية الكرسي",
    arabicText: "اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ",
    transliteration: "Allahu la ilaha illa huwal-Hayyul-Qayyum. La ta'khudhuhu sinatun wa la nawm. Lahu ma fis-samawati wa ma fil-ard. Man dhal-ladhi yashfa'u 'indahu illa bi-idhnih. Ya'lamu ma bayna aydihim wa ma khalfahum. Wa la yuhituna bi-shay'im-min 'ilmihi illa bima sha'. Wasi'a kursiyyuhus-samawati wal-ard. Wa la ya'uduhu hifdhuhuma. Wa huwal-'Aliyyul-'Adhim.",
    translationEn: "Allah - there is no deity except Him, the Ever-Living, the Sustainer of existence. Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth. Who is it that can intercede with Him except by His permission? He knows what is before them and what will be after them, and they encompass not a thing of His knowledge except for what He wills. His Kursi (Throne) extends over the heavens and the earth, and their preservation tires Him not. And He is the Most High, the Most Great.",
    source: "Quran 2:255",
    repetitions: 1,
    bestTime: "Before sleep, after each prayer",
    difficulty: "intermediate",
    estDurationSec: 60,
    rizqBenefit: "The greatest verse in the Quran - provides complete protection and blessings",
    propheticContext: "The Prophet (ﷺ) said: 'Whoever recites Ayatul Kursi after every obligatory prayer, nothing prevents him from entering Paradise except death.' (An-Nasa'i). Abu Hurayrah reported that the Prophet (ﷺ) said whoever recites it before sleeping will have a guardian from Allah and no devil will come near them until morning.",
    xpValue: 35
  },
  {
    id: 7,
    categoryId: 3,
    collectionId: 1,
    titleEn: "Istighfar for Rizq",
    titleAr: "الاستغفار للرزق",
    arabicText: "أَسْتَغْفِرُ اللَّهَ الَّذِي لَا إِلَهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ وَأَتُوبُ إِلَيْهِ",
    transliteration: "Astaghfirullah alladhi la ilaha illa huwal hayyul qayyumu wa atubu ilayh",
    translationEn: "I seek forgiveness from Allah, the One whom there is no god except Him, the Ever-Living, the Sustainer, and I repent to Him",
    source: "Abu Dawud, Tirmidhi",
    repetitions: 3,
    bestTime: "Anytime",
    difficulty: "beginner",
    estDurationSec: 15,
    rizqBenefit: "Istighfar opens doors of provision - whoever makes istighfar a habit, Allah provides from unexpected sources",
    propheticContext: "The Prophet (ﷺ) said: Whoever makes istighfar constantly, Allah will give him relief from every worry and provide for him from where he does not expect",
    xpValue: 15
  },
  {
    id: 8,
    categoryId: 1,
    collectionId: 1,
    titleEn: "Sayyidul Istighfar",
    titleAr: "سيد الاستغفار",
    arabicText: "اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ خَلَقْتَنِي وَأَنَا عَبْدُكَ وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ",
    transliteration: "Allahumma anta Rabbi la ilaha illa anta, khalaqtani wa ana 'abduka, wa ana 'ala 'ahdika wa wa'dika mastata't. A'udhu bika min sharri ma sana't. Abu'u laka bi ni'matika 'alayya, wa abu'u bi dhanbi, faghfir li, fa innahu la yaghfirudh-dhunuba illa anta.",
    translationEn: "O Allah, You are my Lord, there is no god but You. You created me and I am Your servant, and I am upon Your covenant and promise as much as I am able. I seek refuge in You from the evil of what I have done. I acknowledge Your favor upon me and I acknowledge my sin, so forgive me, for none forgives sins except You.",
    source: "Bukhari 6306",
    repetitions: 1,
    bestTime: "Morning and evening",
    difficulty: "intermediate",
    estDurationSec: 45,
    rizqBenefit: "The master supplication for forgiveness - said with conviction, it guarantees Paradise. Seeking forgiveness opens doors of provision.",
    propheticContext: "The Prophet (ﷺ) said: 'Whoever says this during the day with firm conviction and dies that day before evening, will be among the people of Paradise. And whoever says it at night with firm conviction and dies before morning, will be among the people of Paradise.' (Bukhari 6306)",
    xpValue: 40
  },
  {
    id: 9,
    categoryId: 4,
    collectionId: 1,
    titleEn: "Praising Allah",
    titleAr: "التسبيح والتحميد",
    arabicText: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ سُبْحَانَ اللَّهِ الْعَظِيمِ",
    transliteration: "SubhanAllahi wa bihamdihi, SubhanAllahil 'Adheem",
    translationEn: "Glory be to Allah and His is the praise, Glory be to Allah the Magnificent",
    source: "Bukhari, Muslim",
    repetitions: 10,
    bestTime: "Anytime",
    difficulty: "beginner",
    estDurationSec: 30,
    rizqBenefit: "Light on the tongue, heavy on the scales, beloved to the Most Merciful",
    propheticContext: "The Prophet (ﷺ) said: Two words are light on the tongue, heavy on the scales, and beloved to the Most Merciful",
    xpValue: 20
  },
  {
    id: 10,
    categoryId: 3,
    collectionId: 1,
    titleEn: "Dua for Debt Relief",
    titleAr: "دعاء قضاء الدين",
    arabicText: "اللَّهُمَّ اقْضِ عَنِّي الدَّيْنَ وَأَغْنِنِي مِنَ الْفَقْرِ",
    transliteration: "Allahumma iqdi 'annid-dayna wa aghnini minal-faqr",
    translationEn: "O Allah, settle my debts and free me from poverty",
    source: "Ahmad",
    repetitions: 3,
    bestTime: "After Salah",
    difficulty: "beginner",
    estDurationSec: 10,
    rizqBenefit: "Specifically for relief from debt and financial hardship",
    propheticContext: "The Prophet (ﷺ) taught various duas for seeking relief from debt",
    xpValue: 15
  },
  {
    id: 11,
    categoryId: 1,
    collectionId: 1,
    titleEn: "Tahleel - Declaration of Tawheed",
    titleAr: "التهليل - كلمة التوحيد",
    arabicText: "لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ",
    transliteration: "La ilaha illallah wahdahu la sharika lahu, lahul-mulku wa lahul-hamdu, wa huwa 'ala kulli shay'in qadir",
    translationEn: "There is none worthy of worship except Allah alone, He has no partner. His is the dominion and His is the praise, and He is capable of all things.",
    source: "Bukhari 6403, Muslim 2691",
    repetitions: 100,
    bestTime: "Morning",
    difficulty: "intermediate",
    estDurationSec: 600,
    rizqBenefit: "An extremely powerful dhikr that covers all the good we need from Allah - brings protection, blessings, and erases sins",
    propheticContext: "The Prophet (ﷺ) said: Whoever says this 100 times in a day will have the reward of freeing 10 slaves, 100 good deeds recorded, 100 bad deeds erased, and protection from Shaytan until evening. No one can do better except one who does more.",
    xpValue: 50
  },

  // ============================================
  // NEW BEGINNINGS JOURNEY - Foundational Duas
  // For returning Muslims reconnecting with faith
  // ============================================
  {
    id: 12,
    categoryId: 5,
    collectionId: 1,
    titleEn: "Bismillah - In Allah's Name",
    titleAr: "بِسْمِ اللَّهِ",
    arabicText: "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
    transliteration: "Bismillahir-Rahmanir-Raheem",
    translationEn: "In the name of Allah, the Most Gracious, the Most Merciful",
    source: "Quran 1:1",
    repetitions: 3,
    bestTime: "Anytime",
    difficulty: "beginner",
    estDurationSec: 15,
    rizqBenefit: "Every good deed begun with Bismillah carries blessings. Start everything in Allah's name.",
    propheticContext: "The Prophet (ﷺ) said: Any important matter that does not begin with Bismillah is devoid of blessing.",
    xpValue: 10,
    encouragementMessage: "This is where every journey begins. One simple phrase, infinite blessings."
  },
  {
    id: 13,
    categoryId: 5,
    collectionId: 1,
    titleEn: "Alhamdulillah - All Praise to Allah",
    titleAr: "الْحَمْدُ لِلَّهِ",
    arabicText: "الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ",
    transliteration: "Alhamdulillahi Rabbil-'Aalameen",
    translationEn: "All praise is due to Allah, Lord of all the worlds",
    source: "Quran 1:2",
    repetitions: 3,
    bestTime: "Anytime",
    difficulty: "beginner",
    estDurationSec: 15,
    rizqBenefit: "Gratitude multiplies blessings. Those who thank Allah are given more.",
    propheticContext: "The Prophet (ﷺ) said: Allah is pleased with His servant who says Alhamdulillah after eating or drinking.",
    xpValue: 10,
    encouragementMessage: "Gratitude transforms the heart. Even on hard days, there's always something to be thankful for."
  },
  {
    id: 14,
    categoryId: 5,
    collectionId: 1,
    titleEn: "SubhanAllah - Glory to Allah",
    titleAr: "سُبْحَانَ اللَّهِ",
    arabicText: "سُبْحَانَ اللَّهِ",
    transliteration: "SubhanAllah",
    translationEn: "Glory be to Allah (He is free from any imperfection)",
    source: "Bukhari, Muslim",
    repetitions: 10,
    bestTime: "Anytime",
    difficulty: "beginner",
    estDurationSec: 30,
    rizqBenefit: "SubhanAllah plants trees in Paradise for you. Each utterance is a seed of eternal reward.",
    propheticContext: "The Prophet (ﷺ) said: Is any one of you unable to earn a thousand good deeds each day? Say SubhanAllah 100 times.",
    xpValue: 15,
    encouragementMessage: "Just one word, said with presence, connects you to the infinite. You're doing beautifully."
  },
  {
    id: 15,
    categoryId: 5,
    collectionId: 1,
    titleEn: "La ilaha illallah - Declaration of Faith",
    titleAr: "لَا إِلَٰهَ إِلَّا اللَّهُ",
    arabicText: "لَا إِلَٰهَ إِلَّا اللَّهُ",
    transliteration: "La ilaha illallah",
    translationEn: "There is no god but Allah",
    source: "Bukhari, Muslim",
    repetitions: 10,
    bestTime: "Anytime",
    difficulty: "beginner",
    estDurationSec: 30,
    rizqBenefit: "The best dhikr. This declaration is the foundation of our faith and the key to Paradise.",
    propheticContext: "The Prophet (ﷺ) said: The best dhikr is La ilaha illallah, and the best dua is Alhamdulillah.",
    xpValue: 20,
    encouragementMessage: "These words are the most beloved to Allah. Speaking them is returning home."
  },
  {
    id: 16,
    categoryId: 5,
    collectionId: 1,
    titleEn: "Astaghfirullah - Seeking Forgiveness",
    titleAr: "أَسْتَغْفِرُ اللَّهَ",
    arabicText: "أَسْتَغْفِرُ اللَّهَ",
    transliteration: "Astaghfirullah",
    translationEn: "I seek forgiveness from Allah",
    source: "Bukhari, Muslim",
    repetitions: 10,
    bestTime: "Anytime",
    difficulty: "beginner",
    estDurationSec: 30,
    rizqBenefit: "Istighfar opens doors that seemed closed. It brings relief, provision, and peace.",
    propheticContext: "The Prophet (ﷺ) used to seek forgiveness 100 times a day, teaching us that forgiveness is for everyone.",
    xpValue: 15,
    encouragementMessage: "There is no sin too great for Allah's mercy. Every moment is a fresh start."
  }
];

const journeys = [
  {
    id: 1,
    name: "Rizq Seeker",
    slug: "rizq-seeker",
    description: "A comprehensive daily practice focused on increasing provision and blessings in your life.",
    emoji: "💰",
    estimatedMinutes: 15,
    dailyXp: 270,
    isPremium: false,
    isFeatured: true,
    sortOrder: 0
  },
  {
    id: 2,
    name: "Morning Warrior",
    slug: "morning-warrior",
    description: "Start your day with powerful duas for protection and blessings.",
    emoji: "🌅",
    estimatedMinutes: 22,
    dailyXp: 300,
    isPremium: false,
    isFeatured: true,
    sortOrder: 1
  },
  {
    id: 3,
    name: "Debt Freedom",
    slug: "debt-freedom",
    description: "Daily duas specifically for relief from debt and financial hardship.",
    emoji: "🔓",
    estimatedMinutes: 10,
    dailyXp: 125,
    isPremium: false,
    isFeatured: true,
    sortOrder: 2
  },
  {
    id: 4,
    name: "Evening Peace",
    slug: "evening-peace",
    description: "End your day with duas for gratitude and protection through the night.",
    emoji: "🌙",
    estimatedMinutes: 10,
    dailyXp: 195,
    isPremium: false,
    isFeatured: false,
    sortOrder: 3
  },
  {
    id: 5,
    name: "Gratitude Builder",
    slug: "gratitude-builder",
    description: "Build a habit of thankfulness with these powerful duas of gratitude.",
    emoji: "🤲",
    estimatedMinutes: 10,
    dailyXp: 155,
    isPremium: false,
    isFeatured: false,
    sortOrder: 4
  },
  {
    id: 6,
    name: "New Beginnings",
    slug: "new-beginnings",
    description: "A gentle reintroduction to daily remembrance. Perfect for those reconnecting with their faith — no pressure, just peace.",
    emoji: "🌱",
    estimatedMinutes: 5,
    dailyXp: 70,
    isPremium: false,
    isFeatured: true,
    sortOrder: 5,
    // New Beginnings specific fields
    personaTarget: "returning",
    welcomeMessage: "Welcome back. Every journey begins with a single step. There's no judgment here — only growth.",
    missedDayMessage: "It's okay. Every moment is a chance to reconnect. Pick up where you left off.",
    streakRestorationFree: true
  }
];

const journeyDuas = [
  // Rizq Seeker (Journey 1)
  { journeyId: 1, duaId: 3, timeSlot: "anytime", sortOrder: 1 },
  { journeyId: 1, duaId: 7, timeSlot: "anytime", sortOrder: 2 },
  { journeyId: 1, duaId: 10, timeSlot: "anytime", sortOrder: 3 },

  // Morning Warrior (Journey 2)
  { journeyId: 2, duaId: 1, timeSlot: "morning", sortOrder: 1 },
  { journeyId: 2, duaId: 2, timeSlot: "morning", sortOrder: 2 },
  { journeyId: 2, duaId: 8, timeSlot: "morning", sortOrder: 3 },
  { journeyId: 2, duaId: 11, timeSlot: "morning", sortOrder: 4 },

  // Debt Freedom (Journey 3)
  { journeyId: 3, duaId: 10, timeSlot: "anytime", sortOrder: 1 },
  { journeyId: 3, duaId: 3, timeSlot: "anytime", sortOrder: 2 },
  { journeyId: 3, duaId: 7, timeSlot: "anytime", sortOrder: 3 },

  // Evening Peace (Journey 4)
  { journeyId: 4, duaId: 5, timeSlot: "evening", sortOrder: 1 },
  { journeyId: 4, duaId: 6, timeSlot: "evening", sortOrder: 2 },

  // Gratitude Builder (Journey 5)
  { journeyId: 5, duaId: 4, timeSlot: "morning", sortOrder: 1 },
  { journeyId: 5, duaId: 9, timeSlot: "anytime", sortOrder: 2 },

  // New Beginnings (Journey 6) - Foundational duas for returning Muslims
  { journeyId: 6, duaId: 12, timeSlot: "anytime", sortOrder: 1 },  // Bismillah
  { journeyId: 6, duaId: 13, timeSlot: "anytime", sortOrder: 2 },  // Alhamdulillah
  { journeyId: 6, duaId: 14, timeSlot: "anytime", sortOrder: 3 },  // SubhanAllah
  { journeyId: 6, duaId: 15, timeSlot: "anytime", sortOrder: 4 },  // La ilaha illallah
  { journeyId: 6, duaId: 16, timeSlot: "anytime", sortOrder: 5 },  // Astaghfirullah
];

// ============================================
// SEED FUNCTIONS
// ============================================

async function seedCollection(collectionName, data, idField = 'id') {
  console.log(`\nSeeding ${collectionName}...`);
  const batch = db.batch();

  for (const item of data) {
    const docId = String(item[idField]);
    const docRef = db.collection(collectionName).doc(docId);

    // Add timestamp
    const docData = {
      ...item,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };

    batch.set(docRef, docData);
    console.log(`  + ${collectionName}/${docId}`);
  }

  await batch.commit();
  console.log(`✓ Seeded ${data.length} documents to ${collectionName}`);
}

async function seedJourneyDuas() {
  console.log(`\nSeeding journey_duas...`);
  const batch = db.batch();

  for (const item of journeyDuas) {
    // Create composite ID: journeyId_duaId
    const docId = `${item.journeyId}_${item.duaId}`;
    const docRef = db.collection('journey_duas').doc(docId);

    const docData = {
      ...item,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    };

    batch.set(docRef, docData);
    console.log(`  + journey_duas/${docId}`);
  }

  await batch.commit();
  console.log(`✓ Seeded ${journeyDuas.length} documents to journey_duas`);
}

async function main() {
  console.log('='.repeat(50));
  console.log('RIZQ Firestore Seeder');
  console.log('='.repeat(50));
  console.log(`Project: rizq-app-c6468`);
  console.log(`Time: ${new Date().toISOString()}`);

  try {
    // Seed all collections
    await seedCollection('categories', categories);
    await seedCollection('duas', duas);
    await seedCollection('journeys', journeys);
    await seedJourneyDuas();

    console.log('\n' + '='.repeat(50));
    console.log('✅ SEEDING COMPLETE!');
    console.log('='.repeat(50));
    console.log('\nYou can now view the data at:');
    console.log('https://console.firebase.google.com/project/rizq-app-c6468/firestore');

  } catch (error) {
    console.error('\n❌ Error seeding data:', error);
    process.exit(1);
  }

  process.exit(0);
}

main();
