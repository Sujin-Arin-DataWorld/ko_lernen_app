#!/usr/bin/env python3
"""책 한 컷 Cloud Function (`analyze_korean_text`) 배포 후 스모크 테스트.

사용:
    python3 functions/analyze_korean_text/smoke_test.py <ENDPOINT_URL>

  <ENDPOINT_URL> = `gcloud functions describe ... --format='value(serviceConfig.uri)'`
  또는 기본 `https://europe-west3-ko-lernen-app.cloudfunctions.net/analyze_korean_text`.

표준 라이브러리만 사용(의존성 0). 배포된 HTTP 엔드포인트에 실제 POST 해서
응답 계약(main.py: words/grammar/sentences/warnings)을 검증한다.
전부 통과 → exit 0, 하나라도 실패 → exit 1 (CI 친화).
"""
import json
import os
import sys
import urllib.error
import urllib.request

DEFAULT_URL = (
    "https://europe-west3-ko-lernen-app.cloudfunctions.net/analyze_korean_text"
)


def request_headers(id_token, app_check_token):
    """Return the two credentials required by the production endpoint."""
    return {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {id_token}",
        "X-Firebase-AppCheck": app_check_token,
    }


def credentials_from_environment():
    """Read test credentials without ever printing them to the console."""
    id_token = os.environ.get("BOOK_ANALYSIS_ID_TOKEN", "").strip()
    app_check_token = os.environ.get("BOOK_ANALYSIS_APP_CHECK_TOKEN", "").strip()
    if not id_token or not app_check_token:
        raise RuntimeError(
            "Set BOOK_ANALYSIS_ID_TOKEN and BOOK_ANALYSIS_APP_CHECK_TOKEN "
            "from a signed test app before running the authenticated smoke test."
        )
    return request_headers(id_token, app_check_token)


def post(url, payload, headers=None, timeout=40):
    if headers is None:
        headers = credentials_from_environment()
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        url, data=data,
        headers=headers, method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.status, json.loads(r.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        raw = e.read().decode("utf-8", "replace")
        try:
            return e.code, json.loads(raw)
        except json.JSONDecodeError:
            return e.code, {"_raw": raw}
    except Exception as e:  # noqa: BLE001
        return 0, {"_error": str(e)}


_results = []


def check(name, ok, detail=""):
    _results.append(bool(ok))
    mark = "✅" if ok else "❌"
    print(f"{mark} {name}" + (f" — {detail}" if detail else ""))


def main():
    url = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_URL
    try:
        credentials_from_environment()
    except RuntimeError as error:
        print(f"authenticated smoke test not started: {error}", file=sys.stderr)
        return 2
    print(f"→ POST {url}\n")

    # 1) 정상 독일어 요청
    st, body = post(url, {"text": "저는 학생이에요. 오늘 날씨가 좋아요.", "lang": "de"})
    check("정상 요청 200", st == 200, f"status={st}")
    check("words/grammar/sentences 키 존재",
          all(k in body for k in ("words", "grammar", "sentences")))
    words = body.get("words", [])
    check("words 비어있지 않음", len(words) > 0, f"{len(words)}개")
    if words:
        w0 = words[0]
        check("word 스키마(korean·pos·translation·example)",
              all(k in w0 for k in ("korean", "pos", "translation", "example")))
        n_trans = sum(1 for w in words if w.get("translation"))
        check("DeepL 번역 채워짐(≥1)", n_trans > 0,
              f"{n_trans}/{len(words)} — 0이면 DEEPL_API_KEY 확인")
    sents = body.get("sentences", [])
    check("sentences 분리됨(≥2)", len(sents) >= 2, f"{len(sents)}개")
    print(f"   (info) grammar 검출 {len(body.get('grammar', []))}개 "
          "(콘텐츠 의존 — soft)")

    # 2) 영어 요청
    _, body = post(url, {"text": "감사합니다. 안녕히 가세요.", "lang": "en"})
    en_words = body.get("words", [])
    check("영어 요청 번역(≥1)",
          any(w.get("translation") for w in en_words),
          f"{sum(1 for w in en_words if w.get('translation'))}개 번역")

    # 3) 빈 텍스트 → warnings empty_text (200)
    _, body = post(url, {"text": "", "lang": "de"})
    check("빈 텍스트 → empty_text 경고",
          "empty_text" in body.get("warnings", []),
          f"warnings={body.get('warnings')}")

    # 4) 초과 텍스트 → 400 text_too_long
    st, body = post(url, {"text": "가" * 5001, "lang": "de"})
    check("초과 텍스트 → 400 text_too_long",
          st == 400 and "text_too_long" in body.get("warnings", []),
          f"status={st}")

    print()
    passed, total = sum(_results), len(_results)
    print(f"{passed}/{total} 통과")
    return 0 if passed == total else 1


if __name__ == "__main__":
    sys.exit(main())
