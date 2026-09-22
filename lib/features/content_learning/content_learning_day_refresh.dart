import 'dart:async';
import 'package:flutter/widgets.dart';
import 'content_learning_service.dart';

/// Refreshes date-dependent presentation without creating a plan or writing data.
mixin ContentLearningDayRefresh<T extends StatefulWidget> on State<T> {
  Timer? _dayTimer;
  late final AppLifecycleListener _dayLifecycle;
  String _displayedDate = '';

  @override
  void initState() {
    super.initState();
    _scheduleDayRefresh();
    _dayLifecycle = AppLifecycleListener(onResume: _scheduleDayRefresh);
  }

  void _scheduleDayRefresh() {
    _dayTimer?.cancel();
    final now = ContentLearningService.localNow;
    final date = now.toIso8601String().substring(0, 10);
    if (_displayedDate.isNotEmpty && _displayedDate != date && mounted) {
      setState(() {});
    }
    _displayedDate = date;
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    _dayTimer = Timer(tomorrow.difference(now), _scheduleDayRefresh);
  }

  @override
  void dispose() {
    _dayTimer?.cancel();
    _dayLifecycle.dispose();
    super.dispose();
  }
}
