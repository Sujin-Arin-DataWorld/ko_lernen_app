/**
 * 고품질 TTS 동적 합성 — Cloud Function (2nd gen / v2 API)
 * ============================================================================
 * 동적 콘텐츠(책 한 컷 OCR·내 단어장의 사용자 입력 단어)를 Cloud Text-to-Speech
 * 로 합성해 돌려준다. 사전생성된 고정 콘텐츠(526 단어+예문+204 대화)는 클라가
 * Firebase Storage 에서 직접 읽으므로 이 함수를 타지 않는다.
 *
 * 흐름:
 *   1. sha1("{voice}|{text}") 로 키 계산 (클라/사전생성 스크립트와 동일 규칙)
 *   2. 승인 코퍼스만 `tts/v3`; 개인 음성은 UID 전용 `tts_private`와 24h 만료
 *   3. 없으면 service_idempotency 를 선점한 승자만 한도를 깎고 Cloud TTS 를 부른다
 *   4. 동시 재시도는 Storage 를 잠시 기다렸다가, 없으면 합성 없이 503
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
const { scopedCacheKey, privateMetadataIsCurrent, cacheSaveOptions } = require("./tts_privacy");
const { ServiceCostError } = require("./service_cost_policy");
const { confirmTtsCost } = require("./tts_cost_adapter");
const {
  CALLABLE_OPTIONS,
  SYNTH_DEADLINE_MS,
  TtsRequestError,
  abandonTtsReplay,
  claimTtsReplay,
  completeTtsReplay,
  isUsableAudioBuffer,
  refundDailyTtsQuotas,
  ttsLogErrorCode,
  ttsProviderBreaker,
  ttsSynthesisPlan,
  validateTtsRequest,
  underDailyTtsQuotas,
  withDeadline,
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
const INFLIGHT_POLL_ATTEMPTS = 14;
const INFLIGHT_POLL_MS = 500;

function sleep(ms) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}

async function loadUsableAudio(fileRef, key) {
  const [exists] = await fileRef.exists();
  if (!exists) {
    return null;
  }
  if (!key.isCanonical) {
    const [metadata] = await fileRef.getMetadata();
    if (!privateMetadataIsCurrent(metadata)) {
      return null;
    }
  }
  const [buf] = await fileRef.download();
  if (isUsableAudioBuffer(buf)) {
    return buf;
  }
  try {
    await fileRef.delete();
  } catch {
    // Empty or corrupt objects must not be replayed as a cache hit.
  }
  return null;
}

async function waitForUsableAudio(fileRef, key) {
  for (let attempt = 0; attempt < INFLIGHT_POLL_ATTEMPTS; attempt += 1) {
    await sleep(INFLIGHT_POLL_MS);
    const audioBuffer = await loadUsableAudio(fileRef, key);
    if (isUsableAudioBuffer(audioBuffer)) {
      return audioBuffer;
    }
  }
  return null;
}

async function synthesizeSpeech(text, voiceKey) {
  const [response] = await withDeadline(
    ttsClient.synthesizeSpeech(
      {
        input: { text },
        voice: { languageCode: "ko-KR", name: VOICES[voiceKey] },
        audioConfig: { audioEncoding: "MP3", speakingRate: RATE },
      },
      { timeout: SYNTH_DEADLINE_MS },
    ),
    SYNTH_DEADLINE_MS,
  );
  const audioBuffer = Buffer.from(response.audioContent || []);
  if (!isUsableAudioBuffer(audioBuffer)) {
    throw new Error("empty TTS audio");
  }
  return audioBuffer;
}

async function synthesizeTts(request) {
    try {
      const { text, voice, installationId } = validateTtsRequest(request);

      const key = scopedCacheKey(request.auth.uid, voice, text);
      const voiceKey = key.voice;
      const db = admin.firestore();
      const fileRef = admin.storage().bucket(BUCKET).file(key.storagePath);
      const assertAccountActive = async () => {
        const marker = await db.collection("account_deletions").doc(request.auth.uid).get();
        if (marker.exists) {
          throw new HttpsError("failed-precondition", "Account deletion is in progress.");
        }
      };
      const responseFor = async (bytes) => {
        await assertAccountActive();
        if (key.isCanonical) return { audioBase64: bytes.toString("base64"), cacheScope: "canonical" };
        const [metadata] = await fileRef.getMetadata();
        if (!privateMetadataIsCurrent(metadata)) {
          throw new HttpsError("unavailable", "TTS audio is not available.");
        }
        await assertAccountActive();
        return { audioBase64: bytes.toString("base64"), cacheScope: "private",
          expiresAtMillis: Number(metadata.metadata.expiresAtMillis) };
      };
      await assertAccountActive();

      let audioBuffer = await loadUsableAudio(fileRef, key);
      if (isUsableAudioBuffer(audioBuffer)) {
        return await responseFor(audioBuffer);
      }

      let claim;
      try {
        claim = await claimTtsReplay(db, key.storagePath);
      } catch {
        throw new HttpsError(
          "unavailable",
          "TTS synthesis is temporarily unavailable.",
        );
      }
      const consume = claim.consume;

      if (!ttsProviderBreaker.allow()) {
        if (consume) {
          try {
            await abandonTtsReplay(db, key.storagePath);
          } catch {
            // Keep the circuit error; the pending receipt expires.
          }
        }
        throw new HttpsError(
          "unavailable",
          "TTS synthesis is temporarily unavailable.",
        );
      }

      let costReservation;
      if (consume) {
        let quota;
        try {
          quota = await underDailyTtsQuotas(db, {
            uid: request.auth.uid,
            installationId,
          });
        } catch (error) {
          // No synthesis has begun. Release only this undispatched replay lock;
          // a possibly committed cost transaction is deliberately never refunded.
          try { await abandonTtsReplay(db, key.storagePath); } catch { /* bounded receipt TTL */ }
          throw error;
        }
        costReservation = quota.costReservation;
        if (!quota.allowed) {
          try {
            await abandonTtsReplay(db, key.storagePath);
          } catch {
            // Keep the quota error; the pending receipt expires.
          }
          console.warn("Daily TTS synthesis limit reached", {
            scope: quota.exceededScope,
          });
          throw new HttpsError(
            "resource-exhausted",
            "Daily synthesis limit reached.",
          );
        }
      }

      audioBuffer = await loadUsableAudio(fileRef, key);
      let plan = ttsSynthesisPlan(claim, isUsableAudioBuffer(audioBuffer));
      if (plan.action === "wait") {
        audioBuffer = await waitForUsableAudio(fileRef, key);
        plan = ttsSynthesisPlan(claim, isUsableAudioBuffer(audioBuffer));
      }
      if (plan.action === "wait") {
        if (plan.reason === "pending") {
          throw new HttpsError(
            "unavailable",
            "TTS synthesis is already in progress.",
          );
        }
        throw new HttpsError(
          "unavailable",
          "TTS audio is not available.",
        );
      }

      try {
        if (plan.action === "return") {
          if (plan.refund) {
            try {
              await refundDailyTtsQuotas(db, {
                uid: request.auth.uid,
                installationId,
              });
            } catch {
              console.warn("TTS quota refund failed", {
                scope: "tts",
              });
            }
          }
        } else {
          await confirmTtsCost(db, costReservation);
          await assertAccountActive();
          audioBuffer = await synthesizeSpeech(text, voiceKey);
          await assertAccountActive();
          await fileRef.save(audioBuffer, cacheSaveOptions(key));
          try {
            await assertAccountActive();
          } catch (error) {
            if (!key.isCanonical) {
              // Storage cannot join a Firestore transaction. Close the save race
              // before responding; denied direct reads + TTL remain fail-closed
              // if the compensating delete itself transiently fails.
              await fileRef.delete({ ignoreNotFound: true });
            }
            throw error;
          }
          ttsProviderBreaker.recordSuccess();
        }
        try {
          await completeTtsReplay(db, key.storagePath);
        } catch {
          // Storage already has the usable object; the receipt is optional.
        }
      } catch (error) {
        ttsProviderBreaker.recordFailure();
        if (consume) {
          try {
            await refundDailyTtsQuotas(db, {
              uid: request.auth.uid,
              installationId,
            });
          } catch {
            console.warn("TTS quota refund failed", {
              scope: "tts",
            });
          }
          try {
            await abandonTtsReplay(db, key.storagePath);
          } catch {
            // Keep the original provider failure.
          }
        }
        throw error;
      }

      try {
        return await responseFor(audioBuffer);
      } catch (error) {
        if (!key.isCanonical) {
          try {
            await fileRef.delete({ ignoreNotFound: true });
          } catch {
            // Direct reads remain denied and the lifecycle rule expires residue.
          }
        }
        throw error;
      }
    } catch (e) {
      if (e instanceof TtsRequestError || e instanceof ServiceCostError) {
        throw new HttpsError(e.code, e.message);
      }
      if (e instanceof HttpsError) {
        throw e;
      }
      console.error("synthesize_tts error", ttsLogErrorCode(e));
      throw new HttpsError("internal", "TTS synthesis failed.");
    }
}

// 새 앱의 정본 이름과 이미 배포된 구버전 별칭에 같은 제한을 적용해 어느
// 엔드포인트로도 일일 한도를 우회할 수 없게 한다.
exports.synthesize_tts = onCall(CALLABLE_OPTIONS, synthesizeTts);
exports.synthesize_tts_v2 = onCall(CALLABLE_OPTIONS, synthesizeTts);
