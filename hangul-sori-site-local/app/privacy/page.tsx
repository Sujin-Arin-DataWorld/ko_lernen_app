import type { Metadata } from "next";
import { LegalShell } from "../legal";

export const metadata: Metadata = {
  title: "Datenschutz",
  description: "Datenschutzhinweise für die Hangul Sori Website, Testbewerbungen und App.",
  alternates: { canonical: "/privacy" },
};

type Locale = "de" | "en" | "ko";

function ExternalLink({ href, children }: { href: string; children: React.ReactNode }) {
  return <a className="text-link" href={href} target="_blank" rel="noreferrer">{children}</a>;
}

const cookieInventory = {
  de: {
    headings: ["Name", "Anbieter", "Zweck", "Kategorie", "Dauer"],
    rows: [
      ["CookieConsent", "Hangul Sori / Usercentrics", "Speichert und dokumentiert deine Datenschutzauswahl.", "Notwendig", "Bis zu 12 Monate"],
      ["_ga", "Google Analytics", "Unterscheidet Besucher für zusammengefasste Nutzungsstatistiken.", "Statistik, nur nach Einwilligung", "180 Tage"],
      ["_ga_6R9J2N1PCC", "Google Analytics", "Ordnet Seitenaufrufe und Interaktionen einer Sitzung zu.", "Statistik, nur nach Einwilligung", "180 Tage"],
    ],
  },
  en: {
    headings: ["Name", "Provider", "Purpose", "Category", "Duration"],
    rows: [
      ["CookieConsent", "Hangul Sori / Usercentrics", "Stores and documents your privacy choice.", "Necessary", "Up to 12 months"],
      ["_ga", "Google Analytics", "Distinguishes visitors for aggregated usage statistics.", "Statistics, consent only", "180 days"],
      ["_ga_6R9J2N1PCC", "Google Analytics", "Links page views and interactions to a session.", "Statistics, consent only", "180 days"],
    ],
  },
  ko: {
    headings: ["이름", "제공자", "목적", "분류", "기간"],
    rows: [
      ["CookieConsent", "Hangul Sori / Usercentrics", "개인정보 선택을 저장하고 기록합니다.", "필수", "최대 12개월"],
      ["_ga", "Google Analytics", "집계된 이용 통계를 위해 방문자를 구분합니다.", "통계, 동의 후에만", "180일"],
      ["_ga_6R9J2N1PCC", "Google Analytics", "페이지 조회와 상호작용을 세션에 연결합니다.", "통계, 동의 후에만", "180일"],
    ],
  },
} as const;

function CookieInventory({ locale }: { locale: Locale }) {
  const inventory = cookieInventory[locale];
  return <div className="cookie-inventory" role="region" aria-label="Cookie inventory" tabIndex={0}>
    <table>
      <thead><tr>{inventory.headings.map((heading) => <th key={heading} scope="col">{heading}</th>)}</tr></thead>
      <tbody>{inventory.rows.map((row) => <tr key={row[0]}>{row.map((cell) => <td key={cell}>{cell}</td>)}</tr>)}</tbody>
    </table>
  </div>;
}

