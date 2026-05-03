# SearchPulse

Real-time autocomplete search — every keystroke fires a live query to PostgreSQL.  
**Go backend · PostgreSQL · React + TypeScript · Docker**

---

## Architecture

```
Browser
  │  onChange → fetch /api/suggest?q=...  (debounced 120ms, per keystroke)
  │  Enter    → fetch /api/search?q=...
  ▼
nginx :3000
  │  location /api → proxy_pass http://backend:8080
  ▼
Go :8080
  │  GET /api/suggest  →  ILIKE prefix + anywhere
  │  GET /api/search   →  ILIKE + websearch_to_tsquery + similarity()
  ▼
PostgreSQL :5432
     companies · products · innovations · trends
     GIN indexes on tsvector + pg_trgm
```

---

## Directory Structure

```
searchpulse/
├── docker-compose.yml
├── up.sh / down.sh / clean.sh
├── backend/
│   ├── Dockerfile                  # golang:1.22-alpine builder → alpine:3.19 runtime
│   ├── go.mod                      # single dep: github.com/lib/pq v1.10.9
│   ├── cmd/server/main.go          # net/http ServeMux, inline CORS
│   └── internal/
│       ├── db/db.go                # database/sql pool (20 max conns)
│       ├── handlers/handlers.go    # Health · Suggest · Search
│       └── models/models.go        # SearchResult · Suggestion · SearchResponse
├── frontend/
│   ├── Dockerfile                  # node:20 build → nginx:alpine serve
│   ├── nginx.conf                  # SPA + /api proxy
│   └── src/
│       ├── App.tsx                 # UI, dropdown, keyboard nav (↑↓ Enter Esc)
│       ├── hooks/useSearch.ts      # per-keystroke fetch, debounce, AbortController
│       ├── types/index.ts
│       └── index.css               # dark terminal theme, JetBrains Mono + Syne
└── postgres/init/
    ├── 01_schema.sql               # DDL — 4 tables, GIN indexes, tsvector columns
    └── 02_seed.sql                 # 20 companies, 20 products, 15 papers, 20 trends
```

---

## Database Schema

### Extensions

```sql
CREATE EXTENSION IF NOT EXISTS pg_trgm;   -- trigram similarity + GIN ops
CREATE EXTENSION IF NOT EXISTS unaccent;  -- accent-insensitive search
```

---

### Table: `companies`

```sql
CREATE TABLE companies (
    id                  SERIAL PRIMARY KEY,
    name                VARCHAR(255) NOT NULL,
    ticker              VARCHAR(10),             -- e.g. 'NVDA', NULL if private
    sector              VARCHAR(100),            -- e.g. 'Artificial Intelligence'
    country             VARCHAR(100),
    founded_year        INTEGER,
    market_cap_billion  DECIMAL(10,2),           -- NULL for private companies
    employee_count      INTEGER,
    description         TEXT,
    website             VARCHAR(255),
    is_public           BOOLEAN DEFAULT true,
    created_at          TIMESTAMPTZ DEFAULT NOW(),

    -- auto-generated, kept in sync by Postgres on every write
    search_vector       TSVECTOR GENERATED ALWAYS AS (
                            to_tsvector('english',
                                coalesce(name,'') || ' ' ||
                                coalesce(sector,'') || ' ' ||
                                coalesce(description,''))
                        ) STORED
);

CREATE INDEX idx_companies_name_trgm        ON companies USING GIN (name gin_trgm_ops);
CREATE INDEX idx_companies_description_trgm ON companies USING GIN (description gin_trgm_ops);
CREATE INDEX idx_companies_fts              ON companies USING GIN (search_vector);
```

**Sample data:**

| id | name | ticker | sector | country | founded | mkt_cap ($B) | employees | public |
|----|------|--------|--------|---------|---------|--------------|-----------|--------|
| 1 | Anthropic | — | Artificial Intelligence | USA | 2021 | 18.4 | 850 | ✗ |
| 2 | OpenAI | — | Artificial Intelligence | USA | 2015 | 80.0 | 1700 | ✗ |
| 3 | NVIDIA | NVDA | Semiconductors | USA | 1993 | 2200.0 | 29600 | ✓ |
| 4 | Mistral AI | — | Artificial Intelligence | France | 2023 | 6.0 | 200 | ✗ |
| 9 | Cloudflare | NET | Networking | USA | 2009 | 32.0 | 3800 | ✓ |
| 11 | Stripe | — | Fintech | USA | 2010 | 65.0 | 8000 | ✗ |

---

### Table: `products`

