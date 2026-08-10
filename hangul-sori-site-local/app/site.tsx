import Link from "next/link";

type Locale = "de" | "en" | "ko";

const copy = {
  de: {
    nav: ["App ansehen", "Highlights", "Alle Funktionen"], support: "Support", eyebrow: "Dein Koreanisch. Dein Hanok.",
    title: <>Koreanisch lernen, das sich wie eine <em>eigene Welt</em> anfühlt.</>,
    lede: "Lerne Hangul, Wortschatz und Grammatik in deinem eigenen Hanok. Tiger und Elster begleiten dich vom ersten Buchstaben bis zum echten Gespräch.",
    beta: "Für den Testzugang vormerken", iosState: "iOS in Vorbereitung", androidState: "Android-Test läuft", badges: ["Zum Start kostenlos", "Keine Werbung", "Local-first", "Deutsch & English"],
    privacyTitle: "Local-first, transparent erklärt.", privacyText: "Lerninhalte und Fotos bleiben standardmäßig auf deinem Gerät. Online-Dienste werden nur für ausgewählte Funktionen genutzt.", privacyLink: "Datenverarbeitung verstehen",
    previewEyebrow: "Ein Blick in die App", previewTitle: "Nicht nur lernen. In einer Welt weiterkommen.", previewText: "Jeder Bereich hat eine klare Aufgabe. Kurze Lektionen bauen Wissen auf, Wiederholungen halten es fest und dein Hanok zeigt deinen Fortschritt.",
    featuresEyebrow: "Drei Gründe, weiterzulernen", featuresTitle: "Die besonderen Seiten von Hangul Sori.",
    journeyEyebrow: "Dein Lernrhythmus", journeyTitle: "Kleine Schritte, die sichtbar etwas aufbauen.",
    moreTitle: "Alles unter einem Dach", moreText: "Von den ersten Zeichen bis zur Lerngruppe. Öffne die Bereiche, die dich interessieren.",
    freeTitle: "Zum Start komplett kostenlos.", freeText: "Während der Testphase und zum ersten öffentlichen Release gibt es kein Abo und keinen In-App-Kauf. Falls sich das später ändert, wird es vorher klar angekündigt.",
    faqTitle: "Häufig gefragt", finalTitle: "Dein erster Buchstabe wartet schon.", finalText: "Starte mit Hangul und baue dir Schritt für Schritt deinen eigenen koreanischen Lernort.",
  },
  en: {
    nav: ["See the app", "Highlights", "All features"], support: "Support", eyebrow: "Your Korean. Your hanok.",
    title: <>Learn Korean in a world that feels <em>entirely your own.</em></>,
    lede: "Learn Hangul, vocabulary and grammar inside your own hanok. A tiger and magpie guide you from your first letter to a real conversation.",
    beta: "Join the testing list", iosState: "iOS in preparation", androidState: "Android testing", badges: ["Free at launch", "No ads", "Local-first", "German & English"],
    privacyTitle: "Local-first, explained clearly.", privacyText: "Learning content and photos stay on your device by default. Online services are used only for selected features.", privacyLink: "Understand data use",
    previewEyebrow: "Inside the app", previewTitle: "More than lessons. A world that grows with you.", previewText: "Every area has a clear role. Short lessons build knowledge, spaced review makes it stick, and your hanok makes progress visible.",
    featuresEyebrow: "Three reasons to return", featuresTitle: "What makes Hangul Sori different.",
    journeyEyebrow: "Your learning rhythm", journeyTitle: "Small steps that build something visible.",
    moreTitle: "Everything under one roof", moreText: "From your first letter to a study group. Open the areas you want to explore.",
    freeTitle: "Completely free at launch.", freeText: "There is no subscription or in-app purchase during testing or for the first public release. Any future change will be announced clearly in advance.",
    faqTitle: "Frequently asked", finalTitle: "Your first letter is waiting.", finalText: "Begin with Hangul and build your own place for learning Korean, one step at a time.",
  },
  ko: {
    nav: ["앱 미리보기", "핵심 기능", "전체 기능"], support: "고객지원", eyebrow: "나의 한국어. 나의 한옥.",
    title: <>나만의 세계 속에서 <em>한국어를 배워보세요.</em></>,
    lede: "나만의 한옥에서 한글, 어휘, 문법을 배워보세요. 호랑이와 까치가 첫 글자부터 실제 대화까지 함께합니다.",
    beta: "테스트 소식 받기", iosState: "iOS 출시 준비 중", androidState: "Android 테스트 중", badges: ["출시 초기 무료", "광고 없음", "로컬 우선", "독일어 & 영어 지원"],
    privacyTitle: "로컬 우선 원칙을 투명하게 설명합니다.", privacyText: "학습 콘텐츠와 사진은 기본적으로 기기에 저장됩니다. 온라인 서비스는 선택한 기능에만 사용됩니다.", privacyLink: "데이터 처리 방식 보기",
    previewEyebrow: "앱 미리보기", previewTitle: "공부만 하는 앱이 아니라, 함께 자라는 세계.", previewText: "짧은 레슨으로 배우고, 복습 일정으로 기억하고, 성장하는 한옥에서 나의 진도를 확인할 수 있어요.",
    featuresEyebrow: "계속 배우고 싶은 세 가지 이유", featuresTitle: "한글소리만의 특별한 학습 경험.",
    journeyEyebrow: "나만의 학습 리듬", journeyTitle: "작은 학습이 눈에 보이는 성장으로 이어집니다.",
    moreTitle: "한 지붕 아래 모든 기능", moreText: "첫 글자부터 학습 모임까지, 궁금한 영역을 열어보세요.",
    freeTitle: "첫 출시 버전은 완전히 무료예요.", freeText: "테스트 기간과 첫 공개 출시에서는 구독이나 인앱결제를 제공하지 않습니다. 나중에 변경되는 경우 미리 명확하게 안내합니다.",
    faqTitle: "자주 묻는 질문", finalTitle: "첫 글자가 기다리고 있어요.", finalText: "한글부터 시작해 나만의 한국어 학습 공간을 한 단계씩 만들어보세요.",
  },
};

