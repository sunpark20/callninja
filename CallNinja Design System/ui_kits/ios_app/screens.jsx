// CallNinja screens — SlotRow, MainScreen, NumberInputSheet, OnboardingCountry, OnboardingExtensions

function SlotRow({ slot, dark, onTap, onToggle }) {
  const t = theme(dark);
  const statusIcon = () => {
    if (slot.reloading) return <div className="cn-spinner" style={{ width:18, height:18, border:`2px solid ${t.fg3}`, borderTopColor: t.accent, borderRadius:'50%', animation:'cnspin 0.8s linear infinite' }}/>;
    if (slot.error === 'disabled') return Icon.triangle(t.warning);
    if (slot.error) return Icon.xCircle(t.danger);
    if (slot.empty) return Icon.plusCircle(t.fg2);
    if (slot.enabled) return Icon.shieldCheck(t.success);
    return Icon.shieldOff(t.fg2);
  };
  const caption = () => {
    if (slot.reloading) return <span style={{ color: CN.orange }}>등록 중...</span>;
    if (slot.error === 'disabled') return <span style={{ color: CN.orange }}>설정에서 켜주세요</span>;
    if (slot.error === 'failed') return <span style={{ color: CN.red }}>DB 충돌. 기기를 재시작해 보세요.</span>;
    if (slot.enabled) return <span style={{ color: t.success }}>100만개 차단 중</span>;
    return <span style={{ color: t.fg2 }}>차단 중지됨</span>;
  };
  return (
    <CNRow dark={dark} onClick={onTap}>
      <div style={{ width: 28, display:'flex', alignItems:'center', justifyContent:'center' }}>{statusIcon()}</div>
      {slot.empty ? (
        <div style={{ color: t.fg2, flex:1 }}>차단할 번호를 입력하세요</div>
      ) : (
        <div style={{ flex:1, display:'flex', flexDirection:'column', gap:2 }}>
          <div style={{ fontFamily:'var(--font-mono)', fontSize:17, color:t.fg, letterSpacing:0.2 }}>{slot.pattern}</div>
          <div style={{ fontSize:12 }}>{caption()}</div>
        </div>
      )}
      {!slot.empty && <CNToggle on={slot.enabled} dark={dark} disabled={slot.reloading} onChange={onToggle}/>}
    </CNRow>
  );
}

function MainScreen({ state, setState, dark }) {
  const t = theme(dark);
  const enabledExt = state.extensionsEnabled;
  const totalExt = 10;
  const [sheet, setSheet] = React.useState(null); // {type:'input'|'detail', idx}
  const selected = sheet ? state.slots[sheet.idx] : null;

  const openInput = (idx) => setSheet({ type: 'input', idx });
  const openDetail = (idx) => setSheet({ type: 'detail', idx });

  const setSlot = (idx, patch) => {
    const slots = state.slots.slice();
    slots[idx] = { ...slots[idx], ...patch };
    setState({ ...state, slots });
  };

  return (
    <div style={{ height:'100%', display:'flex', flexDirection:'column', background:t.bg, paddingTop: 60 }}>
      {/* Nav bar */}
      <div style={{ padding:'0 16px', paddingTop: 4, display:'flex', alignItems:'center', justifyContent:'space-between' }}>
        <div style={{ fontSize:34, fontWeight:700, color:t.fg, letterSpacing:0.37 }}>콜닌자</div>
        <div style={{ color: t.accent, padding: 8, cursor:'pointer' }}>{Icon.gear(t.accent)}</div>
      </div>

      <div style={{ flex:1, overflow:'auto', paddingTop: 12, paddingBottom: 40 }}>
        {/* Status section */}
        <CNList dark={dark}>
          <CNRow dark={dark}>
            <div style={{ flex:1 }}>🇰🇷 대한민국</div>
            <div style={{ color: enabledExt < totalExt ? CN.orange : CN.green, fontVariantNumeric:'tabular-nums' }}>
              {enabledExt}/{totalExt} 활성화
            </div>
          </CNRow>
        </CNList>

        {/* Slots */}
        <CNList header="차단 슬롯" dark={dark}>
          {state.slots.map((s, i) => (
            <SlotRow key={i} slot={s} dark={dark}
              onTap={() => s.empty ? openInput(i) : openDetail(i)}
              onToggle={() => setSlot(i, { enabled: !s.enabled })}/>
          ))}
        </CNList>

        <div style={{ padding:'0 32px', fontSize:13, color:t.fg2, marginTop:-12 }}>
          연락처에 저장된 번호는 차단되지 않습니다.
        </div>
      </div>

      {sheet?.type === 'input' && (
        <NumberInputSheet dark={dark}
          existing={state.slots.map(s => s.prefix)}
          currentIndex={sheet.idx}
          onCancel={() => setSheet(null)}
          onConfirm={(result, input) => {
            setSlot(sheet.idx, { empty:false, pattern:result.pattern, prefix:result.prefix, input, enabled:true, reloading:true });
            setSheet(null);
            setTimeout(() => setSlot(sheet.idx, { reloading:false }), 900);
          }}/>
      )}

      {sheet?.type === 'detail' && selected && (
        <SlotDetailSheet dark={dark} slot={selected} idx={sheet.idx}
          onClose={() => setSheet(null)}
          onDelete={() => { setSlot(sheet.idx, { empty:true, pattern:null, prefix:null, input:null, enabled:false }); setSheet(null); }}
          onChange={() => setSheet({ type:'input', idx: sheet.idx })}/>
      )}
    </div>
  );
}

