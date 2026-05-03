# SearchPulse

Real-time autocomplete search — every keystroke fires a live query to PostgreSQL.  
**Go backend · PostgreSQL · React + TypeScript · Docker**

---

## Architecture

```
Browser
  │  onChange → fetch /api/suggest?q=...  (every 120ms debounce)
  │  Enter    → fetch /api/search?q=...
  ▼
nginx :3000
  │  location /api → proxy_pass http://backend:8080
  ▼
Go :8080
  │  GET /api/suggest  →  ILIKE prefix + anywhere query
  │  GET /api/search   →  ILIKE + websearch_to_tsquery + similarity()
  ▼
PostgreSQL :5432
     companies · products · innovations · trends
     GIN indexes on tsvector columns
     pg_trgm extension
```

---

## Directory Structure

```
searchpulse/
├── docker-compose.yml
├── up.sh / down.sh / clean.sh
│
├── backend/
│   ├── Dockerfile                        # golang:1.22-alpine builder → alpine:3.19 runtime
│   ├── go.mod                            # single dep: github.com/lib/pq v1.10.9
│   └── cmd/server/main.go               # net/http ServeMux, inline CORS
│   └── internal/
│       ├── db/db.go                      # database/sql pool
│       ├── handlers/handlers.go          # Health, Suggest, Search
│       └── models/models.go             # SearchResult, Suggestion, SearchResponse
│
├── frontend/
│   ├── Dockerfile                        # node:20 build → nginx:alpine serve
│   ├── nginx.conf                        # SPA + /api proxy (no trailing slash)
│   └── src/
│       ├── App.tsx                       # UI, dropdown, keyboard nav
│       ├── hooks/useSearch.ts            # per-keystroke fetch, debounce, abort
│       ├── types/index.ts
│       └── index.css                     # dark terminal theme
│
└── postgres/init/
    ├── 01_schema.sql                     # 4 tables + GIN + tsvector indexes
    └── 02_seed.sql                       # 20 companies, 20 products, 15 papers, 20 trends
```

---

## Quick Start

```bash
./up.sh        # docker compose up --build, waits for healthy backend
               # → http://localhost:3000

./down.sh      # stop, preserve data
./clean.sh     # full teardown + free ports 3000 / 8080 / 5432
```

Requires Docker with Compose V2. Ports 3000, 8080, 5432 must be free.

---

## Database Schema

### `companies`
| Column | Type | Notes |
|---|---|---|
| id | SERIAL PK | |
| name | VARCHAR | GIN trigram index |
| ticker | VARCHAR | nullable |
| sector | VARCHAR | e.g. "Artificial Intelligence" |
| country | VARCHAR | |
| founded_year | INTEGER | |
| market_cap_billion | DECIMAL | nullable for private |
| employee_count | INTEGER | |
| description | TEXT | full-text indexed |
| website | VARCHAR | |
| is_public | BOOLEAN | |
| search_vector | TSVECTOR | auto-generated, GIN indexed |

### `products`
| Column | Type | Notes |
|---|---|---|
| id | SERIAL PK | |
| company_id | INTEGER FK | → companies |
| name | VARCHAR | |
| category | VARCHAR | e.g. "Language Model" |
| launch_year | INTEGER | |
| version | VARCHAR | |
| description | TEXT | full-text indexed |
| tags | TEXT[] | searchable array |
| rating | DECIMAL(3,2) | 0–5 |
| monthly_active_users_million | DECIMAL | |
| search_vector | TSVECTOR | auto-generated |

### `innovations`
| Column | Type | Notes |
|---|---|---|
| id | SERIAL PK | |
| title | VARCHAR | |
| authors | TEXT[] | |
| institution | VARCHAR | |
| year | INTEGER | |
| field | VARCHAR | e.g. "Deep Learning" |
| abstract | TEXT | full-text indexed |
| citations | INTEGER | |
| arxiv_id | VARCHAR | |
| impact_score | DECIMAL(5,2) | 0–100 |
| search_vector | TSVECTOR | auto-generated |

### `trends`
| Column | Type | Notes |
|---|---|---|
| id | SERIAL PK | |
| name | VARCHAR | |
| category | VARCHAR | e.g. "AI/ML", "Infrastructure" |
| momentum_score | INTEGER | 0–100 |
| year_emerged | INTEGER | |
| description | TEXT | full-text indexed |
| related_tags | TEXT[] | searchable array |
| adoption_stage | VARCHAR | emerging / growing / mainstream / declining |
| search_vector | TSVECTOR | auto-generated |

---

## API

