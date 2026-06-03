import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// **NotificationService (M3)** — tägliche lokale Lern-Erinnerung (Retention).
///
/// Best-effort wie [AuthService]/[PremiumService]: initialisiert leise, wirft
/// nie. Plant eine täglich wiederkehrende Benachrichtigung (`zonedSchedule` +
/// `matchDateTimeComponents.time`) — überlebt App-Neustarts; der Boot-Receiver
/// (AndroidManifest) stellt sie nach einem Reboot wieder her.
///
/// Es werden KEINE Cloud-Dienste genutzt (kein FCM) → keine zusätzlichen
/// Daten verlassen das Gerät; passt zur "no ads / minimal data"-Haltung.
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static const int _dailyId = 1001;
  static const String _channelId = 'daily_reminder';
  static const int _streakSaverId = 1002;
  static const String _streakChannelId = 'streak_saver';

  /// In `main()` aufrufen (best-effort). Initialisiert Plugin + Zeitzonen.
  /// Plant NICHTS — das Planen passiert beim Einschalten in den Einstellungen
  /// (eine einmal geplante tägliche Erinnerung überlebt App-Neustarts).
  static Future<void> init() async {
    if (kIsWeb) return;
    try {
      tzdata.initializeTimeZones();
      try {
        final info = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(info.identifier));
      } catch (_) {
        // Zeitzone nicht ermittelbar → tz.local bleibt UTC. Die Erinnerung
        // kann dann um den UTC-Offset abweichen, aber nichts crasht.
      }
      const android = AndroidInitializationSettings('@mipmap/launcher_icon');
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: darwin),
      );
      _ready = true;
    } catch (e) {
      debugPrint('NotificationService: init skipped — $e');
    }
  }

  /// System-Berechtigung anfragen (Android 13+ / iOS). `true` wenn erlaubt.
  static Future<bool> requestPermission() async {
    if (!_ready) return false;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return await ios.requestPermissions(
                alert: true, badge: true, sound: true) ??
            false;
      }
      return false;
    } catch (e) {
      debugPrint('NotificationService: permission failed — $e');
      return false;
    }
  }

  /// Plant die täglich wiederkehrende Erinnerung um [hour]:[minute].
  /// Ersetzt eine evtl. bestehende (gleiche ID).
  static Future<void> scheduleDaily({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    if (!_ready) return;
    try {
      await _plugin.zonedSchedule(
        _dailyId,
        title,
        body,
        _nextInstanceOf(hour, minute),
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            'Tägliche Erinnerung',
            channelDescription: 'Erinnert dich täglich ans Koreanisch-Lernen.',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // täglich wiederholen
      );
    } catch (e) {
      debugPrint('NotificationService: schedule failed — $e');
    }
  }

  /// Späte Abend-Erinnerung "Streak sichern" — separate ID/Kanal, stärkerer
  /// Retention-Nudge als die normale Tageserinnerung. Ersetzt bestehende.
  static Future<void> scheduleStreakSaver({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    if (!_ready) return;
    try {
      await _plugin.zonedSchedule(
        _streakSaverId,
        title,
        body,
        _nextInstanceOf(hour, minute),
        NotificationDetails(
          android: AndroidNotificationDetails(
            _streakChannelId,
            'Streak-Schutz',
            channelDescription:
                'Erinnert dich abends, deinen Streak zu sichern.',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('NotificationService: streak-saver schedule failed — $e');
    }
  }

  static Future<void> cancelAll() async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  static tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
