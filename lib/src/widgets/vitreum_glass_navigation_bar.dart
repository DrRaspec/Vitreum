import 'package:flutter/material.dart';

import '../core/vitreum_backend.dart';
import '../core/vitreum_config.dart';
import '../core/vitreum_quality.dart';
import '../core/vitreum_shape.dart';
import '../core/vitreum_style.dart';
import 'vitreum_glass.dart';

/// A destination displayed by [VitreumGlassNavigationBar].
@immutable
class VitreumNavigationDestination {
  const VitreumNavigationDestination({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// A cross-platform Flutter approximation of floating glass navigation.
///
/// This widget is not a `UITabBar`, does not use `UITabBarController`, and
/// never claims native iOS tab-bar behavior. Use a native host integration
/// such as the example app's `VitreumNativeTabScaffold` when the real system
/// tab bar is required.
class VitreumGlassNavigationBar extends StatefulWidget {
  const VitreumGlassNavigationBar({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.style = VitreumStyle.regular,
    this.quality = VitreumQuality.adaptive,
    this.fallbackStyle = const VitreumFallbackStyle(),
    this.showDebugBounds = false,
    super.key,
  }) : assert(destinations.length >= 2),
       assert(selectedIndex >= 0 && selectedIndex < destinations.length);

  final List<VitreumNavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VitreumStyle style;
  final VitreumQuality quality;
  final VitreumFallbackStyle fallbackStyle;
  final bool showDebugBounds;

  @override
  State<VitreumGlassNavigationBar> createState() =>
      _VitreumGlassNavigationBarState();
}

class _VitreumGlassNavigationBarState extends State<VitreumGlassNavigationBar> {
  int? _pressedIndex;

  @override
  Widget build(BuildContext context) {
    final content = SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: List<Widget>.generate(
            widget.destinations.length,
            _destination,
          ),
        ),
      ),
    );

    final surface = VitreumGlass(
      mode: VitreumMode.simulated,
      shape: const VitreumShape.capsule(),
      style: widget.style,
      quality: widget.quality,
      fallbackStyle: widget.fallbackStyle,
      semanticLabel: 'Simulated primary navigation',
      child: content,
    );

    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        surface,
        if (widget.showDebugBounds)
          const Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: _BoundsPainter())),
          ),
      ],
    );
  }

  Widget _destination(int index) {
    final destination = widget.destinations[index];
    final selected = widget.selectedIndex == index;
    final pressed = _pressedIndex == index;
    final foreground = selected
        ? Colors.white.withValues(alpha: 0.94)
        : Colors.white.withValues(alpha: 0.58);

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: destination.label,
        child: GestureDetector(
          key: ValueKey<String>('vitreum-navigation-destination-$index'),
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressedIndex = index),
          onTapCancel: () => setState(() => _pressedIndex = null),
          onTapUp: (_) => setState(() => _pressedIndex = null),
          onTap: () => widget.onDestinationSelected(index),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 88, minHeight: 44),
              child: AnimatedScale(
                scale: pressed ? 0.975 : (selected ? 1.035 : 1),
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOutCubic,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    AnimatedContainer(
                      width: 36,
                      height: 36,
                      duration: const Duration(milliseconds: 140),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(
                          alpha: pressed ? 0.10 : (selected ? 0.05 : 0),
                        ),
                      ),
                      child: Icon(
                        destination.icon,
                        size: 24,
                        color: foreground,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        destination.label,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BoundsPainter extends CustomPainter {
  const _BoundsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF3B30)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const length = 10.0;
    final path = Path()
      ..moveTo(0, length)
      ..lineTo(0, 0)
      ..lineTo(length, 0)
      ..moveTo(size.width - length, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, length)
      ..moveTo(size.width, size.height - length)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width - length, size.height)
      ..moveTo(length, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, size.height - length);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BoundsPainter oldDelegate) => false;
}
