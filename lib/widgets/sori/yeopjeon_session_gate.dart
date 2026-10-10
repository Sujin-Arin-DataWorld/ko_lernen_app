import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/account/cloud_write_session.dart';
import '../../services/local_data_lifetime.dart';

/// Removes an old account's receipt subtree as soon as identity changes.
class YeopjeonSessionGate extends StatefulWidget {
  const YeopjeonSessionGate({super.key, required this.child});
  final Widget child;
  @override
  State<YeopjeonSessionGate> createState() => _YeopjeonSessionGateState();
}

class _YeopjeonSessionGateState extends State<YeopjeonSessionGate> {
  final _lifetime = LocalDataLifetime.capture();
  final _identity = cloudWriteSessionController.identityEpoch;
  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: cloudWriteSessionController.changes,
    builder: (context, _, __) =>
        _lifetime.isCurrent &&
            _identity == cloudWriteSessionController.identityEpoch
        ? widget.child
        : Scaffold(
            body: SafeArea(
              child: Center(
                child: TextButton(
                  onPressed: () => Navigator.maybePop(context),
                  child: Text(AppL10n.of(context).btnClose),
                ),
              ),
            ),
          ),
  );
}
