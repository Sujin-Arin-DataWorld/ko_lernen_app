import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'auth_service.dart';
import 'notification_service.dart';

/// **PushService** — FCM 푸시(계 피드 알림, 예: 주간목표 달성).
///
/// best-effort: 권한 거부/Firebase 미설정/웹이면 조용히 무동작(throw 안 함).
/// FCM 등록 토큰을 `users/{uid}.fcmTokens`(array)에 저장 → `functions/gye`의
/// `weekly_goal_rollover`가 멤버 토큰을 모아 멀티캐스트.
///
/// ⚠️ **정책 전환**: [NotificationService]는 의도적으로 FCM을 안 썼다(no-FCM,
/// 데이터 최소화). 계 커뮤니티 알림을 위해 Jin 승인 하에 도입.
/// **iOS는 APNs 설정 필요**(Xcode "Push Notifications" capability + APNs 키).
/// 데이터: FCM 등록 토큰(기기 식별자)이 전송됨 → `docs/store/data-safety.md` 갱신.
class PushService {
  PushService._();

  static bool _ready = false;
  static bool get isReady => _ready;

  /// main()에서 best-effort 호출. 권한 요청 + 토큰 저장 + 포그라운드 핸들러.
  static Future<void> init() async {
    if (kIsWeb) {
      return; // 웹 FCM은 별도 SW 설정 필요 — 범위 외.
    }
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return; // 사용자가 거부 → 푸시 없음(앱은 정상).
      }

      // 포그라운드 수신 → 로컬 알림으로 표시(NotificationService 재사용).
      FirebaseMessaging.onMessage.listen((msg) {
        final n = msg.notification;
        if (n != null) {
          NotificationService.showNow(
            title: n.title ?? 'Hangul Sori',
            body: n.body ?? '',
          );
        }
      });

      final token = await messaging.getToken();
      if (token != null) {
        await _persistToken(token);
      }
      messaging.onTokenRefresh.listen(_persistToken);
      _ready = true;
    } catch (e) {
      debugPrint('PushService: init skipped — $e');
    }
  }

  /// 현재 사용자 문서에 토큰 추가(중복은 arrayUnion이 흡수).
  static Future<void> _persistToken(String token) async {
    final uid = AuthService.current?.uid;
    if (uid == null) {
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {
          'fcmTokens': FieldValue.arrayUnion([token]),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('PushService: token persist skipped — $e');
    }
  }

  /// 로그아웃/계정 전환 시 현재 토큰 제거(다른 사용자에게 알림 안 가게).
  static Future<void> removeToken() async {
    final uid = AuthService.current?.uid;
    if (uid == null) {
      return;
    }
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        return;
      }
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {
          'fcmTokens': FieldValue.arrayRemove([token]),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('PushService: token remove skipped — $e');
    }
  }
}
