-- Insert Collections
INSERT INTO collections (name, slug, is_premium) VALUES
('Core Collection', 'core', FALSE),
('Extended Collection', 'extended', TRUE),
('Specialized Collections', 'specialized', TRUE)
ON CONFLICT (slug) DO NOTHING;

-- Insert Categories (slugs match frontend DuaCategory type)
INSERT INTO categories (name, slug, description) VALUES
('Morning', 'morning', 'Duas for the morning to seek protection and provision.'),
('Evening', 'evening', 'Duas for the evening and night.'),
('Rizq', 'rizq', 'Duas specifically asking for wealth and provision.'),
('Gratitude', 'gratitude', 'Duas of thankfulness and appreciation.')
ON CONFLICT (slug) DO NOTHING;

-- Insert Duas (Core Collection - Phase 1)

-- 1. Ayatul Kursi
INSERT INTO duas (
    title_en, title_ar, arabic_text, transliteration, translation_en,
    source, repetitions, best_time, difficulty, est_duration_sec,
    rizq_benefit, prophetic_context, xp_value, collection_id, category_id
) VALUES (
    'Ayatul Kursi (Verse of the Throne)',
    'آية الكرسي',
    'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ',
    'Allahu la ilaha illa Huwal-Hayyul-Qayyum, la ta''khudhuhu sinatun wa la nawm, lahu ma fis-samawati wa ma fil-ard, man dhal-ladhi yashfa''u ''indahu illa bi-idhnih, ya''lamu ma bayna aydihim wa ma khalfahum, wa la yuhituna bi-shay''im-min ''ilmihi illa bima sha''a, wasi''a kursiyyuhus-samawati wal-ard, wa la ya''uduhu hifdhuhuma, wa Huwal-''Aliyyul-''Adhim.',
    'Allah - there is no deity except Him, the Ever-Living, the Sustainer of existence. Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth. Who is it that can intercede with Him except by His permission? He knows what is before them and what will be after them, and they encompass not a thing of His knowledge except for what He wills. His Throne extends over the heavens and the earth, and their preservation tires Him not. And He is the Most High, the Most Great.',
    'Quran 2:255',
    1,
    'After Fajr, before sleep, after each salah',
    'Beginner',
    45,
    'Comprehensive protection of wealth and provision',
    'The Prophet ﷺ said: "Whoever recites Ayatul Kursi after every obligatory prayer, nothing will prevent him from entering Paradise except death." (An-Nasa''i). He ﷺ also told Abu Hurayrah: "When you go to bed, recite Ayatul Kursi, for there will be a guard from Allah protecting you throughout the night, and Satan will not come near you until morning." (Sahih Bukhari). This is the greatest verse in the Quran, containing the most comprehensive description of Allah''s majesty.',
    50,
    (SELECT id FROM collections WHERE slug = 'core'),
    (SELECT id FROM categories WHERE slug = 'morning')
);

-- 2. Morning Protection Dua
INSERT INTO duas (
    title_en, title_ar, arabic_text, transliteration, translation_en,
    source, repetitions, best_time, difficulty, est_duration_sec,
    rizq_benefit, prophetic_context, xp_value, collection_id, category_id
) VALUES (
    'Morning Protection Dua (Sabah wa Amsa)',
    'دعاء الصباح والمساء',
    'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذَا الْيَوْمِ وَخَيْرَ مَا بَعْدَهُ، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذَا الْيَوْمِ وَشَرِّ مَا بَعْدَهُ',
    'Asbahna wa asbahal-mulku lillah, walhamdu lillah, la ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamd, wa Huwa ''ala kulli shay''in Qadir. Rabbi as''aluka khayra ma fi hadhal-yawm wa khayra ma ba''dah, wa a''udhu bika min sharri ma fi hadhal-yawm wa sharri ma ba''dah.',
    'We have entered a new day and with it all dominion belongs to Allah. Praise is to Allah. None has the right to be worshipped but Allah alone, Who has no partner. To Allah belongs the dominion, and to Him is all praise, and He has power over everything. My Lord, I ask You for the good of this day and the good that follows it, and I seek refuge in You from the evil of this day and the evil that follows it.',
    'Sahih Muslim 2723',
    1,
    'After Fajr, upon waking',
    'Beginner',
    30,
    'Asking for the good/provision of the day ahead',
    'This dua was part of the Prophet''s ﷺ daily morning routine. He would recite it upon waking, establishing a practice of beginning each day by acknowledging Allah''s sovereignty. The Companions reported that he ﷺ was consistent with this remembrance, never missing it. Ibn Umar (may Allah be pleased with him) narrated that he learned this directly from the Prophet ﷺ as essential morning adhkar.',
    30,
    (SELECT id FROM collections WHERE slug = 'core'),
    (SELECT id FROM categories WHERE slug = 'morning')
);

