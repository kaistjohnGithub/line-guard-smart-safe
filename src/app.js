const { useState, useEffect, useRef, useCallback } = React;

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
    amber: { background: 'var(--amber-light)', borderColor: 'rgba(217,119,6,.35)', color: 'var(--amber)' },
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

function FormInput({ value, onChange, placeholder, style = {} }) {
  return (
    <input value={value || ''} onChange={e => onChange && onChange(e.target.value)}
      placeholder={placeholder}
      style={{
        background: 'var(--surface2)', border: '1px solid var(--border2)',
        borderRadius: 6, padding: '7px 10px', color: 'var(--t1)', fontSize: 12,
        outline: 'none', width: '100%', ...style,
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
function CameraDetail({ cam, onBack, toast }) {
  const [selPrompt, setSelPrompt] = useState(0);
  const [promptText, setPromptText] = useState(PROMPTS[0].text);
  const [vlmRunning, setVlmRunning] = useState(false);
  const [showModal, setShowModal] = useState(false);

  const runVLM = () => {
    setVlmRunning(true); toast('VLM กำลังวิเคราะห์วิดีโอ…', '✦');
    setTimeout(() => { setVlmRunning(false); toast('VLM วิเคราะห์เสร็จแล้ว!', '✓'); }, 2200);
  };

  const sopSteps = [
    { text: 'Scan barcode at entry point', st: 'ok' },
    { text: 'Check machine status light', st: 'ok' },
    { text: 'Confirm full stop before cover open', st: 'skip' },
    { text: 'Sample inspection per standard', st: 'na' },
    { text: 'Record result in system', st: 'na' },
  ];
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
          Build: <b style={{ color: 'var(--t1)' }}>A1</b> &nbsp;|&nbsp; Process: <b style={{ color: 'var(--t1)' }}>Assembly</b> &nbsp;|&nbsp; CCTV: <b style={{ color: 'var(--blue)' }}>{cam.id}</b>
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
            <PanelHead title={`Live CCTV — ${cam.name}`} icon="⬡"
              right={<><Badge>{cam.fps} FPS</Badge><Badge color="blue">VLM v2.1</Badge></>} />
            {cam.videoSrc ? (
              <video src={cam.videoSrc} autoPlay muted loop controls
                style={{ width: '100%', maxHeight: 280, objectFit: 'contain', display: 'block', background: '#0a1020' }} />
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
              </div>
            )}
            <div style={{ display: 'flex', gap: 5, padding: '7px 10px', background: '#f0f5ff', borderTop: '1px solid var(--border)', flexWrap: 'wrap' }}>
              {[{l:'● LIVE',a:true},{l:'⏸ Pause'},{l:'⏪ Playback'},{l:'📷 Snapshot'},{l:'Overlay ON',a:true},{l:'Zone ON',a:true},{l:'BBox ON',a:true},{l:'⛶ Full'}].map(b => (
                <button key={b.l} onClick={() => toast(b.l, '▶')} style={{ padding: '3px 9px', borderRadius: 4, fontSize: 10, fontWeight: 500, border: `1px solid ${b.a ? 'rgba(29,110,245,.35)' : 'var(--border2)'}`, background: b.a ? 'rgba(29,110,245,.1)' : 'var(--surface2)', color: b.a ? 'var(--blue)' : 'var(--t2)', cursor: 'pointer', fontFamily: 'inherit' }}>{b.l}</button>
              ))}
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
            <PanelHead title="SOP / Standard Work" icon="≡" right={<><Badge color="blue">v1.3</Badge><Btn variant="ghost" size="sm">Edit</Btn></>} />
            <div style={{ padding: '10px 12px' }}>
              <div style={{ fontSize: 10, color: 'var(--t3)', marginBottom: 8 }}>K.Somsak · 10 Mar 2026</div>
              {sopSteps.map((s, i) => {
                const ts = s.st === 'ok' ? { bg: 'var(--green-light)', border: 'rgba(22,163,74,.3)', color: 'var(--green)', label: '✓ OK' }
                  : s.st === 'skip' ? { bg: 'var(--red-light)', border: 'rgba(229,62,62,.3)', color: 'var(--red)', label: '✗ SKIP' }
                  : { bg: 'rgba(100,116,139,.1)', border: 'rgba(100,116,139,.25)', color: 'var(--gray)', label: 'N/A' };
                return (
                  <div key={i} style={{ display: 'flex', alignItems: 'flex-start', gap: 9, padding: '6px 0', borderBottom: '1px solid var(--border)' }}>
                    <div style={{ width: 20, height: 20, borderRadius: '50%', flexShrink: 0, background: 'rgba(29,110,245,.09)', border: '1px solid rgba(29,110,245,.2)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 9, fontWeight: 700, color: 'var(--blue)', marginTop: 1 }}>{i + 1}</div>
                    <div style={{ flex: 1, fontSize: 12, lineHeight: 1.6 }}>{s.text}</div>
                    <span style={{ fontSize: 8, padding: '2px 5px', borderRadius: 3, flexShrink: 0, background: ts.bg, border: `1px solid ${ts.border}`, color: ts.color, fontWeight: 700, marginTop: 2, whiteSpace: 'nowrap' }}>{ts.label}</span>
                  </div>
                );
              })}
              <div style={{ display: 'flex', gap: 6, marginTop: 10 }}>
                <Btn variant="teal" size="sm" onClick={() => toast('AI analyzing…', '✦')}>✦ AI Suggest</Btn>
                <Btn variant="ghost" size="sm">Full SOP</Btn>
              </div>
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
function SOPManagement({ toast }) {
  const [selSop, setSelSop] = useState(0);
  const [steps, setSteps] = useState(SOP_STEPS);
  const [showNew, setShowNew] = useState(false);
  const [showHist, setShowHist] = useState(false);
  const statusColors = { published: 'var(--green)', draft: 'var(--amber)', review: 'var(--red)' };
  const addStep = () => setSteps(p => [...p, { id: Date.now(), text: '', risk: 'Low', ppe: [] }]);

  return (
    <div style={{ flex: 1, overflowY: 'auto', padding: 16 }}>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4,1fr)', gap: 8, marginBottom: 16 }}>
        <KPICard value="12" label="Total SOPs"   color="blue" /><KPICard value="10" label="Published" color="green" />
        <KPICard value="2"  label="Draft"        color="amber" /><KPICard value="1" label="Needs Review" color="red" />
      </div>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
        <div style={{ fontSize: 11, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.08em', color: 'var(--t2)', display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ display: 'inline-block', width: 12, height: 2, background: 'var(--blue)' }} />SOP Management
        </div>
        <div style={{ display: 'flex', gap: 6 }}>
          <Btn variant="teal" onClick={() => setShowNew(true)}>+ New SOP</Btn>
          <Btn variant="ghost" onClick={() => toast('Exporting…', '⬇')}>Export All</Btn>
        </div>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: '260px 1fr', gap: 10, minHeight: 500 }}>
        <Panel>
          <PanelHead title="SOP List" right={<input placeholder="Search…" style={{ width: 90, background: 'var(--surface2)', border: '1px solid var(--border2)', borderRadius: 4, padding: '3px 7px', fontSize: 10, outline: 'none' }} />} />
          <div style={{ overflowY: 'auto', flex: 1 }}>
            {SOP_DATA.map((s, i) => (
              <div key={s.id} onClick={() => setSelSop(i)}
                style={{ padding: '9px 14px', borderBottom: '1px solid var(--border)', cursor: 'pointer', borderLeft: `2px solid ${selSop === i ? 'var(--blue)' : 'transparent'}`, background: selSop === i ? 'rgba(29,110,245,.06)' : 'transparent', transition: 'all .15s' }}>
                <div style={{ fontSize: 9, fontWeight: 600, marginBottom: 2, display: 'flex', alignItems: 'center', gap: 6 }}>
                  <span style={{ color: 'var(--blue)' }}>{s.id}</span>
                  <span style={{ fontSize: 8, fontWeight: 700, padding: '1px 5px', borderRadius: 3, background: `${statusColors[s.status]}18`, border: `1px solid ${statusColors[s.status]}40`, color: statusColors[s.status], textTransform: 'uppercase' }}>{s.status}</span>
                </div>
                <div style={{ fontSize: 12, fontWeight: 500, marginBottom: 2 }}>{s.name}</div>
                <div style={{ fontSize: 10, color: 'var(--t3)' }}>{s.process} · {s.ver} · {s.updated}</div>
              </div>
            ))}
          </div>
        </Panel>
        <Panel style={{ overflow: 'hidden' }}>
          <PanelHead title={`Edit — ${SOP_DATA[selSop].id}`} icon="≡"
            right={<><Badge color="blue">{SOP_DATA[selSop].ver}</Badge><Btn variant="ghost" size="sm" onClick={() => setShowHist(true)}>History</Btn><Btn variant="ghost" size="sm" onClick={() => toast('Draft saved!', '✓')}>Save Draft</Btn><Btn variant="primary" size="sm" onClick={() => toast('Published!', '⬆')}>⬆ Publish</Btn></>} />
          <div style={{ overflowY: 'auto', flex: 1, padding: 14 }}>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 12 }}>
              <FormGroup label="SOP Title"><FormInput value={SOP_DATA[selSop].name} /></FormGroup>
              <FormGroup label="Process / Station"><FormInput value={SOP_DATA[selSop].process} /></FormGroup>
              <FormGroup label="Effective Date"><FormInput value="2026-03-01" /></FormGroup>
              <FormGroup label="Owner"><FormInput value={`${SOP_DATA[selSop].by} (Safety Officer)`} /></FormGroup>
            </div>
            <Divider />
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
              <div style={{ fontSize: 11, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.07em', color: 'var(--t2)' }}>Work Steps</div>
              <div style={{ display: 'flex', gap: 6 }}>
                <Btn variant="ghost" size="sm" onClick={addStep}>+ Add Step</Btn>
                <Btn variant="teal" size="sm" onClick={() => toast('AI generating from video…', '✦')}>✦ AI Generate</Btn>
              </div>
            </div>
            {steps.map((s, i) => (
              <div key={s.id} style={{ background: 'var(--surface2)', border: '1px solid var(--border)', borderRadius: 6, marginBottom: 6, overflow: 'hidden' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '7px 10px', background: '#e8f0ff', borderBottom: '1px solid var(--border)' }}>
                  <div style={{ width: 22, height: 22, borderRadius: '50%', background: 'rgba(29,110,245,.1)', border: '1px solid rgba(29,110,245,.2)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 10, fontWeight: 700, color: 'var(--blue)', flexShrink: 0 }}>{i + 1}</div>
                  <input value={s.text} onChange={e => setSteps(p => p.map((x, j) => j === i ? { ...x, text: e.target.value } : x))}
                    placeholder="Enter step description…"
                    style={{ flex: 1, background: 'transparent', border: 'none', outline: 'none', fontSize: 12, color: 'var(--t1)', fontFamily: 'inherit' }} />
                  <div style={{ display: 'flex', gap: 4 }}>
                    {['↑', '↓'].map(d => <Btn key={d} variant="ghost" size="sm" onClick={() => toast(`Step moved ${d}`, '↕')}>{d}</Btn>)}
                    <Btn variant="danger" size="sm" onClick={() => setSteps(p => p.filter((_, j) => j !== i))}>✕</Btn>
                  </div>
                </div>
                <div style={{ padding: '6px 10px', display: 'flex', alignItems: 'center', gap: 10, fontSize: 11 }}>
                  <span style={{ color: 'var(--t3)' }}>Risk if skipped:</span>
                  <select value={s.risk} onChange={e => setSteps(p => p.map((x, j) => j === i ? { ...x, risk: e.target.value } : x))} style={{ background: 'transparent', border: '1px solid var(--border2)', borderRadius: 4, padding: '2px 6px', fontSize: 10, outline: 'none' }}>
                    <option>Low</option><option>High</option><option>Critical</option>
                  </select>
                  <span style={{ color: 'var(--t3)', marginLeft: 8 }}>PPE:</span>
                  {['Gloves', 'Face Shield'].map(p => (
                    <label key={p} style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 10, color: 'var(--t2)', cursor: 'pointer' }}>
                      <input type="checkbox" defaultChecked={s.ppe && s.ppe.includes(p)} />{p}
                    </label>
                  ))}
                </div>
              </div>
            ))}
            <Divider />
            <FormGroup label="Version Notes"><textarea defaultValue="Updated step 3: Added dual-confirmation requirement…" style={{ width: '100%', background: 'var(--surface2)', border: '1px solid var(--border2)', borderRadius: 6, padding: '7px 10px', fontSize: 12, minHeight: 55, outline: 'none', lineHeight: 1.6, resize: 'vertical', fontFamily: 'inherit' }} /></FormGroup>
            <Divider />
            <div style={{ fontSize: 11, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.07em', color: 'var(--t2)', marginBottom: 8 }}>Version History</div>
            {VERSION_HISTORY.map(h => (
              <div key={h.ver} style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '7px 0', borderBottom: '1px solid var(--border)', fontSize: 11 }}>
                <span style={{ width: 32, fontSize: 10, fontWeight: 700, color: 'var(--blue)', textAlign: 'center' }}>{h.ver}</span>
                <span style={{ flex: 1, color: 'var(--t2)' }}>{h.note} <span style={{ color: 'var(--t3)' }}>— {h.by}</span></span>
                <span style={{ fontSize: 9, padding: '2px 6px', borderRadius: 3, background: h.type === 'add' ? 'var(--green-light)' : 'var(--amber-light)', border: `1px solid ${h.type === 'add' ? 'rgba(22,163,74,.3)' : 'rgba(217,119,6,.3)'}`, color: h.type === 'add' ? 'var(--green)' : 'var(--amber)', fontWeight: 600 }}>{h.type === 'add' ? '+ Added' : '~ Modified'}</span>
                <span style={{ fontSize: 10, color: 'var(--t3)' }}>{h.date}</span>
                <Btn variant="ghost" size="sm" onClick={() => toast(`Restored ${h.ver}!`, '↩')}>Restore</Btn>
              </div>
            ))}
          </div>
        </Panel>
      </div>
      <Modal show={showNew} onClose={() => setShowNew(false)} title="+ New SOP" footer={<><Btn variant="ghost" onClick={() => setShowNew(false)}>Cancel</Btn><Btn variant="primary" onClick={() => { toast('SOP created!', '✓'); setShowNew(false); }}>Create</Btn></>}>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 10 }}>
          <FormGroup label="SOP ID"><FormInput placeholder="e.g. SOP-013" /></FormGroup>
          <FormGroup label="Title"><FormInput placeholder="SOP Title" /></FormGroup>
          <FormGroup label="Process"><FormInput placeholder="Assembly A" /></FormGroup>
          <FormGroup label="Station"><FormInput placeholder="Station 01" /></FormGroup>
        </div>
        <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
          <select style={{ flex: 1, background: 'var(--surface2)', border: '1px solid var(--border2)', borderRadius: 6, padding: '7px 10px', fontSize: 12, outline: 'none' }}><option>CAM-A01 — Press Machine 1</option></select>
          <Btn variant="teal" onClick={() => toast('AI generating SOP from video…', '✦')}>✦ Generate from Video</Btn>
        </div>
      </Modal>
      <Modal show={showHist} onClose={() => setShowHist(false)} title="Version History — SOP-001" footer={<Btn variant="ghost" onClick={() => setShowHist(false)}>Close</Btn>}>
        {VERSION_HISTORY.map(h => (
          <div key={h.ver} style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '8px 0', borderBottom: '1px solid var(--border)', fontSize: 12 }}>
            <span style={{ width: 36, fontWeight: 700, color: 'var(--blue)' }}>{h.ver}</span>
            <span style={{ flex: 1, color: 'var(--t2)' }}>{h.note}</span>
            <span style={{ color: 'var(--t3)', fontSize: 10 }}>{h.by}</span>
            <span style={{ color: 'var(--t3)', fontSize: 10, marginLeft: 8 }}>{h.date}</span>
            <Btn variant="ghost" size="sm" onClick={() => { toast(`Restored ${h.ver}!`, '↩'); setShowHist(false); }}>Restore</Btn>
          </div>
        ))}
      </Modal>
    </div>
  );
}

// ── Page: Prompt Library ─────────────────────────────────
function PromptLibrary({ toast }) {
  const [sel, setSel] = useState(0);
  const [filter, setFilter] = useState('all');
  const [promptText, setPromptText] = useState(PROMPTS[0].text);
  const [testing, setTesting] = useState(false);
  const [output, setOutput] = useState('');
  const [showNew, setShowNew] = useState(false);
  const tags = ['all', 'SAFETY', 'SOP', 'RULE GEN', 'PPE', 'NEAR-MISS', 'CUSTOM'];
  const filtered = filter === 'all' ? PROMPTS : PROMPTS.filter(p => p.type === filter);
  const runTest = () => {
    setTesting(true); setOutput(''); toast('Testing prompt on latest footage…', '✦');
    setTimeout(() => { setTesting(false); setOutput('Risk Level: CRITICAL\nOperator approaching press zone without confirmation. Guard not verified. Hand within unsafe proximity during active cycle. Near-miss detected at frame 1340.\n\nRecommendations: 3 safety rules, 2 SOP updates required.'); }, 2400);
  };
  return (
    <div style={{ flex: 1, overflowY: 'auto', padding: 16 }}>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4,1fr)', gap: 8, marginBottom: 16 }}>
        <KPICard value="14" label="Total Prompts"    color="blue" /><KPICard value="6" label="System Templates" color="green" />
        <KPICard value="5"  label="Custom"           color="amber" /><KPICard value="3" label="Pinned" color="gray" />
      </div>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
        <div style={{ fontSize: 11, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.08em', color: 'var(--t2)', display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ display: 'inline-block', width: 12, height: 2, background: 'var(--blue)' }} />Prompt Library
        </div>
        <div style={{ display: 'flex', gap: 6 }}>
          <Btn variant="teal" onClick={() => setShowNew(true)}>+ New Prompt</Btn>
          <Btn variant="ghost" onClick={() => toast('Exporting…', '⬇')}>Export</Btn>
        </div>
      </div>
      <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 14 }}>
        {tags.map(t => (
          <button key={t} onClick={() => setFilter(t)} style={{ padding: '4px 14px', borderRadius: 20, fontSize: 10, fontWeight: 600, cursor: 'pointer', border: `1.5px solid ${filter === t ? 'var(--blue)' : 'var(--border2)'}`, background: filter === t ? 'var(--blue-light)' : '#fff', color: filter === t ? 'var(--blue)' : 'var(--t2)', transition: 'all .15s', fontFamily: 'inherit' }}>{t}</button>
        ))}
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: '240px 1fr', gap: 10, minHeight: 500 }}>
        <div style={{ overflowY: 'auto' }}>
          {filtered.map(p => {
            const idx = PROMPTS.indexOf(p);
            return (
              <div key={p.id} onClick={() => { setSel(idx); setPromptText(p.text); setOutput(''); }}
                style={{ background: sel === idx ? 'rgba(29,110,245,.06)' : '#fff', border: `1.5px solid ${sel === idx ? 'var(--blue)' : 'var(--border)'}`, borderRadius: 10, padding: 12, marginBottom: 8, cursor: 'pointer', transition: 'all .15s' }}>
                <div style={{ fontSize: 10, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.08em', color: p.typeColor, marginBottom: 5 }}>● {p.type}</div>
                <div style={{ fontSize: 13, fontWeight: 600, marginBottom: 4 }}>{p.name}</div>
                <div style={{ fontSize: 10, color: 'var(--t3)', lineHeight: 1.5, marginBottom: 8 }}>{p.id === 'P-07' ? 'Write your own custom prompt' : 'Analyze video for ' + p.name.toLowerCase()}</div>
                <div style={{ display: 'flex', gap: 5 }}><Badge color="blue" style={{ fontSize: 8 }}>Active</Badge><Badge color="gray" style={{ fontSize: 8 }}>📌</Badge></div>
              </div>
            );
          })}
        </div>
        <Panel style={{ overflow: 'hidden' }}>
          <PanelHead title={`Prompt Editor — ${PROMPTS[sel].name}`} icon="✦" right={<><Badge color="blue">{PROMPTS[sel].type}</Badge><Btn variant="ghost" size="sm" onClick={() => toast('Pinned!', '📌')}>📌 Pin</Btn></>} />
          <div style={{ overflowY: 'auto', flex: 1, padding: 14 }}>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 12 }}>
              <FormGroup label="Prompt Name"><FormInput value={PROMPTS[sel].name} /></FormGroup>
              <FormGroup label="Category"><select style={{ background: 'var(--surface2)', border: '1px solid var(--border2)', borderRadius: 6, padding: '7px 10px', fontSize: 12, outline: 'none', width: '100%' }}>{tags.filter(t => t !== 'all').map(t => <option key={t}>{t}</option>)}</select></FormGroup>
            </div>
            <FormGroup label="Active for Process"><FormInput value="All Processes" /></FormGroup>
            <div style={{ marginTop: 10, marginBottom: 5, fontSize: 10, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.07em', color: 'var(--t3)' }}>Prompt Text</div>
            <textarea value={promptText} onChange={e => setPromptText(e.target.value)} style={{ width: '100%', background: 'var(--surface2)', border: '1px solid var(--border2)', borderRadius: 6, padding: '10px 12px', fontSize: 11, color: 'var(--t1)', resize: 'vertical', minHeight: 140, outline: 'none', lineHeight: 1.8, fontFamily: "'IBM Plex Mono',monospace" }} />
            <div style={{ display: 'flex', gap: 6, marginTop: 8, marginBottom: 14, flexWrap: 'wrap' }}>
              <Btn variant="primary" onClick={runTest} disabled={testing}>{testing ? '⟳ Running…' : '▶ Test Run'}</Btn>
              <Btn variant="teal" onClick={() => toast('Saved!', '✓')}>Save Changes</Btn>
              <Btn variant="ghost" onClick={() => toast('Saved as new!', '✦')}>Save as New</Btn>
              <Btn variant="danger" size="sm" onClick={() => toast('Deleted', '✕', 'var(--red)')}>Delete</Btn>
            </div>
            <Divider />
            <div style={{ fontSize: 11, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.07em', color: 'var(--t2)', marginBottom: 8 }}>Test Output Preview</div>
            <div style={{ background: 'var(--surface2)', border: '1px solid var(--border)', borderRadius: 6, padding: 12, minHeight: 80, fontSize: 11, lineHeight: 1.8 }}>
              {testing && <div style={{ color: 'var(--blue)', display: 'flex', alignItems: 'center', gap: 8 }}><span>⟳</span> VLM processing video…</div>}
              {!testing && !output && <span style={{ color: 'var(--t3)', fontStyle: 'italic' }}>Press "▶ Test Run" to see VLM output with this prompt…</span>}
              {!testing && output && <div><div style={{ fontSize: 10, fontWeight: 700, color: 'var(--blue)', marginBottom: 6 }}>✦ VLM Output</div>{output.split('\n').map((l, i) => <div key={i} style={{ marginBottom: 2 }}>{l || '\u00A0'}</div>)}</div>}
            </div>
            <Divider />
            <div style={{ fontSize: 11, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.07em', color: 'var(--t2)', marginBottom: 10 }}>Usage Stats</div>
            {[{label:'Usage this month',val:'247 times',pct:82,color:'var(--blue)'},{label:'Avg. accuracy',val:'94%',pct:94,color:'var(--green)'},{label:'False positive rate',val:'6%',pct:6,color:'var(--amber)'}].map(s => (
              <div key={s.label} style={{ marginBottom: 10 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4, fontSize: 11 }}><span style={{ color: 'var(--t2)' }}>{s.label}</span><span style={{ fontWeight: 600, color: s.color }}>{s.val}</span></div>
                <div style={{ height: 5, background: '#dce6f8', borderRadius: 3, overflow: 'hidden' }}><div style={{ height: '100%', width: `${s.pct}%`, background: s.color, borderRadius: 3 }} /></div>
              </div>
            ))}
          </div>
        </Panel>
      </div>
      <Modal show={showNew} onClose={() => setShowNew(false)} title="+ New Prompt Template" footer={<><Btn variant="ghost" onClick={() => setShowNew(false)}>Cancel</Btn><Btn variant="primary" onClick={() => { toast('Prompt saved!', '✓'); setShowNew(false); }}>Save to Library</Btn></>}>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 10 }}>
          <FormGroup label="Prompt Name"><FormInput placeholder="My Custom Prompt" /></FormGroup>
          <FormGroup label="Category"><select style={{ background: 'var(--surface2)', border: '1px solid var(--border2)', borderRadius: 6, padding: '7px 10px', fontSize: 12, outline: 'none', width: '100%' }}>{tags.filter(t => t !== 'all').map(t => <option key={t}>{t}</option>)}</select></FormGroup>
        </div>
        <FormGroup label="Prompt Text"><textarea placeholder="Write your VLM prompt here…" style={{ width: '100%', background: 'var(--surface2)', border: '1px solid var(--border2)', borderRadius: 6, padding: '9px 10px', fontSize: 11, minHeight: 140, outline: 'none', lineHeight: 1.7, resize: 'vertical', fontFamily: 'inherit' }} /></FormGroup>
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
  const [tab, setTab] = useState('action');
  const [rules, setRules] = useState(RULES);
  const [showModal, setShowModal] = useState(false);
  const tabs = [
    { key: 'action', label: 'Unsafe Actions', n: RULES.action.length },
    { key: 'condition', label: 'Unsafe Conditions', n: RULES.condition.length },
    { key: 'nearmiss', label: 'Near-Miss', n: RULES.nearmiss.length },
    { key: 'pending', label: 'Pending', n: RULES.pending.length },
  ];
  const sevColors = { critical: 'var(--red)', high: 'var(--amber)', medium: 'var(--blue)', low: 'var(--gray)' };
  return (
    <div style={{ flex: 1, overflowY: 'auto', padding: 16 }}>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4,1fr)', gap: 8, marginBottom: 16 }}>
        <KPICard value="38" label="Total Rules" color="blue" /><KPICard value="25" label="Manual" color="green" />
        <KPICard value="13" label="AI-Generated" color="amber" /><KPICard value="3" label="Pending Approval" color="red" />
      </div>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
        <div style={{ fontSize: 11, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.08em', color: 'var(--t2)', display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ display: 'inline-block', width: 12, height: 2, background: 'var(--blue)' }} />Safety Rule Management
        </div>
        <div style={{ display: 'flex', gap: 6 }}><Btn variant="teal" onClick={() => setShowModal(true)}>✦ AI Generate</Btn><Btn variant="ghost">+ Manual Add</Btn></div>
      </div>
      <div style={{ display: 'flex', gap: 5, marginBottom: 14, borderBottom: '1px solid var(--border)', paddingBottom: 0 }}>
        {tabs.map(t => (
          <button key={t.key} onClick={() => setTab(t.key)} style={{ padding: '7px 14px', border: 'none', background: 'transparent', cursor: 'pointer', fontSize: 12, fontWeight: tab === t.key ? 700 : 400, color: tab === t.key ? 'var(--blue)' : 'var(--t2)', fontFamily: 'inherit', borderBottom: `2px solid ${tab === t.key ? 'var(--blue)' : 'transparent'}`, transition: 'all .15s' }}>
            {t.label} ({t.n})
          </button>
        ))}
      </div>
      <div>
        {(rules[tab] || []).map((r, i) => (
          <div key={r.id} style={{ display: 'flex', alignItems: 'flex-start', gap: 10, padding: '10px 14px', background: '#fff', border: '1px solid var(--border)', borderRadius: 8, marginBottom: 7 }}>
            <div style={{ width: 28, height: 28, borderRadius: 6, flexShrink: 0, background: `${sevColors[r.sev]}15`, border: `1px solid ${sevColors[r.sev]}30`, display: 'flex', alignItems: 'center', justifyContent: 'center', color: sevColors[r.sev], fontSize: 13 }}>⚑</div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 12, lineHeight: 1.6, marginBottom: 5 }}>{r.text}</div>
              <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap', fontSize: 10, color: 'var(--t3)' }}>
                <span style={{ fontWeight: 700, color: sevColors[r.sev], textTransform: 'uppercase' }}>{r.sev}</span>
                <span>{r.id}</span><span>{r.process}</span>
                <span style={{ color: r.source === 'AI-Generated' ? 'var(--blue)' : 'var(--t3)' }}>{r.source}</span>
              </div>
            </div>
            <div style={{ display: 'flex', gap: 5, flexShrink: 0, marginTop: 2 }}>
              {tab === 'pending' && <Btn variant="teal" size="sm" onClick={() => { setRules(prev => ({ ...prev, pending: prev.pending.filter((_, j) => j !== i), action: [...prev.action, r] })); toast('Rule approved!', '✓'); }}>Approve</Btn>}
              <Btn variant="ghost" size="sm">Edit</Btn>
              <Btn variant="danger" size="sm" onClick={() => { setRules(prev => ({ ...prev, [tab]: prev[tab].filter((_, j) => j !== i) })); toast('Deleted', '✕', 'var(--red)'); }}>✕</Btn>
            </div>
          </div>
        ))}
        {(rules[tab] || []).length === 0 && (
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', padding: 40, color: 'var(--t3)', gap: 8 }}>
            <span style={{ fontSize: 32, opacity: .3 }}>⚑</span><span style={{ fontSize: 12 }}>No rules in this category</span>
          </div>
        )}
      </div>
      <Modal show={showModal} onClose={() => setShowModal(false)} title="✦ AI Generate Safety Rule"
        footer={<><Btn variant="ghost" onClick={() => setShowModal(false)}>Cancel</Btn><Btn variant="primary" onClick={() => { toast('Rules published!', '⬆'); setShowModal(false); }}>Publish</Btn></>}>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 12 }}>
          <FormGroup label="Camera"><select style={{ width: '100%', background: 'var(--surface2)', border: '1px solid var(--border2)', borderRadius: 6, padding: '7px 10px', fontSize: 12, outline: 'none' }}><option>CAM-A01</option></select></FormGroup>
          <FormGroup label="Time Range"><FormInput value="14:20:00 — 14:25:00" /></FormGroup>
        </div>
        <div style={{ background: 'rgba(29,110,245,.06)', border: '1px solid rgba(29,110,245,.18)', borderRadius: 8, padding: 14, fontSize: 12, lineHeight: 1.8 }}>
          <div style={{ fontWeight: 700, color: 'var(--blue)', marginBottom: 8 }}>✦ AI Generated Output</div>
          <b style={{ color: 'var(--red)' }}>Unsafe Actions:</b><br />• Operator must not enter press zone while machine cycle is active<br />• Machine guard must be confirmed before approaching<br /><br />
          <b style={{ color: 'var(--amber)' }}>Preventive Rules:</b><br />• Dual-lock mechanism required at all press stations<br />• Proximity sensor within 1.5m of press zone
        </div>
      </Modal>
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
const API = 'http://localhost:8000';
const STATUS_COLOR = { SAFE: 'green', WARNING: 'amber', DANGER: 'red' };
const STATUS_ICON  = { SAFE: '✓', WARNING: '⚠', DANGER: '✕' };

function AnalyzePage({ toast }) {
  const [camId, setCamId]     = useState(CAMERAS[0]?.id || '');
  const [interval, setInt]    = useState(3);
  const [file, setFile]       = useState(null);
  const [dragOver, setDragOver] = useState(false);
  const [job, setJob]         = useState(null);   // { job_id, status, ... }
  const [polling, setPolling] = useState(false);
  const [jobs, setJobs]       = useState([]);
  const fileRef = useRef();

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
          if (data.status === 'done' || data.status === 'failed') {
            setPolling(false);
            toast(data.status === 'done' ? 'Analysis complete!' : `Failed: ${data.error}`, data.status === 'done' ? 'green' : 'red');
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

  const statusColor = s => s === 'done' ? 'green' : s === 'failed' ? 'red' : s === 'running' ? 'blue' : 'gray';

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
    if (page === 'cameras')   return <CameraList onOpenCamera={openCamera} />;
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