function GermanPrivacy() {
  return <>
    <div className="legal-card">
      <h2>1. Verantwortliche Stelle</h2>
      <p><b>Sujin Park, Sujin Arin DataWorld</b><br />Kurfürstenstraße 14<br />60486 Frankfurt am Main<br />Deutschland<br />E-Mail: <a className="text-link" href="mailto:hello@hangul-sori.com">hello@hangul-sori.com</a></p>
      <p>Datenschutzanfragen können jederzeit per E-Mail gestellt werden. Die vollständigen Anbieterangaben stehen im <a className="text-link" href="/impressum">Impressum</a>.</p>
    </div>

    <div className="legal-card">
      <h2>2. Bereitstellung, Sicherheit und Serverprotokolle</h2>
      <p>Die Website und das Testerformular werden über Cloudflare bereitgestellt. Beim Abruf können technisch erforderliche Daten wie IP-Adresse, Datum und Uhrzeit, aufgerufene Adresse, Referrer, Browser- und Betriebssystemangaben in Sicherheits- und Zugriffsprotokollen verarbeitet werden. Zweck ist die sichere, stabile Auslieferung sowie die Abwehr von Missbrauch.</p>
      <p>Rechtsgrundlage ist Art. 6 Abs. 1 lit. f DSGVO. Unser berechtigtes Interesse liegt im sicheren Betrieb der Website. Empfänger kann Cloudflare, Inc. als Auftragsverarbeiter sein. Übermittlungen außerhalb des EWR erfolgen nach den vertraglichen Schutzmechanismen von Cloudflare. Protokolle werden nur so lange aufbewahrt, wie sie für Betrieb, Fehleranalyse und Missbrauchsabwehr erforderlich sind. Mehr dazu: <ExternalLink href="https://www.cloudflare.com/privacypolicy/">Cloudflare Privacy Policy</ExternalLink>.</p>
    </div>

    <div className="legal-card" id="cookies">
      <h2>3. Einwilligungsverwaltung mit Cookiebot</h2>
      <p>Wir verwenden Cookiebot CMP von Usercentrics A/S, Dänemark, um deine Auswahl zu technisch nicht notwendigen Cookies zu erfassen, durchzusetzen und nach Art. 7 Abs. 1 DSGVO nachweisen zu können. Dabei können Einwilligungsstatus, Zeitstempel, die aufgerufene URL, Browserdaten und eine zur Protokollierung anonymisierte IP-Adresse verarbeitet werden.</p>
      <p>Die für die Einwilligungsverwaltung erforderliche Speicherung ist nach § 25 Abs. 2 Nr. 2 TDDDG technisch notwendig. Soweit personenbezogene Daten für den Nachweis verarbeitet werden, stützen wir dies auf Art. 6 Abs. 1 lit. c DSGVO. Nicht notwendige Dienste bleiben bis zu deiner aktiven Auswahl gesperrt. Du kannst deine Auswahl jederzeit über „Cookie-Einstellungen“ im Footer widerrufen oder ändern.</p>
      <CookieInventory locale="de" />
    </div>

    <div className="legal-card" id="website-analytics">
      <h2>4. Google Analytics nur nach Einwilligung</h2>
      <p>Wir verwenden Google Analytics 4, Mess-ID G-6R9J2N1PCC, ausschließlich nach aktiver Zustimmung zur Kategorie „Statistik“. Vorher wird das Google-Analytics-Skript nicht geladen und es findet keine Anfrage an Google Analytics statt. Werbespeicher, Google Signals, Werbenutzerdaten und personalisierte Werbung sind deaktiviert.</p>
      <p>Nach Zustimmung können besuchte Seiten, Interaktionen, Zeitstempel, technische Browser- und Geräteangaben, eine ungefähre Region sowie Cookie-Kennungen verarbeitet werden. Rechtsgrundlagen sind deine Einwilligung nach Art. 6 Abs. 1 lit. a DSGVO und § 25 Abs. 1 TDDDG. Empfänger ist Google Ireland Limited; eine Verarbeitung durch Google LLC in den USA kann nicht ausgeschlossen werden. Google verwendet dafür die in seinen Datenverarbeitungsbedingungen vorgesehenen Schutzmechanismen, einschließlich Angemessenheitsbeschlüssen und Standardvertragsklauseln, soweit anwendbar.</p>
      <p>Website-Cookies von Google Analytics laufen 180 Tage nach der letzten Messung ab; bei einem weiteren Besuch nach Einwilligung beginnt diese Frist erneut. Ereignis- und Nutzerdaten können in Google Analytics bis zu 14 Monate gespeichert werden; zusammengefasste Berichte können länger bestehen bleiben. Beim Widerruf wird die weitere Messung gestoppt und vorhandene Google-Analytics-Cookies dieser Website werden gelöscht. Bereits rechtmäßig verarbeitete Daten bleiben vom Widerruf unberührt. Mehr dazu: <ExternalLink href="https://policies.google.com/privacy">Google-Datenschutzerklärung</ExternalLink>.</p>
    </div>

    <div className="legal-card" id="tester-applications">
      <h2>5. Bewerbungen für den App-Test</h2>
      <p>Wenn du das Testerformular absendest, verarbeiten wir Name oder Spitzname, Einladungsadresse, Plattform, Gerät, Betriebssystem, Erklärungssprache, Koreanisch-Niveau, ausgewählte Testbereiche, Altersbestätigung, Testbereitschaft und eine freiwillige Nachricht. Pflichtangaben sind erforderlich, um die Bewerbung zu prüfen und eine passende Einladung zu senden.</p>
      <p>Rechtsgrundlage ist Art. 6 Abs. 1 lit. b DSGVO für vorvertragliche Maßnahmen auf deine Anfrage. Das Formular wird durch einen Cloudflare Worker verarbeitet und an ein durch Google bereitgestelltes Betreiber-Postfach gesendet. Auf der Website wird keine zusätzliche Bewerberdatenbank geführt. E-Mails werden spätestens sechs Monate nach Ende der betreffenden Testphase gelöscht, sofern keine weitere Abstimmung oder gesetzliche Aufbewahrung erforderlich ist.</p>
    </div>

    <div className="legal-card">
      <h2>6. Datenschutz in der App</h2>
      <p>Lernfortschritt, SRS-Status, Spielergebnisse, Einstellungen, eigene Lernpakete, Notizen sowie verwaltete Buch- oder Wortfotos bleiben grundsätzlich lokal auf deinem Gerät. Die App kann eine zufällige Firebase-UID erstellen und Remote Config abrufen. Cloud-Backup, Analytics, Crashlytics, Benachrichtigungen und Teilen-Funktionen werden nur im Umfang der von dir aktivierten Funktion genutzt.</p>
      <p>Ausgewählte Bilder werden auf dem Gerät zugeschnitten und mit ML Kit erkannt. Bilddateien werden nicht an die Textanalyse oder ein portables Backup gesendet. Wenn du ausdrücklich Analyse oder Übersetzung anforderst, können extrahierter Text und Zielsprache per HTTPS an die hierfür genannten Anbieter, darunter DeepL, übertragen werden. Gye-Lernkreise sind für Personen ab 16 Jahren.</p>
      <p><a className="text-link" href="/account-deletion">Konto und Daten löschen</a></p>
    </div>

    <div className="legal-card">
      <h2>7. Deine Rechte</h2>
      <p>Du hast nach Maßgabe der DSGVO das Recht auf Auskunft, Berichtigung, Löschung, Einschränkung der Verarbeitung, Datenübertragbarkeit und Widerspruch. Eine Einwilligung kannst du jederzeit mit Wirkung für die Zukunft widerrufen. Es findet keine ausschließlich automatisierte Entscheidung mit rechtlicher oder ähnlich erheblicher Wirkung statt.</p>
      <p>Schreibe an <a className="text-link" href="mailto:hello@hangul-sori.com?subject=Hangul%20Sori%20Datenschutz">hello@hangul-sori.com</a>. Du kannst dich außerdem bei einer Datenschutzaufsichtsbehörde beschweren, insbesondere beim <ExternalLink href="https://datenschutz.hessen.de/">Hessischen Beauftragten für Datenschutz und Informationsfreiheit</ExternalLink>.</p>
    </div>
  </>;
}