-- 3. Dua Upon Leaving Home
INSERT INTO duas (
    title_en, title_ar, arabic_text, transliteration, translation_en,
    source, repetitions, best_time, difficulty, est_duration_sec,
    rizq_benefit, prophetic_context, xp_value, collection_id, category_id
) VALUES (
    'Dua for Provision Upon Leaving Home',
    'دعاء الخروج من المنزل',
    'بِسْمِ اللَّهِ، تَوَكَّلْتُ عَلَى اللَّهِ، لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
    'Bismillah, tawakkaltu ''alallah, la hawla wa la quwwata illa billah.',
    'In the name of Allah, I have placed my trust in Allah; there is no power and no strength except with Allah.',
    'Abu Dawud 5095',
    1,
    'Before going to work, business, job search',
    'Beginner',
    5,
    'Reliance on Allah for sustenance during daily activities',
    'The Prophet ﷺ taught this dua as protection when leaving one''s home. He ﷺ said: "Whoever says when leaving his house: ''Bismillah, tawakkaltu ''alallah, la hawla wa la quwwata illa billah'' - it will be said to him: You are guided, defended, and protected. The devil will turn away from him." (At-Tirmidhi). Anas ibn Malik reported this was the Prophet''s constant practice before stepping outside.',
    15,
    (SELECT id FROM collections WHERE slug = 'core'),
    (SELECT id FROM categories WHERE slug = 'morning')
);

-- 4. Sayyidul Istighfar
INSERT INTO duas (
    title_en, title_ar, arabic_text, transliteration, translation_en,
    source, repetitions, best_time, difficulty, est_duration_sec,
    rizq_benefit, prophetic_context, xp_value, collection_id, category_id
) VALUES (
    'The Master Dua for Provision (Sayyidul Istighfar)',
    'سيد الاستغفار',
    'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي، فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ',
    'Allahumma Anta Rabbi, la ilaha illa Ant, khalaqtani wa ana ''abduk, wa ana ''ala ''ahdika wa wa''dika mas-tata''t, a''udhu bika min sharri ma sana''t, abu''u laka bi-ni''matika ''alayy, wa abu''u bi-dhanbi, faghfir li fa-innahu la yaghfirudh-dhunuba illa Ant.',
    'O Allah, You are my Lord. There is no god but You. You created me and I am Your servant, and I am keeping my covenant and promise to You as much as I can. I seek refuge in You from the evil of what I have done. I acknowledge Your blessings upon me, and I acknowledge my sins. So forgive me, for none forgives sins except You.',
    'Sahih Al-Bukhari 6306',
    1,
    'After Fajr',
    'Intermediate',
    40,
    'Acknowledging Allah''s blessings opens doors to more provision',
    'The Prophet ﷺ called this "Sayyidul Istighfar" - the Master of Seeking Forgiveness. Shaddad ibn Aws narrated that the Prophet ﷺ said: "The most superior way of asking for forgiveness is this dua. Whoever says it during the day with firm faith in it and dies on that day before evening, will be among the people of Paradise. And whoever says it during the night with firm faith in it and dies before morning, will be among the people of Paradise." (Sahih Bukhari). The Prophet ﷺ emphasized this dua connects istighfar to provision, as sins can block rizq.',
    40,
    (SELECT id FROM collections WHERE slug = 'core'),
    (SELECT id FROM categories WHERE slug = 'rizq')
);

