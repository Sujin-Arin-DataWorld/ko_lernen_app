import 'package:flutter/widgets.dart';

import '../../services/storage_service.dart';
import 'spotlight_coach.dart';

/// 콘텐츠 화면 첫 진입 사용법 스포트라이트 코치마크 공통 믹스인.
///
/// 화면 적용:
///   (a) `class _XState extends State<X> with ScreenCoachMixin<X>`
///   (b) [coachId] 선언 (= storage 키 접미. `Storage.kScreenCoachIds`에 등록)
///   (c) 타겟 위젯에 GlobalKey 부착(key: 또는 KeyedSubtree)
///   (d) [buildCoachSteps] 구현 (1~3 SpotlightStep)
///   (e) initState에서 [scheduleCoach] 1회 호출
/// async 로드 화면은 [coachReady]를 override해 타겟이 빌드된 뒤 발화하게 한다.
///
/// 가드 3중: 프로세스 세션 1회([_firedThisSession]) + 영구 플래그
/// ([Storage.tutSeen]) + postFrame `mounted` 재확인. 또 spotlight 엔진이 측정
/// 불가 타겟을 자동 skip하므로 스크롤/탭 밖 타겟도 안전(빈 단계면 표시 안 함).
mixin ScreenCoachMixin<T extends StatefulWidget> on State<T> {
  // 같은 세션에 화면을 다시 들어가도(새 State) 재발화 안 함 — 프로세스 전역.
  static final Set<String> _firedThisSession = <String>{};
  static int _tutorialResetRevision = Storage.tutorialResetRevision;

  void _syncTutorialReset() {
    final revision = Storage.tutorialResetRevision;
    if (_tutorialResetRevision != revision) {
      _tutorialResetRevision = revision;
      _firedThisSession.clear();
    }
  }

  /// storage 키 접미. `Storage.kScreenCoachIds`에 반드시 등록.
  String get coachId;

  /// 이 화면의 스포트라이트 단계들. 빈 리스트면 표시 안 함.
  List<SpotlightStep> buildCoachSteps(BuildContext context);

  /// 타겟이 빌드돼 측정 가능할 때 true. async 로드 화면은 override.
  bool get coachReady => true;

  int _coachPolls = 0;

  /// initState에서 1회 호출 — 첫 진입·미표시면 다음 프레임에 코치마크 예약.
  void scheduleCoach() {
    _syncTutorialReset();
    assert(
      Storage.kScreenCoachIds.contains(coachId),
      'coachId "$coachId" missing from Storage.kScreenCoachIds',
    );
    if (_firedThisSession.contains(coachId) || Storage.tutSeen(coachId)) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryShow());
  }

  void _tryShow() {
    _syncTutorialReset();
    if (!mounted ||
        _firedThisSession.contains(coachId) ||
        Storage.tutSeen(coachId)) {
      return;
    }
    if (!coachReady) {
      // 타겟이 아직 안 뜸 — 다음 프레임 재시도(최대 ~3초, 화면 이탈 시 mounted로 정지).
      if (_coachPolls++ > 180) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryShow());
      return;
    }
    final steps = buildCoachSteps(context);
    if (steps.isEmpty) {
      return;
    }
    _firedThisSession.add(coachId);
    SpotlightCoach.show(
      context,
      steps: steps,
      onComplete: () => Storage.setTutSeen(coachId),
    );
  }
}
