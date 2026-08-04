# P1 사랑방 아트 — 다운로드 시트 (2026-08-04, URL 재확인본)

이 세션(클라우드 컨테이너)과 기기 VM 둘 다 **`*.supabase.co` 로 나가는 연결이 없다.**
그래서 이 9장은 Jin 이 브라우저로 받아 넣어야 한다. 아래 URL 은 방금
`list_my_generations` 로 **다시 뽑은 현재 값**이다.

> ⚠️ 이전 `P1-SARANGBANG` 메모의 서안·책가도·자개문갑 링크 3개는 **틀렸다.**
> 그대로 눌렀으면 404 였다. 아래 표를 쓸 것.

## 1) 실내 장식 6종 → `assets/illustrations/decorations/_raw/`

| 저장할 이름 | 물건 | 다운로드 |
|---|---|---|
| `decoration_munbangsau.png` | 문방사우 — 붓·벼루·먹·연적·두루마리 | https://uyncfjzfumputmyodmlr.supabase.co/storage/v1/object/public/public-assets/user-e15b6641-5d77-480c-85aa-0c1061b9c2cd/bbanana/gvi_1785839371699_kh2ia.png |
| `decoration_seoan.png` | 서안 — 날개처럼 들린 상판 | https://uyncfjzfumputmyodmlr.supabase.co/storage/v1/object/public/public-assets/user-e15b6641-5d77-480c-85aa-0c1061b9c2cd/bbanana/1785845291219.png |
| `decoration_chaekgado.png` | 책가도 병풍 | https://uyncfjzfumputmyodmlr.supabase.co/storage/v1/object/public/public-assets/user-e15b6641-5d77-480c-85aa-0c1061b9c2cd/bbanana/1785845315915.png |
| `decoration_jagae_mungap.jpg` | 자개 문갑 (**서버가 JPG 로 떨궜다 — 확장자 그대로**) | https://uyncfjzfumputmyodmlr.supabase.co/storage/v1/object/public/public-assets/user-e15b6641-5d77-480c-85aa-0c1061b9c2cd/bbanana/1785845340625.jpg |
| `decoration_gat_buchae.png` | 갓과 부채 | https://uyncfjzfumputmyodmlr.supabase.co/storage/v1/object/public/public-assets/user-e15b6641-5d77-480c-85aa-0c1061b9c2cd/bbanana/gvi_1785839407073_1b2ygb.png |
| `decoration_soban.png` | 소반 | https://uyncfjzfumputmyodmlr.supabase.co/storage/v1/object/public/public-assets/user-e15b6641-5d77-480c-85aa-0c1061b9c2cd/bbanana/gvi_1785839433358_iy9mit.png |

## 2) 보자기 2종 → `assets/illustrations/reward/_raw/`

| 저장할 이름 | 다운로드 |
|---|---|
| `reward_bojagi_closed.png` | https://uyncfjzfumputmyodmlr.supabase.co/storage/v1/object/public/public-assets/user-e15b6641-5d77-480c-85aa-0c1061b9c2cd/bbanana/gvi_1785844599317_cwg88na.png |
| `reward_bojagi_open.png` | https://uyncfjzfumputmyodmlr.supabase.co/storage/v1/object/public/public-assets/user-e15b6641-5d77-480c-85aa-0c1061b9c2cd/bbanana/gvi_1785844605473_7eullb.png |

## 3) 빈 사랑방 → `assets/illustrations/hanok/sarangbang_empty.png`

https://uyncfjzfumputmyodmlr.supabase.co/storage/v1/object/public/public-assets/user-e15b6641-5d77-480c-85aa-0c1061b9c2cd/bbanana/gvi_1785843188666_o97h7h.png

A안(3/4 시점 · 좌측 벽감 · 좌상단 횃대). `kSarangbangSlots` 좌표가 이 그림 기준이다.
컷아웃이 필요 없는 배경이라 `_raw` 를 거치지 않고 바로 `hanok/` 에 넣으면 된다.

**11:50 에 만든 두 장(`gvi_1785844200382_8aj7ng`, `gvi_1785844208455_rm2g4s`)은 쓰지 말 것** —
그건 실루엣/마커 비교용 목업이라 방 위에 UI 가 그려져 있다.

---

## 넣은 뒤

```bash
python3 tool/decoration_normalize.py
```

흰 배경 플러드필 → 투명화 → 트림 → 긴 변 1254 제한 + 3% 여백.
**정사각으로 안 맞춘다** — 기존 장식이 제각각이고 슬롯이 폭만 맞추기 때문이다.

그다음 내가 할 일 (한 커밋으로 묶는다):

1. `kAvailableDecorations` 에 6줄 추가 — 안 넣으면 `Image.asset` 을 시도조차 안 하고
   조용히 placeholder 가 뜬다. 눈으로는 못 잡는 버그라 `decoration_slot_test` 가
   **파일 ↔ 화이트리스트 양방향**으로 막고 있다 (지금은 일부러 red 가 된다)
2. `test/data_integrity_test.dart` 의 `pending` 집합에서 3줄 제거
   (`sarangbang_empty.png` · `reward_bojagi_closed.png` · `reward_bojagi_open.png`)
3. 8종 컨택트시트로 눈 검수 — **`gat_buchae` 와 `soban` 두 장은 내가 아직 못 봤다.**
   나머지는 확인했다

## 못 하면 대안

링크가 죽었거나 받기 번거로우면 말해줘. bbanana2 호출 자체는 이 세션에서 되니까
같은 프롬프트로 다시 뽑아 새 링크를 줄 수 있다. 다만 **받아서 넣는 건 어느 쪽이든
Jin 손이 필요하다** — 이 컨테이너에서 supabase 로 나가는 길이 막혀 있다.
