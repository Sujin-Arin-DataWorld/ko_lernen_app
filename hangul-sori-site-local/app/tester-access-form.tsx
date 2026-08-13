"use client";

import { Apple, ArrowRight, CheckCircle2, LoaderCircle, Play } from "lucide-react";
import { useState, type FormEvent } from "react";
import type { Locale } from "./site";
import { STORE_LINKS } from "./store-links";

const copy = {
  en: {
    eyebrow: "TEST ACCESS",
    title: "Join the Hangul Sori test.",
    text: "Tell us only what we need to send the right invitation and plan useful feedback.",
    close: "Close test application",
    name: "Name or nickname",
    namePlaceholder: "How should we address you?",
    email: "Email for the test invitation",
    emailHelp: "Use the Google Play or Apple ID email that should receive the invitation.",
    platform: "Test device",
    android: "Android",
    androidNote: "Testing now",
    ios: "iPhone / iOS",
    iosNote: "Waiting list",
    device: "Device model",
    devicePlaceholder: "e.g. Pixel 8, Galaxy S23, iPhone 15",
    os: "OS version",
    osPlaceholder: "e.g. Android 15, iOS 18",
    language: "Explanation language",
    languagePlaceholder: "Choose a language",
    german: "German",
    english: "English",
    level: "Your Korean level",
    levelPlaceholder: "Choose your current level",
    levels: ["Complete beginner", "Learning Hangul", "I can read Hangul", "Basic conversation", "Intermediate or above"],
    focus: "What would you like to test?",
    focuses: ["Hangul & reading", "Pronunciation & listening", "Everyday Korean", "Vocabulary & SRS", "Mini games & hanok progress"],
    notes: "Anything else we should know?",
    notesPlaceholder: "Optional: what you hope to practice or notice during the test",
    age: "I confirm that I am at least 16 years old.",
    commitment: "When invited, I can test the app several times and send brief feedback.",
    privacyPrefix: "I have read the ",
    privacyLink: "privacy information for test applications",
    privacySuffix: " and acknowledge the processing described there.",
    submit: "Send test application",
    sending: "Sending application",
    required: "Required fields",
    focusError: "Choose at least one area you would like to test.",
    error: "The application could not be sent. Please check the fields and try again.",
    successTitle: "Your application has arrived.",
    successText: "Thank you. We will review your device and learning profile and contact you by email.",
    installLead: "Your install link is ready:",
    installIos: "Install via TestFlight",
    installAndroid: "Install on Google Play",
    installAndroidNote: "If you don't see the app yet, we'll email your invitation shortly after adding you as a tester.",
    successClose: "Back to the website",
  },
  de: {
    eyebrow: "TESTZUGANG",
    title: "Für den Hangul Sori Test bewerben.",
    text: "Diese Angaben reichen aus, damit wir die passende Einladung senden und hilfreiches Feedback planen können.",
    close: "Testbewerbung schließen",
    name: "Name oder Spitzname",
    namePlaceholder: "Wie dürfen wir dich ansprechen?",
    email: "E-Mail für die Testeinladung",
    emailHelp: "Nutze die Google-Play- oder Apple-ID-Adresse, die die Einladung erhalten soll.",
    platform: "Testgerät",
    android: "Android",
    androidNote: "Test läuft",
    ios: "iPhone / iOS",
    iosNote: "Warteliste",
    device: "Gerätemodell",
    devicePlaceholder: "z. B. Pixel 8, Galaxy S23, iPhone 15",
    os: "Betriebssystem",
    osPlaceholder: "z. B. Android 15, iOS 18",
    language: "Sprache der Erklärungen",
    languagePlaceholder: "Sprache auswählen",
    german: "Deutsch",
    english: "Englisch",
    level: "Dein Koreanisch-Niveau",
    levelPlaceholder: "Aktuellen Stand auswählen",
    levels: ["Noch keine Vorkenntnisse", "Ich lerne Hangul", "Ich kann Hangul lesen", "Einfache Gespräche", "Mittelstufe oder höher"],
    focus: "Was möchtest du testen?",
    focuses: ["Hangul & Lesen", "Aussprache & Hören", "Koreanisch im Alltag", "Vokabeln & SRS", "Minispiele & Hanok-Fortschritt"],
    notes: "Gibt es noch etwas Wichtiges?",
    notesPlaceholder: "Optional: was du üben oder beim Test besonders beachten möchtest",
    age: "Ich bestätige, dass ich mindestens 16 Jahre alt bin.",
    commitment: "Nach der Einladung kann ich die App mehrmals testen und kurzes Feedback senden.",
    privacyPrefix: "Ich habe die ",
    privacyLink: "Datenschutzhinweise für Testbewerbungen",
    privacySuffix: " gelesen und zur Kenntnis genommen.",
    submit: "Testbewerbung senden",
    sending: "Bewerbung wird gesendet",
    required: "Pflichtfelder",
    focusError: "Wähle mindestens einen Bereich aus, den du testen möchtest.",
    error: "Die Bewerbung konnte nicht gesendet werden. Bitte prüfe die Felder und versuche es erneut.",
    successTitle: "Deine Bewerbung ist angekommen.",
    successText: "Danke. Wir prüfen dein Gerät und Lernprofil und melden uns per E-Mail.",
    installLead: "Dein Installationslink ist bereit:",
    installIos: "Über TestFlight installieren",
    installAndroid: "Bei Google Play installieren",
    installAndroidNote: "Falls die App noch nicht erscheint, senden wir dir die Einladung per E-Mail, sobald wir dich als Tester hinzugefügt haben.",
    successClose: "Zurück zur Website",
  },
  ko: {
    eyebrow: "테스트 참여",
    title: "한글소리 테스터로 신청해 주세요.",
    text: "알맞은 초대를 보내고 필요한 피드백을 준비하는 데 필요한 정보만 받습니다.",
    close: "테스터 신청 닫기",
    name: "이름 또는 닉네임",
    namePlaceholder: "어떻게 불러드리면 될까요?",
    email: "테스트 초대를 받을 이메일",
    emailHelp: "초대를 받을 Google Play 계정 또는 Apple ID 이메일을 입력해 주세요.",
    platform: "테스트 기기",
    android: "Android",
    androidNote: "테스트 진행 중",
    ios: "iPhone / iOS",
    iosNote: "대기 명단",
    device: "기기 모델",
    devicePlaceholder: "예: Pixel 8, Galaxy S23, iPhone 15",
    os: "운영체제 버전",
    osPlaceholder: "예: Android 15, iOS 18",
    language: "설명 언어",
    languagePlaceholder: "언어 선택",
    german: "독일어",
    english: "영어",
    level: "현재 한국어 수준",
    levelPlaceholder: "현재 수준 선택",
    levels: ["완전 초보", "한글을 배우는 중", "한글을 읽을 수 있음", "간단한 대화 가능", "중급 이상"],
    focus: "어떤 부분을 테스트하고 싶나요?",
    focuses: ["한글과 읽기", "발음과 듣기", "생활 한국어", "어휘와 SRS", "미니게임과 한옥 성장"],
    notes: "추가로 알려줄 내용이 있나요?",
    notesPlaceholder: "선택 사항: 연습하고 싶은 내용이나 테스트에서 살펴보고 싶은 점",
    age: "만 16세 이상임을 확인합니다.",
    commitment: "초대를 받으면 앱을 여러 번 사용하고 짧은 피드백을 보낼 수 있습니다.",
    privacyPrefix: "테스터 신청 ",
    privacyLink: "개인정보 안내",
    privacySuffix: "를 읽고 안내된 정보 처리를 확인했습니다.",
    submit: "테스터 신청 보내기",
    sending: "신청 보내는 중",
    required: "필수 항목",
    focusError: "테스트하고 싶은 영역을 하나 이상 선택해 주세요.",
    error: "신청을 보내지 못했습니다. 입력 내용을 확인하고 다시 시도해 주세요.",
    successTitle: "신청이 도착했습니다.",
    successText: "감사합니다. 기기와 학습 정보를 확인한 뒤 이메일로 연락드리겠습니다.",
    installLead: "설치 링크가 준비되어 있어요:",
    installIos: "TestFlight로 설치하기",
    installAndroid: "Google Play에서 설치하기",
    installAndroidNote: "앱이 아직 보이지 않으면, 테스터로 등록한 뒤 초대 메일을 보내드릴게요.",
    successClose: "사이트로 돌아가기",
  },
} as const;

