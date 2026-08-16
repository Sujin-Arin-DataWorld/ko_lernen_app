import Link from "next/link";
import { Apple, ArrowRight, Brain, Check, Coffee, Gamepad2, Headphones, Languages, MapPin, Mic2, Play, Repeat2, Sparkles, UsersRound, Volume2 } from "lucide-react";
import { TesterAccessForm } from "./tester-access-form";
import { CookieSettingsButton } from "./cookie-settings-button";
import { CulturalLocaleSync, CulturalTerm } from "./cultural-glossary";

export type Locale = "de" | "en" | "ko";

const content = {
  en: {
    nav: ["How it works", "Features", "For learners"],
    login: "Log in",
    start: "Start learning",
    eyebrow: "한글을, 소리로 배우다",
    headline: "Learn Korean and build your own hanok.",
    intro: "Tiger and Magpie guide you through Hangul, pronunciation, everyday Korean and games. Each completed lesson adds to your hanok. In Gye, learners can share progress and encourage each other.",
    secondary: "See how it works",
    proof: ["Made for English speakers", "Natural Korean audio", "Lessons take 5 to 10 minutes"],
    stepsEyebrow: "HOW A LESSON WORKS",
    stepsTitle: "Listen, speak, then review.",
    stepsIntro: "Lessons are short. You hear a phrase, say it aloud and review it again before you forget it.",
    steps: [
      ["Listen", "Hear natural Korean in short, focused clips."],
      ["Speak", "Repeat with rhythm and clear mouth cues."],
      ["Review", "Review useful words and phrases at the right time."],
    ],
    featuresEyebrow: "WHAT YOU CAN LEARN",
    featuresTitle: "Hangul, pronunciation and everyday Korean in one place.",
    featuresIntro: "Choose the activity you need. Progress carries across lessons, vocabulary review and games.",
    features: [
      ["한", "Hangul", "Build syllable blocks and read with confidence."],
      ["소", "Pronunciation", "Train sound contrasts, rhythm and natural flow."],
      ["기", "Vocabulary SRS", "Review the right words before they fade."],
      ["말", "Everyday Korean", "Practice Korean for cafés, transport and conversations with friends."],
      ["놀이", "Mini games", "Turn quick listening wins into a steady habit."],
    ],
    journeyEyebrow: "나의 한옥",
    journeyTitle: "Your hanok changes as you learn.",
    journeyIntro: "Lessons and reviews unlock new parts of the building. The stages show what you have finished and what comes next.",
    journey: ["Hangul foundations", "Sound & rhythm", "Everyday Korean", "Speak with confidence"],
    current: "Current level",
    complete: "62% complete",
    learnersEyebrow: "EXPLANATIONS IN GERMAN AND ENGLISH",
    learnersTitle: "Explanations for German and English speakers.",
    learnersIntro: "Compare unfamiliar Korean sounds with examples from German or English. The examples are explained in your language, while the audio stays in Korean.",
    trust: [
      ["German or English", "Change the explanation language without losing progress."],
      ["Sound comparisons", "Use familiar sounds to hear the difference between Korean consonants and vowels."],
      ["Everyday situations", "Practice Korean for cafés, transport and conversations with friends."],
      ["Gye learning circles", "Join a small learning group, share progress and send encouragement."],
    ],
    finalEyebrow: "TEST HANGUL SORI",
    finalTitle: "Try the current test version.",
    finalIntro: "iOS and Android testing are open now.",
    socialEyebrow: "LEARN WITH US ON INSTAGRAM",
    socialTitle: "A little Korean for your feed.",
    socialIntro: "Try Sori Check, discover how names sound in Hangul and watch a hanok grow one lesson at a time.",
    socialButton: "Follow on Instagram",
    socialCards: ["Sori Check", "Your name in Hangul", "One sound. One building block."],
    footerLine: "Hangul, pronunciation, everyday Korean and learning groups for German and English speakers.",
  },
  de: {
    nav: ["So funktioniert’s", "Funktionen", "Für Lernende"],
    login: "Anmelden",
    start: "Jetzt lernen",
    eyebrow: "한글을, 소리로 배우다",
    headline: "Lerne Koreanisch und baue deinen eigenen Hanok.",
    intro: "Tiger und Elster begleiten dich durch Hangul, Aussprache, Alltagssprache und Spiele. Jede abgeschlossene Lektion erweitert deinen Hanok. In Gye können Lernende Fortschritte teilen und sich gegenseitig ermutigen.",
    secondary: "So funktioniert’s",
    proof: ["Für Deutschsprachige", "Natürliches Koreanisch", "Lektionen dauern 5 bis 10 Minuten"],
    stepsEyebrow: "SO LÄUFT EINE LEKTION AB",
    stepsTitle: "Hören, sprechen, wiederholen.",
    stepsIntro: "Die Lektionen sind kurz. Du hörst einen Satz, sprichst ihn nach und wiederholst ihn, bevor du ihn wieder vergisst.",
    steps: [
      ["Hören", "Natürliches Koreanisch in kurzen, fokussierten Clips."],
      ["Nachsprechen", "Wiederhole mit Rhythmus und klaren Mundhinweisen."],
      ["Wiederholen", "Wiederhole nützliche Wörter und Sätze zum richtigen Zeitpunkt."],
    ],
    featuresEyebrow: "DAS KANNST DU LERNEN",
    featuresTitle: "Hangul, Aussprache und Alltagssprache an einem Ort.",
    featuresIntro: "Wähle die Übung, die du gerade brauchst. Dein Fortschritt bleibt in Lektionen, Vokabeltraining und Spielen erhalten.",
    features: [
      ["한", "Hangul", "Baue Silbenblöcke und lies Schritt für Schritt sicher."],
      ["소", "Aussprache", "Trainiere Lautkontraste, Rhythmus und natürlichen Sprachfluss."],
      ["기", "Vokabeltraining", "Wiederhole nützliche Wörter zum richtigen Zeitpunkt."],
      ["말", "Koreanisch im Alltag", "Übe Sprache für Café, Verkehr und tägliche Situationen."],
      ["놀이", "Minispiele", "Übe Hören und Lesen in kurzen Spielrunden."],
    ],
    journeyEyebrow: "나의 한옥",
    journeyTitle: "Dein Hanok wächst mit deinem Lernfortschritt.",
    journeyIntro: "Lektionen und Wiederholungen schalten neue Bauteile frei. Die Stufen zeigen, was fertig ist und was als Nächstes kommt.",
    journey: ["Hangul-Grundlagen", "Laut & Rhythmus", "Koreanisch im Alltag", "Sicher sprechen"],
    current: "Aktuelles Level",
    complete: "62 % geschafft",
    learnersEyebrow: "ERKLÄRUNGEN AUF DEUTSCH UND ENGLISCH",
    learnersTitle: "Erklärungen für deutsch- und englischsprachige Lernende.",
    learnersIntro: "Vergleiche neue koreanische Laute mit Beispielen aus dem Deutschen oder Englischen. Die Erklärungen sind in deiner Sprache, das Audio bleibt Koreanisch.",
    trust: [
      ["Deutsch oder Englisch", "Wechsle die Erklärungssprache, ohne deinen Fortschritt zu verlieren."],
      ["Lautvergleiche", "Nutze vertraute Laute, um koreanische Konsonanten und Vokale zu unterscheiden."],
      ["Alltagssituationen", "Übe Koreanisch für Cafés, Verkehr und Gespräche mit Freunden."],
      ["Gye-Lernkreise", "Lerne in einer kleinen Gruppe, teile Fortschritte und sende Ermutigungen."],
    ],
    finalEyebrow: "HANGUL SORI TESTEN",
    finalTitle: "Probiere die aktuelle Testversion aus.",
    finalIntro: "Die Tests für iOS und Android sind jetzt geöffnet.",
    socialEyebrow: "LERNE MIT UNS AUF INSTAGRAM",
    socialTitle: "Ein bisschen Koreanisch für deinen Feed.",
    socialIntro: "Mach beim Sori Check mit, entdecke deinen Namen in Hangul und sieh zu, wie dein Hanok mit jeder Lektion wächst.",
    socialButton: "Auf Instagram folgen",
    socialCards: ["Sori Check", "Dein Name in Hangul", "Ein Laut. Ein Baustein."],
    footerLine: "Hangul, Aussprache, Alltagssprache und Lerngruppen für deutsch- und englischsprachige Lernende.",
  },
  ko: {
    nav: ["학습 방식", "주요 기능", "학습자 안내"],
    login: "로그인",
    start: "학습 시작",
    eyebrow: "한글을, 소리로 배우다",
    headline: "한국어를 배우며 나만의 한옥을 지어요.",
    intro: "호랑이와 까치가 한글, 발음, 생활 한국어, 게임 학습을 안내합니다. 수업을 마칠 때마다 한옥에 새로운 부분이 생깁니다. 계에서는 학습자들이 진도를 나누고 서로 응원할 수 있습니다.",
    secondary: "학습 방식 보기",
    proof: ["독일어와 영어 설명", "자연스러운 한국어 음성", "5분에서 10분 학습"],
    stepsEyebrow: "한 수업의 학습 순서",
    stepsTitle: "듣고, 말하고, 다시 복습해요.",
    stepsIntro: "짧은 문장을 듣고 소리 내어 따라 말합니다. 잊기 전에 다시 복습합니다.",
    steps: [
      ["듣기", "짧고 집중된 음성으로 자연스러운 한국어를 듣습니다."],
      ["따라 말하기", "리듬과 입 모양 안내에 맞춰 소리를 반복합니다."],
      ["복습하기", "필요한 단어와 문장을 알맞은 때에 다시 봅니다."],
    ],
    featuresEyebrow: "배울 수 있는 내용",
    featuresTitle: "한글, 발음, 생활 한국어를 한곳에서 배워요.",
    featuresIntro: "필요한 학습을 골라 시작하세요. 수업, 단어 복습, 게임의 진도가 함께 이어집니다.",
    features: [
      ["한", "한글", "글자 블록을 이해하고 자신 있게 읽습니다."],
      ["소", "발음", "소리 차이와 리듬, 자연스러운 흐름을 연습합니다."],
      ["기", "단어 SRS", "잊기 전에 필요한 단어를 다시 만납니다."],
      ["말", "실생활 한국어", "카페, 교통, 일상에서 쓰는 표현을 익힙니다."],
      ["놀이", "미니게임", "짧은 듣기 성공을 꾸준한 습관으로 만듭니다."],
    ],
    journeyEyebrow: "나의 한옥",
    journeyTitle: "학습할수록 한옥이 달라져요.",
    journeyIntro: "수업과 복습을 마치면 한옥의 새 부분이 열립니다. 단계 이미지에서 완성한 부분과 다음 목표를 확인할 수 있습니다.",
    journey: ["한글 기초", "소리와 리듬", "생활 한국어", "자연스럽게 말하기"],
    current: "현재 레벨",
    complete: "62% 완료",
    learnersEyebrow: "독일어와 영어 설명",
    learnersTitle: "독일어와 영어 사용자를 위한 설명을 제공합니다.",
    learnersIntro: "낯선 한국어 소리를 독일어 또는 영어의 예와 비교합니다. 설명은 선택한 언어로 제공하고, 음성은 한국어로 들려줍니다.",
    trust: [
      ["독일어 또는 영어", "진도를 유지한 채 설명 언어를 바꿀 수 있습니다."],
      ["소리 비교", "익숙한 소리와 비교하며 한국어 자음과 모음의 차이를 듣습니다."],
      ["생활 속 상황", "카페, 교통, 친구와의 대화에 필요한 한국어를 연습합니다."],
      ["계 학습 모임", "작은 학습 모임에서 진도를 나누고 서로 응원합니다."],
    ],
    finalEyebrow: "한글소리 테스트",
    finalTitle: "현재 테스트 버전을 사용해 보세요.",
    finalIntro: "iOS와 Android 테스트를 지금 이용할 수 있습니다.",
    socialEyebrow: "인스타그램에서 함께 배워요",
    socialTitle: "피드에서 만나는 짧은 한국어.",
    socialIntro: "소리 체크에 참여하고, 이름을 한글로 써 보고, 수업마다 자라는 한옥을 만나 보세요.",
    socialButton: "인스타그램 팔로우",
    socialCards: ["소리 체크", "내 이름을 한글로", "한 소리. 한 칸."],
    footerLine: "독일어와 영어 사용자를 위한 한글, 발음, 생활 한국어, 학습 모임.",
  },
} as const;

