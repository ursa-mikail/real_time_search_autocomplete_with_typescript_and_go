package models

type ResultKind = string

type MetaItem struct {
	Label string `json:"label"`
	Value string `json:"value"`
}

type SearchResult struct {
	ID          int        `json:"id"`
	Kind        ResultKind `json:"kind"`
	Title       string     `json:"title"`
	Subtitle    string     `json:"subtitle"`
	Description string     `json:"description"`
	Badge       string     `json:"badge,omitempty"`
	Meta        []MetaItem `json:"meta,omitempty"`
	Score       float64    `json:"score"`
	Tags        []string   `json:"tags,omitempty"`
}

type Suggestion struct {
	Text     string `json:"text"`
	Kind     string `json:"kind"`
	Subtitle string `json:"subtitle"`
}

type SearchResponse struct {
	Query      string         `json:"query"`
	Results    []SearchResult `json:"results"`
	TotalCount int            `json:"total_count"`
	ElapsedMs  int64          `json:"elapsed_ms"`
}
