# Privacy Policy — Hangul Sori (Koreanisch lernen App)

**Effective Date:** 2026-05-20
**Last Updated:** 2026-05-20

---

> ⚠️ **사용자 작업 필요:**
> 1. 이 파일을 `privacy.html`로 변환 (Markdown→HTML 변환기, 예: pandoc 또는 markdowntohtml.com)
> 2. 무료 호스팅 옵션 중 하나에 업로드:
>    - **Termly** (https://termly.io) — Generator 무료 + 호스팅 무료
>    - **GitHub Pages** (이미 있는 repo) — `docs/privacy.html` 또는 `gh-pages` 브랜치
>    - **Notion** public page → `Share to web`
>    - **Vercel/Netlify** 무료
> 3. URL: `https://hangul-sori.com/privacy` — Cloudflare Pages 무료 호스팅 사용 (도메인 hangul-sori.com 등록 완료)

---

## English Version

### 1. Introduction

This Privacy Policy describes how **Hangul Sori** ("we", "our", or "the App"), developed by **Sujin Arin DataWorld** (Frankfurt am Main, Germany), collects, uses, and protects your information when you use our mobile application.

By using Hangul Sori, you agree to the practices described in this policy.

### 2. Data We Collect

#### 2.1 Stored Locally on Your Device (Always)
The following data is stored **only on your device** using Android SharedPreferences and never leaves your phone unless you explicitly enable Cloud Sync:

- Learning progress (vocabulary cards seen, "got it / didn't get it" counts)
- Game scores (Hangul Wordle, Initial Consonant Quiz)
- Learning streak (consecutive days using the app)
- Spaced Repetition System (SRS) state per vocabulary item
- App preferences (UI language, TTS speed)
- Selected CEFR level (A1 – B2)

#### 2.2 Anonymous Authentication (Automatic)
On first launch, Hangul Sori creates an **anonymous Firebase user ID** to enable optional cloud features. This ID is:
- A random string (e.g., `1kbImEZQRaZ80OxIrmKH0LN5dBI2`)
- Not linked to any personal information
- Used only as a backend identifier
- Stored by Google Firebase (Frankfurt, EU servers)

#### 2.3 Optional: Cloud Sync via Google Sign-In
If you choose to enable Cloud Backup in Settings, we collect:
- Your Google account email address
- Your Google display name
- A link between your anonymous ID and your Google account

This is used solely to restore your learning progress when you switch devices. We do not use this data for marketing, profiling, or sharing with third parties.

#### 2.4 Cloud-Stored Data (Only If You Enable Sync)
When Cloud Sync is enabled, the same learning data listed in §2.1 is backed up to **Google Firestore** (Frankfurt region, EU servers) under your user ID. You can disable sync and delete cloud data anytime in Settings.

#### 2.5 What We Do NOT Collect
- ❌ Your real name (beyond optional Google display name)
- ❌ Phone number
- ❌ Location data
- ❌ Photos, contacts, files, microphone
- ❌ Browsing history outside the app
- ❌ Advertising IDs (this version has no ads)

### 3. Third-Party Services

Hangul Sori uses the following third-party services:

| Service | Provider | Purpose | Data Shared |
|---|---|---|---|
| Firebase Authentication | Google LLC | Anonymous + Google login | Anonymous UID, optional email |
| Firebase Firestore | Google LLC | Cloud backup of learning data | Encrypted learning progress |
| Firebase Analytics | **Disabled** | — | None |
| Google Sign-In | Google LLC | OAuth flow | Email, display name |
| flutter_tts (Text-to-Speech) | Native Android TTS | Korean pronunciation | None — runs offline |
| AdMob | Google LLC | **Disabled in this version** | None |

Google's Privacy Policy applies to Firebase data: https://policies.google.com/privacy

### 4. Data Retention

- **On-device data**: Retained until you uninstall the app or use "Reset" in Settings
- **Anonymous Firebase user**: Retained indefinitely unless deleted via Settings → "Delete cloud data"
- **Google-linked account data**: Retained until you sign out + delete cloud data, or until you delete your Google account

### 5. Your Rights (GDPR — applicable to all users)

You have the right to:
- **Access** all data we store about you (anonymous UID + cloud-synced learning data)
- **Rectify** incorrect data (within the app)
- **Delete** your data:
  - On-device: Settings → "Reset"
  - Cloud: Settings → "Delete cloud data" (deletes Firestore entry + Firebase user)
- **Restrict processing**: Disable Cloud Sync in Settings
- **Data portability**: Contact us for an export of your data
- **Withdraw consent**: Disable features anytime in Settings
- **Lodge a complaint**: with your national data protection authority

### 6. Children's Privacy (COPPA + GDPR Article 8)

Hangul Sori is rated for general audiences. We do not knowingly collect data from children under 13 (US) / 16 (EU). The Google Sign-In feature requires an age-eligible Google account.

If you are a parent and believe your child has provided us with personal information, please contact us to have it removed.

### 7. Security

- All data transmission to Firebase uses TLS 1.3 encryption
- Firestore data is encrypted at rest (Google-managed encryption)
- Local data is stored in app-private storage (not accessible by other apps)
- We do not store passwords — Google handles all authentication

### 8. International Data Transfers

Firebase services are hosted in **Frankfurt, Germany (europe-west3 region)** by default for EU users. For users outside the EU, data may be processed in Google's global infrastructure under Standard Contractual Clauses (SCC).

### 9. Changes to This Policy

We may update this Privacy Policy. Changes will be reflected in the "Last Updated" date above. Material changes will be notified in-app.

### 10. Contact

**Data Controller:**
Sujin Park (Sujin Arin DataWorld)
Frankfurt am Main, Germany
Email: **hello@hangul-sori.com**

---

---

## Deutsche Version

### 1. Einleitung

Diese Datenschutzerklärung beschreibt, wie **Hangul Sori** ("wir", "uns" oder "die App"), entwickelt von **Sujin Arin DataWorld** (Frankfurt am Main, Deutschland), Ihre Informationen bei der Nutzung unserer mobilen Anwendung erhebt, verwendet und schützt.

Durch die Nutzung von Hangul Sori stimmen Sie den in dieser Richtlinie beschriebenen Praktiken zu.

### 2. Erhobene Daten

#### 2.1 Lokal auf Ihrem Gerät gespeichert (immer)
Folgende Daten werden ausschließlich auf Ihrem Gerät über Android SharedPreferences gespeichert und verlassen Ihr Telefon nicht, es sei denn, Sie aktivieren ausdrücklich Cloud Sync:

- Lernfortschritt (gesehene Vokabelkarten, "Gewusst / Nicht gewusst"-Zählungen)
- Spielergebnisse (Hangul Wordle, Initialkonsonanten-Quiz)
- Lern-Streak (aufeinanderfolgende Tage)
- SRS-Status (Spaced Repetition) pro Vokabel
- App-Einstellungen (UI-Sprache, TTS-Geschwindigkeit)
- Gewähltes Sprachniveau (A1 – B2)

#### 2.2 Anonyme Authentifizierung (automatisch)
Beim ersten Start erstellt Hangul Sori eine **anonyme Firebase-User-ID**, um optionale Cloud-Funktionen zu ermöglichen. Diese ID:
- Ist eine zufällige Zeichenkette
- Ist nicht mit persönlichen Informationen verknüpft
- Dient ausschließlich als Backend-Identifikator
- Wird von Google Firebase gespeichert (Frankfurt, EU-Server)

#### 2.3 Optional: Cloud Sync via Google-Anmeldung
Wenn Sie Cloud-Backup in den Einstellungen aktivieren, erheben wir:
- Ihre Google-Konto-E-Mail-Adresse
- Ihren Google-Anzeigenamen
- Eine Verknüpfung zwischen anonymer ID und Google-Konto

Dies dient ausschließlich der Wiederherstellung Ihres Lernfortschritts bei Gerätewechsel. Wir verwenden diese Daten **nicht** für Marketing, Profilbildung oder Weitergabe an Dritte.

#### 2.4 In der Cloud gespeicherte Daten (nur bei aktivem Sync)
Bei aktiviertem Cloud Sync werden die in §2.1 genannten Lerndaten in **Google Firestore** (Frankfurt, EU) unter Ihrer User-ID gesichert. Sie können den Sync jederzeit deaktivieren und Cloud-Daten löschen.

#### 2.5 Was wir NICHT erheben
- ❌ Ihren echten Namen (außer optionalem Google-Anzeigenamen)
- ❌ Telefonnummer
- ❌ Standortdaten
- ❌ Fotos, Kontakte, Dateien, Mikrofon
- ❌ Browserverlauf außerhalb der App
- ❌ Werbe-IDs (diese Version enthält keine Werbung)

### 3. Drittanbieter

Hangul Sori verwendet folgende Drittanbieter:

| Dienst | Anbieter | Zweck | Übermittelte Daten |
|---|---|---|---|
| Firebase Authentication | Google LLC | Anonyme + Google-Anmeldung | Anonyme UID, optional E-Mail |
| Firebase Firestore | Google LLC | Cloud-Backup der Lerndaten | Verschlüsselte Lernfortschritte |
| Firebase Analytics | **Deaktiviert** | — | Keine |
| Google Sign-In | Google LLC | OAuth-Flow | E-Mail, Anzeigename |
| flutter_tts | Native Android TTS | Koreanische Aussprache | Keine — läuft offline |
| AdMob | Google LLC | **In dieser Version deaktiviert** | Keine |

Es gilt die Google-Datenschutzerklärung: https://policies.google.com/privacy

### 4. Speicherdauer

- **Gerätelokale Daten**: Bis zur Deinstallation oder "Zurücksetzen" in Einstellungen
- **Anonymer Firebase-User**: Unbegrenzt, bis "Cloud-Daten löschen" verwendet wird
- **Google-verknüpfte Daten**: Bis zur Abmeldung + Cloud-Löschung oder Google-Konto-Löschung

### 5. Ihre Rechte (DSGVO)

Sie haben das Recht auf:
- **Auskunft** über alle gespeicherten Daten
- **Berichtigung** falscher Daten (innerhalb der App)
- **Löschung** Ihrer Daten:
  - Lokal: Einstellungen → "Zurücksetzen"
  - Cloud: Einstellungen → "Cloud-Daten löschen"
- **Einschränkung der Verarbeitung**: Cloud Sync deaktivieren
- **Datenübertragbarkeit**: Kontaktieren Sie uns für einen Export
- **Widerruf der Einwilligung**: Funktionen jederzeit deaktivieren
- **Beschwerderecht** bei der zuständigen Datenschutzbehörde

### 6. Datenschutz von Kindern (DSGVO Art. 8 + COPPA)

Hangul Sori ist für alle Altersgruppen freigegeben. Wir erheben wissentlich keine Daten von Kindern unter 13 (USA) / 16 (EU). Die Google-Anmeldung erfordert ein altersberechtigtes Google-Konto.

Eltern können uns kontaktieren, um Daten ihrer Kinder löschen zu lassen.

### 7. Sicherheit

- Alle Datenübertragungen zu Firebase verwenden TLS 1.3-Verschlüsselung
- Firestore-Daten werden im Ruhezustand verschlüsselt
- Lokale Daten werden im App-privaten Speicher gehalten
- Wir speichern keine Passwörter — Google übernimmt die Authentifizierung

### 8. Internationale Datenübertragung

Firebase-Dienste werden standardmäßig in **Frankfurt, Deutschland (europe-west3)** für EU-Nutzer gehostet. Für Nutzer außerhalb der EU kann eine Verarbeitung in Googles globaler Infrastruktur unter Standardvertragsklauseln (SCC) erfolgen.

### 9. Änderungen dieser Richtlinie

Wir können diese Datenschutzerklärung aktualisieren. Änderungen werden im Datum "Last Updated" oben angezeigt. Wesentliche Änderungen werden in der App mitgeteilt.

### 10. Kontakt

**Verantwortlicher (Art. 4 Nr. 7 DSGVO):**
Sujin Park (Sujin Arin DataWorld)
Frankfurt am Main, Deutschland
E-Mail: **hello@hangul-sori.com**

---

## 한국어 요약 (informativ — nicht rechtsverbindlich)

한글소리(Hangul Sori)는 다음을 수집합니다:
- 학습 진도 (기기 내 저장만, 클라우드 동기화는 선택)
- 게임 점수, Streak, SRS 상태
- 익명 Firebase ID (자동 생성, 개인 정보 아님)
- Google 로그인 시: 이메일, 이름 (선택 사항, 백업용)

수집하지 않는 것: 위치, 사진, 연락처, 마이크, 광고 ID.

데이터 서버: Frankfurt (EU). 모든 권리(접근, 삭제, 이전) 보장. 문의: hello@hangul-sori.com
