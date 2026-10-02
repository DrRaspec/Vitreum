import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;

typedef VitreumScrollMinimizerBuilder =
    Widget Function(BuildContext context, bool hasScrolledContent);

/// Shared scroll behavior for Vitreum's Flutter-owned bars.
class VitreumScrollMinimizer extends StatefulWidget {
  const VitreumScrollMinimizer({
    required this.builder,
    required this.scrollController,
    required this.minimizeOnScroll,
    required this.trackScrollEdge,
    required this.expandOnInteraction,
    required this.minimizedTranslation,
    required this.minimizedScale,
    super.key,
  });

  final VitreumScrollMinimizerBuilder builder;
  final ScrollController? scrollController;
  final bool minimizeOnScroll;
  final bool trackScrollEdge;
  final bool expandOnInteraction;
  final Offset minimizedTranslation;
  final double minimizedScale;

  @override
  State<VitreumScrollMinimizer> createState() => _VitreumScrollMinimizerState();
}

class _VitreumScrollMinimizerState extends State<VitreumScrollMinimizer> {
  static const _minimizeDistance = 28.0;
  static const _expandDistance = 16.0;
  static const _edgeTolerance = 2.0;

  ScrollController? _attachedController;
  bool _minimized = false;
  bool _hasScrolledContent = false;
  bool _offsetInitialized = false;
  double _lastOffset = 0;
  double _directionDistance = 0;

  @override
  void initState() {
    super.initState();
    _attach(widget.scrollController);
  }

