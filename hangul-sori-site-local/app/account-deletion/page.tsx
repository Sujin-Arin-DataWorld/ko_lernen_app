import type { Metadata } from "next";
import { LegalShell } from "../legal";

type Locale = "de" | "en" | "ko";
type PageProps = { searchParams: Promise<{ lang?: string }> };

const content = {
  de: {
    metadata: {
      title: "Konto und Daten löschen",
      description: "So beantragst du die Löschung deines Hangul Sori-Kontos und verwaltest lokale Daten oder Cloud-Backups.",
    },
    eyebrow: "Konto und Daten",
    title: "Konto und Daten löschen",
    intro: "Wähle den Weg, der zu deinem Ziel passt. Eine Deinstallation allein löscht kein bestehendes Konto oder Cloud-Backup.",
    requestTitle: "Dauerhafte Kontolöschung per E-Mail anfragen",
    requestIntro: "Du kannst die dauerhafte Löschung deines Hangul Sori-Kontos und der damit verbundenen Kontodaten auch ohne installierte App anfragen.",
    pageDoesNothing: "Beim Öffnen dieser Seite wird nichts gesendet. Der Link öffnet nur dein E-Mail-Programm; die Anfrage wird erst versendet, wenn du die E-Mail selbst abschickst.",
    recipient: "Empfänger",
    identification: "Nenne zur Zuordnung nur deine Anmeldeart (Gast, Google oder Apple) und bei einem verknüpften Konto die verwendete E-Mail-Adresse. Sende kein Passwort und keine Ausweiskopie.",
    async: "Mit dem Versand beantragst du die Löschung. Die Zuordnung des Kontos und die dauerhafte Bereinigung der zugehörigen Kontodaten können anschließend Zeit benötigen.",
    subject: "Hangul Sori Konto löschen",
    requestLabel: "E-Mail zur Kontolöschung öffnen →",
    appTitle: "Konto in der App löschen",
    appSteps: [
      "Öffne Hangul Sori.",
      "Öffne Einstellungen und dann den Kontobereich.",
      "Wähle Konto löschen, lies den Hinweis und bestätige.",
      "Bei einem verknüpften Google- oder Apple-Konto kann eine erneute Anmeldung nötig sein.",
    ],
    scopeTitle: "Welche Aktion brauchst du?",
    headings: ["Aktion", "Wirkung", "Nicht enthalten"],
    rows: [
      ["Lokale Daten zurücksetzen", "Entfernt Lernstand, verwaltete Bilder und lokale Caches auf diesem Gerät.", "Löscht weder das Konto noch ein vorhandenes Cloud-Backup."],
      ["Cloud-Backup löschen", "Entfernt die zum Konto gespeicherten Lern-Backup-Daten.", "Das Konto selbst bleibt bestehen."],
      ["Konto löschen", "Startet die dauerhafte Löschung des Kontos und der damit verbundenen Kontodaten.", "Löscht weder dein Google- noch dein Apple-Konto."],
      ["App deinstallieren", "Entfernt die App und ihre lokalen Daten von diesem Gerät.", "Fordert keine Löschung des Kontos oder eines Cloud-Backups an."],
    ],
  },
  en: {
    metadata: {
      title: "Delete account and data",
      description: "How to request deletion of your Hangul Sori account and manage local data or cloud backups.",
    },
    eyebrow: "Account and data",
    title: "Delete account and data",
    intro: "Choose the route that matches your goal. Uninstalling the app alone does not delete an existing account or cloud backup.",
    requestTitle: "Request permanent account deletion by email",
    requestIntro: "You can request permanent deletion of your Hangul Sori account and its associated account data even when the app is not installed.",
    pageDoesNothing: "Opening this page sends nothing. The link only opens your email app; the request is sent only when you send the email yourself.",
    recipient: "Recipient",
    identification: "For identification, provide only your sign-in method (guest, Google, or Apple) and, for a linked account, the email address you used. Do not send a password or identity document.",
    async: "Sending the email requests deletion. Identifying the account and permanently cleaning up its associated account data may take additional time.",
    subject: "Hangul Sori account deletion",
    requestLabel: "Open account deletion email →",
    appTitle: "Delete your account in the app",
    appSteps: [
      "Open Hangul Sori.",
      "Open Settings, then the account section.",
      "Choose Delete account, read the notice, and confirm.",
      "A linked Google or Apple account may require you to sign in again.",
    ],
    scopeTitle: "Which action do you need?",
    headings: ["Action", "Effect", "Not included"],
    rows: [
      ["Reset local data", "Removes learning progress, managed images, and local caches from this device.", "Does not delete the account or an existing cloud backup."],
      ["Delete cloud backup", "Removes learning backup data stored for the account.", "The account itself remains active."],
      ["Delete account", "Starts permanent deletion of the account and its associated account data.", "Does not delete your Google or Apple account."],
      ["Uninstall the app", "Removes the app and its local data from this device.", "Does not request deletion of the account or a cloud backup."],
    ],
  },
  ko: {
    metadata: {
      title: "계정 및 데이터 삭제",
      description: "Hangul Sori 계정 삭제를 요청하고 기기 데이터와 클라우드 백업을 관리하는 방법입니다.",
    },
    eyebrow: "계정 및 데이터",
    title: "계정 및 데이터 삭제",
    intro: "원하는 결과에 맞는 방법을 선택하세요. 앱을 삭제하는 것만으로 기존 계정이나 클라우드 백업이 삭제되지는 않습니다.",
    requestTitle: "이메일로 영구 계정 삭제 요청하기",
    requestIntro: "앱을 설치하지 않은 상태에서도 Hangul Sori 계정과 연결된 계정 데이터의 영구 삭제를 요청할 수 있습니다.",
    pageDoesNothing: "이 페이지를 여는 것만으로는 아무 내용도 전송되지 않습니다. 링크는 이메일 앱만 열며, 사용자가 직접 이메일을 보내야 요청이 전송됩니다.",
    recipient: "받는 주소",
    identification: "계정 확인을 위해 로그인 방식(게스트, Google 또는 Apple)과 연결 계정에서 사용한 이메일 주소만 적어 주세요. 비밀번호나 신분증 사본은 보내지 마세요.",
    async: "이메일을 보내면 삭제를 요청하게 됩니다. 계정을 확인하고 연결된 계정 데이터를 영구적으로 정리하는 데에는 추가 시간이 걸릴 수 있습니다.",
    subject: "Hangul Sori 계정 삭제",
    requestLabel: "계정 삭제 이메일 열기 →",
    appTitle: "앱에서 계정 삭제하기",
    appSteps: [
      "Hangul Sori를 엽니다.",
      "설정에서 계정 영역을 엽니다.",
      "계정 삭제를 선택하고 안내를 읽은 뒤 확인합니다.",
      "Google 또는 Apple 연결 계정은 다시 로그인이 필요할 수 있습니다.",
    ],
    scopeTitle: "어떤 작업이 필요한가요?",
    headings: ["작업", "결과", "포함되지 않는 항목"],
    rows: [
      ["기기 데이터 초기화", "이 기기의 학습 진도, 관리 중인 이미지와 로컬 캐시를 제거합니다.", "계정이나 기존 클라우드 백업은 삭제하지 않습니다."],
      ["클라우드 백업 삭제", "계정에 저장된 학습 백업 데이터를 제거합니다.", "계정 자체는 유지됩니다."],
      ["계정 삭제", "계정과 연결된 계정 데이터의 영구 삭제를 시작합니다.", "Google 또는 Apple 계정은 삭제하지 않습니다."],
      ["앱 삭제", "이 기기에서 앱과 로컬 데이터를 제거합니다.", "계정이나 클라우드 백업 삭제를 요청하지 않습니다."],
    ],
  },
} as const;

