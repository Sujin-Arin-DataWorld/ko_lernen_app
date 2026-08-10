import 'curriculum.dart';

/// A read-only view of every graph link in one course mission. The planner
/// keeps catalog order intact so presentation cannot silently reorder a
/// learner's actual mission or synthesize a completion event.
class CourseMissionStepPlan {
  const CourseMissionStepPlan._(this.steps);

  factory CourseMissionStepPlan.fromLinks(Iterable<ContentLink> links) {
    final orderedLinks = List<ContentLink>.unmodifiable(links);
    final total = orderedLinks.length;
    return CourseMissionStepPlan._(
      List<CourseMissionStep>.unmodifiable([
        for (var index = 0; index < total; index++)
          CourseMissionStep(
            link: orderedLinks[index],
            index: index,
            total: total,
          ),
      ]),
    );
  }

  final List<CourseMissionStep> steps;

  CourseMissionStep? stepForContentLinkId(String contentLinkId) {
    final normalized = contentLinkId.trim();
    if (normalized.isEmpty) return null;
    for (final step in steps) {
      if (step.link.id == normalized) return step;
    }
    return null;
  }
}

class CourseMissionStep {
  const CourseMissionStep({
    required this.link,
    required this.index,
    required this.total,
  });

  final ContentLink link;
  final int index;
  final int total;

  int get displayIndex => index + 1;

  double get progress => total == 0 ? 0 : displayIndex / total;
}