-- 5. Dua for Halal Provision
INSERT INTO duas (
    title_en, title_ar, arabic_text, transliteration, translation_en,
    source, repetitions, best_time, difficulty, est_duration_sec,
    rizq_benefit, prophetic_context, xp_value, collection_id, category_id
) VALUES (
    'Dua for Halal Provision',
    'دعاء الرزق الحلال',
    'اللَّهُمَّ اكْفِنِي بِحَلَالِكَ عَنْ حَرَامِكَ، وَأَغْنِنِي بِفَضْلِكَ عَمَّنْ سِوَاكَ',
    'Allahumma-kfini bi-halalika ''an haramik, wa aghnini bi-fadlika ''amman siwak.',
    'O Allah, make what is lawful enough for me, as opposed to what is unlawful, and spare me by Your grace from need of others.',
    'At-Tirmidhi 3563',
    3,
    'Anytime, especially when seeking income',
    'Beginner',
    15,
    'Directly asks for lawful, blessed provision',
    'Ali ibn Abi Talib (may Allah be pleased with him) reported that a slave who had made a contract for his freedom came to him and said: "I am unable to pay for my freedom, help me." Ali said: "Shall I not teach you words that the Prophet ﷺ taught me? If you had a debt as great as a mountain, Allah would pay it for you." Then he taught him this dua. The Prophet ﷺ specifically connected this supplication to financial relief and independence from depending on others.',
    25,
    (SELECT id FROM collections WHERE slug = 'core'),
    (SELECT id FROM categories WHERE slug = 'rizq')
);

-- 6. Evening Protection Dua
INSERT INTO duas (
    title_en, title_ar, arabic_text, transliteration, translation_en,
    source, repetitions, best_time, difficulty, est_duration_sec,
    rizq_benefit, prophetic_context, xp_value, collection_id, category_id
) VALUES (
    'Evening Protection Dua',
    'دعاء المساء',
    'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذِهِ اللَّيْلَةِ وَخَيْرَ مَا بَعْدَهَا، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذِهِ اللَّيْلَةِ وَشَرِّ مَا بَعْدَهَا',
    'Amsayna wa amsal-mulku lillah, walhamdu lillah, la ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamd, wa Huwa ''ala kulli shay''in Qadir. Rabbi as''aluka khayra ma fi hadhihil-laylah wa khayra ma ba''daha, wa a''udhu bika min sharri ma fi hadhihil-laylah wa sharri ma ba''daha.',
    'We have entered the evening and the kingdom belongs to Allah. Praise is to Allah. There is no god but Allah alone, with no partner. To Him belongs the dominion and all praise, and He has power over everything. My Lord, I ask You for the good of this night and the good that follows it, and I seek refuge in You from the evil of this night and the evil that follows it.',
    'Sahih Muslim 2723',
    1,
    'After Maghrib, before sleep',
    'Beginner',
    30,
    'Protection of nighttime provision and opportunities',
    'This is the evening counterpart to the morning adhkar. The Prophet ﷺ would recite this consistently after Maghrib prayer. Abu Hurayrah reported that the Prophet ﷺ taught his companions to bookend their days with these supplications - morning and evening - creating a complete cycle of divine protection and seeking good. The change from "yawm" (day) to "laylah" (night) reflects the Prophet''s attention to the unique blessings and challenges of each time period.',
    30,
    (SELECT id FROM collections WHERE slug = 'core'),
    (SELECT id FROM categories WHERE slug = 'evening')
);

-- 7. Dua for Relief from Debt
INSERT INTO duas (
    title_en, title_ar, arabic_text, transliteration, translation_en,
    source, repetitions, best_time, difficulty, est_duration_sec,
    rizq_benefit, prophetic_context, xp_value, collection_id, category_id
) VALUES (
    'Dua for Relief from Debt',
    'دعاء التخلص من الدين',
    'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ، وَأَعُوذُ بِكَ مِنَ الْعَجْزِ وَالْكَسَلِ، وَأَعُوذُ بِكَ مِنَ الْجُبْنِ وَالْبُخْلِ، وَأَعُوذُ بِكَ مِنْ غَلَبَةِ الدَّيْنِ وَقَهْرِ الرِّجَالِ',
    'Allahumma inni a''udhu bika minal-hammi wal-hazan, wa a''udhu bika minal-''ajzi wal-kasal, wa a''udhu bika minal-jubni wal-bukhl, wa a''udhu bika min ghalabatid-dayni wa qahrir-rijal.',
    'O Allah, I seek refuge in You from worry and grief, I seek refuge in You from helplessness and laziness, I seek refuge in You from cowardice and miserliness, and I seek refuge in You from being overpowered by debt and from the oppression of men.',
    'Sahih Al-Bukhari 6363',
    3,
    'After Fajr, during hardship',
    'Intermediate',
    25,
    'Removes obstacles to provision (debt, laziness, fear)',
    'Abu Sa''id al-Khudri reported: "The Prophet ﷺ entered the mosque one day and saw a man from the Ansar called Abu Umamah. He asked: ''What is wrong with you that I see you sitting in the mosque when it is not prayer time?'' He replied: ''I am worried about my debts, O Messenger of Allah.'' The Prophet ﷺ said: ''Shall I not teach you words which, if you say them, Allah will remove your worry and settle your debt?'' He then taught him this supplication." (Abu Dawud). The Prophet ﷺ personally prescribed this for debt relief.',
    35,
    (SELECT id FROM collections WHERE slug = 'core'),
    (SELECT id FROM categories WHERE slug = 'rizq')
);

