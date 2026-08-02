/**
 * 고품질 TTS 동적 합성 — Cloud Function (2nd gen / v2 API)
 * ============================================================================
 * 동적 콘텐츠(책 한 컷 OCR·내 단어장의 사용자 입력 단어)를 Cloud Text-to-Speech
 * 로 합성해 돌려준다. 사전생성된 고정 콘텐츠(526 단어+예문+204 대화)는 클라가
 * Firebase Storage 에서 직접 읽으므로 이 함수를 타지 않는다.
 *
 * 흐름:
 *   1. sha1("{voice}|{text}") 로 키 계산 (클라/사전생성 스크립트와 동일 규칙)
 *   2. Storage `tts/v3/{voice}/{hash}.mp3` 이미 있으면 다운로드해 반환 (재합성 방지)
 *   3. 없으면 Cloud TTS 합성 → Storage 저장(다음 사용자 캐시) → 반환
 *   응답: { audioBase64 }  — 클라가 디코드해 즉시 재생 + 로컬 캐시
 *
 * region = europe-west3 (gye CF·Firestore 와 동일). node 22.
 * 배포:  firebase deploy --only functions:tts-firebase-functions
 * 선행:  Cloud Text-to-Speech API 활성화 + Firebase Storage 활성화 + Blaze.
 * ============================================================================
 */

const { HttpsError, onCall } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");
const textToSpeech = require("@google-cloud/text-to-speech");
const { cacheKey } = require("./tts_contract");
const {
  CALLABLE_OPTIONS,
  TtsRequestError,
  validateTtsRequest,
} = require("./tts_request_guard");

admin.initializeApp();
setGlobalOptions({ region: "europe-west3" });

const ttsClient = new textToSpeech.TextToSpeechClient();

// ⚠️ Firebase Storage 활성화 후 실제 버킷명으로 교정
//    (신형 *.firebasestorage.app / 구형 *.appspot.com). gs:// 없이.
const BUCKET = "ko-lernen-app.firebasestorage.app";

// 클라/사전생성 스크립트와 반드시 동일한 voice 매핑.
// male 은 --demo 로 고른 Chirp3-HD 채택본으로 generate_tts.py 와 함께 교체.
const VOICES = {
  female: "ko-KR-Chirp3-HD-Zephyr",
  male: "ko-KR-Chirp3-HD-Enceladus",
};
const RATE = 1.0; // ⚠️ tool/generate_tts.py 의 RATE 와 반드시 동일 (0.9→1.0 자연 속도)

exports.synthesize_tts = onCall(CALLABLE_OPTIONS, async (request) => {
    try {
      const { text, voice } = validateTtsRequest(request);
      const key = cacheKey(voice, text);
      const voiceKey = key.voice;

      const fileRef = admin.storage().bucket(BUCKET).file(key.storagePath);

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

      return { audioBase64: audioBuffer.toString("base64") };
    } catch (e) {
      if (e instanceof TtsRequestError) {
        throw new HttpsError(e.code, e.message);
      }
      if (e instanceof HttpsError) {
        throw e;
      }
      console.error("synthesize_tts error", e);
      throw new HttpsError("internal", "TTS synthesis failed.");
    }
  });