  @override
  void didUpdateWidget(VitreumScrollMinimizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      _detach();
      _resetState();
      _attach(widget.scrollController);
    } else if (oldWidget.minimizeOnScroll && !widget.minimizeOnScroll) {
      _minimized = false;
      _directionDistance = 0;
    }
    if (oldWidget.trackScrollEdge && !widget.trackScrollEdge) {
      _hasScrolledContent = false;
    } else if (!oldWidget.trackScrollEdge && widget.trackScrollEdge) {
      final controller = _attachedController;
      final position = controller == null ? null : _singlePosition(controller);
      if (position != null && position.hasContentDimensions) {
        _lastOffset = _boundedPixels(position);
        _offsetInitialized = true;
        _hasScrolledContent =
            _hasScrollableContent(position) &&
            _distanceFromInitialEdge(position) > _edgeTolerance;
      }
    }
  }

  void _attach(ScrollController? controller) {
    if (controller == null || identical(controller, _attachedController)) {
      return;
    }
    _attachedController = controller;
    _lastOffset = controller.initialScrollOffset;
    _offsetInitialized = true;
    controller.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !identical(controller, _attachedController)) return;
      _synchronizeOffset(controller);
    });
  }

  void _detach() {
    _attachedController?.removeListener(_handleScroll);
    _attachedController = null;
  }

  void _resetState() {
    _minimized = false;
    _hasScrolledContent = false;
    _offsetInitialized = false;
    _lastOffset = 0;
    _directionDistance = 0;
  }

  ScrollPosition? _singlePosition(ScrollController controller) {
    if (!controller.hasClients || controller.positions.length != 1) return null;
    return controller.positions.single;
  }

  void _synchronizeOffset(ScrollController controller) {
    final position = _singlePosition(controller);
    if (position == null || !position.hasContentDimensions) return;
    _lastOffset = _boundedPixels(position);
    _offsetInitialized = true;
    final hasScrolledContent =
        widget.trackScrollEdge &&
        _hasScrollableContent(position) &&
        _distanceFromInitialEdge(position) > _edgeTolerance;
    if (hasScrolledContent != _hasScrolledContent) {
      setState(() => _hasScrolledContent = hasScrolledContent);
    }
  }

  void _handleScroll() {
    if (!mounted) return;
    final controller = _attachedController;
    if (controller == null || !identical(controller, widget.scrollController)) {
      return;
    }
    final position = _singlePosition(controller);
    if (position == null || !position.hasContentDimensions) {
      if (_minimized || _hasScrolledContent) {
        setState(() {
          _minimized = false;
          _hasScrolledContent = false;
          _directionDistance = 0;
        });
      }
      return;
    }
    if (axisDirectionToAxis(position.axisDirection) != Axis.vertical) {
      if (_minimized || _hasScrolledContent) {
        setState(() {
          _minimized = false;
          _hasScrolledContent = false;
          _directionDistance = 0;
        });
      }
      return;
    }

    final offset = _boundedPixels(position);
    if (!_offsetInitialized) {
      _lastOffset = offset;
      _offsetInitialized = true;
      return;
    }

    final canScroll = _hasScrollableContent(position);
    final hasMovedFromEdge =
        canScroll && _distanceFromInitialEdge(position) > _edgeTolerance;
    final hasScrolledContent = widget.trackScrollEdge && hasMovedFromEdge;
    var minimized = _minimized;

    // Native tab-bar minimization is driven by user scrolling. Ignoring idle
    // changes prevents keyboard avoidance, restoration, and programmatic
    // scroll commands from changing the bar state.
    if (!canScroll || !widget.minimizeOnScroll) {
      minimized = false;
      _directionDistance = 0;
    } else if (_distanceFromInitialEdge(position) <= _edgeTolerance) {
      minimized = false;
      _directionDistance = 0;
    } else if (position.userScrollDirection != ScrollDirection.idle) {
      final delta = _normalizedVerticalDelta(
        offset - _lastOffset,
        position.axisDirection,
      );
      if (delta != 0) {
        if (_directionDistance != 0 && delta.sign != _directionDistance.sign) {
          _directionDistance = 0;
        }
        _directionDistance += delta;
      }

      if (!minimized &&
          hasMovedFromEdge &&
          _directionDistance >= _minimizeDistance) {
        minimized = true;
        _directionDistance = 0;
      } else if (minimized && _directionDistance <= -_expandDistance) {
        minimized = false;
        _directionDistance = 0;
      }
    }

    _lastOffset = offset;
    if (minimized != _minimized || hasScrolledContent != _hasScrolledContent) {
      setState(() {
        _minimized = minimized;
        _hasScrolledContent = hasScrolledContent;
      });
    }
  }

  double _boundedPixels(ScrollPosition position) => position.pixels
      .clamp(position.minScrollExtent, position.maxScrollExtent)
      .toDouble();

  bool _hasScrollableContent(ScrollPosition position) =>
      position.maxScrollExtent - position.minScrollExtent > _edgeTolerance;

  double _distanceFromInitialEdge(ScrollPosition position) =>
      (_boundedPixels(position) - position.minScrollExtent).abs();

  double _normalizedVerticalDelta(double delta, AxisDirection direction) =>
      switch (direction) {
        AxisDirection.down => delta,
        AxisDirection.up => -delta,
        AxisDirection.left || AxisDirection.right => 0,
      };

  void _restoreForInteraction() {
    if (!widget.expandOnInteraction || !_minimized) return;
    _directionDistance = 0;
    setState(() => _minimized = false);
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 180);

    return Listener(
      key: const ValueKey('vitreum-scroll-minimizer-listener'),
      onPointerDown: (_) => _restoreForInteraction(),
      child: AnimatedSlide(
        key: const ValueKey('vitreum-scroll-minimizer-slide'),
        duration: duration,
        curve: Curves.easeInOutCubic,
        offset: _minimized ? widget.minimizedTranslation : Offset.zero,
        child: AnimatedScale(
          key: const ValueKey('vitreum-scroll-minimizer-scale'),
          duration: duration,
          curve: Curves.easeInOutCubic,
          scale: _minimized ? _validatedMinimizedScale : 1,
          child: widget.builder(context, _hasScrolledContent),
        ),
      ),
    );
  }

  double get _validatedMinimizedScale => widget.minimizedScale.isFinite
      ? widget.minimizedScale.clamp(0.5, 1).toDouble()
      : 0.9;
}
