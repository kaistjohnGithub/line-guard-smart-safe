const { useState, useEffect, useRef, useCallback } = React;

const API = 'http://localhost:8000';

// ── Data from mock-data.js ───────────────────────────────
const { cameras: CAMERAS, prompts: PROMPTS, sops: SOP_DATA,
        sopSteps: SOP_STEPS_SEED, alerts: ALERTS_SEED,
        events: EVENTS, rules: RULES } = window.SSG_DATA;

const SOP_STEPS = SOP_STEPS_SEED.map((s, i) => ({ ...s, id: i }));

const VERSION_HISTORY = [
  {ver:'v1.3',date:'10 Mar 2026',by:'K.Somsak',note:'Added dual-confirmation for Step 3',type:'mod'},
  {ver:'v1.2',date:'20 Feb 2026',by:'P.Naree',note:'Updated step 5 recording deadline',type:'mod'},
  {ver:'v1.1',date:'10 Jan 2026',by:'T.Chai',note:'Added guard door verification step',type:'add'},
  {ver:'v1.0',date:'01 Dec 2025',by:'Admin',note:'Initial SOP created',type:'add'},
];

// ── Shared Components ────────────────────────────────────

function Btn({ children, variant = 'ghost', size = 'md', onClick, disabled, style = {} }) {
  const base = {
    border: '1.5px solid', borderRadius: 6, cursor: disabled ? 'not-allowed' : 'pointer',
    fontFamily: 'inherit', fontWeight: 600, transition: 'all .15s', whiteSpace: 'nowrap',
    opacity: disabled ? 0.5 : 1,
    fontSize: size === 'sm' ? 11 : size === 'lg' ? 14 : 12,
    padding: size === 'sm' ? '4px 10px' : size === 'lg' ? '8px 18px' : '5px 13px',
  };
  const variants = {
    primary: { background: 'var(--blue)', borderColor: 'var(--blue)', color: '#fff' },
    ghost: { background: 'var(--surface2)', borderColor: 'var(--border2)', color: 'var(--t2)' },
    teal: { background: 'var(--blue-light)', borderColor: 'rgba(29,110,245,.3)', color: 'var(--blue)' },
    danger: { background: 'var(--red-light)', borderColor: 'rgba(229,62,62,.35)', color: 'var(--red)' },
    amber: { background: 'rgba(217,119,6,.12)', borderColor: 'rgba(217,119,6,.4)', color: 'var(--amber)' },
  };
  return (
    <button onClick={disabled ? undefined : onClick} style={{ ...base, ...variants[variant], ...style }}>
      {children}
    </button>
  );
}

function Badge({ children, color = 'blue', style = {} }) {
  const colors = {
    blue: { bg: 'var(--blue-light)', border: 'rgba(29,110,245,.25)', text: 'var(--blue)' },
    red: { bg: 'var(--red-light)', border: 'rgba(229,62,62,.3)', text: 'var(--red)' },
    amber: { bg: 'var(--amber-light)', border: 'rgba(217,119,6,.3)', text: 'var(--amber)' },
    green: { bg: 'var(--green-light)', border: 'rgba(22,163,74,.3)', text: 'var(--green)' },
    gray: { bg: 'rgba(100,116,139,.12)', border: 'rgba(100,116,139,.25)', text: 'var(--gray)' },
  };
  const c = colors[color] || colors.blue;
  return (
    <span style={{
      fontSize: 10, padding: '2px 8px', borderRadius: 4, fontWeight: 700,
      background: c.bg, border: `1px solid ${c.border}`, color: c.text,
      textTransform: 'uppercase', letterSpacing: '0.05em', ...style,
    }}>
      {children}
    </span>
  );
}

function StatusPill({ status }) {
  const map = {
    online:   { bg: 'var(--green-light)', border: 'rgba(22,163,74,.3)',   color: 'var(--green)', label: 'ONLINE' },
    offline:  { bg: 'rgba(100,116,139,.12)', border: 'rgba(100,116,139,.25)', color: 'var(--gray)',  label: 'OFFLINE' },
    delay:    { bg: 'var(--amber-light)', border: 'rgba(217,119,6,.3)',   color: 'var(--amber)', label: 'DELAY' },
    critical: { bg: 'var(--red-light)',   border: 'rgba(229,62,62,.3)',   color: 'var(--red)',   label: 'CRITICAL' },
  };
  const c = map[status] || map.offline;
  return (
    <span style={{
      fontSize: 9, fontWeight: 700, padding: '2px 7px', borderRadius: 3,
      background: c.bg, border: `1px solid ${c.border}`, color: c.color,
      textTransform: 'uppercase', letterSpacing: '0.07em',
    }}>{c.label}</span>
  );
}

function SevBadge({ sev }) {
  const map = {
    critical: { bg: 'var(--red)', color: '#fff' },
    high:     { bg: 'var(--red-light)', border: '1px solid rgba(229,62,62,.3)', color: 'var(--red)' },
    medium:   { bg: 'var(--amber-light)', border: '1px solid rgba(217,119,6,.3)', color: 'var(--amber)' },
    low:      { bg: 'rgba(100,116,139,.12)', border: '1px solid rgba(100,116,139,.25)', color: 'var(--gray)' },
  };
  const key = (sev || '').toLowerCase();
  const c = map[key] || map.low;
  return (
    <span style={{
      fontSize: 8, fontWeight: 800, padding: '2px 5px', borderRadius: 3,
      textTransform: 'uppercase', letterSpacing: '0.08em', ...c,
    }}>{sev}</span>
  );
}

function Panel({ children, style = {} }) {
  return (
    <div style={{
      background: 'var(--surface)', border: '1px solid var(--border)',
      borderRadius: 10, overflow: 'hidden', display: 'flex', flexDirection: 'column', ...style,
    }}>
      {children}
    </div>
  );
}

function PanelHead({ title, right, icon }) {
  return (
    <div style={{
      padding: '8px 14px', background: '#f0f5ff', borderBottom: '1px solid var(--border)',
      display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexShrink: 0,
    }}>
      <span style={{
        fontSize: 10, fontWeight: 700, textTransform: 'uppercase',
        letterSpacing: '0.08em', color: 'var(--t2)', display: 'flex', alignItems: 'center', gap: 6,
      }}>
        {icon && <span style={{ fontSize: 13 }}>{icon}</span>}{title}
      </span>
      {right && <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>{right}</div>}
    </div>
  );
}

function KPICard({ value, label, delta, color = 'blue' }) {
  const c   = { blue: 'var(--blue)', green: 'var(--green)', red: 'var(--red)', amber: 'var(--amber)', gray: 'var(--gray)' };
  const bc  = { blue: 'var(--blue)', green: 'var(--green)', red: 'var(--red)', amber: 'var(--amber)', gray: 'var(--border)' };
  return (
    <div style={{
      background: 'var(--surface)', border: '1px solid var(--border)',
      borderRadius: 10, padding: '12px 14px', position: 'relative', overflow: 'hidden',
    }}>
      <div style={{
        position: 'absolute', top: 0, left: 0, right: 0, height: 3,
        background: bc[color], animation: color === 'red' ? 'blink 2s infinite' : 'none',
      }} />
      <div style={{ fontSize: 26, fontWeight: 700, color: c[color], lineHeight: 1 }}>{value}</div>
      <div style={{
        fontSize: 10, color: 'var(--t3)', textTransform: 'uppercase',
        letterSpacing: '0.07em', marginTop: 4, fontWeight: 500,
      }}>{label}</div>
      {delta && <div style={{ fontSize: 10, marginTop: 3, color: 'var(--t3)' }}>{delta}</div>}
    </div>
  );
}

function Divider() {
  return <div style={{ borderTop: '1px solid var(--border)', margin: '10px 0' }} />;
}

// Toast
function ToastContainer({ toasts }) {
  return (
    <div style={{
      position: 'fixed', bottom: 20, right: 20, zIndex: 9999,
      display: 'flex', flexDirection: 'column', gap: 8, pointerEvents: 'none',
    }}>
      {toasts.map(t => (
        <div key={t.id} style={{
          background: '#fff', border: '1px solid var(--border2)',
          borderRadius: 10, padding: '10px 16px', display: 'flex', alignItems: 'center', gap: 10,
          minWidth: 260, fontSize: 12, pointerEvents: 'all',
          borderLeft: `3px solid ${t.color || 'var(--blue)'}`,
          animation: 'slideup .3s ease', boxShadow: '0 4px 16px rgba(0,0,0,.08)',
        }}>
          <span style={{ fontSize: 16 }}>{t.icon}</span>{t.msg}
        </div>
      ))}
    </div>
  );
}

function useToast() {
  const [toasts, setToasts] = useState([]);
  const add = useCallback((msg, icon = '✓', color = 'var(--blue)') => {
    const id = Date.now();
    setToasts(p => [...p, { id, msg, icon, color }]);
    setTimeout(() => setToasts(p => p.filter(t => t.id !== id)), 2800);
  }, []);
  return { toasts, add };
}

// Modal
function Modal({ show, onClose, title, children, footer }) {
  if (!show) return null;
  return (
    <div onClick={e => { if (e.target === e.currentTarget) onClose(); }}
      style={{
        position: 'fixed', inset: 0, background: 'rgba(0,0,0,.45)', zIndex: 1000,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
      <div style={{
        background: '#fff', borderRadius: 14, width: 600, maxWidth: '95vw',
        maxHeight: '85vh', display: 'flex', flexDirection: 'column', overflow: 'hidden',
        boxShadow: '0 24px 48px rgba(0,0,0,.12)',
      }}>
        <div style={{
          padding: '16px 20px', borderBottom: '1px solid var(--border)',
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          background: '#f8faff', flexShrink: 0,
        }}>
          <span style={{ fontSize: 16, fontWeight: 700 }}>{title}</span>
          <button onClick={onClose} style={{
            width: 30, height: 30, borderRadius: '50%',
            border: '1px solid var(--border2)', background: 'var(--surface2)', cursor: 'pointer',
            display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 14,
          }}>✕</button>
        </div>
        <div style={{ padding: 20, overflowY: 'auto', flex: 1 }}>{children}</div>
        {footer && (
          <div style={{
            padding: '12px 20px', borderTop: '1px solid var(--border)',
            display: 'flex', gap: 8, justifyContent: 'flex-end', background: '#f8faff', flexShrink: 0,
          }}>{footer}</div>
        )}
      </div>
    </div>
  );
}

function FormGroup({ label, children }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
      <div style={{
        fontSize: 10, fontWeight: 700, textTransform: 'uppercase',
        letterSpacing: '0.07em', color: 'var(--t3)',
      }}>{label}</div>
      {children}
    </div>
  );
}

function FormInput({ value, onChange, placeholder, disabled, style = {} }) {
  return (
    <input value={value || ''} disabled={disabled} onChange={e => onChange && onChange(e.target.value)}
      placeholder={placeholder}
      style={{
        background: 'var(--surface2)', border: '1px solid var(--border2)',
        borderRadius: 6, padding: '7px 10px', color: 'var(--t1)', fontSize: 12,
        outline: 'none', width: '100%', opacity: disabled ? 0.65 : 1, cursor: disabled ? 'not-allowed' : 'text', ...style,
      }} />
  );
}

// ── MockFeed Canvas ──────────────────────────────────────
function MockFeed({ camId, status, height = 192 }) {
  const ref = useRef(null);
  useEffect(() => {
    const canvas = ref.current;
    if (!canvas) return undefined;
    const ctx = canvas.getContext('2d');
    let dot = { x: 140, y: 90 };
    let frame = 0;
    const tick = () => {
      const w = canvas.width, h = canvas.height;
      ctx.fillStyle = '#0a1020';
      ctx.fillRect(0, 0, w, h);
      ctx.strokeStyle = 'rgba(29,110,245,.04)';
      ctx.lineWidth = 1;
      for (let x = 0; x < w; x += 32) { ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, h); ctx.stroke(); }
      for (let y = 0; y < h; y += 32) { ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(w, y); ctx.stroke(); }
      ctx.strokeStyle = 'rgba(229,62,62,.6)';
      ctx.lineWidth = 1.5;
      ctx.setLineDash([4, 4]);
      ctx.strokeRect(w * 0.22, h * 0.27, w * 0.37, h * 0.44);
      ctx.setLineDash([]);
      dot.x += (Math.random() - 0.5) * 4;
      dot.y += (Math.random() - 0.5) * 3;
      dot.x = Math.max(10, Math.min(w - 10, dot.x));
      dot.y = Math.max(10, Math.min(h - 10, dot.y));
      ctx.fillStyle = status === 'critical' ? '#ef4444' : 'rgba(29,110,245,.9)';
      ctx.beginPath(); ctx.arc(dot.x, dot.y, 5, 0, Math.PI * 2); ctx.fill();
      ctx.fillStyle = '#22c55e';
      ctx.font = "11px 'IBM Plex Mono', monospace";
      ctx.fillText(camId, 8, 16);
      ctx.fillStyle = 'rgba(255,255,255,.45)';
      ctx.font = "9px 'IBM Plex Mono', monospace";
      const stamp = new Date().toLocaleTimeString('en-GB');
      ctx.fillText(stamp, w - 70, h - 7);
      if (Math.floor(frame / 12) % 2 === 0) {
        ctx.fillStyle = '#ef4444';
        ctx.beginPath(); ctx.arc(w - 18, 10, 4, 0, Math.PI * 2); ctx.fill();
        ctx.fillStyle = '#fff';
        ctx.font = "9px 'IBM Plex Mono', monospace";
        ctx.fillText('REC', w - 44, 14);
      }
      frame++;
    };
    tick();
    const id = window.setInterval(tick, 80);
    return () => window.clearInterval(id);
  }, [camId, status]);
  return (
    <canvas ref={ref} width={640} height={height}
      style={{ width: '100%', height: height, display: 'block', background: '#0a1020' }} />
  );
}

// ── Sidebar ──────────────────────────────────────────────
const NAV = [
  { key: 'dashboard', label: 'Dashboard',       icon: '⬡', section: 'Monitor' },
  { key: 'cameras',   label: 'Camera List',     icon: '⊞', section: null },
  { key: 'alerts',    label: 'Alert Center',    icon: '◈', badge: ALERTS_SEED.filter(a => a.unread).length, badgeColor: 'red', section: null },
  { key: 'sop',       label: 'SOP Management',  icon: '≡', section: 'Manage' },
  { key: 'rules',     label: 'Safety Rules',    icon: '⚑', badge: '3 AI', badgeColor: 'amber', section: null },
  { key: 'prompts',   label: 'Prompt Library',  icon: '✦', section: null },
  { key: 'events',    label: 'Event History',   icon: '⊶', section: 'Reports' },
  { key: 'analyze',   label: 'AI Video Analyze',icon: '▶', section: null },
  { key: 'analytics', label: 'Analytics',       icon: '⌇', section: null },
  { key: 'settings',  label: 'Admin / Settings',icon: '⚙', section: 'System' },
];