// NumberInput sheet — the HERO moment
function NumberInputSheet({ dark, existing, currentIndex, onCancel, onConfirm }) {
  const t = theme(dark);
  const [phone, setPhone] = React.useState('');
  const inputRef = React.useRef(null);
  React.useEffect(()=>{ inputRef.current?.focus(); },[]);

  // simple KR E.164 pattern computation matching the real converter
  const result = React.useMemo(() => {
    const digits = phone.replace(/\D/g,'');
    if (!digits) return null;
    if (digits.length < 9) return { err: `번호를 끝까지 입력해 주세요 (${digits.length}자리 입력됨)` };
    if (digits.length > 11) return { err: `번호가 너무 깁니다 (최대 11자리)` };
    let local = digits.startsWith('0') ? digits.slice(1) : digits;
    const e164 = '82' + local;
    const prefix = Math.floor(Number(e164) / 1_000_000);
    if (existing.includes(prefix)) {
      const idx = existing.indexOf(prefix);
      if (idx !== currentIndex) return { err: `슬롯 ${idx+1}에 이미 같은 범위가 등록되어 있습니다` };
    }
    // format KR pattern with 6-digit wildcard
    const len = digits.length;
    const keep = len - 6;
    const pref = digits.slice(0, keep);
    const pattern = len === 11
      ? `${pref.slice(0,3)}-${pref.slice(3)}${'X'.repeat(6 - (5 - pref.length))}-XXXX`.replace(/XXXXXX-XXXX/,'XX-XXXX')
      : `${pref}${'X'.repeat(6)}`;
    // cleaner: pattern for 11 digits = XXX-XXYY-YYYY where YYs are wild
    const p11 = (() => {
      const d = digits + 'X'.repeat(Math.max(0, 11 - digits.length));
      const combined = d.slice(0, keep) + 'X'.repeat(6);
      return `${combined.slice(0,3)}-${combined.slice(3,7)}-${combined.slice(7,11)}`;
    })();
    return { pattern: p11, prefix, count: 1_000_000 };
  }, [phone, existing, currentIndex]);

  const ok = result && !result.err;
  return (
    <Sheet dark={dark} title="번호 입력" onCancel={onCancel}>
      <div style={{ padding:'28px 0', display:'flex', flexDirection:'column', gap:24, height:'100%', boxSizing:'border-box' }}>
        <div style={{ textAlign:'center', padding:'0 20px' }}>
          <div style={{ fontSize:17, fontWeight:600, color:t.fg, lineHeight:1.4 }}>
            스팸 전화에서 본 번호를<br/>그대로 입력하세요
          </div>
          <div style={{ fontSize:15, color:t.fg2, marginTop:8 }}>🇰🇷 대한민국 (+82)</div>
        </div>

        <div style={{ padding:'0 20px' }}>
          <input ref={inputRef} value={phone} onChange={e=>setPhone(e.target.value)}
            placeholder="전화번호 입력" type="tel"
            style={{
              width:'100%', boxSizing:'border-box', padding:'16px',
              background: t.input, border:0, borderRadius:12,
              textAlign:'center', fontFamily:'var(--font-mono)', fontSize:22, fontWeight:600, color:t.fg,
              outline:'none',
            }}/>
        </div>

        {/* Hero pattern preview */}
        {result && ok && (
          <div style={{ padding:'0 20px' }}>
            <div style={{
              background: t.successTint, borderRadius:12, padding:20, textAlign:'center',
              animation:'cnPop 0.28s cubic-bezier(0.2, 0.9, 0.4, 1.2)',
            }}>
              <div style={{ fontFamily:'var(--font-mono)', fontSize:28, fontWeight:700, color:t.success, letterSpacing:0.5 }}>
                {result.pattern}
              </div>
              <div style={{ fontSize:15, color:t.fg2, marginTop:6 }}>
                패턴 모두 차단 (1,000,000개)
              </div>
            </div>
          </div>
        )}
        {result?.err && (
          <div style={{ padding:'0 20px', color:CN.orange, fontSize:15, textAlign:'center' }}>{result.err}</div>
        )}

        <div style={{ flex:1 }}/>
        <div style={{ padding:'0 20px 24px' }}>
          <CNButton dark={dark} full disabled={!ok} onClick={() => ok && onConfirm({ pattern: result.pattern, prefix: result.prefix }, phone)}>확인</CNButton>
        </div>
      </div>
    </Sheet>
  );
}

