import 'package:flutter/widgets.dart';

@immutable
class VitreumInteractionData {
  const VitreumInteractionData({
    this.pressed = false,
    this.hovered = false,
    this.focused = false,
    this.position,
  });

  final bool pressed;
  final bool hovered;
  final bool focused;
  final Offset? position;

  double get intensity {
    if (pressed) return 1;
    if (focused) return 0.46;
    if (hovered) return 0.28;
    return 0;
  }

  @override
  bool operator ==(Object other) =>
      other is VitreumInteractionData &&
      other.pressed == pressed &&
      other.hovered == hovered &&
      other.focused == focused &&
      other.position == position;

  @override
  int get hashCode => Object.hash(pressed, hovered, focused, position);
}

class VitreumInteractionScope extends InheritedWidget {
  const VitreumInteractionScope({
    required this.data,
    required super.child,
    super.key,
  });

  final VitreumInteractionData data;

  static VitreumInteractionData of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<VitreumInteractionScope>()
          ?.data ??
      const VitreumInteractionData();

  @override
  bool updateShouldNotify(VitreumInteractionScope oldWidget) =>
      oldWidget.data != data;
}