function EnglishPrivacy() {
  return <>
    <div className="legal-card">
      <h2>1. Controller</h2>
      <p><b>Sujin Park, Sujin Arin DataWorld</b><br />Kurfürstenstraße 14<br />60486 Frankfurt am Main<br />Germany<br />Email: <a className="text-link" href="mailto:hello@hangul-sori.com">hello@hangul-sori.com</a></p>
      <p>You may contact us about privacy at any time. Full provider details are available in the <a className="text-link" href="/impressum">legal notice</a>.</p>
    </div>

    <div className="legal-card">
      <h2>2. Delivery, security, and server logs</h2>
      <p>The website and tester form are delivered through Cloudflare. Requests may process technically required information such as IP address, time, requested URL, referrer, browser, and operating system in access and security logs. We use this information to deliver the site reliably and prevent abuse.</p>
      <p>The legal basis is Article 6(1)(f) GDPR. Our legitimate interest is the secure operation of the website. Cloudflare, Inc. may receive the data as our processor. Transfers outside the EEA use Cloudflare&apos;s contractual safeguards. Logs are kept only as long as necessary for operation, troubleshooting, and abuse prevention. See the <ExternalLink href="https://www.cloudflare.com/privacypolicy/">Cloudflare Privacy Policy</ExternalLink>.</p>
    </div>

    <div className="legal-card" id="cookies">
      <h2>3. Consent management with Cookiebot</h2>
      <p>We use Cookiebot CMP from Usercentrics A/S, Denmark, to record and enforce your choices about non-essential cookies and to demonstrate consent under Article 7(1) GDPR. It may process consent status, timestamp, visited URL, browser information, and an anonymized IP address for the consent log.</p>
      <p>Storage needed to remember and enforce your choice is strictly necessary under section 25(2)(2) TDDDG. Processing needed to demonstrate consent is based on Article 6(1)(c) GDPR. Optional services remain blocked until you actively choose them. You can withdraw or change your choice at any time through “Cookie settings” in the footer.</p>
      <CookieInventory locale="en" />
    </div>

    <div className="legal-card" id="website-analytics">
      <h2>4. Google Analytics only after consent</h2>
      <p>We use Google Analytics 4, measurement ID G-6R9J2N1PCC, only after you actively accept the Statistics category. Before that, the Google Analytics script is not downloaded and no Google Analytics request is made. Advertising storage, Google Signals, advertising user data, and personalized advertising are disabled.</p>
      <p>After consent, visited pages, interactions, timestamps, browser and device information, an approximate region, and cookie identifiers may be processed. The legal bases are your consent under Article 6(1)(a) GDPR and section 25(1) TDDDG. The recipient is Google Ireland Limited; processing by Google LLC in the United States cannot be ruled out. Google uses the safeguards in its data processing terms, including adequacy decisions and standard contractual clauses where applicable.</p>
      <p>Google Analytics cookies on this website expire 180 days after the last measurement; another visit after consent restarts that period. Event and user data may be retained in Google Analytics for up to 14 months; aggregated reports may remain longer. If you withdraw consent, further measurement stops and existing Google Analytics cookies for this website are removed. Withdrawal does not affect processing that was lawful before it. See <ExternalLink href="https://policies.google.com/privacy">Google&apos;s Privacy Policy</ExternalLink>.</p>
    </div>

    <div className="legal-card" id="tester-applications">
      <h2>5. Applications for the app test</h2>
      <p>When you submit the tester form, we process your name or nickname, invitation email, platform, device, operating system, explanation language, Korean level, selected test areas, age confirmation, testing commitment, and an optional message. Required fields are needed to review your application and send the correct invitation.</p>
      <p>The legal basis is Article 6(1)(b) GDPR for steps taken at your request before participation. A Cloudflare Worker processes the form and sends it to the operator&apos;s mailbox, which is provided by Google. The website does not keep a separate applicant database. Emails are deleted no later than six months after the relevant test phase ends unless continued coordination or a legal retention duty requires them.</p>
    </div>

    <div className="legal-card">
      <h2>6. Privacy in the app</h2>
      <p>Learning progress, SRS state, game results, settings, your own learning packs, notes, and managed book or word photos normally stay on your device. The app may create a random Firebase UID and fetch Remote Config. Cloud backup, Analytics, Crashlytics, notifications, and sharing features are used only to the extent of the feature you enable.</p>
      <p>Selected images are cropped and recognized on the device with ML Kit. Image files are not sent to text analysis or a portable backup. If you expressly request analysis or translation, extracted text and the target language may be sent by HTTPS to the named providers, including DeepL. Gye learning circles are for people aged 16 and older.</p>
      <p><a className="text-link" href="/account-deletion">Delete account and data</a></p>
    </div>

    <div className="legal-card">
      <h2>7. Your rights</h2>
      <p>Subject to the GDPR, you have rights of access, correction, deletion, restriction, data portability, and objection. You may withdraw consent at any time for the future. We do not make decisions based solely on automated processing that have legal or similarly significant effects.</p>
      <p>Contact <a className="text-link" href="mailto:hello@hangul-sori.com?subject=Hangul%20Sori%20Privacy">hello@hangul-sori.com</a>. You may also complain to a data protection authority, in particular the <ExternalLink href="https://datenschutz.hessen.de/">Hessian Commissioner for Data Protection and Freedom of Information</ExternalLink>.</p>
    </div>
  </>;
}