const featureGroups = {
  de: [
    ["Hangul von Grund auf", "19 Konsonanten, 21 Vokale, Batchim, animierte Strichfolge und Nachzeichnen mit dem Finger."],
    ["Wortschatz A1 bis B2", "526 Wörter in 61 kleinen Packs, Aussprache, deutsche und englische Übersetzung sowie SM-2-Wiederholung."],
    ["Grammatik im Kontext", "88 Muster mit verständlichen Erklärungen, Audio und Beispielen aus echten Gesprächen."],
    ["Szenarien für den Alltag", "Café, Markt, Hotel, U-Bahn, Taxi und Apotheke mit Dialogen, Mini-Quests und Kulturnotizen."],
    ["Eigene Lernpakete", "Wörter selbst eingeben, Listen per CSV importieren, Fotos ergänzen und eigene Karten sowie Quiz erstellen."],
    ["Spiele und Hörtraining", "Anlaut-Quiz, Hangul Wordle, Wortkette, Lücken, Übersetzung und Hörmodus mit Tempo und Untertiteln."],
    ["Fortschritt und Belohnungen", "Streaks, Spezial-Quests, saisonale Belohnungen und ein Hanok, das mit deinem Lernen wächst."],
    ["Teilen und Gye", "Lernpakete teilen und ab 16 Jahren optional in geschützten Lerngruppen mit Stickern und Anfeuerungen lernen."],
  ],
  en: [
    ["Hangul from the ground up", "19 consonants, 21 vowels, batchim, animated stroke order and finger tracing."],
    ["Vocabulary from A1 to B2", "526 words in 61 small packs, pronunciation, German and English translations, plus SM-2 review."],
    ["Grammar in context", "88 patterns with clear explanations, audio and examples that sound like real conversation."],
    ["Everyday scenarios", "Cafés, markets, hotels, the subway, taxis and pharmacies with dialogue, mini quests and culture notes."],
    ["Your own learning packs", "Add words, import CSV lists, attach photos and turn your material into cards and quizzes."],
    ["Games and listening", "Initial sound quiz, Hangul Wordle, word chain, fill-in tasks, translation and listening modes."],
    ["Progress and rewards", "Streaks, special quests, seasonal rewards and a hanok that grows as you learn."],
    ["Sharing and Gye", "Share learning packs and, from age 16, optionally learn in protected groups with stickers and cheers."],
  ],
  ko: [
    ["기초부터 배우는 한글", "자음 19개, 모음 21개, 받침, 애니메이션 획순과 손가락 따라 쓰기를 제공합니다."],
    ["A1부터 B2 어휘", "526개 단어를 61개의 작은 팩으로 나누고 발음, 독일어·영어 번역, SM-2 복습을 제공합니다."],
    ["맥락으로 배우는 문법", "88개 문법 패턴을 실제 대화 예문, 오디오, 이해하기 쉬운 설명과 함께 배웁니다."],
    ["실생활 시나리오", "카페, 시장, 호텔, 지하철, 택시, 약국을 대화, 미니 퀘스트, 문화 노트로 연습합니다."],
    ["나만의 학습 팩", "단어를 직접 추가하고 CSV 목록과 사진을 넣어 나만의 카드와 퀴즈를 만들 수 있습니다."],
    ["게임과 듣기", "초성 퀴즈, 한글 Wordle, 끝말잇기, 빈칸, 번역, 속도와 자막을 조절하는 듣기 모드가 있습니다."],
    ["성장과 보상", "연속 학습, 특별 퀘스트, 계절 보상과 함께 학습할수록 한옥이 성장합니다."],
    ["공유와 계", "학습 팩을 공유하고 만 16세 이상은 스티커와 응원을 사용하는 선택형 학습 그룹에 참여할 수 있습니다."],
  ],
};

