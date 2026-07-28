import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:vitreum/vitreum.dart';

import 'package:vitreum_example/main.dart';

void main() {
  testWidgets('example presents the Vitreum showcase', (tester) async {
    await tester.pumpWidget(const VitreumExample());
    await tester.pump();

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Coastal studio'), findsOneWidget);
  });

  testWidgets('floating navigation fits portrait and landscape', (
    tester,
  ) async {
    for (final size in <Size>[const Size(430, 932), const Size(932, 430)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(const VitreumExample());
      await tester.pump();

      expect(
        tester.getSize(find.byType(VitreumGlassNavigationBar)),
        Size(size.width - 40, 64),
      );
      expect(tester.takeException(), isNull);
    }
  });
}