const IOS_TESTFLIGHT = {
  // Set isAvailable to false before deploying an update that closes iOS testing.
  // All iOS CTAs will then return visitors to the existing tester application form.
  isAvailable: true,
  url: "https://testflight.apple.com/join/sbvJNQSt",
} as const;

const testerCopy = {
  en: {
    iosAvailable: "iOS beta available",
    iosUnavailable: "iOS in preparation",
    android: "Android testing",
  },
  de: {
    iosAvailable: "iOS-Beta verfügbar",
    iosUnavailable: "iOS in Vorbereitung",
    android: "Android-Test läuft",
  },
  ko: {
    iosAvailable: "iOS 베타 이용 가능",
    iosUnavailable: "iOS 준비 중",
    android: "Android 테스트 중",
  },
} as const;

function localeHref(locale: Locale) {
  return locale === "en" ? "/en" : locale === "ko" ? "/ko" : "/de";
}

function ButtonLink({ href, children, variant = "primary", compact = false }: { href: string; children: React.ReactNode; variant?: "primary" | "secondary" | "ghost"; compact?: boolean }) {
  return <a className={`button button-${variant}${compact ? " button-compact" : ""}`} href={href}>{children}<ArrowRight aria-hidden="true" size={18} strokeWidth={2.4}/></a>;
}

