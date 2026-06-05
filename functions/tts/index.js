/**
 * 고품질 TTS 동적 합성 — Cloud Function (2nd gen / v2 API)
 * ============================================================================
 * 동적 콘텐츠(책 한 컷 OCR·내 단어장의 사용자 입력 단어)를 Cloud Text-to-Speech
 * 로 합성해 돌려준다. 사전생성된 고정 콘텐츠(526 단어+예문+204 대화)는 클라가
 * Firebase Storage 에서 직접 읽으므로 이 함수를 타지 않는다.
 *
 * 흐름:
 *   1. sha1("{voice}|{text}") 로 키 계산 (클라/사전생성 스크립트와 동일 규칙)
 *   2. Storage `tts/{voice}/{hash}.mp3` 이미 있으면 다운로드해 반환 (재합성 방지)
 *   3. 없으면 Cloud TTS 합성 → Storage 저장(다음 사용자 캐시) → 반환
 *   응답: { audioBase64 }  — 클라가 디코드해 즉시 재생 + 로컬 캐시
 *
 * region = europe-west3 (gye CF·Firestore 와 동일). node 22.
 * 배포:  firebase deploy --only functions:tts-firebase-functions
 * 선행:  Cloud Text-to-Speech API 활성화 + Firebase Storage 활성화 + Blaze.
 * ============================================================================
 */

const { onRequest } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");
const crypto = require("crypto");
const textToSpeech = require("@google-cloud/text-to-speech");

admin.initializeApp();
setGlobalOptions({ region: "europe-west3" });

const ttsClient = new textToSpeech.TextToSpeechClient();

// ⚠️ Firebase Storage 활성화 후 실제 버킷명으로 교정
//    (신형 *.firebasestorage.app / 구형 *.appspot.com). gs:// 없이.
const BUCKET = "ko-lernen-app.firebasestorage.app";

// 클라/사전생성 스크립트와 반드시 동일한 voice 매핑.
const VOICES = {
  female: "ko-KR-Chirp3-HD-Aoede",
  male: "ko-KR-Neural2-C",
};
const RATE = 0.9; // 사전생성과 동일 속도

exports.synthesize_tts = onRequest(
  { cors: true, memory: "256MiB", timeoutSeconds: 30 },
  async (req, res) => {
    try {
      const text = ((req.body && req.body.text) || "").trim();
      const voiceKey = (req.body && req.body.voice) === "male" ? "male" : "female";

      if (!text) {
        res.status(400).json({ error: "empty" });
        return;
      }
      // 동적 합성 abuse 방지 — 학습 단어/짧은 문장만.
      if (text.length > 500) {
        res.status(400).json({ error: "too_long" });
        return;
      }

      const hash = crypto
        .createHash("sha1")
        .update(`${voiceKey}|${text}`)
        .digest("hex");
      const path = `tts/${voiceKey}/${hash}.mp3`;
      const fileRef = admin.storage().bucket(BUCKET).file(path);

      let audioBuffer;
      const [exists] = await fileRef.exists();
      if (exists) {
        const [buf] = await fileRef.download();
        audioBuffer = buf;
      } else {
        const [response] = await ttsClient.synthesizeSpeech({
          input: { text },
          voice: { languageCode: "ko-KR", name: VOICES[voiceKey] },
          audioConfig: { audioEncoding: "MP3", speakingRate: RATE },
        });
        audioBuffer = Buffer.from(response.audioContent);
        await fileRef.save(audioBuffer, {
          contentType: "audio/mpeg",
          resumable: false,
          metadata: { cacheControl: "public, max-age=31536000" },
        });
      }

      res.status(200).json({ audioBase64: audioBuffer.toString("base64") });
    } catch (e) {
      console.error("synthesize_tts error", e);
      res.status(500).json({ error: "synth_failed" });
    }
  }
);
