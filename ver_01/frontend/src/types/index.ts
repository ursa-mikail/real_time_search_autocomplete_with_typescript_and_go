export type ResultKind = 'company' | 'product' | 'innovation' | 'trend';

export interface MetaItem {
  label: string;
  value: string;
}

export interface SearchResult {
  id: number;
  kind: ResultKind;
  title: string;
  subtitle: string;
  description: string;
  badge?: string;
  meta: MetaItem[];
  score: number;
  tags?: string[];
}

export interface Suggestion {
  text: string;
  kind: ResultKind;
  subtitle: string;
}

export interface SearchResponse {
  query: string;
  results: SearchResult[];
  total_count: number;
  elapsed_ms: number;
}