```sql
CREATE TABLE products (
    id                           SERIAL PRIMARY KEY,
    company_id                   INTEGER REFERENCES companies(id) ON DELETE CASCADE,
    name                         VARCHAR(255) NOT NULL,
    category                     VARCHAR(100),    -- e.g. 'Language Model', 'Hardware'
    launch_year                  INTEGER,
    version                      VARCHAR(50),
    description                  TEXT,
    tags                         TEXT[],           -- e.g. ARRAY['LLM','AI','safety']
    rating                       DECIMAL(3,2) CHECK (rating >= 0 AND rating <= 5),
    monthly_active_users_million DECIMAL(10,2),   -- NULL if not disclosed
    created_at                   TIMESTAMPTZ DEFAULT NOW(),

    search_vector                TSVECTOR GENERATED ALWAYS AS (
                                     to_tsvector('english',
                                         coalesce(name,'') || ' ' ||
                                         coalesce(category,'') || ' ' ||
                                         coalesce(description,''))
                                 ) STORED
);

CREATE INDEX idx_products_name_trgm        ON products USING GIN (name gin_trgm_ops);
CREATE INDEX idx_products_description_trgm ON products USING GIN (description gin_trgm_ops);
CREATE INDEX idx_products_fts              ON products USING GIN (search_vector);
```

**Sample data:**

| id | company | name | category | version | rating | MAU (M) | tags |
|----|---------|------|----------|---------|--------|---------|------|
| 1 | Anthropic | Claude | Language Model | 3.5 Sonnet | 4.8 | 10.0 | LLM, AI, assistant, safety |
| 2 | OpenAI | ChatGPT | AI Assistant | 4o | 4.6 | 180.0 | LLM, AI, chatbot, GPT |
| 4 | NVIDIA | H100 GPU | Hardware | SXM5 | 4.9 | — | GPU, hardware, AI, training |
| 5 | NVIDIA | CUDA | Developer Platform | 12.3 | 4.8 | — | GPU, parallel, computing, ML |
| 8 | DeepMind | AlphaFold 2 | Bioinformatics | 2.3 | 5.0 | — | biology, protein, science |
| 12 | HashiCorp | Terraform | IaC | 1.8 | 4.7 | — | IaC, DevOps, cloud |

---

### Table: `innovations`

```sql
CREATE TABLE innovations (
    id           SERIAL PRIMARY KEY,
    title        VARCHAR(500) NOT NULL,
    authors      TEXT[],         -- e.g. ARRAY['Vaswani, A.', 'Shazeer, N.']
    institution  VARCHAR(255),   -- e.g. 'Google Brain'
    year         INTEGER,
    field        VARCHAR(100),   -- e.g. 'Deep Learning', 'NLP', 'AI Safety'
    abstract     TEXT,
    citations    INTEGER DEFAULT 0,
    arxiv_id     VARCHAR(50),    -- e.g. '1706.03762', NULL if not on arXiv
    impact_score DECIMAL(5,2),   -- 0–100 composite impact rating
    created_at   TIMESTAMPTZ DEFAULT NOW(),

    search_vector TSVECTOR GENERATED ALWAYS AS (
                      to_tsvector('english',
                          coalesce(title,'') || ' ' ||
                          coalesce(field,'') || ' ' ||
                          coalesce(abstract,''))
                  ) STORED
);

CREATE INDEX idx_innovations_title_trgm ON innovations USING GIN (title gin_trgm_ops);
CREATE INDEX idx_innovations_fts        ON innovations USING GIN (search_vector);
```

**Sample data:**

| id | title | institution | year | field | citations | impact |
|----|-------|-------------|------|-------|-----------|--------|
| 1 | Attention Is All You Need | Google Brain | 2017 | Deep Learning | 98,000 | 99.9 |
| 2 | BERT: Pre-training of Deep Bidirectional Transformers | Google AI | 2018 | NLP | 45,000 | 95.2 |
| 5 | LoRA: Low-Rank Adaptation of Large Language Models | Microsoft | 2021 | NLP | 8,900 | 93.5 |
| 6 | Highly Accurate Protein Structure Prediction with AlphaFold | DeepMind | 2021 | Bioinformatics | 22,000 | 98.7 |
| 14 | Denoising Diffusion Probabilistic Models | UC Berkeley | 2020 | Generative AI | 12,000 | 96.4 |

---

### Table: `trends`

```sql
CREATE TABLE trends (
    id             SERIAL PRIMARY KEY,
    name           VARCHAR(255) NOT NULL,
    category       VARCHAR(100),  -- e.g. 'AI/ML', 'Infrastructure', 'Databases'
    momentum_score INTEGER CHECK (momentum_score >= 0 AND momentum_score <= 100),
    year_emerged   INTEGER,
    description    TEXT,
    related_tags   TEXT[],        -- e.g. ARRAY['RAG','vector-db','LLM']
    adoption_stage VARCHAR(50),   -- 'emerging' | 'growing' | 'mainstream' | 'declining'
    created_at     TIMESTAMPTZ DEFAULT NOW(),

    search_vector  TSVECTOR GENERATED ALWAYS AS (
                       to_tsvector('english',
                           coalesce(name,'') || ' ' ||
                           coalesce(category,'') || ' ' ||
                           coalesce(description,''))
                   ) STORED
);

CREATE INDEX idx_trends_name_trgm ON trends USING GIN (name gin_trgm_ops);
CREATE INDEX idx_trends_fts       ON trends USING GIN (search_vector);
```

