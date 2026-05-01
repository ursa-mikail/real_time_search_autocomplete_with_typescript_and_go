import { useState, useRef, useCallback } from 'react';
import { SearchResponse, Suggestion } from '../types';

const API = '/api';

export function useSearch() {
  const [query,      setQ]       = useState('');
  const [sugs,       setSugs]    = useState<Suggestion[]>([]);
  const [open,       setOpen]    = useState(false);
  const [sugLoading, setSugLoad] = useState(false); // true while keystroke fetch in-flight
  const [results,    setResults] = useState<SearchResponse | null>(null);
  const [loading,    setLoading] = useState(false);
  const [error,      setError]   = useState<string | null>(null);

  const timer   = useRef<ReturnType<typeof setTimeout>>();
  const sugCtl  = useRef<AbortController>();
  const srchCtl = useRef<AbortController>();

  /**
   * Fires on EVERY keystroke (onChange).
   * Immediately cancels the previous debounce + aborts the previous in-flight fetch.
   * After 120ms silence → hits GET /api/suggest?q=... on the live Postgres backend.
   * Dropdown updates with whatever Postgres returns.
   */
  const setQuery = useCallback((q: string) => {
    setQ(q);
    clearTimeout(timer.current);
    sugCtl.current?.abort();
    setSugLoad(false);

    if (!q.trim()) {
      setSugs([]);
      setOpen(false);
      setResults(null);
      return;
    }

    setSugLoad(true); // show live indicator immediately

    timer.current = setTimeout(async () => {
      const ctl = new AbortController();
      sugCtl.current = ctl;
      try {
        const res  = await fetch(`${API}/suggest?q=${encodeURIComponent(q)}`, { signal: ctl.signal });
        const data = await res.json();
        const list: Suggestion[] = Array.isArray(data) ? data : [];
        setSugs(list);
        setOpen(list.length > 0);
      } catch {
        // AbortError = superseded by next keystroke — ignore
      } finally {
        setSugLoad(false);
      }
    }, 120);
  }, []);

  const runSearch = useCallback(async (q: string) => {
    const t = q.trim();
    if (!t) return;
    srchCtl.current?.abort();
    const ctl = new AbortController();
    srchCtl.current = ctl;
    setSugs([]); setOpen(false); setLoading(true); setError(null);
    try {
      const res  = await fetch(`${API}/search?q=${encodeURIComponent(t)}`, { signal: ctl.signal });
      const body = await res.json();
      if (!res.ok) throw new Error(body.error ?? `HTTP ${res.status}`);
      setResults(body);
    } catch (e: unknown) {
      if (e instanceof Error && e.name !== 'AbortError') setError(e.message);
    } finally {
      setLoading(false);
    }
  }, []);

  const selectSuggestion = useCallback((text: string) => {
    clearTimeout(timer.current);
    sugCtl.current?.abort();
    setSugLoad(false);
    setQ(text); setSugs([]); setOpen(false);
    runSearch(text);
  }, [runSearch]);

  return {
    query, setQuery,
    sugs, open, sugLoading,
    closeDropdown: () => setOpen(false),
    results, loading, error,
    submitSearch: () => runSearch(query),
    selectSuggestion,
  };
}
