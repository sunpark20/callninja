// CallNinja UI kit — app primitives matching the real SwiftUI components.
// Uses SF-native metrics. Expects colors_and_type.css loaded on the page.

const CN = {
  pink: '#E4455E',
  pinkDark: '#EB6478',
  green: '#34C759',
  greenDark: '#30D158',
  orange: '#FF9F0A',
  red: '#FF3B30',
  blue: '#0A84FF',
};

const theme = (dark) => ({
  bg:       dark ? '#000000' : '#F2F2F7',
  surface:  dark ? '#1C1C1E' : '#FFFFFF',
  elev:     dark ? '#2C2C2E' : '#FFFFFF',
  input:    dark ? '#2C2C2E' : '#E5E5EA',
  fg:       dark ? '#FFFFFF' : '#000000',
  fg2:      dark ? 'rgba(235,235,245,0.60)' : 'rgba(60,60,67,0.60)',
  fg3:      dark ? 'rgba(235,235,245,0.30)' : 'rgba(60,60,67,0.30)',
  sep:      dark ? 'rgba(84,84,88,0.60)' : 'rgba(60,60,67,0.18)',
  accent:   dark ? CN.pinkDark : CN.pink,
  success:  dark ? CN.greenDark : CN.green,
  successTint: dark ? 'rgba(48,209,88,0.18)' : 'rgba(52,199,89,0.10)',
  warning:  CN.orange,
  danger:   CN.red,
  info:     CN.blue,
});

// Prominent button ("다음", "시작하기", "확인")
function CNButton({ children, onClick, disabled, variant = 'prominent', dark, full, size='large' }) {
  const t = theme(dark);
  const base = {
    border: 0, cursor: disabled ? 'not-allowed' : 'pointer',
    fontFamily: 'inherit', fontSize: size === 'large' ? 17 : 15, fontWeight: 600,
    padding: size === 'large' ? '0 20px' : '0 14px',
    height: size === 'large' ? 50 : 34,
    borderRadius: 12,
    width: full ? '100%' : undefined,
    display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
    transition: 'opacity 0.1s',
  };
  const variants = {
    prominent: { background: disabled ? t.fg3 : t.accent, color: disabled ? (dark?'rgba(255,255,255,0.3)':'rgba(60,60,67,0.4)') : '#fff' },
    tinted:    { background: dark ? 'rgba(235,100,120,0.22)' : 'rgba(228,69,94,0.15)', color: t.accent },
    plain:     { background: 'transparent', color: t.accent },
    destructive:{ background: 'transparent', color: t.danger },
  };
  return (
    <button onClick={disabled ? undefined : onClick} style={{ ...base, ...variants[variant] }}
      onMouseDown={e=>e.currentTarget.style.opacity=0.7}
      onMouseUp={e=>e.currentTarget.style.opacity=1}
      onMouseLeave={e=>e.currentTarget.style.opacity=1}>
      {children}
    </button>
  );
}

function CNToggle({ on, onChange, disabled, dark }) {
  const t = theme(dark);
  return (
    <div onClick={()=>!disabled && onChange?.(!on)}
      style={{
        width: 51, height: 31, borderRadius: 999,
        background: on ? t.success : (dark ? 'rgba(120,120,128,0.32)' : 'rgba(120,120,128,0.16)'),
        position: 'relative', cursor: disabled?'not-allowed':'pointer',
        transition: 'background 0.2s', opacity: disabled ? 0.5 : 1, flexShrink: 0,
      }}>
      <div style={{
        position: 'absolute', top: 2, left: on ? 22 : 2,
        width: 27, height: 27, borderRadius: '50%', background: '#fff',
        boxShadow: '0 3px 8px rgba(0,0,0,0.15), 0 2px 2px rgba(0,0,0,0.1)',
        transition: 'left 0.2s',
      }}/>
    </div>
  );
}

// Grouped List — mimics SwiftUI List(.insetGrouped)
function CNList({ header, footer, children, dark }) {
  const t = theme(dark);
  const kids = React.Children.toArray(children);
  return (
    <div style={{ marginBottom: 24 }}>
      {header && (
        <div style={{ padding: '0 32px 6px', fontSize: 13, color: t.fg2, textTransform: 'uppercase', letterSpacing: 0.2 }}>
          {header}
        </div>
      )}
      <div style={{ margin: '0 16px', background: t.surface, borderRadius: 10, overflow: 'hidden' }}>
        {kids.map((c, i) => (
          <React.Fragment key={i}>
            {c}
            {i < kids.length - 1 && <div style={{ height: 0.5, background: t.sep, marginLeft: 16 }}/>}
          </React.Fragment>
        ))}
      </div>
      {footer && (
        <div style={{ padding: '6px 32px 0', fontSize: 13, color: t.fg2 }}>
          {footer}
        </div>
      )}
    </div>
  );
}