function SlotDetailSheet({ dark, slot, idx, onClose, onDelete, onChange }) {
  const t = theme(dark);
  const start = String(slot.prefix) + '000000';
  const end = String(slot.prefix) + '999999';
  return (
    <Sheet dark={dark} title={`슬롯 ${idx+1}`} compact onCancel={onClose}>
      <div style={{ padding:'16px 0 24px', height:'100%', overflowY:'auto' }}>
        <CNList dark={dark}>
          <CNRow dark={dark}>
            <div style={{ fontFamily:'var(--font-mono)', fontSize:22, fontWeight:500 }}>{slot.pattern}</div>
          </CNRow>
        </CNList>
        <CNList header="차단 범위" dark={dark}>
          <CNRow dark={dark}>
            <div style={{ fontFamily:'var(--font-mono)', fontSize:12, color:t.fg2 }}>{start} ~ {end}</div>
          </CNRow>
          <CNRow dark={dark}>
            <div style={{ fontSize:17 }}>총 1,000,000개</div>
          </CNRow>
        </CNList>
        {slot.input && (
          <CNList header="원본 번호" dark={dark}>
            <CNRow dark={dark}><div>{slot.input}</div></CNRow>
          </CNList>
        )}
        <CNList dark={dark}>
          <CNRow dark={dark} onClick={onChange}><div style={{ color: t.accent }}>번호 변경</div></CNRow>
          <CNRow dark={dark} onClick={onDelete}><div style={{ color: t.danger }}>삭제</div></CNRow>
        </CNList>
      </div>
    </Sheet>
  );
}

// Sheet — iOS modal half-sheet appearance
function Sheet({ children, title, onCancel, dark, compact }) {
  const t = theme(dark);
  return (
    <div style={{ position:'absolute', inset:0, zIndex:10, pointerEvents:'auto' }}>
      <div style={{ position:'absolute', inset:0, background:'rgba(0,0,0,0.25)', animation:'cnFade 0.2s' }} onClick={onCancel}/>
      <div style={{
        position:'absolute', left:0, right:0, bottom:0, top: compact ? 120 : 80,
        background: t.bg, borderTopLeftRadius:14, borderTopRightRadius:14,
        display:'flex', flexDirection:'column', animation:'cnSlide 0.28s cubic-bezier(0.2,0.9,0.3,1)',
        boxShadow:'0 -2px 40px rgba(0,0,0,0.2)',
      }}>
        <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between', padding:'14px 16px', borderBottom:`0.5px solid ${t.sep}` }}>
          <div style={{ color: t.accent, cursor:'pointer', fontSize:17 }} onClick={onCancel}>취소</div>
          <div style={{ fontSize:17, fontWeight:600, color:t.fg }}>{title}</div>
          <div style={{ width:30 }}/>
        </div>
        <div style={{ flex:1, overflowY:'auto' }}>{children}</div>
      </div>
    </div>
  );
}

