import 'package:flutter/material.dart';
import '../models/course_mastery.dart';
import '../models/curriculum.dart';
import '../motion/transitions.dart';
import '../screens/first_voice_success_screen.dart';
import 'course_progress_service.dart';
import 'curriculum_catalog.dart';
import 'onboarding_companion_service.dart';
import 'storage_service.dart';

/// Shared post-attempt invitation; callers control the real return boundary.
abstract final class CourseAttemptCompanion {
  static Future<void> offer(
    BuildContext context, {
    required CourseUnit unit,
    required Set<String> evidenceIdsBefore,
    CourseMasterySnapshot? after,
    Iterable<ContentLink>? links,
  }) async {
    final snapshot =
        after ?? await CourseProgressService.shared.readForDisplay();
    if (snapshot == null || !context.mounted) {
      return;
    }
    final contentLinks = links ?? (await CurriculumCatalog.load()).contentLinks;
    if (!context.mounted ||
        !OnboardingCompanionService.shouldOfferAfterAttempt(
          introPreviewSeen: Storage.introPreviewSeen,
          activeCourseUnitId: unit.id,
          activeCourseLevel: unit.level,
          evidenceIdsBefore: evidenceIdsBefore,
          evidenceAfter: snapshot.evidence,
          contentLinks: contentLinks.toList(),
        )) {
      return;
    }
    final language = Localizations.localeOf(context).languageCode;
    await Navigator.of(context).push<void>(
      SoriTransitions.page<void>(
        (_) => FirstVoiceSuccessScreen(canDo: unit.canDo.pick(language)),
      ),
    );
  }
}