export function Header({ locale }: { locale: Locale }) {
  const c = copy[locale];
  return <header className="topbar">
    <Link className="brand" href={`/${locale}`} aria-label="Hangul Sori"><img src="/hangul-sori-logo.png" alt=""/><span><b>한글소리</b><small>Hangul Sori</small></span></Link>
    <nav aria-label="Navigation"><Link href={`/${locale}#preview`}>{c.nav[0]}</Link><Link href={`/${locale}#highlights`}>{c.nav[1]}</Link><Link href={`/${locale}#all-features`}>{c.nav[2]}</Link><Link href="/support">{c.support}</Link></nav>
    <div className="language" aria-label="Language"><Link className={locale === "de" ? "active" : ""} aria-current={locale === "de" ? "page" : undefined} href="/de">DE</Link><Link className={locale === "en" ? "active" : ""} aria-current={locale === "en" ? "page" : undefined} href="/en">EN</Link><Link className={locale === "ko" ? "active" : ""} aria-current={locale === "ko" ? "page" : undefined} href="/ko">한국어</Link></div>
  </header>;
}

function StoreButtons({ locale, compact = false }: { locale: Locale; compact?: boolean }) {
  const c = copy[locale];
  return <div className={`store-row ${compact ? "compact" : ""}`} aria-label="App availability">
    <button className="store-button" disabled><span></span><span><small>{c.iosState}</small>App Store</span></button>
    <button className="store-button" disabled><span className="play">▶</span><span><small>{c.androidState}</small>Google Play</span></button>
  </div>;
}

