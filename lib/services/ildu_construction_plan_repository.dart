import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/ildu_construction_plan.dart';

final class IlDuConstructionPlanRepository {
  static const assetPath =
      'assets/data/ildu_sarangchae_construction_plan_v1.json';

  const IlDuConstructionPlanRepository({this.bundle});

  final AssetBundle? bundle;

  Future<IlDuEstateConstructionPlan> load() async {
    final raw = await (bundle ?? rootBundle).loadString(assetPath);
    return IlDuEstateConstructionPlan.fromJson(jsonDecode(raw));
  }
}
