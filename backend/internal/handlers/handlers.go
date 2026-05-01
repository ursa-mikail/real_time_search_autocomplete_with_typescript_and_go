package handlers

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strings"
	"time"

	"github.com/searchpulse/backend/internal/models"
)

type Handler struct{ db *sql.DB }

func New(db *sql.DB) *Handler { return &Handler{db: db} }

// ── Health ────────────────────────────────────────────────────────────────────

func (h *Handler) Health(w http.ResponseWriter, r *http.Request) {
	if err := h.db.Ping(); err != nil {
		writeJSON(w, 503, map[string]string{"status": "unhealthy", "error": err.Error()})
		return
	}
	writeJSON(w, 200, map[string]string{"status": "healthy"})
}

// ── Suggest ───────────────────────────────────────────────────────────────────

func (h *Handler) Suggest(w http.ResponseWriter, r *http.Request) {
	q := strings.TrimSpace(r.URL.Query().Get("q"))
	if q == "" {
		writeJSON(w, 200, []models.Suggestion{})
		return
	}
	out, err := h.suggest(q)
	if err != nil {
		log.Printf("suggest q=%q err=%v", q, err)
		writeJSON(w, 200, []models.Suggestion{}) // never break the UI
		return
	}
	writeJSON(w, 200, out)
}

func (h *Handler) suggest(q string) ([]models.Suggestion, error) {
	prefix  := q + "%"
	anywhere := "%" + q + "%"

	// Uses only ILIKE — works for any length query, always returns results.
	// Prefix matches ranked higher than anywhere matches.
	const sqlQ = `
		SELECT text, kind, subtitle, rank FROM (
			SELECT
				name                                                      AS text,
				'company'                                                 AS kind,
				COALESCE(sector, '') || ' · ' || COALESCE(country, '')   AS subtitle,
				CASE WHEN name ILIKE $1 THEN 2 ELSE 1 END                AS rank
			FROM companies
			WHERE name ILIKE $1 OR name ILIKE $2

			UNION ALL

			SELECT
				p.name                                                    AS text,
				'product'                                                 AS kind,
				COALESCE(p.category,'') || ' · ' || COALESCE(c.name,'') AS subtitle,
				CASE WHEN p.name ILIKE $1 THEN 2 ELSE 1 END              AS rank
			FROM products p
			LEFT JOIN companies c ON c.id = p.company_id
			WHERE p.name ILIKE $1 OR p.name ILIKE $2

			UNION ALL

			SELECT
				name                                                      AS text,
				'trend'                                                   AS kind,
				COALESCE(category,'') || ' · ' || COALESCE(adoption_stage,'') AS subtitle,
				CASE WHEN name ILIKE $1 THEN 2 ELSE 1 END                AS rank
			FROM trends
			WHERE name ILIKE $1 OR name ILIKE $2

			UNION ALL

			SELECT
				title                                                     AS text,
				'innovation'                                              AS kind,
				COALESCE(field,'') || ' · ' || year::text                AS subtitle,
				CASE WHEN title ILIKE $1 THEN 2 ELSE 1 END               AS rank
			FROM innovations
			WHERE title ILIKE $1 OR title ILIKE $2
		) t
		ORDER BY rank DESC, length(text) ASC
		LIMIT 8
	`
	rows, err := h.db.Query(sqlQ, prefix, anywhere)
	if err != nil {
		return nil, fmt.Errorf("suggest query: %w", err)
	}
	defer rows.Close()

	var out []models.Suggestion
	for rows.Next() {
		var s models.Suggestion
		var rank int // discard
		if err := rows.Scan(&s.Text, &s.Kind, &s.Subtitle, &rank); err == nil {
			out = append(out, s)
		}
	}
	if out == nil {
		out = []models.Suggestion{}
	}
	return out, nil
}

// ── Search ────────────────────────────────────────────────────────────────────

func (h *Handler) Search(w http.ResponseWriter, r *http.Request) {
	q := strings.TrimSpace(r.URL.Query().Get("q"))
	if q == "" {
		writeJSON(w, 400, map[string]string{"error": "q required"})
		return
	}
	start := time.Now()
	results, err := h.search(q)
	if err != nil {
		log.Printf("search q=%q err=%v", q, err)
		writeJSON(w, 500, map[string]string{"error": err.Error()})
		return
	}
	writeJSON(w, 200, models.SearchResponse{
		Query:      q,
		Results:    results,
		TotalCount: len(results),
		ElapsedMs:  time.Since(start).Milliseconds(),
	})
}