function PhoneHero() {
  return <div className="hero-visual" id="preview" aria-label="Hangul Sori app preview">
    <div className="sun"/><div className="phone phone-main"><div className="phone-screen hanok-screen"><div className="status"><span>9:41</span><span>● ● ●</span></div><p className="screen-kicker">좋은 아침이에요, Sujin!</p><div className="streak">🔥 12 Tage</div><h2>Dein Hanok</h2><div className="hanok-art"><img src="/hanok-gate.png" alt="Hanok courtyard with a tiger and magpies"/></div><div className="progress-card"><span>Heute</span><b>3 von 5 Lektionen</b><div><i/></div></div><div className="bottom-nav"><b>⌂</b><span>가</span><span>▤</span><span>♙</span></div></div></div>
    <div className="phone phone-side"><div className="phone-screen lesson-screen"><div className="status"><span>9:41</span><span>● ● ●</span></div><p className="screen-kicker">한글 쓰기</p><h2>오늘의 글자</h2><div className="letter-card"><small>따라 써 보세요</small><strong>ㅎ</strong><span>hieut</span></div><button>연습 시작</button></div></div>
    <img className="mascots" src="https://www.hangul-sori.com/assets/welcome-hero.png" alt="Hangul Sori tiger and magpie"/><span className="petal p1"/><span className="petal p2"/><span className="petal p3"/>
  </div>;
}

const previews: Record<Locale, string[][]> = {
  de: [
    ["한옥", "Dein Hanok", "Fortschritt, den du wachsen siehst"], ["가", "Hangul schreiben", "Strich für Strich sicher lesen"],
    ["오늘", "SRS-Wortkarten", "Wiederholen, bevor du vergisst"], ["대화", "Echte Gespräche", "Café, U-Bahn, Hotel und mehr"],
    ["책", "책 한 컷", "Vom Buchtext zum Lernpaket"], ["ㅂ_ㅂ_", "Mini-Games", "Kurze Übungen mit direktem Feedback"],
  ],
  en: [
    ["한옥", "Your hanok", "Progress you can watch grow"], ["가", "Write Hangul", "Read confidently, stroke by stroke"],
    ["오늘", "SRS vocabulary", "Review before you forget"], ["대화", "Real conversations", "Cafés, subways, hotels and more"],
    ["책", "One page, one pack", "Turn textbook text into practice"], ["ㅂ_ㅂ_", "Mini-games", "Short exercises with instant feedback"],
  ],
  ko: [
    ["한옥", "나의 한옥", "눈으로 확인하는 학습 성장"], ["가", "한글 쓰기", "획순부터 차근차근 익히기"],
    ["오늘", "SRS 단어 카드", "잊기 전에 알맞게 복습하기"], ["대화", "실생활 대화", "카페, 지하철, 호텔 등 실제 상황"],
    ["책", "책 한 컷", "교재의 문장을 나만의 학습 팩으로"], ["ㅂ_ㅂ_", "미니게임", "짧은 연습과 즉각적인 피드백"],
  ],
};

export function Footer({ locale }: { locale: Locale }) {
  return <footer><div className="footer-brand"><img src="/hangul-sori-logo.png" alt=""/><div><b>한글소리</b><span>Learn Korean like learning a song.</span></div></div><div className="footer-links"><Link href="/features">Features</Link><Link href="/support">Support</Link><Link href={locale === "de" ? "/privacy" : `/privacy?lang=${locale}`}>Privacy</Link><Link href="/terms">Terms</Link><Link href="/account-deletion">Account deletion</Link><Link href="/impressum">Impressum</Link><Link href="/press">Press</Link></div><p>© 2026 Sujin Arin DataWorld · Frankfurt am Main</p><Link className="locale-back" href={`/${locale}`}>↑ Top</Link></footer>;
}