function localeFrom(lang?: string): Locale {
  return lang === "en" ? "en" : lang === "ko" ? "ko" : "de";
}

export async function generateMetadata({ searchParams }: PageProps): Promise<Metadata> {
  const locale = localeFrom((await searchParams).lang);
  return {
    ...content[locale].metadata,
    alternates: { canonical: "/account-deletion" },
  };
}

export default async function AccountDeletion({ searchParams }: PageProps) {
  const locale = localeFrom((await searchParams).lang);
  const c = content[locale];
  const mailto = `mailto:hello@hangul-sori.com?subject=${encodeURIComponent(c.subject)}`;

  return <LegalShell locale={locale} langBase="/account-deletion" eyebrow={c.eyebrow} title={c.title} intro={c.intro}>
    <div className="legal-card">
      <h2>{c.requestTitle}</h2>
      <p>{c.requestIntro}</p>
      <a className="text-link" href={mailto}>{c.requestLabel}</a>
      <p><b>{c.recipient}:</b> <a className="text-link" href={mailto}>hello@hangul-sori.com</a></p>
      <p>{c.pageDoesNothing}</p>
      <p>{c.identification}</p>
      <p className="notice">{c.async}</p>
    </div>
    <div className="legal-card">
      <h2>{c.appTitle}</h2>
      <ol>{c.appSteps.map((step) => <li key={step}>{step}</li>)}</ol>
    </div>
    <div className="legal-card">
      <h2>{c.scopeTitle}</h2>
      <table>
        <thead><tr>{c.headings.map((heading) => <th key={heading}>{heading}</th>)}</tr></thead>
        <tbody>{c.rows.map((row) => <tr key={row[0]}>{row.map((cell) => <td key={cell}>{cell}</td>)}</tr>)}</tbody>
      </table>
    </div>
  </LegalShell>;
}