function Sidebar({ active, onNav }) {
  const sections = [];
  NAV.forEach(item => {
    if (item.section) sections.push({ type: 'section', label: item.section });
    sections.push({ type: 'item', ...item });
  });
  return (
    <div style={{ width: 210, flexShrink: 0, background: '#fff', borderRight: '1px solid var(--border)', display: 'flex', flexDirection: 'column', height: '100%' }}>
      <div style={{ padding: '16px 14px', borderBottom: '1px solid var(--border)', display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{ width: 34, height: 34, background: 'var(--blue)', borderRadius: 9, display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 800, fontSize: 15, color: '#fff', flexShrink: 0, boxShadow: '0 0 0 3px rgba(29,110,245,.15)' }}>L</div>
        <div>
          <div style={{ fontSize: 12, fontWeight: 700, color: 'var(--blue)', letterSpacing: '0.02em' }}>LINE GUARD</div>
          <div style={{ fontSize: 9, color: 'var(--t3)', letterSpacing: '0.06em', textTransform: 'uppercase' }}>AI Safety · DENSO</div>
        </div>
      </div>
      <nav style={{ flex: 1, overflowY: 'auto', padding: '8px 0' }}>
        {sections.map((s, i) => s.type === 'section' ? (
          <div key={i} style={{ padding: '12px 14px 4px', fontSize: 9, color: '#b0bdd6', textTransform: 'uppercase', letterSpacing: '0.1em', fontWeight: 600 }}>{s.label}</div>
        ) : (
          <div key={s.key} onClick={() => onNav(s.key)}
            style={{ display: 'flex', alignItems: 'center', gap: 9, padding: '8px 14px', cursor: 'pointer', fontSize: 12, transition: 'all .15s', borderLeft: `2px solid ${active === s.key ? 'var(--blue)' : 'transparent'}`, background: active === s.key ? 'rgba(29,110,245,.07)' : 'transparent', color: active === s.key ? 'var(--blue)' : 'var(--t2)', fontWeight: active === s.key ? 600 : 400 }}>
            <span style={{ fontSize: 14, width: 16, textAlign: 'center' }}>{s.icon}</span>
            {s.label}
            {s.badge ? <Badge color={s.badgeColor || 'blue'} style={{ marginLeft: 'auto', fontSize: 9 }}>{s.badge}</Badge> : null}
          </div>
        ))}
      </nav>
      <div style={{ padding: '10px 14px', borderTop: '1px solid var(--border)', background: '#f8faff', display: 'flex', alignItems: 'center', gap: 8 }}>
        <div style={{ width: 30, height: 30, borderRadius: '50%', background: 'rgba(29,110,245,.1)', border: '1.5px solid var(--border2)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 10, fontWeight: 700, color: 'var(--blue)', flexShrink: 0 }}>KS</div>
        <div>
          <div style={{ fontSize: 12, fontWeight: 500 }}>K. Somsak</div>
          <div style={{ fontSize: 10, color: 'var(--t3)' }}>Safety Officer</div>
        </div>
        <div className="pulse" style={{ width: 7, height: 7, borderRadius: '50%', background: 'var(--green)', marginLeft: 'auto' }} />
      </div>
    </div>
  );
}

// ── Topbar ───────────────────────────────────────────────
function Topbar({ clock }) {
  return (
    <div style={{ height: 44, background: '#fff', borderBottom: '1px solid var(--border)', padding: '0 16px', display: 'flex', alignItems: 'center', gap: 8, flexShrink: 0, boxShadow: '0 1px 4px rgba(29,110,245,.05)' }}>
      {['Build ▾ A1', 'Process ▾ Assembly', 'Sub ▾ Press', 'Station ▾ All'].map(t => (
        <div key={t} style={{ background: 'var(--surface2)', border: '1px solid var(--border2)', borderRadius: 5, padding: '4px 10px', fontSize: 11, color: 'var(--t2)', cursor: 'pointer', whiteSpace: 'nowrap' }}>{t}</div>
      ))}
      <input placeholder="⌕  Search cameras, events…" style={{ flex: 1, maxWidth: 200, background: 'var(--surface2)', border: '1px solid var(--border2)', borderRadius: 5, padding: '5px 10px', fontSize: 11, color: 'var(--t1)', outline: 'none' }} />
      <select style={{ background: 'var(--surface2)', border: '1px solid var(--border2)', borderRadius: 5, padding: '4px 8px', fontSize: 11, color: 'var(--t1)', outline: 'none' }}>
        <option>All Status</option><option>Online</option><option>Offline</option><option>Critical</option>
      </select>
      <div style={{ marginLeft: 'auto', display: 'flex', alignItems: 'center', gap: 8 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 5, background: 'rgba(22,163,74,.08)', border: '1px solid rgba(22,163,74,.25)', borderRadius: 4, padding: '3px 8px' }}>
          <div className="pulse" style={{ width: 5, height: 5, borderRadius: '50%', background: 'var(--green)' }} />
          <span style={{ fontSize: 9, color: 'var(--green)', fontWeight: 700 }}>LIVE</span>
        </div>
        <span style={{ fontSize: 10, color: 'var(--t3)', fontFamily: "'IBM Plex Mono',monospace" }}>{clock}</span>
      </div>
    </div>
  );
}

// ── CameraCard ───────────────────────────────────────────
function CameraCard({ cam, onOpen }) {
  const topColors  = { online: 'var(--green)', offline: 'var(--gray)', delay: 'var(--amber)', critical: 'var(--red)' };
  const riskColors = { CRITICAL: 'var(--red)', HIGH: 'var(--red)', MED: 'var(--amber)', LOW: 'var(--green)', 'N/A': 'var(--gray)' };
  const isOff = cam.status === 'offline';
  return (
    <div
      style={{ background: '#fff', border: '1px solid var(--border)', borderRadius: 10, padding: 12, cursor: isOff ? 'default' : 'pointer', transition: 'all .18s', position: 'relative', overflow: 'hidden' }}
      onMouseEnter={e => { if (!isOff) e.currentTarget.style.borderColor = 'var(--blue)'; }}
      onMouseLeave={e => { e.currentTarget.style.borderColor = 'var(--border)'; }}
    >
      <div style={{ position: 'absolute', top: 0, left: 0, right: 0, height: 3, background: topColors[cam.status], animation: cam.status === 'critical' ? 'blink 1s infinite' : 'none' }} />
      <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: 6 }}>
        <span style={{ fontSize: 10, color: 'var(--blue)', fontWeight: 700, letterSpacing: '0.1em' }}>{cam.id}</span>
        <StatusPill status={cam.status} />
      </div>
      <div style={{ height: 72, background: '#0a1020', borderRadius: 6, marginBottom: 8, position: 'relative', overflow: 'hidden', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        {!isOff && <div className="scan" style={{ top: 0 }} />}
        <span style={{ fontSize: 10, color: 'rgba(29,110,245,.5)', letterSpacing: '0.1em' }}>{isOff ? '— OFFLINE —' : '▶ LIVE FEED'}</span>
      </div>
      <div style={{ fontSize: 13, fontWeight: 600, marginBottom: 2 }}>{cam.name}</div>
      <div style={{ fontSize: 10, color: 'var(--t3)', marginBottom: 10 }}>{cam.process} · {cam.station}</div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 5, marginBottom: 10 }}>
        {[
          { v: cam.fps || '—', l: 'FPS',    c: cam.fps < 5 && cam.fps > 0 ? 'var(--amber)' : 'var(--t1)' },
          { v: cam.alerts,     l: 'Alerts', c: cam.alerts > 0 ? 'var(--red)' : 'var(--t1)' },
          { v: cam.risk,       l: 'Risk',   c: riskColors[cam.risk] || 'var(--gray)' },
        ].map(s => (
          <div key={s.l} style={{ background: 'var(--surface2)', border: '1px solid var(--border)', borderRadius: 5, padding: '5px 7px' }}>
            <div style={{ fontSize: 13, fontWeight: 700, color: s.c, lineHeight: 1 }}>{s.v}</div>
            <div style={{ fontSize: 8, color: 'var(--t3)', textTransform: 'uppercase', letterSpacing: '0.06em', marginTop: 2 }}>{s.l}</div>
          </div>
        ))}
      </div>
      <button onClick={isOff ? undefined : onOpen} disabled={isOff}
        style={{ width: '100%', padding: '7px', background: isOff ? 'var(--surface2)' : 'rgba(29,110,245,.09)', border: `1px dashed ${isOff ? 'var(--border)' : 'rgba(29,110,245,.3)'}`, borderRadius: 5, color: isOff ? 'var(--gray)' : 'var(--blue)', fontSize: 11, fontWeight: 700, cursor: isOff ? 'not-allowed' : 'pointer', fontFamily: 'inherit', letterSpacing: '0.06em', textTransform: 'uppercase', opacity: isOff ? 0.5 : 1 }}>
        {isOff ? '● Offline' : '▶ Open Monitor'}
      </button>
    </div>
  );
}

// ── Page: Dashboard ──────────────────────────────────────
function Dashboard({ onOpenCamera }) {
  return (
    <div style={{ flex: 1, overflowY: 'auto', padding: 16 }}>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(5,1fr)', gap: 8, marginBottom: 16 }}>
        <KPICard value="24" label="Total Cameras"  delta="Build A1 · All Process"  color="blue" />
        <KPICard value="20" label="Online"          delta="↑ 2 from yesterday"      color="green" />
        <KPICard value="2"  label="Offline"         delta="Last: CAM-A04 09:41"     color="gray" />
        <KPICard value="5"  label="Active Alerts"   delta="3 unacknowledged"        color="amber" />
        <KPICard value="2"  label="Critical Today"  delta="Near-miss detected"      color="red" />
      </div>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
        <div style={{ fontSize: 11, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.08em', color: 'var(--t2)', display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ display: 'inline-block', width: 12, height: 2, background: 'var(--blue)' }} />
          Camera Monitoring — Press Process
        </div>
        <div style={{ display: 'flex', gap: 6 }}>
          <Btn variant="teal" size="sm">⊞ Grid</Btn>
          <Btn variant="ghost" size="sm">≡ List</Btn>
          <Btn variant="teal" size="sm">⟳ Refresh</Btn>
        </div>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill,minmax(250px,1fr))', gap: 10 }}>
        {CAMERAS.map(cam => <CameraCard key={cam.id} cam={cam} onOpen={() => onOpenCamera(cam)} />)}
      </div>
    </div>
  );
}

// ── Page: Camera List ────────────────────────────────────
function CameraList({ onOpenCamera }) {
  return (
    <div style={{ flex: 1, overflowY: 'auto', padding: 16 }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
        <div style={{ fontSize: 11, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.08em', color: 'var(--t2)', display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ display: 'inline-block', width: 12, height: 2, background: 'var(--blue)' }} />All Cameras — Build A1
        </div>
        <Btn variant="teal" size="sm">⟳ Refresh</Btn>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill,minmax(250px,1fr))', gap: 10 }}>
        {CAMERAS.map(cam => <CameraCard key={cam.id} cam={cam} onOpen={() => onOpenCamera(cam)} />)}
      </div>
    </div>
  );
}

// ── Page: Camera Detail ──────────────────────────────────
function CameraFleetCard({ cam, onOpen, mode = 'grid', onPing, onEdit, onDelete, onArchive }) {
  const topColors  = { online: 'var(--green)', offline: 'var(--gray)', delay: 'var(--amber)', critical: 'var(--red)' };
  const riskColors = { CRITICAL: 'var(--red)', HIGH: 'var(--red)', MED: 'var(--amber)', LOW: 'var(--green)', 'N/A': 'var(--gray)' };
  const isOff = cam.status === 'offline';
  const isList = mode === 'list';
  const processParts = (cam.process || '').split('/').map(s => s.trim()).filter(Boolean);
  const processMain = processParts[0] || cam.process || 'Unknown';
  const processSub = processParts.slice(1).join(' / ');

  return (
    <div
      style={{ background: '#fff', border: '1px solid var(--border)', borderRadius: 10, padding: 12, cursor: isOff ? 'default' : 'pointer', transition: 'all .18s', position: 'relative', overflow: 'hidden' }}
      onMouseEnter={e => { if (!isOff) e.currentTarget.style.borderColor = 'var(--blue)'; }}
      onMouseLeave={e => { e.currentTarget.style.borderColor = 'var(--border)'; }}
    >
      <div style={{ position: 'absolute', top: 0, left: 0, right: 0, height: 3, background: topColors[cam.status], animation: cam.status === 'critical' ? 'blink 1s infinite' : 'none' }} />
      <div style={{ display: 'flex', gap: 12, alignItems: isList ? 'center' : 'stretch', flexDirection: isList ? 'row' : 'column' }}>
        <div style={{ flexShrink: 0, width: isList ? 168 : '100%' }}>
          <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: 6 }}>
            <span style={{ fontSize: 10, color: 'var(--blue)', fontWeight: 700, letterSpacing: '0.1em' }}>{cam.id}</span>
            <StatusPill status={cam.status} />
          </div>
          <div style={{ height: isList ? 96 : 72, background: '#0a1020', borderRadius: 6, marginBottom: isList ? 0 : 8, position: 'relative', overflow: 'hidden', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            {cam.thumbnailUrl
              ? <img src={cam.thumbnailUrl} alt={cam.name} style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', objectFit: 'cover', opacity: isOff ? 0.4 : 1 }} onError={function(e) { e.target.style.display = 'none'; }} />
              : null}
            {!isOff && <div className="scan" style={{ top: 0 }} />}
            {!cam.thumbnailUrl && <span style={{ fontSize: 10, color: 'rgba(29,110,245,.5)', letterSpacing: '0.1em' }}>{isOff ? '--- OFFLINE ---' : 'LIVE FEED'}</span>}
            {cam.thumbnailUrl && isOff && <span style={{ position: 'relative', fontSize: 10, color: 'rgba(255,255,255,.6)', letterSpacing: '0.1em', background: 'rgba(0,0,0,.45)', padding: '2px 8px', borderRadius: 4 }}>OFFLINE</span>}
          </div>
        </div>

        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', gap: 8, alignItems: 'flex-start', marginBottom: 8 }}>
            <div style={{ minWidth: 0 }}>
              <div style={{ fontSize: 13, fontWeight: 600, marginBottom: 2 }}>{cam.name}</div>
              <div style={{ fontSize: 10, color: 'var(--t3)', marginBottom: 6 }}>{cam.process} · {cam.station}</div>
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6 }}>
                <Badge color="gray">{processMain}</Badge>
                {processSub ? <Badge color="blue">{processSub}</Badge> : null}
                {cam.videoSrc ? <Badge color="green">Recorded Demo</Badge> : <Badge color="gray">Synthetic Feed</Badge>}
                {cam.hasHistory ? <Badge color="amber">History Linked</Badge> : null}
              </div>
            </div>
            {isList ? (
              <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: 4, flexShrink: 0 }}>
                <div style={{ fontSize: 10, color: 'var(--t3)', textTransform: 'uppercase', letterSpacing: '0.06em' }}>Station</div>
                <div style={{ fontSize: 12, color: 'var(--t2)', fontWeight: 600 }}>{cam.station}</div>
              </div>
            ) : null}
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: isList ? 'repeat(4,minmax(0,1fr))' : '1fr 1fr 1fr', gap: 5, marginBottom: 10 }}>
            {[
              { v: cam.fps || '—', l: 'FPS', c: cam.fps < 5 && cam.fps > 0 ? 'var(--amber)' : 'var(--t1)' },
              { v: cam.alerts, l: 'Alerts', c: cam.alerts > 0 ? 'var(--red)' : 'var(--t1)' },
              { v: cam.risk, l: 'Risk', c: riskColors[cam.risk] || 'var(--gray)' },
              ...(isList ? [{ v: cam.status.toUpperCase(), l: 'Link', c: topColors[cam.status] || 'var(--gray)' }] : []),
            ].map(s => (
              <div key={s.l} style={{ background: 'var(--surface2)', border: '1px solid var(--border)', borderRadius: 5, padding: '5px 7px' }}>
                <div style={{ fontSize: 13, fontWeight: 700, color: s.c, lineHeight: 1 }}>{s.v}</div>
                <div style={{ fontSize: 8, color: 'var(--t3)', textTransform: 'uppercase', letterSpacing: '0.06em', marginTop: 2 }}>{s.l}</div>
              </div>
            ))}
          </div>

          <div style={{ display: 'flex', gap: 7, flexWrap: 'wrap' }}>
            <button onClick={isOff ? undefined : onOpen} disabled={isOff}
              style={{ flex: isList ? '0 0 auto' : 1, padding: '7px 12px', background: isOff ? 'var(--surface2)' : 'rgba(29,110,245,.09)', border: `1px dashed ${isOff ? 'var(--border)' : 'rgba(29,110,245,.3)'}`, borderRadius: 5, color: isOff ? 'var(--gray)' : 'var(--blue)', fontSize: 11, fontWeight: 700, cursor: isOff ? 'not-allowed' : 'pointer', fontFamily: 'inherit', letterSpacing: '0.06em', textTransform: 'uppercase', opacity: isOff ? 0.5 : 1 }}>
              {isOff ? 'Offline' : 'Open Monitor'}
            </button>
            <button onClick={() => onPing && onPing(cam)}
              style={{ padding: '7px 12px', background: 'var(--surface2)', border: '1px solid var(--border2)', borderRadius: 5, color: 'var(--t2)', fontSize: 11, fontWeight: 700, cursor: 'pointer', fontFamily: 'inherit', letterSpacing: '0.04em', textTransform: 'uppercase' }}>
              Ping Feed
            </button>
            <button onClick={() => onEdit && onEdit(cam)}
              style={{ padding: '7px 12px', background: '#fff', border: '1px solid var(--border2)', borderRadius: 5, color: 'var(--t2)', fontSize: 11, fontWeight: 700, cursor: 'pointer', fontFamily: 'inherit', letterSpacing: '0.04em', textTransform: 'uppercase' }}>
              Edit
            </button>
            <button onClick={() => onArchive && onArchive(cam)}
              style={{ padding: '7px 12px', background: 'rgba(217,119,6,.12)', border: '1px solid rgba(217,119,6,.25)', borderRadius: 5, color: 'var(--amber)', fontSize: 11, fontWeight: 700, cursor: 'pointer', fontFamily: 'inherit', letterSpacing: '0.04em', textTransform: 'uppercase' }}>
              Archive
            </button>
            <button onClick={() => onDelete && onDelete(cam)}
              style={{ padding: '7px 12px', background: 'var(--red-light)', border: '1px solid rgba(229,62,62,.25)', borderRadius: 5, color: 'var(--red)', fontSize: 11, fontWeight: 700, cursor: 'pointer', fontFamily: 'inherit', letterSpacing: '0.04em', textTransform: 'uppercase' }}>
              {cam.hasHistory ? 'Delete Locked' : 'Delete'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

function CameraFleetPage({ onOpenCamera, toast }) {
  const [cameraRows, setCameraRows] = useState([]);
  const [processes, setProcesses] = useState([]);
  const [processSops, setProcessSops] = useState([]);
  const [loadingCameras, setLoadingCameras] = useState(true);
  const [backendError, setBackendError] = useState('');
  const [showNewCamera, setShowNewCamera] = useState(false);
  const [creatingCamera, setCreatingCamera] = useState(false);
  const [editingCameraId, setEditingCameraId] = useState(null);
  const [uploadingVideo, setUploadingVideo] = useState(false);
  const [videoFile, setVideoFile] = useState(null);
  const [videoPreviewUrl, setVideoPreviewUrl] = useState('');
  const [videoFirstFrame, setVideoFirstFrame] = useState('');
  const [originalVideoSrc, setOriginalVideoSrc] = useState('');
  const [newCameraForm, setNewCameraForm] = useState({
    id: '',
    name: '',
    processId: '',
    sopId: '',
    process: '',
    station: '',
    videoSrc: '',
    status: 'online',
  });
  const [query, setQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [riskFilter, setRiskFilter] = useState('all');
  const [processFilter, setProcessFilter] = useState('all');
  const [viewMode, setViewMode] = useState('grid');
  const [sortBy, setSortBy] = useState('risk');
  const [refreshTick, setRefreshTick] = useState(0);
  const toAbsoluteMediaUrl = useCallback(path => {
    if (!path) return '';
    return path.startsWith('/media/') ? `${API}${path}` : path;
  }, []);
  const buildNextCameraId = useCallback((rows = cameraRows) => {
    const matched = rows
      .map(cam => (cam.id || '').match(/^CAM-([A-Z])(\d{2})$/))
      .filter(Boolean)
      .map(match => ({ letter: match[1], num: Number(match[2]) }));
    if (!matched.length) return 'CAM-A01';
    matched.sort((a, b) => a.letter === b.letter ? a.num - b.num : a.letter.localeCompare(b.letter));
    const last = matched[matched.length - 1];
    let nextLetter = last.letter;
    let nextNum = last.num + 1;
    if (nextNum > 99) {
      nextLetter = String.fromCharCode(last.letter.charCodeAt(0) + 1);
      nextNum = 1;
    }
    return `CAM-${nextLetter}${String(nextNum).padStart(2, '0')}`;
  }, [cameraRows]);

  useEffect(() => {
    let cancelled = false;
    setLoadingCameras(true);
    setBackendError('');
    fetch(`${API}/api/cameras`)
      .then(r => r.ok ? r.json() : Promise.reject(new Error(`HTTP ${r.status}`)))
      .then(data => {
        if (cancelled) return;
        if (!Array.isArray(data)) throw new Error('Invalid backend response');
        setCameraRows(data);
      })
      .catch(err => {
        if (cancelled) return;
        setCameraRows([]);
        setBackendError(err.message || 'Unable to reach backend');
      })
      .finally(() => {
        if (!cancelled) setLoadingCameras(false);
      });
    return () => { cancelled = true; };
  }, [refreshTick]);

  useEffect(() => {
    fetch(`${API}/api/processes`)
      .then(r => r.ok ? r.json() : [])
      .then(data => { if (Array.isArray(data)) setProcesses(data); })
      .catch(() => {});
  }, []);

  useEffect(() => {
    if (!newCameraForm.processId) {
      setProcessSops([]);
      setNewCameraForm(p => ({ ...p, sopId: '' }));
      return;
    }
    fetch(`${API}/api/processes/${newCameraForm.processId}/sops`)
      .then(r => r.ok ? r.json() : [])
      .then(data => {
        if (!Array.isArray(data)) {
          setProcessSops([]);
          return;
        }
        setProcessSops(data);
        setNewCameraForm(p => {
          const exists = data.some(s => String(s.id) === String(p.sopId));
          return exists ? p : { ...p, sopId: '' };
        });
      })
      .catch(() => setProcessSops([]));
  }, [newCameraForm.processId]);

  useEffect(() => {
    if (!showNewCamera) {
      setVideoPreviewUrl('');
      setVideoFirstFrame('');
      setVideoFile(null);
    }
  }, [showNewCamera]);

  const processOptions = ['all'].concat(Array.from(new Set(cameraRows.map(cam => cam.process))).sort());
  const normalizedQuery = query.trim().toLowerCase();
  const filteredCameras = cameraRows
    .filter(cam => {
      if (statusFilter !== 'all' && cam.status !== statusFilter) return false;
      if (riskFilter !== 'all' && cam.risk !== riskFilter) return false;
      if (processFilter !== 'all' && cam.process !== processFilter) return false;
      if (!normalizedQuery) return true;
      const haystack = [cam.id, cam.name, cam.process, cam.station, cam.risk].join(' ').toLowerCase();
      return haystack.includes(normalizedQuery);
    })
    .slice()
    .sort((a, b) => {
      const riskOrder = { CRITICAL: 0, HIGH: 1, MED: 2, LOW: 3, 'N/A': 4 };
      const statusOrder = { critical: 0, delay: 1, online: 2, offline: 3 };
      if (sortBy === 'name') return a.name.localeCompare(b.name);
      if (sortBy === 'alerts') return (b.alerts || 0) - (a.alerts || 0);
      if (sortBy === 'status') return (statusOrder[a.status] ?? 99) - (statusOrder[b.status] ?? 99);
      return (riskOrder[a.risk] ?? 99) - (riskOrder[b.risk] ?? 99);
    });

  const summary = {
    total: cameraRows.length,
    online: cameraRows.filter(cam => cam.status === 'online').length,
    attention: cameraRows.filter(cam => cam.status === 'critical' || cam.status === 'delay').length,
    offline: cameraRows.filter(cam => cam.status === 'offline').length,
    alerts: cameraRows.reduce((sum, cam) => sum + (cam.alerts || 0), 0),
  };

  const pingCamera = () => {
    setRefreshTick(v => v + 1);
  };

  const resetNewCameraForm = () => setNewCameraForm({
    id: '',
    name: '',
    processId: '',
    sopId: '',
    process: '',
    station: '',
    videoSrc: '',
    status: 'online',
  });

  const removeStoredVideo = async videoUrl => {
    if (!videoUrl || !videoUrl.startsWith('/media/videos/')) return;
    try {
      await fetch(`${API}/api/media?url=${encodeURIComponent(videoUrl)}`, { method: 'DELETE' });
    } catch {}
  };

  const closeCameraModal = async () => {
    const currentVideoSrc = (newCameraForm.videoSrc || '').trim();
    const shouldCleanup = currentVideoSrc && currentVideoSrc !== originalVideoSrc && currentVideoSrc.startsWith('/media/videos/');
    if (shouldCleanup) {
      await removeStoredVideo(currentVideoSrc);
    }
    setShowNewCamera(false);
    setEditingCameraId(null);
    setVideoFile(null);
    setVideoPreviewUrl('');
    setVideoFirstFrame('');
    setOriginalVideoSrc('');
    resetNewCameraForm();
  };

  const loadNextCameraId = async () => {
    const localId = buildNextCameraId();
    setNewCameraForm(p => ({ ...p, id: p.id || localId }));
    try {
      const res = await fetch(`${API}/api/cameras/next-id`);
      const data = await res.json();
      if (res.ok && data.id) {
        setNewCameraForm(p => ({ ...p, id: data.id }));
        return;
      }
    } catch {}
    setNewCameraForm(p => ({ ...p, id: localId }));
  };

  const submitCamera = async () => {
    const resolvedCameraId = (newCameraForm.id || buildNextCameraId()).trim().toUpperCase();
    if (!newCameraForm.name.trim()) {
      toast && toast('Camera Name is required', '⚠', 'var(--amber)');
      return;
    }
    if (!newCameraForm.processId) {
      toast && toast('Please select a Process', '⚠', 'var(--amber)');
      return;
    }
    if (uploadingVideo) {
      toast && toast('Please wait for the video upload to finish', '⚠', 'var(--amber)');
      return;
    }

    setCreatingCamera(true);
    try {
      const isEdit = !!editingCameraId;
      const targetId = (editingCameraId || resolvedCameraId).trim().toUpperCase();
      const uploadedVideoSrc = newCameraForm.videoSrc.trim();

      const res = await fetch(isEdit ? `${API}/api/cameras/${targetId}` : `${API}/api/cameras`, {
        method: isEdit ? 'PUT' : 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          ...(isEdit ? {} : { id: resolvedCameraId }),
          name: newCameraForm.name.trim(),
          processId: newCameraForm.processId ? Number(newCameraForm.processId) : null,
          sopId: newCameraForm.sopId ? Number(newCameraForm.sopId) : null,
          process: newCameraForm.process.trim(),
          station: newCameraForm.station.trim(),
          videoSrc: uploadedVideoSrc,
          status: newCameraForm.status,
        }),
      });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error(data.detail || `HTTP ${res.status}`);

      setCameraRows(prev => {
        const withoutDup = prev.filter(cam => cam.id !== data.id);
        return [...withoutDup, data];
      });
      setShowNewCamera(false);
      setEditingCameraId(null);
      setVideoFile(null);
      setVideoPreviewUrl('');
      setVideoFirstFrame('');
      setOriginalVideoSrc('');
      resetNewCameraForm();
      setRefreshTick(v => v + 1);
      toast && toast(`Camera ${data.id} ${isEdit ? 'updated' : 'created'}`, '✓');
    } catch (err) {
      toast && toast(`${editingCameraId ? 'Update' : 'Create'} camera failed: ${err.message}`, '⚠', 'var(--red)');
    } finally {
      setCreatingCamera(false);
    }
  };

  const openNewCameraModal = () => {
    setEditingCameraId(null);
    resetNewCameraForm();
    setVideoFile(null);
    setVideoPreviewUrl('');
    setVideoFirstFrame('');
    setOriginalVideoSrc('');
    setNewCameraForm(p => ({ ...p, id: buildNextCameraId() }));
    setShowNewCamera(true);
    loadNextCameraId();
  };

  const openEditCameraModal = cam => {
    setEditingCameraId(cam.id);
    setNewCameraForm({
      id: cam.id || '',
      name: cam.name || '',
      processId: cam.processId ? String(cam.processId) : '',
      sopId: cam.sopId ? String(cam.sopId) : '',
      process: cam.process || '',
      station: cam.station || '',
      videoSrc: cam.videoSrc || '',
      status: cam.status || 'online',
    });
    setOriginalVideoSrc(cam.videoSrc || '');
    setVideoFile(null);
    setVideoPreviewUrl(toAbsoluteMediaUrl(cam.videoSrc || ''));
    setVideoFirstFrame(toAbsoluteMediaUrl(cam.thumbnailUrl || ''));
    setShowNewCamera(true);
  };

  const deleteCamera = async cam => {
    if (!window.confirm(`Delete camera ${cam.id}? This cannot be undone.`)) return;
    if (cam.hasHistory) {
      toast && toast(`Camera ${cam.id} cannot be deleted because it has linked alerts, events, or analysis history. Use Archive instead.`, 'âš ', 'var(--amber)');
      return;
    }
    try {
      const res = await fetch(`${API}/api/cameras/${cam.id}`, { method: 'DELETE' });
      if (!res.ok) {
        const data = await res.json().catch(() => ({}));
        throw new Error(data.detail || `HTTP ${res.status}`);
      }
      setCameraRows(prev => prev.filter(row => row.id !== cam.id));
      toast && toast(`Camera ${cam.id} deleted`, '✓');
    } catch (err) {
      toast && toast(`Delete camera failed: ${err.message}`, '⚠', 'var(--red)');
    }
  };

  const archiveCamera = async cam => {
    if (!window.confirm(`Archive camera ${cam.id}? It will be removed from the active fleet list but its history will be kept.`)) return;
    try {
      const res = await fetch(`${API}/api/cameras/${cam.id}/archive`, { method: 'POST' });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) {
        throw new Error(data.detail || `HTTP ${res.status}`);
      }
      setCameraRows(prev => prev.filter(row => row.id !== cam.id));
      toast && toast(`Camera ${cam.id} archived`, 'âœ“');
    } catch (err) {
      toast && toast(`Archive camera failed: ${err.message}`, 'âš ', 'var(--red)');
    }
  };

  const handleVideoSelect = async file => {
    const currentStoredVideo = (newCameraForm.videoSrc || '').trim();
    if (!file) {
      if (currentStoredVideo && currentStoredVideo !== originalVideoSrc) {
        await removeStoredVideo(currentStoredVideo);
      }
      setVideoFile(null);
      setVideoPreviewUrl('');
      setVideoFirstFrame('');
      setNewCameraForm(p => ({ ...p, videoSrc: originalVideoSrc || '' }));
      setVideoPreviewUrl(toAbsoluteMediaUrl(originalVideoSrc || ''));
      return;
    }

    setVideoFile(file);
    setVideoPreviewUrl('');
    setVideoFirstFrame('');
    setUploadingVideo(true);
    try {
      if (currentStoredVideo && currentStoredVideo !== originalVideoSrc) {
        await removeStoredVideo(currentStoredVideo);
      }
      const uploadFd = new FormData();
      uploadFd.append('file', file);
      const uploadRes = await fetch(`${API}/api/media/upload`, { method: 'POST', body: uploadFd });
      const uploadData = await uploadRes.json().catch(() => ({}));
      if (!uploadRes.ok) throw new Error(uploadData.detail || 'Video upload failed');

      setNewCameraForm(p => ({ ...p, videoSrc: uploadData.url || '' }));
      setVideoPreviewUrl(toAbsoluteMediaUrl(uploadData.url || ''));
      setVideoFirstFrame(toAbsoluteMediaUrl(uploadData.thumbnail_url || ''));
      toast && toast('Video uploaded and preview generated', '✓');
    } catch (err) {
      setVideoFile(null);
      setVideoPreviewUrl('');
      setVideoFirstFrame('');
      setNewCameraForm(p => ({ ...p, videoSrc: originalVideoSrc || '' }));
      setVideoPreviewUrl(toAbsoluteMediaUrl(originalVideoSrc || ''));
      toast && toast(`Video preview failed: ${err.message}`, '⚠', 'var(--red)');
    } finally {
      setUploadingVideo(false);
    }
  };

  return (
    <div style={{ flex: 1, overflowY: 'auto', padding: 16 }}>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(5,minmax(0,1fr))', gap: 8, marginBottom: 16 }}>
        <KPICard value={summary.total} label="Total Cameras" delta={`${filteredCameras.length} visible in current filter`} color="blue" />
        <KPICard value={summary.online} label="Online" delta="Healthy video links" color="green" />
        <KPICard value={summary.attention} label="Need Attention" delta="Critical or delayed streams" color="amber" />
        <KPICard value={summary.offline} label="Offline" delta="Requires local check" color="gray" />
        <KPICard value={summary.alerts} label="Open Alerts" delta="Across all camera feeds" color="red" />
      </div>

      <Panel>
        <PanelHead title="Camera Fleet" icon="⊞"
          right={<div style={{ display: 'flex', gap: 6 }}>
            <Btn variant="primary" size="sm" onClick={openNewCameraModal}>+ New Camera</Btn>
            <Btn variant={viewMode === 'grid' ? 'teal' : 'ghost'} size="sm" onClick={() => setViewMode('grid')}>Grid</Btn>
            <Btn variant={viewMode === 'list' ? 'teal' : 'ghost'} size="sm" onClick={() => setViewMode('list')}>List</Btn>
            <Btn variant="teal" size="sm" onClick={() => setRefreshTick(v => v + 1)}>Refresh {refreshTick ? `· ${refreshTick}` : ''}</Btn>
          </div>} />
        <div style={{ padding: 14 }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12, gap: 12, flexWrap: 'wrap' }}>
            <div style={{ fontSize: 11, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.08em', color: 'var(--t2)', display: 'flex', alignItems: 'center', gap: 8 }}>
              <span style={{ display: 'inline-block', width: 12, height: 2, background: 'var(--blue)' }} />All Cameras · Build A1
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, flexWrap: 'wrap' }}>
              <Badge color="red">{cameraRows.filter(cam => cam.risk === 'CRITICAL').length} Critical Risk</Badge>
              <Badge color="amber">{cameraRows.filter(cam => cam.status === 'delay').length} Delayed</Badge>
              <Badge color="gray">{cameraRows.filter(cam => !cam.videoSrc).length} No Preview</Badge>
              {loadingCameras ? <Badge color="blue">Syncing Backend</Badge> : (backendError ? <Badge color="red">Backend unavailable</Badge> : <Badge color="green">Backend Live</Badge>)}
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'minmax(220px,1.4fr) repeat(4,minmax(140px,1fr))', gap: 8, marginBottom: 12 }}>
            <input
              value={query}
              onChange={e => setQuery(e.target.value)}
              placeholder="Search by camera, process, station, or risk"
              style={{ background: 'var(--surface2)', border: '1px solid var(--border2)', borderRadius: 6, padding: '8px 10px', fontSize: 12, color: 'var(--t1)', outline: 'none', width: '100%' }}
            />
            <select value={statusFilter} onChange={e => setStatusFilter(e.target.value)} style={{ background: 'var(--surface2)', border: '1px solid var(--border2)', borderRadius: 6, padding: '8px 10px', fontSize: 12, color: 'var(--t1)', outline: 'none' }}>
              <option value="all">All Status</option>
              <option value="online">Online</option>
              <option value="delay">Delay</option>
              <option value="critical">Critical</option>
              <option value="offline">Offline</option>
            </select>
            <select value={riskFilter} onChange={e => setRiskFilter(e.target.value)} style={{ background: 'var(--surface2)', border: '1px solid var(--border2)', borderRadius: 6, padding: '8px 10px', fontSize: 12, color: 'var(--t1)', outline: 'none' }}>
              <option value="all">All Risk</option>
              <option value="CRITICAL">Critical</option>
              <option value="HIGH">High</option>
              <option value="MED">Medium</option>
              <option value="LOW">Low</option>
              <option value="N/A">N/A</option>
            </select>
            <select value={processFilter} onChange={e => setProcessFilter(e.target.value)} style={{ background: 'var(--surface2)', border: '1px solid var(--border2)', borderRadius: 6, padding: '8px 10px', fontSize: 12, color: 'var(--t1)', outline: 'none' }}>
              <option value="all">All Process</option>
              {processOptions.slice(1).map(process => <option key={process} value={process}>{process}</option>)}
            </select>
            <select value={sortBy} onChange={e => setSortBy(e.target.value)} style={{ background: 'var(--surface2)', border: '1px solid var(--border2)', borderRadius: 6, padding: '8px 10px', fontSize: 12, color: 'var(--t1)', outline: 'none' }}>
              <option value="risk">Sort: Risk</option>
              <option value="alerts">Sort: Alerts</option>
              <option value="status">Sort: Status</option>
              <option value="name">Sort: Name</option>
            </select>
          </div>

          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 12 }}>
            {[
              { key: 'all', label: 'All' },
              { key: 'online', label: 'Healthy' },
              { key: 'critical', label: 'Critical' },
              { key: 'delay', label: 'Delayed' },
              { key: 'offline', label: 'Offline' },
            ].map(item => (
              <button
                key={item.key}
                onClick={() => setStatusFilter(item.key)}
                style={{ padding: '6px 10px', borderRadius: 999, border: `1px solid ${statusFilter === item.key ? 'rgba(29,110,245,.3)' : 'var(--border2)'}`, background: statusFilter === item.key ? 'var(--blue-light)' : '#fff', color: statusFilter === item.key ? 'var(--blue)' : 'var(--t2)', fontSize: 11, fontWeight: 700, cursor: 'pointer', fontFamily: 'inherit' }}
              >
                {item.label}
              </button>
            ))}
            {(query || riskFilter !== 'all' || processFilter !== 'all' || statusFilter !== 'all' || sortBy !== 'risk') ? (
              <button
                onClick={() => { setQuery(''); setStatusFilter('all'); setRiskFilter('all'); setProcessFilter('all'); setSortBy('risk'); }}
                style={{ padding: '6px 10px', borderRadius: 999, border: '1px solid var(--border2)', background: '#fff', color: 'var(--t3)', fontSize: 11, fontWeight: 700, cursor: 'pointer', fontFamily: 'inherit' }}
              >
                Reset Filters
              </button>
            ) : null}
          </div>

          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10, gap: 8, flexWrap: 'wrap' }}>
            <div style={{ fontSize: 11, color: 'var(--t3)' }}>
              Showing <span style={{ color: 'var(--t1)', fontWeight: 700 }}>{filteredCameras.length}</span> of <span style={{ color: 'var(--t1)', fontWeight: 700 }}>{cameraRows.length}</span> cameras
            </div>
            <div style={{ fontSize: 10, color: 'var(--t3)', textTransform: 'uppercase', letterSpacing: '0.06em' }}>
              {loadingCameras ? 'Loading camera fleet from backend' : (backendError ? `Backend unavailable${backendError ? ` · ${backendError}` : ''}` : 'Priority ordered for operations triage')}
            </div>
          </div>

          {filteredCameras.length ? (
            <div style={{ display: 'grid', gridTemplateColumns: viewMode === 'grid' ? 'repeat(auto-fill,minmax(290px,1fr))' : '1fr', gap: 10 }}>
              {filteredCameras.map(cam => <CameraFleetCard key={cam.id} cam={cam} mode={viewMode} onOpen={() => onOpenCamera(cam)} onPing={pingCamera} onEdit={openEditCameraModal} onDelete={deleteCamera} onArchive={archiveCamera} />)}
            </div>
          ) : (
            <div style={{ border: '1px dashed var(--border2)', borderRadius: 10, padding: '28px 16px', background: 'var(--surface2)', textAlign: 'center' }}>
              <div style={{ fontSize: 14, fontWeight: 700, color: 'var(--t2)', marginBottom: 6 }}>
                {backendError ? 'Backend unavailable' : 'No cameras match this filter set'}
              </div>
              <div style={{ fontSize: 11, color: 'var(--t3)', marginBottom: 12 }}>
                {backendError
                  ? 'Camera data could not be loaded from the backend. Check the API/database connection and try refresh again.'
                  : 'Try broadening status, process, or search criteria to restore the fleet view.'}
              </div>
              <Btn
                variant="ghost"
                size="sm"
                onClick={() => {
                  if (backendError) {
                    setRefreshTick(v => v + 1);
                    return;
                  }
                  setQuery('');
                  setStatusFilter('all');
                  setRiskFilter('all');
                  setProcessFilter('all');
                  setSortBy('risk');
                }}
              >
                {backendError ? 'Retry Backend' : 'Clear Filters'}
              </Btn>
            </div>
          )}
        </div>
      </Panel>

      <Modal
        show={showNewCamera}
        onClose={closeCameraModal}
        title={editingCameraId ? `Edit Camera · ${editingCameraId}` : "+ New Camera"}
        footer={<><Btn variant="ghost" onClick={closeCameraModal}>Cancel</Btn><Btn variant="primary" onClick={submitCamera} disabled={creatingCamera || uploadingVideo}>{uploadingVideo ? 'Preparing Video…' : creatingCamera ? (editingCameraId ? 'Saving…' : 'Creating…') : (editingCameraId ? 'Save Changes' : 'Create Camera')}</Btn></>}
      >
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, marginBottom: 12 }}>
          <FormGroup label="Camera ID">
            <FormInput
              value={newCameraForm.id}
              onChange={v => setNewCameraForm(p => ({ ...p, id: v.toUpperCase() }))}
              placeholder="CAM-A09"
              disabled
              style={{ borderColor: !newCameraForm.id ? 'var(--amber)' : 'var(--border2)' }}
            />
          </FormGroup>
          <FormGroup label="Status">
            <select
              value={newCameraForm.status}
              onChange={e => setNewCameraForm(p => ({ ...p, status: e.target.value }))}
              style={{ background: 'var(--surface2)', border: '1px solid var(--border2)', borderRadius: 6, padding: '7px 10px', fontSize: 12, outline: 'none', fontFamily: 'inherit' }}
            >
              <option value="online">Online</option>
              <option value="delay">Delay</option>
              <option value="offline">Offline</option>
              <option value="critical">Critical</option>
            </select>
          </FormGroup>
        </div>

        <FormGroup label="Camera Name">
          <FormInput
            value={newCameraForm.name}
            onChange={v => setNewCameraForm(p => ({ ...p, name: v }))}
            placeholder="Press Machine 3"
            style={{ borderColor: !newCameraForm.name ? 'var(--amber)' : 'var(--border2)' }}
          />
        </FormGroup>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, marginTop: 12 }}>
          <FormGroup label="Process">
            <select
              value={newCameraForm.processId}
              onChange={e => {
                const nextId = e.target.value;
                const proc = processes.find(p => String(p.id) === String(nextId));
                setNewCameraForm(p => ({ ...p, processId: nextId, process: proc?.name || '', sopId: '' }));
              }}
              style={{ background: 'var(--surface2)', border: '1px solid var(--border2)', borderRadius: 6, padding: '7px 10px', fontSize: 12, outline: 'none', fontFamily: 'inherit' }}
            >
              <option value="">Select Process</option>
              {processes.map(proc => <option key={proc.id} value={proc.id}>{proc.name}</option>)}
            </select>
          </FormGroup>
          <FormGroup label="Station">
            <FormInput
              value={newCameraForm.station}
              onChange={v => setNewCameraForm(p => ({ ...p, station: v }))}
              placeholder="Station 03"
            />
          </FormGroup>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, marginTop: 12 }}>
          <FormGroup label="SOP">
            <select
              value={newCameraForm.sopId}
              onChange={e => setNewCameraForm(p => ({ ...p, sopId: e.target.value }))}
              disabled={!newCameraForm.processId}
              style={{ background: 'var(--surface2)', border: '1px solid var(--border2)', borderRadius: 6, padding: '7px 10px', fontSize: 12, outline: 'none', fontFamily: 'inherit', opacity: !newCameraForm.processId ? 0.65 : 1 }}
            >
              <option value="">{newCameraForm.processId ? 'Select SOP' : 'Select Process First'}</option>
              {processSops.map(sop => <option key={sop.id} value={sop.id}>{sop.code} · {sop.title}</option>)}
            </select>
          </FormGroup>
          <FormGroup label="Video Source">
            <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
              <input
                type="file"
                accept="video/*"
                onChange={e => handleVideoSelect(e.target.files?.[0] || null)}
                style={{ background: 'var(--surface2)', border: '1px solid var(--border2)', borderRadius: 6, padding: '7px 10px', fontSize: 12, outline: 'none', fontFamily: 'inherit' }}
              />
              <div style={{ fontSize: 10, color: 'var(--t3)' }}>
                {uploadingVideo ? 'Uploading video and generating preview…' : (videoFile ? `Selected: ${videoFile.name}` : (newCameraForm.videoSrc ? `Stored path: ${newCameraForm.videoSrc}` : 'No video file selected'))}
              </div>
              {videoFirstFrame ? (
                <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                  <div style={{ fontSize: 10, color: 'var(--t3)', textTransform: 'uppercase', letterSpacing: '0.06em' }}>First Frame Preview</div>
                  <img
                    src={videoFirstFrame}
                    alt="First frame preview"
                    onError={() => setVideoFirstFrame('')}
                    style={{ width: '100%', maxHeight: 180, objectFit: 'contain', borderRadius: 8, border: '1px solid var(--border)', background: '#0a1020' }}
                  />
                </div>
              ) : null}
              {(videoPreviewUrl || newCameraForm.videoSrc) ? (
                <video
                  src={videoPreviewUrl || toAbsoluteMediaUrl(newCameraForm.videoSrc)}
                  controls
                  muted
                  style={{ width: '100%', maxHeight: 180, borderRadius: 8, background: '#0a1020' }}
                />
              ) : null}
            </div>
          </FormGroup>
        </div>

        <div style={{ background: 'rgba(29,110,245,.06)', border: '1px solid rgba(29,110,245,.18)', borderRadius: 8, padding: '12px 14px', marginTop: 14 }}>
          <div style={{ fontSize: 10, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.08em', color: 'var(--blue)', marginBottom: 6 }}>Preview</div>
          <div style={{ fontSize: 12, color: 'var(--t2)', lineHeight: 1.7 }}>
            Camera <b style={{ color: 'var(--t1)' }}>{newCameraForm.id || 'CAM-XXX'}</b> will appear in the fleet list with process <b style={{ color: 'var(--t1)' }}>{newCameraForm.process || 'Unassigned'}</b>, station <b style={{ color: 'var(--t1)' }}>{newCameraForm.station || newCameraForm.name || 'Unnamed Station'}</b>, and SOP <b style={{ color: 'var(--t1)' }}>{processSops.find(s => String(s.id) === String(newCameraForm.sopId))?.title || 'Not selected'}</b>.
          </div>
        </div>
      </Modal>
    </div>
  );
}