function StoreButtons({ locale, light = false }: { locale: Locale; light?: boolean }) {
  const t = testerCopy[locale];
  const iosTestingOpen = IOS_TESTFLIGHT.isAvailable;
  return <div className={`store-buttons${light ? " store-buttons-light" : ""}`} aria-label="App testing access">
    <a className="store-button" href={iosTestingOpen ? IOS_TESTFLIGHT.url : "#tester-access"} target={iosTestingOpen ? "_blank" : undefined} rel={iosTestingOpen ? "noopener noreferrer" : undefined} aria-haspopup={iosTestingOpen ? undefined : "dialog"}><span className="store-icon" aria-hidden="true"><Apple size={20} strokeWidth={2}/></span><span><small>{iosTestingOpen ? t.iosAvailable : t.iosUnavailable}</small><b>App Store</b></span></a>
    <a className="store-button" href="#tester-access" aria-haspopup="dialog"><span className="store-icon play-icon" aria-hidden="true"><Play size={18} fill="currentColor" strokeWidth={1.8}/></span><span><small>{t.android}</small><b>Google Play</b></span></a>
  </div>;
}

function Brand() {
  return <span className="brand-mark" aria-label="Hangul Sori"><picture><source media="(max-width: 560px)" srcSet="/icon-192.png"/><img className="brand-logo" src="/hangul-sori-logo.png" alt="" width="44" height="44"/></picture><span><b>Hangul Sori</b><small>한글소리</small></span></span>;
}

