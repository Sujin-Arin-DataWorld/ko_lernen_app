#!/usr/bin/env python3
"""책 한 컷 Cloud Function (`analyze_korean_text`) 배포 후 스모크 테스트.

사용:
    python3 functions/analyze_korean_text/smoke_test.py <ENDPOINT_URL> <de|en> \
      --expected-app-id <Firebase App ID>

  <ENDPOINT_URL> = `gcloud functions describe ... --format='value(serviceConfig.uri)'`
  또는 기본 `https://europe-west3-ko-lernen-app.cloudfunctions.net/analyze_korean_text`.

표준 라이브러리만 사용(의존성 0). 배포된 HTTP 엔드포인트에 실제 POST 해서
응답 계약(main.py: words/grammar/sentences/warnings)을 검증한다.
전부 통과 → exit 0, 하나라도 실패 → exit 1 (CI 친화).
"""
import argparse
import base64
import json
import os
import re
import sys
import urllib.error
import urllib.request

DEFAULT_URL = (
    "https://europe-west3-ko-lernen-app.cloudfunctions.net/analyze_korean_text"
)


def app_id_from_app_check_token(token):
    """Read the JWT subject without printing or trusting it as verification.

    The endpoint independently verifies the token signature. This local check
    only proves that an Android or iOS smoke run received the intended
    platform token before any network request is made.
    """
    try:
        segments = token.split(".")
        if len(segments) != 3:
            raise ValueError
        payload = segments[1]
        padding = "=" * (-len(payload) % 4)
        claims = json.loads(base64.urlsafe_b64decode(payload + padding))
        app_id = claims.get("sub")
        if not isinstance(app_id, str) or not app_id:
            raise ValueError
        return app_id
    except (ValueError, TypeError, json.JSONDecodeError) as error:
        raise ValueError("App Check token has no readable app ID claim") from error


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


def tampered_app_check_token(token):
    """Change a significant JWT signature character without logging tokens."""
    if not token:
        return "invalid-app-check-token"
    segments = token.split(".")
    target_index = 2 if len(segments) >= 3 and segments[2] else len(segments) - 1
    segment = segments[target_index]
    if not segment:
        return "invalid-app-check-token"
    char_index = len(segment) // 2
    replacement = "A" if segment[char_index] != "A" else "B"
    segments[target_index] = (
        segment[:char_index] + replacement + segment[char_index + 1:]
    )
    return ".".join(segments)


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
    mark = "PASS" if ok else "FAIL"
    print(f"[{mark}] {name}" + (f" - {detail}" if detail else ""))


def _parser():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("url", nargs="?", default=DEFAULT_URL)
    parser.add_argument("language", nargs="?", default="de")
    parser.add_argument("--expected-app-id", required=True)
    return parser