function CameraDetail({ cam, onBack, toast }) {
  const [selPrompt, setSelPrompt] = useState(0);
  const [promptText, setPromptText] = useState(PROMPTS[0].text);
  const [vlmRunning, setVlmRunning] = useState(false);
  const [showModal, setShowModal] = useState(false);
  const [sopData, setSopData] = useState(null);
  const [videoError, setVideoError] = useState('');

  var toAbsMedia = function(path) {
    if (!path) return '';
    // Use relative path — nginx proxies /media/ to backend and handles Range requests
    return path.startsWith('/media/') ? API + path : path;
  };

  React.useEffect(function() {
    if (!cam.processId || !cam.sopId) return;
    fetch(API + '/api/processes/' + cam.processId + '/sops/' + cam.sopId)
      .then(function(r) { return r.ok ? r.json() : null; })
      .then(function(d) { if (d) setSopData(d); })
      .catch(function() {});
  }, [cam.processId, cam.sopId]);

  React.useEffect(function() {
    setVideoError('');
  }, [cam.videoSrc]);

  var sopSteps = sopData ? (sopData.steps || []) : [];
  var safetyRules = [];
  if (sopData) { try { safetyRules = JSON.parse(sopData.safety_rules || '[]'); } catch(e) {} }
  var ppeList = [];
  if (sopData) { try { ppeList = JSON.parse(sopData.equipment || '[]'); } catch(e) {} }

  const runVLM = () => {
    setVlmRunning(true); toast('VLM กำลังวิเคราะห์วิดีโอ…', '✦');
    setTimeout(() => { setVlmRunning(false); toast('VLM วิเคราะห์เสร็จแล้ว!', '✓'); }, 2200);
  };

  const tl = [
    { t: '14:22:01', s: 'medium',   e: 'Operator stood in restricted zone' },
    { t: '14:22:11', s: 'high',     e: 'Hand detected near moving part' },
    { t: '14:22:19', s: 'critical', e: 'Machine running + hand in zone' },
    { t: '14:22:28', s: 'low',      e: 'Floor clutter detected' },
  ];

  return (
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
      <div style={{ background: '#fff', borderBottom: '1px solid var(--border)', padding: '8px 16px', display: 'flex', alignItems: 'center', gap: 10, flexShrink: 0, flexWrap: 'wrap', boxShadow: '0 1px 4px rgba(29,110,245,.05)' }}>
        <Btn variant="ghost" size="sm" onClick={onBack}>← Back</Btn>
        <div style={{ fontSize: 11, color: 'var(--t3)' }}>
          Process: <b style={{ color: 'var(--t1)' }}>{cam.process || '—'}</b> &nbsp;|&nbsp; Station: <b style={{ color: 'var(--t1)' }}>{cam.station || '—'}</b> &nbsp;|&nbsp; CCTV: <b style={{ color: 'var(--blue)' }}>{cam.id}</b>
          {sopData && <span> &nbsp;|&nbsp; SOP: <b style={{ color: 'var(--blue)' }}>{sopData.code} — {sopData.title}</b></span>}
        </div>
        <div style={{ marginLeft: 'auto', display: 'flex', gap: 8, alignItems: 'center' }}>
          <StatusPill status={cam.status} />
          <Badge color="blue">AI Active</Badge>
          <Btn variant="danger" size="sm" onClick={() => toast('Alert sent!', '⚠', 'var(--red)')}>⚠ Send Alert</Btn>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 265px', gap: 10, flex: 1, overflow: 'hidden', padding: 10, background: 'var(--bg)' }}>
        {/* LEFT */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8, overflow: 'hidden', minWidth: 0 }}>
          <Panel>
            <PanelHead title={`Monitor — ${cam.name}`} icon="⬡"
              right={<>
                {cam.videoSrc && <Badge color="green">🎬 Recorded Video</Badge>}
                {!cam.videoSrc && <Badge color="gray">Synthetic Feed</Badge>}
                <Badge>{cam.fps} FPS</Badge>
              </>} />
            {cam.videoSrc ? (
              <div style={{ background: '#0a1020', position: 'relative' }}>
                <video
                  key={toAbsMedia(cam.videoSrc)}
                  src={toAbsMedia(cam.videoSrc)}
                  controls
                  onLoadedData={() => setVideoError('')}
                  onError={() => setVideoError('This video file loaded from storage but could not be decoded by the browser. Re-upload it after the backend ffmpeg update so it can be converted to H.264.')}
                  style={{ width: '100%', maxHeight: 320, objectFit: 'contain', display: 'block', background: '#0a1020' }}
                />
                {videoError ? (
                  <div style={{ padding: '10px 12px', background: 'var(--red-light)', borderTop: '1px solid rgba(229,62,62,.2)', fontSize: 11, color: 'var(--red)', lineHeight: 1.45 }}>
                    {videoError}
                  </div>
                ) : null}
                <div style={{ position: 'absolute', top: 8, left: 8, display: 'flex', gap: 5, pointerEvents: 'none' }}>
                  <span style={{ fontSize: 9, fontWeight: 700, background: 'rgba(0,0,0,.65)', color: '#fff', padding: '2px 8px', borderRadius: 4, letterSpacing: '0.06em' }}>{cam.id}</span>
                  <StatusPill status={cam.status} />
                </div>
              </div>
            ) : (
              <div style={{ position: 'relative', overflow: 'hidden' }}>
                <MockFeed camId={cam.id} status={cam.status} height={192} />
                <div style={{ position: 'absolute', top: 52, left: 68, width: 120, height: 88, border: '1.5px dashed rgba(229,62,62,.8)', borderRadius: 3, display: 'flex', alignItems: 'flex-start', pointerEvents: 'none' }}>
                  <span style={{ fontSize: 8, color: 'var(--red)', fontWeight: 700, padding: '1px 5px', background: 'rgba(229,62,62,.15)' }}>⚠ DANGER ZONE</span>
                </div>
                <div style={{ position: 'absolute', top: 90, right: 48, width: 88, height: 68, border: '1.5px dashed rgba(217,119,6,.7)', borderRadius: 3, pointerEvents: 'none' }}>
                  <span style={{ fontSize: 8, color: 'var(--amber)', fontWeight: 700, padding: '1px 4px' }}>WARN</span>
                </div>
                {cam.status === 'critical' && (
                  <div className="blink" style={{ position: 'absolute', top: 8, right: 8, background: 'var(--red)', color: '#fff', fontSize: 9, fontWeight: 800, padding: '3px 9px', borderRadius: 4, letterSpacing: '0.07em', pointerEvents: 'none' }}>⚠ CRITICAL</div>
                )}
                <div style={{ position: 'absolute', bottom: 8, left: 0, right: 0, textAlign: 'center', fontSize: 10, color: 'rgba(255,255,255,.4)' }}>ไม่มีวิดีโอ — ไปที่ Edit Camera เพื่อแนบวิดีโอ</div>
              </div>
            )}
            <div style={{ display: 'flex', gap: 5, padding: '7px 10px', background: '#f0f5ff', borderTop: '1px solid var(--border)', flexWrap: 'wrap', alignItems: 'center' }}>
              <span style={{ fontSize: 10, color: 'var(--t3)', marginRight: 4 }}>Camera:</span>
              <span style={{ fontSize: 10, fontWeight: 700, color: 'var(--blue)', marginRight: 8 }}>{cam.id} — {cam.station || '—'}</span>
              {cam.videoSrc && <span style={{ fontSize: 10, color: 'var(--t3)', fontFamily: "'IBM Plex Mono',monospace", marginLeft: 'auto' }}>{cam.videoSrc.split('/').pop()}</span>}
            </div>
          </Panel>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8, flex: 1, minHeight: 0 }}>
            <Panel style={{ overflow: 'hidden' }}>
              <PanelHead title="Safety Rules / AI Analysis" icon="⚑" right={<Btn variant="teal" size="sm" onClick={() => setShowModal(true)}>✦ Generate</Btn>} />
              <div style={{ overflowY: 'auto', padding: '10px 12px', flex: 1 }}>
                {[
                  { label: 'Unsafe Actions', color: 'var(--red)', items: ['Hand entered danger zone during machine run', 'Operator skipped barcode scan step', 'No glove / no face shield detected'] },
                  { label: 'Unsafe Conditions', color: 'var(--amber)', items: ['Oil spill detected near machine base', 'Guard door open while machine active'] },
                  { label: 'Near-Miss', color: 'var(--red)', items: ['Machine running + hand in zone — CRITICAL'] },
                ].map(cat => (
                  <div key={cat.label} style={{ marginBottom: 10 }}>
                    <div style={{ fontSize: 9, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.09em', color: 'var(--t2)', display: 'flex', alignItems: 'center', gap: 5, marginBottom: 5 }}>
                      <span style={{ width: 5, height: 5, borderRadius: '50%', background: cat.color, display: 'inline-block' }} />{cat.label}
                    </div>
                    {cat.items.map(it => (
                      <div key={it} style={{ fontSize: 11, padding: '5px 8px', borderRadius: 4, marginBottom: 3, borderLeft: `2px solid ${cat.color}`, background: cat.color === 'var(--amber)' ? 'var(--amber-light)' : 'var(--red-light)', color: 'var(--t1)', lineHeight: 1.5 }}>{it}</div>
                    ))}
                  </div>
                ))}
                <div style={{ background: 'rgba(29,110,245,.06)', border: '1px solid rgba(29,110,245,.18)', borderRadius: 6, padding: '9px 11px', marginTop: 6 }}>
                  <div style={{ fontSize: 9, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.09em', color: 'var(--blue)', marginBottom: 5 }}>✦ AI Suggestion</div>
                  <div style={{ fontSize: 11, color: 'var(--t1)', lineHeight: 1.7 }}>Add rule: "Confirm full machine stop before hand enters press area. Dual-confirmation required before cover open."</div>
                  <div style={{ display: 'flex', gap: 6, marginTop: 8 }}>
                    <Btn variant="teal" size="sm" onClick={() => toast('Rule saved!', '✓')}>Accept</Btn>
                    <Btn variant="ghost" size="sm" onClick={() => setShowModal(true)}>Edit</Btn>
                    <Btn variant="danger" size="sm" onClick={() => toast('Alert sent!', '⚠', 'var(--red)')}>Alert</Btn>
                  </div>
                </div>
              </div>
            </Panel>

            <Panel style={{ overflow: 'hidden' }}>
              <PanelHead title="Event Timeline" icon="⊶" right={<><span style={{ fontSize: 10, color: 'var(--t3)' }}>4 events</span><Btn variant="ghost" size="sm" onClick={() => toast('Exported!', '⬇')}>Export</Btn></>} />
              <div style={{ overflowY: 'auto', padding: '10px 12px', flex: 1 }}>
                {tl.map(row => (
                  <div key={row.t} style={{ display: 'flex', alignItems: 'flex-start', gap: 7, padding: '5px 0', borderBottom: '1px solid var(--border)' }}>
                    <span style={{ fontSize: 10, color: 'var(--t3)', minWidth: 58, fontFamily: "'IBM Plex Mono',monospace" }}>{row.t}</span>
                    <SevBadge sev={row.s} />
                    <span style={{ fontSize: 11, color: 'var(--t1)', lineHeight: 1.5 }}>{row.e}</span>
                  </div>
                ))}
                <div style={{ background: 'rgba(29,110,245,.06)', border: '1px solid rgba(29,110,245,.18)', borderRadius: 6, padding: '9px 11px', marginTop: 8 }}>
                  <div style={{ fontSize: 9, fontWeight: 700, color: 'var(--blue)', textTransform: 'uppercase', letterSpacing: '0.09em', marginBottom: 5 }}>✦ VLM Summary</div>
                  <div style={{ fontSize: 11, color: 'var(--t1)', lineHeight: 1.7 }}>Operator approached press area without confirming stop. Machine guard opened before motion ceased. Near-miss risk: <span style={{ color: 'var(--red)', fontWeight: 600 }}>CRITICAL</span>.</div>
                </div>
                <div style={{ display: 'flex', gap: 6, marginTop: 8 }}>
                  <Btn variant="teal" size="sm" onClick={runVLM} disabled={vlmRunning}>{vlmRunning ? '⟳ Running…' : '▶ Re-run VLM'}</Btn>
                  <Btn variant="ghost" size="sm">Full History</Btn>
                </div>
              </div>
            </Panel>
          </div>
        </div>

        {/* RIGHT */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8, overflowY: 'auto' }}>
          <Panel>
            <PanelHead title={'SOP' + (sopData ? ' — ' + sopData.code : '')} icon="≡"
              right={sopData ? <Badge color="blue">{sopData.title}</Badge> : <span style={{ fontSize: 10, color: 'var(--t3)' }}>ไม่ได้ผูก SOP</span>} />
            <div style={{ padding: '10px 12px', overflowY: 'auto', flex: 1 }}>
              {!sopData && !cam.sopId && (
                <div style={{ fontSize: 11, color: 'var(--t3)', fontStyle: 'italic', textAlign: 'center', padding: 20 }}>ไม่มี SOP ผูกกับกล้องนี้<br />กด Edit เพื่อเลือก SOP</div>
              )}
              {!sopData && cam.sopId && (
                <div style={{ fontSize: 11, color: 'var(--t3)', textAlign: 'center', padding: 20 }}>⟳ กำลังโหลด SOP…</div>
              )}
              {sopData && ppeList.length > 0 && (
                <div style={{ marginBottom: 10 }}>
                  <div style={{ fontSize: 9, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.08em', color: 'var(--t2)', marginBottom: 5 }}>🦺 PPE Required</div>
                  <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4 }}>
                    {ppeList.map(function(item, i) {
                      return <span key={i} style={{ fontSize: 10, background: '#e8f0ff', color: 'var(--blue)', padding: '2px 8px', borderRadius: 20, border: '1px solid rgba(29,110,245,.2)' }}>{item}</span>;
                    })}
                  </div>
                </div>
              )}
              {sopData && sopSteps.length > 0 && (
                <div style={{ marginBottom: 10 }}>
                  <div style={{ fontSize: 9, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.08em', color: 'var(--t2)', marginBottom: 5 }}>📋 Work Steps</div>
                  {sopSteps.map(function(s, i) {
                    var riskColor = { Low: 'var(--t3)', Medium: '#b45309', High: '#c2410c', Critical: 'var(--red)' }[s.title_th] || 'var(--t3)';
                    return (
                      <div key={i} style={{ display: 'flex', alignItems: 'flex-start', gap: 8, padding: '5px 0', borderBottom: '1px solid var(--border)' }}>
                        <div style={{ width: 18, height: 18, borderRadius: '50%', flexShrink: 0, background: 'rgba(29,110,245,.09)', border: '1px solid rgba(29,110,245,.2)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 9, fontWeight: 700, color: 'var(--blue)', marginTop: 1 }}>{s.step_no}</div>
                        <div style={{ flex: 1 }}>
                          <div style={{ fontSize: 11, lineHeight: 1.5, color: 'var(--t1)' }}>{s.title}</div>
                          {s.description && <div style={{ fontSize: 10, color: 'var(--t3)', marginTop: 1 }}>{s.description}</div>}
                        </div>
                        {s.title_th && s.title_th !== 'Low' && <span style={{ fontSize: 9, fontWeight: 700, color: riskColor, flexShrink: 0, marginTop: 2 }}>{s.title_th}</span>}
                      </div>
                    );
                  })}
                </div>
              )}
              {sopData && safetyRules.length > 0 && (
                <div>
                  <div style={{ fontSize: 9, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.08em', color: 'var(--t2)', marginBottom: 5 }}>⚠ Safety Rules</div>
                  {safetyRules.map(function(r, i) {
                    var sevColor = { Low: 'var(--t3)', Medium: '#b45309', High: '#c2410c', Critical: 'var(--red)' }[r.severity] || '#b45309';
                    var sevBg = { Low: 'rgba(100,116,139,.1)', Medium: 'rgba(217,119,6,.1)', High: 'rgba(194,65,12,.1)', Critical: 'var(--red-light)' }[r.severity] || 'rgba(217,119,6,.1)';
                    return (
                      <div key={i} style={{ display: 'flex', gap: 7, alignItems: 'flex-start', padding: '5px 7px', borderRadius: 5, marginBottom: 4, background: sevBg, border: '1px solid ' + sevColor + '33' }}>
                        <span style={{ fontSize: 9, fontWeight: 700, color: sevColor, flexShrink: 0, marginTop: 1 }}>[{r.severity || 'Medium'}]</span>
                        <span style={{ fontSize: 11, color: 'var(--t1)', lineHeight: 1.5 }}>{r.text}</span>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          </Panel>

          <Panel>
            <PanelHead title="Prompt & VLM Control" icon="✦" right={<Badge color="blue">VLM Ready</Badge>} />
            <div style={{ padding: '10px 12px' }}>
              <div style={{ fontSize: 10, color: 'var(--t3)', marginBottom: 6, textTransform: 'uppercase', letterSpacing: '0.07em' }}>Select Prompt Template</div>
              {PROMPTS.map((p, i) => (
                <div key={p.id} onClick={() => { setSelPrompt(i); setPromptText(p.text); }}
                  style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '5px 7px', borderRadius: 5, cursor: 'pointer', marginBottom: 2, background: selPrompt === i ? 'rgba(29,110,245,.08)' : 'transparent', border: selPrompt === i ? '1px solid rgba(29,110,245,.2)' : '1px solid transparent' }}>
                  <div style={{ width: 12, height: 12, borderRadius: '50%', flexShrink: 0, border: `1.5px solid ${selPrompt === i ? 'var(--blue)' : 'var(--border2)'}`, background: selPrompt === i ? 'var(--blue)' : 'transparent', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    {selPrompt === i && <div style={{ width: 4, height: 4, borderRadius: '50%', background: '#fff' }} />}
                  </div>
                  <span style={{ fontSize: 11, color: 'var(--t1)' }}>{p.name}</span>
                </div>
              ))}
              <textarea value={promptText} onChange={e => setPromptText(e.target.value)}
                style={{ width: '100%', background: 'var(--surface2)', border: '1px solid var(--border2)', borderRadius: 5, padding: '8px 10px', fontSize: 10, color: 'var(--t1)', resize: 'vertical', minHeight: 72, outline: 'none', lineHeight: 1.6, fontFamily: "'IBM Plex Mono',monospace", marginTop: 8, marginBottom: 8 }} />
              <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                <Btn variant="primary" size="sm" onClick={runVLM} disabled={vlmRunning}>{vlmRunning ? '⟳ Running…' : '▶ Run VLM'}</Btn>
                <Btn variant="ghost" size="sm" onClick={() => toast('Saved!', '✓')}>Save</Btn>
                <Btn variant="ghost" size="sm">Library</Btn>
                <Btn variant="ghost" size="sm" onClick={() => toast('Compare mode…', '⊙', 'var(--amber)')}>Compare</Btn>
              </div>
            </div>
          </Panel>
        </div>
      </div>

      <Modal show={showModal} onClose={() => setShowModal(false)} title="✦ AI Generate Safety Rule"
        footer={<><Btn variant="ghost" onClick={() => setShowModal(false)}>Cancel</Btn><Btn variant="ghost" onClick={() => { toast('Saved as draft!', '✓'); setShowModal(false); }}>Save Draft</Btn><Btn variant="primary" onClick={() => { toast('Rules published!', '⬆'); setShowModal(false); }}>Publish</Btn></>}>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 12 }}>
          <FormGroup label="Source Camera"><select style={{ background: 'var(--surface2)', border: '1px solid var(--border2)', borderRadius: 6, padding: '7px 10px', fontSize: 12, outline: 'none' }}><option>CAM-A01 — Press Machine 1</option></select></FormGroup>
          <FormGroup label="Time Range"><FormInput value="14:20:00 — 14:25:00" /></FormGroup>
        </div>
        <FormGroup label="Context / Notes"><textarea defaultValue="Operator approaching press area during active cycle. Focus on physical interaction rules." style={{ width: '100%', background: 'var(--surface2)', border: '1px solid var(--border2)', borderRadius: 6, padding: '8px 10px', fontSize: 12, minHeight: 80, outline: 'none', lineHeight: 1.6, resize: 'vertical' }} /></FormGroup>
        <div style={{ background: 'rgba(29,110,245,.06)', border: '1px solid rgba(29,110,245,.18)', borderRadius: 8, padding: '12px 14px', marginTop: 12 }}>
          <div style={{ fontSize: 11, fontWeight: 700, color: 'var(--blue)', marginBottom: 8 }}>✦ AI Generated Output</div>
          <div style={{ fontSize: 12, color: 'var(--t1)', lineHeight: 1.8 }}>
            <b style={{ color: 'var(--red)' }}>Unsafe Actions:</b><br />• Operator must not enter press zone while machine cycle is active<br />• Machine guard must be physically confirmed before approaching<br /><br />
            <b style={{ color: 'var(--amber)' }}>Preventive Rules:</b><br />• Add dual-lock: operator badge + machine stop confirmation<br />• Install proximity sensor alarm within 1.5m of press zone
          </div>
        </div>
      </Modal>
    </div>
  );
}

// ── Page: SOP Management ─────────────────────────────────
const PPE_OPTIONS = ['Gloves', 'Face Shield', 'Safety Shoes', 'Safety Vest', 'Helmet', 'Ear Protection'];
const TEMPLATE_PPE = {
  forklift: ['Helmet', 'Safety Vest', 'Safety Shoes', 'Gloves'],
  welding:  ['Face Shield', 'Gloves', 'Safety Shoes', 'Ear Protection'],
  assembly: ['Gloves', 'Safety Shoes', 'Safety Vest'],
  blank:    [],
};
const RISK_LEVELS = ['Low', 'Medium', 'High', 'Critical'];
const RISK_STYLE = {
  Low:      { bg: 'transparent',                    border: 'var(--border2)',             color: 'var(--t2)',    headerBg: '#e8f0ff' },
  Medium:   { bg: 'rgba(217,119,6,.08)',             border: 'rgba(217,119,6,.4)',          color: '#b45309',      headerBg: 'rgba(217,119,6,.1)' },
  High:     { bg: 'rgba(234,88,12,.08)',             border: 'rgba(234,88,12,.45)',         color: '#c2410c',      headerBg: 'rgba(234,88,12,.1)' },
  Critical: { bg: 'rgba(220,38,38,.08)',             border: 'rgba(220,38,38,.45)',         color: 'var(--red)',   headerBg: 'rgba(220,38,38,.1)' },
};
const STATUS_COLORS = { published: 'var(--green)', draft: 'var(--amber)', review: 'var(--red)' };

const DELETED_SOPS_KEY = 'lg_deleted_sops';
const getDeletedCodes = () => { try { return JSON.parse(localStorage.getItem(DELETED_SOPS_KEY) || '[]'); } catch { return []; } };
const addDeletedCode = code => { const d = getDeletedCodes(); if (!d.includes(code)) localStorage.setItem(DELETED_SOPS_KEY, JSON.stringify([...d, code])); };
const removeDeletedCode = code => { localStorage.setItem(DELETED_SOPS_KEY, JSON.stringify(getDeletedCodes().filter(c => c !== code))); };

function SOPManagement({ toast }) {
  const deletedCodes = getDeletedCodes();
  // Init SOP list from mock data, excluding previously deleted
  const [sops, setSops] = useState(() => SOP_DATA
    .filter(s => !deletedCodes.includes(s.id))
    .map((s, i) => ({
      ...s,
      effectiveDate: '2026-03-01',
      owner: `${s.by} (Safety Officer)`,
      versionNotes: 'Updated step 3: Added dual-confirmation requirement…',
      ppe: ['Gloves', 'Face Shield'],
      steps: SOP_STEPS.filter((_, j) => i === 0 ? j < 5 : false).map((st, j) => ({
        id: st.id ?? j, text: st.text ?? st.description ?? '', risk: 'Low',
      })),
      history: VERSION_HISTORY,
      isDirty: false,
    })));
  const [selIdx, setSelIdx] = useState(0);
  const [search, setSearch] = useState('');
  const [showNew, setShowNew] = useState(false);
  const [showHist, setShowHist] = useState(false);
  const [showNewProc, setShowNewProc] = useState(false);
  const [newProcForm, setNewProcForm] = useState({ code: '', name: '', name_th: '' });
  const [newForm, setNewForm] = useState({ id: '', title: '', processId: '', owner: '', template: 'blank' });
  const [dbProcesses, setDbProcesses] = useState([]);
  const [saving, setSaving] = useState(false);
  const [ppeInput, setPpeInput] = useState('');
  const [ruleForm, setRuleForm] = useState({ text: '', severity: 'Medium', category: 'action' });
  const [editingRuleIdx, setEditingRuleIdx] = useState(null);
  const [editingRuleData, setEditingRuleData] = useState({ text: '', severity: 'Medium', category: 'action' });

  // Load process list + DB SOPs on mount
  useEffect(() => {
    fetch(`${API}/api/processes`).then(r => r.ok ? r.json() : []).then(setDbProcesses).catch(() => {});
    fetch(`${API}/api/processes/sops/all`)
      .then(r => r.ok ? r.json() : [])
      .then(dbSops => {
        if (!dbSops.length) return;
        const now = new Date();
        const dateStr = now.toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' });
        setSops(prev => {
          // Build lookup: code → db record
          const dbByCode = {};
          dbSops.forEach(s => { dbByCode[(s.code || '').toUpperCase()] = s; });

          // Update existing SOPs (mock or already added) with DB ids + metadata
          const updated = prev.map(s => {
            const db = dbByCode[(s.id || '').toUpperCase()];
            if (!db) return s;
            const ver = db.version ? (db.version.startsWith('v') ? db.version : 'v' + db.version) : s.ver;
            return {
              ...s,
              dbId: db.id,
              dbProcessId: db.process_id,
              name: db.title || s.name,
              status: db.status || s.status,
              ver,
              by: db.responsible || s.by,
              _stepsLoaded: false, // force reload steps from DB
            };
          });

          // Append SOPs that exist in DB but not in prev list at all
          const existingCodes = new Set(updated.map(s => (s.id || '').toUpperCase()));
          const newOnes = dbSops
            .filter(s => !existingCodes.has((s.code || '').toUpperCase()))
            .map(s => ({
              id: s.code, dbId: s.id, dbProcessId: s.process_id,
              name: s.title, process: s.process_name || 'Unknown',
              status: s.status || 'draft', ver: s.version ? (s.version.startsWith('v') ? s.version : 'v' + s.version) : 'v1.0',
              updated: dateStr, by: s.responsible || 'User',
              effectiveDate: now.toISOString().split('T')[0], owner: s.responsible || 'User',
              versionNotes: '', steps: [{ id: 1, text: '', risk: 'Low', ppe: [] }],
              history: [], isDirty: false,
            }));
          return newOnes.length ? [...updated, ...newOnes] : updated;
        });
      })
      .catch(() => {});
  }, []);

  const sop = sops[selIdx] || sops[0];

  // Load actual steps from DB when selecting a DB-backed SOP
  useEffect(() => {
    const cur = sops[selIdx];
    if (!cur || !cur.dbId || !cur.dbProcessId || cur._stepsLoaded) return;
    fetch(`${API}/api/processes/${cur.dbProcessId}/sops/${cur.dbId}`)
      .then(r => r.ok ? r.json() : null)
      .then(data => {
        if (!data) return;
        setSops(p => p.map((s, i) => {
          if (i !== selIdx) return s;
          const steps = (data.steps || []).map((st, j) => ({
            id: j + 1, text: st.title || '',
            risk: st.title_th || (st.is_critical ? 'Critical' : 'Low'),
            riskNote: st.description || '',
          }));
          let ppe = s.ppe || [];
          try { const eq = JSON.parse(data.equipment || '[]'); if (Array.isArray(eq) && eq.length) ppe = eq; } catch {}
          let history = s.history || [];
          try { const h = JSON.parse(data.kpi || '[]'); if (Array.isArray(h)) history = h; } catch {}
          const versionNotes = data.purpose || s.versionNotes || '';
          const status = data.status || s.status || 'draft';
          let safetyRules = s.safetyRules || [];
          try { const sr = JSON.parse(data.safety_rules || '[]'); if (Array.isArray(sr)) safetyRules = sr; } catch {}
          return { ...s, steps: steps.length ? steps : s.steps, ppe, versionNotes, history, status, safetyRules, _stepsLoaded: true };
        }));
      })
      .catch(() => {});
  }, [selIdx, (sops[selIdx] || {}).dbId]);

  // ── Helpers ──
  const deleteSop = (idx) => {
    const target = sops[idx];
    if (!window.confirm(`Delete "${target.name}" (${target.id})? This cannot be undone.`)) return;
    const doDelete = () => {
      addDeletedCode(target.id); // persist so mock SOPs stay deleted after refresh
      setSops(p => {
        const next = p.filter((_, i) => i !== idx);
        setSelIdx(Math.min(idx, next.length - 1));
        return next;
      });
      toast(`${target.id} deleted`);
    };
    if (target.dbId && target.dbProcessId) {
      fetch(`${API}/api/processes/${target.dbProcessId}/sops/${target.dbId}`, { method: 'DELETE' })
        .then(r => { if (r.ok || r.status === 204) doDelete(); else toast('Failed to delete from DB'); })
        .catch(() => toast('Network error'));
    } else {
      doDelete();
    }
  };

  const updateSop = (field, val) => setSops(p => p.map((s, i) => i === selIdx ? { ...s, [field]: val, isDirty: true } : s));
  const selectSop = (idx) => { setSelIdx(idx); setEditingRuleIdx(null); };
  const updateStep = (si, field, val) => updateSop('steps', sop.steps.map((s, i) => i === si ? { ...s, [field]: val } : s));
  const addPpeItem = (item) => {
    const val = (item || '').trim();
    if (!val || (sop.ppe || []).includes(val)) return;
    const newPpe = [...(sop.ppe || []), val];
    const updated = { ...sop, ppe: newPpe };
    setSops(p => p.map((s, i) => i === selIdx ? updated : s));
    _pushToDb(updated).then(() => toast('PPE saved ✓', 'green'));
  };
  const removePpeItem = (ppeIdx) => {
    const newPpe = (sop.ppe || []).filter((_, i) => i !== ppeIdx);
    const updated = { ...sop, ppe: newPpe };
    setSops(p => p.map((s, i) => i === selIdx ? updated : s));
    _pushToDb(updated).then(() => toast('PPE updated ✓', 'green'));
  };
  const addSafetyRule = () => {
    const text = (ruleForm.text || '').trim();
    if (!text) return;
    const newRule = { id: Date.now(), text, severity: ruleForm.severity, category: ruleForm.category };
    const newRules = [...(sop.safetyRules || []), newRule];
    const updated = { ...sop, safetyRules: newRules };
    setSops(p => p.map((s, i) => i === selIdx ? updated : s));
    _pushToDb(updated).then(() => toast('Rule saved ✓', 'green'));
    setRuleForm(f => ({ ...f, text: '' }));
  };
  const saveEditingRule = () => {
    if (!editingRuleData.text.trim()) return;
    const newRules = (sop.safetyRules || []).map((r, i) =>
      i === editingRuleIdx ? { ...r, text: editingRuleData.text.trim(), severity: editingRuleData.severity, category: editingRuleData.category } : r
    );
    const updated = { ...sop, safetyRules: newRules };
    setSops(p => p.map((s, i) => i === selIdx ? updated : s));
    _pushToDb(updated).then(() => toast('Rule updated ✓', 'green'));
    setEditingRuleIdx(null);
  };
  const removeSafetyRule = (ri) => {
    const newRules = (sop.safetyRules || []).filter((_, i) => i !== ri);
    const updated = { ...sop, safetyRules: newRules };
    setSops(p => p.map((s, i) => i === selIdx ? updated : s));
    _pushToDb(updated).then(() => toast('Rule removed ✓', 'green'));
  };
  const addStep = () => updateSop('steps', [...sop.steps, { id: Date.now(), text: '', risk: 'Low' }]);
  const removeStep = si => updateSop('steps', sop.steps.filter((_, i) => i !== si));
  const moveStep = (si, dir) => {
    const ni = si + dir;
    if (ni < 0 || ni >= sop.steps.length) return;
    const arr = [...sop.steps];
    [arr[si], arr[ni]] = [arr[ni], arr[si]];
    updateSop('steps', arr);
  };
  const _pushToDb = (sopObj, newVer) => {
    if (!sopObj.dbId || !sopObj.dbProcessId) return Promise.resolve();
    const steps = (sopObj.steps || []).map((s, i) => ({
      step_no: i + 1, title: s.text || '', title_th: s.risk || 'Low',
      description: s.riskNote || '', is_critical: s.risk === 'Critical',
    }));
    return fetch(`${API}/api/processes/${sopObj.dbProcessId}/sops/${sopObj.dbId}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ title: sopObj.name, version: newVer || sopObj.ver, responsible: sopObj.owner, equipment: JSON.stringify(sopObj.ppe || []), purpose: sopObj.versionNotes || '', kpi: JSON.stringify(sopObj.history || []), status: sopObj.status || 'draft', safety_rules: JSON.stringify(sopObj.safetyRules || []), steps }),
    }).catch(() => {});
  };

  const saveDraft = () => {
    const updated = { ...sop, status: 'draft', isDirty: false };
    _pushToDb(updated, updated.ver).then(() => {
      setSops(p => p.map((s, i) => i === selIdx ? updated : s));
      toast('Draft saved to DB ✓', 'green');
    });
  };

  const publish = () => {
    const parts = (sop.ver || 'v1.0').replace('v', '').split('.').map(Number);
    parts[1] = (parts[1] || 0) + 1;
    const newVer = `v${parts.join('.')}`;
    const now = new Date();
    const updated = {
      ...sop, status: 'published', isDirty: false, ver: newVer,
      updated: now.toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' }),
      history: [{ ver: newVer, note: sop.versionNotes || 'Published', by: 'User', date: now.toISOString().split('T')[0], type: 'add' }, ...(sop.history || [])],
    };
    _pushToDb(updated, newVer).then(() => {
      setSops(p => p.map((s, i) => i === selIdx ? updated : s));
      toast(`Published as ${newVer} ✓`, 'green');
    });
  };
  const createProcess = () => {
    if (!newProcForm.code.trim() || !newProcForm.name.trim()) { toast('Code and Name are required'); return; }
    fetch(`${API}/api/processes`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ code: newProcForm.code.trim().toUpperCase(), name: newProcForm.name.trim(), name_th: newProcForm.name_th.trim() || null }),
    })
    .then(r => { if (r.status === 409) { toast('Process code already exists'); return null; } if (!r.ok) { toast('Failed to create process'); return null; } return r.json(); })
    .then(created => {
      if (!created) return;
      setDbProcesses(p => [...p, created]);
      setNewForm(f => ({ ...f, processId: String(created.id) }));
      setShowNewProc(false);
      setNewProcForm({ code: '', name: '', name_th: '' });
      toast(`Process "${created.name}" added ✓`);
    })
    .catch(() => toast('Network error'));
  };

  const createSop = () => {
    if (!newForm.id.trim() || !newForm.title.trim()) { toast('SOP ID and Title are required'); return; }
    if (!newForm.processId) { toast('Please select a Process'); return; }

    const templateSteps = newForm.template === 'forklift' ? [
      { step_no: 1, title: 'ตรวจสอบ Forklift และพื้นที่ปฏิบัติงาน', description: '', is_critical: false },
      { step_no: 2, title: 'สวม PPE ให้ครบถ้วนก่อนเข้าพื้นที่', description: '', is_critical: true },
      { step_no: 3, title: 'ขับ Forklift เข้าหาม้วนวัสดุด้วยความเร็วต่ำ', description: '', is_critical: false },
    ] : newForm.template === 'welding' ? [
      { step_no: 1, title: 'ตรวจสอบอุปกรณ์เชื่อมและพื้นที่ปฏิบัติงาน', description: '', is_critical: false },
      { step_no: 2, title: 'สวม PPE และกางเกงกันไฟก่อนเริ่มงาน', description: '', is_critical: true },
      { step_no: 3, title: 'ตรวจสอบระบบระบายอากาศก่อนเชื่อม', description: '', is_critical: true },
    ] : newForm.template === 'assembly' ? [
      { step_no: 1, title: 'ตรวจสอบชิ้นส่วนและเครื่องมือประกอบ', description: '', is_critical: false },
      { step_no: 2, title: 'ประกอบชิ้นส่วนตามลำดับที่กำหนด', description: '', is_critical: false },
      { step_no: 3, title: 'ตรวจสอบคุณภาพหลังประกอบเสร็จ', description: '', is_critical: false },
    ] : [];
    const templatePpe = TEMPLATE_PPE[newForm.template] || [];

    setSaving(true);
    fetch(`${API}/api/processes/${newForm.processId}/sops`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        code: newForm.id.trim().toUpperCase(),
        title: newForm.title.trim(),
        responsible: newForm.owner || undefined,
        equipment: JSON.stringify(templatePpe),
        steps: templateSteps,
      }),
    })
    .then(res => {
      if (res.status === 409) { toast('SOP ID already exists — choose another'); setSaving(false); return null; }
      if (!res.ok) { toast('Failed to create SOP'); setSaving(false); return null; }
      return res.json();
    })
    .then(created => {
      if (!created) return;
      const proc = dbProcesses.find(p => String(p.id) === String(newForm.processId));
      const now = new Date();
      const newSop = {
        id: created.code,
        dbId: created.id,
        dbProcessId: newForm.processId,
        name: created.title,
        process: proc ? proc.name : 'Unknown',
        status: 'draft', ver: 'v1.0',
        updated: now.toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' }),
        by: newForm.owner || 'User',
        effectiveDate: now.toISOString().split('T')[0],
        owner: newForm.owner || 'User',
        versionNotes: '',
        ppe: templatePpe,
        steps: templateSteps.length > 0
          ? templateSteps.map((s, i) => ({ id: i + 1, text: s.title, risk: 'Low' }))
          : [{ id: Date.now(), text: '', risk: 'Low' }],
        history: [], isDirty: false,
      };
      setSops(p => {
        setSelIdx(p.length);
        return [...p, newSop];
      });
      setShowNew(false);
      setNewForm({ id: '', title: '', processId: '', owner: '', template: 'blank' });
      toast(`SOP ${created.code} created in DB ✓`);
      setSaving(false);
    })
    .catch(() => { toast('Network error'); setSaving(false); });
  };

  const filtered = sops.filter(s => !search || s.name.toLowerCase().includes(search.toLowerCase()) || s.id.toLowerCase().includes(search.toLowerCase()));

  const totalSops = sops.length;
  const publishedCount = sops.filter(s => s.status === 'published').length;
  const draftCount = sops.filter(s => s.status === 'draft').length;
  const reviewCount = sops.filter(s => s.status === 'review').length;

  return (
    <div style={{ flex: 1, overflowY: 'auto', padding: 16 }}>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4,1fr)', gap: 8, marginBottom: 16 }}>
        <KPICard value={totalSops} label="Total SOPs" color="blue" />
        <KPICard value={publishedCount} label="Published" color="green" />
        <KPICard value={draftCount} label="Draft" color="amber" />
        <KPICard value={reviewCount} label="Needs Review" color="red" />
      </div>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
        <div style={{ fontSize: 11, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.08em', color: 'var(--t2)', display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ display: 'inline-block', width: 12, height: 2, background: 'var(--blue)' }} />SOP Management
        </div>
        <div style={{ display: 'flex', gap: 6 }}>
          <Btn variant="teal" onClick={() => {
            const nums = sops.map(s => parseInt((s.id || '').replace(/\D/g,''))).filter(n => !isNaN(n));
            const next = nums.length > 0 ? Math.max(...nums) + 1 : 1;
            const autoId = 'SOP-' + String(next).padStart(3, '0');
            setNewForm(p => ({ ...p, id: autoId }));
            setShowNew(true);
          }}>+ New SOP</Btn>
          <Btn variant="ghost" onClick={() => toast('Exporting…', '⬇')}>Export All</Btn>
        </div>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: '260px 1fr', gap: 10, minHeight: 500 }}>
        {/* ── SOP List Panel ── */}
        <Panel>
          <PanelHead title="SOP List" right={
            <input
              placeholder="Search…"
              value={search}
              onChange={e => setSearch(e.target.value)}
              style={{ width: 90, background: 'var(--surface2)', border: '1px solid var(--border2)', borderRadius: 4, padding: '3px 7px', fontSize: 10, outline: 'none' }}
            />
          } />
          <div style={{ overflowY: 'auto', flex: 1 }}>
            {filtered.map((s) => {
              const idx = sops.indexOf(s);
              const stColor = STATUS_COLORS[s.status] || 'var(--gray)';
              return (
                <div key={s.id || idx}
                  style={{ padding: '9px 14px', borderBottom: '1px solid var(--border)', borderLeft: `2px solid ${selIdx === idx ? 'var(--blue)' : 'transparent'}`, background: selIdx === idx ? 'rgba(29,110,245,.06)' : 'transparent', transition: 'all .15s', position: 'relative' }}
                  onMouseEnter={e => { e.currentTarget.querySelector('.del-btn').style.opacity = '1'; }}
                  onMouseLeave={e => { e.currentTarget.querySelector('.del-btn').style.opacity = '0'; }}>
                  <div onClick={() => selectSop(idx)} style={{ cursor: 'pointer' }}>
                    <div style={{ fontSize: 9, fontWeight: 600, marginBottom: 2, display: 'flex', alignItems: 'center', gap: 6 }}>
                      <span style={{ color: 'var(--blue)' }}>{s.id}</span>
                      <span style={{ fontSize: 8, fontWeight: 700, padding: '1px 5px', borderRadius: 3, background: `${stColor}18`, border: `1px solid ${stColor}40`, color: stColor, textTransform: 'uppercase' }}>{s.status}</span>
                      {s.isDirty && <span style={{ fontSize: 8, color: 'var(--amber)' }}>●</span>}
                    </div>
                    <div style={{ fontSize: 12, fontWeight: 500, marginBottom: 2, paddingRight: 20 }}>{s.name}</div>
                    <div style={{ fontSize: 10, color: 'var(--t3)' }}>{s.process} · {s.ver} · {s.updated}</div>
                  </div>
                  <button className="del-btn" onClick={e => { e.stopPropagation(); deleteSop(idx); }}
                    style={{ position: 'absolute', top: 8, right: 8, opacity: 0, transition: 'opacity .15s', background: 'var(--red-light)', border: '1px solid rgba(229,62,62,.3)', color: 'var(--red)', borderRadius: 4, width: 20, height: 20, fontSize: 10, cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 700, padding: 0 }}>
                    ✕
                  </button>
                </div>
              );
            })}
            {filtered.length === 0 && (
              <div style={{ padding: 20, textAlign: 'center', fontSize: 11, color: 'var(--t3)' }}>No SOPs match search</div>
            )}
          </div>
        </Panel>

        {/* ── Edit Panel ── */}
        {sop && (
          <Panel style={{ overflow: 'hidden' }}>
            <PanelHead title={`Edit — ${sop.id}`} icon="≡"
              right={<>
                <Badge color={sop.status === 'published' ? 'green' : sop.status === 'review' ? 'red' : 'amber'}>{sop.ver}</Badge>
                {sop.isDirty && <Badge color="amber">Unsaved</Badge>}
                <Btn variant="ghost" size="sm" onClick={() => setShowHist(true)}>History</Btn>
                <Btn variant="ghost" size="sm" onClick={saveDraft}>Save Draft</Btn>
                <Btn variant="primary" size="sm" onClick={publish}>⬆ Publish</Btn>
              </>}
            />
            <div style={{ overflowY: 'auto', flex: 1, padding: 14 }}>
              {/* Basic Info */}
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 12 }}>
                <FormGroup label="SOP Title">
                  <FormInput value={sop.name || ''} onChange={val => updateSop('name', val)} />
                </FormGroup>
                <FormGroup label="Process / Station">
                  <FormInput value={sop.process || ''} onChange={val => updateSop('process', val)} />
                </FormGroup>
                <FormGroup label="Effective Date">
                  <input
                    type="date"
                    value={sop.effectiveDate || ''}
                    onChange={e => updateSop('effectiveDate', e.target.value)}
                    style={{
                      background: 'var(--surface2)', border: '1px solid var(--border2)',
                      borderRadius: 6, padding: '7px 10px', fontSize: 12, color: 'var(--t1)',
                      outline: 'none', width: '100%', fontFamily: 'inherit', boxSizing: 'border-box',
                    }}
                  />
                </FormGroup>
                <FormGroup label="Owner">
                  <FormInput value={sop.owner || ''} onChange={val => updateSop('owner', val)} />
                </FormGroup>
              </div>
              <Divider />

              {/* ── PPE Required (SOP-level) ── */}
              <div style={{ background: '#f0f4ff', border: '1px solid rgba(29,110,245,.18)', borderRadius: 8, padding: '10px 12px', marginBottom: 12 }}>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
                  <div style={{ fontSize: 11, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.07em', color: 'var(--blue)' }}>PPE Required for this SOP</div>
                  <div style={{ fontSize: 10, color: 'var(--t3)' }}>Saved with Save Draft / Publish</div>
                </div>
                {/* Current PPE chips */}
                <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 8 }}>
                  {(sop.ppe || []).length === 0 && (
                    <span style={{ fontSize: 11, color: 'var(--t3)', fontStyle: 'italic' }}>No PPE assigned yet</span>
                  )}
                  {(sop.ppe || []).map((p, pi) => (
                    <span key={pi} style={{ display: 'inline-flex', alignItems: 'center', gap: 5, padding: '3px 10px', borderRadius: 20, background: 'var(--blue)', color: '#fff', fontSize: 11, fontWeight: 600 }}>
                      {p}
                      <button onClick={() => removePpeItem(pi)} style={{ background: 'none', border: 'none', color: '#fff', cursor: 'pointer', fontSize: 12, lineHeight: 1, padding: 0, opacity: 0.8 }}>×</button>
                    </span>
                  ))}
                </div>
                {/* Quick-add standard PPE */}
                <div style={{ display: 'flex', gap: 4, flexWrap: 'wrap', marginBottom: 8 }}>
                  {PPE_OPTIONS.filter(p => !(sop.ppe || []).includes(p)).map(p => (
                    <button key={p} onClick={() => addPpeItem(p)}
                      style={{ padding: '3px 10px', borderRadius: 20, fontSize: 10, fontWeight: 600, cursor: 'pointer', background: '#fff', border: '1.5px dashed rgba(29,110,245,.4)', color: 'var(--blue)', fontFamily: 'inherit' }}>
                      + {p}
                    </button>
                  ))}
                </div>
                {/* Custom PPE input */}
                <div style={{ display: 'flex', gap: 6 }}>
                  <input
                    value={ppeInput} onChange={e => setPpeInput(e.target.value)}
                    onKeyDown={e => { if (e.key === 'Enter' && ppeInput.trim()) { addPpeItem(ppeInput.trim()); setPpeInput(''); } }}
                    placeholder="Custom PPE… (press Enter)"
                    style={{ flex: 1, background: '#fff', border: '1px solid var(--border2)', borderRadius: 6, padding: '5px 10px', fontSize: 11, outline: 'none', fontFamily: 'inherit' }}
                  />
                  <Btn variant="ghost" size="sm" onClick={() => { if (ppeInput.trim()) { addPpeItem(ppeInput.trim()); setPpeInput(''); } }}>Add</Btn>
                </div>
              </div>

              {/* ── Safety Rules (SOP-level) ── */}
              <div style={{ background: '#fffbf0', border: '1px solid rgba(217,119,6,.25)', borderRadius: 8, padding: '10px 12px', marginBottom: 12 }}>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
                  <div style={{ fontSize: 11, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.07em', color: 'var(--amber)' }}>⚑ Safety Rules for this SOP</div>
                  <div style={{ fontSize: 10, color: 'var(--t3)' }}>Linked to {sop.process} · Saved with Save Draft / Publish</div>
                </div>
                {/* Rules list */}
                {(sop.safetyRules || []).length === 0 && (
                  <div style={{ fontSize: 11, color: 'var(--t3)', fontStyle: 'italic', marginBottom: 8 }}>No rules yet — add below</div>
                )}
                {(sop.safetyRules || []).map((r, ri) => {
                  const isEditing = editingRuleIdx === ri;
                  const sevC = { Low: 'var(--gray)', Medium: 'var(--blue)', High: 'var(--amber)', Critical: 'var(--red)' }[r.severity] || 'var(--gray)';
                  const catLabel = { action: 'Unsafe Action', condition: 'Unsafe Condition', nearmiss: 'Near-Miss' }[r.category] || r.category;
                  if (isEditing) {
                    return (
                      <div key={r.id} style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '6px 8px', background: '#fffbf0', border: '1px solid rgba(217,119,6,.4)', borderRadius: 6, marginBottom: 5 }}>
                        <select value={editingRuleData.severity} onChange={e => setEditingRuleData(f => ({ ...f, severity: e.target.value }))}
                          style={{ background: '#fff', border: '1px solid var(--border2)', borderRadius: 4, padding: '3px 6px', fontSize: 10, fontWeight: 700, outline: 'none', fontFamily: 'inherit', flexShrink: 0 }}>
                          {RISK_LEVELS.map(rv => <option key={rv}>{rv}</option>)}
                        </select>
                        <select value={editingRuleData.category} onChange={e => setEditingRuleData(f => ({ ...f, category: e.target.value }))}
                          style={{ background: '#fff', border: '1px solid var(--border2)', borderRadius: 4, padding: '3px 6px', fontSize: 10, outline: 'none', fontFamily: 'inherit', flexShrink: 0 }}>
                          <option value="action">Unsafe Action</option>
                          <option value="condition">Unsafe Condition</option>
                          <option value="nearmiss">Near-Miss</option>
                        </select>
                        <input
                          value={editingRuleData.text} onChange={e => setEditingRuleData(f => ({ ...f, text: e.target.value }))}
                          onKeyDown={e => { if (e.key === 'Enter') saveEditingRule(); if (e.key === 'Escape') setEditingRuleIdx(null); }}
                          autoFocus
                          style={{ flex: 1, background: '#fff', border: '1px solid rgba(217,119,6,.5)', borderRadius: 4, padding: '3px 8px', fontSize: 11, outline: 'none', fontFamily: 'inherit' }}
                        />
                        <Btn variant="amber" size="sm" onClick={saveEditingRule}>Save</Btn>
                        <Btn variant="ghost" size="sm" onClick={() => setEditingRuleIdx(null)}>Cancel</Btn>
                      </div>
                    );
                  }
                  return (
                    <div key={r.id} style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '6px 8px', background: '#fff', border: '1px solid var(--border)', borderRadius: 6, marginBottom: 5 }}>
                      <span style={{ fontSize: 10, fontWeight: 700, color: sevC, width: 52, flexShrink: 0, textTransform: 'uppercase' }}>{r.severity}</span>
                      <span style={{ fontSize: 9, color: 'var(--t3)', width: 80, flexShrink: 0, background: 'var(--surface2)', borderRadius: 3, padding: '1px 5px', textAlign: 'center' }}>{catLabel}</span>
                      <span style={{ flex: 1, fontSize: 11, color: 'var(--t1)' }}>{r.text}</span>
                      <button onClick={() => { setEditingRuleIdx(ri); setEditingRuleData({ text: r.text, severity: r.severity, category: r.category }); }}
                        style={{ background: 'none', border: '1px solid var(--border2)', borderRadius: 4, color: 'var(--t2)', cursor: 'pointer', fontSize: 10, padding: '2px 7px', fontFamily: 'inherit' }}>✎ Edit</button>
                      <button onClick={() => removeSafetyRule(ri)} style={{ background: 'none', border: 'none', color: 'var(--red)', cursor: 'pointer', fontSize: 14, lineHeight: 1, padding: '0 4px', opacity: 0.7 }}>×</button>
                    </div>
                  );
                })}
                {/* Add rule form */}
                <div style={{ display: 'flex', gap: 6, marginTop: 6 }}>
                  <select value={ruleForm.severity} onChange={e => setRuleForm(f => ({ ...f, severity: e.target.value }))}
                    style={{ background: '#fff', border: '1px solid var(--border2)', borderRadius: 4, padding: '4px 6px', fontSize: 10, fontWeight: 700, outline: 'none', fontFamily: 'inherit', flexShrink: 0 }}>
                    {RISK_LEVELS.map(r => <option key={r}>{r}</option>)}
                  </select>
                  <select value={ruleForm.category} onChange={e => setRuleForm(f => ({ ...f, category: e.target.value }))}
                    style={{ background: '#fff', border: '1px solid var(--border2)', borderRadius: 4, padding: '4px 6px', fontSize: 10, outline: 'none', fontFamily: 'inherit', flexShrink: 0 }}>
                    <option value="action">Unsafe Action</option>
                    <option value="condition">Unsafe Condition</option>
                    <option value="nearmiss">Near-Miss</option>
                  </select>
                  <input
                    value={ruleForm.text} onChange={e => setRuleForm(f => ({ ...f, text: e.target.value }))}
                    onKeyDown={e => { if (e.key === 'Enter') addSafetyRule(); }}
                    placeholder="Enter safety rule…"
                    style={{ flex: 1, background: '#fff', border: '1px solid var(--border2)', borderRadius: 4, padding: '4px 8px', fontSize: 11, outline: 'none', fontFamily: 'inherit' }}
                  />
                  <Btn variant="amber" size="sm" onClick={addSafetyRule}>Add</Btn>
                </div>
              </div>

              {/* Work Steps */}
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
                <div style={{ fontSize: 11, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.07em', color: 'var(--t2)' }}>Work Steps</div>
                <div style={{ display: 'flex', gap: 6 }}>
                  <Btn variant="ghost" size="sm" onClick={addStep}>+ Add Step</Btn>
                  <Btn variant="teal" size="sm" onClick={() => toast('AI generating from video…', '✦')}>✦ AI Generate</Btn>
                </div>
              </div>
              {(sop.steps || []).length === 0 && (
                <div style={{ padding: '20px 0', textAlign: 'center', fontSize: 11, color: 'var(--t3)', fontStyle: 'italic' }}>
                  No steps yet — click "+ Add Step" to begin
                </div>
              )}
              {(sop.steps || []).map((s, i) => {
                const rsk = s.risk || 'Low';
                const rs = RISK_STYLE[rsk] || RISK_STYLE.Low;
                const needsNote = rsk === 'Medium' || rsk === 'High' || rsk === 'Critical';
                return (
                  <div key={s.id} style={{ border: `1px solid ${rs.border}`, borderRadius: 6, marginBottom: 6, overflow: 'hidden', background: rs.bg }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '7px 10px', background: rs.headerBg, borderBottom: `1px solid ${rs.border}` }}>
                      <div style={{ width: 22, height: 22, borderRadius: '50%', background: 'rgba(29,110,245,.1)', border: '1px solid rgba(29,110,245,.2)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 10, fontWeight: 700, color: 'var(--blue)', flexShrink: 0 }}>{i + 1}</div>
                      <input
                        value={s.text || ''}
                        onChange={e => updateStep(i, 'text', e.target.value)}
                        placeholder="Enter step description…"
                        style={{ flex: 1, background: 'transparent', border: 'none', outline: 'none', fontSize: 12, color: 'var(--t1)', fontFamily: 'inherit' }}
                      />
                      <div style={{ display: 'flex', gap: 4 }}>
                        <Btn variant="ghost" size="sm" onClick={() => moveStep(i, -1)} disabled={i === 0}>↑</Btn>
                        <Btn variant="ghost" size="sm" onClick={() => moveStep(i, 1)} disabled={i === (sop.steps.length - 1)}>↓</Btn>
                        <Btn variant="danger" size="sm" onClick={() => removeStep(i)}>✕</Btn>
                      </div>
                    </div>
                    <div style={{ padding: '6px 10px', display: 'flex', alignItems: 'center', gap: 8, fontSize: 11 }}>
                      <span style={{ color: 'var(--t3)', flexShrink: 0 }}>Risk:</span>
                      <select
                        value={rsk}
                        onChange={e => updateStep(i, 'risk', e.target.value)}
                        style={{ background: rs.bg, border: `1px solid ${rs.border}`, borderRadius: 4, padding: '2px 8px', fontSize: 10, fontWeight: 700, outline: 'none', fontFamily: 'inherit', color: rs.color, cursor: 'pointer', flexShrink: 0 }}
                      >
                        {RISK_LEVELS.map(r => <option key={r}>{r}</option>)}
                      </select>
                      {needsNote && (
                        <input
                          value={s.riskNote || ''}
                          onChange={e => updateStep(i, 'riskNote', e.target.value)}
                          placeholder={`อธิบายความเสี่ยงระดับ ${rsk} และมาตรการป้องกัน…`}
                          style={{
                            flex: 1, background: 'var(--surface)', border: `1px solid ${rs.border}`,
                            borderRadius: 4, padding: '2px 8px', fontSize: 11,
                            color: 'var(--t1)', fontFamily: 'inherit', outline: 'none',
                          }}
                        />
                      )}
                      {needsNote && !s.riskNote && (
                        <span style={{ fontSize: 9, color: rs.color, fontWeight: 600, flexShrink: 0 }}>⚠</span>
                      )}
                    </div>
                  </div>
                );
              })}
              <Divider />

              {/* Version Notes */}
              <FormGroup label="Version Notes">
                <textarea
                  value={sop.versionNotes || ''}
                  onChange={e => updateSop('versionNotes', e.target.value)}

                  style={{ width: '100%', background: 'var(--surface2)', border: '1px solid var(--border2)', borderRadius: 6, padding: '7px 10px', fontSize: 12, minHeight: 55, outline: 'none', lineHeight: 1.6, resize: 'vertical', fontFamily: 'inherit', boxSizing: 'border-box' }}
                />
              </FormGroup>
              <Divider />

              {/* Version History */}
              <div style={{ fontSize: 11, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.07em', color: 'var(--t2)', marginBottom: 8 }}>Version History</div>
              {(sop.history || []).length === 0 && (
                <div style={{ fontSize: 11, color: 'var(--t3)', fontStyle: 'italic' }}>No history yet</div>
              )}
              {(sop.history || []).map((h, hi) => (
                <div key={hi} style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '7px 0', borderBottom: '1px solid var(--border)', fontSize: 11 }}>
                  <span style={{ width: 32, fontSize: 10, fontWeight: 700, color: 'var(--blue)', textAlign: 'center' }}>{h.ver}</span>
                  <span style={{ flex: 1, color: 'var(--t2)' }}>{h.note} <span style={{ color: 'var(--t3)' }}>— {h.by}</span></span>
                  <span style={{ fontSize: 9, padding: '2px 6px', borderRadius: 3, background: h.type === 'add' ? 'var(--green-light)' : 'var(--amber-light)', border: `1px solid ${h.type === 'add' ? 'rgba(22,163,74,.3)' : 'rgba(217,119,6,.3)'}`, color: h.type === 'add' ? 'var(--green)' : 'var(--amber)', fontWeight: 600 }}>{h.type === 'add' ? '+ Added' : '~ Modified'}</span>
                  <span style={{ fontSize: 10, color: 'var(--t3)' }}>{h.date}</span>
                  <Btn variant="ghost" size="sm" onClick={() => toast(`Restored ${h.ver}!`, '↩')}>Restore</Btn>
                </div>
              ))}
            </div>
          </Panel>
        )}
      </div>

      {/* ── New SOP Modal ── */}
      <Modal show={showNew} onClose={() => { setShowNew(false); setNewForm({ id: '', title: '', processId: '', owner: '', template: 'blank' }); }} title="+ New SOP"
        footer={<>
          <Btn variant="ghost" onClick={() => setShowNew(false)}>Cancel</Btn>
          <Btn variant="primary" onClick={createSop} disabled={saving}>{saving ? 'Creating…' : 'Create SOP'}</Btn>
        </>}
      >
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 10 }}>
          <FormGroup label="SOP ID (auto)">
            <div style={{ display: 'flex', gap: 4 }}>
              <FormInput
                value={newForm.id}
                onChange={val => setNewForm(p => ({ ...p, id: val.toUpperCase() }))}
                style={{ flex: 1, fontFamily: "'IBM Plex Mono',monospace", fontWeight: 600, color: 'var(--blue)' }}
              />
            </div>
          </FormGroup>
          <FormGroup label="Title *">
            <FormInput
              placeholder="SOP Title"
              value={newForm.title}
              onChange={val => setNewForm(p => ({ ...p, title: val }))}
            />
          </FormGroup>
          <FormGroup label="Process *" style={{ gridColumn: '1 / -1' }}>
            <div style={{ display: 'flex', gap: 6 }}>
              <select
                value={newForm.processId}
                onChange={e => setNewForm(p => ({ ...p, processId: e.target.value }))}
                style={{ flex: 1, background: 'var(--surface2)', border: `1px solid ${!newForm.processId ? 'var(--amber)' : 'var(--border2)'}`, borderRadius: 6, padding: '7px 10px', fontSize: 12, outline: 'none', fontFamily: 'inherit' }}
              >
                <option value="">— Select Process —</option>
                {dbProcesses.map(p => (
                  <option key={p.id} value={p.id}>{p.code} — {p.name}</option>
                ))}
              </select>
              <Btn variant="teal" size="sm" onClick={() => {
                const nums = dbProcesses.map(p => parseInt((p.code || '').replace(/\D/g,''))).filter(n => !isNaN(n));
                const next = nums.length > 0 ? Math.max(...nums) + 1 : 1;
                setNewProcForm({ code: 'PROC-' + String(next).padStart(3,'0'), name: '', name_th: '' });
                setShowNewProc(true);
              }}>+ New</Btn>
            </div>
            {dbProcesses.length === 0 && (
              <div style={{ fontSize: 10, color: 'var(--amber)', marginTop: 3 }}>⚠ No processes in DB — click "+ New" to add one</div>
            )}
          </FormGroup>
          <FormGroup label="Owner / Author">
            <FormInput
              placeholder="e.g. K.Somsak"
              value={newForm.owner}
              onChange={val => setNewForm(p => ({ ...p, owner: val }))}
            />
          </FormGroup>
          <FormGroup label="Template">
            <select
              value={newForm.template}
              onChange={e => setNewForm(p => ({ ...p, template: e.target.value }))}
              style={{ width: '100%', background: 'var(--surface2)', border: '1px solid var(--border2)', borderRadius: 6, padding: '7px 10px', fontSize: 12, outline: 'none', fontFamily: 'inherit' }}
            >
              <option value="blank">Blank (empty steps, no PPE)</option>
              <option value="forklift">Forklift — Helmet, Vest, Shoes, Gloves</option>
              <option value="welding">Welding — Face Shield, Gloves, Shoes, Ear Protect</option>
              <option value="assembly">Assembly — Gloves, Shoes, Vest</option>
            </select>
          </FormGroup>
          {newForm.template !== 'blank' && (
            <div style={{ gridColumn: '1/-1', display: 'flex', gap: 6, flexWrap: 'wrap', padding: '6px 10px', background: '#f0f4ff', borderRadius: 6, border: '1px solid rgba(29,110,245,.15)' }}>
              <span style={{ fontSize: 10, color: 'var(--blue)', fontWeight: 700, alignSelf: 'center' }}>Auto PPE:</span>
              {(TEMPLATE_PPE[newForm.template] || []).map(p => (
                <span key={p} style={{ fontSize: 10, padding: '2px 8px', borderRadius: 12, background: 'var(--blue)', color: '#fff', fontWeight: 600 }}>{p}</span>
              ))}
            </div>
          )}
        </div>
        <div style={{ fontSize: 10, color: 'var(--t3)', fontStyle: 'italic' }}>* Required. SOP and PPE will be saved to database immediately.</div>
      </Modal>

      {/* ── New Process Modal ── */}
      <Modal show={showNewProc} onClose={() => setShowNewProc(false)} title="+ New Process"
        footer={<><Btn variant="ghost" onClick={() => setShowNewProc(false)}>Cancel</Btn><Btn variant="primary" onClick={createProcess}>Create Process</Btn></>}
      >
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          <FormGroup label="Process Code *">
            <FormInput placeholder="e.g. WELDING-01" value={newProcForm.code} onChange={val => setNewProcForm(p => ({ ...p, code: val.toUpperCase() }))} />
          </FormGroup>
          <FormGroup label="Process Name (EN) *">
            <FormInput placeholder="e.g. Welding Station Operation" value={newProcForm.name} onChange={val => setNewProcForm(p => ({ ...p, name: val }))} />
          </FormGroup>
          <FormGroup label="ชื่อกระบวนการ (TH)">
            <FormInput placeholder="e.g. การเชื่อมโลหะ" value={newProcForm.name_th} onChange={val => setNewProcForm(p => ({ ...p, name_th: val }))} />
          </FormGroup>
        </div>
      </Modal>

      {/* ── Version History Modal ── */}
      <Modal show={showHist} onClose={() => setShowHist(false)} title={`Version History — ${sop ? sop.id : ''}`}
        footer={<Btn variant="ghost" onClick={() => setShowHist(false)}>Close</Btn>}
      >
        {(sop?.history || []).map((h, hi) => (
          <div key={hi} style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '8px 0', borderBottom: '1px solid var(--border)', fontSize: 12 }}>
            <span style={{ width: 36, fontWeight: 700, color: 'var(--blue)' }}>{h.ver}</span>
            <span style={{ flex: 1, color: 'var(--t2)' }}>{h.note}</span>
            <span style={{ color: 'var(--t3)', fontSize: 10 }}>{h.by}</span>
            <span style={{ color: 'var(--t3)', fontSize: 10, marginLeft: 8 }}>{h.date}</span>
            <Btn variant="ghost" size="sm" onClick={() => { toast(`Restored ${h.ver}!`, '↩'); setShowHist(false); }}>Restore</Btn>
          </div>
        ))}
        {(sop?.history || []).length === 0 && (
          <div style={{ padding: 16, textAlign: 'center', fontSize: 11, color: 'var(--t3)', fontStyle: 'italic' }}>No history yet</div>
        )}
      </Modal>
    </div>
  );
}

// ── Page: Prompt Library ─────────────────────────────────
function PromptLibrary({ toast }) {
  const [prompts, setPrompts] = useState([]);
  const [selId, setSelId] = useState(null);
  const [filter, setFilter] = useState('all');
  const [editName, setEditName] = useState('');
  const [editType, setEditType] = useState('CUSTOM');
  const [editContent, setEditContent] = useState('');
  const [testing, setTesting] = useState(false);
  const [output, setOutput] = useState('');
  const [testStatus, setTestStatus] = useState('idle'); // idle | ok | unavailable
  const [testFile, setTestFile] = useState(null);
  const [testFileType, setTestFileType] = useState('image'); // image | video
  const [testPreview, setTestPreview] = useState(null);
  const [videoFrames, setVideoFrames] = useState([]);
  // VLM settings
  const [vlmInterval, setVlmInterval] = useState(3);
  const [vlmMaxPct, setVlmMaxPct] = useState(50); // percentage of total sampled frames
  const [videoDuration, setVideoDuration] = useState(0); // seconds
  const [vlmTokens, setVlmTokens] = useState(300);
  const [vlmResolution, setVlmResolution] = useState(480);
  const [vlmMultiFrame, setVlmMultiFrame] = useState(1);
  const [qwenHealth, setQwenHealth] = useState(null); // null | {flash_attn, gpu}
  const [flashToggling, setFlashToggling] = useState(false);
  const [testElapsed, setTestElapsed] = useState(0);
  const [testDoneMs, setTestDoneMs] = useState(null);
  const [rawJson, setRawJson] = useState(null);
  const [showRaw, setShowRaw] = useState(false);
  const timerRef = React.useRef(null);
  const startMsRef = React.useRef(null);
  const [showNew, setShowNew] = useState(false);
  const [newName, setNewName] = useState('');
  const [newType, setNewType] = useState('CUSTOM');
  const [newContent, setNewContent] = useState('');
  const [savedOutput, setSavedOutput] = useState(null);
  const [savedJson, setSavedJson] = useState(null);
  const [savedAt, setSavedAt] = useState(null);

  // SOP Context
  const [processes, setProcesses] = useState([]);
  const [ctxProcessId, setCtxProcessId] = useState('');
  const [ctxSops, setCtxSops] = useState([]);
  const [ctxSopId, setCtxSopId] = useState('');
  const [ctxSopData, setCtxSopData] = useState(null); // full SOP detail

  const tags = ['all', 'SAFETY', 'SOP', 'RULE GEN', 'PPE', 'NEAR-MISS', 'CUSTOM'];

  React.useEffect(() => {
    fetch('/api/prompts')
      .then(function(r) { return r.json(); })
      .then(function(data) {
        setPrompts(data);
        if (data.length > 0) {
          setSelId(data[0].id);
          setEditName(data[0].name);
          setEditType(data[0].type);
          setEditContent(data[0].content);
        }
      });
    fetch('/api/processes')
      .then(function(r) { return r.json(); })
      .then(function(data) { setProcesses(data); });
    fetch('/api/vlm/health')
      .then(function(r) { return r.ok ? r.json() : null; })
      .then(function(d) { if (d) setQwenHealth(d); })
      .catch(function() {});
  }, []);

  var selPrompt = prompts.find(function(p) { return p.id === selId; }) || null;
  var filtered = filter === 'all' ? prompts : prompts.filter(function(p) { return p.type === filter; });

  function selectPrompt(p) {
    setSelId(p.id);
    setEditName(p.name);
    setEditType(p.type);
    setEditContent(p.content);
    setOutput('');
    setVideoFrames([]);
    setRawJson(null);
    setShowRaw(false);
    setTestDoneMs(null);
    setTestStatus('idle');
    setSavedOutput(p.last_test_output || null);
    setSavedJson(p.last_test_json || null);
    setSavedAt(p.updated_at || null);
  }

  function saveChanges() {
    if (!selPrompt) return;
    fetch('/api/prompts/' + selPrompt.id, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: editName, type: editType, content: editContent })
    })
      .then(function(r) { return r.json(); })
      .then(function(updated) {
        setPrompts(function(prev) { return prev.map(function(p) { return p.id === updated.id ? updated : p; }); });
        toast('Saved!', '✓');
      });
  }

  function deletePrompt() {
    if (!selPrompt || selPrompt.is_system) return;
    if (!confirm('Delete "' + selPrompt.name + '"?')) return;
    fetch('/api/prompts/' + selPrompt.id, { method: 'DELETE' })
      .then(function() {
        var next = prompts.filter(function(p) { return p.id !== selPrompt.id; });
        setPrompts(next);
        if (next.length > 0) selectPrompt(next[0]);
        else { setSelId(null); setEditName(''); setEditType('CUSTOM'); setEditContent(''); }
        toast('Deleted', '✕');
      });
  }

  function saveResult() {
    if (!selPrompt || !rawJson) return;
    var isVid = testFileType === 'video';
    var outText = isVid
      ? (videoFrames.map(function(fr, i) { return 'Frame ' + (i+1) + ' [' + fr.timestamp_str + ']:\n' + fr.description; }).join('\n\n'))
      : (output || '');
    fetch('/api/prompts/' + selPrompt.id + '/save-result', {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ output: outText, result_json: rawJson })
    })
      .then(function(r) { return r.json(); })
      .then(function(updated) {
        setPrompts(function(prev) { return prev.map(function(p) { return p.id === updated.id ? updated : p; }); });
        setSavedOutput(updated.last_test_output);
        setSavedJson(updated.last_test_json);
        setSavedAt(updated.updated_at);
        toast('Result saved!', '💾');
      });
  }

  function togglePin() {
    if (!selPrompt) return;
    fetch('/api/prompts/' + selPrompt.id + '/pin', { method: 'PATCH' })
      .then(function(r) { return r.json(); })
      .then(function(res) {
        setPrompts(function(prev) { return prev.map(function(p) { return p.id === res.id ? Object.assign({}, p, { is_pinned: res.is_pinned }) : p; }); });
        toast(res.is_pinned ? 'Pinned!' : 'Unpinned', '📌');
      });
  }

  function createPrompt() {
    if (!newName.trim()) return;
    fetch('/api/prompts', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: newName, type: newType, content: newContent })
    })
      .then(function(r) { return r.json(); })
      .then(function(created) {
        setPrompts(function(prev) { return prev.concat([created]); });
        selectPrompt(created);
        setShowNew(false);
        setNewName(''); setNewType('CUSTOM'); setNewContent('');
        toast('Prompt saved!', '✓');
      });
  }

  function onPickTestFile(e) {
    var f = e.target.files && e.target.files[0];
    if (!f) return;
    setTestFile(f);
    setOutput('');
    setVideoFrames([]);
    setTestStatus('idle');
    var isVid = f.type.startsWith('video/');
    setTestFileType(isVid ? 'video' : 'image');
    if (isVid) {
      var objUrl = URL.createObjectURL(f);
      setTestPreview(objUrl);
      var vid = document.createElement('video');
      vid.preload = 'metadata';
      vid.onloadedmetadata = function() { setVideoDuration(vid.duration); URL.revokeObjectURL(vid.src); };
      vid.src = URL.createObjectURL(f);
    } else {
      setVideoDuration(0);
      var reader = new FileReader();
      reader.onload = function(ev) { setTestPreview(ev.target.result); };
      reader.readAsDataURL(f);
    }
  }

  function onSelectProcess(pid) {
    setCtxProcessId(pid);
    setCtxSops([]);
    setCtxSopId('');
    setCtxSopData(null);
    if (!pid) return;
    fetch('/api/processes/' + pid + '/sops')
      .then(function(r) { return r.json(); })
      .then(function(data) { setCtxSops(data); });
  }

  function onSelectSop(sopId) {
    setCtxSopId(sopId);
    setCtxSopData(null);
    if (!sopId) return;
    fetch('/api/processes/' + ctxProcessId + '/sops/' + sopId)
      .then(function(r) { return r.json(); })
      .then(function(data) { setCtxSopData(data); });
  }

  function buildSopContext() {
    if (!ctxSopData) return '';
    var lines = [];
    var proc = processes.find(function(p) { return String(p.id) === String(ctxProcessId); });
    lines.push('=== SOP Context: ' + ctxSopData.title + ' (' + ctxSopData.code + ') ===');
    if (proc) lines.push('Process: ' + proc.name);

    var ppe = [];
    try { ppe = JSON.parse(ctxSopData.equipment || '[]'); } catch(e) {}
    if (ppe.length > 0) lines.push('PPE Required: ' + ppe.join(', '));

    var steps = ctxSopData.steps || [];
    if (steps.length > 0) {
      lines.push('Work Steps:');
      steps.forEach(function(s) {
        var risk = s.title_th ? ' [Risk: ' + s.title_th + ']' : '';
        lines.push('  ' + s.step_no + '. ' + (s.title || '') + (s.description ? ' — ' + s.description : '') + risk);
      });
    }

    var rules = [];
    try { rules = JSON.parse(ctxSopData.safety_rules || '[]'); } catch(e) {}
    if (rules.length > 0) {
      lines.push('Safety Rules:');
      rules.forEach(function(r) {
        lines.push('  - [' + (r.severity || 'Medium') + '] ' + (r.text || ''));
      });
    }
    return lines.join('\n');
  }

  function fmtSec(s) { return s < 60 ? s + 's' : Math.floor(s/60) + 'm ' + (s%60) + 's'; }
  function fmtMs(ms) { return fmtSec(Math.round(ms/1000)); }

  function toggleFlashAttn() {
    if (!qwenHealth || flashToggling) return;
    var newVal = qwenHealth.flash_attn ? 0 : 1;
    setFlashToggling(true);
    fetch('/api/vlm/toggle-flash-attn?enable=' + newVal, { method: 'POST' })
      .then(function(r) {
        if (!r.ok) { return r.json().then(function(e) { throw new Error(e.detail || e.error || ('HTTP ' + r.status)); }); }
        return r.json();
      })
      .then(function(d) {
        setFlashToggling(false);
        if (d.flash_attn !== undefined) {
          setQwenHealth(function(prev) { return Object.assign({}, prev, { flash_attn: d.flash_attn }); });
          toast('Flash Attn ' + (d.flash_attn ? 'ON ⚡' : 'OFF'), d.flash_attn ? '⚡' : '○');
        } else {
          toast('Toggle failed: ' + (d.error || d.detail || JSON.stringify(d)), '⚠');
        }
      })
      .catch(function(err) { setFlashToggling(false); toast('Flash Attn: ' + err.message, '⚠'); });
  }

  function runTest() {
    if (!selPrompt) return;
    if (!testFile) { toast('Please select an image or video first', '⚠'); return; }
    setTesting(true); setOutput(''); setVideoFrames([]); setTestStatus('idle');
    setTestElapsed(0); setTestDoneMs(null); setRawJson(null); setShowRaw(false);
    if (timerRef.current) clearInterval(timerRef.current);
    startMsRef.current = Date.now();
    timerRef.current = setInterval(function() {
      setTestElapsed(Math.floor((Date.now() - startMsRef.current) / 1000));
    }, 500);
    var ctx = buildSopContext();
    var isVid = testFileType === 'video';
    toast(ctx ? 'Sending to Qwen with SOP context…' : 'Sending to Qwen…', '✦');
    var fd = new FormData();
    fd.append('file', testFile);
    if (ctx) fd.append('sop_context', ctx);
    fd.append('max_new_tokens', String(vlmTokens));
    fd.append('resolution', String(vlmResolution));
    if (isVid) {
      var totalSampled = videoDuration > 0 ? Math.max(1, Math.floor(videoDuration / vlmInterval)) : 999;
      var computedMaxFrames = Math.max(1, Math.ceil(totalSampled * vlmMaxPct / 100));
      fd.append('interval_sec', String(vlmInterval));
      fd.append('max_frames', String(computedMaxFrames));
      fd.append('multi_frame', String(vlmMultiFrame));
    }
    var endpoint = isVid
      ? '/api/prompts/' + selPrompt.id + '/test-video'
      : '/api/prompts/' + selPrompt.id + '/test';
    fetch(endpoint, { method: 'POST', body: fd })
      .then(function(r) { return r.json(); })
      .then(function(data) {
        clearInterval(timerRef.current); timerRef.current = null;
        setTestDoneMs(Date.now() - startMsRef.current);
        setTesting(false);
        setTestStatus(data.status);
        setRawJson(data);
        if (isVid) {
          setVideoFrames(data.frames || []);
          if (data.status === 'ok') toast('Done! ' + (data.frames || []).length + ' frames, ' + data.latency_ms + 'ms', '✓');
          else { setOutput(data.description || 'Error'); toast('Qwen service offline', '⚠'); }
        } else {
          setOutput(data.description || '(no output)');
          if (data.status === 'ok') toast('Done! ' + data.latency_ms + 'ms', '✓');
          else toast('Qwen service offline', '⚠');
        }
      })
      .catch(function(err) {
        clearInterval(timerRef.current); timerRef.current = null;
        setTestDoneMs(Date.now() - startMsRef.current);
        setTesting(false);
        setOutput('Request failed: ' + err);
        setTestStatus('unavailable');
      });
  }

  var totalCount = prompts.length;
  var systemCount = prompts.filter(function(p) { return p.is_system; }).length;
  var customCount = prompts.filter(function(p) { return !p.is_system; }).length;
  var pinnedCount = prompts.filter(function(p) { return p.is_pinned; }).length;

  return (
    <div style={{ flex: 1, overflowY: 'auto', padding: 16 }}>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4,1fr)', gap: 8, marginBottom: 16 }}>
        <KPICard value={String(totalCount)} label="Total Prompts" color="blue" />
        <KPICard value={String(systemCount)} label="System Templates" color="green" />
        <KPICard value={String(customCount)} label="Custom" color="amber" />
        <KPICard value={String(pinnedCount)} label="Pinned" color="gray" />
      </div>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
        <div style={{ fontSize: 11, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.08em', color: 'var(--t2)', display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ display: 'inline-block', width: 12, height: 2, background: 'var(--blue)' }} />Prompt Library
        </div>
        <div style={{ display: 'flex', gap: 6 }}>
          <Btn variant="teal" onClick={function() { setShowNew(true); }}>+ New Prompt</Btn>
          <Btn variant="ghost" onClick={function() { toast('Exporting…', '⬇'); }}>Export</Btn>
        </div>
      </div>
      <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 14 }}>
        {tags.map(function(t) {
          return (
            <button key={t} onClick={function() { setFilter(t); }} style={{ padding: '4px 14px', borderRadius: 20, fontSize: 10, fontWeight: 600, cursor: 'pointer', border: '1.5px solid ' + (filter === t ? 'var(--blue)' : 'var(--border2)'), background: filter === t ? 'var(--blue-light)' : '#fff', color: filter === t ? 'var(--blue)' : 'var(--t2)', transition: 'all .15s', fontFamily: 'inherit' }}>{t}</button>
          );
        })}
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: '240px 1fr', gap: 10, minHeight: 500 }}>
        <div style={{ overflowY: 'auto' }}>
          {filtered.map(function(p) {
            return (
              <div key={p.id} onClick={function() { selectPrompt(p); }}
                style={{ background: selId === p.id ? 'rgba(29,110,245,.06)' : '#fff', border: '1.5px solid ' + (selId === p.id ? 'var(--blue)' : 'var(--border)'), borderRadius: 10, padding: 12, marginBottom: 8, cursor: 'pointer', transition: 'all .15s' }}>
                <div style={{ fontSize: 10, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.08em', color: p.type_color || 'var(--blue)', marginBottom: 5 }}>● {p.type}</div>
                <div style={{ fontSize: 13, fontWeight: 600, marginBottom: 4 }}>{p.name}</div>
                <div style={{ fontSize: 10, color: 'var(--t3)', lineHeight: 1.5, marginBottom: 4 }}>{p.code || ''}</div>
                {p.updated_at && <div style={{ fontSize: 9, color: 'var(--t3)', marginBottom: 6 }}>Updated: {new Date(p.updated_at).toLocaleDateString('th-TH')}</div>}
                <div style={{ display: 'flex', gap: 5 }}>
                  <Badge color="blue" style={{ fontSize: 8 }}>Active</Badge>
                  {p.is_pinned && <Badge color="gray" style={{ fontSize: 8 }}>📌</Badge>}
                  {p.is_system && <Badge color="green" style={{ fontSize: 8 }}>System</Badge>}
                </div>
              </div>
            );
          })}
        </div>
        <Panel style={{ overflow: 'hidden' }}>
          {selPrompt ? (
            <>
              <PanelHead title={'Prompt Editor — ' + selPrompt.name} icon="✦"
                right={<>
                  <Badge color="blue">{selPrompt.type}</Badge>
                  {selPrompt.updated_at && <span style={{ fontSize: 9, color: 'var(--t3)', fontFamily: "'IBM Plex Mono',monospace" }}>Updated: {new Date(selPrompt.updated_at).toLocaleString('th-TH', { dateStyle: 'short', timeStyle: 'short' })}</span>}
                  <Btn variant="ghost" size="sm" onClick={togglePin}>{selPrompt.is_pinned ? '📌 Unpin' : '📌 Pin'}</Btn>
                </>} />
              <div style={{ overflowY: 'auto', flex: 1, padding: 14 }}>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 12 }}>
                  <FormGroup label="Prompt Name">
                    <FormInput value={editName} onChange={function(val) { setEditName(val); }} />
                  </FormGroup>
                  <FormGroup label="Category">
                    <select value={editType} onChange={function(e) { setEditType(e.target.value); }}
                      style={{ background: 'var(--surface2)', border: '1px solid var(--border2)', borderRadius: 6, padding: '7px 10px', fontSize: 12, outline: 'none', width: '100%' }}>
                      {tags.filter(function(t) { return t !== 'all'; }).map(function(t) { return <option key={t} value={t}>{t}</option>; })}
                    </select>
                  </FormGroup>
                </div>
                <div style={{ marginTop: 10, marginBottom: 5, fontSize: 10, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.07em', color: 'var(--t3)' }}>Prompt Text</div>
                <textarea value={editContent} onChange={function(e) { setEditContent(e.target.value); }}
                  style={{ width: '100%', background: 'var(--surface2)', border: '1px solid var(--border2)', borderRadius: 6, padding: '10px 12px', fontSize: 11, color: 'var(--t1)', resize: 'vertical', minHeight: 140, outline: 'none', lineHeight: 1.8, fontFamily: "'IBM Plex Mono',monospace" }} />
                <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 8, marginBottom: 10, flexWrap: 'wrap' }}>
                  <Btn variant="teal" onClick={saveChanges}>Save Changes</Btn>
                  {!selPrompt.is_system && <Btn variant="danger" size="sm" onClick={deletePrompt}>Delete</Btn>}
                  <div style={{ flex: 1 }} />
                  <label style={{ display: 'flex', alignItems: 'center', gap: 6, background: 'var(--surface2)', border: '1.5px dashed ' + (testFile ? 'var(--blue)' : 'var(--border2)'), borderRadius: 7, padding: '5px 10px', cursor: 'pointer', fontSize: 11, color: testFile ? 'var(--blue)' : 'var(--t2)', maxWidth: 220, overflow: 'hidden' }}>
                    <span>{testFileType === 'video' ? '🎬' : '🖼'}</span>
                    <span style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{testFile ? testFile.name : 'เลือกภาพ / วิดีโอ…'}</span>
                    <input type="file" accept="image/*,video/*" style={{ display: 'none' }} onChange={onPickTestFile} />
                  </label>
                  <Btn variant="primary" onClick={runTest} disabled={testing || !testFile || flashToggling}>{testing ? '⟳ Running…' : flashToggling ? '⟳ Reloading model…' : '▶ Test Run'}</Btn>
                </div>

                {/* VLM Settings */}
                <div style={{ background: 'rgba(29,110,245,.04)', border: '1px solid rgba(29,110,245,.15)', borderRadius: 8, padding: '10px 12px', marginBottom: 12 }}>
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
                    <div style={{ fontSize: 10, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.07em', color: 'var(--blue)' }}>⚙ VLM Settings</div>
                    {qwenHealth && (
                      <div style={{ display: 'flex', gap: 5 }}>
                        <span style={{ fontSize: 9, padding: '2px 7px', borderRadius: 10, background: 'rgba(16,185,129,.12)', color: 'var(--green)', fontWeight: 600 }}>● GPU: {qwenHealth.gpu ? qwenHealth.gpu.replace('NVIDIA GeForce ','') : 'N/A'}</span>
                        {flashToggling ? (
                          <span style={{ fontSize: 9, padding: '2px 7px', borderRadius: 10, background: 'rgba(29,110,245,.1)', color: 'var(--blue)', fontWeight: 600 }}>⟳ Reloading…</span>
                        ) : (
                          <button onClick={toggleFlashAttn} title="Click to toggle Flash Attention (reloads model ~30s)"
                            style={{ fontSize: 9, padding: '2px 9px', borderRadius: 10, background: qwenHealth.flash_attn ? 'rgba(16,185,129,.15)' : 'rgba(100,116,139,.1)', color: qwenHealth.flash_attn ? 'var(--green)' : 'var(--t3)', fontWeight: 700, border: '1.5px solid ' + (qwenHealth.flash_attn ? 'rgba(16,185,129,.4)' : 'var(--border2)'), cursor: 'pointer', fontFamily: 'inherit', transition: 'all .15s' }}>
                            {qwenHealth.flash_attn ? '⚡ Flash Attn ON' : '○ Flash Attn OFF'}
                          </button>
                        )}
                      </div>
                    )}
                  </div>
                  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)', gap: 6 }}>
                    <div>
                      <div style={{ fontSize: 9, color: 'var(--t3)', marginBottom: 3 }}>Max Tokens</div>
                      <select value={vlmTokens} onChange={function(e) { setVlmTokens(Number(e.target.value)); }}
                        style={{ width: '100%', fontSize: 11, padding: '4px 6px', border: '1px solid var(--border2)', borderRadius: 5, background: '#fff', outline: 'none' }}>
                        {[300,400,500,600,700,800].map(function(v) { return <option key={v} value={v}>{v}</option>; })}
                      </select>
                    </div>
                    <div>
                      <div style={{ fontSize: 9, color: 'var(--t3)', marginBottom: 3 }}>Resolution</div>
                      <select value={vlmResolution} onChange={function(e) { setVlmResolution(Number(e.target.value)); }}
                        style={{ width: '100%', fontSize: 11, padding: '4px 6px', border: '1px solid var(--border2)', borderRadius: 5, background: '#fff', outline: 'none' }}>
                        {[480,512,640].map(function(v) { return <option key={v} value={v}>{v}px</option>; })}
                      </select>
                    </div>
                    <div>
                      <div style={{ fontSize: 9, color: 'var(--t3)', marginBottom: 3 }}>Skip (วินาที/frame)</div>
                      <select value={vlmInterval} onChange={function(e) { setVlmInterval(Number(e.target.value)); }}
                        disabled={testFileType !== 'video'}
                        style={{ width: '100%', fontSize: 11, padding: '4px 6px', border: '1px solid var(--border2)', borderRadius: 5, background: testFileType === 'video' ? '#fff' : 'var(--surface2)', outline: 'none', opacity: testFileType === 'video' ? 1 : 0.5 }}>
                        {[2,3,5,7,10].map(function(v) { return <option key={v} value={v}>{v}s</option>; })}
                      </select>
                    </div>
                    <div>
                      <div style={{ fontSize: 9, color: 'var(--t3)', marginBottom: 3 }}>Max Frames</div>
                      <select value={vlmMaxPct} onChange={function(e) { setVlmMaxPct(Number(e.target.value)); }}
                        disabled={testFileType !== 'video'}
                        style={{ width: '100%', fontSize: 11, padding: '4px 6px', border: '1px solid var(--border2)', borderRadius: 5, background: testFileType === 'video' ? '#fff' : 'var(--surface2)', outline: 'none', opacity: testFileType === 'video' ? 1 : 0.5 }}>
                        {[10,25,50,75,100].map(function(v) { return <option key={v} value={v}>{v}%</option>; })}
                      </select>
                      {testFileType === 'video' && videoDuration > 0 && (function() {
                        var ts = Math.max(1, Math.floor(videoDuration / vlmInterval));
                        var cf = Math.max(1, Math.ceil(ts * vlmMaxPct / 100));
                        return <div style={{ fontSize: 9, color: 'var(--blue)', marginTop: 2 }}>= {cf} / {ts} frames</div>;
                      })()}
                    </div>
                    <div>
                      <div style={{ fontSize: 9, color: 'var(--t3)', marginBottom: 3 }}>Multi-frame</div>
                      <select value={vlmMultiFrame} onChange={function(e) { setVlmMultiFrame(Number(e.target.value)); }}
                        disabled={testFileType !== 'video'}
                        style={{ width: '100%', fontSize: 11, padding: '4px 6px', border: '1px solid var(--border2)', borderRadius: 5, background: testFileType === 'video' ? '#fff' : 'var(--surface2)', outline: 'none', opacity: testFileType === 'video' ? 1 : 0.5 }}>
                        {[1,2,3,4,5,10].map(function(v) { return <option key={v} value={v}>{v === 1 ? '1 (off)' : v + ' frames'}</option>; })}
                      </select>
                    </div>
                  </div>
                  {testFileType === 'video' && (function() {
                    var ts = videoDuration > 0 ? Math.max(1, Math.floor(videoDuration / vlmInterval)) : null;
                    var cf = ts ? Math.max(1, Math.ceil(ts * vlmMaxPct / 100)) : '?';
                    var calls = ts ? Math.ceil(cf / vlmMultiFrame) : '?';
                    var estSec = ts ? Math.ceil(cf / vlmMultiFrame) * 30 : null;
                    return (
                      <div style={{ marginTop: 7, fontSize: 10, color: 'var(--t3)' }}>
                        {ts ? (vlmMaxPct + '% ของ ' + ts + ' frames = ' + cf + ' frames') : ('Max Frames: ' + vlmMaxPct + '% — เลือกวิดีโอเพื่อดูจำนวน frame')}
                        {ts && <span style={{ marginLeft: 8 }}>| ประมาณ: {calls} call{calls > 1 ? 's' : ''} × ~30s ≈ <strong>{estSec}s</strong></span>}
                      </div>
                    );
                  })()}
                </div>

                {testPreview && testFileType === 'image' && (
                  <img src={testPreview} alt="preview" style={{ width: '100%', maxHeight: 140, objectFit: 'contain', borderRadius: 6, marginBottom: 10, border: '1px solid var(--border)' }} />
                )}
                {testPreview && testFileType === 'video' && (
                  <video src={testPreview} controls style={{ width: '100%', maxHeight: 140, borderRadius: 6, marginBottom: 10, border: '1px solid var(--border)' }} />
                )}

                {/* ── SOP Context ─────────────────────────── */}
                <div style={{ background: 'rgba(29,110,245,.04)', border: '1px solid var(--border2)', borderRadius: 8, padding: 12, marginBottom: 12 }}>
                  <div style={{ fontSize: 10, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.08em', color: 'var(--blue)', marginBottom: 10 }}>
                    📋 SOP Context (ส่งไปพร้อม Test Run)
                  </div>
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8, marginBottom: ctxSopData ? 10 : 0 }}>
                    <FormGroup label="Process">
                      <select value={ctxProcessId} onChange={function(e) { onSelectProcess(e.target.value); }}
                        style={{ background: '#fff', border: '1px solid var(--border2)', borderRadius: 6, padding: '7px 10px', fontSize: 12, outline: 'none', width: '100%' }}>
                        <option value="">— ไม่เลือก —</option>
                        {processes.map(function(p) { return <option key={p.id} value={p.id}>{p.code} — {p.name}</option>; })}
                      </select>
                    </FormGroup>
                    <FormGroup label="SOP">
                      <select value={ctxSopId} onChange={function(e) { onSelectSop(e.target.value); }}
                        disabled={!ctxProcessId}
                        style={{ background: '#fff', border: '1px solid var(--border2)', borderRadius: 6, padding: '7px 10px', fontSize: 12, outline: 'none', width: '100%', opacity: ctxProcessId ? 1 : 0.5 }}>
                        <option value="">— เลือก SOP —</option>
                        {ctxSops.map(function(s) { return <option key={s.id} value={s.id}>{s.code} — {s.title}</option>; })}
                      </select>
                    </FormGroup>
                  </div>

                  {ctxSopData && (function() {
                    var ppe = [];
                    try { ppe = JSON.parse(ctxSopData.equipment || '[]'); } catch(e) {}
                    var rules = [];
                    try { rules = JSON.parse(ctxSopData.safety_rules || '[]'); } catch(e) {}
                    return (
                      <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
                        {ppe.length > 0 && (
                          <div>
                            <div style={{ fontSize: 10, fontWeight: 700, color: 'var(--t2)', marginBottom: 5 }}>🦺 PPE Required</div>
                            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 5 }}>
                              {ppe.map(function(item, i) {
                                return <span key={i} style={{ fontSize: 10, background: '#e8f0ff', color: 'var(--blue)', padding: '2px 10px', borderRadius: 20, border: '1px solid rgba(29,110,245,.2)' }}>{item}</span>;
                              })}
                            </div>
                          </div>
                        )}
                        {ctxSopData.steps && ctxSopData.steps.length > 0 && (
                          <div>
                            <div style={{ fontSize: 10, fontWeight: 700, color: 'var(--t2)', marginBottom: 5 }}>📝 Work Steps</div>
                            {ctxSopData.steps.map(function(s) {
                              var riskColor = { Low: 'var(--t3)', Medium: '#b45309', High: '#c2410c', Critical: 'var(--red)' }[s.title_th] || 'var(--t3)';
                              return (
                                <div key={s.step_no} style={{ display: 'flex', gap: 8, padding: '4px 0', borderBottom: '1px solid var(--border)', fontSize: 11 }}>
                                  <span style={{ fontWeight: 700, color: 'var(--blue)', width: 20, flexShrink: 0 }}>{s.step_no}.</span>
                                  <span style={{ flex: 1, color: 'var(--t1)' }}>{s.title}</span>
                                  {s.description && <span style={{ color: 'var(--t3)', fontSize: 10 }}>{s.description}</span>}
                                  {s.title_th && s.title_th !== 'Low' && <span style={{ fontSize: 9, fontWeight: 700, color: riskColor }}>{s.title_th}</span>}
                                </div>
                              );
                            })}
                          </div>
                        )}
                        {rules.length > 0 && (
                          <div>
                            <div style={{ fontSize: 10, fontWeight: 700, color: 'var(--t2)', marginBottom: 5 }}>⚠ Safety Rules</div>
                            {rules.map(function(r, i) {
                              var sevColor = { Low: 'var(--t3)', Medium: '#b45309', High: '#c2410c', Critical: 'var(--red)' }[r.severity] || '#b45309';
                              return (
                                <div key={i} style={{ display: 'flex', gap: 8, alignItems: 'flex-start', padding: '3px 0', fontSize: 11 }}>
                                  <span style={{ fontSize: 9, fontWeight: 700, color: sevColor, marginTop: 2, flexShrink: 0 }}>[{r.severity || 'Medium'}]</span>
                                  <span style={{ color: 'var(--t1)' }}>{r.text}</span>
                                </div>
                              );
                            })}
                          </div>
                        )}
                      </div>
                    );
                  })()}
                </div>

                <div style={{ fontSize: 11, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.07em', color: 'var(--t2)', marginBottom: 6, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                  <span>Test Output {videoFrames.length > 0 && <span style={{ fontWeight: 400, color: 'var(--t3)', fontSize: 10 }}>— {videoFrames.length} frames</span>}</span>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                    {!testing && rawJson && (
                      <button onClick={saveResult}
                        style={{ fontSize: 9, padding: '2px 9px', borderRadius: 6, border: '1.5px solid var(--green)', background: 'rgba(16,185,129,.08)', color: 'var(--green)', cursor: 'pointer', fontFamily: 'inherit', fontWeight: 700 }}>
                        💾 Save Result
                      </button>
                    )}
                    {!testing && rawJson && (
                      <button onClick={function() { setShowRaw(function(v) { return !v; }); }}
                        style={{ fontSize: 9, padding: '2px 8px', borderRadius: 6, border: '1px solid ' + (showRaw ? 'var(--blue)' : 'var(--border2)'), background: showRaw ? 'rgba(29,110,245,.1)' : '#fff', color: showRaw ? 'var(--blue)' : 'var(--t2)', cursor: 'pointer', fontFamily: "'IBM Plex Mono',monospace", fontWeight: 600 }}>
                        {'{ } JSON'}
                      </button>
                    )}
                    {!testing && testDoneMs !== null && (
                      <span style={{ fontFamily: "'IBM Plex Mono',monospace", fontSize: 10, color: testStatus === 'ok' ? 'var(--green)' : 'var(--amber)', fontWeight: 600 }}>⏱ {fmtMs(testDoneMs)}</span>
                    )}
                  </div>
                </div>
                <div style={{ background: 'var(--surface2)', border: '1px solid ' + (testStatus === 'ok' ? 'var(--green)' : testStatus === 'unavailable' ? 'var(--amber)' : 'var(--border)'), borderRadius: 6, padding: 12, minHeight: 70, maxHeight: 420, overflowY: 'auto', fontSize: 11, lineHeight: 1.8, marginBottom: 14 }}>
                  {testing && (function() {
                    var ts = videoDuration > 0 ? Math.max(1, Math.floor(videoDuration / vlmInterval)) : 5;
                    var cf = Math.max(1, Math.ceil(ts * vlmMaxPct / 100));
                    var estSec = Math.ceil(cf / vlmMultiFrame) * 30;
                    var pct = testFileType === 'video'
                      ? Math.min(95, testElapsed / estSec * 100)
                      : Math.min(90, 90 * (1 - Math.exp(-testElapsed / 20)));
                    return (
                      <div>
                        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
                          <div style={{ color: 'var(--blue)', fontSize: 11 }}>
                            ⟳ {testFileType === 'video' ? 'Qwen VLM กำลังวิเคราะห์วิดีโอ…' : 'Qwen VLM กำลังประมวลผล…'}
                          </div>
                          <div style={{ fontFamily: "'IBM Plex Mono',monospace", fontSize: 12, color: 'var(--blue)', fontWeight: 700 }}>⏱ {fmtSec(testElapsed)}</div>
                        </div>
                        <div style={{ height: 6, background: 'rgba(29,110,245,.12)', borderRadius: 3, overflow: 'hidden' }}>
                          <div style={{ height: '100%', width: Math.round(pct) + '%', background: 'var(--blue)', borderRadius: 3, transition: 'width 0.5s ease' }} />
                        </div>
                        {testFileType === 'video' && (
                          <div style={{ marginTop: 4, fontSize: 10, color: 'var(--t3)', display: 'flex', justifyContent: 'space-between' }}>
                            <span>{Math.round(pct)}%</span>
                            <span>est. ~{fmtSec(estSec)}</span>
                          </div>
                        )}
                      </div>
                    );
                  })()}
                  {!testing && showRaw && rawJson && (
                    <pre style={{ margin: 0, fontSize: 10, lineHeight: 1.6, color: 'var(--t1)', whiteSpace: 'pre-wrap', wordBreak: 'break-all', fontFamily: "'IBM Plex Mono',monospace" }}>{JSON.stringify(rawJson, null, 2)}</pre>
                  )}
                  {!testing && !showRaw && videoFrames.length === 0 && !output && !savedOutput && <span style={{ color: 'var(--t3)', fontStyle: 'italic' }}>เลือกภาพ/วิดีโอ → กด ▶ Test Run เพื่อดู VLM output…</span>}
                  {!testing && !showRaw && videoFrames.length === 0 && !output && savedOutput && (
                    <div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
                        <span style={{ fontSize: 10, fontWeight: 700, color: 'var(--green)' }}>💾 Saved Result</span>
                        {savedAt && <span style={{ fontSize: 9, color: 'var(--t3)', fontFamily: "'IBM Plex Mono',monospace" }}>{new Date(savedAt).toLocaleString('th-TH', { dateStyle: 'medium', timeStyle: 'short' })}</span>}
                        {savedJson && (
                          <button onClick={function() { setRawJson(savedJson); setShowRaw(true); }}
                            style={{ fontSize: 9, padding: '1px 7px', borderRadius: 5, border: '1px solid var(--border2)', background: '#fff', color: 'var(--t2)', cursor: 'pointer', fontFamily: "'IBM Plex Mono',monospace" }}>{ '{ } JSON' }</button>
                        )}
                      </div>
                      {savedOutput.split('\n').map(function(l, i) { return <div key={i} style={{ marginBottom: 2 }}>{l || '\u00A0'}</div>; })}
                    </div>
                  )}
                  {!testing && !showRaw && output && (
                    <div>
                      <div style={{ fontSize: 10, fontWeight: 700, color: testStatus === 'ok' ? 'var(--green)' : 'var(--amber)', marginBottom: 6 }}>
                        {testStatus === 'ok' ? '✦ VLM Output' : '⚠ Qwen Service Offline'}
                      </div>
                      {output.split('\n').map(function(l, i) { return <div key={i} style={{ marginBottom: 2 }}>{l || '\u00A0'}</div>; })}
                    </div>
                  )}
                  {!testing && !showRaw && videoFrames.length > 0 && (
                    <div>
                      <div style={{ fontSize: 10, fontWeight: 700, color: 'var(--green)', marginBottom: 10 }}>✦ VLM Video Analysis — {videoFrames.length} frames</div>
                      {videoFrames.map(function(fr, i) {
                        return (
                          <div key={i} style={{ marginBottom: 14, paddingBottom: 12, borderBottom: i < videoFrames.length - 1 ? '1px solid var(--border)' : 'none' }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 6 }}>
                              <span style={{ background: 'var(--blue)', color: '#fff', fontSize: 9, fontWeight: 700, padding: '2px 8px', borderRadius: 10 }}>Frame {i + 1}</span>
                              <span style={{ fontSize: 10, color: 'var(--t3)', fontFamily: "'IBM Plex Mono',monospace" }}>⏱ {fr.timestamp_str}</span>
                            </div>
                            <div style={{ fontSize: 11, lineHeight: 1.7, color: 'var(--t1)' }}>
                              {fr.description.split('\n').map(function(l, li) { return <div key={li} style={{ marginBottom: 1 }}>{l || '\u00A0'}</div>; })}
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  )}
                </div>
                <Divider />
                <div style={{ fontSize: 11, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.07em', color: 'var(--t2)', marginBottom: 4, display: 'flex', alignItems: 'center', gap: 6 }}>
                  Usage Stats <span style={{ fontSize: 9, fontWeight: 400, color: 'var(--t3)', textTransform: 'none', letterSpacing: 0 }}>— coming soon</span>
                </div>
              </div>
            </>
          ) : (
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', flex: 1, color: 'var(--t3)', fontSize: 13 }}>Select a prompt to edit</div>
          )}
        </Panel>
      </div>
      <Modal show={showNew} onClose={function() { setShowNew(false); }} title="+ New Prompt Template"
        footer={<><Btn variant="ghost" onClick={function() { setShowNew(false); }}>Cancel</Btn><Btn variant="primary" onClick={createPrompt}>Save to Library</Btn></>}>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 10 }}>
          <FormGroup label="Prompt Name">
            <FormInput value={newName} onChange={function(e) { setNewName(e.target.value); }} placeholder="My Custom Prompt" />
          </FormGroup>
          <FormGroup label="Category">
            <select value={newType} onChange={function(e) { setNewType(e.target.value); }}
              style={{ background: 'var(--surface2)', border: '1px solid var(--border2)', borderRadius: 6, padding: '7px 10px', fontSize: 12, outline: 'none', width: '100%' }}>
              {tags.filter(function(t) { return t !== 'all'; }).map(function(t) { return <option key={t} value={t}>{t}</option>; })}
            </select>
          </FormGroup>
        </div>
        <FormGroup label="Prompt Text">
          <textarea value={newContent} onChange={function(e) { setNewContent(e.target.value); }} placeholder="Write your VLM prompt here…"
            style={{ width: '100%', background: 'var(--surface2)', border: '1px solid var(--border2)', borderRadius: 6, padding: '9px 10px', fontSize: 11, minHeight: 140, outline: 'none', lineHeight: 1.7, resize: 'vertical', fontFamily: 'inherit' }} />
        </FormGroup>
      </Modal>
    </div>
  );
}

// ── Page: Alert Center ───────────────────────────────────
function AlertCenter({ toast }) {
  const [alerts, setAlerts] = useState(ALERTS_SEED);
  const ackAll = () => { setAlerts(p => p.map(a => ({ ...a, unread: false }))); toast('All alerts acknowledged', '✓'); };
  const ack = id => { setAlerts(p => p.map(a => a.id === id ? { ...a, unread: false } : a)); toast('Acknowledged!', '✓'); };
  const sevIcons  = { critical: '🔴', high: '🟠', medium: '🟡', low: '🟢' };
  const sevColors = { critical: 'var(--red)', high: 'var(--red)', medium: 'var(--amber)', low: 'var(--gray)' };
  return (
    <div style={{ flex: 1, overflowY: 'auto', padding: 16 }}>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(5,1fr)', gap: 8, marginBottom: 16 }}>
        <KPICard value="2" label="Critical" color="red" /><KPICard value="3" label="High" color="amber" />
        <KPICard value="5" label="Acknowledged" color="green" /><KPICard value="12" label="Today Total" color="gray" />
        <KPICard value="8m" label="Avg Response" color="blue" />
      </div>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
        <div style={{ fontSize: 11, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.08em', color: 'var(--t2)', display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ display: 'inline-block', width: 12, height: 2, background: 'var(--blue)' }} />Alert Center — Active & Recent
        </div>
        <div style={{ display: 'flex', gap: 6 }}><Btn variant="ghost" onClick={ackAll}>Acknowledge All</Btn><Btn variant="ghost">Filter</Btn></div>
      </div>
      <Panel>
        <PanelHead title="Alerts — Today" right={<select style={{ background: 'var(--surface2)', border: '1px solid var(--border2)', borderRadius: 5, padding: '3px 8px', fontSize: 11, outline: 'none' }}><option>All Severity</option><option>Critical</option><option>High</option><option>Medium</option></select>} />
        {alerts.map(a => (
          <div key={a.id} style={{ display: 'flex', alignItems: 'flex-start', gap: 10, padding: '10px 14px', borderBottom: '1px solid var(--border)', borderLeft: `3px solid ${a.unread ? sevColors[a.sev] : 'transparent'}`, cursor: 'pointer', transition: 'background .15s' }}
            onMouseEnter={e => e.currentTarget.style.background = 'rgba(29,110,245,.03)'}
            onMouseLeave={e => e.currentTarget.style.background = 'transparent'}>
            <div style={{ width: 32, height: 32, borderRadius: 8, flexShrink: 0, background: `${sevColors[a.sev]}15`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 14, border: `1px solid ${sevColors[a.sev]}30` }}>{sevIcons[a.sev]}</div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 13, fontWeight: 600, marginBottom: 3 }}>{a.title}</div>
              <div style={{ fontSize: 11, color: 'var(--t2)', marginBottom: 5 }}>{a.sub}</div>
              <div style={{ display: 'flex', gap: 5, flexWrap: 'wrap' }}>
                {a.tags.map(t => <span key={t} style={{ fontSize: 9, padding: '2px 7px', borderRadius: 3, background: 'var(--surface2)', border: '1px solid var(--border2)', color: 'var(--t3)' }}>{t}</span>)}
              </div>
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: 6, flexShrink: 0 }}>
              <span style={{ fontSize: 10, color: 'var(--t3)', fontFamily: "'IBM Plex Mono',monospace" }}>{a.time}</span>
              <SevBadge sev={a.sev} />
              {a.unread ? <Btn variant="teal" size="sm" onClick={() => ack(a.id)}>Ack</Btn> : <span style={{ fontSize: 10, color: 'var(--t3)' }}>Acknowledged</span>}
            </div>
          </div>
        ))}
      </Panel>
    </div>
  );
}

// ── Page: Safety Rules ───────────────────────────────────
function SafetyRules({ toast }) {
  const [tab, setTab] = useState('all');
  const [allRules, setAllRules] = useState([]);
  const [loading, setLoading] = useState(true);
  const [procFilter, setProcFilter] = useState('');
  const [search, setSearch] = useState('');

  useEffect(() => {
    fetch(`${API}/api/processes/rules/all`)
      .then(r => r.ok ? r.json() : [])
      .then(data => { setAllRules(data); setLoading(false); })
      .catch(() => setLoading(false));
  }, []);

  const SEV_COLOR = { Low: 'var(--gray)', Medium: 'var(--blue)', High: 'var(--amber)', Critical: 'var(--red)' };
  const CAT_LABEL = { action: 'Unsafe Action', condition: 'Unsafe Condition', nearmiss: 'Near-Miss' };

  const processes = [...new Set(allRules.map(r => r.process_name))].filter(Boolean);
  const searchLow = search.toLowerCase();
  const filtered = allRules.filter(r =>
    (tab === 'all' || r.category === tab) &&
    (!procFilter || r.process_name === procFilter) &&
    (!search || (r.process_name || '').toLowerCase().includes(searchLow) ||
                (r.text || '').toLowerCase().includes(searchLow) ||
                (r.sop_code || '').toLowerCase().includes(searchLow))
  );
  const countByTab = cat => allRules.filter(r => r.category === cat).length;

  const tabs = [
    { key: 'all',       label: 'Show All' },
    { key: 'action',    label: 'Unsafe Actions' },
    { key: 'condition', label: 'Unsafe Conditions' },
    { key: 'nearmiss',  label: 'Near-Miss' },
  ];

  return (
    <div style={{ flex: 1, overflowY: 'auto', padding: 16 }}>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4,1fr)', gap: 8, marginBottom: 16 }}>
        <KPICard value={allRules.length} label="Total Rules" color="blue" />
        <KPICard value={countByTab('action')} label="Unsafe Actions" color="red" />
        <KPICard value={countByTab('condition')} label="Unsafe Conditions" color="amber" />
        <KPICard value={countByTab('nearmiss')} label="Near-Miss" color="green" />
      </div>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
        <div style={{ fontSize: 11, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.08em', color: 'var(--t2)', display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ display: 'inline-block', width: 12, height: 2, background: 'var(--blue)' }} />Safety Rule Management
        </div>
        <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
          <div style={{ position: 'relative' }}>
            <span style={{ position: 'absolute', left: 8, top: '50%', transform: 'translateY(-50%)', fontSize: 11, color: 'var(--t3)', pointerEvents: 'none' }}>⊕</span>
            <input
              value={search} onChange={e => setSearch(e.target.value)}
              placeholder="Search process, rule, SOP…"
              style={{ paddingLeft: 24, paddingRight: search ? 24 : 8, paddingTop: 5, paddingBottom: 5, width: 210, background: 'var(--surface2)', border: '1px solid var(--border2)', borderRadius: 6, fontSize: 11, outline: 'none', fontFamily: 'inherit', color: 'var(--t1)' }}
            />
            {search && (
              <button onClick={() => setSearch('')} style={{ position: 'absolute', right: 6, top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', cursor: 'pointer', fontSize: 12, color: 'var(--t3)', padding: 0, lineHeight: 1 }}>×</button>
            )}
          </div>
          <select value={procFilter} onChange={e => setProcFilter(e.target.value)}
            style={{ background: 'var(--surface2)', border: '1px solid var(--border2)', borderRadius: 6, padding: '5px 10px', fontSize: 11, outline: 'none', fontFamily: 'inherit' }}>
            <option value="">All Processes</option>
            {processes.map(p => <option key={p} value={p}>{p}</option>)}
          </select>
          <Btn variant="ghost" size="sm" onClick={() => { setLoading(true); fetch(`${API}/api/processes/rules/all`).then(r => r.ok ? r.json() : []).then(d => { setAllRules(d); setLoading(false); }).catch(() => setLoading(false)); }}>↺ Refresh</Btn>
        </div>
      </div>
      <div style={{ display: 'flex', gap: 5, marginBottom: 14, borderBottom: '1px solid var(--border)' }}>
        {tabs.map(t => (
          <button key={t.key} onClick={() => setTab(t.key)} style={{ padding: '7px 14px', border: 'none', background: 'transparent', cursor: 'pointer', fontSize: 12, fontWeight: tab === t.key ? 700 : 400, color: tab === t.key ? 'var(--blue)' : 'var(--t2)', fontFamily: 'inherit', borderBottom: `2px solid ${tab === t.key ? 'var(--blue)' : 'transparent'}`, transition: 'all .15s' }}>
            {t.label} ({t.key === 'all' ? allRules.length : countByTab(t.key)})
          </button>
        ))}
      </div>
      {loading && <div style={{ padding: 40, textAlign: 'center', color: 'var(--t3)', fontSize: 12 }}>Loading rules from DB…</div>}
      {!loading && filtered.map((r, i) => {
        const sevC = SEV_COLOR[r.severity] || 'var(--gray)';
        return (
          <div key={`${r.sop_id}-${r.id}-${i}`} style={{ display: 'flex', alignItems: 'flex-start', gap: 10, padding: '10px 14px', background: '#fff', border: '1px solid var(--border)', borderRadius: 8, marginBottom: 7 }}>
            <div style={{ width: 28, height: 28, borderRadius: 6, flexShrink: 0, background: `${sevC}18`, border: `1px solid ${sevC}35`, display: 'flex', alignItems: 'center', justifyContent: 'center', color: sevC, fontSize: 14 }}>⚑</div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 12, lineHeight: 1.6, marginBottom: 5 }}>{r.text}</div>
              <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', fontSize: 10, color: 'var(--t3)' }}>
                <span style={{ fontWeight: 700, color: sevC, textTransform: 'uppercase' }}>{r.severity}</span>
                <span style={{ background: 'var(--surface2)', borderRadius: 3, padding: '1px 6px' }}>{CAT_LABEL[r.category] || r.category}</span>
                <span style={{ color: 'var(--blue)', fontWeight: 600 }}>{r.process_name}</span>
                <span>SOP: {r.sop_code} — {r.sop_title}</span>
              </div>
            </div>
          </div>
        );
      })}
      {!loading && filtered.length === 0 && (
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', padding: 40, color: 'var(--t3)', gap: 8 }}>
          <span style={{ fontSize: 32, opacity: .3 }}>⚑</span>
          <span style={{ fontSize: 12 }}>{allRules.length === 0 ? 'No rules in DB — add rules in SOP Management' : 'No rules in this category'}</span>
        </div>
      )}
    </div>
  );
}

// ── Page: Event History ──────────────────────────────────
function EventHistory({ toast }) {
  const sevColors    = { critical: 'var(--red)', high: 'var(--red)', medium: 'var(--amber)', low: 'var(--gray)' };
  const statusColors = { Open: 'var(--red)', Ack: 'var(--amber)', Resolved: 'var(--green)' };
  return (
    <div style={{ flex: 1, overflowY: 'auto', padding: 16 }}>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4,1fr)', gap: 8, marginBottom: 16 }}>
        <KPICard value="247" label="This Month" color="blue" /><KPICard value="12" label="Critical Events" color="red" />
        <KPICard value="3" label="Near-Miss" color="amber" /><KPICard value="98%" label="Resolved" color="green" />
      </div>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
        <div style={{ fontSize: 11, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.08em', color: 'var(--t2)', display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ display: 'inline-block', width: 12, height: 2, background: 'var(--blue)' }} />Event History
        </div>
        <div style={{ display: 'flex', gap: 6 }}><Btn variant="ghost">Filter</Btn><Btn variant="ghost" onClick={() => toast('Exporting CSV…', '⬇')}>Export CSV</Btn></div>
      </div>
      <Panel>
        <PanelHead title="All Events" />
        <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', minWidth: 800 }}>
            <thead>
              <tr>{['Timestamp','Camera','Station','Severity','Type','Description','AI','Status','Action'].map(h => (
                <th key={h} style={{ padding: '8px 10px', borderBottom: '1.5px solid var(--border)', textAlign: 'left', fontSize: 10, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.06em', color: 'var(--t3)', background: '#eef3ff', position: 'sticky', top: 0, zIndex: 1 }}>{h}</th>
              ))}</tr>
            </thead>
            <tbody>
              {EVENTS.map((e, i) => (
                <tr key={i} onMouseEnter={ev => ev.currentTarget.style.background = 'rgba(29,110,245,.03)'} onMouseLeave={ev => ev.currentTarget.style.background = 'transparent'}>
                  <td style={{ padding: '8px 10px', borderBottom: '1px solid var(--border)', fontFamily: "'IBM Plex Mono',monospace", fontSize: 11, color: 'var(--t2)' }}>{e.ts}</td>
                  <td style={{ padding: '8px 10px', borderBottom: '1px solid var(--border)', fontSize: 11, color: 'var(--blue)', fontWeight: 600 }}>{e.cam}</td>
                  <td style={{ padding: '8px 10px', borderBottom: '1px solid var(--border)', fontSize: 11 }}>{e.stn}</td>
                  <td style={{ padding: '8px 10px', borderBottom: '1px solid var(--border)' }}><span style={{ fontSize: 10, fontWeight: 700, color: sevColors[e.sev], textTransform: 'uppercase' }}>{e.sev}</span></td>
                  <td style={{ padding: '8px 10px', borderBottom: '1px solid var(--border)', fontSize: 11 }}>{e.type}</td>
                  <td style={{ padding: '8px 10px', borderBottom: '1px solid var(--border)', fontSize: 11 }}>{e.desc}</td>
                  <td style={{ padding: '8px 10px', borderBottom: '1px solid var(--border)', textAlign: 'center', color: 'var(--green)', fontSize: 13 }}>{e.ai ? '✓' : '—'}</td>
                  <td style={{ padding: '8px 10px', borderBottom: '1px solid var(--border)' }}><span style={{ fontSize: 11, fontWeight: 600, color: statusColors[e.status] }}>{e.status}</span></td>
                  <td style={{ padding: '8px 10px', borderBottom: '1px solid var(--border)' }}><Btn variant="ghost" size="sm" onClick={() => toast('Viewing event…', '⊶')}>View</Btn></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Panel>
    </div>
  );
}

// ── Page: AI Video Analyze ───────────────────────────────
const STATUS_COLOR = { SAFE: 'green', WARNING: 'amber', DANGER: 'red' };
const STATUS_ICON  = { SAFE: '✓', WARNING: '⚠', DANGER: '✕' };

function AnalyzePage({ toast }) {
  const [camId, setCamId]       = useState(CAMERAS[0]?.id || '');
  const [interval, setInt]      = useState(3);
  const [file, setFile]         = useState(null);
  const [dragOver, setDragOver] = useState(false);
  const [job, setJob]           = useState(null);
  const [polling, setPolling]   = useState(false);
  const [jobs, setJobs]         = useState([]);
  // Process / SOP / Rule selector
  const [processes, setProcesses]   = useState([]);
  const [procId, setProcId]         = useState('');
  const [sops, setSops]             = useState([]);
  const [sopId, setSopId]           = useState('');
  const [sopDetail, setSopDetail]   = useState(null);
  const [ruleSets, setRuleSets]     = useState([]);
  const [ruleSetId, setRuleSetId]   = useState('');
  const [ruleDetail, setRuleDetail] = useState(null);
  const [showSop, setShowSop]       = useState(false);
  const [showRules, setShowRules]   = useState(false);
  const fileRef = useRef();

  // Load processes on mount
  useEffect(() => {
    fetch(`${API}/api/processes`).then(r => r.ok ? r.json() : []).then(setProcesses).catch(() => {});
  }, []);

  // Load SOPs + rule sets when process changes
  useEffect(() => {
    if (!procId) { setSops([]); setRuleSets([]); setSopId(''); setRuleSetId(''); setSopDetail(null); setRuleDetail(null); return; }
    fetch(`${API}/api/processes/${procId}/sops`).then(r => r.json()).then(data => {
      setSops(data);
      if (data[0]) setSopId(String(data[0].id));
    }).catch(() => {});
    fetch(`${API}/api/processes/${procId}/rule-sets`).then(r => r.json()).then(data => {
      setRuleSets(data);
      if (data[0]) setRuleSetId(String(data[0].id));
    }).catch(() => {});
  }, [procId]);

  // Load SOP detail when sopId changes
  useEffect(() => {
    if (!procId || !sopId) { setSopDetail(null); return; }
    fetch(`${API}/api/processes/${procId}/sops/${sopId}`).then(r => r.json()).then(setSopDetail).catch(() => {});
  }, [procId, sopId]);

  // Load rule set detail when ruleSetId changes
  useEffect(() => {
    if (!procId || !ruleSetId) { setRuleDetail(null); return; }
    fetch(`${API}/api/processes/${procId}/rule-sets/${ruleSetId}`).then(r => r.json()).then(setRuleDetail).catch(() => {});
  }, [procId, ruleSetId]);

  // Load past jobs
  useEffect(() => {
    fetch(`${API}/api/analyze`)
      .then(r => r.ok ? r.json() : [])
      .then(setJobs)
      .catch(() => {});
  }, [job]);

  // Poll job status
  useEffect(() => {
    if (!polling || !job) return;
    const id = setInterval(() => {
      fetch(`${API}/api/analyze/${job.job_id}`)
        .then(r => r.json())
        .then(data => {
          setJob(data);
          if (data.status === 'done' || data.status === 'done_no_ai' || data.status === 'failed') {
            setPolling(false);
            toast(data.status === 'failed' ? `Failed: ${data.error}` : 'Analysis complete!', data.status === 'failed' ? 'red' : 'green');
          }
        })
        .catch(() => {});
    }, 2000);
    return () => clearInterval(id);
  }, [polling, job]);

  const handleDrop = e => {
    e.preventDefault(); setDragOver(false);
    const f = e.dataTransfer.files[0];
    if (f && f.type.startsWith('video/')) setFile(f);
  };

  const handleSubmit = async () => {
    if (!file || !camId) { toast('Select camera and video file', 'amber'); return; }
    const fd = new FormData();
    fd.append('file', file);
    fd.append('camera_id', camId);
    fd.append('interval_sec', interval);
    if (procId) fd.append('process_id', procId);
    if (sopId) fd.append('sop_id', sopId);
    if (ruleSetId) fd.append('rule_set_id', ruleSetId);
    try {
      const res = await fetch(`${API}/api/analyze/video`, { method: 'POST', body: fd });
      if (!res.ok) throw new Error(await res.text());
      const data = await res.json();
      setJob(data); setPolling(true);
      toast('Analysis job started', 'blue');
    } catch (e) {
      toast(`Error: ${e.message}`, 'red');
    }
  };

  const loadJob = id => {
    fetch(`${API}/api/analyze/${id}`).then(r => r.json()).then(data => { setJob(data); setPolling(data.status === 'running' || data.status === 'pending'); });
  };

  const statusColor = s => (s === 'done' || s === 'done_no_ai') ? 'green' : s === 'failed' ? 'red' : s === 'running' ? 'blue' : 'gray';

  return (
    <div style={{ flex: 1, overflowY: 'auto', padding: 20, background: 'var(--bg)' }}>
      <div style={{ maxWidth: 900, margin: '0 auto' }}>
        <div style={{ fontSize: 16, fontWeight: 700, color: 'var(--t1)', marginBottom: 16 }}>AI Video Analyze</div>

        <div style={{ display: 'grid', gridTemplateColumns: '340px 1fr', gap: 16, alignItems: 'start' }}>

          {/* ── Upload panel ── */}
          <Panel>
            <PanelHead title="Upload Video" />
            <div style={{ padding: '12px 14px', display: 'flex', flexDirection: 'column', gap: 10 }}>

              <FormGroup label="Camera">
                <select value={camId} onChange={e => setCamId(e.target.value)}
                  style={{ width: '100%', fontSize: 12, padding: '5px 8px', border: '1.5px solid var(--border2)', borderRadius: 6, background: 'var(--surface2)', color: 'var(--t1)' }}>
                  {CAMERAS.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
                </select>
              </FormGroup>

              {/* ── Process / SOP / Rules selector ── */}
              <Divider />
              <div style={{ fontSize: 9, fontWeight: 700, color: 'var(--t3)', letterSpacing: '0.08em', textTransform: 'uppercase' }}>Process & Safety Reference</div>

              <FormGroup label="Process">
                <select value={procId} onChange={e => setProcId(e.target.value)}
                  style={{ width: '100%', fontSize: 12, padding: '5px 8px', border: '1.5px solid var(--border2)', borderRadius: 6, background: 'var(--surface2)', color: 'var(--t1)' }}>
                  <option value="">— None —</option>
                  {processes.map(p => <option key={p.id} value={String(p.id)}>{p.name_th || p.name}</option>)}
                </select>
              </FormGroup>

              {procId && sops.length > 0 && (<>
                <FormGroup label="SOP">
                  <select value={sopId} onChange={e => setSopId(e.target.value)}
                    style={{ width: '100%', fontSize: 12, padding: '5px 8px', border: '1.5px solid var(--border2)', borderRadius: 6, background: 'var(--surface2)', color: 'var(--t1)' }}>
                    {sops.map(s => <option key={s.id} value={String(s.id)}>{s.title_th || s.title}</option>)}
                  </select>
                </FormGroup>

                {/* Work Sequence Checklist */}
                {sopDetail?.steps?.length > 0 && (() => {
                  const parseBullets = desc => (desc || '').split('\n').map(l => l.trim()).filter(l => l.startsWith('-')).map(l => l.replace(/^-\s*/, ''));
                  let seqNum = 0;
                  return (
                    <div style={{ background: 'var(--surface2)', borderRadius: 7, border: '1px solid var(--border)', overflow: 'hidden' }}>
                      <div style={{ padding: '6px 10px', background: 'var(--blue-light)', borderBottom: '1px solid var(--border)', display: 'flex', alignItems: 'center', gap: 6 }}>
                        <span style={{ fontSize: 11 }}>📋</span>
                        <span style={{ fontSize: 10, fontWeight: 700, color: 'var(--blue)' }}>Work Sequence — {sopDetail.title_th}</span>
                        <span style={{ fontSize: 9, color: 'var(--t3)', marginLeft: 'auto' }}>v{sopDetail.version}</span>
                      </div>
                      <div style={{ maxHeight: 300, overflowY: 'auto' }}>
                        {sopDetail.steps.map(s => {
                          const bullets = parseBullets(s.description);
                          const isProhibited = b => b.startsWith('ห้าม');
                          return (
                            <div key={s.step_no} style={{ borderBottom: '1px solid var(--border)' }}>
                              {/* Step header */}
                              <div style={{ padding: '5px 10px', background: s.is_critical ? 'rgba(229,62,62,0.06)' : 'transparent', display: 'flex', alignItems: 'center', gap: 6 }}>
                                <div style={{ minWidth: 18, height: 18, borderRadius: '50%', background: s.is_critical ? 'var(--red)' : 'var(--blue)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 9, fontWeight: 700, color: '#fff', flexShrink: 0 }}>{s.step_no}</div>
                                <span style={{ fontSize: 10, fontWeight: 700, color: s.is_critical ? 'var(--red)' : 'var(--t1)' }}>{s.is_critical ? '⚠ ' : ''}{s.title_th}</span>
                                {s.is_critical && <span style={{ fontSize: 8, background: 'var(--red-light)', color: 'var(--red)', borderRadius: 3, padding: '1px 5px', marginLeft: 'auto', fontWeight: 600 }}>CRITICAL</span>}
                              </div>
                              {/* Sub-items */}
                              {bullets.map((b, bi) => {
                                seqNum++;
                                const prohibited = isProhibited(b);
                                return (
                                  <div key={bi} style={{ display: 'flex', alignItems: 'flex-start', gap: 6, padding: '3px 10px 3px 28px', background: prohibited ? 'rgba(229,62,62,0.03)' : 'transparent' }}>
                                    <div style={{ minWidth: 16, height: 16, borderRadius: 3, border: `1.5px solid ${prohibited ? 'var(--red)' : 'var(--border2)'}`, background: prohibited ? 'var(--red-light)' : '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 8, color: prohibited ? 'var(--red)' : 'var(--t3)', flexShrink: 0, marginTop: 1 }}>{prohibited ? '✕' : seqNum}</div>
                                    <span style={{ fontSize: 10, color: prohibited ? 'var(--red)' : 'var(--t2)', lineHeight: 1.5, fontWeight: prohibited ? 600 : 400 }}>
                                      {prohibited ? '🚫 ' : ''}{b}
                                    </span>
                                  </div>
                                );
                              })}
                            </div>
                          );
                        })}
                      </div>
                    </div>
                  );
                })()}
              </>)}

              {procId && ruleSets.length > 0 && (<>
                <FormGroup label="Safety Rules">
                  <select value={ruleSetId} onChange={e => setRuleSetId(e.target.value)}
                    style={{ width: '100%', fontSize: 12, padding: '5px 8px', border: '1.5px solid var(--border2)', borderRadius: 6, background: 'var(--surface2)', color: 'var(--t1)' }}>
                    {ruleSets.map(rs => <option key={rs.id} value={String(rs.id)}>{rs.title_th || rs.title}</option>)}
                  </select>
                </FormGroup>

                {/* Safety Rules — sequential anomaly checklist */}
                {ruleDetail?.categories && (
                  <div style={{ background: 'var(--surface2)', borderRadius: 7, border: '1px solid var(--border)', overflow: 'hidden' }}>
                    <div style={{ padding: '6px 10px', background: 'rgba(229,62,62,0.07)', borderBottom: '1px solid var(--border)', display: 'flex', alignItems: 'center', gap: 6 }}>
                      <span style={{ fontSize: 11 }}>🛡</span>
                      <span style={{ fontSize: 10, fontWeight: 700, color: 'var(--red)' }}>Safety Rules — Anomaly Checklist</span>
                      <span style={{ fontSize: 9, color: 'var(--t3)', marginLeft: 'auto' }}>v{ruleDetail.version}</span>
                    </div>
                    <div style={{ maxHeight: 280, overflowY: 'auto' }}>
                      {[
                        { cat: 'critical',        label: '🔴 Critical Rules',       color: 'var(--red)',   bg: 'rgba(229,62,62,0.08)' },
                        { cat: 'prohibited',       label: '🚫 Prohibited Actions',   color: 'var(--red)',   bg: 'rgba(229,62,62,0.04)' },
                        { cat: 'before',           label: '📌 ก่อนเริ่มงาน',          color: 'var(--blue)',  bg: 'var(--blue-light)' },
                        { cat: 'during',           label: '⚙ ระหว่างปฏิบัติงาน (During Operation)', color: 'var(--blue)', bg: 'var(--blue-light)' },
                        { cat: 'unsafe_condition', label: '⚠ สภาพไม่ปลอดภัย',        color: 'var(--amber)', bg: 'var(--amber-light)' },
                        { cat: 'safe_practice',    label: '✅ แนวทางที่ปลอดภัย',      color: 'var(--green)', bg: 'var(--green-light)' },
                        { cat: 'general',          label: '📋 กฎทั่วไป',              color: 'var(--t2)',    bg: 'transparent' },
                      ].map(({ cat, label, color, bg }) => {
                        const items = ruleDetail.categories[cat];
                        if (!items?.length) return null;
                        return (
                          <div key={cat} style={{ borderBottom: '1px solid var(--border)' }}>
                            <div style={{ padding: '4px 10px', background: bg, fontSize: 9, fontWeight: 700, color, letterSpacing: '0.05em' }}>{label}</div>
                            {cat === 'during' ? (() => {
                              // Group by sub_section and number sequentially
                              let seqN = 0;
                              const subSectionLabels = { '3.1':'3.1 การเข้าหาวัสดุ','3.2':'3.2 การใส่แกน (Rod)','3.3':'3.3 การยกวัสดุ','3.4':'3.4 การเคลื่อนย้าย','3.5':'3.5 การวางวัสดุ','3.6':'3.6 หลังปฏิบัติงาน' };
                              const groups = {};
                              items.forEach(item => { const k = item.sub_section || 'other'; if (!groups[k]) groups[k] = []; groups[k].push(item); });
                              return Object.entries(groups).map(([sub, subItems]) => (
                                <div key={sub}>
                                  {subSectionLabels[sub] && (
                                    <div style={{ padding: '3px 10px 2px 14px', fontSize: 9.5, fontWeight: 700, color: 'var(--blue)', background: 'var(--blue-light)', borderTop: '1px solid var(--border)' }}>
                                      {subSectionLabels[sub]}
                                    </div>
                                  )}
                                  {subItems.map((item, i) => {
                                    seqN++;
                                    return (
                                      <div key={i} style={{ display: 'flex', alignItems: 'flex-start', gap: 6, padding: '3px 10px 3px 14px', background: item.is_prohibited ? 'rgba(229,62,62,0.04)' : 'transparent' }}>
                                        <div style={{ minWidth: 18, height: 18, borderRadius: 3, border: `1.5px solid ${item.is_prohibited ? 'var(--red)' : item.severity === 'critical' ? 'var(--red)' : 'var(--border2)'}`, background: item.is_prohibited ? 'var(--red-light)' : '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 8, fontWeight: 700, color: item.is_prohibited ? 'var(--red)' : 'var(--t3)', flexShrink: 0, marginTop: 1 }}>{item.is_prohibited ? '✕' : seqN}</div>
                                        <span style={{ fontSize: 10, color: item.is_prohibited || item.severity === 'critical' ? 'var(--red)' : 'var(--t2)', lineHeight: 1.5, fontWeight: item.severity === 'critical' || item.is_prohibited ? 600 : 400, flex: 1 }}>
                                          {item.is_prohibited ? '🚫 ' : item.severity === 'critical' ? '⚠ ' : ''}{item.rule_text_th}
                                        </span>
                                        <span style={{ fontSize: 8, padding: '1px 4px', borderRadius: 3, background: item.severity === 'critical' ? 'var(--red-light)' : item.severity === 'high' ? 'var(--amber-light)' : 'var(--surface3)', color: item.severity === 'critical' ? 'var(--red)' : item.severity === 'high' ? 'var(--amber)' : 'var(--t3)', flexShrink: 0, alignSelf: 'center' }}>{item.severity?.toUpperCase()}</span>
                                      </div>
                                    );
                                  })}
                                </div>
                              ));
                            })() : items.map((item, i) => (
                              <div key={i} style={{ display: 'flex', alignItems: 'flex-start', gap: 6, padding: '3px 10px 3px 14px' }}>
                                <div style={{ minWidth: 14, height: 14, borderRadius: 2, border: `1.5px solid ${item.is_prohibited ? 'var(--red)' : item.severity === 'critical' ? 'var(--red)' : 'var(--border2)'}`, background: item.is_prohibited ? 'var(--red-light)' : '#fff', flexShrink: 0, marginTop: 2 }} />
                                <span style={{ fontSize: 10, color: item.is_prohibited || item.severity === 'critical' ? 'var(--red)' : 'var(--t2)', lineHeight: 1.5, fontWeight: item.severity === 'critical' ? 600 : 400 }}>
                                  {item.is_prohibited ? '🚫 ' : item.severity === 'critical' ? '⚠ ' : ''}{item.rule_text_th}
                                </span>
                                <span style={{ fontSize: 8, padding: '1px 4px', borderRadius: 3, background: item.severity === 'critical' ? 'var(--red-light)' : item.severity === 'high' ? 'var(--amber-light)' : 'var(--surface3)', color: item.severity === 'critical' ? 'var(--red)' : item.severity === 'high' ? 'var(--amber)' : 'var(--t3)', flexShrink: 0, alignSelf: 'center', marginLeft: 'auto' }}>{item.severity?.toUpperCase()}</span>
                              </div>
                            ))}
                          </div>
                        );
                      })}
                    </div>
                  </div>
                )}
              </>)}

              <Divider />
              <FormGroup label={`Frame interval: ${interval}s`}>
                <input type="range" min={1} max={10} value={interval} onChange={e => setInt(+e.target.value)}
                  style={{ width: '100%' }} />
              </FormGroup>

              {/* Drop zone */}
              <div
                onDrop={handleDrop}
                onDragOver={e => { e.preventDefault(); setDragOver(true); }}
                onDragLeave={() => setDragOver(false)}
                onClick={() => fileRef.current.click()}
                style={{ border: `2px dashed ${dragOver ? 'var(--blue)' : 'var(--border2)'}`, borderRadius: 8, padding: '20px 12px', textAlign: 'center', cursor: 'pointer', background: dragOver ? 'var(--blue-light)' : 'var(--surface2)', transition: 'all .15s' }}>
                <div style={{ fontSize: 24, marginBottom: 6 }}>▶</div>
                <div style={{ fontSize: 11, color: 'var(--t2)' }}>{file ? file.name : 'Drag & drop video or click to browse'}</div>
                {file && <div style={{ fontSize: 10, color: 'var(--t3)', marginTop: 4 }}>{(file.size / 1e6).toFixed(1)} MB</div>}
                <input ref={fileRef} type="file" accept="video/*" style={{ display: 'none' }} onChange={e => setFile(e.target.files[0])} />
              </div>

              <Btn variant="primary" onClick={handleSubmit} disabled={!file || !camId || polling}>
                {polling ? '⏳ Analyzing...' : '▶ Start Analysis'}
              </Btn>
            </div>
          </Panel>

          {/* ── Progress / Results ── */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            {job && (
              <Panel>
                <PanelHead title={`Job #${job.job_id} — ${job.camera_id}`}
                  right={<Badge color={statusColor(job.status)}>{job.status?.toUpperCase()}</Badge>} />
                <div style={{ padding: '10px 14px' }}>
                  {/* Progress bar */}
                  <div style={{ height: 6, background: 'var(--surface3)', borderRadius: 4, overflow: 'hidden', marginBottom: 10 }}>
                    <div style={{ height: '100%', width: `${job.progress_pct || 0}%`, background: job.status === 'done' ? 'var(--green)' : job.status === 'failed' ? 'var(--red)' : 'var(--blue)', borderRadius: 4, transition: 'width .4s' }} />
                  </div>
                  <div style={{ fontSize: 11, color: 'var(--t3)', marginBottom: 12 }}>
                    {job.processed_frames || 0} / {job.total_frames || '?'} frames · {job.progress_pct || 0}%
                    {job.error && <span style={{ color: 'var(--red)', marginLeft: 8 }}>{job.error}</span>}
                  </div>

                  {/* Frame results grid */}
                  {(job.frames || []).length > 0 && (
                    <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                      {job.frames.map((f, i) => (
                        <div key={i} style={{ display: 'flex', gap: 10, background: 'var(--surface2)', borderRadius: 8, overflow: 'hidden', border: '1px solid var(--border)' }}>
                          {f.frame_url && (
                            <img src={`${API}${f.frame_url}`} alt={f.timestamp_str}
                              style={{ width: 100, height: 70, objectFit: 'cover', flexShrink: 0 }} />
                          )}
                          <div style={{ flex: 1, padding: '8px 10px 8px 0', minWidth: 0 }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 4 }}>
                              <span style={{ fontSize: 10, color: 'var(--t3)', fontWeight: 600 }}>{f.timestamp_str}</span>
                              <SevBadge sev={f.safety_status === 'DANGER' ? 'critical' : f.safety_status === 'WARNING' ? 'high' : 'low'}>
                                {STATUS_ICON[f.safety_status]} {f.safety_status}
                              </SevBadge>
                              {f.latency_ms && <span style={{ fontSize: 9, color: 'var(--t3)' }}>{f.latency_ms}ms</span>}
                            </div>
                            <div style={{ fontSize: 11, color: 'var(--t2)', lineHeight: 1.4, overflow: 'hidden', display: '-webkit-box', WebkitLineClamp: 3, WebkitBoxOrient: 'vertical' }}>
                              {f.description}
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              </Panel>
            )}

            {/* Past jobs */}
            {jobs.length > 0 && (
              <Panel>
                <PanelHead title="Past Jobs" />
                <div style={{ padding: '8px 14px', display: 'flex', flexDirection: 'column', gap: 4 }}>
                  {jobs.map(j => (
                    <div key={j.job_id} onClick={() => loadJob(j.job_id)}
                      style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '6px 8px', borderRadius: 6, cursor: 'pointer', background: job?.job_id === j.job_id ? 'var(--blue-light)' : 'transparent', transition: 'all .1s' }}>
                      <Badge color={statusColor(j.status)} style={{ fontSize: 9, minWidth: 52, textAlign: 'center' }}>{j.status}</Badge>
                      <span style={{ fontSize: 11, color: 'var(--t2)', flex: 1 }}>Job #{j.job_id} · {j.camera_id}</span>
                      <span style={{ fontSize: 10, color: 'var(--t3)' }}>{j.processed_frames}/{j.total_frames || '?'} frames</span>
                    </div>
                  ))}
                </div>
              </Panel>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

// ── Page: Analytics ──────────────────────────────────────
function Analytics() {
  const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
  const vals = [4,7,3,12,8,2,5];
  const maxV = Math.max(...vals);
  const barColor = v => v >= 10 ? 'var(--red)' : v >= 6 ? 'var(--amber)' : 'var(--blue)';
  const processes = [
    {name:'Press',score:72,color:'var(--amber)'},{name:'Welding',score:88,color:'var(--green)'},
    {name:'Sampling',score:91,color:'var(--green)'},{name:'Robot',score:95,color:'var(--blue)'},
    {name:'Packing',score:99,color:'var(--blue)'},
  ];
  return (
    <div style={{ flex: 1, overflowY: 'auto', padding: 16 }}>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(5,1fr)', gap: 8, marginBottom: 16 }}>
        <KPICard value="92%" label="Safety Score"    delta="↑ +3% vs last month" color="green" />
        <KPICard value="15"  label="Total Incidents" delta="↑ 2 vs last month"   color="red" />
        <KPICard value="3"   label="Near-Miss"       delta="= same as last month" color="amber" />
        <KPICard value="98%" label="PPE Compliance"  delta="↑ +1%"               color="green" />
        <KPICard value="94%" label="SOP Compliance"  delta="↑ +2%"               color="blue" />
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, marginBottom: 12 }}>
        <Panel>
          <PanelHead title="Alerts by Day — This Week" />
          <div style={{ padding: '14px 16px' }}>
            <div style={{ display: 'flex', alignItems: 'flex-end', gap: 8, height: 110 }}>
              {days.map((d, i) => {
                const h = Math.round((vals[i] / maxV) * 90);
                return (
                  <div key={d} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4, flex: 1 }}>
                    <div style={{ fontSize: 11, fontWeight: 700, color: barColor(vals[i]) }}>{vals[i]}</div>
                    <div style={{ width: '100%', height: h, background: barColor(vals[i]), borderRadius: '4px 4px 0 0', opacity: .85 }} />
                    <div style={{ fontSize: 10, color: 'var(--t3)' }}>{d}</div>
                  </div>
                );
              })}
            </div>
          </div>
        </Panel>
        <Panel>
          <PanelHead title="Incident Category Breakdown" />
          <div style={{ padding: '14px 16px', display: 'flex', alignItems: 'center', gap: 20 }}>
            <svg width={110} height={110} viewBox="0 0 100 100">
              <circle cx="50" cy="50" r="36" fill="none" stroke="#e8effe" strokeWidth="16" />
              <circle cx="50" cy="50" r="36" fill="none" stroke="var(--red)" strokeWidth="16" strokeDasharray="72 154" strokeDashoffset="25" transform="rotate(-90 50 50)" />
              <circle cx="50" cy="50" r="36" fill="none" stroke="var(--amber)" strokeWidth="16" strokeDasharray="55 154" strokeDashoffset="-47" transform="rotate(-90 50 50)" />
              <circle cx="50" cy="50" r="36" fill="none" stroke="var(--blue)" strokeWidth="16" strokeDasharray="40 154" strokeDashoffset="-102" transform="rotate(-90 50 50)" />
            </svg>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              {[{label:'Unsafe Action',pct:'43%',color:'var(--red)'},{label:'Unsafe Condition',pct:'33%',color:'var(--amber)'},{label:'Near-Miss',pct:'24%',color:'var(--blue)'}].map(l => (
                <div key={l.label} style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 12 }}>
                  <div style={{ width: 10, height: 10, borderRadius: '50%', background: l.color, flexShrink: 0 }} />
                  <span style={{ color: 'var(--t2)' }}>{l.label}</span>
                  <span style={{ marginLeft: 'auto', fontWeight: 700, color: l.color, fontSize: 13 }}>{l.pct}</span>
                </div>
              ))}
            </div>
          </div>
        </Panel>
        <Panel>
          <PanelHead title="Top Cameras by Alert Count" />
          <div>
            <table style={{ width: '100%', borderCollapse: 'collapse' }}>
              <thead><tr>{['Camera','Station','Alerts','Risk'].map(h => <th key={h} style={{ padding: '8px 12px', borderBottom: '1px solid var(--border)', textAlign: 'left', fontSize: 10, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.06em', color: 'var(--t3)', background: '#eef3ff' }}>{h}</th>)}</tr></thead>
              <tbody>
                {[['CAM-A01','Press 01',18,'critical'],['CAM-A03','Sampling 03',11,'medium'],['CAM-B01','Welding 01',7,'medium'],['CAM-C02','Assembly 02',3,'low']].map(r => (
                  <tr key={r[0]}>
                    <td style={{ padding: '8px 12px', borderBottom: '1px solid var(--border)', fontSize: 12, color: 'var(--blue)', fontWeight: 600 }}>{r[0]}</td>
                    <td style={{ padding: '8px 12px', borderBottom: '1px solid var(--border)', fontSize: 12 }}>{r[1]}</td>
                    <td style={{ padding: '8px 12px', borderBottom: '1px solid var(--border)', fontSize: 13, fontWeight: 700, color: r[2] === 'critical' ? 'var(--red)' : 'var(--amber)' }}>{r[2]}</td>
                    <td style={{ padding: '8px 12px', borderBottom: '1px solid var(--border)' }}><StatusPill status={r[3] === 'low' ? 'online' : r[3] === 'critical' ? 'critical' : 'delay'} /></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Panel>
        <Panel>
          <PanelHead title="SOP Compliance by Process" />
          <div style={{ padding: '14px 16px' }}>
            {processes.map(p => (
              <div key={p.name} style={{ marginBottom: 12 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 5, fontSize: 12 }}><span style={{ color: 'var(--t2)' }}>{p.name}</span><span style={{ fontWeight: 700, color: p.color }}>{p.score}%</span></div>
                <div style={{ height: 6, background: '#dce6f8', borderRadius: 3, overflow: 'hidden' }}><div style={{ height: '100%', width: `${p.score}%`, background: p.color, borderRadius: 3 }} /></div>
              </div>
            ))}
          </div>
        </Panel>
      </div>
    </div>
  );
}

// ── Page: Settings ───────────────────────────────────────
function Settings() {
  return (
    <div style={{ flex: 1, overflowY: 'auto', padding: 16 }}>
      <Panel><PanelHead title="Admin / Settings" icon="⚙" /><div style={{ padding: 20, color: 'var(--t3)', fontSize: 13 }}>Settings panel — coming soon.</div></Panel>
    </div>
  );
}

// ── Root App ─────────────────────────────────────────────
function App() {
  const [page, setPage] = useState('dashboard');
  const [selectedCam, setSelectedCam] = useState(null);
  const [clock, setClock] = useState('');
  const { toasts, add: toast } = useToast();

  useEffect(() => {
    const fmt = () => {
      const n = new Date();
      setClock(`${n.toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' })} — ${n.toLocaleTimeString('en-GB')}`);
    };
    fmt();
    const t = setInterval(fmt, 1000);
    return () => clearInterval(t);
  }, []);

  const nav = key => { if (key !== 'dashboard' && key !== 'cameras') setSelectedCam(null); setPage(key); };
  const openCamera = cam => { setSelectedCam(cam); setPage('detail'); };

  const renderPage = () => {
    if (page === 'detail' && selectedCam) return <CameraDetail cam={selectedCam} onBack={() => nav('dashboard')} toast={toast} />;
    if (page === 'cameras')   return <CameraFleetPage onOpenCamera={openCamera} toast={toast} />;
    if (page === 'sop')       return <SOPManagement toast={toast} />;
    if (page === 'prompts')   return <PromptLibrary toast={toast} />;
    if (page === 'alerts')    return <AlertCenter toast={toast} />;
    if (page === 'rules')     return <SafetyRules toast={toast} />;
    if (page === 'events')    return <EventHistory toast={toast} />;
    if (page === 'analyze')   return <AnalyzePage toast={toast} />;
    if (page === 'analytics') return <Analytics />;
    if (page === 'settings')  return <Settings />;
    return <Dashboard onOpenCamera={openCamera} />;
  };

  const activeNav = page === 'detail' ? 'cameras' : page;

  return (
    <div style={{ display: 'flex', height: '100vh', overflow: 'hidden', background: 'var(--bg)' }}>
      <Sidebar active={activeNav} onNav={nav} />
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden', minWidth: 0 }}>
        <Topbar clock={clock} />
        <div style={{ flex: 1, display: 'flex', overflow: 'hidden' }}>{renderPage()}</div>
      </div>
      <ToastContainer toasts={toasts} />
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