function KoreanPrivacy() {
  return <>
    <div className="legal-card">
      <h2>1. 개인정보처리자</h2>
      <p><b>Sujin Park, Sujin Arin DataWorld</b><br />Kurfürstenstraße 14<br />60486 Frankfurt am Main<br />독일<br />이메일: <a className="text-link" href="mailto:hello@hangul-sori.com">hello@hangul-sori.com</a></p>
      <p>개인정보 문의는 언제든 이메일로 접수할 수 있습니다. 전체 사업자 정보는 <a className="text-link" href="/impressum">법적 고지</a>에서 확인할 수 있습니다.</p>
    </div>

    <div className="legal-card">
      <h2>2. 웹사이트 제공과 보안 기록</h2>
      <p>웹사이트와 테스터 신청 폼은 Cloudflare를 통해 제공됩니다. 접속 과정에서 IP 주소, 접속 시각, 요청 주소, 리퍼러, 브라우저와 운영체제 정보가 보안 및 접속 기록으로 처리될 수 있습니다. 목적은 안정적인 서비스 제공과 오용 방지이며, 근거는 GDPR 제6조 제1항 f호의 정당한 이익입니다.</p>
      <p>Cloudflare, Inc.가 처리자로 참여할 수 있으며 EEA 외 전송에는 Cloudflare의 계약상 보호조치가 적용됩니다. 기록은 운영, 오류 분석, 오용 방지에 필요한 기간만 보관합니다. <ExternalLink href="https://www.cloudflare.com/privacypolicy/">Cloudflare 개인정보처리방침</ExternalLink></p>
    </div>

    <div className="legal-card" id="cookies">
      <h2>3. Cookiebot 동의 관리</h2>
      <p>비필수 쿠키에 대한 선택을 기록하고 적용하기 위해 덴마크 Usercentrics A/S의 Cookiebot CMP를 사용합니다. 동의 상태, 시각, 방문 URL, 브라우저 정보와 동의 기록용 익명화 IP 주소가 처리될 수 있습니다.</p>
      <p>선택을 기억하고 적용하기 위한 저장은 TDDDG 제25조 제2항 제2호에 따라 기술적으로 필요합니다. 선택하지 않은 서비스는 차단됩니다. 푸터의 ‘쿠키 설정’에서 언제든 동의를 철회하거나 변경할 수 있습니다.</p>
      <CookieInventory locale="ko" />
    </div>

    <div className="legal-card" id="website-analytics">
      <h2>4. 동의 후에만 사용하는 Google Analytics</h2>
      <p>측정 ID G-6R9J2N1PCC의 Google Analytics 4는 사용자가 ‘통계’에 동의한 뒤에만 사용합니다. 그 전에는 Google Analytics 스크립트와 네트워크 요청이 모두 차단됩니다. 광고 저장, Google Signals, 광고용 사용자 데이터와 개인 맞춤 광고는 비활성화합니다.</p>
      <p>동의 후 방문 페이지, 상호작용, 시각, 브라우저와 기기 정보, 대략적인 지역, 쿠키 식별자가 처리될 수 있습니다. 법적 근거는 GDPR 제6조 제1항 a호 및 TDDDG 제25조 제1항의 동의입니다. 수신자는 Google Ireland Limited이며 미국의 Google LLC가 처리할 가능성이 있습니다. 해당 전송에는 적용 가능한 적정성 결정과 표준계약조항 등 Google의 보호조치가 사용됩니다.</p>
      <p>이 웹사이트의 Google Analytics 쿠키는 마지막 측정 후 180일이 지나면 만료되며, 동의 상태에서 다시 방문하면 이 기간이 새로 시작됩니다. 이벤트 및 사용자 데이터는 Google Analytics에서 최대 14개월간 보관될 수 있으며 집계 보고서는 더 오래 남을 수 있습니다. 동의를 철회하면 추가 측정이 중단되고 이 사이트의 Google Analytics 쿠키를 삭제합니다. <ExternalLink href="https://policies.google.com/privacy">Google 개인정보처리방침</ExternalLink></p>
    </div>

    <div className="legal-card" id="tester-applications">
      <h2>5. 앱 테스터 신청</h2>
      <p>테스터 신청 시 이름 또는 별명, 초대 이메일, 플랫폼, 기기, 운영체제, 설명 언어, 한국어 수준, 테스트 분야, 나이 확인, 테스트 참여 가능 여부와 선택 메시지를 처리합니다. 필수 정보는 신청 검토와 정확한 초대 전송에 필요합니다.</p>
      <p>법적 근거는 참여 요청에 따른 사전 조치를 위한 GDPR 제6조 제1항 b호입니다. 신청은 Cloudflare Worker를 거쳐 Google이 제공하는 운영자 메일함으로 전달됩니다. 웹사이트에는 별도 신청자 데이터베이스를 두지 않습니다. 메일은 해당 테스트 단계 종료 후 최대 6개월 이내 삭제합니다. 추가 협의나 법정 보관 의무가 있는 경우는 제외합니다.</p>
    </div>

    <div className="legal-card">
      <h2>6. 앱 안의 데이터</h2>
      <p>학습 진도, SRS 상태, 게임 결과, 설정, 개인 학습팩, 메모, 관리 중인 책·단어 사진은 원칙적으로 기기에 저장됩니다. 앱은 임의의 Firebase UID를 만들고 Remote Config를 불러올 수 있습니다. 클라우드 백업, Analytics, Crashlytics, 알림과 공유는 사용자가 활성화한 기능 범위에서만 사용합니다.</p>
      <p>선택 이미지는 기기에서 자르고 ML Kit으로 인식합니다. 이미지 파일은 텍스트 분석이나 이동식 백업으로 전송하지 않습니다. 사용자가 분석이나 번역을 요청하면 추출 텍스트와 대상 언어가 DeepL 등 고지된 제공자에게 HTTPS로 전송될 수 있습니다. Gye 학습 모임은 만 16세 이상을 위한 기능입니다.</p>
      <p><a className="text-link" href="/account-deletion">계정 및 데이터 삭제</a></p>
    </div>

    <div className="legal-card">
      <h2>7. 사용자의 권리</h2>
      <p>GDPR에 따라 열람, 정정, 삭제, 처리 제한, 데이터 이동 및 반대 권리를 행사할 수 있습니다. 동의는 언제든 장래에 대해 철회할 수 있습니다. 법적 또는 유사하게 중대한 영향을 주는 완전 자동화 의사결정은 하지 않습니다.</p>
      <p><a className="text-link" href="mailto:hello@hangul-sori.com?subject=Hangul%20Sori%20Privacy">hello@hangul-sori.com</a>으로 연락하거나 <ExternalLink href="https://datenschutz.hessen.de/">헤센주 개인정보보호 감독기관</ExternalLink>에 민원을 제기할 수 있습니다.</p>
    </div>
  </>;
}

