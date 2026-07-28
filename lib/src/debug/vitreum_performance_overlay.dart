import 'dart:async';
import 'dart:collection';
import 'dart:ui' show FramePhase;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// A rolling snapshot collected by [VitreumPerformanceOverlay].
@immutable
class VitreumPerformanceSnapshot {
  const VitreumPerformanceSnapshot({
    required this.framesPerSecond,
    required this.averageBuildTime,
    required this.maximumBuildTime,
    required this.averageRasterTime,
    required this.maximumRasterTime,
    required this.averageFrameTime,
    required this.jankyFrameCount,
    required this.sampleCount,
    required this.rasterCacheMegabytes,
  });

  /// Approximate rendered frames per second across the current sample window.
  final double framesPerSecond;

  final Duration averageBuildTime;
  final Duration maximumBuildTime;
  final Duration averageRasterTime;
  final Duration maximumRasterTime;
  final Duration averageFrameTime;

  /// Frames whose build or raster work exceeded the configured frame budget.
  final int jankyFrameCount;

  final int sampleCount;

  /// Layer and picture raster-cache image data reported by the latest frame.
  ///
  /// This is not the application's total process memory.
  final double rasterCacheMegabytes;

  double get jankPercentage =>
      sampleCount == 0 ? 0 : jankyFrameCount * 100 / sampleCount;
}

/// Opt-in live frame diagnostics for Vitreum screens.
///
/// This overlay uses Flutter's engine [FrameTiming] callbacks. Enable it only
/// while profiling because collecting and painting diagnostics adds a small
/// amount of work of its own. Profile-mode measurements are more meaningful
/// than debug-mode measurements.
class VitreumPerformanceOverlay extends StatefulWidget {
  const VitreumPerformanceOverlay({
    required this.child,
    this.enabled = false,
    this.alignment = Alignment.topRight,
    this.refreshInterval = const Duration(milliseconds: 500),
    this.frameBudget = const Duration(microseconds: 16667),
    this.maxSamples = 120,
    this.label,
    this.onUpdate,
    super.key,
  }) : assert(maxSamples > 1);

  final Widget child;

  /// Whether frame collection and the visual panel are active.
  final bool enabled;

  final Alignment alignment;

  /// How frequently the visible values and [onUpdate] are refreshed.
  final Duration refreshInterval;

  /// Work above this duration is counted as jank.
  ///
  /// The default is the 60 Hz frame budget. Use about 8.33 ms when explicitly
  /// evaluating a 120 Hz target.
  final Duration frameBudget;

  /// Number of recent engine frames retained for rolling calculations.
  final int maxSamples;

  /// Optional scenario description, such as `simulated · balanced · 12 cards`.
  final String? label;

  /// Receives the same rolling snapshot shown by the panel.
  final ValueChanged<VitreumPerformanceSnapshot>? onUpdate;

  @override
  State<VitreumPerformanceOverlay> createState() =>
      _VitreumPerformanceOverlayState();
}