-- 8. Dua for Beneficial Knowledge & Provision
INSERT INTO duas (
    title_en, title_ar, arabic_text, transliteration, translation_en,
    source, repetitions, best_time, difficulty, est_duration_sec,
    rizq_benefit, prophetic_context, xp_value, collection_id, category_id
) VALUES (
    'Dua for Beneficial Knowledge & Halal Provision',
    'دعاء العلم النافع والرزق الطيب',
    'اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا، وَرِزْقًا طَيِّبًا، وَعَمَلًا مُتَقَبَّلًا',
    'Allahumma inni as''aluka ''ilman nafi''a, wa rizqan tayyiba, wa ''amalan mutaqabbala.',
    'O Allah, I ask You for beneficial knowledge, pure (lawful) provision, and accepted deeds.',
    'Ibn Majah 925',
    1,
    'After Fajr prayer',
    'Beginner',
    15,
    'Directly asks for pure, halal provision',
    'Umm Salamah (may Allah be pleased with her) reported that the Prophet ﷺ used to say this supplication after the Fajr prayer. He ﷺ specifically combined three essential requests: knowledge that benefits (not just information), provision that is pure and lawful (tayyib), and deeds that are accepted by Allah. This comprehensive dua reflects the Prophet''s teaching that success requires all three elements working together - knowledge guides us, rizq sustains us, and accepted deeds elevate us.',
    30,
    (SELECT id FROM collections WHERE slug = 'core'),
    (SELECT id FROM categories WHERE slug = 'morning')
);

-- 9. Dua for Barakah in Provision
INSERT INTO duas (
    title_en, title_ar, arabic_text, transliteration, translation_en,
    source, repetitions, best_time, difficulty, est_duration_sec,
    rizq_benefit, prophetic_context, xp_value, collection_id, category_id
) VALUES (
    'Dua for Barakah in Provision',
    'دعاء البركة في الرزق',
    'اللَّهُمَّ بَارِكْ لَنَا فِيمَا رَزَقْتَنَا',
    'Allahumma barik lana fima razaqtana.',
    'O Allah, bless us in what You have provided for us.',
    'Abu Dawud 3730',
    1,
    'Before meals, when receiving income',
    'Beginner',
    5,
    'Requesting blessing/multiplication in existing provision',
    'The Prophet ﷺ taught that barakah (divine blessing) is what makes provision truly beneficial. He ﷺ said: "When one of you eats, let him mention the name of Allah. If he forgets at the beginning, let him say: ''Bismillahi awwalahu wa akhirahu.''" (Abu Dawud). This short but powerful dua asks for barakah - the multiplying of good and benefit in what we already have. The Prophet ﷺ emphasized that a small amount with barakah is better than abundance without it.',
    15,
    (SELECT id FROM collections WHERE slug = 'core'),
    (SELECT id FROM categories WHERE slug = 'gratitude')
);

-- 10. Dua of Prophet Yunus (Distress to Relief)
INSERT INTO duas (
    title_en, title_ar, arabic_text, transliteration, translation_en,
    source, repetitions, best_time, difficulty, est_duration_sec,
    rizq_benefit, prophetic_context, xp_value, collection_id, category_id
) VALUES (
    'Dua of Prophet Yunus (Distress to Relief)',
    'دعاء يونس عليه السلام',
    'لَا إِلَهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ',
    'La ilaha illa Anta, Subhanaka, inni kuntu minaz-zalimin.',
    'There is no god but You. Glory be to You! Indeed, I have been of the wrongdoers.',
    'Quran 21:87, At-Tirmidhi 3505',
    3,
    'During any difficulty, financial hardship',
    'Beginner',
    10,
    'Opens doors when all seems closed',
    'This is the supplication of Prophet Yunus (Jonah) عليه السلام when he was in the belly of the whale - the darkest, most hopeless situation imaginable. The Prophet Muhammad ﷺ said: "The supplication of Dhun-Nun (Yunus) when he was in the belly of the fish: ''La ilaha illa Anta, Subhanaka, inni kuntu minaz-zalimin.'' No Muslim ever makes dua with it for anything except that Allah responds to him." (At-Tirmidhi). This dua combines tawheed (affirming Allah''s oneness), tasbeeh (glorifying Allah), and acknowledgment of one''s shortcomings - a powerful formula that the Prophet ﷺ guaranteed would be answered.',
    25,
    (SELECT id FROM collections WHERE slug = 'core'),
    (SELECT id FROM categories WHERE slug = 'rizq')
);

