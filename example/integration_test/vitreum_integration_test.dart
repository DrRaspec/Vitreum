import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vitreum/vitreum.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('solid and simulated surfaces render without exceptions', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Column(
          children: <Widget>[
            VitreumGlass(
              mode: VitreumMode.solid,
              child: SizedBox(width: 80, height: 40),
            ),
            VitreumGlass(
              mode: VitreumMode.simulated,
              child: SizedBox(width: 80, height: 40),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(VitreumGlass), findsNWidgets(2));
  });

  testWidgets(
    'Flutter child remains interactive above requested native glass',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 180,
              height: 64,
              child: VitreumGlass(
                mode: VitreumMode.native,
                shape: const VitreumShape.capsule(),
                child: TextButton(
                  onPressed: () => taps++,
                  child: const Text('Tap native surface'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tap native surface'));

      expect(taps, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
