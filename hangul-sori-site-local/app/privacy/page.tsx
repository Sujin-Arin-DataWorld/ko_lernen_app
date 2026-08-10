import type { Metadata } from "next";
import { LegalShell } from "../legal";

export const metadata: Metadata = {
  title: "Datenschutz",
  description:
    "Verständliche Informationen zur local-first Datenverarbeitung in Hangul Sori.",
  alternates: { canonical: "/privacy" },
};

type Locale = "de" | "en" | "ko";

const content: Record<
  Locale,
  { eyebrow: string; title: string; intro: string; body: React.ReactNode }
> = {
  de: {
    eyebrow: "Stand: 10. August 2026",
    title: "Datenschutz, verständlich erklärt",
    intro:
      "Hangul Sori ist local-first, nicht vollständig offline. Hier siehst du die wichtigsten Datenwege in klarer Verbrauchersprache.",
    body: (
      <>
        <div className="legal-card">
          <h2>Was standardmäßig lokal bleibt</h2>
          <p>
            Lernfortschritt, SRS-Status, Spielergebnisse, Streaks,
            Einstellungen, eigene Lernpakete, Bücherregal-Inhalte, Notizen und
            verwaltete Buch- oder Wortfotos werden lokal gespeichert. Der lokale
            Speicher bleibt die maßgebliche Datenquelle.
          </p>
        </div>
        <div className="legal-card">
          <h2>Was beim App-Start passieren kann</h2>
          <p>
            Die App startet Firebase, erstellt oder verwendet eine zufällige
            anonyme Firebase-UID und ruft Remote Config ab. Online-Dienste
            werden nur im Umfang der in der installierten Version aktivierten
            Funktionen verwendet. Der erste öffentliche Release ist ohne
            Abonnement und In-App-Kauf vorgesehen.
          </p>
        </div>
        <div className="legal-card">
          <h2>Fotos, OCR und Analyse</h2>
          <p>
            Das ausgewählte Bild wird auf dem Gerät zugeschnitten und mit ML Kit
            erkannt. Bildbytes werden nicht an die Analyse oder ein portables
            Backup gesendet. Wenn du Analyse oder Übersetzung anforderst, werden
            der extrahierte und gegebenenfalls korrigierte Text sowie die
            Zielsprache per HTTPS übertragen. Textsegmente können an DeepL gehen
            und in einem serverseitigen Übersetzungs-Cache verarbeitet werden.
          </p>
        </div>
        <div className="legal-card">
          <h2>Nur wenn du dich entscheidest</h2>
          <table>
            <tbody>
              <tr>
                <th>Google oder Apple verknüpfen</th>
                <td>
                  Ermöglicht angebotene Firestore-Backups von Lern- und
                  Bücherregal-Texten. Buch- und Wortfotos werden dadurch nicht
                  hochgeladen.
                </td>
              </tr>
              <tr>
                <th>Analytics oder Crashlytics</th>
                <td>
                  Getrennte freiwillige Einwilligungen, in der nativen
                  Konfiguration standardmäßig aus.
                </td>
              </tr>
              <tr>
                <th>Benachrichtigungen</th>
                <td>
                  FCM-Token wird erst beim Aktivieren angefordert und der
                  aktuellen Firebase-UID zugeordnet.
                </td>
              </tr>
              <tr>
                <th>Gye oder Teilen</th>
                <td>
                  Verarbeitet nur die für Lerngruppe oder bewusst geteiltes
                  Lernpaket erforderlichen Daten. Gye ist für Nutzer ab 16
                  Jahren.
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <div className="legal-card">
          <h2>Keine Werbung und kein appübergreifendes Tracking</h2>
          <p>
            Die App enthält kein aktives Werbe-SDK, fordert keine Werbekennung
            an und nutzt Daten nicht für appübergreifendes Tracking. Standort,
            Kontakte und Mikrofon werden nicht angefordert.
          </p>
          <p>
            <a className="text-link" href="/account-deletion">
              Konto und Daten löschen →
            </a>
            <br />
            <a
              className="text-link"
              href="mailto:hello@hangul-sori.com?subject=Hangul%20Sori%20Datenschutz"
            >
              Datenschutzfrage stellen →
            </a>
          </p>
        </div>
      </>
    ),
  },
  en: {
    eyebrow: "Updated 10 August 2026",
    title: "Privacy, explained simply",
    intro:
      "Hangul Sori is local-first, not fully offline. Here are the main data flows in plain, everyday language.",
    body: (
      <>
        <div className="legal-card">
          <h2>What stays on your device by default</h2>
          <p>
            Learning progress, SRS state, game results, streaks, settings, your
            own learning packs, bookshelf content, notes, and managed book or
            word photos are stored locally. Local storage remains the
            authoritative source of your data.
          </p>
        </div>
        <div className="legal-card">
          <h2>What can happen at app startup</h2>
          <p>
            The app starts Firebase, creates or reuses a random anonymous
            Firebase UID, and fetches Remote Config. Online services are used
            only to the extent of the features enabled in your installed
            version. The first public release is planned without any
            subscription or in-app purchase.
          </p>
        </div>
        <div className="legal-card">
          <h2>Photos, OCR, and analysis</h2>
          <p>
            The selected image is cropped and recognized on your device with ML
            Kit. Image bytes are not sent to analysis or to a portable backup.
            When you request analysis or translation, the extracted (and
            optionally corrected) text and the target language are transmitted
            over HTTPS. Text segments may go to DeepL and be processed in a
            server-side translation cache.
          </p>
        </div>
        <div className="legal-card">
          <h2>Only when you choose to</h2>
          <table>
            <tbody>
              <tr>
                <th>Link Google or Apple</th>
                <td>
                  Enables the offered Firestore backups of learning and
                  bookshelf text. Book and word photos are not uploaded by this.
                </td>
              </tr>
              <tr>
                <th>Analytics or Crashlytics</th>
                <td>
                  Separate voluntary opt-ins, off by default in the native
                  configuration.
                </td>
              </tr>
              <tr>
                <th>Notifications</th>
                <td>
                  An FCM token is requested only when you enable them and is
                  linked to your current Firebase UID.
                </td>
              </tr>
              <tr>
                <th>Gye or Sharing</th>
                <td>
                  Processes only the data needed for a study group or a pack you
                  deliberately share. Gye is for users aged 16 and older.
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <div className="legal-card">
          <h2>No advertising and no cross-app tracking</h2>
          <p>
            The app contains no active advertising SDK, requests no advertising
            identifier, and does not use data for cross-app tracking. Location,
            contacts, and microphone are not requested.
          </p>
          <p>
            <a className="text-link" href="/account-deletion">
              Delete account and data →
            </a>
            <br />
            <a
              className="text-link"
              href="mailto:hello@hangul-sori.com?subject=Hangul%20Sori%20Privacy"
            >
              Ask a privacy question →
            </a>
          </p>
        </div>
      </>
    ),
  },
  ko: {
    eyebrow: "2026년 8월 10일 기준",
    title: "쉽게 설명하는 개인정보 처리",
    intro:
      "한글소리는 로컬 우선(local-first)이며 완전한 오프라인은 아닙니다. 주요 데이터 흐름을 쉬운 말로 정리했습니다.",
    body: (
      <>
        <div className="legal-card">
          <h2>기본적으로 기기에 남는 것</h2>
          <p>
            학습 진도, SRS 상태, 게임 결과, 연속 학습, 설정, 사용자 학습팩, 책장
            내용, 메모, 관리되는 책·단어 사진은 기기에 저장됩니다. 로컬 저장소가
            기준이 되는 데이터입니다.
          </p>
        </div>
        <div className="legal-card">
          <h2>앱 시작 시 일어날 수 있는 일</h2>
          <p>
            앱은 Firebase를 시작하고 무작위 익명 Firebase UID를 만들거나
            재사용하며 Remote Config를 불러옵니다. 온라인 서비스는 설치된
            버전에서 활성화된 기능 범위에서만 사용됩니다. 첫 공개 버전은 구독과
            인앱결제 없이 제공될 예정입니다.
          </p>
        </div>
        <div className="legal-card">
          <h2>사진, OCR, 분석</h2>
          <p>
            선택한 이미지는 기기에서 잘리고 ML Kit으로 인식됩니다. 이미지
            바이트는 분석이나 이동식 백업으로 전송되지 않습니다. 분석이나 번역을
            요청하면 추출된(그리고 필요 시 수정된) 텍스트와 대상 언어가 HTTPS로
            전송됩니다. 텍스트 일부는 DeepL로 전달되어 서버 측 번역 캐시에서
            처리될 수 있습니다.
          </p>
        </div>
        <div className="legal-card">
          <h2>사용자가 선택할 때만</h2>
          <table>
            <tbody>
              <tr>
                <th>Google 또는 Apple 연결</th>
                <td>
                  제공되는 학습·책장 텍스트의 Firestore 백업을 사용할 수
                  있습니다. 이때 책·단어 사진은 업로드되지 않습니다.
                </td>
              </tr>
              <tr>
                <th>Analytics 또는 Crashlytics</th>
                <td>
                  각각 별도의 자발적 동의 항목이며, 네이티브 설정에서 기본적으로
                  꺼져 있습니다.
                </td>
              </tr>
              <tr>
                <th>알림</th>
                <td>
                  FCM 토큰은 알림을 켤 때만 요청되며 현재 Firebase UID에
                  연결됩니다.
                </td>
              </tr>
              <tr>
                <th>Gye 또는 공유</th>
                <td>
                  학습 그룹이나 사용자가 직접 공유한 학습팩에 필요한 데이터만
                  처리합니다. Gye는 만 16세 이상 사용자를 위한 기능입니다.
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <div className="legal-card">
          <h2>광고 없음, 앱 간 추적 없음</h2>
          <p>
            앱에는 활성 광고 SDK가 없고, 광고 식별자를 요청하지 않으며, 데이터를
            앱 간 추적에 사용하지 않습니다. 위치, 연락처, 마이크는 요청하지
            않습니다.
          </p>
          <p>
            <a className="text-link" href="/account-deletion">
              계정 및 데이터 삭제 →
            </a>
            <br />
            <a
              className="text-link"
              href="mailto:hello@hangul-sori.com?subject=Hangul%20Sori%20Privacy"
            >
              개인정보 문의하기 →
            </a>
          </p>
        </div>
      </>
    ),
  },
};

export default async function Privacy({
  searchParams,
}: {
  searchParams: Promise<{ lang?: string }>;
}) {
  const { lang } = await searchParams;
  const locale: Locale = lang === "en" ? "en" : lang === "ko" ? "ko" : "de";
  const c = content[locale];
  return (
    <LegalShell
      locale={locale}
      langBase="/privacy"
      eyebrow={c.eyebrow}
      title={c.title}
      intro={c.intro}
    >
      {c.body}
    </LegalShell>
  );
}