-- =============================================================================
-- JOURNEYS SEED DATA
-- =============================================================================

-- Insert Journeys
INSERT INTO journeys (name, slug, description, emoji, estimated_minutes, daily_xp, is_premium, is_featured, sort_order) VALUES
('Rizq Seeker', 'rizq-seeker', 'Increase your provision and blessings through powerful duas for wealth and abundance.', '/images/icons/The Rizq Seeker.png', 15, 270, FALSE, TRUE, 1),
('Morning Warrior', 'morning-warrior', 'Start every day with purpose through essential morning adhkar and protection.', '/images/icons/Morning Warrior.png', 12, 250, FALSE, TRUE, 2),
('Debt Freedom', 'debt-freedom', 'Find relief from debt and financial stress through targeted supplications.', '/images/icons/default-journey.png', 10, 125, FALSE, TRUE, 3),
('Evening Peace', 'evening-peace', 'End each day in gratitude and protection with evening remembrance.', '/images/icons/Evening Peace.png', 10, 195, FALSE, FALSE, 4),
('Gratitude Builder', 'gratitude-builder', 'Cultivate a thankful heart and abundance mindset.', '/images/icons/Gratitude Builder.png', 10, 155, FALSE, FALSE, 5),
('Tahajjud Night Warrior', 'tahajjud-night-warrior', 'Embrace the blessed night prayers and strengthen your connection with Allah.', '/images/icons/Tahajjud Night Warrior.png', 8, 180, FALSE, TRUE, 6),
('Salawat on Prophet', 'salawat-on-prophet', 'Send blessings upon the Prophet Muhammad ﷺ and earn immense rewards.', '/images/icons/Salawat on Prophet.png', 5, 120, FALSE, FALSE, 7),
('Salah Companion', 'salah-companion', 'Perfect your prayer with essential duas before, during, and after Salah.', '/images/icons/Salah Companion.png', 10, 200, FALSE, TRUE, 8),
('Quran Reflection', 'quran-reflection', 'Deepen your connection with the Quran through daily reflection and study.', '/images/icons/Quran Reflection.png', 15, 220, FALSE, FALSE, 9),
('New Muslim Starter', 'new-muslim-starter', 'Essential duas and practices for those beginning their Islamic journey.', '/images/icons/New Muslim Starter.png', 8, 150, FALSE, TRUE, 10),
('Morning Adhkar', 'morning-adhkar', 'Comprehensive morning remembrance to start your day with barakah.', '/images/icons/Morning Adhkar.png', 12, 230, FALSE, FALSE, 11),
('Job Seeker', 'job-seeker', 'Powerful supplications for finding halal employment and career success.', '/images/icons/Job Seeker.png', 10, 160, FALSE, FALSE, 12),
('Istighfar Habit', 'istighfar-habit', 'Build a consistent practice of seeking forgiveness and purifying your heart.', '/images/icons/Istighfar Habit.png', 7, 140, FALSE, FALSE, 13),
('Family Provider', 'family-provider', 'Duas for those striving to provide for their families and loved ones.', '/images/icons/Family provider.png', 10, 175, FALSE, FALSE, 14)
ON CONFLICT (slug) DO NOTHING;

-- =============================================================================
-- JOURNEY DUAS - Link journeys to their duas with time slots
-- =============================================================================

-- Rizq Seeker Journey (5 duas: morning focus + evening istighfar)
INSERT INTO journey_duas (journey_id, dua_id, time_slot, sort_order) VALUES
((SELECT id FROM journeys WHERE slug = 'rizq-seeker'), (SELECT id FROM duas WHERE title_en LIKE '%Beneficial Knowledge%'), 'morning', 1),
((SELECT id FROM journeys WHERE slug = 'rizq-seeker'), (SELECT id FROM duas WHERE title_en LIKE '%Leaving Home%'), 'morning', 2),
((SELECT id FROM journeys WHERE slug = 'rizq-seeker'), (SELECT id FROM duas WHERE title_en LIKE '%Halal Provision%'), 'anytime', 3),
((SELECT id FROM journeys WHERE slug = 'rizq-seeker'), (SELECT id FROM duas WHERE title_en LIKE '%Barakah%'), 'anytime', 4),
((SELECT id FROM journeys WHERE slug = 'rizq-seeker'), (SELECT id FROM duas WHERE title_en LIKE '%Sayyidul Istighfar%'), 'evening', 5)
ON CONFLICT (journey_id, dua_id) DO NOTHING;