function InstagramIcon({ size = 18 }: { size?: number }) {
  return <svg aria-hidden="true" width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect width="18" height="18" x="3" y="3" rx="5"/><circle cx="12" cy="12" r="4"/><circle cx="17.5" cy="6.5" r="1" fill="currentColor" stroke="none"/></svg>;
}

export function Header({ locale }: { locale: Locale }) {
  const c = content[locale];
  return <header className="site-header"><div className="nav-shell">
    <Link className="brand-link" href={localeHref(locale)}><Brand /></Link>
    <nav className="desktop-nav" aria-label="Primary navigation"><Link href="#how">{c.nav[0]}</Link><Link href="#features">{c.nav[1]}</Link><Link href="#learners">{c.nav[2]}</Link></nav>
    <div className="nav-actions"><div className="locale-switch" aria-label="Language"><Link className={locale === "de" ? "active" : ""} href="/de">DE</Link><Link className={locale === "en" ? "active" : ""} href="/en">EN</Link><Link className={locale === "ko" ? "active" : ""} href="/ko">KO</Link></div><a className="login-link" href="#tester-access">{c.login}</a><ButtonLink href="#tester-access" compact>{c.start}</ButtonLink></div>
  </div></header>;
}

function HanokHero({ locale, compact = false }: { locale: Locale; compact?: boolean }) {
  const labels = {
    en: { level: "Your hanok, level 7", status: "3 lessons completed", week: "This week", unlocked: "Roof frame unlocked", mascots: "Tiger and Magpie", welcome: "Welcome back." },
    de: { level: "Dein Hanok, Level 7", status: "3 Lektionen abgeschlossen", week: "Diese Woche", unlocked: "Dachstuhl freigeschaltet", mascots: "Tiger und Elster", welcome: "Willkommen zurück." },
    ko: { level: "나의 한옥, 7단계", status: "수업 3개 완료", week: "이번 주", unlocked: "지붕 단계 열림", mascots: "호랑이와 까치", welcome: "다시 만나서 반가워요." },
  }[locale];
  return <div className={`hanok-hero-media${compact ? " hanok-hero-media-compact" : ""}`}>
    <div className="scene-topline"><span>{labels.level}</span><span className="scene-status">{labels.status}</span></div>
    <video autoPlay muted loop playsInline preload="metadata" poster="/app-assets/hanok-stages/stage-jongga.png" aria-label="Hangul Sori hanok growing as the learner progresses"><source src={compact ? "/app-assets/hanok-jongga.mp4" : "/app-assets/hanok-construction.mp4"} type="video/mp4"/></video>
    <div className="hanok-media-caption"><img src="/app-assets/taego-joy-duo.png" alt="Hangul Sori tiger and magpie mascots"/><div><small>{compact ? labels.mascots : labels.week}</small><b>{compact ? labels.welcome : labels.unlocked}</b></div></div>
  </div>;
}

