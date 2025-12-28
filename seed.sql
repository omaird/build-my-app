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
    rizq_benefit, xp_value, collection_id, category_id
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
    50,
    (SELECT id FROM collections WHERE slug = 'core'),
    (SELECT id FROM categories WHERE slug = 'morning')
);

-- 2. Morning Protection Dua
INSERT INTO duas (
    title_en, title_ar, arabic_text, transliteration, translation_en, 
    source, repetitions, best_time, difficulty, est_duration_sec, 
    rizq_benefit, xp_value, collection_id, category_id
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
    30,
    (SELECT id FROM collections WHERE slug = 'core'),
    (SELECT id FROM categories WHERE slug = 'morning')
);

-- 3. Dua Upon Leaving Home
INSERT INTO duas (
    title_en, title_ar, arabic_text, transliteration, translation_en, 
    source, repetitions, best_time, difficulty, est_duration_sec, 
    rizq_benefit, xp_value, collection_id, category_id
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
    15,
    (SELECT id FROM collections WHERE slug = 'core'),
    (SELECT id FROM categories WHERE slug = 'morning')
);

-- 4. Sayyidul Istighfar
INSERT INTO duas (
    title_en, title_ar, arabic_text, transliteration, translation_en, 
    source, repetitions, best_time, difficulty, est_duration_sec, 
    rizq_benefit, xp_value, collection_id, category_id
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
    40,
    (SELECT id FROM collections WHERE slug = 'core'),
    (SELECT id FROM categories WHERE slug = 'rizq')
);

-- 5. Dua for Halal Provision
INSERT INTO duas (
    title_en, title_ar, arabic_text, transliteration, translation_en, 
    source, repetitions, best_time, difficulty, est_duration_sec, 
    rizq_benefit, xp_value, collection_id, category_id
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
    25,
    (SELECT id FROM collections WHERE slug = 'core'),
    (SELECT id FROM categories WHERE slug = 'rizq')
);

-- 6. Evening Protection Dua
INSERT INTO duas (
    title_en, title_ar, arabic_text, transliteration, translation_en,
    source, repetitions, best_time, difficulty, est_duration_sec,
    rizq_benefit, xp_value, collection_id, category_id
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
    30,
    (SELECT id FROM collections WHERE slug = 'core'),
    (SELECT id FROM categories WHERE slug = 'evening')
);

-- 7. Dua for Relief from Debt
INSERT INTO duas (
    title_en, title_ar, arabic_text, transliteration, translation_en,
    source, repetitions, best_time, difficulty, est_duration_sec,
    rizq_benefit, xp_value, collection_id, category_id
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
    35,
    (SELECT id FROM collections WHERE slug = 'core'),
    (SELECT id FROM categories WHERE slug = 'rizq')
);

-- 8. Dua for Beneficial Knowledge & Provision
INSERT INTO duas (
    title_en, title_ar, arabic_text, transliteration, translation_en,
    source, repetitions, best_time, difficulty, est_duration_sec,
    rizq_benefit, xp_value, collection_id, category_id
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
    30,
    (SELECT id FROM collections WHERE slug = 'core'),
    (SELECT id FROM categories WHERE slug = 'morning')
);

-- 9. Dua for Barakah in Provision
INSERT INTO duas (
    title_en, title_ar, arabic_text, transliteration, translation_en,
    source, repetitions, best_time, difficulty, est_duration_sec,
    rizq_benefit, xp_value, collection_id, category_id
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
    15,
    (SELECT id FROM collections WHERE slug = 'core'),
    (SELECT id FROM categories WHERE slug = 'gratitude')
);

-- 10. Dua of Prophet Yunus (Distress to Relief)
INSERT INTO duas (
    title_en, title_ar, arabic_text, transliteration, translation_en,
    source, repetitions, best_time, difficulty, est_duration_sec,
    rizq_benefit, xp_value, collection_id, category_id
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
    25,
    (SELECT id FROM collections WHERE slug = 'core'),
    (SELECT id FROM categories WHERE slug = 'rizq')
);

-- =============================================================================
-- JOURNEYS SEED DATA
-- =============================================================================

-- Insert Journeys
INSERT INTO journeys (name, slug, description, emoji, estimated_minutes, daily_xp, is_premium, is_featured, sort_order) VALUES
('Rizq Seeker', 'rizq-seeker', 'Increase your provision and blessings through powerful duas for wealth and abundance.', '🌙', 15, 270, FALSE, TRUE, 1),
('Morning Warrior', 'morning-warrior', 'Start every day with purpose through essential morning adhkar and protection.', '🌅', 12, 250, FALSE, TRUE, 2),
('Debt Freedom', 'debt-freedom', 'Find relief from debt and financial stress through targeted supplications.', '💳', 10, 125, FALSE, TRUE, 3),
('Evening Peace', 'evening-peace', 'End each day in gratitude and protection with evening remembrance.', '🌙', 10, 195, FALSE, FALSE, 4),
('Gratitude Builder', 'gratitude-builder', 'Cultivate a thankful heart and abundance mindset.', '🙏', 10, 155, FALSE, FALSE, 5)
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