function CNRow({ children, onClick, dark }) {
  const t = theme(dark);
  const [pressed, setPressed] = React.useState(false);
  return (
    <div onClick={onClick}
      onMouseDown={()=>setPressed(true)} onMouseUp={()=>setPressed(false)} onMouseLeave={()=>setPressed(false)}
      style={{
        padding: '11px 16px', minHeight: 44, display: 'flex', alignItems: 'center', gap: 10,
        background: pressed ? (dark?'#2C2C2E':'#E5E5EA') : 'transparent',
        cursor: onClick ? 'pointer' : 'default', color: t.fg, fontSize: 17,
      }}>
      {children}
    </div>
  );
}

// Lucide-style inline SVG icons (we keep them tiny and local so offline preview works)
const Icon = {
  shieldCheck: (c) => <svg width="22" height="22" viewBox="0 0 24 24" fill={c}><path d="M12 2l8 3v7c0 5-3.5 8.5-8 10-4.5-1.5-8-5-8-10V5l8-3z"/><path d="M8.5 12.5l2.5 2.5 4.5-5" stroke="#fff" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" fill="none"/></svg>,
  shieldOff: (c) => <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M12 2l8 3v7c0 5-3.5 8.5-8 10-4.5-1.5-8-5-8-10V5l8-3z"/><line x1="3" y1="3" x2="21" y2="21"/></svg>,
  plusCircle: (c) => <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.8"><circle cx="12" cy="12" r="9"/><line x1="12" y1="8" x2="12" y2="16"/><line x1="8" y1="12" x2="16" y2="12"/></svg>,
  triangle: (c) => <svg width="22" height="22" viewBox="0 0 24 24" fill={c}><path d="M12 3l10 18H2L12 3z"/><path d="M12 10v5M12 18v.5" stroke="#fff" strokeWidth="2" strokeLinecap="round"/></svg>,
  xCircle: (c) => <svg width="22" height="22" viewBox="0 0 24 24" fill={c}><circle cx="12" cy="12" r="10"/><path d="M8 8l8 8M16 8l-8 8" stroke="#fff" strokeWidth="2" strokeLinecap="round"/></svg>,
  checkCircle: (c) => <svg width="22" height="22" viewBox="0 0 24 24" fill={c}><circle cx="12" cy="12" r="10"/><path d="M8 12l3 3 5-6" stroke="#fff" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" fill="none"/></svg>,
  check: (c) => <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12"/></svg>,
  chevron: (c) => <svg width="10" height="16" viewBox="0 0 10 16" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="2 2 8 8 2 14"/></svg>,
  gear: (c) => <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 00.3 1.8l.1.1a2 2 0 11-2.8 2.8l-.1-.1a1.7 1.7 0 00-1.8-.3 1.7 1.7 0 00-1 1.5V21a2 2 0 11-4 0v-.1a1.7 1.7 0 00-1.1-1.5 1.7 1.7 0 00-1.8.3l-.1.1a2 2 0 11-2.8-2.8l.1-.1a1.7 1.7 0 00.3-1.8 1.7 1.7 0 00-1.5-1H3a2 2 0 110-4h.1a1.7 1.7 0 001.5-1.1 1.7 1.7 0 00-.3-1.8l-.1-.1a2 2 0 112.8-2.8l.1.1a1.7 1.7 0 001.8.3H9a1.7 1.7 0 001-1.5V3a2 2 0 114 0v.1a1.7 1.7 0 001 1.5 1.7 1.7 0 001.8-.3l.1-.1a2 2 0 112.8 2.8l-.1.1a1.7 1.7 0 00-.3 1.8V9a1.7 1.7 0 001.5 1H21a2 2 0 110 4h-.1a1.7 1.7 0 00-1.5 1z"/></svg>,
  search: (c) => <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="11" cy="11" r="7"/><line x1="21" y1="21" x2="16" y2="16"/></svg>,
};

Object.assign(window, { CN, theme, CNButton, CNToggle, CNList, CNRow, Icon });