class _VitreumPerformanceOverlayState extends State<VitreumPerformanceOverlay> {
  final ListQueue<FrameTiming> _timings = ListQueue<FrameTiming>();
  Timer? _refreshTimer;
  VitreumPerformanceSnapshot? _snapshot;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _start();
  }

  @override
  void didUpdateWidget(VitreumPerformanceOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      widget.enabled ? _start() : _stop();
    } else if (widget.enabled &&
        (oldWidget.refreshInterval != widget.refreshInterval ||
            oldWidget.maxSamples != widget.maxSamples)) {
      _stop();
      _start();
    }
  }

  void _start() {
    if (widget.refreshInterval <= Duration.zero) {
      throw ArgumentError.value(
        widget.refreshInterval,
        'refreshInterval',
        'must be greater than zero',
      );
    }
    if (widget.frameBudget <= Duration.zero) {
      throw ArgumentError.value(
        widget.frameBudget,
        'frameBudget',
        'must be greater than zero',
      );
    }
    SchedulerBinding.instance.addTimingsCallback(_recordTimings);
    _refreshTimer = Timer.periodic(widget.refreshInterval, (_) => _refresh());
  }

  void _stop() {
    SchedulerBinding.instance.removeTimingsCallback(_recordTimings);
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _timings.clear();
    _snapshot = null;
  }

  void _recordTimings(List<FrameTiming> timings) {
    _timings.addAll(timings);
    while (_timings.length > widget.maxSamples) {
      _timings.removeFirst();
    }
  }

  void _refresh() {
    if (!mounted || _timings.isEmpty) return;
    final snapshot = _summarize(_timings, widget.frameBudget);
    widget.onUpdate?.call(snapshot);
    setState(() => _snapshot = snapshot);
  }

  @override
  void dispose() {
    if (widget.enabled) _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        widget.child,
        Positioned.fill(
          child: SafeArea(
            minimum: const EdgeInsets.all(8),
            child: Align(
              alignment: widget.alignment,
              child: IgnorePointer(
                child: _PerformancePanel(
                  snapshot: _snapshot,
                  frameBudget: widget.frameBudget,
                  label: widget.label,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

VitreumPerformanceSnapshot _summarize(
  Iterable<FrameTiming> samples,
  Duration frameBudget,
) {
  final timings = samples.toList(growable: false);
  var buildMicros = 0;
  var rasterMicros = 0;
  var frameMicros = 0;
  var maxBuildMicros = 0;
  var maxRasterMicros = 0;
  var jankyFrames = 0;

  for (final timing in timings) {
    final build = timing.buildDuration.inMicroseconds;
    final raster = timing.rasterDuration.inMicroseconds;
    buildMicros += build;
    rasterMicros += raster;
    frameMicros += timing.totalSpan.inMicroseconds;
    if (build > maxBuildMicros) maxBuildMicros = build;
    if (raster > maxRasterMicros) maxRasterMicros = raster;
    if (build > frameBudget.inMicroseconds ||
        raster > frameBudget.inMicroseconds) {
      jankyFrames++;
    }
  }

  var fps = 0.0;
  if (timings.length > 1) {
    final firstVsync = timings.first.timestampInMicroseconds(
      FramePhase.vsyncStart,
    );
    final lastVsync = timings.last.timestampInMicroseconds(
      FramePhase.vsyncStart,
    );
    final elapsedMicros = lastVsync - firstVsync;
    if (elapsedMicros > 0) {
      fps =
          (timings.length - 1) * Duration.microsecondsPerSecond / elapsedMicros;
    }
  }

  final count = timings.length;
  final latest = timings.last;
  return VitreumPerformanceSnapshot(
    framesPerSecond: fps,
    averageBuildTime: Duration(microseconds: buildMicros ~/ count),
    maximumBuildTime: Duration(microseconds: maxBuildMicros),
    averageRasterTime: Duration(microseconds: rasterMicros ~/ count),
    maximumRasterTime: Duration(microseconds: maxRasterMicros),
    averageFrameTime: Duration(microseconds: frameMicros ~/ count),
    jankyFrameCount: jankyFrames,
    sampleCount: count,
    rasterCacheMegabytes:
        latest.layerCacheMegabytes + latest.pictureCacheMegabytes,
  );
}

/// Calculates the overlay's rolling values from synthetic engine timings.
@visibleForTesting
VitreumPerformanceSnapshot debugSummarizePerformanceTimings(
  Iterable<FrameTiming> samples, {
  Duration frameBudget = const Duration(microseconds: 16667),
}) => _summarize(samples, frameBudget);

class _PerformancePanel extends StatelessWidget {
  const _PerformancePanel({
    required this.snapshot,
    required this.frameBudget,
    required this.label,
  });

  final VitreumPerformanceSnapshot? snapshot;
  final Duration frameBudget;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final snapshot = this.snapshot;
    final mode = kProfileMode
        ? 'PROFILE'
        : kReleaseMode
        ? 'RELEASE'
        : 'DEBUG';
    final text = snapshot == null
        ? 'Collecting frames…'
        : [
            'FPS       ${snapshot.framesPerSecond.toStringAsFixed(1)}',
            'Frame avg ${_milliseconds(snapshot.averageFrameTime)} ms',
            'Build     ${_milliseconds(snapshot.averageBuildTime)} / '
                '${_milliseconds(snapshot.maximumBuildTime)} ms',
            'Raster    ${_milliseconds(snapshot.averageRasterTime)} / '
                '${_milliseconds(snapshot.maximumRasterTime)} ms',
            'Jank      ${snapshot.jankyFrameCount}/${snapshot.sampleCount} '
                '(${snapshot.jankPercentage.toStringAsFixed(1)}%)',
            'Cache     ${snapshot.rasterCacheMegabytes.toStringAsFixed(2)} MB',
            'Budget    ${_milliseconds(frameBudget)} ms',
          ].join('\n');

    return Semantics(
      label: 'Vitreum performance diagnostics',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xE6111723),
          border: Border.all(color: const Color(0x665EEBFF)),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: Color(0x55000000), blurRadius: 12),
          ],
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: DefaultTextStyle(
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontSize: 11,
                height: 1.35,
                decoration: TextDecoration.none,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'VITREUM PERF · $mode',
                    style: const TextStyle(
                      color: Color(0xFF7DEBFF),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (label case final value?)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        value,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFFB7C5D8)),
                      ),
                    ),
                  const SizedBox(height: 5),
                  Text(text),
                  if (kDebugMode)
                    const Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: Text(
                        'Use --profile for meaningful results',
                        style: TextStyle(color: Color(0xFFFFCA80)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _milliseconds(Duration value) =>
    (value.inMicroseconds / Duration.microsecondsPerMillisecond)
        .toStringAsFixed(2);
