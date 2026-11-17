# Compact app tokens
Verified from main 2af2b3914c7aa20c28013e02613251d39e07e48a lib/widgets/sori/tokens.dart.
- primary: #1F7A6B
- primaryDark: #0E443B
- gold: #C99A2E
- goldOnLight: #7A5810
- lightBg: #FAF6EC
- lightSurface: #F1ECDC
- lightSurfaceRaised: #FFFDF8
- lightText: #1A1F1D
- lightTextMuted: #5C6660
- lightBorder: #DAD3BE
- lightBorderStrong: #978C73
- body: Noto Sans KR 16px, 1.45 line height; interface: Paperlogy when supplied, otherwise Korean system fallback.
- spacing: 4/8/12/16/24/32/48; 48px minimum controls.

# Existing review raw CSS
```css

:root{color-scheme:light;--ink:#29313a;--muted:#625d55;--paper:#eee9e1;--line:#cfc6b8;--wood:#82572e;--teal:#28685e}*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:15px/1.5 'Malgun Gothic','Segoe UI',sans-serif}header{padding:18px 28px;border-bottom:1px solid var(--line);display:flex;align-items:center;justify-content:space-between;gap:16px}h1{font-size:23px;margin:0;font-weight:700;letter-spacing:-.7px}header p{margin:3px 0 0;color:var(--muted);font-size:13px}.workspace{display:grid;grid-template-columns:200px minmax(0,1fr);max-width:1600px;margin:auto;min-height:calc(100vh - 100px)}nav{padding:16px 12px;border-right:1px solid var(--line)}button,a,input{font:inherit}button,.link{border:1px solid var(--line);background:#faf7f1;color:var(--ink);border-radius:6px;min-height:44px;padding:9px 14px;cursor:pointer;text-decoration:none}button:hover,.link:hover{background:#e5dac9}button:focus-visible,a:focus-visible,input:focus-visible{outline:3px solid var(--teal);outline-offset:3px}button[aria-pressed=true]{background:var(--ink);color:#fff;border-color:var(--ink)}button:disabled{opacity:.45;cursor:default}nav button{display:flex;align-items:center;justify-content:space-between;width:100%;margin-bottom:5px;text-align:left;border-color:transparent;background:transparent}nav small{opacity:.7;font-size:11px}main{padding:20px 24px}.toolbar,.actions,.stagebar{display:flex;align-items:center;gap:8px;flex-wrap:wrap}.toolbar{justify-content:space-between;margin-bottom:12px}.toolbar h2{margin:0;font-size:21px;letter-spacing:-.5px}.well{position:relative;border:1px solid var(--line);border-radius:9px;overflow:hidden;background:#ded8cf;min-height:280px;display:grid;place-items:center}.well img{display:block;width:100%;max-height:68vh;object-fit:contain;cursor:zoom-in}.well .empty{padding:100px 20px;color:var(--muted)}.stagebar{margin-top:14px}.stagebar input{flex:1;min-width:150px;accent-color:var(--wood);height:44px}.stagebar strong{min-width:90px}.note{margin:8px 0 0;font-size:13px;color:var(--muted)}.steps{display:flex;gap:6px;overflow:auto;padding:12px 2px}.steps button{min-width:44px;padding:8px}.steps button[aria-current=true]{border:2px solid var(--wood);background:#e3ceb0}.downloads{display:flex;gap:12px;flex-wrap:wrap;margin-top:12px;font-size:13px}.downloads a{color:var(--teal)}dialog{border:0;padding:0;background:#ded8cf;max-width:96vw;max-height:94vh}dialog img{display:block;max-width:94vw;max-height:86vh;object-fit:contain}dialog button{display:block;margin:8px auto}dialog::backdrop{background:#20262be0}@media(max-width:740px){header{padding:14px 16px}header p{max-width:300px}.workspace{display:block}nav{display:flex;overflow:auto;border-right:0;border-bottom:1px solid var(--line);padding:8px}nav button{width:auto;white-space:nowrap;gap:8px;margin:0}main{padding:14px 12px}.well img{max-height:60vh}.toolbar h2{font-size:18px}.status{display:none}}@media(prefers-reduced-motion:reduce){*{scroll-behavior:auto}}

```