-- Morning Warrior Journey (5 duas: all morning focus)
INSERT INTO journey_duas (journey_id, dua_id, time_slot, sort_order) VALUES
((SELECT id FROM journeys WHERE slug = 'morning-warrior'), (SELECT id FROM duas WHERE title_en LIKE '%Ayatul Kursi%'), 'morning', 1),
((SELECT id FROM journeys WHERE slug = 'morning-warrior'), (SELECT id FROM duas WHERE title_en LIKE '%Morning Protection%'), 'morning', 2),
((SELECT id FROM journeys WHERE slug = 'morning-warrior'), (SELECT id FROM duas WHERE title_en LIKE '%Sayyidul Istighfar%'), 'morning', 3),
((SELECT id FROM journeys WHERE slug = 'morning-warrior'), (SELECT id FROM duas WHERE title_en LIKE '%Beneficial Knowledge%'), 'morning', 4),
((SELECT id FROM journeys WHERE slug = 'morning-warrior'), (SELECT id FROM duas WHERE title_en LIKE '%Leaving Home%'), 'morning', 5)
ON CONFLICT (journey_id, dua_id) DO NOTHING;

-- Debt Freedom Journey (4 duas: focused on debt relief)
INSERT INTO journey_duas (journey_id, dua_id, time_slot, sort_order) VALUES
((SELECT id FROM journeys WHERE slug = 'debt-freedom'), (SELECT id FROM duas WHERE title_en LIKE '%Relief from Debt%'), 'morning', 1),
((SELECT id FROM journeys WHERE slug = 'debt-freedom'), (SELECT id FROM duas WHERE title_en LIKE '%Sayyidul Istighfar%'), 'morning', 2),
((SELECT id FROM journeys WHERE slug = 'debt-freedom'), (SELECT id FROM duas WHERE title_en LIKE '%Prophet Yunus%'), 'anytime', 3),
((SELECT id FROM journeys WHERE slug = 'debt-freedom'), (SELECT id FROM duas WHERE title_en LIKE '%Halal Provision%'), 'evening', 4)
ON CONFLICT (journey_id, dua_id) DO NOTHING;

-- Evening Peace Journey (4 duas: evening focus)
INSERT INTO journey_duas (journey_id, dua_id, time_slot, sort_order) VALUES
((SELECT id FROM journeys WHERE slug = 'evening-peace'), (SELECT id FROM duas WHERE title_en LIKE '%Ayatul Kursi%'), 'evening', 1),
((SELECT id FROM journeys WHERE slug = 'evening-peace'), (SELECT id FROM duas WHERE title_en LIKE '%Evening Protection%'), 'evening', 2),
((SELECT id FROM journeys WHERE slug = 'evening-peace'), (SELECT id FROM duas WHERE title_en LIKE '%Sayyidul Istighfar%'), 'evening', 3),
((SELECT id FROM journeys WHERE slug = 'evening-peace'), (SELECT id FROM duas WHERE title_en LIKE '%Barakah%'), 'evening', 4)
ON CONFLICT (journey_id, dua_id) DO NOTHING;

-- Gratitude Builder Journey (4 duas: gratitude focus)
INSERT INTO journey_duas (journey_id, dua_id, time_slot, sort_order) VALUES
((SELECT id FROM journeys WHERE slug = 'gratitude-builder'), (SELECT id FROM duas WHERE title_en LIKE '%Sayyidul Istighfar%'), 'morning', 1),
((SELECT id FROM journeys WHERE slug = 'gratitude-builder'), (SELECT id FROM duas WHERE title_en LIKE '%Barakah%'), 'morning', 2),
((SELECT id FROM journeys WHERE slug = 'gratitude-builder'), (SELECT id FROM duas WHERE title_en LIKE '%Beneficial Knowledge%'), 'anytime', 3),
((SELECT id FROM journeys WHERE slug = 'gratitude-builder'), (SELECT id FROM duas WHERE title_en LIKE '%Prophet Yunus%'), 'evening', 4)
ON CONFLICT (journey_id, dua_id) DO NOTHING;