const heading = {
  de: { eyebrow: "Stand: 12. August 2026", title: "Datenschutz", intro: "Hier erklären wir, welche Daten die Website, das Testerformular und die Hangul Sori App verarbeiten, warum das geschieht und welche Rechte du hast." },
  en: { eyebrow: "Updated 12 August 2026", title: "Privacy", intro: "This notice explains what the website, tester form, and Hangul Sori app process, why we do so, and the rights available to you." },
  ko: { eyebrow: "2026년 8월 12일 기준", title: "개인정보처리방침", intro: "웹사이트, 테스터 신청 폼과 Hangul Sori 앱에서 어떤 데이터를 왜 처리하는지, 사용자가 어떤 권리를 갖는지 설명합니다." },
} as const;

export default async function Privacy({ searchParams }: { searchParams: Promise<{ lang?: string }> }) {
  const { lang } = await searchParams;
  const locale: Locale = lang === "en" ? "en" : lang === "ko" ? "ko" : "de";
  const c = heading[locale];
  return <LegalShell locale={locale} langBase="/privacy" eyebrow={c.eyebrow} title={c.title} intro={c.intro}>
    {locale === "en" ? <EnglishPrivacy /> : locale === "ko" ? <KoreanPrivacy /> : <GermanPrivacy />}
  </LegalShell>;
}