const lessonDemo = {
  en: { session: "LESSON 08 · FIRST MEETINGS", listen: "Hear the shape", speak: "Catch the rhythm", review: "Keep it", ready: "READY TO REVIEW", result: "Lesson clear", reward: "A new hanok beam is yours", play: "Play Korean phrase", score: "GREAT MATCH" },
  de: { session: "LEKTION 08 · ERSTES TREFFEN", listen: "Hör die Form", speak: "Finde den Rhythmus", review: "Behalte es", ready: "BEREIT ZUM WIEDERHOLEN", result: "Lektion geschafft", reward: "Ein neuer Hanok-Balken gehört dir", play: "Koreanischen Satz abspielen", score: "SEHR GUT" },
  ko: { session: "08번째 수업 · 첫 만남", listen: "소리의 모양 듣기", speak: "리듬 따라잡기", review: "기억에 남기기", ready: "복습할 준비 완료", result: "수업 완료", reward: "한옥에 새 들보가 생겼어요", play: "한국어 문장 재생", score: "아주 좋아요" },
} as const;

function Waveform({ compact = false }: { compact?: boolean }) {
  return <span className={`lesson-wave${compact ? " lesson-wave-compact" : ""}`} aria-hidden="true">{[5,12,22,34,18,42,28,14,30,20,8].map((height,index)=><i key={index} style={{height}}/>)}</span>;
}

function LessonStage({ locale, steps }: { locale: Locale; steps: readonly (readonly [string, string])[] }) {
  const demo = lessonDemo[locale];
  return <div className="lesson-stage">
    <div className="lesson-stage-top"><span>{demo.session}</span><span><i/> 5 MIN</span></div>
    <ol className="lesson-flow">
      <li className="lesson-beat lesson-beat-listen">
        <div className="lesson-beat-head"><span>01</span><Headphones aria-hidden="true" size={24}/></div>
        <small>{demo.listen}</small><h3>{steps[0][0]}</h3><p>{steps[0][1]}</p>
        <div className="listen-demo"><span className="demo-play" aria-hidden="true"><Play size={18} fill="currentColor"/></span><div><b>괜찮아요?</b><span>gwaen-chan-a-yo?</span></div><Waveform compact/></div>
      </li>
      <li className="lesson-beat lesson-beat-speak">
        <div className="lesson-beat-head"><span>02</span><Mic2 aria-hidden="true" size={24}/></div>
        <small>{demo.speak}</small><h3>{steps[1][0]}</h3><p>{steps[1][1]}</p>
        <div className="speak-demo"><span className="speak-score">{demo.score}</span><b>괜 · 찮 · 아 · 요</b><Waveform/></div>
      </li>
      <li className="lesson-beat lesson-beat-review">
        <div className="lesson-beat-head"><span>03</span><Repeat2 aria-hidden="true" size={24}/></div>
        <small>{demo.review}</small><h3>{steps[2][0]}</h3><p>{steps[2][1]}</p>
        <div className="review-demo"><span>{demo.ready}</span><div><b>한</b><b>소</b><b>리</b><em><Check size={18}/></em></div></div>
      </li>
    </ol>
    <div className="lesson-reward"><span><Check size={18}/></span><div><small>{demo.result}</small><b>{demo.reward}</b></div><div className="hanok-line" aria-hidden="true"><i/><i/><i/><i/></div></div>
  </div>;
}