def main(argv=None):
    _results.clear()
    args = _parser().parse_args(argv)
    url = args.url
    language = args.language.strip().lower()
    if language not in {"de", "en"}:
        print("target language must be 'de' or 'en'", file=sys.stderr)
        return 2
    try:
        signed_headers = credentials_from_environment()
    except RuntimeError as error:
        print(f"authenticated smoke test not started: {error}", file=sys.stderr)
        return 2
    try:
        token_app_id = app_id_from_app_check_token(
            signed_headers["X-Firebase-AppCheck"]
        )
    except ValueError as error:
        print(f"authenticated smoke test not started: {error}", file=sys.stderr)
        return 2
    if token_app_id != args.expected_app_id:
        print(
            "authenticated smoke test not started: "
            "App Check token does not match the expected platform",
            file=sys.stderr,
        )
        return 2
    print(f"POST {url}\n")

    # 1) 혼합 교재 + 선택 번역언어. 할당량을 소모하는 유일한 요청이다.
    st, body = post(
        url,
        {
            "text": "Lesson: 저는 Berlin에 살아요. 저는 학생이에요. "
                    "오늘은 학교에 가요.\n"
                    "Ich wohne in Berlin.\nمرحبا",
            "lang": language,
        },
        headers=signed_headers,
    )
    check("정상 요청 200", st == 200, f"status={st}")
    check(
        "필수 응답 스키마 존재",
        all(
            key in body
            for key in (
                "words", "grammar", "sentences", "warnings", "analysisLanguage"
            )
        ),
    )
    check(
        "analysisLanguage 요청값 일치",
        body.get("analysisLanguage") == language,
        f"received={body.get('analysisLanguage')!r}",
    )
    words = body.get("words", [])
    check("words 비어있지 않음", len(words) > 0, f"{len(words)}개")
    if words:
        w0 = words[0]
        check("word 스키마(korean·pos·translation·example)",
              all(k in w0 for k in ("korean", "pos", "translation", "example")))
        n_trans = sum(1 for w in words if w.get("translation"))
        check(f"DeepL {language} 번역 채워짐(1개 이상)", n_trans > 0,
              f"{n_trans}/{len(words)} - 0이면 DEEPL_API_KEY 확인")
        expected_noun = "Nomen" if language == "de" else "Noun"
        check(
            f"명사 POS 현지화({expected_noun})",
            any(word.get("pos") == expected_noun for word in words),
        )
    sents = body.get("sentences", [])
    check("sentences 분리됨(2개 이상)", len(sents) >= 2, f"{len(sents)}개")
    print(f"   (info) grammar 검출 {len(body.get('grammar', []))}개 "
          "(콘텐츠 의존 - soft)")

    warnings = body.get("warnings", [])
    serialized = json.dumps(body, ensure_ascii=False)
    check(
        "혼합 OCR → 비한국어 구간 필터 경고",
        "non_korean_segments_ignored" in warnings
        and "unexpected_script_filtered" in warnings,
        f"warnings={warnings}",
    )
    check(
        "혼합 OCR → 응답에 Arabic/bidi 문자 없음",
        re.search(r"[\u0600-\u06ff\u202a-\u202e]", serialized) is None,
    )
    mixed_sentences = body.get("sentences", [])
    check(
        "혼합 OCR → 한국어 문장만 반환",
        bool(mixed_sentences)
        and all(
            re.search(r"[\uac00-\ud7a3]", item.get("korean", ""))
            for item in mixed_sentences
        ),
    )

    # 2) 빈 텍스트 → warnings empty_text (200)
    _, body = post(url, {"text": "", "lang": "de"}, headers=signed_headers)
    check("빈 텍스트 → empty_text 경고",
          "empty_text" in body.get("warnings", []),
          f"warnings={body.get('warnings')}")

    # 3) 초과 텍스트 → 400 text_too_long
    st, body = post(
        url, {"text": "가" * 5001, "lang": "de"}, headers=signed_headers
    )
    check("초과 텍스트 → 400 text_too_long",
          st == 400 and "text_too_long" in body.get("warnings", []),
          f"status={st}")

    # 4) 한글 없음 → 언어 엔진/할당량 대신 안전한 종료
    _, body = post(
        url,
        {"text": "Only English.\nمرحبا", "lang": "en"},
        headers=signed_headers,
    )
    check(
        "한글 없음 → no_korean_text",
        "no_korean_text" in body.get("warnings", []),
        f"warnings={body.get('warnings')}",
    )

    # 5) 유효 Auth만 있고 App Check가 없으면 분석 전 401.
    auth_only_headers = {
        "Content-Type": "application/json",
        "Authorization": signed_headers["Authorization"],
    }
    st, body = post(
        url,
        {"text": "학생이에요.", "lang": "de"},
        headers=auth_only_headers,
    )
    check(
        "유효 Auth만 있음 → 401",
        st == 401 and "unauthenticated" in body.get("warnings", []),
        f"status={st}",
    )

    # 6) 유효 App Check만 있고 Auth가 없으면 분석 전 401.
    app_check_only_headers = {
        "Content-Type": "application/json",
        "X-Firebase-AppCheck": signed_headers["X-Firebase-AppCheck"],
    }
    st, body = post(
        url,
        {"text": "학생이에요.", "lang": "de"},
        headers=app_check_only_headers,
    )
    check(
        "유효 App Check만 있음 → 401",
        st == 401 and "unauthenticated" in body.get("warnings", []),
        f"status={st}",
    )

    # 7) 유효 Auth와 변조된 App Check 조합도 분석 전 401.
    tampered_headers = dict(signed_headers)
    tampered_headers["X-Firebase-AppCheck"] = tampered_app_check_token(
        signed_headers["X-Firebase-AppCheck"]
    )
    st, body = post(
        url,
        {"text": "학생이에요.", "lang": "de"},
        headers=tampered_headers,
    )
    check(
        "유효 Auth + 변조 App Check → 401",
        st == 401 and "unauthenticated" in body.get("warnings", []),
        f"status={st}",
    )

    print()
    passed, total = sum(_results), len(_results)
    print(f"{passed}/{total} 통과")
    return 0 if passed == total else 1


if __name__ == "__main__":
    sys.exit(main())