// Onboarding — Country
function OnboardingCountry({ dark, country, onPick, onNext }) {
  const t = theme(dark);
  return (
    <div style={{ height:'100%', display:'flex', flexDirection:'column', background:t.bg, padding: '72px 16px 40px' }}>
      <div style={{ flex:1, display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', gap:24 }}>
        <div style={{ fontSize:22, fontWeight:700, color:t.fg }}>사용할 나라를 선택하세요</div>
        <div style={{ fontSize:17, color:t.fg2, textAlign:'center', lineHeight:1.4 }}>
          선택한 나라의 전화번호 형식에 맞게<br/>차단 범위가 자동 계산됩니다.
        </div>
        {country ? (
          <div onClick={onPick} style={{
            width:'100%', boxSizing:'border-box', padding:16, cursor:'pointer',
            background: dark ? 'rgba(255,255,255,0.08)' : 'rgba(255,255,255,0.7)',
            backdropFilter:'blur(20px)', WebkitBackdropFilter:'blur(20px)',
            borderRadius:12, display:'flex', alignItems:'center', gap:14,
            border: `0.5px solid ${t.sep}`,
          }}>
            <div style={{ fontSize:34 }}>{country.flag}</div>
            <div style={{ flex:1 }}>
              <div style={{ fontSize:17, fontWeight:600, color:t.fg }}>{country.name}</div>
              <div style={{ fontSize:15, color:t.fg2 }}>{country.dial}</div>
            </div>
            <div style={{ color:t.fg3 }}>{Icon.chevron(t.fg3)}</div>
          </div>
        ) : (
          <CNButton dark={dark} onClick={onPick}>나라 선택</CNButton>
        )}
      </div>
      {country && <CNButton dark={dark} full onClick={onNext}>다음</CNButton>}
    </div>
  );
}

// Onboarding — Extensions
function OnboardingExtensions({ dark, enabled, onTick, onDone }) {
  const t = theme(dark);
  const all = enabled >= 10;
  return (
    <div style={{ height:'100%', display:'flex', flexDirection:'column', background:t.bg, paddingTop: 60 }}>
      <div style={{ padding:'4px 16px 12px' }}></div>
      <div style={{ flex:1, overflowY:'auto', paddingBottom:40 }}>
        <CNList dark={dark}>
          <div style={{ padding:'16px', display:'flex', flexDirection:'column', gap:12 }}>
            <div style={{ fontSize:17, fontWeight:600, color:t.fg }}>설정에서 10개 항목을 켜주세요</div>
            <div style={{ fontSize:15, color:t.fg2 }}>설정 &gt; 앱 &gt; 전화 &gt; 차단 및 발신자 확인</div>
          </div>
          <div style={{ padding:'0 16px 16px' }}>
            <CNButton dark={dark} variant="tinted" onClick={onTick}>설정 열기 (+1 켬)</CNButton>
          </div>
          <div style={{ padding:'14px 16px', display:'flex', justifyContent:'center', alignItems:'center', gap:8 }}>
            <div style={{ fontSize:20, fontWeight:700, color:t.fg, fontVariantNumeric:'tabular-nums' }}>{enabled}/10 활성화</div>
            {all && <div>{Icon.checkCircle(t.success)}</div>}
          </div>
        </CNList>
        {all && (
          <CNList dark={dark}>
            <div style={{ padding:16 }}>
              <CNButton dark={dark} full onClick={onDone}>시작하기</CNButton>
            </div>
          </CNList>
        )}
      </div>
    </div>
  );
}

Object.assign(window, { SlotRow, MainScreen, NumberInputSheet, SlotDetailSheet, Sheet, OnboardingCountry, OnboardingExtensions });