const featureDemo = {
  en: { build: "BUILD A SYLLABLE", sound: "SOUND LAB", due: "DUE TODAY", streak: "day streak", scene: "REAL-LIFE SCENE", game: "QUICK MATCH", correct: "3 IN A ROW", listen: "Listen again", situation: "At a café" },
  de: { build: "BAUE EINE SILBE", sound: "LAUTLABOR", due: "HEUTE FÄLLIG", streak: "Tage in Folge", scene: "ECHTE SITUATION", game: "SCHNELLES MATCH", correct: "3 RICHTIG", listen: "Noch einmal hören", situation: "Im Café" },
  ko: { build: "글자 블록 만들기", sound: "소리 연구소", due: "오늘 복습", streak: "일 연속", scene: "생활 속 장면", game: "빠른 소리 맞히기", correct: "3개 연속 정답", listen: "다시 듣기", situation: "카페에서" },
} as const;

function FeatureShowcase({ locale, features }: { locale: Locale; features: readonly (readonly [string, string, string])[] }) {
  const demo = featureDemo[locale];
  return <div className="feature-showcase">
    <article className="feature-panel feature-hangul">
      <div className="feature-panel-head"><span>{demo.build}</span><b>{features[0][0]}</b></div>
      <div className="hangul-builder" aria-hidden="true"><span>ㄱ</span><i>+</i><span>ㅏ</span><i>=</i><strong>가</strong></div>
      <div className="feature-panel-copy"><div><small>01</small><h3>{features[0][1]}</h3></div><p>{features[0][2]}</p></div>
    </article>
    <article className="feature-panel feature-pronunciation">
      <div className="feature-panel-head"><span>{demo.sound}</span><Volume2 size={21}/></div>
      <div className="sound-lab"><div><small>ㅓ / ㅗ</small><b>서울 · 소울</b></div><Waveform/><span className="demo-action"><Play size={15} fill="currentColor"/> {demo.listen}</span></div>
      <div className="feature-panel-copy"><div><small>02</small><h3>{features[1][1]}</h3></div><p>{features[1][2]}</p></div>
    </article>
    <article className="feature-panel feature-srs">
      <div className="feature-panel-head"><span>{demo.due}</span><Brain size={20}/></div>
      <div className="srs-count"><strong>12</strong><span><b>7</b> {demo.streak}</span></div>
      <div className="feature-panel-copy"><div><small>03</small><h3>{features[2][1]}</h3></div><p>{features[2][2]}</p></div>
    </article>
    <article className="feature-panel feature-games">
      <div className="feature-panel-head"><span>{demo.game}</span><Gamepad2 size={20}/></div>
      <div className="game-match"><span>소</span><span>서</span><span className="active">수</span><b><Sparkles size={14}/>{demo.correct}</b></div>
      <div className="feature-panel-copy"><div><small>05</small><h3>{features[4][1]}</h3></div><p>{features[4][2]}</p></div>
    </article>
    <article className="feature-panel feature-everyday">
      <div className="everyday-scene"><span><Coffee size={19}/>{demo.situation}</span><div><b>아이스 아메리카노 한 잔 주세요.</b><span className="demo-play" aria-hidden="true"><Volume2 size={18}/></span></div><small>{locale === "de" ? "„Einen Iced Americano, bitte.“" : locale === "ko" ? "아이스 아메리카노 한 잔을 주문하는 표현" : "“One iced Americano, please.”"}</small></div>
      <div className="feature-panel-copy"><div><small>{demo.scene}</small><h3>{features[3][1]}</h3></div><p>{features[3][2]}</p></div>
    </article>
  </div>;
}

