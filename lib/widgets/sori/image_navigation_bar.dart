import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show kTouchSlop;

import 'approved_chrome_assets.dart';
import 'tokens.dart';

/// Native destination behavior with the user's five image-only icons.
/// Selection, keyboard, tooltip and screen-reader actions remain NavigationBar's.
class SoriImageNavigationBar extends StatefulWidget {
  const SoriImageNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.labels,
    required this.assets,
  }) : assert(labels.length == 5),
       assert(assets.length == 5);

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<String> labels;
  final List<String> assets;

  @override
  State<SoriImageNavigationBar> createState() => _SoriImageNavigationBarState();
}

class _SoriImageNavigationBarState extends State<SoriImageNavigationBar>
    with WidgetsBindingObserver {
  late bool _resumed;

  @override
  void initState() {
    super.initState();
    _resumed =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final resumed = state == AppLifecycleState.resumed;
    if (_resumed != resumed) {
      setState(() => _resumed = resumed);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TickerMode(
    enabled: _resumed,
    child: NavigationBar(
      key: const ValueKey('sori-image-navigation-bar'),
      height: 60,
      backgroundColor: SoriSurfaces.of(context).surface,
      indicatorColor: Colors.transparent,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
      selectedIndex: widget.selectedIndex,
      onDestinationSelected: widget.onDestinationSelected,
      destinations: [
        for (var index = 0; index < widget.assets.length; index++)
          _ImageDestination(
            // Pausing clears transient contact state; resuming starts settled.
            key: ValueKey('${widget.assets[index]}-$_resumed'),
            asset: widget.assets[index],
            label: widget.labels[index],
            selected: widget.selectedIndex == index,
            motionActive: _resumed,
          ),
      ],
    ),
  );
}

class _ImageDestination extends StatefulWidget {
  const _ImageDestination({
    super.key,
    required this.asset,
    required this.label,
    required this.selected,
    required this.motionActive,
  });

  final String asset;
  final String label;
  final bool selected;
  final bool motionActive;

  @override
  State<_ImageDestination> createState() => _ImageDestinationState();
}

class _ImageDestinationState extends State<_ImageDestination> {
  bool _pressed = false;
  Offset? _pointerOrigin;

  void _release() {
    if (!mounted) {
      return;
    }
    _pointerOrigin = null;
    if (_pressed) {
      setState(() => _pressed = false);
    }
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (event) {
      _pointerOrigin = event.position;
      setState(() => _pressed = true);
    },
    onPointerMove: (event) {
      if (_pointerOrigin != null &&
          (event.position - _pointerOrigin!).distance > kTouchSlop) {
        _release();
      }
    },
    onPointerUp: (_) => _release(),
    onPointerCancel: (_) => _release(),
    child: NavigationDestination(
      key: ValueKey('sori-image-destination-${widget.asset}'),
      label: widget.label,
      tooltip: widget.label,
      icon: SoriNavigationImage(
        asset: widget.asset,
        selected: widget.selected,
        pressed: _pressed,
        motionActive: widget.motionActive,
      ),
      selectedIcon: SoriNavigationImage(
        asset: widget.asset,
        selected: widget.selected,
        pressed: _pressed,
        motionActive: widget.motionActive,
      ),
    ),
  );
}

/// A short spatial settle and a separate non-overshooting contact shadow.
/// No ticker runs at rest; reduced motion keeps the selected marker static.
class SoriNavigationImage extends StatelessWidget {
  const SoriNavigationImage({
    super.key,
    required this.asset,
    required this.selected,
    this.pressed = false,
    this.motionActive = true,
  });

  final String asset;
  final bool selected;
  final bool pressed;
  final bool motionActive;

  @override
  Widget build(BuildContext context) {
    final animate =
        motionActive &&
        !SoriMotion.reduceMotion(context) &&
        TickerMode.valuesOf(context).enabled;
    final target = !animate
        ? 0.0
        : pressed
        ? -1.0
        : selected
        ? 1.0
        : 0.0;
    final duration = animate ? SoriMotion.fast : Duration.zero;
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: AnimatedContainer(
              duration: duration,
              curve: SoriMotion.gentle,
              decoration: BoxDecoration(
                color: selected ? const Color(0xff084a3e) : Colors.transparent,
                borderRadius: BorderRadius.circular(SoriRadius.sm),
                border: Border.all(
                  color: selected
                      ? const Color(0xffd4bc80)
                      : Colors.transparent,
                  width: 1.2,
                ),
                boxShadow: selected
                    ? const [
                        BoxShadow(
                          color: Color(0xff082d27),
                          offset: Offset(0, 2),
                        ),
                        BoxShadow(
                          color: Color(0x300c281b),
                          offset: Offset(0, 3),
                          blurRadius: 4,
                        ),
                      ]
                    : const [],
              ),
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: target, end: target),
            duration: duration,
            curve: SoriMotion.gentle,
            child: ApprovedChromeImage(asset: asset, size: 48),
            builder: (_, value, child) => Transform.translate(
              key: ValueKey('sori-navigation-depth-$asset'),
              offset: Offset(0, -2 * value),
              child: Transform.scale(scale: 1 + .05 * value, child: child),
            ),
          ),
        ],
      ),
    );
  }
}