const levelValues = ["beginner", "hangul-learning", "hangul-reading", "basic-conversation", "intermediate-plus"];
const focusValues = ["hangul-reading", "pronunciation-listening", "everyday-korean", "vocabulary-srs", "games-hanok"];

export function TesterAccessForm({ locale }: { locale: Locale }) {
  const t = copy[locale];
  const [state, setState] = useState<"idle" | "sending" | "success" | "error">("idle");
  const [message, setMessage] = useState("");
  const [platform, setPlatform] = useState<"android" | "ios" | null>(null);

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const form = event.currentTarget;
    const data = new FormData(form);
    const focus = data.getAll("focus").map(String);

    if (focus.length === 0) {
      setState("error");
      setMessage(t.focusError);
      return;
    }

    const selectedPlatform = data.get("platform") === "ios" ? "ios" : "android";
    setState("sending");
    setMessage("");

    try {
      const response = await fetch("/api/tester-application", {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "x-hangul-sori-form": "tester-application",
        },
        body: JSON.stringify({
          locale,
          name: data.get("name"),
          email: data.get("email"),
          platform: data.get("platform"),
          device: data.get("device"),
          osVersion: data.get("osVersion"),
          explanationLanguage: data.get("explanationLanguage"),
          koreanLevel: data.get("koreanLevel"),
          focus,
          notes: data.get("notes"),
          ageConfirmed: data.get("ageConfirmed") === "yes",
          commitment: data.get("commitment") === "yes",
          privacyAcknowledged: data.get("privacyAcknowledged") === "yes",
          website: data.get("website"),
        }),
      });

      if (!response.ok) throw new Error("tester application rejected");
      form.reset();
      setPlatform(selectedPlatform);
      setState("success");
    } catch {
      setState("error");
      setMessage(t.error);
    }
  }

  return (
    <div className="tester-dialog" id="tester-access" role="dialog" aria-modal="true" aria-labelledby="tester-title">
      <a className="tester-backdrop" href="#tester-access-closed" aria-label={t.close} />
      <div className="tester-card">
        <a className="tester-close" href="#tester-access-closed" aria-label={t.close}>×</a>
        {state === "success" ? (
          <div className="tester-success" role="status">
            <span className="tester-success-icon" aria-hidden="true"><CheckCircle2 size={32} /></span>
            <p className="eyebrow">{t.eyebrow}</p>
            <h2 id="tester-title">{t.successTitle}</h2>
            <p>{t.successText}</p>
            <div className="tester-install">
              <p className="tester-install-lead">{t.installLead}</p>
              {platform === "ios" ? (
                <a className="button button-primary tester-install-cta" href={STORE_LINKS.ios} target="_blank" rel="noopener noreferrer">
                  <Apple aria-hidden="true" size={18} />{t.installIos}
                </a>
              ) : (
                <>
                  <a className="button button-primary tester-install-cta" href={STORE_LINKS.android} target="_blank" rel="noopener noreferrer">
                    <Play aria-hidden="true" size={16} fill="currentColor" />{t.installAndroid}
                  </a>
                  <small className="tester-install-note">{t.installAndroidNote}</small>
                </>
              )}
            </div>
            <a className="button button-ghost" href="#tester-access-closed">{t.successClose}<ArrowRight aria-hidden="true" size={18} /></a>
          </div>
        ) : (
          <>
            <p className="eyebrow">{t.eyebrow}</p>
            <h2 id="tester-title">{t.title}</h2>
            <p className="tester-intro">{t.text}</p>
            <form className="tester-form" onSubmit={submit}>
              <div className="form-trap" aria-hidden="true">
                <label htmlFor="tester-website">Website</label>
                <input id="tester-website" name="website" type="text" tabIndex={-1} autoComplete="off" />
              </div>

              <div className="form-grid">
                <label className="form-field">
                  <span>{t.name} <i>*</i></span>
                  <input name="name" type="text" required maxLength={80} autoComplete="name" placeholder={t.namePlaceholder} />
                </label>
                <label className="form-field">
                  <span>{t.email} <i>*</i></span>
                  <input name="email" type="email" required maxLength={254} autoComplete="email" placeholder="name@example.com" />
                  <small>{t.emailHelp}</small>
                </label>
              </div>

              <fieldset className="form-fieldset">
                <legend>{t.platform} <i>*</i></legend>
                <div className="platform-options">
                  <label><input name="platform" type="radio" value="android" required /><span><b>{t.android}</b><small>{t.androidNote}</small></span></label>
                  <label><input name="platform" type="radio" value="ios" required /><span><b>{t.ios}</b><small>{t.iosNote}</small></span></label>
                </div>
              </fieldset>

              <div className="form-grid">
                <label className="form-field">
                  <span>{t.device}</span>
                  <input name="device" type="text" maxLength={80} placeholder={t.devicePlaceholder} />
                </label>
                <label className="form-field">
                  <span>{t.os}</span>
                  <input name="osVersion" type="text" maxLength={40} placeholder={t.osPlaceholder} />
                </label>
                <label className="form-field">
                  <span>{t.language} <i>*</i></span>
                  <select name="explanationLanguage" required defaultValue="">
                    <option value="" disabled>{t.languagePlaceholder}</option>
                    <option value="de">{t.german}</option>
                    <option value="en">{t.english}</option>
                  </select>
                </label>
                <label className="form-field">
                  <span>{t.level} <i>*</i></span>
                  <select name="koreanLevel" required defaultValue="">
                    <option value="" disabled>{t.levelPlaceholder}</option>
                    {t.levels.map((label, index) => <option value={levelValues[index]} key={levelValues[index]}>{label}</option>)}
                  </select>
                </label>
              </div>

              <fieldset className="form-fieldset">
                <legend>{t.focus} <i>*</i></legend>
                <div className="focus-options">
                  {t.focuses.map((label, index) => <label key={focusValues[index]}><input name="focus" type="checkbox" value={focusValues[index]} /><span>{label}</span></label>)}
                </div>
              </fieldset>

              <label className="form-field form-field-wide">
                <span>{t.notes}</span>
                <textarea name="notes" rows={3} maxLength={800} placeholder={t.notesPlaceholder} />
              </label>

              <div className="consent-list">
                <label><input name="ageConfirmed" type="checkbox" value="yes" required /><span>{t.age}</span></label>
                <label><input name="commitment" type="checkbox" value="yes" required /><span>{t.commitment}</span></label>
                <label><input name="privacyAcknowledged" type="checkbox" value="yes" required /><span>{t.privacyPrefix}<a href={`/privacy?lang=${locale}#tester-applications`}>{t.privacyLink}</a>{t.privacySuffix}</span></label>
              </div>

              <div className={`form-message${state === "error" ? " form-message-error" : ""}`} role="alert" aria-live="polite">
                {message}
              </div>
              <button className="button button-primary tester-submit" type="submit" disabled={state === "sending"}>
                {state === "sending" ? <><LoaderCircle className="spin" aria-hidden="true" size={18} />{t.sending}</> : <>{t.submit}<ArrowRight aria-hidden="true" size={18} /></>}
              </button>
              <small className="required-note">* {t.required}</small>
            </form>
          </>
        )}
      </div>
    </div>
  );
}