const culturalHeroCopy = {
  en: {
    headlineBefore: "Learn Korean and build your own ", hanok: "hanok", headlineAfter: ".",
    introBefore: "Tiger and Magpie guide you through Hangul, pronunciation, everyday Korean and games. Each completed lesson adds to your hanok. In ", gye: "Gye", introAfter: ", learners can share progress and encourage each other.",
  },
  de: {
    headlineBefore: "Lerne Koreanisch und baue deinen eigenen ", hanok: "Hanok", headlineAfter: ".",
    introBefore: "Tiger und Elster begleiten dich durch Hangul, Aussprache, Alltagssprache und Spiele. Jede abgeschlossene Lektion erweitert deinen Hanok. In ", gye: "Gye", introAfter: " können Lernende Fortschritte teilen und sich gegenseitig ermutigen.",
  },
  ko: {
    headlineBefore: "한국어를 배우며 나만의 ", hanok: "한옥", headlineAfter: "을 지어요.",
    introBefore: "호랑이와 까치가 한글, 발음, 생활 한국어, 게임 학습을 안내합니다. 수업을 마칠 때마다 한옥에 새로운 부분이 생깁니다. ", gye: "계", introAfter: "에서는 학습자들이 진도를 나누고 서로 응원할 수 있습니다.",
  },
} as const;

function CulturalHeroHeadline({ locale }: { locale: Locale }) {
  const copy = culturalHeroCopy[locale];
  return <>{copy.headlineBefore}<CulturalTerm termId="hanok" locale={locale}>{copy.hanok}</CulturalTerm>{copy.headlineAfter}</>;
}

function CulturalHeroIntro({ locale }: { locale: Locale }) {
  const copy = culturalHeroCopy[locale];
  return <>{copy.introBefore}<CulturalTerm termId="gye" locale={locale}>{copy.gye}</CulturalTerm>{copy.introAfter}</>;
}

export function Footer({ locale }: { locale: Locale }) {
  const c = content[locale];
  return <footer className="site-footer"><div className="footer-top"><Brand/><p>{c.footerLine}</p><div className="footer-links"><Link href="#how">{c.nav[0]}</Link><Link href="#features">{c.nav[1]}</Link><a href="https://www.instagram.com/hangulsori_learnkorean/" target="_blank" rel="noreferrer"><InstagramIcon size={15}/>Instagram</a><Link href="/support">Support</Link><Link href="/privacy">Privacy</Link><Link href="/impressum">Impressum</Link><CookieSettingsButton locale={locale}/></div></div><div className="footer-bottom"><span>© 2026 Hangul Sori</span><span>Frankfurt am Main, Germany</span></div></footer>;
}

