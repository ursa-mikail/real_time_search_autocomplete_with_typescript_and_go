import { useRef, useEffect, KeyboardEvent, useState } from 'react';
import { useSearch } from './hooks/useSearch';
import { ResultKind, SearchResult, Suggestion } from './types';
import './index.css';

const KIND: Record<ResultKind, { label: string; color: string; icon: string }> = {
  company:    { label: 'Company',  color: '#00d9ff', icon: '◈' },
  product:    { label: 'Product',  color: '#a78bfa', icon: '⬡' },
  innovation: { label: 'Research', color: '#34d399', icon: '◎' },
  trend:      { label: 'Trend',    color: '#fb923c', icon: '◆' },
};

const HINTS = ['transformer','NVIDIA','AlphaFold','RAG','Rust','diffusion','Claude','CUDA'];
const PHS   = [
  'Type anything — suggestions stream live from Postgres...',
  'Try "attention" or "NVIDIA"...',
  'Search companies, products, research, trends...',
  'Try "AlphaFold" or "vector database"...',
  'Try "diffusion" or "LoRA"...',
];

function usePlaceholder() {
  const [i, setI] = useState(0);
  useEffect(() => {
    const t = setInterval(() => setI(n => (n + 1) % PHS.length), 3000);
    return () => clearInterval(t);
  }, []);
  return PHS[i];
}

function KindBadge({ kind }: { kind: ResultKind }) {
  const k = KIND[kind];
  return (
    <span className="badge" style={{ '--c': k.color } as React.CSSProperties}>
      {k.icon} {k.label}
    </span>
  );
}

function SugRow({ s, active, onPick, onHover }: {
  s: Suggestion; active: boolean;
  onPick: (t: string) => void; onHover: () => void;
}) {
  const k = KIND[s.kind];
  return (
    <button
      className={`sug-row${active ? ' active' : ''}`}
      onMouseEnter={onHover}
      onMouseDown={e => { e.preventDefault(); onPick(s.text); }}
    >
      <span style={{ color: k.color, flexShrink: 0, fontSize: '.9rem' }}>{k.icon}</span>
      <span className="sug-name">{s.text}</span>
      <span className="sug-sub">{s.subtitle}</span>
      <span className="sug-tag" style={{ color: k.color }}>{k.label}</span>
    </button>
  );
}

function Card({ r, onTag }: { r: SearchResult; onTag: (t: string) => void }) {
  const k   = KIND[r.kind];
  const pct = Math.min(Math.round(r.score * 100), 100);
  return (
    <article className="card" style={{ '--c': k.color } as React.CSSProperties}>
      <div className="card-bar" />
      <div className="card-body">
        <div className="card-row">
          <KindBadge kind={r.kind} />
          {r.badge && <span className="card-pill">{r.badge}</span>}
        </div>
        <h3 className="card-title">{r.title}</h3>
        <p  className="card-sub">{r.subtitle}</p>
        <p  className="card-desc">{r.description}</p>
        {r.meta && r.meta.length > 0 && (
          <div className="meta-grid">
            {r.meta.map((m, i) => (
              <div key={i} className="meta-cell">
                <span className="meta-lbl">{m.label}</span>
                <span className="meta-val">{m.value}</span>
              </div>
            ))}
          </div>
        )}
        {r.tags && r.tags.length > 0 && (
          <div className="tag-row">
            {r.tags.slice(0, 6).map(t => (
              <button key={t} className="tag" onClick={() => onTag(t)}>#{t}</button>
            ))}
          </div>
        )}
        <div className="score-row">
          <div className="score-track">
            <div className="score-fill" style={{ width: `${pct}%`, background: k.color }} />
          </div>
          <span className="score-num">{pct}%</span>
        </div>
      </div>
    </article>
  );
}

