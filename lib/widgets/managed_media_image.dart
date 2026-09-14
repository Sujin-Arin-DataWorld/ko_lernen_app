import 'dart:io';

import 'package:flutter/material.dart';

import '../services/account/cloud_write_session.dart';
import '../services/word_image_service.dart';
import 'display_sized_file_image.dart';

class ManagedMediaImage extends StatefulWidget {
  const ManagedMediaImage({
    super.key,
    required this.reference,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.sessions,
  });

  final String reference;
  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  @visibleForTesting
  final CloudWriteSessionController? sessions;

  @override
  State<ManagedMediaImage> createState() => _ManagedMediaImageState();
}

class _ManagedMediaImageState extends State<ManagedMediaImage>
    with WidgetsBindingObserver {
  late CloudWriteSessionController _sessions;
  late Future<File?> _file;

  @override
  void initState() {
    super.initState();
    _sessions = widget.sessions ?? cloudWriteSessionController;
    _sessions.changes.addListener(_reload);
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void didUpdateWidget(ManagedMediaImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sessions = widget.sessions ?? cloudWriteSessionController;
    if (_sessions != sessions) {
      _sessions.changes.removeListener(_reload);
      _sessions = sessions;
      _sessions.changes.addListener(_reload);
      _load();
    } else if (oldWidget.reference != widget.reference) {
      _load();
    }
  }

  void _load() {
    final session = _sessions.current;
    final canRead = session == null
        ? !_sessions.hasBeenActivated
        : session.mode == CloudWriteMode.ready;
    // Rapid lifecycle events can replace a lookup before the next frame's
    // FutureBuilder subscribes. Always handle errors at creation time.
    _file = canRead
        ? WordImageService.resolve(widget.reference).onError((_, _) => null)
        : Future<File?>.value();
  }

  void _reload() => setState(_load);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reload();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessions.changes.removeListener(_reload);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return FutureBuilder<File?>(
      // A new lookup has no ownership of the previous file, even while waiting.
      key: ObjectKey(_file),
      future: _file,
      builder: (context, snapshot) {
        final file = snapshot.data;
        final child = file == null
            ? SizedBox(
                width: widget.width,
                height: widget.height,
                child: const Icon(Icons.image_not_supported_outlined),
              )
            : Image(
                image: DisplaySizedFileImage(
                  file,
                  Size(widget.width * dpr, widget.height * dpr),
                  widget.fit,
                ),
                width: widget.width,
                height: widget.height,
                fit: widget.fit,
                errorBuilder: (_, __, ___) => SizedBox(
                  width: widget.width,
                  height: widget.height,
                  child: const Icon(Icons.image_not_supported_outlined),
                ),
              );
        return widget.borderRadius == null
            ? child
            : ClipRRect(borderRadius: widget.borderRadius!, child: child);
      },
    );
  }
}
