import '../services/gye_service.dart';
import 'generated/app_localizations.dart';

/// [GyeError] → 현지화 메시지. gye 화면들이 공유.
String gyeErrorMessage(AppL10n t, GyeError e) => switch (e) {
      GyeError.network => t.gyeErrNetwork,
      GyeError.notFound => t.gyeErrNotFound,
      GyeError.full => t.gyeErrFull,
      GyeError.tooManyGye => t.gyeErrTooMany,
      GyeError.invalidName => t.gyeErrName,
      GyeError.invalidNickname => t.gyeErrNickname,
      GyeError.profanity => t.gyeErrProfanity,
    };