### `GET /api/health`
```json
{ "status": "healthy" }
```

### `GET /api/suggest?q=<query>`
Fires on every keystroke. Returns up to 8 suggestions across all tables.  
Uses `ILIKE 'q%'` (prefix, ranked higher) + `ILIKE '%q%'` (anywhere).

```json
[
  { "text": "NVIDIA", "kind": "company", "subtitle": "Semiconductors · USA" },
  { "text": "NVIDIA H100 GPU", "kind": "product", "subtitle": "Hardware · NVIDIA" }
]
```

### `GET /api/search?q=<query>`
Full ranked search. Combines `ILIKE`, `websearch_to_tsquery`, and `similarity()`.  
Returns up to 20 results sorted by relevance score.

```json
{
  "query": "transformer",
  "results": [
    {
      "id": 1,
      "kind": "innovation",
      "title": "Attention Is All You Need",
      "subtitle": "Deep Learning · Google Brain",
      "description": "Introduces the Transformer architecture...",
      "badge": "2017",
      "meta": [
        { "label": "Citations", "value": "98000" },
        { "label": "Impact",   "value": "99.9"  },
        { "label": "arXiv",    "value": "1706.03762" }
      ],
      "score": 0.91,
      "tags": []
    }
  ],
  "total_count": 8,
  "elapsed_ms": 6
}
```

---

## How Live Autocomplete Works

```
keystroke fires
      │
      ▼
setQuery(value)
  ├─ cancel previous debounce timer
  ├─ abort previous in-flight fetch (AbortController)
  ├─ set sugLoading = true  →  cyan dot pulses in UI
  └─ start 120ms debounce
          │
          ▼ (after 120ms of no typing)
      fetch /api/suggest?q=value
          │
          ▼
      Go handler → SQL: ILIKE prefix + anywhere across 4 tables
          │
          ▼
      JSON array → setSugs(list) → setOpen(true)
      sugLoading = false  →  dot goes solid, count shown
```

No data is pre-loaded to the frontend. Every suggestion list comes from a
fresh Postgres query. You can verify in DevTools → Network — a new
`/api/suggest?q=...` request fires on every keystroke.

---

## Search Strategy

| Method | Used for | PostgreSQL feature |
|---|---|---|
| Prefix match | Autocomplete — `"NV"` → `"NVIDIA"` | `ILIKE 'q%'` |
| Anywhere match | Autocomplete fallback | `ILIKE '%q%'` |
| Full-text search | Stemming, natural language | `websearch_to_tsquery` + `tsvector` GIN |
| Trigram similarity | Fuzzy ranking score | `similarity()` from `pg_trgm` |

Results are ranked by `GREATEST(similarity_score, ts_rank)` across all four tables in a single `UNION ALL` query.

---

## Try These Searches

| Query | Finds |
|---|---|
| `nv` | NVIDIA (prefix match kicks in immediately) |
| `transformer` | "Attention Is All You Need" paper + trend |
| `alpha` | AlphaFold paper, AlphaFold product |
| `rag` | Retrieval-Augmented Generation trend + paper |
| `rust` | Rust language trend |
| `claude` | Anthropic + Claude product |
| `diffusion` | DDPM paper + Stable Diffusion |
| `lora` | LoRA fine-tuning paper |
| `edge` | Edge computing trend + Cloudflare Workers |
| `vector` | Vector database trend + Weaviate + Qdrant |

---

## Local Dev (without Docker)

**Postgres:**
```bash
docker run -d --name sp-db \
  -e POSTGRES_USER=searchpulse \
  -e POSTGRES_PASSWORD=searchpulse \
  -e POSTGRES_DB=searchpulse \
  -p 5432:5432 \
  -v $(pwd)/postgres/init:/docker-entrypoint-initdb.d \
  postgres:16-alpine
```

**Backend:**
```bash
cd backend
go run ./cmd/server
# API at http://localhost:8080
```

**Frontend:**
```bash
cd frontend
npm install && npm run dev
# UI at http://localhost:5173
# vite.config.ts proxies /api → localhost:8080
```

---

## Tech Stack

| Layer | Tech |
|---|---|
| Frontend | React 18, TypeScript, Vite |
| Styling | Pure CSS — JetBrains Mono + Syne, dark terminal theme |
| Backend | Go 1.22, `net/http`, `database/sql`, `lib/pq` |
| Database | PostgreSQL 16, `pg_trgm`, `tsvector` GIN indexes |
| Proxy | nginx — serves SPA, proxies `/api` to Go |
| Containers | Docker + Compose V2 |