func (h *Handler) search(q string) ([]models.SearchResult, error) {
	like := "%" + q + "%"

	// websearch_to_tsquery is safe for any user input — no panics on short/special strings.
	// Every column in the inner SELECTs has an explicit AS alias so the outer
	// SELECT id, kind, title, ... can reference them by name.
	const sqlQ = `
		SELECT id, kind, title, subtitle, description, badge, meta, score, tags
		FROM (

			SELECT
				c.id                          AS id,
				'company'                     AS kind,
				c.name                        AS title,
				COALESCE(c.sector,'') || ' · ' || COALESCE(c.country,'') AS subtitle,
				COALESCE(c.description,'')    AS description,
				CASE WHEN c.is_public
					THEN 'PUBLIC' || CASE WHEN c.ticker IS NOT NULL THEN ' · ' || c.ticker ELSE '' END
					ELSE 'PRIVATE'
				END                           AS badge,
				json_build_array(
					json_build_object('label','Founded',    'value', COALESCE(c.founded_year::text,  'N/A')),
					json_build_object('label','Employees',  'value', COALESCE(c.employee_count::text,'N/A')),
					json_build_object('label','Market Cap', 'value',
						CASE WHEN c.market_cap_billion IS NOT NULL
							THEN '$' || c.market_cap_billion::text || 'B'
							ELSE 'Private' END)
				)::text                       AS meta,
				GREATEST(
					similarity(c.name, $1),
					ts_rank(c.search_vector, websearch_to_tsquery('english', $1))
				)                             AS score,
				'[]'::text                    AS tags
			FROM companies c
			WHERE c.name ILIKE $2
			   OR c.description ILIKE $2
			   OR c.search_vector @@ websearch_to_tsquery('english', $1)

			UNION ALL

			SELECT
				p.id                          AS id,
				'product'                     AS kind,
				p.name                        AS title,
				COALESCE(p.category,'') || ' · ' || COALESCE(c.name,'') AS subtitle,
				COALESCE(p.description,'')    AS description,
				COALESCE(p.version,'')        AS badge,
				json_build_array(
					json_build_object('label','Launched','value', COALESCE(p.launch_year::text,'N/A')),
					json_build_object('label','Rating',  'value',
						CASE WHEN p.rating IS NOT NULL THEN p.rating::text || '/5' ELSE 'N/A' END),
					json_build_object('label','MAU',     'value',
						CASE WHEN p.monthly_active_users_million IS NOT NULL
							THEN p.monthly_active_users_million::text || 'M'
							ELSE 'N/A' END)
				)::text                       AS meta,
				GREATEST(
					similarity(p.name, $1),
					ts_rank(p.search_vector, websearch_to_tsquery('english', $1))
				)                             AS score,
				COALESCE(array_to_json(p.tags)::text, '[]') AS tags
			FROM products p
			LEFT JOIN companies c ON c.id = p.company_id
			WHERE p.name ILIKE $2
			   OR p.description ILIKE $2
			   OR array_to_string(p.tags, ' ') ILIKE $2
			   OR p.search_vector @@ websearch_to_tsquery('english', $1)

			UNION ALL

			SELECT
				i.id                          AS id,
				'innovation'                  AS kind,
				i.title                       AS title,
				COALESCE(i.field,'') || ' · ' || COALESCE(i.institution,'') AS subtitle,
				COALESCE(i.abstract,'')       AS description,
				i.year::text                  AS badge,
				json_build_array(
					json_build_object('label','Citations','value', COALESCE(i.citations::text,'0')),
					json_build_object('label','Impact',   'value', COALESCE(i.impact_score::text,'N/A')),
					json_build_object('label','arXiv',    'value', COALESCE(i.arxiv_id,'N/A'))
				)::text                       AS meta,
				GREATEST(
					similarity(i.title, $1),
					ts_rank(i.search_vector, websearch_to_tsquery('english', $1))
				)                             AS score,
				'[]'::text                    AS tags
			FROM innovations i
			WHERE i.title ILIKE $2
			   OR i.abstract ILIKE $2
			   OR i.search_vector @@ websearch_to_tsquery('english', $1)

			UNION ALL

			SELECT
				t.id                          AS id,
				'trend'                       AS kind,
				t.name                        AS title,
				COALESCE(t.category,'') || ' · ' || COALESCE(t.adoption_stage,'') AS subtitle,
				COALESCE(t.description,'')    AS description,
				'MOMENTUM ' || t.momentum_score::text AS badge,
				json_build_array(
					json_build_object('label','Emerged','value', COALESCE(t.year_emerged::text,'N/A')),
					json_build_object('label','Stage',  'value', COALESCE(t.adoption_stage,'N/A')),
					json_build_object('label','Score',  'value', t.momentum_score::text || '/100')
				)::text                       AS meta,
				GREATEST(
					similarity(t.name, $1),
					ts_rank(t.search_vector, websearch_to_tsquery('english', $1))
				)                             AS score,
				COALESCE(array_to_json(t.related_tags)::text, '[]') AS tags
			FROM trends t
			WHERE t.name ILIKE $2
			   OR t.description ILIKE $2
			   OR array_to_string(t.related_tags, ' ') ILIKE $2
			   OR t.search_vector @@ websearch_to_tsquery('english', $1)

		) combined
		ORDER BY score DESC
		LIMIT 20
	`
	rows, err := h.db.Query(sqlQ, q, like)
	if err != nil {
		return nil, fmt.Errorf("search query: %w", err)
	}
	defer rows.Close()

	var out []models.SearchResult
	for rows.Next() {
		var r models.SearchResult
		var meta, tags string
		if err := rows.Scan(
			&r.ID, &r.Kind, &r.Title, &r.Subtitle,
			&r.Description, &r.Badge, &meta, &r.Score, &tags,
		); err != nil {
			log.Printf("scan: %v", err)
			continue
		}
		if err := json.Unmarshal([]byte(meta), &r.Meta); err != nil {
			r.Meta = []models.MetaItem{}
		}
		if tags != "" && tags != "[]" {
			json.Unmarshal([]byte(tags), &r.Tags)
		}
		out = append(out, r)
	}
	if out == nil {
		out = []models.SearchResult{}
	}
	return out, nil
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(v)
}