export default function App() {
  const {
    query, setQuery,
    sugs, open, sugLoading,
    closeDropdown,
    results, loading, error,
    submitSearch, selectSuggestion,
  } = useSearch();

  const ph       = usePlaceholder();
  const inputRef = useRef<HTMLInputElement>(null);
  const wrapRef  = useRef<HTMLDivElement>(null);
  const [active, setActive] = useState(-1);

  useEffect(() => setActive(-1), [sugs]);

  useEffect(() => {
    const fn = (e: MouseEvent) => {
      if (wrapRef.current && !wrapRef.current.contains(e.target as Node)) closeDropdown();
    };
    document.addEventListener('mousedown', fn);
    return () => document.removeEventListener('mousedown', fn);
  }, [closeDropdown]);

  const onKey = (e: KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Escape') { closeDropdown(); return; }
    if (!open || sugs.length === 0) {
      if (e.key === 'Enter') submitSearch();
      return;
    }
    if (e.key === 'ArrowDown') { e.preventDefault(); setActive(a => Math.min(a + 1, sugs.length - 1)); }
    else if (e.key === 'ArrowUp') { e.preventDefault(); setActive(a => Math.max(a - 1, -1)); }
    else if (e.key === 'Enter') {
      e.preventDefault();
      if (active >= 0) selectSuggestion(sugs[active].text);
      else { closeDropdown(); submitSearch(); }
    }
  };

  const grouped = results?.results.reduce<Partial<Record<ResultKind, SearchResult[]>>>((acc, r) => {
    (acc[r.kind as ResultKind] ??= []).push(r); return acc;
  }, {});

  const dropdownVisible = open || sugLoading; // show dropdown shell while fetching too

  return (
    <div className="app">
      <div className="bg-grid" />
      <div className="bg-glow" />
      <main className="main">

        {/* header */}
        <header className="hdr">
          <div className="logo">
            <span className="logo-dot" />
            <span className="logo-txt">Search<em>Pulse</em></span>
          </div>
          <p className="tagline">Live autocomplete · every keystroke hits Postgres</p>
        </header>

        {/* search + dropdown */}
        <div className="search-wrap" ref={wrapRef}>
          <div className={`search-box${dropdownVisible ? ' is-open' : ''}`}>
            <span className="search-ico">⌕</span>
            <input
              ref={inputRef}
              className="search-input"
              type="text"
              value={query}
              placeholder={ph}
              onChange={e => setQuery(e.target.value)}
              onKeyDown={onKey}
              autoComplete="off"
              spellCheck={false}
            />
            {/* live indicator — pulses on every keystroke fetch */}
            {sugLoading && <span className="sug-spin" title="fetching from Postgres…" />}
            {loading    && <span className="spin" />}
            {query && (
              <button
                className="clear"
                onMouseDown={e => { e.preventDefault(); setQuery(''); inputRef.current?.focus(); }}
              >✕</button>
            )}
            <button className="go-btn" onClick={submitSearch} disabled={!query.trim() || loading}>
              Search
            </button>
          </div>

          {/* dropdown — shows while loading OR has results */}
          {dropdownVisible && (
            <div className="dropdown" role="listbox">
              <div className="drop-hdr">
                <span className="drop-live">
                  {/* blinking dot proves each request is live */}
                  <span className={`live-dot${sugLoading ? ' fetching' : ''}`} />
                  {sugLoading ? 'querying Postgres…' : `${sugs.length} suggestion${sugs.length !== 1 ? 's' : ''}`}
                </span>
                <span className="drop-keys">↑↓ · Enter · Esc</span>
              </div>
              {sugs.map((s, i) => (
                <SugRow
                  key={`${s.kind}:${s.text}`}
                  s={s} active={i === active}
                  onPick={selectSuggestion}
                  onHover={() => setActive(i)}
                />
              ))}
              {!sugLoading && sugs.length === 0 && (
                <div className="drop-empty">No matches — keep typing</div>
              )}
            </div>
          )}
        </div>

        {/* status */}
        {results && (
          <div className="status">
            <span>
              {results.total_count} result{results.total_count !== 1 ? 's' : ''} for{' '}
              <strong>"{results.query}"</strong>
            </span>
            <span className="status-ms">{results.elapsed_ms}ms</span>
            {(Object.entries(KIND) as [ResultKind, typeof KIND[ResultKind]][]).map(([k, v]) => {
              const n = grouped?.[k]?.length ?? 0;
              if (!n) return null;
              return <span key={k} style={{ color: v.color }}>{v.icon} {n} {v.label}{n !== 1 ? 's' : ''}</span>;
            })}
          </div>
        )}

        {error && <div className="err-bar">⚠ {error}</div>}

        {/* results */}
        <section>
          {!results && !loading && (
            <div className="empty">
              <div className="orb" />
              <h2>Explore the Tech Universe</h2>
              <p>
                Start typing — every keystroke fires a live query to Postgres and
                updates suggestions in real time. Hit <kbd>Enter</kbd> or click a
                suggestion for full results.
              </p>
              <div className="hints">
                {HINTS.map(h => (
                  <button key={h} className="hint" onClick={() => selectSuggestion(h)}>{h}</button>
                ))}
              </div>
              <div className="legend">
                {(Object.entries(KIND) as [ResultKind, typeof KIND[ResultKind]][]).map(([k, v]) => (
                  <div key={k} className="leg-item">
                    <span style={{ color: v.color }}>{v.icon}</span> {v.label}
                  </div>
                ))}
              </div>
            </div>
          )}

          {results && results.total_count === 0 && (
            <div className="no-res">
              <span className="no-res-sym">∅</span>
              <p>No results for <strong>"{results.query}"</strong></p>
              <p className="no-res-tip">Try a broader term</p>
            </div>
          )}

          {results && results.total_count > 0 && (
            <div className="grid">
              {results.results.map(r => (
                <Card key={`${r.kind}:${r.id}`} r={r} onTag={selectSuggestion} />
              ))}
            </div>
          )}
        </section>

        <footer className="foot">
          SearchPulse · Go · PostgreSQL · React · TypeScript
        </footer>
      </main>
    </div>
  );
}