export function Landing({ locale }: { locale: Locale }) {
  const c = copy[locale];
  const localePreviews = previews[locale];
  const highlights = locale === "de" ? [
    ["Dein Hanok wächst mit dir", "Lektionen, Wiederholungen und Quests bauen deinen Hof vom Grundstein bis zum Jongga-Anwesen aus.", "01"],
    ["Lehrbuch fotografieren, Lernpaket erstellen", "Das Foto und die Texterkennung bleiben lokal. Nur wenn du Analyse oder Übersetzung wählst, kann der extrahierte Text online verarbeitet werden.", "02"],
    ["Hangul, Wortschatz und echte Gespräche", "Ein zusammenhängender Lernweg mit Schreiben, SRS, Grammatik, Audio, Spielen und alltagstauglichen Dialogen.", "03"],
  ] : locale === "en" ? [
    ["Your hanok grows with you", "Lessons, reviews and quests build your courtyard from the first foundation to a complete jongga estate.", "01"],
    ["Photograph a page, create a learning pack", "The photo and text recognition stay local. Extracted text may be processed online only when you choose analysis or translation.", "02"],
    ["Hangul, vocabulary and real conversation", "One connected path with writing, SRS, grammar, audio, games and dialogue for everyday situations.", "03"],
  ] : [
    ["나와 함께 성장하는 한옥", "레슨, 복습, 퀘스트를 완료하면 빈 마당이 종가 한옥으로 한 단계씩 성장합니다.", "01"],
    ["교재를 찍고 학습 팩 만들기", "사진과 글자 인식은 기기에서 처리됩니다. 분석이나 번역을 선택할 때만 추출된 텍스트가 온라인에서 처리될 수 있습니다.", "02"],
    ["한글, 어휘, 실제 대화까지", "쓰기, SRS, 문법, 오디오, 게임, 실생활 대화가 하나의 학습 경로로 연결됩니다.", "03"],
  ];
  const steps = locale === "de" ? ["Lernmodus wählen", "Kurz lernen und spielen", "Zum richtigen Zeitpunkt wiederholen", "Den Hanok wachsen sehen"] : locale === "en" ? ["Choose a learning mode", "Learn and play in short sessions", "Review at the right time", "Watch your hanok grow"] : ["학습 모드 선택", "짧게 배우고 게임하기", "복습 일정에 맞춰 기억하기", "성장하는 한옥 확인"];
  const faqs = locale === "de" ? [
    ["Funktioniert die App offline?", "Kernlektionen und lokales Lernen sind offline nutzbar. Die App verbindet sich beim Start mit Firebase. Analyse, Übersetzung, dynamische Aussprache, optionale Synchronisierung und Community-Funktionen benötigen eine Verbindung."],
    ["Werden meine Buchfotos hochgeladen?", "Nein. Auswahl, Zuschnitt und OCR laufen auf dem Gerät. Wenn du Analyse oder Übersetzung anforderst, kann nur der extrahierte und gegebenenfalls korrigierte Text per HTTPS übertragen werden."],
    ["Brauche ich ein Konto?", "Beim Start wird eine anonyme Firebase-Identität erstellt. Ein Google- oder Apple-Konto musst du nur verknüpfen, wenn du angebotene Backup- und Sync-Funktionen nutzen möchtest."],
    ["Gibt es Werbung oder Tracking?", "Die App enthält kein aktives Werbe-SDK und nutzt keine Werbe-ID für appübergreifendes Tracking. Analytics und Crashlytics sind getrennte, freiwillige Opt-ins und standardmäßig aus."],
  ] : locale === "en" ? [
    ["Does the app work offline?", "Core lessons and local learning work offline. The app connects to Firebase at startup. Analysis, translation, dynamic pronunciation, optional sync and community features require a connection."],
    ["Are my book photos uploaded?", "No. Selection, cropping and OCR happen on the device. When you request analysis or translation, only extracted and possibly corrected text may be sent over HTTPS."],
    ["Do I need an account?", "An anonymous Firebase identity is created at startup. You only need to link Google or Apple when you want offered backup and sync features."],
    ["Does the app use ads or tracking?", "There is no active advertising SDK and no advertising ID is used for cross-app tracking. Analytics and Crashlytics are separate voluntary opt-ins and off by default."],
  ] : [
    ["오프라인에서도 사용할 수 있나요?", "핵심 레슨과 로컬 학습은 오프라인에서 사용할 수 있습니다. 앱 시작 시 Firebase에 연결하며 분석, 번역, 동적 발음, 선택형 동기화, 커뮤니티 기능은 인터넷 연결이 필요합니다."],
    ["교재 사진이 서버로 전송되나요?", "아니요. 사진 선택, 자르기, OCR은 기기에서 처리됩니다. 분석이나 번역을 요청하면 추출하고 수정한 텍스트만 HTTPS로 전송될 수 있습니다."],
    ["계정이 꼭 필요한가요?", "앱 시작 시 익명 Firebase 식별자가 생성됩니다. 제공되는 백업과 동기화를 사용하려는 경우에만 Google 또는 Apple 계정을 연결하면 됩니다."],
    ["광고나 추적 기능이 있나요?", "활성 광고 SDK가 없으며 앱 간 추적을 위한 광고 ID를 사용하지 않습니다. Analytics와 Crashlytics는 별도 선택 동의 항목이며 기본적으로 꺼져 있습니다."],
  ];
  const launchItems = locale === "de" ? ["Kein Abo", "Keine In-App-Käufe", "Keine Werbung", "Alle im Release freigeschalteten Funktionen ohne Bezahlung"] : locale === "en" ? ["No subscription", "No in-app purchases", "No advertising", "Every feature included in the release is available without payment"] : ["구독 없음", "인앱결제 없음", "광고 없음", "출시 버전에 포함된 모든 기능을 결제 없이 이용"];
  const featureEyebrow = locale === "ko" ? "A1부터 B2까지" : locale === "en" ? "Features from A1 to B2" : "Features von A1 bis B2";
  const freeEyebrow = locale === "ko" ? "첫 출시 버전 무료" : locale === "en" ? "Free at launch" : "Zum Start kostenlos";
  return <main lang={locale}><Header locale={locale}/>
    <section className="hero"><div className="hero-copy"><p className="eyebrow">{c.eyebrow}</p><h1>{c.title}</h1><p className="lede">{c.lede}</p><StoreButtons locale={locale}/><a className="beta-link" href="mailto:hello@hangul-sori.com?subject=Hangul%20Sori%20Beta">{c.beta} <span>→</span></a><ul className="trust-row">{c.badges.map(x=><li key={x}><i>✓</i> {x}</li>)}</ul></div><PhoneHero/></section>
    <section className="privacy-strip"><div><span className="shield">◈</span><p><b>{c.privacyTitle}</b><br/>{c.privacyText}</p></div><Link href={locale === "de" ? "/privacy" : `/privacy?lang=${locale}`}>{c.privacyLink} <span>→</span></Link></section>

    <section className="section preview-section"><div className="section-heading"><div><p className="eyebrow">{c.previewEyebrow}</p><h2>{c.previewTitle}</h2></div><p>{c.previewText}</p></div><div className="preview-grid">{localePreviews.map((p,i)=><article className={`preview-card preview-${i+1}`} key={p[1]}><div className="mini-screen"><span>{p[0]}</span><i>{i === 0 ? "Level 7" : i === 2 ? (locale === "de" ? "Heute 8" : locale === "en" ? "Due 8" : "오늘 8") : "한글소리"}</i></div><h3>{p[1]}</h3><p>{p[2]}</p></article>)}</div><p className="preview-note">{locale === "ko" ? "실제 출시 빌드의 최종 스크린샷으로 교체될 앱 화면 구성입니다." : locale === "en" ? "Screen compositions ready to be replaced with final captures from the signed release build." : "Bildkompositionen, die vor dem Launch durch finale Aufnahmen des signierten Builds ersetzt werden."}</p></section>

    <section className="section highlights" id="highlights"><div className="section-heading"><div><p className="eyebrow">{c.featuresEyebrow}</p><h2>{c.featuresTitle}</h2></div></div><div className="highlight-stack">{highlights.map((h,i)=><article key={h[2]}><span>{h[2]}</span><div><h3>{h[0]}</h3><p>{h[1]}</p></div><div className={`feature-art art-${i+1}`}>{i === 0 ? <><video autoPlay muted loop playsInline preload="metadata" poster="/intro-gate-poster.jpg" aria-hidden="true"><source src="/intro-gate-to-madang.mp4" type="video/mp4"/></video><img className="motion-fallback" src="/intro-gate-poster.jpg" alt=""/></> : <b>{i===1?"책 한 컷":"가 · 말"}</b>}</div></article>)}</div></section>

    <section className="journey"><div className="section"><p className="eyebrow">{c.journeyEyebrow}</p><h2>{c.journeyTitle}</h2><ol>{steps.map((s,i)=><li key={s}><span>{String(i+1).padStart(2,"0")}</span><b>{s}</b></li>)}</ol></div></section>

    <section className="section all-features" id="all-features"><div className="section-heading"><div><p className="eyebrow">{featureEyebrow}</p><h2>{c.moreTitle}</h2></div><p>{c.moreText}</p></div><div className="accordion-grid">{featureGroups[locale].map((f,i)=><details key={f[0]} open={i<2}><summary><span>{String(i+1).padStart(2,"0")}</span>{f[0]}<i>+</i></summary><p>{f[1]}</p></details>)}</div></section>

    <section className="section privacy-explainer"><div><p className="eyebrow">Privacy by choice</p><h2>{locale === "ko" ? "어떤 기능이 언제 온라인을 사용하는지 확인하세요." : locale === "en" ? "Know exactly when a feature goes online." : "Du weißt genau, wann eine Funktion online geht."}</h2><p>{locale === "ko" ? "‘100% 오프라인’이라는 단순한 약속 대신, 기능별 처리 방식을 정확하게 보여줍니다." : locale === "en" ? "Instead of a broad 100% offline claim, Hangul Sori explains how each feature handles data." : "Statt eines pauschalen 100-Prozent-offline-Versprechens erklärt Hangul Sori die Verarbeitung pro Funktion."}</p><Link className="text-link" href={locale === "de" ? "/privacy" : `/privacy?lang=${locale}`}>{c.privacyLink} →</Link></div><div className="data-map"><div><span>L</span><p><b>{locale === "ko" ? "기기에 저장" : locale === "en" ? "Stored on device" : "Auf dem Gerät"}</b><small>{locale === "ko" ? "학습 진도, SRS, 사진, 메모" : "Progress, SRS, photos, notes"}</small></p></div><div><span>O</span><p><b>{locale === "ko" ? "사용자가 선택할 때" : locale === "en" ? "Only when selected" : "Nur wenn gewählt"}</b><small>{locale === "ko" ? "분석, 번역, TTS, 동기화" : "Analysis, translation, TTS, sync"}</small></p></div><div><span>✓</span><p><b>{locale === "ko" ? "선택 동의" : locale === "en" ? "Voluntary opt-in" : "Freiwilliges Opt-in"}</b><small>Analytics, Crashlytics, Notifications</small></p></div></div></section>

    <section className="section plans"><div className="section-heading"><div><p className="eyebrow">{freeEyebrow}</p><h2>{c.freeTitle}</h2></div><p>{c.freeText}</p></div><article className="launch-free"><div><span>0 €</span><h3>{locale === "ko" ? "부담 없이 한글소리를 시작하세요" : locale === "en" ? "Start Hangul Sori without a paywall" : "Starte Hangul Sori ohne Bezahlschranke"}</h3></div><ul>{launchItems.map(x=><li key={x}>✓ {x}</li>)}</ul></article></section>

    <section className="section faq"><p className="eyebrow">FAQ</p><h2>{c.faqTitle}</h2><div>{faqs.map(f=><details key={f[0]}><summary>{f[0]}<span>+</span></summary><p>{f[1]}</p></details>)}</div></section>
    <section className="final-cta"><div className="final-media"><video autoPlay muted loop playsInline preload="metadata" poster="/taego-joy-poster.jpg" aria-hidden="true"><source src="/taego-joy-duo.mp4" type="video/mp4"/></video><img className="motion-fallback" src="/taego-joy-poster.jpg" alt="Hangul Sori tiger and magpie"/></div><div><p className="eyebrow">한글소리 · Hangul Sori</p><h2>{c.finalTitle}</h2><p>{c.finalText}</p><StoreButtons locale={locale} compact/><a className="beta-link light" href="mailto:hello@hangul-sori.com?subject=Hangul%20Sori%20Beta">{c.beta} →</a></div></section><a className="mobile-cta" href="mailto:hello@hangul-sori.com?subject=Hangul%20Sori%20Beta">{c.beta} <span>→</span></a><Footer locale={locale}/>
  </main>;
}
