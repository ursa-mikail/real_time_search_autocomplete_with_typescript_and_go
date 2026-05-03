CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS unaccent;

-- SearchPulse — People Edition
-- Same 4-table structure the existing handlers already query.
-- companies  → people profiles
-- products   → their open-source projects
-- innovations→ their blog posts / papers
-- trends     → skills trending in the community

-- ── companies → people ────────────────────────────────────────────────────────
CREATE TABLE companies (
    id                  SERIAL PRIMARY KEY,
    name                VARCHAR(255) NOT NULL,  -- full name  "Alice Chen"
    ticker              VARCHAR(60),            -- @handle    "alice_chen"
    sector              VARCHAR(100),           -- job title  "Principal Engineer"
    country             VARCHAR(100),           -- employer   "Anthropic"
    founded_year        INTEGER,                -- year joined community
    market_cap_billion  DECIMAL(10,2),          -- reputation (stored as decimal)
    employee_count      INTEGER,                -- follower count
    description         TEXT,                   -- bio
    website             VARCHAR(255),           -- github / portfolio
    is_public           BOOLEAN DEFAULT true,   -- true=verified, false=unverified
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    search_vector TSVECTOR GENERATED ALWAYS AS (
        to_tsvector('english',
            coalesce(name,'')        || ' ' ||
            coalesce(ticker,'')      || ' ' ||
            coalesce(sector,'')      || ' ' ||
            coalesce(country,'')     || ' ' ||
            coalesce(description,''))
    ) STORED
);
CREATE INDEX idx_companies_name_trgm        ON companies USING GIN (name gin_trgm_ops);
CREATE INDEX idx_companies_description_trgm ON companies USING GIN (description gin_trgm_ops);
CREATE INDEX idx_companies_fts              ON companies USING GIN (search_vector);

-- ── products → open-source projects ──────────────────────────────────────────
CREATE TABLE products (
    id                           SERIAL PRIMARY KEY,
    company_id                   INTEGER REFERENCES companies(id) ON DELETE CASCADE,
    name                         VARCHAR(255) NOT NULL,  -- repo / project name
    category                     VARCHAR(100),           -- "Rust · CLI", "Python · ML"
    launch_year                  INTEGER,
    version                      VARCHAR(50),            -- latest release tag
    description                  TEXT,
    tags                         TEXT[],
    rating                       DECIMAL(3,2),           -- community rating 0-5
    monthly_active_users_million DECIMAL(10,2),          -- GitHub stars ÷ 1000
    created_at                   TIMESTAMPTZ DEFAULT NOW(),
    search_vector TSVECTOR GENERATED ALWAYS AS (
        to_tsvector('english',
            coalesce(name,'')     || ' ' ||
            coalesce(category,'') || ' ' ||
            coalesce(description,''))
    ) STORED
);
CREATE INDEX idx_products_name_trgm        ON products USING GIN (name gin_trgm_ops);
CREATE INDEX idx_products_description_trgm ON products USING GIN (description gin_trgm_ops);
CREATE INDEX idx_products_fts              ON products USING GIN (search_vector);

-- ── innovations → blog posts / papers ────────────────────────────────────────
CREATE TABLE innovations (
    id           SERIAL PRIMARY KEY,
    title        VARCHAR(500) NOT NULL,
    authors      TEXT[],           -- @handle of author(s)
    institution  VARCHAR(255),     -- platform: "dev.to", "arXiv", "Medium"
    year         INTEGER,
    field        VARCHAR(100),     -- topic: "Distributed Systems", "AI Safety"
    abstract     TEXT,             -- post excerpt / paper abstract
    citations    INTEGER DEFAULT 0,-- upvotes / citations
    arxiv_id     VARCHAR(50),      -- url slug or arXiv id
    impact_score DECIMAL(5,2),     -- engagement score 0-100
    created_at   TIMESTAMPTZ DEFAULT NOW(),
    search_vector TSVECTOR GENERATED ALWAYS AS (
        to_tsvector('english',
            coalesce(title,'')    || ' ' ||
            coalesce(field,'')    || ' ' ||
            coalesce(abstract,''))
    ) STORED
);
CREATE INDEX idx_innovations_title_trgm ON innovations USING GIN (title gin_trgm_ops);
CREATE INDEX idx_innovations_fts        ON innovations USING GIN (search_vector);

-- ── trends → skills trending in the community ─────────────────────────────────
CREATE TABLE trends (
    id             SERIAL PRIMARY KEY,
    name           VARCHAR(255) NOT NULL,
    category       VARCHAR(100),
    momentum_score INTEGER CHECK (momentum_score >= 0 AND momentum_score <= 100),
    year_emerged   INTEGER,
    description    TEXT,
    related_tags   TEXT[],
    adoption_stage VARCHAR(50),
    created_at     TIMESTAMPTZ DEFAULT NOW(),
    search_vector TSVECTOR GENERATED ALWAYS AS (
        to_tsvector('english',
            coalesce(name,'')        || ' ' ||
            coalesce(category,'')    || ' ' ||
            coalesce(description,''))
    ) STORED
);
CREATE INDEX idx_trends_name_trgm ON trends USING GIN (name gin_trgm_ops);
CREATE INDEX idx_trends_fts       ON trends USING GIN (search_vector);