**Sample data:**

| id | name | category | momentum | emerged | stage | tags |
|----|------|----------|----------|---------|-------|------|
| 1 | Large Language Models | AI/ML | 98 | 2020 | mainstream | GPT, transformers, NLP |
| 2 | Retrieval-Augmented Generation | AI/ML | 92 | 2021 | growing | RAG, vector-db, LLM |
| 4 | Vector Databases | Databases | 88 | 2021 | growing | embeddings, semantic-search |
| 5 | AI Agents | AI/ML | 95 | 2023 | emerging | agents, autonomy, LLM |
| 8 | Rust Language | Programming | 86 | 2016 | growing | Rust, systems, memory-safety |

---

### Index Summary

| Index | Column | Type | Used for |
|-------|--------|------|----------|
| `idx_*_fts` | `search_vector` | GIN | Full-text search, `ts_rank` scoring |
| `idx_*_name_trgm` | `name` / `title` | GIN pg_trgm | Trigram similarity scoring |
| `idx_*_description_trgm` | `description` | GIN pg_trgm | Fuzzy description search |

`search_vector` is `GENERATED ALWAYS AS ... STORED` — Postgres updates it automatically on every insert/update. Zero application-level sync required.

---

## How Live Autocomplete Works

```
user types "N"
  → onChange fires instantly
  → cancel previous debounce timer
  → abort previous in-flight fetch (AbortController)
  → sugLoading = true  →  cyan dot pulses in UI
  → wait 120ms

user types "NV"  ← within 120ms, previous timer cancelled
user types "NVI" ← same

120ms of silence
  → GET /api/suggest?q=NVI  ← real HTTP request → Go → Postgres
  → SQL runs across all 4 tables:
      WHERE name ILIKE 'NVI%'    (prefix, ranked 2)
         OR name ILIKE '%NVI%'   (anywhere, ranked 1)
      UNION ALL products ... UNION ALL trends ... UNION ALL innovations
      ORDER BY rank DESC, length(text) ASC
      LIMIT 8
  → JSON array → browser → dropdown renders live
  → sugLoading = false

user picks "NVIDIA" or presses Enter
  → GET /api/search?q=NVIDIA  ← full ranked search
  → ILIKE + websearch_to_tsquery + similarity() across all tables
  → result cards render
```

No data is pre-loaded to the frontend. Verify in DevTools → Network:  
a fresh `/api/suggest?q=...` request fires on every keystroke.

---

## API Reference

### `GET /api/health`
```json
{ "status": "healthy" }
```

### `GET /api/suggest?q=<query>`
Returns up to 8 suggestions. Prefix matches ranked above anywhere matches.

```json
[
  { "text": "NVIDIA",         "kind": "company", "subtitle": "Semiconductors · USA" },
  { "text": "NVIDIA H100 GPU","kind": "product",  "subtitle": "Hardware · NVIDIA"   }
]
```

### `GET /api/search?q=<query>`
Returns up to 20 results ranked by `GREATEST(similarity, ts_rank)`.

```json
{
  "query":       "transformer",
  "total_count": 8,
  "elapsed_ms":  6,
  "results": [{
    "id":          1,
    "kind":        "innovation",
    "title":       "Attention Is All You Need",
    "subtitle":    "Deep Learning · Google Brain",
    "description": "Introduces the Transformer architecture...",
    "badge":       "2017",
    "meta": [
      { "label": "Citations", "value": "98000"      },
      { "label": "Impact",    "value": "99.9"       },
      { "label": "arXiv",     "value": "1706.03762" }
    ],
    "score": 0.91,
    "tags":  []
  }]
}
```

---

## Quick Start

```bash
./up.sh        # docker compose up --build, polls until backend healthy
               # → http://localhost:3000

./down.sh      # stop containers, preserve postgres volume
./clean.sh     # full teardown + kill ports 3000 / 8080 / 5432
```

Requires Docker with Compose V2. Ports 3000, 8080, 5432 must be free.

---

## Try These Searches

| Type | What to try | Finds |
|------|-------------|-------|
| Prefix (2 chars) | `nv` | NVIDIA instantly |
| Prefix (3 chars) | `alp` | AlphaFold paper + product |
| Full word | `transformer` | "Attention Is All You Need" + trend |
| Acronym | `rag` | RAG trend + paper |
| Tag search | `lora` | LoRA fine-tuning paper |
| Multi-word | `vector database` | Weaviate, Qdrant, vector DB trend |
| Company | `claude` | Anthropic + Claude product |

---

## Tech Stack

| Layer | Tech |
|-------|------|
| Frontend | React 18 · TypeScript · Vite |
| Styling | Pure CSS · JetBrains Mono + Syne · dark terminal |
| Backend | Go 1.22 · `net/http` · `database/sql` · `lib/pq` |
| Database | PostgreSQL 16 · `pg_trgm` · `tsvector` GIN indexes |
| Proxy | nginx — SPA + `/api` reverse proxy |
| Containers | Docker + Compose V2 |