export function Landing({ locale }: { locale: Locale }) {
  const c = content[locale];
  const trustIcons = [<Languages key="languages" size={25}/>, <Headphones key="sounds" size={25}/>, <MapPin key="situations" size={25}/>, <UsersRound key="gye" size={25}/>];
  return <main lang={locale}>
    <CulturalLocaleSync locale={locale}/>
    <Header locale={locale}/>
    <section className="hero-section"><div className="hero-shell"><div className="hero-copy"><p className="eyebrow korean-brand-copy">{c.eyebrow}</p><h1><CulturalHeroHeadline locale={locale}/></h1><p className="hero-intro"><CulturalHeroIntro locale={locale}/></p><div className="hero-actions"><ButtonLink href="#tester-access">{c.start}</ButtonLink><ButtonLink href="#how" variant="secondary">{c.secondary}</ButtonLink></div><StoreButtons locale={locale}/><ul className="proof-row">{c.proof.map(item=><li key={item}><span aria-hidden="true">✓</span>{item}</li>)}</ul></div><HanokHero locale={locale}/></div></section>

    <section className="section how-section" id="how"><div className="section-shell"><div className="section-heading"><div><p className="eyebrow">{c.stepsEyebrow}</p><h2>{c.stepsTitle}</h2></div><p>{c.stepsIntro}</p></div><LessonStage locale={locale} steps={c.steps}/></div></section>

    <section className="section features-section" id="features"><div className="section-shell"><div className="section-heading"><div><p className="eyebrow">{c.featuresEyebrow}</p><h2>{c.featuresTitle}</h2></div><p>{c.featuresIntro}</p></div><FeatureShowcase locale={locale} features={c.features}/></div></section>

    <section className="journey-section"><div className="journey-shell"><div className="journey-copy"><p className="eyebrow eyebrow-light korean-brand-copy">{c.journeyEyebrow}</p><h2 className={locale === "ko" ? "ko-emotive-title" : undefined}>{c.journeyTitle}</h2><p>{c.journeyIntro}</p><div className="progress-meta"><span>{c.current}</span><b>{c.complete}</b></div><div className="progress-bar" aria-label={c.complete}><span /></div></div><div><div className="hanok-stage-strip" aria-label="Hanok construction stages">{[
      ["/app-assets/hanok-stages/stage-empty.png", "01"],
      ["/app-assets/hanok-stages/stage-foundation.png", "02"],
      ["/app-assets/hanok-stages/stage-pillars.png", "03"],
      ["/app-assets/hanok-stages/stage-roof.png", "04"],
      ["/app-assets/hanok-stages/stage-jongga.png", "05"],
    ].map(([src,label],index)=><figure className={index < 3 ? "unlocked" : ""} key={src}><img src={src} alt=""/><figcaption>{label}</figcaption></figure>)}</div><ol className="journey-track">{c.journey.map((item,index)=><li className={index < 2 ? "done" : index === 2 ? "current" : "locked"} key={item}><span className="journey-node">{index < 2 ? <Check size={20} strokeWidth={3}/> : index + 1}</span><div><small>{index === 0 ? "A1 01" : index === 1 ? "A1 02" : index === 2 ? "A1 03" : "A2 01"}</small><b>{item}</b></div></li>)}</ol></div></div></section>

    <section className="section learners-section" id="learners"><div className="section-shell learner-shell"><div className="learner-copy"><p className="eyebrow">{c.learnersEyebrow}</p><h2>{c.learnersTitle}</h2><p>{c.learnersIntro}</p><div className="language-note"><span>DE</span><span>EN</span><ArrowRight aria-hidden="true" size={19}/><strong>한국어</strong></div></div><div className="trust-grid">{c.trust.map((item,index)=><article key={item[0]}><div className="trust-card-top"><span>{trustIcons[index]}</span><small>0{index+1}</small></div><h3>{item[0]}</h3><p>{item[1]}</p></article>)}</div></div></section>

    <section className="section social-section" id="instagram"><div className="section-shell"><div className="social-heading"><div><p className="eyebrow">{c.socialEyebrow}</p><h2>{c.socialTitle}</h2><p>{c.socialIntro}</p></div><a className="button button-primary" href="https://www.instagram.com/hangulsori_learnkorean/" target="_blank" rel="noreferrer"><InstagramIcon size={20}/>{c.socialButton}</a></div><div className="social-grid">{[
      ["/social/sori-check-01.png", c.socialCards[0]],
      ["/social/name-in-hangul.png", c.socialCards[1]],
      ["/social/one-sound-one-space.png", c.socialCards[2]],
    ].map(([src,label], index)=><a className={`social-card social-card-${index + 1}`} key={src} href="https://www.instagram.com/hangulsori_learnkorean/" target="_blank" rel="noreferrer" aria-label={`${label} on Instagram`}><span className="social-media" aria-hidden="true">{index === 0 ? <video autoPlay muted loop playsInline preload="metadata" poster={src}><source src="/social/sori-check-01-reel.mp4" type="video/mp4"/></video> : <img src={src} alt=""/>}</span><span className="social-card-label"><InstagramIcon size={17}/>{label}<ArrowRight size={17}/></span></a>)}</div></div></section>

    <section className="final-section" id="start"><div className="final-shell"><div><p className="eyebrow eyebrow-light">{c.finalEyebrow}</p><h2>{c.finalTitle}</h2><p>{c.finalIntro}</p><StoreButtons locale={locale} light/></div><HanokHero locale={locale} compact/></div></section>
    <Footer locale={locale}/><TesterAccessForm locale={locale}/>
  </main>;
}
