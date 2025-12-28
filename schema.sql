-- Create Categories Table
CREATE TABLE IF NOT EXISTS categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    slug VARCHAR(255) NOT NULL UNIQUE,
    description TEXT
);

-- Create Collections Table
CREATE TABLE IF NOT EXISTS collections (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    slug VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    is_premium BOOLEAN DEFAULT FALSE
);

-- Create Duas Table
CREATE TABLE IF NOT EXISTS duas (
    id SERIAL PRIMARY KEY,
    category_id INTEGER REFERENCES categories(id),
    collection_id INTEGER REFERENCES collections(id),
    title_en VARCHAR(255) NOT NULL,
    title_ar VARCHAR(255),
    arabic_text TEXT NOT NULL,
    transliteration TEXT,
    translation_en TEXT,
    source VARCHAR(255),
    repetitions INTEGER DEFAULT 1,
    best_time VARCHAR(255),
    difficulty VARCHAR(50), -- Beginner, Intermediate, Advanced
    est_duration_sec INTEGER,
    rizq_benefit TEXT,
    prophetic_context TEXT, -- Historical background: when Prophet ﷺ recommended it, hadith quotes, circumstances
    xp_value INTEGER DEFAULT 10,
    audio_url VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create Indexes
CREATE INDEX idx_duas_category_id ON duas(category_id);
CREATE INDEX idx_duas_collection_id ON duas(collection_id);

-- Create Journeys Table (pre-built paths users can subscribe to)
CREATE TABLE IF NOT EXISTS journeys (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    emoji VARCHAR(10) DEFAULT '📿',
    estimated_minutes INTEGER DEFAULT 15,
    daily_xp INTEGER DEFAULT 100,
    is_premium BOOLEAN DEFAULT FALSE,
    is_featured BOOLEAN DEFAULT FALSE,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create Journey Duas Table (links journeys to their duas with time slots)
CREATE TABLE IF NOT EXISTS journey_duas (
    id SERIAL PRIMARY KEY,
    journey_id INTEGER REFERENCES journeys(id) ON DELETE CASCADE,
    dua_id INTEGER REFERENCES duas(id) ON DELETE CASCADE,
    time_slot VARCHAR(50) NOT NULL, -- 'morning', 'anytime', 'evening'
    sort_order INTEGER DEFAULT 0,
    UNIQUE(journey_id, dua_id)
);

-- Create Indexes for Journey Tables
CREATE INDEX idx_journey_duas_journey_id ON journey_duas(journey_id);
CREATE INDEX idx_journey_duas_dua_id ON journey_duas(dua_id);
CREATE INDEX idx_journeys_slug ON journeys(slug);
CREATE INDEX idx_journeys_featured ON journeys(is_featured);
