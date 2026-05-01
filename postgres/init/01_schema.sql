-- SearchPulse Database Schema
-- A rich dataset of tech companies, products, and innovations

CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS unaccent;

-- Companies table
CREATE TABLE companies (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    ticker VARCHAR(10),
    sector VARCHAR(100),
    country VARCHAR(100),
    founded_year INTEGER,
    market_cap_billion DECIMAL(10,2),
    employee_count INTEGER,
    description TEXT,
    website VARCHAR(255),
    is_public BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Products / Technologies
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    company_id INTEGER REFERENCES companies(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100),
    launch_year INTEGER,
    version VARCHAR(50),
    description TEXT,
    tags TEXT[],
    rating DECIMAL(3,2) CHECK (rating >= 0 AND rating <= 5),
    monthly_active_users_million DECIMAL(10,2),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Innovations / Research Papers
CREATE TABLE innovations (
    id SERIAL PRIMARY KEY,
    title VARCHAR(500) NOT NULL,
    authors TEXT[],
    institution VARCHAR(255),
    year INTEGER,
    field VARCHAR(100),
    abstract TEXT,
    citations INTEGER DEFAULT 0,
    arxiv_id VARCHAR(50),
    impact_score DECIMAL(5,2),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tech Trends
CREATE TABLE trends (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100),
    momentum_score INTEGER CHECK (momentum_score >= 0 AND momentum_score <= 100),
    year_emerged INTEGER,
    description TEXT,
    related_tags TEXT[],
    adoption_stage VARCHAR(50), -- 'emerging', 'growing', 'mainstream', 'declining'
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- GIN indexes for fast full-text + trigram search
CREATE INDEX idx_companies_name_trgm ON companies USING GIN (name gin_trgm_ops);
CREATE INDEX idx_companies_description_trgm ON companies USING GIN (description gin_trgm_ops);
CREATE INDEX idx_products_name_trgm ON products USING GIN (name gin_trgm_ops);
CREATE INDEX idx_products_description_trgm ON products USING GIN (description gin_trgm_ops);
CREATE INDEX idx_innovations_title_trgm ON innovations USING GIN (title gin_trgm_ops);
CREATE INDEX idx_trends_name_trgm ON trends USING GIN (name gin_trgm_ops);

-- Full-text search vectors
ALTER TABLE companies ADD COLUMN search_vector tsvector
    GENERATED ALWAYS AS (
        to_tsvector('english', coalesce(name,'') || ' ' || coalesce(sector,'') || ' ' || coalesce(description,''))
    ) STORED;
CREATE INDEX idx_companies_fts ON companies USING GIN(search_vector);

ALTER TABLE products ADD COLUMN search_vector tsvector
    GENERATED ALWAYS AS (
        to_tsvector('english', coalesce(name,'') || ' ' || coalesce(category,'') || ' ' || coalesce(description,''))
    ) STORED;
CREATE INDEX idx_products_fts ON products USING GIN(search_vector);

ALTER TABLE innovations ADD COLUMN search_vector tsvector
    GENERATED ALWAYS AS (
        to_tsvector('english', coalesce(title,'') || ' ' || coalesce(field,'') || ' ' || coalesce(abstract,''))
    ) STORED;
CREATE INDEX idx_innovations_fts ON innovations USING GIN(search_vector);

ALTER TABLE trends ADD COLUMN search_vector tsvector
    GENERATED ALWAYS AS (
        to_tsvector('english', coalesce(name,'') || ' ' || coalesce(category,'') || ' ' || coalesce(description,''))
    ) STORED;
CREATE INDEX idx_trends_fts ON trends USING GIN(search_vector);
